-- Marks on reserved items in any bag or bank view, a rescue when one is sold anyway and a warning at the
-- auction house. WoW gives addons no way to lock an item against selling, so CraftPilot marks and warns.
--
-- Bag views differ between addons (default bags, EllesmereUI, Baganator, Bagnon, AdiBags, ...). Instead of
-- supporting each one, item buttons are found by what they expose: a bag and slot (GetBagID/GetID, bagID/slotID,
-- bag/slot, GetSlotAndBagID) or an item (GetItemID, itemID, GetItemLink, itemLink, link). Anything shown as a
-- normal item button therefore gets the mark.
local _,CP=...
local L=CP.L

local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c,d=pcall(fn,...)
  if ok then return a,b,c,d end
end
local function clock() return type(GetTime)=="function" and GetTime() or 0 end
-- Newer clients hand some values to addons as "secret": comparing them raises an error. Never touch those.
local function secret(v) return type(issecretvalue)=="function" and issecretvalue(v)==true end
local function plain(v) if v~=nil and not secret(v) then return v end end
local DOT="Interface\\CharacterFrame\\TempPortraitAlphaMask"
local COLORS={keep={.98,.76,.22},plan={.40,.68,1}}

-- Reserved items: kept for a later step (gold) or needed by a plan now (blue).
function CP:ReservedItems()
  local cache=self.reservedCache
  if cache and clock()-cache.at<2 then return cache.items end
  local items={}
  for owner in pairs(self.db and self.db.plans or {}) do
    for id,n in pairs((self:PlanRequirements(owner))) do
      if n>0 then items[id]=items[id] or {kind="plan",need=n} end
    end
    -- Kept for a later step: marked even when there is enough, so it is not sold by mistake.
    for _,e in ipairs(self.KeepList and self:KeepList(owner) or {}) do
      items[e.item]={kind="keep",need=e.need,use=e.uses[1]}
    end
  end
  -- 0.2.1: the raid stock and what it takes to craft it.
  if self.db and self.RaidStockRequirements then
    for id,n in pairs(self:RaidStockRequirements()) do
      if n>0 and not items[id] then items[id]={kind="plan",need=n,raid=true} end
    end
  end
  self.reservedCache={at=clock(),items=items}
  return items
end

local function call(b,name)
  local fn=b[name]
  if type(fn)=="function" then
    local a,c=safe(fn,b)
    return plain(a),plain(c)
  end
end
-- The item a button shows, from whatever the bag addon exposes; nil for anything else.
function CP:ButtonItem(b)
  if type(b)~="table" then return nil end
  local bag,slot
  if type(rawget(b,"GetSlotAndBagID") or b.GetSlotAndBagID)=="function" then slot,bag=call(b,"GetSlotAndBagID") end
  if bag==nil and type(b.GetBagID)=="function" then bag=call(b,"GetBagID");slot=call(b,"GetID") end
  if bag==nil then
    bag=plain(rawget(b,"bagID") or rawget(b,"bag") or rawget(b,"bagId"))
    slot=plain(rawget(b,"slotID") or rawget(b,"slot") or rawget(b,"slotId"))
  end
  if type(bag)=="number" and type(slot)=="number" and slot>0 then
    local id
    if C_Container and type(C_Container.GetContainerItemID)=="function" then id=safe(C_Container.GetContainerItemID,bag,slot)
    elseif type(GetContainerItemID)=="function" then id=safe(GetContainerItemID,bag,slot) end
    id=plain(id)
    if type(id)=="number" then return id end
  end
  local id=plain(rawget(b,"itemID") or rawget(b,"itemId"))
  if type(id)~="number" and type(b.GetItemID)=="function" then id=call(b,"GetItemID") end
  if type(id)=="number" then return id end
  local link=plain(rawget(b,"itemLink") or rawget(b,"link"))
  if type(link)~="string" and type(b.GetItemLink)=="function" then link=call(b,"GetItemLink") end
  if type(link)=="string" then return tonumber(link:match("item:(%d+)")) end
  return nil
end

-- Only what an item button offers is read: no sizes or positions of foreign frames (those can be secret).
-- CraftPilot's own rows (material lists, cards) show items too, but already say what they are for.
local function ownFrame(f)
  local node=f
  for _=1,25 do
    if type(node)~="table" then return false end
    local ok,name=pcall(function() return node:GetName() end)
    if ok and type(name)=="string" and not secret(name) and name:sub(1,10)=="CraftPilot" then return true end
    local okParent,parent=pcall(function() return node:GetParent() end)
    if not okParent or parent==nil or parent==node then return false end
    node=parent
  end
  return false
