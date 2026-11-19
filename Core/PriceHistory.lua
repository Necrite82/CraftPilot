-- CraftPilot: price provenance and freshness.
-- Uses Auctionator's documented external API v1; no private database tables.
local _,CP=...
local L=CP.L
local function call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,result=pcall(fn,...)
  if ok then return result end
  return nil
end
-- 1.1.0: auction prices from Auctionator, TradeSkillMaster or Auctioneer, each through its own public API.
-- "auto" takes the first that has a price, in that order; a chosen source comes first, the others stay fallbacks.
-- A source that is missing, has no price or throws is skipped quietly.
local function itemLink(id)
  local link
  if C_Item and type(C_Item.GetItemInfo)=="function" then link=select(2,call(C_Item.GetItemInfo,id)) end
  if type(link)~="string" and type(GetItemInfo)=="function" then link=select(2,call(GetItemInfo,id)) end
  return type(link)=="string" and link or ("item:"..id)
end
local function valid(n) return type(n)=="number" and n==n and n~=math.huge and n>0 and n or nil end
CP.PriceSources={
  {key="auctionator",name="Auctionator",get=function(id)
    local api=_G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
    if not api then return nil end
    local price=valid(call(api.GetAuctionPriceByItemID,"CraftPilot",id))
    if not price then return nil end
    local age=call(api.GetAuctionAgeByItemID,"CraftPilot",id)
    if type(age)~="number" or age~=age or age==math.huge or age<0 then age=nil end
    return price,age
  end},
  {key="tsm",name="TradeSkillMaster",get=function(id)
    local api=_G.TSM_API
    if type(api)~="table" or type(api.GetCustomPriceValue)~="function" then return nil end
    return valid(call(api.GetCustomPriceValue,"first(DBMinBuyout, DBRecent, DBMarket)","i:"..id)),nil
  end},
  {key="auctioneer",name="Auctioneer",get=function(id)
    local api=_G.AucAdvanced and _G.AucAdvanced.API
    if type(api)~="table" or type(api.GetMarketValue)~="function" then return nil end
    return valid(call(api.GetMarketValue,itemLink(id))),nil
  end},
}
function CP:AvailablePriceSources()
  local out={}
  for _,s in ipairs(self.PriceSources) do
    local present=(s.key=="auctionator" and _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1)
      or (s.key=="tsm" and type(_G.TSM_API)=="table") or (s.key=="auctioneer" and type(_G.AucAdvanced)=="table")
    if present then out[#out+1]=s end
  end
  return out
end
function CP:PriceSourceName(key)
  return ({auto=L("Automatisch"),auctionator="Auctionator",tsm="TradeSkillMaster",auctioneer="Auctioneer"})[key or "auto"] or L("Automatisch")
end
function CP:PriceSourceDetail()
  local names={}
  for _,s in ipairs(self:AvailablePriceSources()) do
    local age=self.PriceSourceScanTime and self:PriceSourceScanTime(s.key)
    local days=age and math.max(0,math.floor(((type(time)=="function" and time() or age)-age)/86400))
    names[#names+1]=s.name..(days and (days==0 and L(" (Scan heute)") or string.format(L(" (Scan vor %d T.)"),days)) or "")
  end
  local active=self.ActivePriceSource and self:ActivePriceSource()
  return L("Automatisch: Die Quelle mit dem neuesten Scan zählt zuerst, die anderen springen ein, wenn ihr ein Preis fehlt. Eine gewählte Quelle wird immer zuerst gefragt.")
    .."\n"..L("Gefunden: ")..(#names>0 and table.concat(names,", ") or L("keine – Auctionator empfohlen"))
    ..((active and (self.db.ui.priceSource or "auto")=="auto") and ("\n"..L("Automatisch nimmt jetzt: ")..active.name) or "")
end
function CP:AuctionPrice(itemID)
  local pref=self.db and self.db.ui and self.db.ui.priceSource or "auto"
  local order={}
  local base=(pref=="auto" and self.AutoPriceSourceOrder) and self:AutoPriceSourceOrder() or self.PriceSources
  for _,s in ipairs(base) do if s.key==pref then order[#order+1]=s end end
  for _,s in ipairs(base) do if s.key~=pref then order[#order+1]=s end end
  for _,s in ipairs(order) do
    local ok,price,age=pcall(s.get,itemID)
    if ok and price then
      -- 1.3.0: TSM and Auctioneer give no age; CraftPilot's own scan detection estimates it (Core/PriceScan.lua).
      local estimated=false
      if age==nil and self.EstimatedPriceAge then age=self:EstimatedPriceAge(s.key,itemID);estimated=age~=nil end
      return price,age,s.name,estimated
    end
  end
  return nil
end
function CP:PriceDetails(itemID)
  local ah,age,provider,estimated=self:AuctionPrice(itemID)
  local vendor=self:CatalogVendorPrice(itemID)
  local selected=ah
  -- "Auctionator" stays the source name for Auctionator; other providers are named as themselves.
  local source=ah and provider or L("unbekannt")
  if vendor and (not selected or vendor<selected) then
    selected=vendor
    source=L("Haendler")
  end
  local freshness
  if source==L("Haendler") then freshness="vendor"
  elseif not selected then freshness="missing"
  elseif age==nil then freshness="unknown"
  elseif age>7 then freshness="stale"
  elseif age>3 then freshness="aging"
  else freshness="fresh" end
  return {price=selected,auction=ah,vendor=vendor,ageDays=age,ageEstimated=estimated or nil,
    source=source,provider=provider,freshness=freshness}
end

function CP:PriceFreshness(itemID)
  local p=self:PriceDetails(itemID)
  local label
  if p.freshness=="fresh" then label=L("AH aktuell (")..p.ageDays..L(" T.)")
  elseif p.freshness=="aging" then label="AH "..p.ageDays..L(" T. alt")
  elseif p.freshness=="stale" then label=L("AH VERALTET (")..p.ageDays..L(" T.)")
  elseif p.freshness=="unknown" then label=L("AH Alter unbekannt")
  elseif p.freshness=="vendor" then label=L("Haendlerpreis")
  else label=L("Kein Preis") end
  return label,p
end

function CP:PriceSummary(items)
  local n,stale,unknown,missing=0,0,0,0
  for _,item in ipairs(items or {}) do
    local id=type(item)=="table" and item.id or item
    if type(id)=="number" then
      n=n+1
      local p=self:PriceDetails(id)
      if p.freshness=="stale" or p.freshness=="aging" then stale=stale+1 end
      if p.freshness=="unknown" then unknown=unknown+1 end
      if p.freshness=="missing" then missing=missing+1 end
    end
  end
  return {items=n,stale=stale,unknown=unknown,missing=missing}
end

-- When Auctionator's price database last changed: our own note from its update callback, or Auctionator's
-- record of its last full scan.
function CP:LastAuctionScan()
  -- 1.3.0: the newest data of any price source.
  local newest
  if self.PriceSourceScanTime then
    for _,s in ipairs(self:AvailablePriceSources()) do
      local at=self:PriceSourceScanTime(s.key)
      if at and (not newest or at>newest) then newest=at end
    end
    if newest then return newest end
  end
  local own=self.db and self.db.ahUpdated
  local saved=_G.Auctionator and _G.Auctionator.SavedState and _G.Auctionator.SavedState.TimeOfLastGetAllScan
  saved=type(saved)=="number" and saved or nil
  if own and saved then return math.max(own,saved) end
  return own or saved
end

function CP:ProfessionPriceStatus(key)
  if #self:AvailablePriceSources()==0 then return L("AH: kein Preis-Addon (Auctionator empfohlen)"),"missing" end
  local seen={}
  for _,recipe in pairs(self.db.recipes[key] or {}) do
    if not recipe.disabled then
      for _,mat in ipairs(recipe.mats or {}) do seen[mat[1]]=true end
    end
  end
  local n,old,unknown,missing,vendors=0,0,0,0,0
  for id in pairs(seen) do
    n=n+1
    local p=self:PriceDetails(id)
    if p.auction then
      if p.ageDays==nil then unknown=unknown+1
      elseif p.ageDays>3 then old=old+1 end
    elseif p.vendor then vendors=vendors+1
    else missing=missing+1 end
  end
  if n==0 then return L("AH: noch keine Materialdaten"),"unknown" end
  -- After a scan within the last day, a material without any price simply isn't offered at the AH right now
  -- (bound items, rare drops, vendor-only goods): that isn't something a new scan can fix.
  local scanned=self:LastAuctionScan()
  local recent=scanned and type(time)=="function" and time()-scanned<86400
  local notListed=0
  if recent then notListed,missing=missing,0 end
  local issues={}
  if missing>0 then issues[#issues+1]=missing..L(" fehlen") end
  if old>0 then issues[#issues+1]=old..L(" älter als 3 T.") end
  if unknown>0 then issues[#issues+1]=unknown..L(" ohne Datum") end
  if #issues>0 then return L("AH: ")..table.concat(issues," · "),"warning" end
  if vendors==n then return L("AH: nur Händlerpreise benötigt"),"vendor" end
  if notListed>0 then
    return string.format(L("AH: %d Materialien aktuell, %d derzeit nicht im AH"),n-vendors-notListed,notListed),"fresh"
  end
  return string.format(L("AH: %d Materialien aktuell"),n-vendors),"fresh"
end
