-- 0.2.1: recipe wishlist with sources (trainer, vendor, Merchant's Favor, quest, boss drop), tooltip hints on
-- the recipe item and on the NPCs that drop it, and an auction house alarm when a wished recipe shows up in
-- the saved Auctionator prices. Read-only: nothing is bought or learned.
local _,CP=...
local L=CP.L

local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c=pcall(fn,...)
  if ok then return a,b,c end
end
local function secret(v) return type(issecretvalue)=="function" and issecretvalue(v)==true end
local function plain(v) if v~=nil and not secret(v) then return v end end
-- The game font has no star or check glyph (they show as boxes): use the ready-check texture instead.
local STAR="|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t "
CP.WISH_MARK=STAR
local function today() return type(date)=="function" and date("%Y-%m-%d") or "?" end

function CP:Wishlist(key)
  self.db.wishlist=type(self.db.wishlist)=="table" and self.db.wishlist or {}
  if key then
    self.db.wishlist[key]=type(self.db.wishlist[key])=="table" and self.db.wishlist[key] or {}
    return self.db.wishlist[key]
  end
  return self.db.wishlist
end
function CP:IsWished(key,id) return self:Wishlist(key)[id]==true end
function CP:ToggleWish(key,id)
  local list=self:Wishlist(key)
  list[id]=not list[id] or nil
  self.wishIndex=nil;self.wishItems=nil;self.tooltipCache=nil
  return list[id]==true
end

-- Where a recipe comes from, as short text parts: {kind, text}. Bosses come from QuestieDB at runtime.
function CP:RecipeSources(key,id)
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local out={}
  if not recipe then return out end
  local vendorsDone=false
  for _,source in ipairs(recipe.get or {}) do
    if source.kind=="trainer" then out[#out+1]={kind="trainer",text=L("Lehrer")}
    elseif source.kind=="vendor" and not vendorsDone then
      vendorsDone=true
      for i,v in ipairs(self:RecipeVendors(key,id,true)) do
        if i<=2 then out[#out+1]={kind="vendor",text=v.name.." ("..self:VendorOfferPrice(v)..")"} end
      end
    elseif source.kind=="quest" then out[#out+1]={kind="quest",text=L("Quest: ")..(source.questName or ("#"..tostring(source.quest)))}
    elseif source.kind=="start" then out[#out+1]={kind="start",text=L("Von Anfang an bekannt")}
    elseif source.kind=="drop" then
      local drops=self:QuestieItemDrops(recipe.item)
      if #drops>0 then
        for i,d in ipairs(drops) do
          if i<=3 then out[#out+1]={kind="drop",npc=d.id,text=d.name..(d.zone and (" · "..d.zone) or "")} end
        end
        if #drops>3 then out[#out+1]={kind="drop",text=string.format(L("und %d weitere Gegner"),#drops-3)} end
      else
        out[#out+1]={kind="drop",text=type(source.npcs)=="number" and string.format(L("Drop (%d Gegner)"),source.npcs) or L("Drop")}
      end
    end
  end
  return out
end
-- Where to go for a recipe: a vendor with a known place (your faction first), else a boss with a known place.
-- Returns {location, label} or nil. Drop chances are not in any data CraftPilot has.
function CP:RecipeGoTo(key,id)
  local best
  for _,v in ipairs(self:RecipeVendors(key,id,true)) do
    if v.location and (not best or (best.restricted and not v.restricted)) then best=v end
  end
  if best then return {location=best.location,label=best.name,kind="vendor"} end
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  for _,d in ipairs(recipe and recipe.item and self:QuestieItemDrops(recipe.item) or {}) do
    local record=self.QuestieNpcRecord and self:QuestieNpcRecord(d.id)
    if record and record.point then
      local p=record.point
      return {location={name=d.name,zone=p.zone or d.zone or "",map=p.map,x=p.x,y=p.y,indoor=true},label=d.name,kind="drop"}
    end
  end
  return nil
end
function CP:GoToRecipe(key,id)
  local go=self:RecipeGoTo(key,id)
  if not go then self:Say(L("Für dieses Rezept ist kein Ort hinterlegt."));return false end
  self:SetWaypoint(go.location)
  return true
end
function CP:RecipeClickHint(key,id,wished)
  local go=self:RecipeGoTo(key,id)
  local left=go and string.format(L("Klick: Wegpunkt zu %s"),go.label) or nil
  local right=wished and L("Rechtsklick: von der Wunschliste") or L("Rechtsklick: auf die Wunschliste")
  return left and (left.." · "..right) or (wished and L("Anklicken: von der Wunschliste nehmen") or L("Anklicken: auf die Wunschliste"))
end
-- 0.2.2: visible buttons on recipe cards (waypoint, wishlist) instead of relying on right-click.
function CP:RecipeButtons(key,id)
  local out={}
  if self:RecipeGoTo(key,id) then out[#out+1]={label=L("Wegpunkt"),action=function() CP:GoToRecipe(key,id) end} end
  local wished=self:IsWished(key,id)
  out[#out+1]={label=wished and L("Von der Wunschliste") or L("Auf die Wunschliste"),action=function() CP:ToggleWish(key,id);CP:Render() end}
  return out
end
local function recipeCardActions(self,key,id)
  local toggle=function() CP:ToggleWish(key,id);CP:Render() end
  if self:RecipeGoTo(key,id) then return function() CP:GoToRecipe(key,id) end,toggle end
  return toggle,toggle
end
CP.RecipeCardActions=recipeCardActions
function CP:RecipeSourceText(key,id)
  local parts={}
  for _,s in ipairs(self:RecipeSources(key,id)) do parts[#parts+1]=s.text end
  return #parts>0 and table.concat(parts," · ") or L("Quelle unbekannt")
end

-- Recipes worth wishing for: not learned, available, from skill 200 up, best profit first.
function CP:WishSuggestions(key,limit)
  local catalog=self:RecipeVendorCatalog(key)
  local rows={}
  for id,recipe in pairs(catalog and catalog.recipes or {}) do
    local native=(self.db.recipes[key] or {})[id]
    if not (native and native.learned) and not recipe.unavailable and not self:IsWished(key,id) and (recipe.learn or 0)>=200 then
      local profit=self:RecipeProfit(key,id)
      rows[#rows+1]={id=id,learn=recipe.learn or 0,profit=profit and profit.missing==0 and profit.profitBuy or nil}
    end
  end
  table.sort(rows,function(a,b)
    if (a.profit~=nil)~=(b.profit~=nil) then return a.profit~=nil end
    if a.profit and b.profit and a.profit~=b.profit then return a.profit>b.profit end
    if a.learn~=b.learn then return a.learn>b.learn end
    return a.id<b.id
  end)
  local out={}
  for i=1,math.min(limit or 6,#rows) do out[i]=rows[i] end
  return out
end

function CP:WishlistCards(key)
  local cards={{sectionHeader=true,title=L("Rezept-Wunschliste")}}
  local list=self:Wishlist(key)
  local ids={};for id in pairs(list) do ids[#ids+1]=id end;table.sort(ids)
  local catalog=self:RecipeVendorCatalog(key)
  if #ids==0 then
    cards[#cards+1]={title=L("Noch keine Wünsche"),detail=L("Bei einem Vorschlag unten „Auf die Wunschliste“ wählen. Bosse, die das Rezept droppen, zeigen es dann im Tooltip, und der AH-Alarm meldet es."),color="blue"}
  end
  for _,id in ipairs(ids) do
    local native=(self.db.recipes[key] or {})[id]
    local recipe=catalog and catalog.recipes[id]
    local learned=native and native.learned
    cards[#cards+1]={title=STAR..self:RecipeName(key,id,recipe and recipe.name),
      detail=learned and L("Erlernt · kann von der Wunschliste") or self:RecipeSourceText(key,id),
      footer=(learned and L("Erlernt") or (recipe and recipe.learn and (L("ab Skill ")..recipe.learn)) or ""),
      buttons=self:RecipeButtons(key,id),
      color=learned and "green" or "gold",icon=self.RecipeIcon and self:RecipeIcon(key,id),
      tooltipItem=recipe and recipe.item,recipeKey=key,recipeID=id,showMarket=false,
      action=learned and function() CP:ToggleWish(key,id);CP:Render() end or (recipeCardActions(self,key,id)),
      rightAction=select(2,recipeCardActions(self,key,id))}
  end
  local suggestions=self:WishSuggestions(key,5)
  if #suggestions>0 then
    cards[#cards+1]={sectionHeader=true,title=L("Vorschläge · noch nicht erlernt")}
    for _,s in ipairs(suggestions) do
      cards[#cards+1]={title=self:RecipeName(key,s.id),detail=self:RecipeSourceText(key,s.id),
        footer=(s.profit and (L("Gewinn je Herstellung: ")..(s.profit<0 and "-" or "+")..self:FormatCostMoney(math.abs(s.profit))) or ""),
        buttons=self:RecipeButtons(key,s.id),
        color="blue",icon=self.RecipeIcon and self:RecipeIcon(key,s.id),recipeKey=key,recipeID=s.id,showMarket=false,
        action=(recipeCardActions(self,key,s.id)),rightAction=select(2,recipeCardActions(self,key,s.id))}
    end
  end
  return cards
end

-- Tooltips: recipe item on the wishlist, NPCs that drop a wished recipe --------------------------------------------
function CP:WishedRecipeItems()
  if self.wishItems then return self.wishItems end
  local out={}
  for key,list in pairs(self:Wishlist()) do
    local catalog=self:RecipeVendorCatalog(key)
    for id in pairs(list) do
      local recipe=catalog and catalog.recipes[id]
      if recipe and recipe.item then out[recipe.item]={key=key,id=id} end
    end
  end
  self.wishItems=out
  return out
end
function CP:WishDropIndex()
  if self.wishIndex then return self.wishIndex end
  local index={}
  for item,w in pairs(self:WishedRecipeItems()) do
    for _,d in ipairs(self:QuestieItemDrops(item)) do
      index[d.id]=index[d.id] or {}
      index[d.id][#index[d.id]+1]=w
    end
  end
  self.wishIndex=index
  return index
end
function CP:NpcIDFromGUID(guid)
  guid=plain(guid)
  if type(guid)~="string" then return nil end
  local kind,id=guid:match("^(%a+)%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)")
  if kind~="Creature" and kind~="Vehicle" then return nil end
  return tonumber(id)
end
function CP:WishUnitLines(npc)
  if not self.db or self.db.ui.tooltips==false or type(npc)~="number" then return nil end
  local wishes=self:WishDropIndex()[npc]
  local watched=self.WatchUnitLines and self:WatchUnitLines(npc)
  if not wishes and not watched then return nil end
  local lines={}
  for _,w in ipairs(wishes or {}) do lines[#lines+1]=L("Droppt dein Wunschrezept: ")..self:RecipeName(w.key,w.id) end
  for _,l in ipairs(watched or {}) do lines[#lines+1]=l end
  return lines
end
local unitHooked=false
function CP:HookWishTooltips()
  if unitHooked then return end
  unitHooked=true
  local function add(tooltip,guid)
    local lines=CP:WishUnitLines(CP:NpcIDFromGUID(guid))
    if not lines or type(tooltip.AddLine)~="function" then return end
    for _,l in ipairs(lines) do tooltip:AddLine("CraftPilot: "..l,.88,.69,.31) end
  end
  if _G.TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall)=="function" and _G.Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(tooltip,data)
      local guid=data and plain(data.guid)
      if not guid and type(tooltip.GetUnit)=="function" then local _,unit=tooltip:GetUnit();guid=unit and safe(UnitGUID,unit) end
      add(tooltip,guid)
    end)
  elseif _G.GameTooltip and type(GameTooltip.HookScript)=="function" then
    pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetUnit",function(tooltip)
      local _,unit=tooltip:GetUnit();add(tooltip,unit and safe(UnitGUID,unit))
    end)
  end
end

-- AH alarm -----------------------------------------------------------------------------------------------------------
-- After a scan: wished recipes with a fresh AH price, and raid stock cheaper at the AH than crafting. Each item is
-- reported once per day.
function CP:AuctionAlarms()
  local out={}
  if self.db.ui.ahAlarm==false then return out end
  for item,w in pairs(self:WishedRecipeItems()) do
    local p=self:PriceDetails(item)
    if p.auction and p.ageDays~=nil and p.ageDays<=1 then
      out[#out+1]={item=item,kind="recipe",price=p.auction,text=string.format(L("Wunschrezept im AH: %s für %s"),self:RecipeName(w.key,w.id),self:FormatCostMoney(p.auction))}
    end
  end
  for _,row in ipairs(self.RaidStockRows and self:RaidStockRows() or {}) do
    if row.missing>0 and row.ah and row.craft and row.ah<row.craft*0.9 and row.ageDays~=nil and row.ageDays<=1 then
      out[#out+1]={item=row.item,kind="stock",price=row.ah,text=string.format(L("Raid-Vorrat günstig im AH: %s für %s statt %s selbst herstellen"),
        self:ItemName(row.item),self:FormatCostMoney(row.ah),self:FormatCostMoney(row.craft))}
    end
  end
  for _,a in ipairs(self.WatchAlarms and self:WatchAlarms() or {}) do out[#out+1]=a end
  table.sort(out,function(a,b) return a.item<b.item end)
  return out
end
function CP:CheckAuctionAlarms()
  if not self.db then return 0 end
  self.db.alarmSeen=type(self.db.alarmSeen)=="table" and self.db.alarmSeen or {}
  local day,shown=today(),0
  for _,a in ipairs(self:AuctionAlarms()) do
    local marker=a.kind..":"..a.item
    if self.db.alarmSeen[marker]~=day then
      self.db.alarmSeen[marker]=day;shown=shown+1
      if self.CompanionNotice then self:CompanionNotice(a.text) end
      self:Say(a.text)
    end
  end
  return shown
end
function CP:AlarmCards()
  local alarms=self:AuctionAlarms()
  if #alarms==0 then return {} end
  local cards={{sectionHeader=true,title=L("AH-Alarm · aus dem letzten Scan")}}
  for _,a in ipairs(alarms) do cards[#cards+1]={title=a.text,color="gold",tooltipItem=a.item,showMarket=false,metrics=nil} end
  return cards
end

local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","AUCTION_HOUSE_CLOSED"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then
    CP:HookWishTooltips()
    local api=_G.Auctionator and Auctionator.API and Auctionator.API.v1
    if api and type(api.RegisterForDBUpdate)=="function" then
      pcall(api.RegisterForDBUpdate,"CraftPilot",function() CP:OnPriceDataUpdated("auctionator") end)
    end
  elseif event=="AUCTION_HOUSE_CLOSED" and CP.db then
    CP:CheckAuctionAlarms()
  end
end)
