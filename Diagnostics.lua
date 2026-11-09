-- Bounded local diagnostics. Reports leave the game only through a user-copied link.
local _,CP=...
local L=CP.L
local function safeText(value,limit)
  if type(issecretvalue)=="function" and issecretvalue(value) then return "[restricted]" end
  if type(value)~="string" and type(value)~="number" then return "" end
  local text=tostring(value):sub(1,limit or 3500)
  text=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|H.-|h(.-)|h","%1")
  text=text:gsub("[%w._%%+%-]+@[%w.%-]+%.[%a]+","[email]")
  text=text:gsub("[A-Za-z]:[\\/][^\r\n]-([Cc]raft[Pp]ilot[\\/][^\r\n]*)","%1")
  text=text:gsub("[A-Za-z]:[\\/][^\r\n]*","[local path]"):gsub("/Users/[^%s]+","[local path]"):gsub("/home/[^%s]+","[local path]")
  text=text:gsub("https?://[^%s]+","[URL]")
  if type(UnitName)=="function" then
    local name=UnitName("player")
    if not (type(issecretvalue)=="function" and issecretvalue(name)) and type(name)=="string" and #name>0 then text=text:gsub(name:gsub("(%W)","%%%1"),"[player]") end
  end
  return text
end
function CP:CaptureDiagnostic(message,stack,blocked)
  if not self.db or self.capturingDiagnostic then return false end
  if type(issecretvalue)=="function" and (issecretvalue(message) or issecretvalue(stack)) then return false end
  local own=(type(message)=="string" and message:find("CraftPilot",1,true)) or (type(stack)=="string" and stack:find("CraftPilot",1,true))
  if not blocked and not own then return false end
  message=safeText(message,1500);stack=safeText(stack,3500)
  self.capturingDiagnostic=true
  self.db.diagnostics=type(self.db.diagnostics)=="table" and self.db.diagnostics or {}
  local entries=self.db.diagnostics
  for _,entry in ipairs(entries) do
    if entry.message==message and entry.stack==stack then
      entry.count=math.min(9999,(tonumber(entry.count) or 1)+1);self.capturingDiagnostic=false;return true
    end
  end
  entries[#entries+1]={message=message,stack=stack,count=1,version=self.version}
  while #entries>20 do table.remove(entries,1) end
  self.capturingDiagnostic=false
  if not self.diagnosticNotice then
    self.diagnosticNotice=true
    self:Say(L("CraftPilot-Fehler erfasst. Einstellungen > Fehler melden öffnet den Bericht."))
  end
  return true
end
function CP:ImportBugGrabberDiagnostics()
  local grabber=_G.BugGrabber
  if type(grabber)~="table" or type(grabber.GetDB)~="function" then return end
  local ok,errors=pcall(grabber.GetDB,grabber)
  if not ok or type(errors)~="table" then return end
  self.importedDiagnostics=self.importedDiagnostics or setmetatable({},{__mode="k"})
  for i=math.max(1,#errors-49),#errors do
    local entry=errors[i]
    if type(entry)=="table" and not self.importedDiagnostics[entry] then
      -- Deliberately never inspect BugGrabber's locals or other saved fields.
      self:CaptureDiagnostic(entry.message,entry.stack)
      self.importedDiagnostics[entry]=true
    end
  end
end
function CP:DiagnosticStatus()
  return string.format(L("%d lokale Fehlerberichte · Vorschau und GitHub-Link; kein automatischer Upload."),#(self.db.diagnostics or {}))
    ..(self.nativeDiagnostics and "" or L(" Lua-Erfassung über optionales !BugGrabber."))
end
function CP:BuildDiagnosticReport()
  self:ImportBugGrabberDiagnostics()
  local version,build,_,interface
  if type(GetBuildInfo)=="function" then version,build,_,interface=GetBuildInfo() end
  local key=self.db.view
  local prof=self.db.professions[key] or {}
  local lines={"CraftPilot "..safeText(self.version,80),"Client: "..safeText(version,80).." / "..safeText(build,80).." / "..safeText(interface,80),
    "Locale: "..safeText(type(GetLocale)=="function" and GetLocale() or "unknown",20),
    "View: "..safeText(self.db.ui.tab,30).." / "..safeText(key,30).." / skill "..safeText(prof.skill,10).." / "..safeText(prof.cap,10),
    "Optional integrations: Auctionator="..tostring(_G.Auctionator~=nil)..", TomTom="..tostring(_G.TomTom~=nil)..", QuestieDB="..tostring(_G.QuestieDB~=nil),
    "Capture: native="..tostring(self.nativeDiagnostics==true)..", BugGrabber="..tostring(_G.BugGrabber~=nil),
    "","Steps to reproduce / expected result:","",""}
  local errors=self.db.diagnostics or {}
  for i=math.max(1,#errors-4),#errors do
    local entry=errors[i]
    lines[#lines+1]="Error "..i.." ("..(tonumber(entry.count) or 1).."x; "..safeText(entry.version,80)..")"
    lines[#lines+1]=safeText(entry.message,1500);lines[#lines+1]=safeText(entry.stack,3500);lines[#lines+1]=""
  end
  if #errors==0 then lines[#lines+1]="No CraftPilot Lua errors captured." end
  return table.concat(lines,"\n")
end
local function encode(s) return (s:gsub("([^%w%-_.~])",function(c) return string.format("%%%02X",string.byte(c)) end)) end
function CP:DiagnosticIssueURL(report)
  report=safeText(report,12000)
  -- Keep the copyable link short enough for browser address bars. Full text remains in the preview.
  local body=report
  local suffix="\n[Report shortened for link. Paste full preview if needed.]"
  while #encode(body)>5500 do body=body:sub(1,math.max(0,#body-200)) end
  if body~=report then body=body..suffix end
  return "https://github.com/Necrite82/CraftPilot/issues/new?title="..encode("[Bug] CraftPilot "..self.version).."&body="..encode(body)
end
function CP:OpenDiagnosticReport()
  if not self.diagnosticWindow then
    local frame=CreateFrame("Frame","CraftPilotDiagnosticWindow",UIParent,"BackdropTemplate")
    frame:SetSize(650,590);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(.045,.06,.075,.99);frame:SetBackdropBorderColor(.75,.57,.25,1)
    local function label(y,text)
      local fs=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
      fs:SetPoint("TOPLEFT",22,y);fs:SetWidth(600);fs:SetJustifyH("LEFT");fs:SetText(text);return fs
    end
    label(-22,L("Fehler melden"))
    label(-53,L("Bericht prüfen und ergänzen. Link auswählen, Strg+C, im Browser einfügen und GitHub-Issue absenden. Ein GitHub-Konto ist erforderlich."))
    local scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",22,-105);scroll:SetPoint("BOTTOMRIGHT",-46,165)
    local report=CreateFrame("EditBox",nil,scroll)
    report:SetMultiLine(true);report:SetAutoFocus(false);report:SetFontObject(ChatFontNormal);report:SetSize(575,280)
    report:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    local measure=frame:CreateFontString(nil,"OVERLAY","ChatFontNormal")
    measure:SetWidth(575);measure:Hide()
    report:SetScript("OnTextChanged",function(box)
      measure:SetText(box:GetText())
      local height=measure:GetStringHeight()
      box:SetHeight(math.max(280,type(height)=="number" and height+40 or 280));scroll:UpdateScrollChildRect()
    end)
    report:SetScript("OnCursorChanged",function(_,_,y,_,height)
      local offset=scroll:GetVerticalScroll()
      if -y<offset then scroll:SetVerticalScroll(-y)
      elseif -y+height>offset+scroll:GetHeight() then scroll:SetVerticalScroll(-y+height-scroll:GetHeight()) end
    end)
    scroll:SetScrollChild(report);frame.report=report
    label(-435,L("Der Link enthält den Bericht. Beim Öffnen wird er an GitHub übertragen. Bitte vorab prüfen; keine Chat- oder Inventardaten werden gesammelt."))
    local link=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
    link:SetSize(600,26);link:SetPoint("BOTTOMLEFT",24,72);link:SetAutoFocus(false)
    link:SetScript("OnEscapePressed",function(box) box:ClearFocus() end);frame.link=link
    local function button(x,width,text,action)
      local b=CreateFrame("Button",nil,frame,"BackdropTemplate");CP:StyleActionButton(b)
      b:SetSize(width,28);b:SetPoint("BOTTOMLEFT",x,24);b:SetText(text);b:SetScript("OnClick",action)
    end
    button(22,185,L("GitHub-Link kopieren"),function()
      link:SetText(CP:DiagnosticIssueURL(report:GetText()));link:SetFocus();link:HighlightText()
    end)
    button(217,185,L("Bericht kopieren"),function() report:SetFocus();report:HighlightText() end)
    button(412,210,L("Lokale Fehler löschen"),function()
      CP.db.diagnostics={};CP.diagnosticNotice=nil;report:SetText(CP:BuildDiagnosticReport());link:SetText("")
    end)
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-5,-5);close:SetScript("OnClick",function() frame:Hide() end)
    UISpecialFrames[#UISpecialFrames+1]="CraftPilotDiagnosticWindow";self.diagnosticWindow=frame
  end
  self.diagnosticWindow.report:SetText(self:BuildDiagnosticReport());self.diagnosticWindow.link:SetText("");self.diagnosticWindow:Show()
end
function CP:InitializeDiagnostics()
  if self.diagnosticsReady then return end
  self.diagnosticsReady=true
  -- Native listener leaves the game's global error handler and secure click paths untouched.
  if type(AddLuaErrorHandler)=="function" then
    self.nativeDiagnostics=pcall(AddLuaErrorHandler,function(message,stack) CP:CaptureDiagnostic(message,stack) end)
  end
  local events=CreateFrame("Frame")
  for _,event in ipairs({"ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN"}) do pcall(events.RegisterEvent,events,event) end
  events:SetScript("OnEvent",function(_,event,addon,func)
    if addon=="CraftPilot" then CP:CaptureDiagnostic(event..": CraftPilot",safeText(func,500),true) end
  end)
  if EventRegistry and type(EventRegistry.RegisterCallback)=="function" then
    EventRegistry:RegisterCallback("BugGrabber.BugGrabbed",function() CP:ImportBugGrabberDiagnostics() end,self)
  end
end
