local _, CP = ...
local D = CP.Data

local W, H = 750, 676
local GOLD = "|cffffd878"
local BLUE = "|cff79c6f1"
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
  if CP.ellesmereSkin and type(CP.ellesmereSkin.Button)=="function" then
    pcall(CP.ellesmereSkin.Button,b)
  end
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
if type(frame.SetResizable)=="function" then frame:SetResizable(true) end
if type(frame.SetResizeBounds)=="function" then
  frame:SetResizeBounds(750,570,1100,930)
elseif type(frame.SetMinResize)=="function" then
  frame:SetMinResize(750,570)
  if type(frame.SetMaxResize)=="function" then frame:SetMaxResize(1100,930) end
end
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
local build = text(header, "GameFontDisableSmall", W-175, -40, 105, "v0.7.0-alpha")
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -8)
local resizeGrip=CreateFrame("Button",nil,frame)
resizeGrip:SetSize(24,24)
resizeGrip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3)
if type(resizeGrip.SetNormalTexture)=="function" then
  resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
end
resizeGrip:SetScript("OnMouseDown",function()
  if type(frame.StartSizing)=="function" then frame:StartSizing("BOTTOMRIGHT") end
end)
resizeGrip:SetScript("OnMouseUp",function()
  if type(frame.StopMovingOrSizing)=="function" then frame:StopMovingOrSizing() end
  if CP.SaveWindowPosition then CP:SaveWindowPosition() end
end)

local themeName = text(frame,"GameFontDisableSmall",18,-82,250,"")
local stageProgress=CreateFrame("StatusBar",nil,frame)
stageProgress:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-319)
stageProgress:SetSize(W-36,5)
if type(stageProgress.SetStatusBarTexture)=="function" then stageProgress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") end
if type(stageProgress.SetMinMaxValues)=="function" then stageProgress:SetMinMaxValues(0,300) end
if type(stageProgress.SetStatusBarColor)=="function" then stageProgress:SetStatusBarColor(.91,.68,.31,1) end
local skinButton = button(frame,170,23, W-198,-78,"Design: Automatisch",function()
  if not CP.db then return end
  local current=CP.db.ui.skin
  CP.db.ui.skin=current=="auto" and "dark" or (current=="dark" and "classic" or "auto")
  CP:ApplyTheme()
  CP:Render()
end)

