-- 0.2: "Endgame" (0.2.0: "Nach 300") – what a profession earns once the skilling is done. Profit per recipe from the saved
-- auction prices, Merchant's Favor recipes and what they are worth. Read-only: nothing is bought or sold.
--
-- Own or farmed materials are never free here: they are valued at what selling them would bring (AH minus
-- the cut, or the vendor price, whichever is higher). That is the honest comparison between "craft it" and
-- "sell the materials".
local _,CP=...
local L=CP.L

local function money(self,value)
  if type(value)~="number" then return L("unbekannt") end
  local sign=value<0 and "-" or "+"
  return sign..self:FormatCostMoney(math.abs(value))
end

local function recipeMaterials(native,recipe)
  local out={}
  if native and type(native.mats)=="table" and #native.mats>0 then
    for _,mat in ipairs(native.mats) do
      if type(mat[1])=="number" and type(mat[2])=="number" then out[mat[1]]=(out[mat[1]] or 0)+mat[2] end
    end
  else
    for item,n in pairs(recipe and recipe.mats or {}) do if type(n)=="number" then out[item]=n end end
  end
  return out
end

-- Profit of one craft: {output, made, sale, buy, own, profitBuy, profitOwn, missing, stale}.
--   buy  = every material at its purchase price (AH or vendor, the cheaper one)
--   own  = every material at what selling it would bring (opportunity value of own or farmed stock)
--   sale = what the result sells for (AH net of the cut, or vendor price)
function CP:RecipeProfit(key,id)
  local native=(self.db.recipes[key] or {})[id]
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local output=self:RecipeMarketOutput(key,id)
  if type(output)~="number" then return nil end
  local made=math.max(1,(recipe and (recipe.count or recipe.yield)) or 1)
  local result={key=key,id=id,output=output,made=made,buy=0,own=0,missing=0,stale=0}
  local mats=recipeMaterials(native,recipe)
  if not next(mats) then return nil end
  for item,n in pairs(mats) do
    local p=self:PriceDetails(item)
    if p.price then result.buy=result.buy+p.price*n else result.missing=result.missing+1 end
    if p.freshness=="stale" or p.freshness=="unknown" then result.stale=result.stale+1 end
    result.own=result.own+self:ItemSaleValue(item)*n
  end
  local m=self:ItemMarket(output)
  result.bound=m.bound
  result.sale=self:ItemSaleValue(output)*made
  if result.sale<=0 then result.missing=result.missing+1 end
  local out=self:PriceDetails(output)
  if out.freshness=="stale" or out.freshness=="unknown" then result.stale=result.stale+1 end
  result.profitBuy=result.sale-result.buy
  result.profitOwn=result.sale-result.own
  return result
end

