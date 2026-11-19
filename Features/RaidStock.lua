-- 0.2.1: raid stock. Pick consumables and how many you want before a raid; CraftPilot compares crafting
-- (yourself or a twink) with buying at the AH, reserves what you already have and the materials to craft the
-- rest, and can hand the missing items to Auctionator. Nothing is bought or crafted automatically.
local _,CP=...
local L=CP.L

local DEFAULT_COUNT=5

function CP:RaidStock()
  self.db.raidStock=type(self.db.raidStock)=="table" and self.db.raidStock or {}
  return self.db.raidStock
end

-- Is an item a consumable (potion, flask, elixir, food, scroll ...)? From the client's item class.
function CP:IsConsumable(item)
  local fn=(_G.C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
  if type(fn)~="function" or type(item)~="number" then return false end
  local ok,_,_,_,_,_,classID=pcall(fn,item)
  return ok and classID==0
end

local function recipeData(self,key,id)
  local native=(self.db.recipes[key] or {})[id]
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local mats={}
  if native and type(native.mats)=="table" and #native.mats>0 then
    for _,m in ipairs(native.mats) do if type(m[1])=="number" then mats[m[1]]=(mats[m[1]] or 0)+m[2] end end
  else
    for item,n in pairs(recipe and recipe.mats or {}) do if type(n)=="number" then mats[item]=n end end
  end
  local yield=math.max(1,(recipe and (recipe.count or recipe.yield)) or (native and native.outputMin) or 1)
  return mats,yield,native and native.learned
end

-- Consumables you (or a twink) can craft, for the "add to raid stock" list: {item, key, id}.
function CP:RaidStockCandidates(key)
  local out,seen={},{}
  for id,native in pairs(self.db.recipes[key] or {}) do
    local item=native.learned and self:RecipeMarketOutput(key,id)
    if type(item)=="number" and not seen[item] and not self:RaidStock()[item] and self:IsConsumable(item) then
      seen[item]=true
      out[#out+1]={item=item,key=key,id=id,name=self:RecipeName(key,id,native.name)}
    end
  end
  table.sort(out,function(a,b) return a.name<b.name end)
  return out
end

function CP:SetRaidStock(item,key,id,count)
  local stock=self:RaidStock()
  if not count or count<=0 then stock[item]=nil
  else stock[item]={count=math.floor(count),key=key,id=id} end
  self:InvalidateReservations()
  self.reservedCache=nil
end

-- One row per stocked item: what you have, what is missing, crafting versus buying.
--   craft = materials for one item at purchase prices (nil when unknown or not craftable here)
--   ah    = AH price of the finished item
--   how   = "craft" or "buy" (the cheaper known way), "have" when nothing is missing, nil when unknown
function CP:RaidStockRows()
  local rows={}
  for item,entry in pairs(self:RaidStock()) do
    if type(entry)=="table" and type(entry.count)=="number" then
      local have=self:ItemAvailability(item)
      local row={item=item,key=entry.key,id=entry.id,count=entry.count,have=have,missing=math.max(0,entry.count-have)}
      local mats,yield,learned=recipeData(self,entry.key,entry.id)
      local makers=self.ItemMakers and self:ItemMakers(item) or {}
      local maker=learned and L("du") or (makers[1] and makers[1].alt)
      if (learned or maker) and next(mats) then
        local cost,known=0,true
        for mat,n in pairs(mats) do
          local p=self:PriceDetails(mat).price
          if not p then known=false;break end
          cost=cost+p*n
        end
        if known then row.craft=cost/yield end
        row.mats,row.yield,row.maker=mats,yield,maker
      end
      local p=self:PriceDetails(item)
      row.ah,row.ageDays=p.auction,p.ageDays
      if row.missing==0 then row.how="have"
      elseif row.craft and (not row.ah or row.craft<=row.ah) then row.how="craft"
      elseif row.ah then row.how="buy" end
      rows[#rows+1]=row
    end
  end
  table.sort(rows,function(a,b) return a.item<b.item end)
  return rows
end

-- What the raid stock needs, for the shared reservation (Planning.lua, owner "raid"): the finished items you
-- already own (so they are not sold) plus the materials to craft the missing ones.
function CP:RaidStockRequirements()
  local required={}
  local function add(id,n) if n>0 then required[id]=(required[id] or 0)+n end end
  for _,row in ipairs(self:RaidStockRows()) do
    add(row.item,math.min(row.have,row.count))
    if row.how=="craft" and row.mats and row.missing>0 then
      local crafts=math.ceil(row.missing/(row.yield or 1))
      for mat,n in pairs(row.mats) do add(mat,n*crafts) end
    end
  end
  return required
end

-- Missing amounts for Auctionator: materials for items to craft, the items themselves where buying is cheaper.
function CP:RaidStockShopping()
  local missing,total,unknown={},0,0
  local ledger=self:ReservationLedger()
  local allocated=ledger.allocated.raid or {}
  for _,row in ipairs(self:RaidStockRows()) do
    if row.how=="buy" then
      missing[row.item]=(missing[row.item] or 0)+row.missing;total=total+row.missing*row.ah
    elseif row.how=="craft" then
      local crafts=math.ceil(row.missing/(row.yield or 1))
      for mat,n in pairs(row.mats) do
        missing[mat]=(missing[mat] or 0)+n*crafts
      end
    elseif row.missing>0 then unknown=unknown+1 end
  end
  -- Materials already in stock (and reserved for the raid) are not bought again.
  for mat,n in pairs(missing) do
    local own=allocated[mat] or 0
    local item=self:RaidStock()[mat]
    if not item then
      local left=math.max(0,n-own)
      missing[mat]=left>0 and left or nil
      if left>0 then total=total+left*(self:PriceDetails(mat).price or 0) end
    end
  end
  return missing,total,unknown
end

function CP:RaidStockCards(key)
  local cards={{sectionHeader=true,title=L("Raid-Vorrat")}}
  local rows=self:RaidStockRows()
  if #rows==0 then
    cards[#cards+1]={title=L("Noch kein Raid-Vorrat"),detail=L("Unten bei einem Trank, Fläschchen oder Essen „Auf den Raid-Vorrat“ wählen. CraftPilot vergleicht dann Herstellen mit dem AH-Kauf und reserviert, was du schon hast."),color="blue"}
  end
  for _,row in ipairs(rows) do
    local status
    if row.how=="have" then status=L("Vorrat reicht")
    elseif row.how=="craft" then status=string.format(L("%d herstellen (%s) · ca. %s je Stück"),row.missing,row.maker or L("du"),self:FormatCostMoney(row.craft))
      ..(row.ah and (" · "..L("AH ")..self:FormatCostMoney(row.ah)) or "")
    elseif row.how=="buy" then status=string.format(L("%d im AH kaufen · ca. %s je Stück"),row.missing,self:FormatCostMoney(row.ah))
      ..(row.craft and (" · "..L("herstellen ")..self:FormatCostMoney(row.craft)) or "")
    else status=string.format(L("%d fehlen · kein Preis und kein Hersteller bekannt"),row.missing) end
    local item,entry=row.item,{key=row.key,id=row.id}
    -- 0.2.2: plus and minus instead of a slider, and a bar for what is already there.
    cards[#cards+1]={title=self:ItemName(item),detail=status,
      footer=string.format(L("%d von %d da · "),math.min(row.have,row.count),row.count)..L("0 nimmt den Eintrag heraus"),
      color=row.how=="have" and "green" or "gold",tooltipItem=item,recipeKey=row.key,recipeID=row.id,showMarket=false,
      icon=self.RecipeIcon and self:RecipeIcon(row.key,row.id),
      progress=row.count>0 and math.min(1,row.have/row.count) or 0,
      stepper={value=row.count,min=0,max=40,step=1,apply=function(value) CP:SetRaidStock(item,entry.key,entry.id,value);CP:Render() end}}
  end
  if #rows>0 then
    local _,total,unknown=self:RaidStockShopping()
    cards[#cards+1]={title=L("Raid-Vorrat an Auctionator"),
      detail=string.format(L("Fehlende Materialien und Tränke als Einkaufsliste · ca. %s"),self:FormatCostMoney(total))
        ..(unknown>0 and (" · "..string.format(L("%d ohne Preis"),unknown)) or ""),
      footer=L("Kauf bleibt manuell."),color="gold",
      action=function() CP:ExportToAuctionator("raid");CP:Render() end}
  end
  local candidates=self:RaidStockCandidates(key)
  if #candidates>0 then
    cards[#cards+1]={sectionHeader=true,title=L("Zum Raid-Vorrat hinzufügen")}
    for i=1,math.min(6,#candidates) do
      local c=candidates[i]
      local add=function() CP:SetRaidStock(c.item,c.key,c.id,DEFAULT_COUNT);CP:Render() end
      cards[#cards+1]={title=c.name,detail=string.format(L("Fügt %d Stück zum Raid-Vorrat hinzu"),DEFAULT_COUNT),
        color="blue",icon=self.RecipeIcon and self:RecipeIcon(c.key,c.id),tooltipItem=c.item,recipeKey=c.key,recipeID=c.id,showMarket=false,
        action=add,buttons={{label=L("Auf den Raid-Vorrat"),action=add}}}
    end
  end
  return cards
end