local professionButtons={}
local professionOrder={}
for i,key in ipairs(D.order) do
  local col=(i-1)%4
  local row=math.floor((i-1)/4)
  local b=button(frame,174,27,18+col*179,-111-row*32,
    D.professions[key].name,function()
      CP:ChangeView(key,true)
  end)
  professionButtons[key]=b
  professionOrder[#professionOrder+1]=b
end

local tabs={
  {key="now", label="Jetzt skillen"},
  {key="stages", label="Etappen 1–300"},
  {key="mats", label="Materialien"},
  {key="plan", label="Einkaufsplan"},
  {key="trainers", label="Lehrer"},
  {key="help", label="Hilfe / Befehle"}
}
local tabButtons={}
local orderedTabs={}
for i,t in ipairs(tabs) do
  tabButtons[t.key]=button(frame,112,27,18+(i-1)*117,-183,t.label,function()
    CP:OpenTab(t.key)
  end)
  orderedTabs[#orderedTabs+1]=tabButtons[t.key]
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
local sortButtons={}
local sorts={
  {key="cost",label="Preis"},
  {key="chance",label="Skillchance"},
  {key="missing",label="Zukaufmenge"},
  {key="name",label="Name"},
}
for i,item in ipairs(sorts) do
  sortButtons[item.key]=button(frame,115,25,18+(i-1)*119,-358,item.label,function()
    CP.db.ui.recipeSort=item.key
    CP:Render()
  end)
  sortButtons[item.key]:Hide()
end
local bankButton=button(frame,250,25,18,-358,"Bank: einschalten",function()
  CP.db.includeBank=not CP.db.includeBank
  CP:Refresh(false)
end)
bankButton:Hide()
local bankDetails=text(frame,"GameFontDisableSmall",283,-361,410,"")
bankDetails:Hide()
trainerAction1:Hide()
trainerAction2:Hide()
trainerInfo:Hide()

-- Multi-recipe shopping planner. Numeric controls are user-editable.
local rangeLabel=text(frame,"GameFontHighlightSmall",18,-362,42,"Von")
local rangeStart=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
rangeStart:SetSize(54,24)
rangeStart:SetPoint("TOPLEFT",frame,"TOPLEFT",52,-352)
local targetLabel=text(frame,"GameFontHighlightSmall",116,-362,42,"Bis")
local rangeEnd=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
rangeEnd:SetSize(54,24)
rangeEnd:SetPoint("TOPLEFT",frame,"TOPLEFT",149,-352)
local quantityLabel=text(frame,"GameFontHighlightSmall",215,-362,52,"Menge")
local rangeQty=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
rangeQty:SetSize(50,24)
rangeQty:SetPoint("TOPLEFT",frame,"TOPLEFT",266,-352)
for _,field in ipairs({rangeStart,rangeEnd,rangeQty}) do
  if type(field.SetNumeric)=="function" then field:SetNumeric(true) end
  if type(field.SetAutoFocus)=="function" then field:SetAutoFocus(false) end
  field:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  field:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
end
local function fieldNumber(field,fallback)
  local value=type(field.GetText)=="function" and field:GetText() or nil
  return tonumber(value) or fallback
end
local rangeApply=button(frame,93,25,332,-352,"Bereich OK",function()
  local p=CP:PlanFor(CP.db.view)
  if CP:SetPlanRange(CP.db.view,fieldNumber(rangeStart,p.start),
      fieldNumber(rangeEnd,p.target)) then CP:Render()
  else CP:Say("Bereich 1–300: Start muss kleiner als Ziel sein.") end
end)
local planAdd=button(frame,142,25,431,-352,"Rezept +",function()
  local key=CP.db.view
  local chosen=CP:SelectedOption(key)
  if not chosen then CP:Say("Bitte erst ein aktuelles Rezept wählen.");return end
  if CP:AddPlanCraft(key,chosen.id,fieldNumber(rangeQty,1)) then CP:Render()
  else CP:Say("Rezept oder Menge ungültig.") end
end)
local planDraft=button(frame,152,25,18,-383,"Schnellschritt +10",function()
  if CP:DraftPlanStep(CP.db.view) then CP:Render() end
end)
local planPrint=button(frame,132,25,177,-383,"Liste im Chat",function()
  CP:PrintPlanShopping(CP.db.view)
end)
local planClear=button(frame,112,25,314,-383,"Plan leeren",function()
  CP:ClearPlanCraft(CP.db.view)
  CP:Render()
end)
local planHint=text(frame,"GameFontDisableSmall",435,-386,285,"Nur bekannte Rezepte")
local planControls={rangeLabel,rangeStart,targetLabel,rangeEnd,quantityLabel,
 rangeQty,rangeApply,planAdd,planDraft,planPrint,planClear,planHint}
local syncedPlan
local function syncPlanFields(key)
  local p=CP:PlanFor(key)
  local marker=key..":"..p.start..":"..p.target
  if marker==syncedPlan then return end
  syncedPlan=marker
  rangeStart:SetText(tostring(p.start))
  rangeEnd:SetText(tostring(p.target))
  rangeQty:SetText("1")
end

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
local recipeButtons={}
local visualCards={}
local function gold(value)
  if type(value)~="number" then return "Preis fehlt" end
  local v=math.floor(value+0.5)
  return string.format("%dg %ds %dc",math.floor(v/10000),
    math.floor((v%10000)/100),v%100)
end

local function clearRows()
  for _,r in ipairs(rows) do r:Hide() end
  for _,b in ipairs(trainerButtons) do b:Hide() end
  for _,b in ipairs(recipeButtons) do b:Hide() end
  for _,b in ipairs(visualCards) do b:Hide() end
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

-- CraftPilot's original visual indicators use native flat textures, not
-- artwork copied from another addon. Recipe icons come from the game client.
local function setRecipeRows(key,options,chosen)
  clearRows()
  for i,entry in ipairs(options) do
    local b=recipeButtons[i]
    if not b then
      b=button(content,W-113,57,5,-(i-1)*61,"",function()
        if b.craftRecipe and CP.db then
          CP.db.ui.selectedRecipes[CP.db.view]=b.craftRecipe.id
          CP:Render()
        end
      end)
      b.nameLabel=text(b,"GameFontHighlight",48,-7,W-180,"")
      b.infoLabel=text(b,"GameFontDisableSmall",48,-30,W-180,"")
      if type(b.CreateTexture)=="function" then
        local icon=b:CreateTexture(nil,"ARTWORK")
        if icon then
          icon:SetSize(35,35)
          icon:SetPoint("LEFT",b,"LEFT",9,0)
          b.craftIcon=icon
          if CP.ellesmereSkin and type(CP.ellesmereSkin.SquareIcon)=="function" then
            pcall(CP.ellesmereSkin.SquareIcon,icon,b)
          end
        end
        local marker=b:CreateTexture(nil,"OVERLAY")
        if marker then
          marker:SetSize(3,45)
          marker:SetPoint("LEFT",b,"LEFT",1,0)
          b.craftStripe=marker
        end
      end
      recipeButtons[i]=b
    end
    b.craftRecipe=entry
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-(i-1)*61)
    b:SetSize((type(content.GetWidth)=="function" and content:GetWidth() or (W-95))-8,57)
    if b.craftIcon and type(b.craftIcon.SetTexture)=="function" then
      local texture=entry.icon
      if not texture and entry.outputItemID and C_Item and type(C_Item.GetItemIconByID)=="function" then
        local ok,value=pcall(C_Item.GetItemIconByID,entry.outputItemID)
        if ok then texture=value end
      end
      b.craftIcon:SetTexture(texture or "Interface\\Icons\\INV_Misc_Note_01")
    end
    if b.craftStripe and type(b.craftStripe.SetColorTexture)=="function" then
      if chosen and entry.id==chosen.id then
        b.craftStripe:SetColorTexture(.20,.81,.66,.95)
      else
        b.craftStripe:SetColorTexture(.37,.48,.67,.70)
      end
    end
    local active=chosen and entry.id==chosen.id
    b.nameLabel:SetText((active and GREEN.."● AUSGEWÄHLT  "..RESET or "")
      ..entry.name)
    local price=entry.unknown and ("AH-Preis unvollständig") or gold(entry.cost)
    b.infoLabel:SetText(string.format("Skill %.0f%%  •  %s / Skillpunkt  •  %d Materialien fehlen",
      entry.chance*100,price,entry.missing))
    b:Show()
  end
  content:SetHeight(math.max(270,#options*61+16))
  if type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
end

-- Shared visual cards for stages, materials and shopping plans.
-- Graphics are composed from native flat textures and client-provided item icons.
local function setVisualCards(entries)
  clearRows()
  local cardHeight=73
  for i,entry in ipairs(entries) do
    local b=visualCards[i]
    if not b then
      b=CreateFrame("Button",nil,content,"BackdropTemplate")
      b:SetSize(W-110,cardHeight-5)
      b:SetBackdrop(backdrop)
      b.titleLabel=text(b,"GameFontNormal",55,-7,W-170,"")
      b.detailLabel=text(b,"GameFontHighlightSmall",55,-30,W-170,"")
      b.footLabel=text(b,"GameFontDisableSmall",55,-51,W-170,"")
      if type(b.CreateTexture)=="function" then
        b.craftIcon=b:CreateTexture(nil,"ARTWORK")
        if b.craftIcon then
          b.craftIcon:SetSize(32,32)
          b.craftIcon:SetPoint("LEFT",b,"LEFT",12,3)
        end
        b.craftStripe=b:CreateTexture(nil,"OVERLAY")
        if b.craftStripe then
          b.craftStripe:SetSize(3,52)
          b.craftStripe:SetPoint("LEFT",b,"LEFT",2,0)
        end
        b.craftDot=b:CreateTexture(nil,"OVERLAY")
        if b.craftDot then
          b.craftDot:SetSize(8,8)
          b.craftDot:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",22,8)
        end
      end
      b:SetScript("OnClick",function()
        if type(b.craftAction)=="function" then b.craftAction() end
      end)
      visualCards[i]=b
      if CP.ellesmereSkin and type(CP.ellesmereSkin.Panel)=="function" then
        pcall(CP.ellesmereSkin.Panel,b)
      end
    end
    b.craftAction=entry.action
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-(i-1)*cardHeight)
    b:SetSize((type(content.GetWidth)=="function" and content:GetWidth() or W-95)-8,cardHeight-5)
    local r,g,bl=.32,.47,.69
    if entry.color=="green" then r,g,bl=.19,.75,.55 end
    if entry.color=="gold" then r,g,bl=.90,.69,.28 end
    if entry.color=="red" then r,g,bl=.93,.42,.36 end
    if type(b.SetBackdropColor)=="function" and not CP.ellesmereSkin then
      b:SetBackdropColor(.08,.10,.13,.85)
    end
    if b.craftStripe and type(b.craftStripe.SetColorTexture)=="function" then
      b.craftStripe:SetColorTexture(r,g,bl,1)
    end
    if b.craftDot and type(b.craftDot.SetColorTexture)=="function" then
      b.craftDot:SetColorTexture(r,g,bl,1)
    end
    if b.craftIcon and type(b.craftIcon.SetTexture)=="function" then
      b.craftIcon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_Note_01")
    end
    b.titleLabel:SetText(entry.title or "")
    b.detailLabel:SetText(entry.detail or "")
    b.footLabel:SetText(entry.footer or "")
    b:Show()
  end
  content:SetHeight(math.max(280,#entries*cardHeight+15))
  if type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
end

local function itemIcon(id)
  if C_Item and type(C_Item.GetItemIconByID)=="function" then
    local ok,texture=pcall(C_Item.GetItemIconByID,id)
    if ok and texture then return texture end
  end
  return "Interface\\Icons\\INV_Misc_Bag_08"
end

local function materialCards(materials,caption)
  local entries={}
  if caption then entries[#entries+1]={
    title=caption,detail="Taschen live · Bank letzter Stand · AH-Preise aus gespeichertem Scan",
    footer="Nicht erfasste Bankmaterialien gelten nicht als bestätigt vorhanden.",color="gold",
    icon="Interface\\Icons\\INV_Misc_Bag_08"}
  end
  for _,m in ipairs(materials) do
    local qty=m.required or m[2] or 0
    local id=m.id or m[1]
    local total,bags,bank,live,known=CP:ItemAvailability(id)
    local missing=math.max(0,qty-total)
    local price=CP:Price(id)
    local status=live and "LIVE" or (known and "LETZTER STAND" or "UNBEKANNT")
    entries[#entries+1]={
      title=(CP:ItemName(id)).."  ·  benötigt "..qty.."  ·  fehlt "..missing,
      detail="Tasche "..bags.."  ·  Bank "..bank.." ("..status..")  ·  Gesamt "..total,
      footer=missing>0 and (price and "Voraussichtlicher Zukauf "..gold(missing*price)
        or "Für fehlende Materialien liegt kein AH-Preis vor")
        or "✓ Genügend Material laut erfasstem Bestand",
      icon=itemIcon(id),color=missing>0 and "red" or "green"
    }
  end
  if #entries==0 then entries[1]={
    title="Keine Materialien",detail="Rezept im Tab Jetzt skillen auswählen.",
    icon="Interface\\Icons\\INV_Misc_Note_01"} end
  setVisualCards(entries)
end

local footer=text(frame,"GameFontDisableSmall",19,-645,W-40,
  "Alpha: Keine automatischen Käufe oder Herstellungsaktionen. Preise sind AH-Snapshots.")

local helpRows={
  GOLD.."ALLGEMEIN"..RESET,
  "/cp".."     Fenster öffnen / schließen",
  "/cp hilfe".."     Diese Hilfe öffnen",
  "/cp etappen".."     Skill-Etappen anzeigen",
  "/cp plan".."     Planer für frei wählbaren Skillbereich",
  "/cp einkauf".."     Plan-Einkaufsliste im Chat",
  "/cp autoopen on|off".."     Berufsfenster beim Klick automatisch öffnen",
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
  "/cp sort cost|chance|missing|name".."     Rezeptsortierung",
  "Im Einkaufsplan Start, Ziel und Menge eintragen; Rezept hinzufügen.",
  "Schnellschritt +10: vorsichtige Empfehlung für nur den nächsten Abschnitt.",
  "Ein Skillbereich 30–100 verlangt ggf. weitere, noch unbekannte Rezepte.",
  "Bankbestand wird beim Öffnen des Bankschalters erfasst.",
  "Ein letzter Bankstand kann veraltet sein – vor größeren Einkäufen prüfen.",
  GOLD.."BERUFE"..RESET,
  "/cp ingi".."   Ingenieurskunst      /cp bergbau   Bergbau",
  "/cp schmied".."   Schmiedekunst       /cp vz   Verzauberkunst",
  "/cp schneider".."   Schneiderei          /cp leder   Lederverarbeitung",
  "/cp kraeuter".."   Kräuterkunde         /cp alchemie   Alchemie",
  GOLD.."TIPPS"..RESET,
  "Lehrer mit einem Klick auswählen: alle Einträge in der Lehrer-Liste sind anklickbar.",
  "NÄHE ist nur auf derselben Karte vergleichbar – kein automatisches Reiserouting.",
  "Ein externes UI verändert nicht automatisch jedes fremde Addon. Auto unterstützt",
  "vorhandene Blizzard-Templates und, wenn verfügbar, die EllesmereUI-Schnittstelle."
}

-- Official EllesmereUI third-party skinning API (not copied UI assets).
local function useSkin(S,fn,...)
  if S and type(S[fn])=="function" then
    pcall(S[fn],...)
  end
end

local function registerEllesmereUI()
  local eui=_G.EllesmereUI
  if type(eui)~="table" or type(eui.RegisterSkin)~="function" then return end
  pcall(eui.RegisterSkin,"CraftPilot",function(S)
    CP.ellesmereSkin=S
    useSkin(S,"Shell",frame)
    useSkin(S,"Panel",header)
    useSkin(S,"Panel",summary)
    useSkin(S,"Panel",contentPanel)
    useSkin(S,"CloseButton",close)
    for _,b in ipairs(allButtons) do useSkin(S,"Button",b) end
    for _,b in ipairs(orderedTabs) do useSkin(S,"Tab",b) end
    if scroll.ScrollBar then useSkin(S,"ScrollBar",scroll.ScrollBar) end
    useSkin(S,"ApplyBarFill",stageProgress)
    if CP.db then CP:ApplyTheme() end
  end)
end

function CP:ApplyTheme()
  if not self.db then return end
  local pref=self.db.ui.skin or "auto"
  local hasEUI=pref=="auto" and type(self.ellesmereSkin)=="table"
  local name=pref=="classic" and "Klassisch" or (pref=="dark" and "Dunkel" or "Automatisch")
  local dark=pref~="classic"
  local palette=dark and {0.065,0.075,0.092} or {0.16,0.115,0.07}
  local sub=dark and {0.11,0.125,0.145} or {0.22,0.16,0.095}
  local border=dark and {0.36,0.32,0.24,1} or {0.56,0.40,0.23,1}
  -- Leave all Ellesmere surfaces alone in Auto. Ellesmere manages its own theme
  -- and any future live recoloring.
  if not hasEUI then
    color(frame,palette[1],palette[2],palette[3],0.98,border)
    color(header,sub[1],sub[2],sub[3],0.99,border)
    color(summary,sub[1],sub[2],sub[3],0.96,border)
    color(contentPanel,palette[1],palette[2],palette[3],0.88,border)
  end
  skinButton:SetText("Design: "..name)
  themeName:SetText("Oberfläche: "..(hasEUI and "EllesmereUI"
    or (pref=="auto" and "Blizzard / Standard" or name)))
end

local restored=false
function CP:RestoreWindowPosition()
  if restored or not self.db then return end
  restored=true
  local width=math.max(750,math.min(1100,self.db.ui.width or W))
  local height=math.max(570,math.min(930,self.db.ui.height or H))
  frame:SetSize(width,height)
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
  local width=type(frame.GetWidth)=="function" and frame:GetWidth()
  local height=type(frame.GetHeight)=="function" and frame:GetHeight()
  if type(width)=="number" then self.db.ui.width=math.max(750,math.min(1100,width)) end
  if type(height)=="number" then self.db.ui.height=math.max(570,math.min(930,height)) end
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

local function layout()
  local width=type(frame.GetWidth)=="function" and frame:GetWidth() or W
  local height=type(frame.GetHeight)=="function" and frame:GetHeight() or H
  if type(width)~="number" then width=W end
  if type(height)~="number" then height=H end
  local inner=width-36
  header:SetWidth(width-20)
  summary:SetWidth(inner)
  stageProgress:SetWidth(inner)
  content:SetWidth(width-96)
  title:SetWidth(math.max(290,width-240))
  subtitle:SetWidth(math.max(290,width-240))
  build:ClearAllPoints()
  build:SetPoint("TOPRIGHT",header,"TOPRIGHT",-42,-40)
  skinButton:ClearAllPoints()
  skinButton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-18,-78)
  status:SetWidth(inner-26)
  rankText:SetWidth(inner-26)
  priceText:SetWidth(inner-26)
  section:SetWidth(inner)
  footer:ClearAllPoints()
  footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",19,22)
  footer:SetWidth(width-62)
  local profWidth=(inner-15)/4
  for i,b in ipairs(professionOrder) do
    b:ClearAllPoints()
    b:SetSize(profWidth,27)
    b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+((i-1)%4)*(profWidth+5),
      -111-math.floor((i-1)/4)*32)
  end
  local tabWidth=(inner-20)/6
  for i,b in ipairs(orderedTabs) do
    b:ClearAllPoints()
    b:SetSize(tabWidth,27)
    b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(i-1)*(tabWidth+4),-183)
  end
  for _,row in ipairs(rows) do row:SetWidth(width-113) end
  for _,b in ipairs(trainerButtons) do
    b:SetWidth(width-113)
  end
  for _,b in ipairs(recipeButtons) do
    b:SetWidth(width-113)
    if b.nameLabel then b.nameLabel:SetWidth(width-180) end
    if b.infoLabel then b.infoLabel:SetWidth(width-180) end
  end
