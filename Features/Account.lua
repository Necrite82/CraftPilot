-- Account-wide helpers: profession cooldowns of every character, what to take from the bank, what to mail
-- to which twink, a session balance and plans to share as text. Read-only advice; CraftPilot never moves
-- items, sends mail or crafts by itself.
local _,CP=...
local L=CP.L

local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c,d,e,f=pcall(fn,...)
  if ok then return a,b,c,d,e,f end
end
local function now() return type(time)=="function" and time() or 0 end

-- Cooldowns ---------------------------------------------------------------------------------------------------
-- Recipes with a cooldown (Mooncloth, transmutes, ...) come from the catalog; the remaining time from the client
-- whenever the profession window is read. Stored per character in the account database.
function CP:SnapshotCooldowns(key)
  local entry=self.CurrentCharacter and self:CurrentCharacter()
  local catalog=self:RecipeVendorCatalog(key)
  local T=C_TradeSkillUI
  if not entry or not catalog or not T then return end
  entry.cooldowns=type(entry.cooldowns)=="table" and entry.cooldowns or {}
  for id,native in pairs(self.db.recipes[key] or {}) do
    local recipe=catalog.recipes[id]
    if native.learned and recipe and recipe.cooldown then
      local left=safe(T.GetRecipeCooldown,id)
      left=type(left)=="number" and math.max(0,left) or 0
      entry.cooldowns[id]={key=key,name=native.name or recipe.name,readyAt=now()+left,period=recipe.cooldown}
    end
  end
end

function CP:CooldownList()
  local out={}
  local t=now()
  for charKey,c in pairs(self.account and self.account.characters or {}) do
    for id,cd in pairs(c.cooldowns or {}) do
      out[#out+1]={char=c.name or charKey,me=charKey==self.characterKey,id=id,key=cd.key,name=cd.name,readyAt=cd.readyAt or 0,
        ready=(cd.readyAt or 0)<=t,left=math.max(0,(cd.readyAt or 0)-t)}
    end
  end
  table.sort(out,function(a,b) if a.ready~=b.ready then return a.ready end if a.readyAt~=b.readyAt then return a.readyAt<b.readyAt end return a.char<b.char end)
  return out
end

function CP:FormatDuration(seconds)
  seconds=math.max(0,math.floor(seconds or 0))
  local h=math.floor(seconds/3600)
  if h>=24 then return string.format(L("%d T. %d Std."),math.floor(h/24),h%24) end
  if h>0 then return string.format(L("%d Std. %d Min."),h,math.floor(seconds%3600/60)) end
  return string.format(L("%d Min."),math.max(1,math.floor(seconds/60)))
end

function CP:ReadyCooldownText(key)
  local parts={}
  for _,cd in ipairs(self:CooldownList()) do
    if cd.ready and (not key or cd.key==key) and #parts<3 then parts[#parts+1]=cd.name..(cd.me and "" or (" ("..cd.char..")")) end
  end
  if #parts==0 then return nil end
  return L("Cooldown bereit: ")..table.concat(parts,", ")
end

-- Plans of every character: what they still miss, for the mailbox on another character.
function CP:SnapshotNeeds()
  local entry=self.CurrentCharacter and self:CurrentCharacter()
  if not entry or not self.db then return end
  local needs={}
  for owner in pairs(self.db.plans) do
    local required=self:PlanRequirements(owner)
    for id,n in pairs(required) do
      local have=self:RawItemCount(id,false)+(self:BankCount(id))
      if n>have then needs[id]=(needs[id] or 0)+(n-have) end
    end
  end
  entry.needs=needs
end

