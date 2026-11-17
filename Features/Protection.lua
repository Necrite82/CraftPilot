-- 0.2: more warnings for reserved items. Besides selling (Marks.lua) CraftPilot now warns when a reserved item
-- is about to be destroyed, disenchanted or mailed to someone who is not one of your own characters.
-- WoW gives addons no way to stop these actions, so this only warns; nothing is cancelled or changed.
local _,CP=...
local L=CP.L

local DISENCHANT=13262
local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c,d,e=pcall(fn,...)
  if ok then return a,b,c,d,e end
end
local function clock() return type(GetTime)=="function" and GetTime() or 0 end
local function secret(v) return type(issecretvalue)=="function" and issecretvalue(v)==true end
local function plain(v) if v~=nil and not secret(v) then return v end end

local function reservedText(self,item)
  local r=self.ReservedItems and self:ReservedItems()[item]
  if not r then return nil end
  return r.use and string.format(L("für %s ab Skill %d"),r.use.name,r.use.at) or L("für deinen Plan")
end

-- One warning per item and action within a few seconds, shown in the error frame and the chat.
function CP:WarnReserved(action,item)
  local use=reservedText(self,item)
  if not use then return false end
  self.protectionWarned=self.protectionWarned or {}
  local marker=action..":"..item
  if self.protectionWarned[marker] and clock()-self.protectionWarned[marker]<5 then return true end
  self.protectionWarned[marker]=clock()
  local texts={
    destroy=L("Achtung: %s wird %s gebraucht · nicht zerstören."),
    disenchant=L("Achtung: %s wird %s gebraucht · nicht entzaubern."),
    mail=L("Achtung: %s wird %s gebraucht · Empfänger ist keiner deiner Charaktere."),
  }
  local text=string.format(texts[action] or texts.destroy,self:ItemName(item),use)
  if _G.UIErrorsFrame and type(UIErrorsFrame.AddMessage)=="function" then UIErrorsFrame:AddMessage(text,1,.3,.3) end
  self:Say(text)
  return true
end

-- Is a mail recipient one of the account's characters on this realm? Forever names have a first and a
-- last name; a match on the full name or on the first name followed by a space counts.
function CP:IsOwnCharacter(name)
  name=plain(name)
  if type(name)~="string" then return false end
  name=name:lower():gsub("^%s+",""):gsub("%s+$",""):gsub("%-.*$","")
  if name=="" then return false end
  local me=self.CurrentCharacter and self:CurrentCharacter()
  for _,c in pairs(self.account and self.account.characters or {}) do
    local own=type(c.name)=="string" and c.name:lower()
    if own and (not me or c.realm==me.realm) and (own==name or name:sub(1,#own+1)==own.." " or own:sub(1,#name+1)==name.." ") then return true end
  end
  return false
end

function CP:CheckMailAttachments()
  if not self.db or self.db.ui.itemMarks==false then return end
  local box=_G.SendMailNameEditBox
  local recipient=box and type(box.GetText)=="function" and safe(box.GetText,box)
  if type(recipient)~="string" or recipient=="" or self:IsOwnCharacter(recipient) then return end
  for i=1,(tonumber(_G.ATTACHMENTS_MAX_SEND) or 12) do
    local _,item=safe(GetSendMailItem,i)
    item=plain(item)
    if type(item)=="number" then self:WarnReserved("mail",item) end
  end
end

local cursorLock={}
local frame=CreateFrame("Frame")
for _,event in ipairs({"DELETE_ITEM_CONFIRM","UNIT_SPELLCAST_SENT","ITEM_LOCK_CHANGED","MAIL_SEND_INFO_UPDATE","MAIL_SHOW"}) do
  pcall(frame.RegisterEvent,frame,event)
end
frame:SetScript("OnEvent",function(_,event,a,b,c,d)
  if not CP.db or CP.db.ui.itemMarks==false then return end
  if event=="DELETE_ITEM_CONFIRM" then
    local kind,item=safe(GetCursorInfo)
    item=plain(item)
    if plain(kind)=="item" and type(item)=="number" then CP:WarnReserved("destroy",item) end
  elseif event=="UNIT_SPELLCAST_SENT" then
    if plain(a)=="player" and plain(d)==DISENCHANT then
      CP.disenchantSent=clock()
      if cursorLock.item and clock()-cursorLock.at<2 then CP:WarnReserved("disenchant",cursorLock.item) end
    end
  elseif event=="ITEM_LOCK_CHANGED" then
    local bag,slot=plain(a),plain(b)
    if type(bag)~="number" or type(slot)~="number" then return end
    local item=CP.ButtonItem and CP:ButtonItem({bagID=bag,slotID=slot})
    if not item then return end
    cursorLock.item,cursorLock.at=item,clock()
    if CP.disenchantSent and clock()-CP.disenchantSent<2 then CP:WarnReserved("disenchant",item) end
  elseif event=="MAIL_SEND_INFO_UPDATE" then
    CP:CheckMailAttachments()
  elseif event=="MAIL_SHOW" then
    -- The recipient may be typed after the items are attached: check again when the name field is left.
    local box=_G.SendMailNameEditBox
    if box and not CP.mailBoxHooked and type(box.HookScript)=="function" then
      CP.mailBoxHooked=true
      pcall(box.HookScript,box,"OnEditFocusLost",function() CP:CheckMailAttachments() end)
    end
  end
end)
