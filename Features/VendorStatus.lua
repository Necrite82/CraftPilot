-- 1.3.0: vendor recipes with a visit status. At a merchant CraftPilot notes which recipes from its catalog are on
-- offer, how many (limited stock), sold out, or not offered at all – with the date. Nothing is guessed: no restock
-- times, only what was seen. Learning tour and learn targets use it: a vendor seen sold out is skipped in favour of
-- another vendor or the AH, and the stop says when it was seen.
local _,CP=...
local L=CP.L

local function now() return type(time)=="function" and time() or 0 end
local function store(self)
  local root=self.account or self.db
  if not root then return nil end
  root.vendorSeen=type(root.vendorSeen)=="table" and root.vendorSeen or {}
  return root.vendorSeen
end

-- recipe item -> {key,id} over all catalogs, once.
-- and npc -> recipe items the catalog says it sells.
local itemIndex,byNpc
local function recipeItems()
  if itemIndex then return itemIndex,byNpc end
  itemIndex,byNpc={},{}
  for key,data in pairs(CP.CatalogData or {}) do
    if type(data)=="table" and type(data.recipes)=="table" then
      for id,r in pairs(data.recipes) do
        if type(r)=="table" and type(r.item)=="number" then
          itemIndex[r.item]={key=key,id=id}
          for _,src in ipairs(r.get or {}) do
            if src.kind=="vendor" and type(src.npc)=="number" then
              byNpc[src.npc]=byNpc[src.npc] or {};byNpc[src.npc][r.item]=true
            end
          end
        end
      end
    end
  end
  return itemIndex,byNpc
end
function CP:ResetVendorStatusIndex() itemIndex,byNpc=nil,nil end

-- seen[npc][recipeItem] = {at, state = "offered" | "soldout" | "missing", left = n (limited stock)}
function CP:RecordMerchantRecipes(npc,offers)
  local s=store(self);if not s or type(npc)~="number" then return 0 end
  local entry=s[npc] or {};s[npc]=entry
  local at,n=now(),0
  local offered={}
  for _,o in ipairs(offers or {}) do
    if recipeItems()[o.item] then
      offered[o.item]=true;n=n+1
      local state=(o.available==0) and "soldout" or "offered"
      entry[o.item]={at=at,state=state,left=(o.available and o.available>0) and o.available or nil}
    end
  end
  -- Recipes the catalog lists for this vendor that are not in the window at all.
  local _,npcs=recipeItems()
  for item in pairs(npcs[npc] or {}) do
    if not offered[item] then entry[item]={at=at,state="missing"} end
  end
  return n
end

function CP:VendorRecipeStatus(npc,item)
  local s=store(self)
  return s and s[npc] and s[npc][item] or nil
end

function CP:VendorStatusText(status)
  if not status then return nil end
  local day=type(date)=="function" and date("%d.%m.",status.at) or ""
  if status.state=="soldout" then return string.format(L("ausverkauft (gesehen %s)"),day) end
  if status.state=="missing" then return string.format(L("nicht im Angebot (gesehen %s)"),day) end
  if status.left then return string.format(L("noch %d vorrätig (gesehen %s)"),status.left,day) end
  return string.format(L("im Angebot (gesehen %s)"),day)
end

-- Is this vendor worth the trip for the recipe? false when it was last seen sold out or without it.
function CP:VendorLooksAvailable(npc,item)
  local st=self:VendorRecipeStatus(npc,item)
  return not st or st.state=="offered"
end

local function scanMerchant()
  if not CP.db then return end
  local guid=type(UnitGUID)=="function" and UnitGUID("npc")
  local npc=type(guid)=="string" and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
  if not npc then return end
  local offers={}
  local n=type(GetMerchantNumItems)=="function" and GetMerchantNumItems() or 0
  for i=1,n do
    local item=type(GetMerchantItemID)=="function" and GetMerchantItemID(i)
    if not item and type(GetMerchantItemLink)=="function" then
      local link=GetMerchantItemLink(i);item=type(link)=="string" and tonumber(link:match("item:(%d+)"))
    end
    if item then
      local available
      if type(GetMerchantItemInfo)=="function" then available=select(5,GetMerchantItemInfo(i)) end
      offers[#offers+1]={item=item,available=type(available)=="number" and available>=0 and available or nil}
    end
  end
  CP:RecordMerchantRecipes(npc,offers)
end

local events=CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_UPDATE")
events:SetScript("OnEvent",function() pcall(scanMerchant) end)