end
frame:SetScript("OnSizeChanged",function() layout() end)
layout()
registerEllesmereUI()

function CP:OpenTab(tab)
  if not self.db then return end
  local valid={now=true,stages=true,mats=true,plan=true,trainers=true,help=true}
  if not valid[tab] then return end
  self.db.ui.tab=tab
  frame:Show()
  self:Render()
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
  if type(stageProgress.SetValue)=="function" then
    stageProgress:SetValue(math.max(0,math.min(300,skill)))
  end

  for k,b in pairs(professionButtons) do
    b:SetText((k==key and GOLD.."● "..RESET or "")..D.professions[k].name)
  end
  for k,b in pairs(tabButtons) do
    local label
    for _,t in ipairs(tabs) do if t.key==k then label=t.label;break end end
    b:SetText((k==tab and GOLD.."● "..RESET or "")..(label or k))
    local S=self.ellesmereSkin
    if S and self.db.ui.skin=="auto" and type(S.SetTabSelection)=="function" then
      pcall(S.SetTabSelection,b,k==tab)
    end
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
  priceText:SetText("Preis: "..(self.db.mode=="cash" and "Zukauf" or "Materialwert")
    .."  |  "..self:BankStatus()
    .."  |  AH: gespeicherter Scan")

  local isTrainers=tab=="trainers"
  local isRecipes=tab=="now" and not prof.gathering
  local isMats=tab=="mats" and not prof.gathering
  trainerAction1:SetShown(isTrainers)
  trainerAction2:SetShown(isTrainers)
  trainerInfo:SetShown(isTrainers)
  for _,mode in ipairs(sorts) do
    local b=sortButtons[mode.key]
    b:SetShown(isRecipes)
    b:SetText((self.db.ui.recipeSort==mode.key and "● " or "")..mode.label)
  end
  bankButton:SetShown(isMats)
  bankDetails:SetShown(isMats)
  bankButton:SetText("Bankmaterialien: "..(self.db.includeBank and "AN" or "AUS"))
  bankDetails:SetText(self:BankStatus())
  contentPanel:ClearAllPoints()
  contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,
    (isTrainers or isRecipes or isMats) and -395 or -358)
  contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,49)

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
    local chosen,options=self:SelectedOption(key)
    local captured=self.db.lastCapture
    local current=captured and captured.key==key and captured.skill==skill
    if tab=="mats" then
      section:SetText("Materialbedarf für das ausgewählte Rezept")
      if #options==0 then
        lines[#lines+1]="Kein geeignetes eingelesenes Rezept. Berufsfenster öffnen."
      else
        local best=chosen
        lines[#lines+1]=GOLD.."AUSWAHL  "..RESET..best.name
        lines[#lines+1]=MUTED.."Bankbestände sind nur beim Bankbesuch aktuell geprüft."..RESET
        for _,mat in ipairs(best.mats) do
          local total,bag,bank,live,known=self:ItemAvailability(mat[1])
          local deficit=math.max(0,mat[2]-total)
          local price=self:Price(mat[1])
          local marker=self.db.includeBank and (live and "Bank live" or (known and "letzter Stand" or "unbekannt")) or "nur Tasche"
          lines[#lines+1]=string.format("%s: %d benötigt | Tasche %d | Bank %d (%s)",
            self:ItemName(mat[1]),mat[2],bag,bank,marker)
          if deficit>0 then
            lines[#lines+1]=string.format("  → %d nachkaufen | %s",
              deficit,price and gold(price*deficit) or "Preis fehlt")
          else
            lines[#lines+1]=GREEN.."  ✓ Material vorhanden"..RESET
          end
        end
      end
    else
      section:SetText("Erlernte Rezepte – geschätzte Kosten je Skillpunkt")
      if not current then
        lines[#lines+1]="Berufsfenster öffnen und Aktualisieren drücken."
        lines[#lines+1]="Nur aktuelle Skillfarben lassen sich sinnvoll vergleichen."
      elseif #options==0 then
        lines[#lines+1]="Keine aktuell auswertbaren Rezepte mit eindeutigen Materialien."
      else
        section:SetText("Rezept anklicken = auswählen  |  Sortierung oben ändern")
      end
    end
    if not record then
      lines[#lines+1]="Beruf noch nicht auf diesem Charakter erfasst."
    end
    if tab=="now" and current and #options>0 then
      setRecipeRows(key,options,chosen)
    else
      setRows(lines)
    end
  end
  footer:SetText("CraftPilot 0.7 Alpha  |  Materialliste: geplante Mengen, keine Skillgarantie  |  /cp hilfe")
end

function CP:ToggleWindow()
  if frame:IsShown() then frame:Hide();return end
  self:Refresh(true)
  frame:Show()
end
