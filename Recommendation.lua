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
  local options=self:Options(key)
  if #options==0 then return nil end
  local best=options[1]
  local step=self:ForwardRouteStep(key)
  if step then for _,entry in ipairs(options) do if entry.id==step.id then best=entry;break end end end
  local advice=self:CraftSuggestion(key,best.id)
  local count=math.max(1,advice.count or 1)
  local cost=self:CostCalculation("recipe",key,best.id,count)
  local missing,parts={},{}
  for _,mat in ipairs(cost.materials) do
    if (mat.missing or 0)>0 then
      missing[#missing+1]={id=mat.id,quantity=mat.missing}
      if #parts<3 then parts[#parts+1]=mat.missing.." "..self:ItemName(mat.id) end
    end
  end
  if #missing>3 then parts[#parts+1]=string.format(L("+%d weitere"),#missing-3) end
  local title=(advice.target or 0)>record.skill
    and string.format(L("Empfehlung: %d× %s bis Skill %d"),count,best.name,advice.target)
    or (L("Empfehlung: ")..best.name)
  local detail
  if #missing==0 then
    detail=L("Alles vorrätig · direkt herstellen")
  else
    detail=L("Fehlt: ")..table.concat(parts,", ").." · "
      ..(cost.cashComplete and (L("ca. ")..self:FormatCostMoney(cost.buy)) or L("Preis unvollständig"))
  end
  local pickups={}
  for _,mat in ipairs(cost.materials) do
    if (mat.alts or 0)>0 and #pickups<2 then pickups[#pickups+1]=self:AltPickupText(mat.id,mat.alts) end
  end
  if #pickups>0 then detail=detail.."  ·  "..L("Von Twinks: ")..table.concat(pickups,", ") end
  for _,offer in ipairs(self:TrainerOffersCached(key)) do
    local saving=offer.comparison and offer.comparison.cashSaving
    if saving and saving>0 then
      detail=detail.."  ·  "..L("Tipp: ")..offer.name..L(" beim Lehrer ist günstiger")
      break
    end
  end
  return {key=key,id=best.id,name=best.name,count=count,title=title,detail=detail,
    missing=#missing,materials=missing}
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
function CP:SearchRecommendation()
  local rec=self.currentRecommendation
  if not rec or #rec.materials==0 then self:Say(L("Keine fehlenden Materialien."));return false end
  local names,seen={},{}
  for _,mat in ipairs(rec.materials) do
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
    local list={};for _,n in ipairs(names) do list[#list+1]=n.quantity.."× "..n.name end
    self:Say(L("Auctionator fehlt · Einkauf: ")..table.concat(list,", "))
    return false
  end
  if auctionHouseOpen() and type(api.MultiSearchExact)=="function" then
    local terms={};for _,n in ipairs(names) do terms[#terms+1]=n.name end
    local ok=pcall(api.MultiSearchExact,"CraftPilot",terms)
    if ok then self:Say(L("Auctionator sucht die fehlenden Materialien."));return true end
  end
  if type(api.CreateShoppingList)=="function" and type(api.ConvertToSearchString)=="function" then
    local terms={}
    for _,n in ipairs(names) do
      local ok,term=pcall(api.ConvertToSearchString,"CraftPilot",{searchString=n.name,isExact=true,quantity=n.quantity})
      if not ok or type(term)~="string" then self:Say(L("Auctionator-Liste konnte nicht erstellt werden."));return false end
      terms[#terms+1]=term
    end
    local ok,result=pcall(api.CreateShoppingList,"CraftPilot","CraftPilot - "..L("Empfehlung"),terms)
    if ok and result~=false then
      self:Say(L("Einkaufsliste „CraftPilot - Empfehlung“ in Auctionator angelegt · am Auktionshaus öffnen."))
      return true
    end
  end
  self:Say(L("Auctionator-Liste konnte nicht erstellt werden."))
  return false
end
