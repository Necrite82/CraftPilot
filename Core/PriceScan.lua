-- 1.3.0: which auction addon is actually used, and how old its prices are.
-- Auctionator reports the age of each price itself. TradeSkillMaster and Auctioneer do not, so CraftPilot watches
-- the prices of the items it cares about (path materials, wishlist, watchlist, raid stock): when they change after
-- an auction house visit or at login (TSM app data), that source has new data. Many changes at once count as a full
-- scan for all items, a few as new prices for just those items. "Automatisch" then asks the source with the newest
-- data first. Display and ordering only; nothing is read from private addon tables.
local _,CP=...
local L=CP.L
local DAY=86400
local FULL_MIN,FULL_SHARE,SAMPLE_MAX=5,0.2,300
local function now() return type(time)=="function" and time() or 0 end

local function store(self)
  -- Hot path (every price lookup): the realm's table is looked up once per session.
  if self.priceSeenStore then return self.priceSeenStore end
  local root=self.account or self.db
  if not root then return nil end
  root.priceSeen=type(root.priceSeen)=="table" and root.priceSeen or {}
  local me=self.CurrentCharacter and self:CurrentCharacter()
  local realm=(me and me.realm) or "?"
  root.priceSeen[realm]=root.priceSeen[realm] or {}
  if me then self.priceSeenStore=root.priceSeen[realm] end
  return root.priceSeen[realm]
end
local function sourceStore(self,key)
  local s=store(self);if not s then return nil end
  s[key]=type(s[key])=="table" and s[key] or {items={}}
  s[key].items=type(s[key].items)=="table" and s[key].items or {}
  return s[key]
end

-- Items whose prices are watched: what CraftPilot actually shows prices for.
function CP:PriceSampleItems()
  local set,list={},{}
  local function add(id) if type(id)=="number" and not set[id] and #list<SAMPLE_MAX then set[id]=true;list[#list+1]=id end end
  for _,path in pairs(self.lastPathByKey or {}) do for id in pairs(path.quantities or {}) do add(id) end end
  for id in pairs(self.WishedRecipeItems and self:WishedRecipeItems() or {}) do add(id) end
  for id in pairs(self.ItemWatch and self:ItemWatch() or {}) do add(id) end
  for _,row in ipairs(self.RaidStockRows and self:RaidStockRows() or {}) do add(row.item) end
  return list
end

-- Compares current prices of each source without its own age with the last snapshot. Returns the keys of the
-- sources that have new data.
function CP:DetectPriceScans()
  local updated={}
  local items=self:PriceSampleItems()
  if #items==0 then return updated end
  local t=now()
  for _,s in ipairs(self:AvailablePriceSources()) do
    if s.key~="auctionator" then
      local st=sourceStore(self,s.key)
      if st then
        local changed,priced,first={},0,not next(st.items)
        for _,id in ipairs(items) do
          local ok,price=pcall(s.get,id)
          if ok and price then
            priced=priced+1
            local seen=st.items[id]
            if not seen then st.items[id]={p=price}
            elseif seen.p~=price then seen.p=price;changed[#changed+1]=id end
          end
        end
        if not first and #changed>0 then
          if #changed>=FULL_MIN and #changed>=priced*FULL_SHARE then st.at=t
          else for _,id in ipairs(changed) do st.items[id].at=t end end
          updated[#updated+1]=s.key
        end
      end
    end
  end
  return updated
end

-- Time of the newest data of a source (for one item, or overall).
function CP:PriceSourceScanTime(key,item)
  if key=="auctionator" then
    local own=self.db and self.db.auctionatorUpdated
    local saved=_G.Auctionator and _G.Auctionator.SavedState and _G.Auctionator.SavedState.TimeOfLastGetAllScan
    saved=type(saved)=="number" and saved or nil
    if own and saved then return math.max(own,saved) end
    return own or saved
  end
  local st=sourceStore(self,key)
  if not st then return nil end
  local at=st.at
  if item then
    local seen=st.items[item]
    if seen and seen.at and (not at or seen.at>at) then at=seen.at end
  else
    for _,seen in pairs(st.items) do if seen.at and (not at or seen.at>at) then at=seen.at end end
  end
  return at
end
-- Estimated age in days of a price from a source without its own age; nil if no scan was seen yet.
function CP:EstimatedPriceAge(key,item)
  local at=self:PriceSourceScanTime(key,item)
  if not at then return nil end
  return math.max(0,math.floor((now()-at)/DAY))
end

-- Order for "Automatisch": the source with the newest data first, sources never seen scanning in the usual order.
function CP:AutoPriceSourceOrder()
  -- Cached for a minute and dropped whenever new price data arrives.
  local t=now()
  if self.priceOrderCache and t-self.priceOrderCache.at<60 then return self.priceOrderCache.list end
  local list,rank={},{}
  for i,s in ipairs(self.PriceSources) do list[#list+1]=s;rank[s.key]=i end
  local times={}
  for _,s in ipairs(list) do times[s.key]=self:PriceSourceScanTime(s.key) or -1 end
  table.sort(list,function(a,b)
    if times[a.key]~=times[b.key] then return times[a.key]>times[b.key] end
    return rank[a.key]<rank[b.key]
  end)
  self.priceOrderCache={at=t,list=list}
  return list
end
function CP:ActivePriceSource()
  for _,s in ipairs(self:AutoPriceSourceOrder()) do
    for _,a in ipairs(self:AvailablePriceSources()) do if a.key==s.key then return s end end
  end
  return nil
end

-- New prices from any source: alarms, "after the scan" and caches, the same for every addon.
function CP:OnPriceDataUpdated(key)
  if not self.db then return end
  self.tooltipCache=nil;self.pathCache=nil;self.priceOrderCache=nil
  self.db.ahUpdated=now()
  if key=="auctionator" then self.db.auctionatorUpdated=self.db.ahUpdated end
  if self.CheckAuctionAlarms then pcall(self.CheckAuctionAlarms,self) end
  if self.ComparePathAfterScan then pcall(self.ComparePathAfterScan,self) end
  if self.frame and type(self.frame.IsShown)=="function" and self.frame:IsShown() and self.Render then self:Render() end
end
function CP:CheckPriceScans()
  local updated=self:DetectPriceScans()
  if #updated>0 then self:OnPriceDataUpdated(updated[1]) end
  return updated
end

local function later(seconds,fn)
  if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(seconds,fn) else fn() end
end
if type(CreateFrame)=="function" then
  local frame=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_LOGIN","AUCTION_HOUSE_CLOSED"}) do pcall(frame.RegisterEvent,frame,event) end
  frame:SetScript("OnEvent",function(_,event)
    if not CP.db then return end
    -- At login the paths are not computed yet; TSM's app data is also in place only after a moment.
    later(event=="PLAYER_LOGIN" and 20 or 2,function() pcall(CP.CheckPriceScans,CP) end)
  end)
end