-- Bank ---------------------------------------------------------------------------------------------------------
-- What the current plans need that lies in the bank and not in the bags.
function CP:BankPickups()
  local need={}
  for owner in pairs(self.db.plans) do
    for id,n in pairs((self:PlanRequirements(owner))) do need[id]=(need[id] or 0)+n end
  end
  local rec=self.currentRecommendation
  for _,m in ipairs(rec and rec.materials or {}) do need[m.id]=math.max(need[m.id] or 0,m.quantity) end
  local out={}
  for id,n in pairs(need) do
    local bags=self:RawItemCount(id,false)
    local bank=self:BankCount(id)
    local take=math.min(bank,math.max(0,n-bags))
    if take>0 then out[#out+1]={id=id,count=take,name=self:ItemName(id)} end
  end
  table.sort(out,function(a,b) return a.name<b.name end)
  return out
end

-- Mail ---------------------------------------------------------------------------------------------------------
function CP:SnapshotMail()
  local entry=self.CurrentCharacter and self:CurrentCharacter()
  if not entry or type(GetInboxNumItems)~="function" then return end
  local mail={}
  local n=safe(GetInboxNumItems) or 0
  local attachments=_G.ATTACHMENTS_MAX_RECEIVE or 16
  for i=1,n do
    for j=1,attachments do
      local _,itemID,_,count=safe(GetInboxItem,i,j)
      if type(itemID)=="number" and type(count)=="number" and count>0 then mail[itemID]=(mail[itemID] or 0)+count end
    end
  end
  entry.mail=mail
  entry.mailScanned=now()
  self.altIndex=nil
end

-- Items in this character's bags that a twink on the same realm and faction still needs for its plans.
function CP:MailForTwinks()
  local me=self.CurrentCharacter and self:CurrentCharacter()
  local out={}
  if not me then return out end
  for charKey,c in pairs(self.account and self.account.characters or {}) do
    if charKey~=self.characterKey and c.realm==me.realm and c.faction==me.faction then
      local items={}
      for id,n in pairs(c.needs or {}) do
        local have=self:RawItemCount(id,false)
        if have>0 then items[#items+1]={id=id,count=math.min(have,n),name=self:ItemName(id)} end
      end
      if #items>0 then
        table.sort(items,function(a,b) return a.name<b.name end)
        out[#out+1]={name=c.name or charKey,items=items}
      end
    end
  end
  table.sort(out,function(a,b) return a.name<b.name end)
  return out
end

-- Fill in recipient and subject; the player attaches the items and sends the mail.
function CP:PrepareMail(name,items)
  if type(_G.SendMailNameEditBox)~="table" then self:Say(L("Briefkasten nicht geöffnet."));return false end
  if type(MailFrameTab_OnClick)=="function" then pcall(MailFrameTab_OnClick,nil,2) end
  pcall(SendMailNameEditBox.SetText,SendMailNameEditBox,name)
  if type(_G.SendMailSubjectEditBox)=="table" then pcall(SendMailSubjectEditBox.SetText,SendMailSubjectEditBox,"CraftPilot") end
  local list={};for _,it in ipairs(items or {}) do list[#list+1]=it.count.."× "..it.name end
  self:Say(string.format(L("Brief an %s vorbereitet · bitte anhängen: %s"),name,table.concat(list,", ")))
  return true
end

-- A small panel beside the bank or the mailbox. Lines: {text, action, caption}.
-- The bank and mailbox hints: movable (the spot is remembered), and closing one hides it until its list changes.
local function helperPanel(self,name,host)
  local f=self[name]
  if not f then
    f=CreateFrame("Frame","CraftPilot"..name,UIParent,"BackdropTemplate")
    f:SetSize(280,80);f:SetFrameStrata("HIGH");f:SetClampedToScreen(true)
    f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() f:StartMoving() end)
    f:SetScript("OnDragStop",function()
      f:StopMovingOrSizing()
      local point,_,relative,x,y=f:GetPoint()
      if CP.db and point then CP.db.ui.helperPos=CP.db.ui.helperPos or {};CP.db.ui.helperPos[name]={point,relative,x,y} end
    end)
    if type(f.SetBackdrop)=="function" then
      f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f:SetBackdropColor(.07,.08,.10,.96);f:SetBackdropBorderColor(.88,.69,.31,.8)
    end
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-8);f.title:SetWidth(240);f.title:SetJustifyH("LEFT")
    f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton");f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
    f.close:SetScript("OnClick",function()
      if CP.db and f.signature then CP.db.ui.helperDismissed=CP.db.ui.helperDismissed or {};CP.db.ui.helperDismissed[name]=f.signature end
      f:Hide()
    end)
    f.lines={};f.buttons={}
    self[name]=f
  end
  f:ClearAllPoints()
  local saved=self.db and self.db.ui.helperPos and self.db.ui.helperPos[name]
  if type(saved)=="table" and saved[1] then f:SetPoint(saved[1],UIParent,saved[2] or saved[1],saved[3] or 0,saved[4] or 0)
  elseif type(host)=="table" and type(host.IsShown)=="function" and host:IsShown() then f:SetPoint("TOPLEFT",host,"TOPRIGHT",8,0)
  else f:SetPoint("CENTER",UIParent,"CENTER",300,100) end
  return f
end
-- Shown unless switched off or closed for exactly this list.
local function helperWanted(self,name,setting,signature)
  if not self.db or self.db.ui[setting]==false then return false end
  local dismissed=self.db.ui.helperDismissed and self.db.ui.helperDismissed[name]
  return dismissed~=signature
end
local function fillPanel(f,title,rows)
  f.title:SetText(title)
  local y=30
  for i,row in ipairs(rows) do
    local line=f.lines[i]
    if not line then line=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");line:SetJustifyH("LEFT");line:SetWidth(258);f.lines[i]=line end
    line:ClearAllPoints();line:SetPoint("TOPLEFT",f,"TOPLEFT",10,-y);line:SetText(row.text);line:Show()
    local h=line:GetStringHeight();y=y+(type(h)=="number" and h>0 and h or 14)+4
    local b=f.buttons[i]
    if row.action then
      if not b then b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetSize(258,22);f.buttons[i]=b end
      b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",10,-y);b:SetText(row.caption or "");b:SetScript("OnClick",row.action);b:Show()
      y=y+26
    elseif b then b:Hide() end
  end
  for i=#rows+1,#f.lines do f.lines[i]:Hide();if f.buttons[i] then f.buttons[i]:Hide() end end
  f:SetHeight(y+8)
  f:Show()
end

function CP:ShowBankHelper()
  if not self.db then return end
  local pickups=self:BankPickups()
  local parts={};for _,p in ipairs(pickups) do parts[#parts+1]=p.count.."× "..p.name end
  local signature=table.concat(parts,";")
  if #pickups==0 or not helperWanted(self,"BankHelper","bankHelper",signature) then if self.BankHelper then self.BankHelper:Hide() end;return end
  local f=helperPanel(self,"BankHelper",_G.BankFrame)
  f.signature=signature
  fillPanel(f,L("CraftPilot · aus der Bank mitnehmen"),{{text=table.concat(parts,"\n")},{text="|cff8c8c8c"..L("Ziehen zum Verschieben · X blendet aus, bis sich die Liste ändert").."|r"}})
end

function CP:ShowMailHelper()
  if not self.db then return end
  local twinks=self:MailForTwinks()
  local sig={}
  for _,t in ipairs(twinks) do for _,it in ipairs(t.items) do sig[#sig+1]=t.name..":"..it.count..":"..it.name end end
  local signature=table.concat(sig,";")
  if #twinks==0 or not helperWanted(self,"MailHelper","mailHelper",signature) then if self.MailHelper then self.MailHelper:Hide() end;return end
  local rows={}
  for _,t in ipairs(twinks) do
    local parts={};for i,it in ipairs(t.items) do if i<=4 then parts[#parts+1]=it.count.."× "..it.name end end
    if #t.items>4 then parts[#parts+1]=string.format(L("+%d weitere"),#t.items-4) end
    local name,items=t.name,t.items
    rows[#rows+1]={text=string.format(L("%s braucht: %s"),t.name,table.concat(parts,", ")),caption=string.format(L("Brief an %s vorbereiten"),t.name),
      action=function() CP:PrepareMail(name,items) end}
  end
  local f=helperPanel(self,"MailHelper",_G.MailFrame)
  f.signature=signature
  fillPanel(f,L("CraftPilot · für deine Twinks"),rows)
end

-- Session balance -----------------------------------------------------------------------------------------------
-- Skill points gained and gold spent at the auction house, vendors and trainers since login, against what the
-- cheapest path expected for those points.
function CP:StartSession()
  local s={start=now(),money=safe(GetMoney) or 0,spent=0,skills={},perPoint={}}
  for key,p in pairs(self.db and self.db.professions or {}) do s.skills[key]=p.skill end
  self.session=s
end

local spendingFrames={"AuctionHouseFrame","AuctionFrame","MerchantFrame","ClassTrainerFrame"}
function CP:TrackMoney()
  local s=self.session;if not s then return end
  local money=safe(GetMoney) or s.money
  local delta=money-(s.lastMoney or s.money)
  s.lastMoney=money
  if delta>=0 then return end
  for _,name in ipairs(spendingFrames) do
    local f=_G[name]
    if type(f)=="table" and type(f.IsShown)=="function" and f:IsShown() then s.spent=s.spent-delta;return end
  end
end

function CP:SessionBalance(key)
  local s=self.session
  local record=self.db and self.db.professions[key]
  if not s or not record then return nil end
  s.skills[key]=s.skills[key] or record.skill
  if not s.perPoint[key] and self.CheapestPath then
    local path=self:CheapestPath(key)
    if path and path.reached>path.from then s.perPoint[key]=path.total/(path.reached-path.from) end
  end
  local gained=(record.skill or 0)-(s.skills[key] or 0)
  local expected=s.perPoint[key] and gained*s.perPoint[key]
  return {gained=gained,spent=s.spent,expected=expected,minutes=math.floor((now()-s.start)/60)}
end

function CP:SessionText(key)
  local b=self:SessionBalance(key)
  if not b or (b.gained<=0 and b.spent<=0) then return nil end
  local text=string.format(L("Diese Sitzung: +%d Punkte · ausgegeben %s"),b.gained,self:FormatCostMoney(b.spent))
  if b.expected and b.gained>0 then text=text..string.format(L(" (Plan: ca. %s)"),self:FormatCostMoney(b.expected)) end
  return text
end

-- Share a plan as text ---------------------------------------------------------------------------------------------
-- CP1;profession;from;to;recipe=count,... : the planned crafts, readable by any CraftPilot.
function CP:ExportPlan(key)
  local plan=self:PlanFor(key)
  local crafts={}
  local route=self:AutoRouteShopping(key)
  if route then for _,s in ipairs(route.steps) do crafts[s.id]=(crafts[s.id] or 0)+s.crafts end
  else for id,n in pairs(plan.crafts or {}) do crafts[id]=n end end
  local parts={}
  for id,n in pairs(crafts) do if type(n)=="number" and n>0 then parts[#parts+1]=id.."="..n end end
  table.sort(parts)
  if #parts==0 then return nil end
  return "CP1;"..key..";"..plan.start..";"..plan.target..";"..table.concat(parts,",")
end

function CP:ImportPlan(text)
  if type(text)~="string" then return false,L("Kein Text.") end
  text=text:gsub("%s","")
  local key,from,to,list=text:match("^CP1;(%a+);(%d+);(%d+);([%d=,]+)$")
  if not key or not self.Data.professions[key] then return false,L("Unbekanntes Format · erwartet CP1;Beruf;von;bis;Rezept=Anzahl,…") end
  local crafts,n={},0
  for id,count in list:gmatch("(%d+)=(%d+)") do
    id,count=tonumber(id),tonumber(count)
    if id and count and count>0 and count<=1000 then crafts[id]=count;n=n+1 end
  end
  if n==0 then return false,L("Keine Rezepte im Text.") end
  local plan=self:PlanFor(key)
  plan.start=math.max(1,math.min(299,tonumber(from)));plan.target=math.max(plan.start+1,math.min(300,tonumber(to)))
  plan.crafts=crafts;plan.autoRoute=nil;plan.autoMode=nil
  self:InvalidateReservations()
  self.db.view=key
  return true,key,n
end

function CP:OpenShareWindow(key,mode)
  local f=self.shareWindow
  if not f then
    f=CreateFrame("Frame","CraftPilotShareWindow",UIParent,"BackdropTemplate")
    f:SetSize(460,200);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    if type(f.SetBackdrop)=="function" then
      f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f:SetBackdropColor(.07,.08,.10,.97);f:SetBackdropBorderColor(.88,.69,.31,.9)
    end
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",12,-10)
    f.hint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall");f.hint:SetPoint("TOPLEFT",f,"TOPLEFT",12,-30);f.hint:SetWidth(430);f.hint:SetJustifyH("LEFT")
    f.box=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.box:SetSize(430,26);f.box:SetPoint("TOPLEFT",f,"TOPLEFT",16,-78);f.box:SetAutoFocus(false)
    if type(f.box.SetMaxLetters)=="function" then f.box:SetMaxLetters(4000) end
    f.box:SetScript("OnEscapePressed",function() f:Hide() end)
    f.apply=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.apply:SetSize(160,24);f.apply:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",12,12)
    f.apply:SetText(L("Plan übernehmen"))
    f.apply:SetScript("OnClick",function()
      local ok,result,n=CP:ImportPlan(f.box:GetText())
      if ok then CP:Say(string.format(L("Plan mit %d Rezepten übernommen."),n));f:Hide();CP.db.ui.tab="plan";CP:Refresh(false)
      else CP:Say(result) end
    end)
    f.close=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.close:SetSize(100,24);f.close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-12,12)
    f.close:SetText(L("Schließen"));f.close:SetScript("OnClick",function() f:Hide() end)
    self.shareWindow=f
  end
  if mode=="import" then
    f.title:SetText(L("Plan importieren"))
    f.hint:SetText(L("Text eines anderen CraftPilot einfügen (Strg+V) und übernehmen. Dein bisheriger Plan für diesen Beruf wird ersetzt."))
    f.box:SetText("");f.apply:Show()
  else
    local text=self:ExportPlan(key)
    if not text then self:Say(L("Noch kein Plan zum Teilen · zuerst Plan erstellen."));return false end
    f.title:SetText(L("Plan teilen"))
    f.hint:SetText(L("Text markieren und kopieren (Strg+C), dann z. B. im Gildenchat oder per Brief weitergeben."))
    f.box:SetText(text);f.apply:Hide()
    if type(f.box.HighlightText)=="function" then f.box:HighlightText() end
  end
  f:Show()
  if type(f.box.SetFocus)=="function" then f.box:SetFocus() end
  return true
end

-- Events --------------------------------------------------------------------------------------------------------
local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_MONEY","MAIL_SHOW","MAIL_INBOX_UPDATE","MAIL_CLOSED","BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYER_LOGOUT"}) do
  pcall(frame.RegisterEvent,frame,event)
end
local announced=false
frame:SetScript("OnEvent",function(_,event)
  if not CP.db and event~="PLAYER_LOGIN" then return end
  if event=="PLAYER_LOGIN" then
    CP:StartSession()
    local function announce()
      if announced then return end
      announced=true
      local ready={}
      for _,cd in ipairs(CP:CooldownList()) do if cd.ready then ready[#ready+1]=cd.name.." ("..cd.char..")" end end
      if #ready>0 then CP:Say(L("Cooldowns bereit: ")..table.concat(ready,", ")) end
    end
    if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(8,announce) else announce() end
  elseif event=="PLAYER_MONEY" then
    CP:TrackMoney()
  elseif event=="MAIL_SHOW" or event=="MAIL_INBOX_UPDATE" then
    CP:SnapshotMail()
    if event=="MAIL_SHOW" then CP:ShowMailHelper() end
  elseif event=="MAIL_CLOSED" then
    if CP.MailHelper then CP.MailHelper:Hide() end
  elseif event=="BANKFRAME_OPENED" then
    local function show() CP:ShowBankHelper() end
    if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(.2,show) else show() end
  elseif event=="BANKFRAME_CLOSED" then
    if CP.BankHelper then CP.BankHelper:Hide() end
    CP:SnapshotNeeds()
  elseif event=="PLAYER_LOGOUT" then
    CP:SnapshotNeeds()
  end
end)

-- The "Twinks" tab ---------------------------------------------------------------------------------------------
function CP:TwinkCards(key)
  local cards={}
  local characters=self.account and self.account.characters or {}
  local me=self.CurrentCharacter and self:CurrentCharacter()
  local others=0;for charKey in pairs(characters) do if charKey~=self.characterKey then others=others+1 end end
  if others==0 then
    cards[#cards+1]={title=L("Noch keine Twinks erfasst"),detail=L("Einmal mit jedem Twink einloggen, Berufsfenster und Bank öffnen. Danach siehst du hier Vorräte, Berufe und Cooldowns aller Charaktere."),color="blue"}
  end
  -- Cooldowns
  local cooldowns=self:CooldownList()
  if #cooldowns>0 then
    cards[#cards+1]={sectionHeader=true,title=L("COOLDOWNS")}
    for _,cd in ipairs(cooldowns) do
      cards[#cards+1]={title=cd.name.." · "..cd.char,detail=cd.ready and L("Bereit") or (L("Wieder bereit in ")..self:FormatDuration(cd.left)),
        color=cd.ready and "green" or "blue",icon=self.Data.professionIcons and self.Data.professionIcons[cd.key]}
    end
  end
  -- Stock on twinks for this profession's plan and the recommendation
  local need={}
  for id,n in pairs((self:PlanRequirements(key))) do need[id]=n end
  local rec=self.currentRecommendation
  for _,m in ipairs(rec and rec.key==key and rec.materials or {}) do need[m.id]=math.max(need[m.id] or 0,m.quantity) end
  local stock={}
  for id,n in pairs(need) do
    for _,a in ipairs(self:AltStock(id)) do
      if a.reachable then
        local where={}
        if a.bags>0 then where[#where+1]=a.bags.." "..L("Taschen") end
        if a.bank>0 then where[#where+1]=a.bank.." "..L("Bank") end
        if (a.mail or 0)>0 then where[#where+1]=a.mail.." "..L("Post") end
        stock[#stock+1]={id=id,name=self:ItemName(id),alt=a.name,where=table.concat(where,", "),need=n}
      end
    end
  end
  if #stock>0 then
    table.sort(stock,function(a,b) if a.alt~=b.alt then return a.alt<b.alt end return a.name<b.name end)
    cards[#cards+1]={sectionHeader=true,title=L("BEI TWINKS FÜR DEINEN PLAN")}
    for _,s in ipairs(stock) do
      cards[#cards+1]={title=s.name.." · "..s.alt,detail=s.where..string.format(L(" · Plan braucht %d"),s.need),tooltipItem=s.id,color="gold",
        footer=L("Per Post schicken lassen; der Briefkasten des Twinks zeigt es auch an.")}
    end
  end
  -- Twinks who make materials cheaper than the auction house
  local path=self.CheapestPath and self:CheapestPath(key)
  if path and #path.altCrafts>0 then
    cards[#cards+1]={sectionHeader=true,title=L("TWINKS KÖNNEN HERSTELLEN")}
    for _,c in ipairs(path.altCrafts) do
      cards[#cards+1]={title=self:ItemName(c.item).." · "..c.alt,detail=string.format(L("Selbst herstellen spart ca. %s je Stück gegenüber dem AH."),self:FormatCostMoney(c.saving))
        ..(c.sure and "" or ("\n"..L("Rezept beim Twink nicht bestätigt · einmal dessen Berufsfenster öffnen."))),tooltipItem=c.item,color="green"}
    end
  end
  -- Characters
  local list={}
  for charKey,c in pairs(characters) do list[#list+1]={key=charKey,c=c} end
  table.sort(list,function(a,b) if (a.key==self.characterKey)~=(b.key==self.characterKey) then return a.key==self.characterKey end return a.key<b.key end)
  if #list>0 then cards[#cards+1]={sectionHeader=true,title=L("CHARAKTERE")} end
  for _,row in ipairs(list) do
    local c=row.c
    local profs={}
    for pkey,p in pairs(c.professions or {}) do
      local meta=self.Data.professions[pkey]
      profs[#profs+1]=(meta and meta.name or pkey).." "..(p.skill or 0).."/"..(p.cap or 0)
    end
    table.sort(profs)
    local reach=me and c.realm==me.realm and c.faction==me.faction
    local seen=c.updated and type(date)=="function" and date("%d.%m. %H:%M",c.updated) or "?"
    cards[#cards+1]={title=(c.name or row.key)..(row.key==self.characterKey and L(" (du)") or "")..(c.level and (" · "..L("Stufe ")..c.level) or ""),
      detail=(#profs>0 and table.concat(profs," · ") or L("Keine Berufe erfasst")),
      footer=string.format(L("Stand %s · Bank %s · Post %s"),seen,c.bankScanned and L("erfasst") or L("noch nicht geöffnet"),c.mailScanned and L("erfasst") or L("noch nicht geöffnet"))
        ..((reach or row.key==self.characterKey) and "" or ("  ·  "..L("anderes Realm oder Fraktion: nur Info"))),
      color=row.key==self.characterKey and "gold" or (reach and "blue" or "red")}
  end
  return cards
end