end
local function looksLikeItemButton(f)
  if type(f)~="table" then return false end
  local ok,isButton=pcall(function() return f:IsObjectType("Button") end)
  if not ok or isButton~=true then return false end
  if ownFrame(f) then return false end
  return type(f.GetBagID)=="function" or type(f.GetSlotAndBagID)=="function" or rawget(f,"bagID")~=nil or rawget(f,"bag")~=nil
    or type(f.GetItemID)=="function" or rawget(f,"itemID")~=nil or rawget(f,"itemLink")~=nil
end

local buttons=setmetatable({},{__mode="k"})
local lastScan=0
-- Collect item buttons once in a while; bag addons create theirs lazily.
function CP:FindItemButtons(force)
  if not force and clock()-lastScan<15 then return buttons end
  lastScan=clock()
  if type(EnumerateFrames)~="function" then return buttons end
  local f=EnumerateFrames()
  local guard=0
  while f and guard<100000 do
    guard=guard+1
    if not buttons[f] and looksLikeItemButton(f) then buttons[f]=true end
    f=EnumerateFrames(f)
  end
  return buttons
end

-- Marks live in CraftPilot's own table, never as a field on another addon's or Blizzard's button.
local marks=setmetatable({},{__mode="k"})
CP.itemMarks=marks
local function mark(b,kind)
  local m=marks[b]
  if not kind then if m then m:Hide() end;return end
  if not m then
    local holder=CreateFrame("Frame",nil,b)
    holder:SetAllPoints(b)
    if type(holder.SetFrameLevel)=="function" and type(b.GetFrameLevel)=="function" then holder:SetFrameLevel((b:GetFrameLevel() or 1)+5) end
    m=holder:CreateTexture(nil,"OVERLAY")
    m:SetSize(10,10);m:SetPoint("TOPLEFT",holder,"TOPLEFT",2,-2)
    m:SetTexture(DOT)
    m.holder=holder
    marks[b]=m
  end
  local c=COLORS[kind]
  m:SetVertexColor(c[1],c[2],c[3],1)
  m.holder:Show();m:Show()
end

function CP:UpdateItemMarks(force)
  if not self.db or self.db.ui.itemMarks==false then
    for b in pairs(buttons) do mark(b,nil) end
    return
  end
  if type(InCombatLockdown)=="function" and InCombatLockdown() then return end
  local reserved=self:ReservedItems()
  for b in pairs(self:FindItemButtons(force)) do
    local visible=true
    if type(b.IsVisible)=="function" then visible=plain(safe(b.IsVisible,b)) end
    if visible then
      local item=self:ButtonItem(b)
      local r=item and reserved[item]
      mark(b,r and r.kind or nil)
    end
  end
end

-- Rescue: reserved items sold at a vendor are offered for buyback right away.
local function bagCounts(self)
  local counts={}
  for id in pairs(self:ReservedItems()) do counts[id]=self:RawItemCount(id,false) end
  return counts
end

