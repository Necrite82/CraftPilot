local _, CP = ...
local D = CP.Data

local W, H = 750, 676
local GOLD = "|cffffd878"
local GREEN = "|cff89e1aa"
local MUTED = "|cff9dabb8"
local RESET = "|r"

local function text(parent, font, x, y, width, value)
  local node = parent:CreateFontString(nil, "OVERLAY", font)
  node:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  node:SetWidth(width)
  node:SetJustifyH("LEFT")
  node:SetText(value or "")
  return node
end

local allButtons = {}
local function button(parent, width, height, x, y, caption, callback)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, height)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetText(caption)
  b:SetScript("OnClick", callback)
  allButtons[#allButtons+1] = b
  return b
end

local function color(frame, r, g, b, a, border)
  if frame and type(frame.SetBackdropColor) == "function" then
    frame:SetBackdropColor(r, g, b, a or 1)
  end
  if frame and type(frame.SetBackdropBorderColor) == "function" and border then
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
  end
end

local backdrop = {
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14,
  insets = {left=3,right=3,top=3,bottom=3}
}
local frame = CreateFrame("Frame", "CraftPilotMainFrame", UIParent, "BackdropTemplate")
frame:SetSize(W, H)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop(backdrop)
frame:SetMovable(true)
frame:EnableMouse(true)
if type(frame.SetClampedToScreen)=="function" then frame:SetClampedToScreen(true) end
frame:Hide()
CP.frame = frame
if type(UISpecialFrames)=="table" then
  table.insert(UISpecialFrames, "CraftPilotMainFrame")
end

local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
header:SetSize(W-20, 64)
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
header:SetBackdrop(backdrop)
header:EnableMouse(true)
header:RegisterForDrag("LeftButton")
header:SetScript("OnDragStart", function()
  if type(frame.StartMoving)=="function" then frame:StartMoving() end
end)
header:SetScript("OnDragStop", function()
  if type(frame.StopMovingOrSizing)=="function" then frame:StopMovingOrSizing() end
  if CP.SaveWindowPosition then CP:SaveWindowPosition() end
end)
local title = text(header, "GameFontNormalLarge", 16, -12, 410, "CRAFTPILOT")
local subtitle = text(header, "GameFontHighlightSmall", 16, -36, 450,
  "WoW Forever  |  Acht Berufe  |  Skill 1–300  |  Ziehen zum Verschieben")
local build = text(header, "GameFontDisableSmall", W-175, -40, 105, "v0.5.0-alpha")
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -8)

local themeName = text(frame,"GameFontDisableSmall",18,-82,250,"")
local skinButton = button(frame,170,23, W-198,-78,"Design: Automatisch",function()
  if not CP.db then return end
  local current=CP.db.ui.skin
  CP.db.ui.skin=current=="auto" and "dark" or (current=="dark" and "classic" or "auto")
  CP:ApplyTheme()
  CP:Render()
end)

local professionButtons={}
for i,key in ipairs(D.order) do
  local col=(i-1)%4
  local row=math.floor((i-1)/4)
  local b=button(frame,174,27,18+col*179,-111-row*32,
    D.professions[key].name,function()
      CP:ChangeView(key)
  end)
  professionButtons[key]=b
end

local tabs={
  {key="now", label="Jetzt skillen"},
  {key="stages", label="Etappen 1–300"},
  {key="mats", label="Materialien"},
  {key="trainers", label="Lehrer"},
  {key="help", label="Hilfe / Befehle"}
}
local tabButtons={}
for i,t in ipairs(tabs) do
  tabButtons[t.key]=button(frame,139,27,18+(i-1)*143,-183,t.label,function()
    CP:OpenTab(t.key)
  end)
end

local summary = CreateFrame("Frame", nil, frame, "BackdropTemplate")
summary:SetSize(W-36,92)
summary:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-226)
summary:SetBackdrop(backdrop)
local status=text(summary,"GameFontNormal",14,-11,W-65,"")
local rankText=text(summary,"GameFontHighlightSmall",14,-37,W-65,"")
local priceText=text(summary,"GameFontDisableSmall",14,-64,W-65,"")
local section=text(frame,"GameFontNormal",19,-334,W-50,"")

