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
function CP:PriceDetails(itemID)
  local api=_G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
  local ah=api and call(api.GetAuctionPriceByItemID,"CraftPilot",itemID)
  if type(ah)~="number" or ah<=0 then ah=nil end
  local age=api and call(api.GetAuctionAgeByItemID,"CraftPilot",itemID)
  if type(age)~="number" or age<0 then age=nil end
  local vendor=self:CatalogVendorPrice(itemID)
  local selected=ah
  local source=ah and "Auctionator" or L("unbekannt")
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
  return {price=selected,auction=ah,vendor=vendor,ageDays=age,
    source=source,freshness=freshness}
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