-- Learned recipes of a profession with a complete price picture, best profit first.
function CP:ProfitList(key)
  local rows,incomplete={},0
  for id,native in pairs(self.db.recipes[key] or {}) do
    if native.learned and not native.disabled then
      local r=self:RecipeProfit(key,id)
      if r and r.missing==0 then rows[#rows+1]=r elseif r then incomplete=incomplete+1 end
    end
  end
  table.sort(rows,function(a,b)
    if a.profitBuy~=b.profitBuy then return a.profitBuy>b.profitBuy end
    return a.id<b.id
  end)
  return rows,incomplete
end

-- Recipes this profession can buy with Merchant's Favor and not yet known: {id, name, favor, level, profit}.
function CP:FavorRecipes(key)
  local catalog=self:RecipeVendorCatalog(key)
  local out={}
  for id,recipe in pairs(catalog and catalog.recipes or {}) do
    local native=(self.db.recipes[key] or {})[id]
    if not (native and native.learned) and not recipe.unavailable then
      local favor,level
      for _,source in ipairs(recipe.get or {}) do
        if source.kind=="vendor" and type(source.favor)=="number" and (not favor or source.favor<favor) then favor,level=source.favor,source.favorLevel end
      end
      if favor then
        local profit=self:RecipeProfit(key,id)
        out[#out+1]={id=id,name=self:RecipeName(key,id,recipe.name),favor=favor,level=level,learn=recipe.learn,
          profit=profit and profit.missing==0 and profit.profitBuy or nil,output=profit and profit.output}
      end
    end
  end
  table.sort(out,function(a,b)
    if (a.profit~=nil)~=(b.profit~=nil) then return a.profit~=nil end
    if a.profit and b.profit and a.profit~=b.profit then return a.profit>b.profit end
    return a.id<b.id
  end)
  return out
end

-- 0.2.2: the Endgame page is split into four sub-pages (profit, raid stock, wishlist, Merchant's Favor);
-- without a page every section is returned (tests, older callers).
function CP:EndgameCards(key,page)
  local prof=self.Data.professions[key]
  local cut=tonumber(self.db.ui.economyCut) or 5
  local cards={}
  local function append(list) for _,card in ipairs(list or {}) do cards[#cards+1]=card end end
  local crafting=prof and not (prof.gathering and not prof.crafting)
  if not page or page=="profit" then
    cards[#cards+1]={title=L("Endgame · Gold, Rezepte und Raid-Vorrat"),
      detail=string.format(L("Gewinn je Herstellung nach deinen gespeicherten AH-Preisen, abzüglich %d %% AH-Abzug. Eigene oder gefarmte Materialien zählen mit dem, was ihr Verkauf bringen würde."),cut),
      footer=L("Gespeicherte Scans, keine Live-Angebote · CraftPilot kauft und verkauft nichts."),color="gold",icon=self.Data.professionIcons[key]}
    append(self.AlarmCards and self:AlarmCards())
    if not crafting then
      cards[#cards+1]={title=L("Sammelberuf"),detail=L("Für Sammelberufe gibt es keine Rezepte zum Herstellen. Den Wert deiner Funde zeigt der Gegenstands-Tooltip."),color="blue"}
    else
      append(self:ProfitCards(key))
    end
  end
  if not page or page=="stock" then append(self.RaidStockCards and self:RaidStockCards(key)) end
  if crafting and (not page or page=="wish") then append(self.WishlistCards and self:WishlistCards(key)) end
  if not page or page=="favor" then
    local favor=crafting and self:FavorCards(key) or {}
    if #favor==0 and page=="favor" then
      cards[#cards+1]={title=L("Keine Favor-Rezepte für diesen Beruf"),detail=L("Merchant's Favor gibt es für Rezepte einiger Berufe. Oben links einen anderen Beruf wählen."),color="blue"}
    end
    append(favor)
  end
  if page=="wish" and not crafting then
    cards[#cards+1]={title=L("Sammelberuf"),detail=L("Für Sammelberufe gibt es keine Rezepte zum Herstellen. Den Wert deiner Funde zeigt der Gegenstands-Tooltip."),color="blue"}
  end
  return cards
end

function CP:ProfitCards(key)
  local cards={}
  local hasPrices=_G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
  if not hasPrices then
    cards[#cards+1]={title=L("Keine AH-Preise"),detail=L("Auctionator installieren und einmal am Auktionshaus scannen. Ohne Preise kann CraftPilot keinen Gewinn ausrechnen."),color="red"}
  end
  local rows,incomplete=self:ProfitList(key)
  cards[#cards+1]={sectionHeader=true,title=L("Gewinn je Herstellung · erlernte Rezepte")}
  if #rows==0 then
    cards[#cards+1]={title=L("Noch keine vollständigen Preise"),
      detail=L("Berufsfenster einmal öffnen, damit CraftPilot deine Rezepte kennt, und am Auktionshaus scannen."),color="blue"}
  end
  for i=1,math.min(12,#rows) do
    local r=rows[i]
    local verdict
    if r.profitBuy<=0 and r.profitOwn<=0 then verdict=L("Lohnt sich nicht: Materialien direkt verkaufen bringt mehr.")
    elseif r.profitOwn<=0 then verdict=L("Nur mit gekauften Materialien sinnvoll: eigene Materialien direkt verkaufen bringt mehr.")
    elseif r.profitBuy<=0 then verdict=L("Nur mit eigenen oder gefarmten Materialien sinnvoll; Zukauf lohnt nicht.")
    else verdict=L("Lohnt sich: mit gekauften und mit eigenen Materialien.") end
    if r.bound then verdict=verdict.." "..L("Ergebnis ist gebunden: nur Händlerpreis.") end
    if r.stale>0 then verdict=verdict.." "..L("Einige Preise sind alt · neu scannen.") end
    cards[#cards+1]={title=money(self,r.profitBuy).."  ·  "..self:RecipeName(key,r.id),
      metrics={{label=L("Kaufen & herstellen"),value=money(self,r.profitBuy),color=r.profitBuy>0 and {.55,.9,.7} or {.95,.5,.45}},
        {label=L("Mit eigenen Materialien"),value=money(self,r.profitOwn),color=r.profitOwn>0 and {.55,.9,.7} or {.95,.5,.45}},
        {label=r.made>1 and string.format(L("Verkauf (%d Stück)"),r.made) or L("Verkauf"),value=self:DisplayMoney(r.sale)}},
      footer=verdict,color=r.profitBuy>0 and "green" or (r.profitOwn>0 and "gold" or "red"),
      icon=self.RecipeIcon and self:RecipeIcon(key,r.id),tooltipItem=r.output,showMarket=false}
  end
  if incomplete>0 then
    cards[#cards+1]={title=string.format(L("%d weitere Rezepte ohne vollständige Preise"),incomplete),
      detail=L("Für Material oder Ergebnis fehlt ein AH- oder Händlerpreis. Nach dem nächsten Scan erscheinen sie hier."),color="blue"}
  end
  return cards
end

function CP:FavorCards(key)
  local cards={}
  local favor=self:FavorRecipes(key)
  if #favor==0 then return cards end
  local rate=tonumber(self.db.ui.favorRate) or 0
  cards[#cards+1]={sectionHeader=true,title=L("Merchant's Favor · Rezepte zum Kaufen")}
  cards[#cards+1]={title=L("So rechnet CraftPilot Favor"),
    detail=rate>0 and string.format(L("1 Favor = %s (deine Einstellung). Gewinn je Herstellung zeigt, nach wie vielen Herstellungen sich das Rezept bezahlt macht."),self:FormatCostMoney(rate))
      or L("Ohne Umrechnung nur Favor-Preis und Gewinn je Herstellung. In den Einstellungen unter Erweitert kannst du Silber je Favor festlegen."),
    color="blue",action=rate<=0 and function() CP:OpenTab("settings") end or nil}
  for i=1,math.min(10,#favor) do
    local f=favor[i]
    local detail=string.format(L("Kostet %d Favor"),f.favor)..(f.level and (" · "..L("Favor-Stufe ")..f.level) or "")
      ..(f.learn and (" · "..L("ab Skill ")..f.learn) or "")
    local go=self:RecipeGoTo(key,f.id)
    if go then detail=detail.."\n"..go.label..(go.location.zone and go.location.zone~="" and (" · "..go.location.zone) or "") end
    local foot
    if f.profit and f.profit>0 then
      foot=L("Gewinn je Herstellung: ")..money(self,f.profit)
      if rate>0 then foot=foot.." · "..string.format(L("bezahlt nach %d Herstellungen"),math.ceil(f.favor*rate/f.profit)) end
    elseif f.profit then foot=L("Gewinn je Herstellung: ")..money(self,f.profit).." · "..L("lohnt sich zum Verkaufen nicht")
    else foot=L("Gewinn unbekannt · Preise fehlen") end
    local catalog=self:RecipeVendorCatalog(key)
    local recipe=catalog and catalog.recipes[f.id]
    local left,right=self.RecipeCardActions(self,key,f.id)
    cards[#cards+1]={title=(self:IsWished(key,f.id) and (CP.WISH_MARK or "") or "")..f.name,detail=detail,
      footer=foot,color=(f.profit and f.profit>0) and "green" or "blue",
      icon=self.RecipeIcon and self:RecipeIcon(key,f.id),tooltipItem=recipe and recipe.item,recipeKey=key,recipeID=f.id,showMarket=false,
      action=left,rightAction=right,buttons=self:RecipeButtons(key,f.id)}
  end
  return cards
end