function CP:CheckSoldReserved()
  local before=self.merchantCounts
  if not before or not self.db then return end
  local reserved=self:ReservedItems()
  local now=bagCounts(self)
  local sold={}
  for id,n in pairs(before) do
    if reserved[id] and (now[id] or 0)<n then sold[#sold+1]={id=id,count=n-(now[id] or 0),r=reserved[id]} end
  end
  self.merchantCounts=now
  if #sold==0 then return end
  local s=sold[1]
  local use=s.r.raid and (" · "..L("für deinen Raid-Vorrat")) or s.r.use and string.format(L(" · gebraucht für %s ab Skill %d"),s.r.use.name,s.r.use.at) or L(" · für deinen Plan")
  local text=string.format(L("Achtung: %d× %s verkauft"),s.count,self:ItemName(s.id))..use
  if self.CompanionNotice then self:CompanionNotice(text) else self:Say(text) end
  self:ShowBuybackHelper(s.id,text)
end

function CP:BuybackIndex(item)
  local n=safe(GetNumBuybackItems) or 0
  for i=n,1,-1 do
    local link=safe(GetBuybackItemLink,i)
    if type(link)=="string" and tonumber(link:match("item:(%d+)"))==item then return i end
  end
end

function CP:ShowBuybackHelper(item,text)
  local f=self.BuybackHelper
  if not f then
    f=CreateFrame("Frame","CraftPilotBuybackHelper",UIParent,"BackdropTemplate")
    f:SetSize(300,96);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
    if type(f.SetBackdrop)=="function" then
      f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f:SetBackdropColor(.10,.05,.05,.97);f:SetBackdropBorderColor(.93,.42,.36,1)
    end
    f.text=f:CreateFontString(nil,"OVERLAY","GameFontHighlight");f.text:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10);f.text:SetWidth(280);f.text:SetJustifyH("LEFT")
    f.buy=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.buy:SetSize(160,24);f.buy:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10)
    f.buy:SetText(L("Zurückkaufen"))
    f.close=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.close:SetSize(100,24);f.close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-10,10)
    f.close:SetText(L("Schließen"));f.close:SetScript("OnClick",function() f:Hide() end)
    self.BuybackHelper=f
  end
  f:ClearAllPoints()
  local host=_G.MerchantFrame
  if type(host)=="table" and type(host.IsShown)=="function" and host:IsShown() then f:SetPoint("TOPLEFT",host,"BOTTOMLEFT",0,-8)
  else f:SetPoint("CENTER",UIParent,"CENTER",0,150) end
  f.text:SetText(text)
  f.buy:SetScript("OnClick",function()
    local i=CP:BuybackIndex(item)
    if i and type(BuybackItem)=="function" then safe(BuybackItem,i);f:Hide()
    else CP:Say(L("Nicht mehr im Rückkauf des Händlers.")) end
  end)
  f.buy:SetShown(self:BuybackIndex(item)~=nil)
  f:Show()
end

-- Auction house: an item picked up or put into the sell slot that a plan still needs gets a clear warning.
function CP:CheckAuctionPick(bag,slot)
  if not self.db or not (self.AuctionHouseOpen and self:AuctionHouseOpen()) or type(bag)~="number" or type(slot)~="number" then return end
  local locked
  if C_Container and type(C_Container.GetContainerItemInfo)=="function" then
    local info=safe(C_Container.GetContainerItemInfo,bag,slot)
    locked=type(info)=="table" and info.isLocked
  end
  if not locked then return end
  local item=self:ButtonItem({bagID=bag,slotID=slot})
  local r=item and self:ReservedItems()[item]
  if not r then return end
  local use=r.raid and L("für deinen Raid-Vorrat") or r.use and string.format(L("für %s ab Skill %d"),r.use.name,r.use.at) or L("für deinen Plan")
  local text=string.format(L("Nicht einstellen: %s wird %s gebraucht."),self:ItemName(item),use)
  if _G.UIErrorsFrame and type(UIErrorsFrame.AddMessage)=="function" then UIErrorsFrame:AddMessage(text,1,.3,.3) end
  self:Say(text)
end

-- Events ------------------------------------------------------------------------------------------------------------
local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","BAG_UPDATE_DELAYED","BANKFRAME_OPENED","PLAYERBANKSLOTS_CHANGED","MERCHANT_SHOW","MERCHANT_CLOSED","ITEM_LOCK_CHANGED"}) do
  pcall(frame.RegisterEvent,frame,event)
end
local pending=false
local function soon(force)
  if pending then return end
  pending=true
  local function run() pending=false;CP:UpdateItemMarks(force) end
  if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(.2,run) else run() end
end
CP.ScheduleItemMarks=soon
frame:SetScript("OnEvent",function(_,event,a,b)
  if not CP.db then return end
  if event=="PLAYER_LOGIN" then
    -- Bag windows open through many paths; refresh the marks whenever a bag view may have changed.
    for _,name in ipairs({"ToggleAllBags","OpenAllBags","ToggleBackpack","ToggleBag","OpenBag"}) do
      if type(_G[name])=="function" and type(hooksecurefunc)=="function" then pcall(hooksecurefunc,name,function() soon(true) end) end
    end
    if C_Timer and type(C_Timer.NewTicker)=="function" then C_Timer.NewTicker(1.5,function() CP:UpdateItemMarks(false) end) end
  elseif event=="MERCHANT_SHOW" then
    CP.merchantCounts=bagCounts(CP)
  elseif event=="MERCHANT_CLOSED" then
    CP.merchantCounts=nil
  elseif event=="BAG_UPDATE_DELAYED" then
    CP.reservedCache=nil
    if CP.merchantCounts then CP:CheckSoldReserved() end
    soon(false)
  elseif event=="ITEM_LOCK_CHANGED" then
    CP:CheckAuctionPick(a,b)
  else
    soon(true)
  end
end)
