-- The single recommended next step for the "Jetzt" tab and the auction-house search for its materials.
-- Read-only advice: nothing is bought, learned or crafted automatically.
local _,CP=...
local L=CP.L

-- Best current option: the saved route's step when one is planned, otherwise the cheapest learned recipe
-- by the normal ranking (unknown prices last, reliable colors first when that setting is on).
function CP:Recommendation(key)
  local prof=self.Data.professions[key]
  local record=self.db and self.db.professions[key]
  if not prof or not record or (prof.gathering and not prof.crafting) then return nil end
  local captured=self.db.lastCapture
  if not (captured and captured.key==key and captured.skill==record.skill) then return nil end
  -- First choice: the first step of the cheapest path to the training cap (AH prices, color chances,
  -- fees once). Fallback without prices: the best learned option by the usual ranking.
  local path=self.CheapestPath and self:CheapestPath(key)
  local first=path and path.segments[1]
  local best,count,target,learn
  -- 1.3.0: your active plan (a saved route that covers the current skill) comes first; the cheapest path is
  -- offered next to it. Either way it is a suggestion: the player switches with one click (ui.recSource[key]).
  local planStep=self.ForwardRouteStep and self:ForwardRouteStep(key)
  if planStep then
    local native=(self.db.recipes[key] or {})[planStep.id]
    if not (native and native.learned) then planStep=nil end
  end
  self.db.ui.recSource=type(self.db.ui.recSource)=="table" and self.db.ui.recSource or {}
  local choice=self.db.ui.recSource[key]
  local source="cheapest"
  local alternative
  if planStep and first and planStep.id~=first.id then
    if choice~="cheapest" then
      source="plan"
      alternative={source="cheapest",id=first.id,name=first.name}
    else
      alternative={source="plan",id=planStep.id,name=planStep.name or self:RecipeName(key,planStep.id)}
    end
    local now=path.perPointNow or {}
    local a,b=now[planStep.id],now[first.id]
    if a and b then alternative.perPointGap=a-b end   -- > 0: the cheapest path saves this per point
  elseif planStep and not first then
    source="plan"
  end
  if source=="plan" then
    best={id=planStep.id,name=planStep.name or self:RecipeName(key,planStep.id)}
    local advice=self:CraftSuggestion(key,best.id)
    count,target=math.max(1,advice.count or 1),advice.target or planStep.last
  elseif first then
    best={id=first.id,name=first.name}
    count,target=first.crafts,first.last
    if not first.learned then learn=first end
  else
    local options=self:Options(key)
    if #options==0 then return nil end
    best=options[1]
    local step=self:ForwardRouteStep(key)
    if step then for _,entry in ipairs(options) do if entry.id==step.id then best=entry;break end end end
    local advice=self:CraftSuggestion(key,best.id)
    count,target=math.max(1,advice.count or 1),advice.target
  end
  local cost=self:CostCalculation("recipe",key,best.id,count)
  local missing,parts={},{}
  for _,mat in ipairs(cost.materials) do
    if (mat.missing or 0)>0 then
      -- quantity = still missing (after stock); required = the whole need, for callers that subtract stock themselves.
      missing[#missing+1]={id=mat.id,quantity=mat.missing,required=mat.quantity}
      if #parts<3 then parts[#parts+1]=mat.missing.." "..self:ItemName(mat.id) end
    end
  end
  if #missing>3 then parts[#parts+1]=string.format(L("+%d weitere"),#missing-3) end
  local title=(target or 0)>record.skill
    and string.format(L("Empfehlung: %d× %s · etwa bis Skill %d"),count,best.name,target)
    or (L("Empfehlung: ")..best.name)
  if learn then
    title=(learn.source=="ah" and L("Erst im AH kaufen: ") or L("Erst lernen: "))..best.name..(learn.fee>0 and (" ("..self:FormatCostMoney(learn.fee)..")") or "")
      .." · "..string.format(L("dann ca. %d× bis Skill %d"),count,target)
  end
  local detail
  local inBags=true
  for _,mat in ipairs(cost.materials) do if (mat.bag or 0)<(mat.quantity or 0) then inBags=false end end
  if #missing==0 and not inBags then
    detail=L("Vorrätig · erst aus Bank/von Twinks holen")
  elseif #missing==0 then
    detail=L("Alles in der Tasche · direkt herstellen")
  else
    detail=L("Fehlt: ")..table.concat(parts,", ").." · "
      ..(cost.cashComplete and (L("Zukauf ca. ")..self:FormatCostMoney(cost.buy)) or L("Preis unvollständig"))
  end
  local pickups,fromAlts={},{}
  for _,mat in ipairs(cost.materials) do if (mat.alts or 0)>0 then fromAlts[#fromAlts+1]={id=mat.id,count=mat.alts} end end
  for _,mat in ipairs(cost.materials) do
    if (mat.alts or 0)>0 and #pickups<2 then pickups[#pickups+1]=self:AltPickupText(mat.id,mat.alts) end
  end
  local extras={}
  -- 1.3.0: what the last scan changed, for ten minutes.
  local change=self.lastPathChange
  if change and change.key==key and (type(time)=="function" and time() or 0)-(change.at or 0)<600 then extras[#extras+1]=change.text end
  local projectText=self.ProjectNextText and self:ProjectNextText()
  if projectText then extras[#extras+1]=projectText end
  if alternative and alternative.source=="cheapest" and (alternative.perPointGap or 0)>0 then
    extras[#extras+1]=string.format(L("Günstiger: %s · spart ca. %s je Punkt"),alternative.name,self:FormatCostMoney(math.floor(alternative.perPointGap)))
  elseif alternative and alternative.source=="plan" then
    extras[#extras+1]=string.format(L("Dein Plan: %s"),alternative.name)
  end
  local raw=self.RawMaterialHints and self:RawMaterialHints(cost.materials,1) or {}
  if #raw>0 then extras[#extras+1]=L("Selbst herstellen: ")..raw[1]
  else
    local second=self.SecondProfessionOptions and self:SecondProfessionOptions(key)[1]
    if second then extras[#extras+1]=L("Zweiter Beruf: ")..self:SecondProfessionText(second) end
  end
  local deal=self.BuyTimingDeals and self:BuyTimingDeals(key,1)[1]
  if deal then extras[#extras+1]="|cff8fd6a6"..L("Jetzt günstig: ")..self:BuyTimingText(deal).."|r" end
  if #pickups>0 then extras[#extras+1]=L("Von Twinks: ")..table.concat(pickups,", ") end
  -- Saving tip: a recipe (perhaps still to learn) that is much cheaper per point right now than the pick,
  -- e.g. a green one the "reliable" setting passes over.
  local tip
  if first and path and path.perPointNow then
    local mine=path.perPointNow[first.id]
    for _,o in ipairs(path.optionsNow or {}) do
      if o.id~=first.id and mine and o.perPoint<mine*0.6 then tip=o;break end
      if o.id==first.id then break end
    end
  end
  -- Second line: twink pickups, saving tip and the whole way, so the first line (what is missing) stays readable.
  if tip then
    extras[#extras+1]=string.format(L("Spartipp: %s%s · ca. %s statt %s je Punkt"),tip.name,tip.learned and "" or L(" (lernen)"),
      self:CompactMoney(tip.perPoint),self:CompactMoney(path.perPointNow[first.id]))
  end
  if path and #path.segments>0 then
    extras[#extras+1]=string.format(L("Ganzer Weg bis %d: ca. %s"),path.reached,self:FormatCostMoney(path.total))
  elseif not first then
    for _,offer in ipairs(self:TrainerOffersCached(key)) do
      local saving=offer.comparison and offer.comparison.cashSaving
      if saving and saving>0 then
        extras[#extras+1]=L("Tipp: ")..offer.name..L(" beim Lehrer ist günstiger")
        break
      end
    end
  end
  local gate=self.RankGate and self:RankGate(key)
  if gate and not gate.levelOk and record.skill>=(record.cap or 0)-10 then detail=gate.text.."  ·  "..detail end
  -- The banner has room for two hints; the companion shows them all (allExtra). Order is priority: twinks,
  -- making it yourself, cheap now, saving tip, whole way (the budget strip names the whole way too).
  local order={}
  for _,prefix in ipairs({L("Nach dem Scan: neue Route "),L("Projekt „"),L("Günstiger: "),L("Dein Plan: "),L("Von Twinks: "),L("Selbst herstellen: "),L("Zweiter Beruf: "),"|cff8fd6a6"..L("Jetzt günstig: "),L("Spartipp: "),L("Tipp: ")}) do
    for i=#extras,1,-1 do
      if extras[i]:sub(1,#prefix)==prefix then order[#order+1]=table.remove(extras,i) end
    end
  end
  for _,e in ipairs(extras) do order[#order+1]=e end
  local allExtra=#order>0 and table.concat(order,"  ·  ") or nil
  local extra=#order>0 and table.concat({order[1],order[2]},"  ·  ") or nil
  return {key=key,id=best.id,name=best.name,count=count,target=target,title=title,detail=detail,extra=extra,allExtra=allExtra,extraParts=order,tip=tip,source=source,alternative=alternative,buy=cost.buy,buyComplete=cost.cashComplete,fromAlts=fromAlts,
    missing=#missing,materials=missing,inBags=inBags,path=path,learn=learn,prices=path and self:PriceSummary(path.priceItems or {})}
end

-- Trainer offers compare costs per recipe; compute them once per render.
function CP:TrainerOffersCached(key)
  local cache=self.trainerOfferCache
  if not cache or cache.key~=key then cache={key=key,list=self:TrainerRecipeOptions(key)};self.trainerOfferCache=cache end
  return cache.list
end

-- The "je Punkt" column: per expected skill point, including a one-time training fee where it applies.
function CP:ListCostText(entry)
  if entry.referenceOnly then return "—" end
  if entry.trainerRecipe then
    local c=entry.comparison
    if c and c.cost and c.cost.cashComplete and (c.points or 0)>0 then return self:CompactMoney(c.cost.cash/c.points) end
    return "?"
  end
  if entry.vendorRecipe then return "—" end
  if entry.unknown then return "?" end
  if (entry.cost or 0)<=0 then return L("vorrätig") end
  return self:CompactMoney(entry.cost)
end

local function auctionHouseOpen()
  for _,name in ipairs({"AuctionHouseFrame","AuctionFrame"}) do
    local f=_G[name]
    if type(f)=="table" and type(f.IsShown)=="function" and f:IsShown() then return true end
  end
  return false
end

-- Search the missing materials of the recommendation. At an open auction house Auctionator searches
-- them at once; elsewhere they become an Auctionator shopping list to open there later.
function CP:AuctionHouseOpen() return auctionHouseOpen() end
function CP:SearchRecommendation()
  local rec=self.currentRecommendation
  if not rec or #rec.materials==0 then self:Say(L("Keine fehlenden Materialien."));return false end
  return self:SearchItems(rec.materials,L("Empfehlung"),L("Auctionator sucht die fehlenden Materialien."))
end

-- Search items ({id, quantity}) at an open auction house, or keep them as an Auctionator shopping list.
function CP:SearchItems(items,listTitle,searching)
  local names,seen={},{}
  for _,mat in ipairs(items) do
    local name=self:ItemName(mat.id)
    if name=="Item #"..mat.id or seen[name] then
      if self.MarketItemData then self:MarketItemData(mat.id) end
      self:Say(L("Gegenstandsname fehlt noch · gleich erneut versuchen."))
      return false
    end
    seen[name]=true
    names[#names+1]={name=name,quantity=mat.quantity}
  end
  local api=_G.Auctionator and Auctionator.API and Auctionator.API.v1
  if not api then
    local list={};for _,n in ipairs(names) do list[#list+1]=(n.quantity or 1).."× "..n.name end
    self:Say(L("Auctionator fehlt · Einkauf: ")..table.concat(list,", "))
    return false
  end
  if auctionHouseOpen() and type(api.MultiSearchExact)=="function" then
    local terms={};for _,n in ipairs(names) do terms[#terms+1]=n.name end
    local ok=pcall(api.MultiSearchExact,"CraftPilot",terms)
    if ok then self:Say(searching or L("Auctionator sucht die fehlenden Materialien."));return true end
  end
  if type(api.CreateShoppingList)=="function" and type(api.ConvertToSearchString)=="function" then
    local terms={}
    for _,n in ipairs(names) do
      local ok,term=pcall(api.ConvertToSearchString,"CraftPilot",{searchString=n.name,isExact=true,quantity=n.quantity or 1})
      if not ok or type(term)~="string" then self:Say(L("Auctionator-Liste konnte nicht erstellt werden."));return false end
      terms[#terms+1]=term
    end
    local ok,result=pcall(api.CreateShoppingList,"CraftPilot","CraftPilot - "..listTitle,terms)
    if ok and result~=false then
      self:Say(string.format(L("Einkaufsliste „CraftPilot - %s“ in Auctionator angelegt · am Auktionshaus öffnen."),listTitle))
      return true
    end
  end
  self:Say(L("Auctionator-Liste konnte nicht erstellt werden."))
  return false
end
