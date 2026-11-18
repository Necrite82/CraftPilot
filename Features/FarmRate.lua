-- 1.1.0: farm or buy, by your own pace. While you gather ores and herbs CraftPilot measures how many you get per
-- hour and where: the time between two gathers (at most five minutes apart) counts for the item gathered. With that
-- the plan can say what farming a missing material saves per hour of your time, next to its AH price.
local _,CP=...
local L=CP.L
local GAP=300
local MIN_SECONDS=600

local function now() return type(time)=="function" and time() or 0 end
local function root(self)
  local r=self.account or self.db
  if not r then return nil end
  r.farmRate=r.farmRate or {}
  return r.farmRate
end

function CP:CurrentMapID()
  if C_Map and type(C_Map.GetBestMapForUnit)=="function" then
    local ok,map=pcall(C_Map.GetBestMapForUnit,"player")
    if ok and type(map)=="number" then return map end
  end
  return 0
end

-- One gather: count the items, and the time since the previous gather if it was recent.
function CP:RecordGather(item,count,map,at)
  if not (self.GatheringItems and self.GatheringItems[item]) then return false end
  local rates=root(self);if not rates then return false end
  at=at or now();map=map or self:CurrentMapID()
  local last=self.lastGatherAt
  self.lastGatherAt=at
  rates[item]=rates[item] or {}
  local z=rates[item][map] or {items=0,seconds=0}
  rates[item][map]=z
  z.items=z.items+(count or 1)
  if last and at-last>0 and at-last<=GAP then z.seconds=z.seconds+(at-last) end
  return true
end

-- Best measured zone for an item: items per hour, or nil while less than ten minutes are measured.
function CP:FarmPace(item)
  local rates=root(self)
  local best
  for map,z in pairs(rates and rates[item] or {}) do
    if z.seconds>=MIN_SECONDS then
      local perHour=z.items/z.seconds*3600
      if not best or perHour>best.perHour then best={map=map,perHour=perHour,items=z.items,seconds=z.seconds} end
    end
  end
  return best
end

-- Farm or buy for a missing amount: minutes needed at your pace and what that saves per hour against the AH.
function CP:FarmOrBuy(item,need)
  local pace=self:FarmPace(item)
  if not pace or need<=0 then return nil end
  local p=self:PriceDetails(item)
  local price=p.price
  local minutes=math.ceil(need/pace.perHour*60)
  local out={pace=pace,minutes=minutes,price=price}
  if price then
    out.buy=price*need
    out.perHour=math.floor(price*pace.perHour)
  end
  return out
end

function CP:FarmOrBuyText(item,need)
  local f=self:FarmOrBuy(item,need)
  if not f then return nil end
  local text=string.format(L("Dein Tempo: ca. %d/Std in %s · %d Stück in ca. %d Min."),math.floor(f.pace.perHour+.5),self:ZoneName(f.pace.map),need,f.minutes)
  if f.buy then
    text=text.." "..string.format(L("Kaufen: %s · Farmen spart dir ca. %s pro Stunde."),self:FormatCostMoney(f.buy),self:FormatCostMoney(f.perHour))
  end
  return text,f
end

-- "You receive loot: [Mithril Ore]x3." -> item, count; only own loot.
local selfPatterns
local function lootPatterns()
  if selfPatterns then return selfPatterns end
  selfPatterns={}
  for _,fmt in ipairs({_G.LOOT_ITEM_SELF_MULTIPLE,_G.LOOT_ITEM_PUSHED_SELF_MULTIPLE,_G.LOOT_ITEM_SELF,_G.LOOT_ITEM_PUSHED_SELF}) do
    if type(fmt)=="string" then
      local pat=fmt:gsub("%%","%%%%"):gsub("([%(%)%.%+%-%*%?%[%]%^%$])","%%%1"):gsub("%%%%s","(.+)"):gsub("%%%%d","(%%d+)")
      selfPatterns[#selfPatterns+1]="^"..pat.."$"
    end
  end
  return selfPatterns
end
function CP:ParseOwnLoot(text)
  if type(text)~="string" then return nil end
  for _,pat in ipairs(lootPatterns()) do
    local link,count=text:match(pat)
    if link then
      local id=tonumber(link:match("item:(%d+)"))
      if id then return id,tonumber(count) or 1 end
    end
  end
  return nil
end

local events=CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_LOOT")
events:SetScript("OnEvent",function(_,_,text)
  if not CP.db then return end
  local item,count=CP:ParseOwnLoot(text)
  if item then CP:RecordGather(item,count) end
end)
