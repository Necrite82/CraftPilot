-- Shopping round at the auction house: the missing materials one by one, each with the price limit, and the
-- bought amount counted from the bags. Auctionator searches; buying stays with the player.
local _,CP=...
local L=CP.L

function CP:ShoppingRoundItems()
  local out={}
  for id,n in pairs(self:MissingForPlans()) do out[#out+1]={id=id,need=n,name=self:ItemName(id)} end
  table.sort(out,function(a,b) return a.name<b.name end)
  return out
end

function CP:RoundRemaining(e)
  return math.max(0,e.need-(self:RawItemCount(e.id,false)-e.start))
end

function CP:StartShoppingRound()
  local items=self:ShoppingRoundItems()
  if #items==0 then self:Say(L("Für deine Pläne fehlt nichts."));return false end
  for _,e in ipairs(items) do e.start=self:RawItemCount(e.id,false) end
  self.shopRound={items=items,index=1}
  self:SearchRoundItem()
  self:ShowRoundPanel()
  return true
end

function CP:SearchRoundItem()
  local round=self.shopRound;if not round then return false end
  local e=round.items[round.index];if not e then return false end
  return self:SearchItems({{id=e.id,quantity=self:RoundRemaining(e)}},L("Einkaufsrunde"),string.format(L("Auctionator sucht %s."),e.name))
end

function CP:AdvanceRound(step)
  local round=self.shopRound;if not round then return end
  round.index=round.index+(step or 1)
  -- Skip what is already bought.
  while (step or 1)>0 and round.items[round.index] and self:RoundRemaining(round.items[round.index])==0 do round.index=round.index+1 end
  if round.index>#round.items then
    self.shopRound=nil
    self:Say(L("Einkaufsrunde fertig."))
  elseif round.index<1 then round.index=1 end
  if self.shopRound then self:SearchRoundItem() end
  self:ShowRoundPanel()
end

-- After a purchase: a finished item moves the round on by itself.
function CP:CheckRound()
  local round=self.shopRound;if not round then return end
  local e=round.items[round.index]
  if e and self:RoundRemaining(e)==0 then
    self:Say(string.format(L("%s erledigt."),e.name))
    self:AdvanceRound(1)
  else self:ShowRoundPanel() end
end

local function button(parent,w,caption,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetSize(w,22);b:SetText(caption);b:SetScript("OnClick",fn)
  return b
end

function CP:ShowRoundPanel()
  if not self.db or not (self.AuctionHouseOpen and self:AuctionHouseOpen()) then if self.RoundPanel then self.RoundPanel:Hide() end;return end
  local f=self.RoundPanel
  if not f then
    f=CreateFrame("Frame","CraftPilotProRoundPanel",UIParent,"BackdropTemplate")
    f:SetSize(290,120);f:SetFrameStrata("HIGH");f:SetClampedToScreen(true)
    if type(f.SetBackdrop)=="function" then
      f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f:SetBackdropColor(.07,.08,.10,.96);f:SetBackdropBorderColor(.88,.69,.31,.8)
    end
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-8);f.title:SetWidth(250);f.title:SetJustifyH("LEFT")
    f.item=f:CreateFontString(nil,"OVERLAY","GameFontHighlight");f.item:SetPoint("TOPLEFT",f,"TOPLEFT",10,-30);f.item:SetWidth(270);f.item:SetJustifyH("LEFT")
    f.info=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.info:SetPoint("TOPLEFT",f,"TOPLEFT",10,-50);f.info:SetWidth(270);f.info:SetJustifyH("LEFT")
    f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton");f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
    f.start=button(f,270,L("Einkaufsrunde starten"),function() CP:StartShoppingRound() end)
    f.search=button(f,86,L("Suchen"),function() CP:SearchRoundItem() end)
    f.back=button(f,86,L("Zurück"),function() CP:AdvanceRound(-1) end)
    f.next=button(f,86,L("Weiter"),function() CP:AdvanceRound(1) end)
    f.stop=button(f,270,L("Runde beenden"),function() CP.shopRound=nil;CP:ShowRoundPanel() end)
    self.RoundPanel=f
  end
  f:ClearAllPoints()
  local host=_G.AuctionHouseFrame or _G.AuctionFrame
  if type(host)=="table" and type(host.IsShown)=="function" and host:IsShown() then f:SetPoint("TOPLEFT",host,"TOPRIGHT",8,0)
  else f:SetPoint("CENTER",UIParent,"CENTER",300,100) end
  local round=self.shopRound
  for _,b in ipairs({f.start,f.search,f.back,f.next,f.stop}) do b:Hide() end
  if not round then
    local items=self:ShoppingRoundItems()
    if #items==0 then f:Hide();return end
    f.title:SetText(L("CraftPilot · Einkaufsrunde"))
    f.item:SetText(string.format(L("%d Materialien fehlen für deine Pläne"),#items))
    local names={};for i,e in ipairs(items) do if i<=3 then names[#names+1]=e.need.."× "..e.name end end
    f.info:SetText(table.concat(names,", ")..(#items>3 and " …" or ""))
    f.start:ClearAllPoints();f.start:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10);f.start:Show()
    f:SetHeight(110);f:Show()
    return
  end
  local e=round.items[round.index]
  f.title:SetText(string.format(L("Einkaufsrunde %d/%d"),round.index,#round.items))
  local left=self:RoundRemaining(e)
  f.item:SetText(string.format(L("Noch %d× %s"),left,e.name))
  local info={}
  local price=self:PriceDetails(e.id).price
  if price then info[#info+1]=L("AH zuletzt: ")..self:FormatCostMoney(price) end
  local limit=self.PriceLimit and self:PriceLimit(self.db.view,e.id)
  if limit then info[#info+1]="|cff8fd6a6"..L("lohnt sich bis ")..self:FormatCostMoney(limit.price).."|r" end
  f.info:SetText(#info>0 and table.concat(info,"  ·  ") or L("Kein Preis bekannt"))
  f.search:ClearAllPoints();f.search:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,38);f.search:Show()
  f.back:ClearAllPoints();f.back:SetPoint("LEFT",f.search,"RIGHT",6,0);f.back:Show()
  f.next:ClearAllPoints();f.next:SetPoint("LEFT",f.back,"RIGHT",6,0);f.next:Show()
  f.stop:ClearAllPoints();f.stop:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10);f.stop:Show()
  f:SetHeight(136);f:Show()
end

local frame=CreateFrame("Frame")
for _,event in ipairs({"AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","BAG_UPDATE_DELAYED"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event)
  if not CP.db then return end
  if event=="AUCTION_HOUSE_SHOW" then
    if C_Timer and C_Timer.After then C_Timer.After(.3,function() CP:ShowRoundPanel() end) else CP:ShowRoundPanel() end
  elseif event=="AUCTION_HOUSE_CLOSED" then
    if CP.RoundPanel then CP.RoundPanel:Hide() end
  elseif CP.shopRound then
    CP:CheckRound()
  end
end)
