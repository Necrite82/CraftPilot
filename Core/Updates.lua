-- Exchanges version numbers only; no external network access or remote code.
local _,CP=...
local L=CP.L
CP.version="1.4.0"
CP.releaseURL="https://github.com/Necrite82/CraftPilot/releases"
CP.discordURL="https://discord.gg/DpsBkHtQS"
local PREFIX="CraftPilotVer"
local channels={GUILD=true,PARTY=true,RAID=true,INSTANCE_CHAT=true}
local function parse(version)
  if type(version)~="string" or #version>24 then return end
  local a,b,c,suffix=version:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
  local stage=({["-alpha"]=0,["-beta"]=1,[""]=2})[suffix]
  if not a or #a>3 or #b>3 or #c>3 or not stage then return end
  -- The numbering restarted at 0.1.0-beta for CurseForge: the stage (alpha, beta, release) counts first,
  -- so every beta is newer than any of the old 0.x alphas.
  return {stage,tonumber(a),tonumber(b),tonumber(c)}
end
function CP:IsNewerVersion(candidate,current)
  local a,b=parse(candidate),parse(current)
  if not a or not b then return false end
  for i=1,4 do if a[i]~=b[i] then return a[i]>b[i] end end
  return false
end
local function now()
  return type(GetTime)=="function" and GetTime() or (type(time)=="function" and time() or 0)
end
function CP:SendVersion(channel,query)
  if not channels[channel] or not C_ChatInfo or type(C_ChatInfo.SendAddonMessage)~="function" then return false end
  local stamp=now()
  self.versionSent=self.versionSent or {}
  local slot=channel..(query and ":query" or ":reply")
  if self.versionSent[slot] and stamp-self.versionSent[slot]<60 then return false end
  self.versionSent[slot]=stamp
  return pcall(C_ChatInfo.SendAddonMessage,PREFIX,(query and "Q|" or "V|")..self.version,channel)
end
function CP:AnnounceVersion()
  if type(IsInGuild)=="function" and IsInGuild() then self:SendVersion("GUILD",true) end
  if LE_PARTY_CATEGORY_INSTANCE and type(IsInGroup)=="function" and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
    self:SendVersion("INSTANCE_CHAT",true)
  elseif type(IsInRaid)=="function" and IsInRaid() then self:SendVersion("RAID",true)
  elseif type(IsInGroup)=="function" and IsInGroup() then self:SendVersion("PARTY",true) end
end
function CP:ReceiveVersion(prefix,message,channel)
  if not self.db or prefix~=PREFIX or not channels[channel] or type(message)~="string" or #message>26 then return false end
  local kind,version=message:match("^([QV])|(.+)$")
  if not kind or not parse(version) then return false end
  if kind=="Q" then self:SendVersion(channel,false) end
  if self:IsNewerVersion(version,self.version) and
    (not parse(self.db.latestSeenVersion) or self:IsNewerVersion(version,self.db.latestSeenVersion)) then
    self.db.latestSeenVersion=version
    if self.db.lastVersionNotice~=version then
      self.db.lastVersionNotice=version
      self:Say(L("Neuere CraftPilot-Version gemeldet: ")..version.." | "..self.releaseURL)
    end
    if self.frame and self.frame:IsShown() then self:Render() end
  end
  return true
end
function CP:VersionStatus()
  local reported=self.db and self.db.latestSeenVersion
  if self:IsNewerVersion(reported,self.version) then return L("Neuere Version gemeldet: ")..reported end
  return L("Keine neuere Version gemeldet")
end
function CP:OpenReleaseLink() return self:OpenCopyLink(L("Release-Link kopieren: Strg+C"),self.releaseURL) end
function CP:OpenDiscordLink()
  return self:OpenCopyLink(L("Discord-Link kopieren: Strg+C, dann im Browser oder in Discord einfügen"),self.discordURL)
end
-- A small window with a link selected for copying (WoW can't open a browser itself).
function CP:OpenCopyLink(caption,url)
  if not self.releaseLinkFrame then
    local frame=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
    frame:SetSize(520,130);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true);frame:SetClampedToScreen(true)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    frame:SetBackdropColor(.06,.08,.10,1)
    local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    title:SetPoint("TOPLEFT",20,-20);title:SetWidth(470);title:SetJustifyH("LEFT")
    local edit=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
    edit:SetSize(470,30);edit:SetPoint("TOPLEFT",25,-55);edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed",function() frame:Hide() end)
    edit:SetScript("OnEnterPressed",function() frame:Hide() end)
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function() frame:Hide() end)
    self.releaseLinkFrame=frame;self.releaseLinkEdit=edit;self.releaseLinkTitle=title
  end
  self.releaseLinkTitle:SetText(caption or "")
  self.releaseLinkFrame:Show()
  self.releaseLinkEdit:SetText(url or "")
  self.releaseLinkEdit:SetFocus();self.releaseLinkEdit:HighlightText()
end
function CP:InitializeVersionChecks()
  if self.versionChecksReady then return end
  if not C_ChatInfo or type(C_ChatInfo.RegisterAddonMessagePrefix)~="function" then return end
  local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,PREFIX)
  if not ok or result==false then return end
  self.versionChecksReady=true
  local frame=CreateFrame("Frame")
  for _,event in ipairs({"CHAT_MSG_ADDON","GROUP_ROSTER_UPDATE","PLAYER_GUILD_UPDATE","PLAYER_ENTERING_WORLD"}) do
    pcall(frame.RegisterEvent,frame,event)
  end
  local scheduled=false
  frame:SetScript("OnEvent",function(_,event,...)
    if event=="CHAT_MSG_ADDON" then self:ReceiveVersion(...);return end
    if scheduled then return end
    scheduled=true
    local function announce() scheduled=false;if self.db then self:AnnounceVersion() end end
    if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(3,announce) else announce() end
  end)
end