local trainerAction1=button(frame,196,25,18,-358,"Empfohlenen Lehrer markieren",function()
  CP:TrainerWaypoint()
end)
local trainerAction2=button(frame,186,25,220,-358,"Nächsten markieren",function()
  CP:TrainerWaypoint("nearest")
end)
local trainerInfo=text(frame,"GameFontDisableSmall",425,-361,285,"")
trainerAction1:Hide()
trainerAction2:Hide()
trainerInfo:Hide()

local contentPanel=CreateFrame("Frame",nil,frame,"BackdropTemplate")
contentPanel:SetBackdrop(backdrop)
contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-358)
contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,49)

local scroll=CreateFrame("ScrollFrame","CraftPilotScroll",contentPanel,
  "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",contentPanel,"TOPLEFT",10,-8)
scroll:SetPoint("BOTTOMRIGHT",contentPanel,"BOTTOMRIGHT",-31,8)

local content=CreateFrame("Frame",nil,scroll)
content:SetWidth(W-96)
content:SetHeight(320)
scroll:SetScrollChild(content)

local rows={}
local trainerButtons={}
local function clearRows()
  for _,r in ipairs(rows) do r:Hide() end
  for _,b in ipairs(trainerButtons) do b:Hide() end
end

local function setRows(lines)
  clearRows()
  for i,entry in ipairs(lines) do
    local row=rows[i]
    if not row then
      row=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
      row:SetPoint("TOPLEFT",content,"TOPLEFT",5,-(i-1)*35)
      row:SetWidth(W-113)
      row:SetHeight(35)
      row:SetJustifyV("TOP")
      row:SetJustifyH("LEFT")
      row:SetWordWrap(true)
      rows[i]=row
    end
    row:SetText(entry)
    row:Show()
  end
  content:SetHeight(math.max(270,#lines*35+16))
  if type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
end

local function setTrainerRows(choices,recommended,nearest,selected)
  clearRows()
  for i,entry in ipairs(choices) do
    local b=trainerButtons[i]
    if not b then
      b=button(content,W-113,31,5,-(i-1)*36,"",function()
        local current=b.craftTrainer
        if current then
          CP.db.ui.selectedTrainers[CP.db.view]=current.name
          CP:SetWaypoint(current)
          CP:Render()
        end
      end)
      trainerButtons[i]=b
    end
    local npc=entry.npc
    b.craftTrainer=npc
    local flags=""
    if npc==recommended then flags=GREEN.."[EMPFOHLEN] "..RESET end
    if npc==nearest then flags=flags..GOLD.."[NAH] "..RESET end
    if selected==npc.name then flags=flags.."[GEWÄHLT] " end
    local cap=entry.canTeach and ("bis "..npc.cap)
      or (MUTED.."nur bis "..npc.cap..RESET)
    local metric=entry.distance and string.format(" | Kartenabstand %.1f",entry.distance)
      or (entry.inZone and " | gleiche Zone" or " | andere Zone")
    b:SetText(flags..npc.name.." — "..npc.zone.." | "..cap..metric)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-(i-1)*36)
    b:Show()
  end
  content:SetHeight(math.max(270,#choices*36+12))
  if type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
end

local footer=text(frame,"GameFontDisableSmall",19,-645,W-40,
  "Alpha: Keine automatischen Käufe oder Herstellungsaktionen. Preise sind AH-Snapshots.")

local helpRows={
  GOLD.."ALLGEMEIN"..RESET,
  "/cp".."     Fenster öffnen / schließen",
  "/cp hilfe".."     Diese Hilfe öffnen",
  "/cp etappen".."     Skill-Etappen anzeigen",
  "/cp lehrer".."     Alle Lehrer mit Wegpunkten anzeigen",
  "/cp trainer".."     Empfohlenen Lehrer markieren",
  "/cp naechster".."     Nächsten Lehrer auf derselben Karte markieren",
  "/cp resetpos".."     Fensterposition zurücksetzen",
  "/cp skin auto|dark|classic".."     Darstellung wählen",
  GOLD.."PLANUNG & PREISE"..RESET,
  "/cp refresh".."     Geöffnetes Berufsfenster erneut einlesen",
  "/cp liste".."     Fehlende Materialien für die nächste Herstellung",
  "/cp mode cash".."     Nur zusätzlichen Zukauf berücksichtigen",
  "/cp mode value".."     Marktwert vorhandener Materialien mitrechnen",
  "/cp bank on|off".."     Bankbestände ein- oder ausschließen",
  GOLD.."BERUFE"..RESET,
  "/cp ingi".."   Ingenieurskunst      /cp bergbau   Bergbau",
  "/cp schmied".."   Schmiedekunst       /cp vz   Verzauberkunst",
  "/cp schneider".."   Schneiderei          /cp leder   Lederverarbeitung",
  "/cp kraeuter".."   Kräuterkunde         /cp alchemie   Alchemie",
  GOLD.."TIPPS"..RESET,
  "Lehrer mit einem Klick auswählen: alle Einträge in der Lehrer-Liste sind anklickbar.",
  "NÄHE ist nur auf derselben Karte vergleichbar – kein automatisches Reiserouting.",
  "Ein externes UI verändert nicht automatisch jedes fremde Addon. Auto unterstützt",
  "vorhandene Blizzard-Templates und, wenn verfügbar, die ElvUI-Skin-Schnittstelle."
}

local themeKey
function CP:ApplyTheme()
  if not self.db then return end
  local pref=self.db.ui.skin or "auto"
  local E=_G.ElvUI
  if type(E)=="table" and type(E.GetModule)~="function" and type(E[1])=="table" then E=E[1] end
  local dark=pref~="classic"
  local name=pref=="classic" and "Klassisch" or (pref=="dark" and "Dunkel" or "Automatisch")
  local palette=dark and {0.065,0.075,0.092} or {0.16,0.115,0.07}
  local sub=dark and {0.11,0.125,0.145} or {0.22,0.16,0.095}
  local border=dark and {0.36,0.32,0.24,1} or {0.56,0.40,0.23,1}
  color(frame,palette[1],palette[2],palette[3],0.98,border)
  color(header,sub[1],sub[2],sub[3],0.99,border)
  color(summary,sub[1],sub[2],sub[3],0.96,border)
  color(contentPanel,palette[1],palette[2],palette[3],0.88,border)
  skinButton:SetText("Design: "..name)
  local applied=false
  if pref=="auto" and type(E)=="table" and type(E.GetModule)=="function" then
    local ok,skins=pcall(E.GetModule,E,"Skins",true)
    if ok and type(skins)=="table" then
      if type(frame.SetTemplate)=="function" then pcall(frame.SetTemplate,frame,"Transparent") end
      if type(skins.HandleButton)=="function" then
        for _,b in ipairs(allButtons) do
          if not b.craftElvUISkinned then
            local worked=pcall(skins.HandleButton,skins,b)
            if worked then b.craftElvUISkinned=true;applied=true end
          end
        end
      end
    end
  end
  themeName:SetText("Oberfläche: "..(applied and "ElvUI-Skin"
    or ((pref=="auto" and "Blizzard / UI-Templates") or name)))
  themeKey=pref
end

local restored=false
function CP:RestoreWindowPosition()
  if restored or not self.db then return end
  restored=true
  local pos=self.db.ui.position
  if type(pos)=="table" and type(pos.point)=="string"
     and type(pos.relPoint)=="string" and type(pos.x)=="number"
     and type(pos.y)=="number" then
    frame:ClearAllPoints()
    frame:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
  end
end

function CP:SaveWindowPosition()
  if not self.db then return end
  local point,_,relPoint,x,y=frame:GetPoint(1)
  if type(point)=="string" and type(relPoint)=="string" and
     type(x)=="number" and type(y)=="number" then
    self.db.ui.position={point=point,relPoint=relPoint,x=x,y=y}
  end
end

function CP:ResetWindowPosition()
  if not self.db then return end
  self.db.ui.position=nil
  frame:ClearAllPoints()
  frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
  self:Say("Fensterposition zurückgesetzt.")
end

function CP:OpenTab(tab)
  if not self.db then return end
  local valid={now=true,stages=true,mats=true,trainers=true,help=true}
  if not valid[tab] then return end
  self.db.ui.tab=tab
  frame:Show()
  self:Render()
end

local function gold(value)
  if type(value)~="number" then return "Preis fehlt" end
  local v=math.floor(value+0.5)
  return string.format("%dg %ds %dc",math.floor(v/10000),
    math.floor((v%10000)/100),v%100)
end

function CP:Render()
  if not self.db then return end
  self:RestoreWindowPosition()
  self:ApplyTheme()
  local key=self.db.view
  local prof=D.professions[key]
  local record=self.db.professions[key]
  local skill=record and record.skill or 0
  local cap=record and record.cap or 0
  local tab=self.db.ui.tab or "now"

  for k,b in pairs(professionButtons) do
    b:SetText((k==key and GOLD.."● "..RESET or "")..D.professions[k].name)
  end
  for k,b in pairs(tabButtons) do
    local label
    for _,t in ipairs(tabs) do if t.key==k then label=t.label;break end end
    b:SetText((k==tab and GOLD.."● "..RESET or "")..(label or k))
  end

  status:SetText(GOLD..prof.name..RESET.."  |  "..(record and (skill.." / "..cap) or "Skill noch nicht eingelesen")
    .."  |  Zielskill 300")
  local nextRank=self:NextRank(key)
  if nextRank then
    local playerLevel=type(UnitLevel)=="function" and UnitLevel("player") or 0
    local needLevel=self:RankCharacterLevel(key,nextRank)
    local notices={}
    if skill<nextRank.min then notices[#notices+1]="ab Berufsskill "..nextRank.min end
    if playerLevel<needLevel then notices[#notices+1]="Charakterstufe "..needLevel.." erforderlich" end
    local qualification=#notices>0 and (" ("..table.concat(notices,", ")..")") or ""
    rankText:SetText("Nächster Ausbildungsrang: "..nextRank.name.." bis "..nextRank.cap..qualification)
  else
    rankText:SetText(record and "Höchster Ausbildungsrang erreicht"
      or "Berufsfenster oder Berufeübersicht öffnen, um Daten einzulesen")
  end
  priceText:SetText("Preis-Modus: "..(self.db.mode=="cash" and "Zukauf" or "Materialwert")
    .."  |  Bank: "..(self.db.includeBank and "ein" or "aus")
    .."  |  Auctionator: gespeicherte Preise, keine Echtzeitangebote")

  local isTrainers=tab=="trainers"
  if isTrainers then
    trainerAction1:Show()
    trainerAction2:Show()
    trainerInfo:Show()
    contentPanel:ClearAllPoints()
    contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-395)
    contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,49)
  else
    trainerAction1:Hide()
    trainerAction2:Hide()
    trainerInfo:Hide()
    contentPanel:ClearAllPoints()
    contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-358)
    contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,49)
  end

  local lines={}
  if tab=="help" then
    section:SetText("Hilfe und Slash-Befehle")
    setRows(helpRows)
  elseif tab=="trainers" then
    local choices,rank,recommended,nearest=self:TrainerChoices(key)
    section:SetText("Lehrer für "..prof.name.."  |  Eintrag anklicken = Wegpunkt")
    trainerAction1:SetEnabled(recommended~=nil)
    trainerAction2:SetEnabled(nearest~=nil)
    trainerInfo:SetText(nearest and "NAH: gleicher Kartenabschnitt"
      or "Andere Zonen: Entfernung unbekannt")
    if #choices==0 then
      setRows({"Für deine Fraktion ist noch kein Lehrer hinterlegt.",
        "Bitte einen fehlenden Lehrerstandort als GitHub-Issue melden."})
    else
      setTrainerRows(choices,recommended,nearest,self.db.ui.selectedTrainers[key])
      if self.db.ui.skin=="auto" then self:ApplyTheme() end
    end
  elseif tab=="stages" then
    section:SetText("Skill-Etappen – nach Material- und Rangwechseln")
    for _,stage in ipairs(D.stages[key]) do
      local marker=skill>=stage[2] and MUTED.."✓ BEENDET"..RESET
        or (skill>=stage[1] and skill<stage[2] and GREEN.."● JETZT"..RESET
            or "○ SPÄTER")
      lines[#lines+1]=string.format("%s   %d–%d  |  %s",
        marker,stage[1],stage[2],stage[3])
    end
    lines[#lines+1]=MUTED.."Orientierung, keine vollständige Rezeptliste oder garantierte Skillroute."..RESET
    setRows(lines)
  elseif prof.gathering then
    section:SetText(prof.name..": nächster sinnvoller Sammelbereich")
    local current=self:CurrentStage(key)
    lines[#lines+1]=GREEN.."AKTUELL"..RESET.."  |  "..(current and current[3] or "Skillstand prüfen")
    lines[#lines+1]="Für alle Skillbereiche: Registerkarte Etappen 1–300."
    lines[#lines+1]="Die Sammelorte sind Gebiets-Empfehlungen, keine festen Vorkommen."
    if key=="herbalism" then
      lines[#lines+1]="Tipp: Kräuter aufspüren einschalten."
    else
      lines[#lines+1]="Tipp: Bergbauvorkommen auf der Minikarte verfolgen."
    end
    setRows(lines)
  else
    local options=self:Options(key)
    local captured=self.db.lastCapture
    local current=captured and captured.key==key and captured.skill==skill
    if tab=="mats" then
      section:SetText("Fehlende Materialien für die nächste empfohlene Herstellung")
      if #options==0 then
        lines[#lines+1]="Kein geeignetes eingelesenes Rezept. Berufsfenster öffnen."
      else
        local best=options[1]
        lines[#lines+1]=GOLD.."EMPFEHLUNG  "..RESET..best.name
        for _,mat in ipairs(best.mats) do
          local deficit=math.max(0,mat[2]-self:ItemCount(mat[1]))
          if deficit>0 then
            local price=self:Price(mat[1])
            lines[#lines+1]=string.format("%d × %s (Bestand %d)  |  %s",
              deficit,self:ItemName(mat[1]),self:ItemCount(mat[1]),
              price and gold(price*deficit) or "kein AH-Preis")
          end
        end
        if #lines==1 then lines[#lines+1]=GREEN.."Alle Materialien vorhanden."..RESET end
      end
    else
      section:SetText("Erlernte Rezepte – geschätzte Kosten je Skillpunkt")
      if not current then
        lines[#lines+1]="Berufsfenster öffnen und Aktualisieren drücken."
        lines[#lines+1]="Nur aktuelle Skillfarben lassen sich sinnvoll vergleichen."
      elseif #options==0 then
        lines[#lines+1]="Keine aktuell auswertbaren Rezepte mit eindeutigen Materialien."
      else
        for i=1,math.min(30,#options) do
          local o=options[i]
          local p=o.unknown and "Preis unvollständig" or gold(o.cost)
          lines[#lines+1]=string.format("%d. %s | %d%% Skillchance | %s | %d Teile fehlen",
            i,o.name,math.floor(o.chance*100),p,o.missing)
        end
      end
    end
    if not record then
      lines[#lines+1]="Beruf noch nicht auf diesem Charakter erfasst."
    end
    setRows(lines)
  end
  footer:SetText("CraftPilot 0.5 Alpha  |  Keine automatischen Aktionen  |  /cp hilfe")
end

function CP:ToggleWindow()
  if frame:IsShown() then frame:Hide();return end
  self:Refresh(true)
  frame:Show()
end
