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
  local stateFrame=CreateFrame("Frame",nil,b)
  stateFrame:SetAllPoints(b)
  local marker=stateFrame:CreateTexture(nil,"OVERLAY")
  marker:SetSize(3,height-8)
  marker:SetPoint("LEFT",stateFrame,"LEFT",2,0)
  marker:SetColorTexture(.91,.68,.31,1)
  marker:Hide()
  b.selectionMarker=marker
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
-- Keep artwork on its own child: EUI Panel deliberately fades header regions.
local brandFrame=CreateFrame("Frame","CraftPilotBrandFrame",header)
brandFrame:SetSize(48,48)
brandFrame:SetPoint("TOPLEFT",header,"TOPLEFT",12,-8)
local brand=brandFrame:CreateTexture(nil,"ARTWORK")
brand:SetSize(48,48)
brand:SetAllPoints(brandFrame)
brand:SetTexture("Interface\\AddOns\\CraftPilot\\Media\\CraftPilot")
local title = text(header, "GameFontNormalLarge", 72, -12, 350, "CRAFTPILOT")
local subtitle = text(header, "GameFontHighlightSmall", 72, -36, 450,
  "WoW Forever  |  Zwölf Berufe  |  Skill 1–300  |  Ziehen zum Verschieben")
local build = text(header, "GameFontDisableSmall", W-175, -40, 105, "v0.10.2-alpha")
local settingsButton=button(header,112,23,W-270,-10,"Einstellungen",function() CP:OpenTab("settings") end)
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
local allProfessionsButton=button(frame,185,23,280,-78,"Alle Berufe anzeigen",function()
  CP.db.ui.showAllProfessions=not CP.db.ui.showAllProfessions
  if not CP.db.ui.showAllProfessions then CP:PreferOwnedProfession() end
  CP:Render()
end)
for i,key in ipairs(D.order) do
  local col=(i-1)%6
  local row=math.floor((i-1)/6)
  local b=button(frame,114,27,18+col*119,-111-row*32,
    D.professions[key].short,function()
      CP:ChangeView(key,true)
  end)
  b:SetScript("OnEnter",function()
    if GameTooltip then
      GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
      GameTooltip:SetText(D.professions[key].name)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  professionButtons[key]=b
  professionOrder[#professionOrder+1]=b
end

local tabs={
  {key="now", label="Jetzt skillen"},
  {key="stages", label="Etappen 1–300"},
  {key="mats", label="Materialien"},
  {key="plan", label="Einkaufsplan"},
  {key="trainers", label="Lehrer"},
  {key="settings", label="Einstellungen"}
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
  if CP.pendingPlanClear~=CP.db.view then
    CP.pendingPlanClear=CP.db.view
  else
    CP:ClearPlanCraft(CP.db.view)
    CP.pendingPlanClear=nil
  end
  CP:Render()
end)
local autoRouteButton=button(frame,142,25,435,-383,"Auto-Route",function()
  local key=CP.db.view
  local p=CP:PlanFor(key)
  if not CP:SetPlanRange(key,fieldNumber(rangeStart,p.start),
      fieldNumber(rangeEnd,p.target)) then
    CP:Say("Ungültiger Bereich.")
    return
  end
  local ok,route=CP:BuildRouteForCurrentPlan(key)
  if not ok then CP:Say(route or "Keine Kandidaten.") end
  CP:Render()
end)
local planHint=text(frame,"GameFontDisableSmall",588,-386,150,"GPL-Katalog")
local planControls={rangeLabel,rangeStart,targetLabel,rangeEnd,quantityLabel,
 rangeQty,rangeApply,planAdd,planDraft,planPrint,planClear,autoRouteButton,planHint}
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
local resetContentScroll=true
local lastContentContext
local trainerButtons={}
local recipeButtons={}
local visualCards={}
local function gold(value)
  return CP:FormatMoney(value)
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
  if resetContentScroll and type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
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
  if resetContentScroll and type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
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
    b.nameLabel:SetText((active and GREEN.."AUSGEWÄHLT  "..RESET or "")
      ..entry.name)
    local price=entry.unknown and "Preis unvollständig" or gold(entry.cost)
    local ids={}
    for _,mat in ipairs(entry.mats) do ids[#ids+1]=mat[1] end
    local summary=CP.PriceSummary and CP:PriceSummary(ids)
    local ageInfo=summary and (summary.stale>0 and " · AH ALT"
      or (summary.unknown>0 and " · Scan ?" or "")) or ""
    b.infoLabel:SetText(string.format("Skill %.0f%%  |  %s / Skillpunkt  |  %d Teile fehlen%s",
      entry.chance*100,price,entry.missing,ageInfo))
    b:Show()
  end
  content:SetHeight(math.max(270,#options*61+16))
  if resetContentScroll and type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
end

-- Shared visual cards for stages, materials and shopping plans.
-- Graphics are composed from native flat textures and client-provided item icons.
local function setVisualCards(entries)
  clearRows()
  local settingsView=CP.db and (CP.db.ui.tab=="settings" or CP.db.ui.tab=="help")
  local cardHeight=settingsView and 92 or 73
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
    if entry.slider then
      if not b.settingSlider then
        local slider=CreateFrame("Slider","CraftPilotSettingsSlider"..i,b,"OptionsSliderTemplate")
        b.settingSlider=slider
        slider:SetPoint("TOPLEFT",b,"TOPLEFT",60,-32)
        slider:SetHeight(18)
        for _,part in ipairs({"Low","High","Text"}) do
          local label=rawget(slider,part) or _G["CraftPilotSettingsSlider"..i..part]
          if label and type(label.Hide)=="function" then label:Hide() end
        end
        slider:SetScript("OnValueChanged",function(control,value)
          if control.craftSync then return end
          local spec=control.craftSpec
          if not spec then return end
          value=math.max(spec.min,math.min(spec.max,math.floor(value/spec.step+.5)*spec.step))
          spec.apply(value)
          b.titleLabel:SetText(spec.label..value..spec.unit)
        end)
      end
      local slider=b.settingSlider
      local spec=entry.slider
      slider.craftSync=true
      slider.craftSpec=spec
      slider:SetWidth(math.max(180,(type(b.GetWidth)=="function" and b:GetWidth() or W-110)-90))
      slider:SetMinMaxValues(spec.min,spec.max)
      slider:SetValueStep(spec.step)
      if type(slider.SetObeyStepOnDrag)=="function" then slider:SetObeyStepOnDrag(true) end
      slider:SetValue(spec.value)
      slider.craftSync=false
      slider:Show()
      b.detailLabel:Hide()
    else
      if b.settingSlider then b.settingSlider:Hide() end
      b.detailLabel:Show()
    end
    b.footLabel:ClearAllPoints()
    b.footLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,settingsView and -72 or -51)
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
  if resetContentScroll and type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
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
    local age=CP.PriceFreshness and CP:PriceFreshness(id) or "Alter unbekannt"
    local status=live and "LIVE" or (known and "LETZTER STAND" or "UNBEKANNT")
    entries[#entries+1]={
      title=(CP:ItemName(id)).."  ·  benötigt "..qty.."  ·  fehlt "..missing,
      detail="Tasche "..bags.."  ·  Bank "..bank.." ("..status..")  ·  Gesamt "..total,
      footer=(missing>0 and (price and "Zukauf "..gold(missing*price)
        or "Fehlender Preis")
        or "Genügend Material").." · "..age,
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
  title:SetWidth(math.max(240,width-400))
  settingsButton:ClearAllPoints()
  settingsButton:SetPoint("TOPRIGHT",header,"TOPRIGHT",-150,-10)
  subtitle:SetWidth(math.max(240,width-300))
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
  local profWidth=(inner-25)/6
  for _,b in pairs(professionButtons) do b:Hide() end
  for i,key in ipairs(CP.db and CP:VisibleProfessions() or D.order) do
    local b=professionButtons[key]
    b:ClearAllPoints()
    b:SetSize(profWidth,27)
    b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+((i-1)%6)*(profWidth+5),
      -111-math.floor((i-1)/6)*32)
    b:Show()
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
  for _,b in ipairs(visualCards) do
    b:SetWidth(width-113)
    if b.titleLabel then b.titleLabel:SetWidth(width-175) end
    if b.detailLabel then b.detailLabel:SetWidth(width-175) end
    if b.footLabel then b.footLabel:SetWidth(width-175) end
    if b.settingSlider then b.settingSlider:SetWidth(math.max(180,width-203)) end
  end
end
frame:SetScript("OnSizeChanged",function() layout() end)
layout()
registerEllesmereUI()

function CP:OpenTab(tab)
  if not self.db then return end
  local valid={now=true,stages=true,mats=true,plan=true,trainers=true,settings=true,help=true}
  if tab=="help" then tab="settings" end
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
  local context=key..":"..tab
  resetContentScroll=context~=lastContentContext
  lastContentContext=context
  if tab~="plan" then self.pendingPlanClear=nil end
  if tab~="settings" and tab~="help" then self.pendingSettingsReset=nil end
  local settingsView=tab=="settings" or tab=="help"
  summary:SetShown(not settingsView)
  stageProgress:SetShown(not settingsView)
  section:ClearAllPoints()
  section:SetPoint("TOPLEFT",frame,"TOPLEFT",19,settingsView and -226 or -334)
  if type(stageProgress.SetValue)=="function" then
    stageProgress:SetValue(math.max(0,math.min(300,skill)))
  end

  allProfessionsButton:SetText(self.db.ui.showAllProfessions and "Nur eigene Berufe" or "Alle Berufe anzeigen")
  for _,b in pairs(professionButtons) do b:Hide() end
  local visible=self:VisibleProfessions()
  local profWidth=((type(frame.GetWidth)=="function" and frame:GetWidth() or W)-61)/6
  for i,k in ipairs(visible) do
    local b=professionButtons[k]
    local owned=self:OwnsProfession(k)
    b:ClearAllPoints()
    b:SetSize(profWidth,27)
    b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+((i-1)%6)*(profWidth+5),-111-math.floor((i-1)/6)*32)
    b:Show()
    b.selectionMarker:SetShown(k==key)
    b:SetText((owned and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t " or "")
      .."|T"..D.professionIcons[k]..":14|t "..D.professions[k].short)
  end
  for k,b in pairs(tabButtons) do
    local label
    for _,t in ipairs(tabs) do if t.key==k then label=t.label;break end end
    b.selectionMarker:SetShown(k==tab)
    b:SetText(label or k)
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
    rankText:SetText(prof.ranksUnverified and "Ausbildungsanforderungen bitte im Spiel prüfen"
      or record and "Höchster Ausbildungsrang erreicht"
      or "Berufsfenster oder Berufeübersicht öffnen, um Daten einzulesen")
  end
  priceText:SetText("Preis: "..(self.db.mode=="cash" and "Zukauf" or "Materialwert")
    .."  |  "..self:BankStatus()
    .."  |  AH: gespeichert  |  Rezeptkatalog: 1.60.1.704xx")

  local isTrainers=tab=="trainers"
  local gatheringOnly=prof.gathering and not prof.crafting
  local isRecipes=tab=="now" and not gatheringOnly
  local isMats=tab=="mats" and not gatheringOnly
  local isPlan=tab=="plan" and not gatheringOnly
  trainerAction1:SetShown(isTrainers)
  trainerAction2:SetShown(isTrainers)
  trainerInfo:SetShown(isTrainers)
  for _,mode in ipairs(sorts) do
    local b=sortButtons[mode.key]
    b:SetShown(isRecipes)
    b.selectionMarker:SetShown(self.db.ui.recipeSort==mode.key)
    b:SetText(mode.label)
  end
  bankButton:SetShown(isMats)
  bankDetails:SetShown(isMats)
  bankButton:SetText("Bankmaterialien: "..(self.db.includeBank and "AN" or "AUS"))
  bankDetails:SetText(self:BankStatus())
  for _,control in ipairs(planControls) do control:SetShown(isPlan) end
  if isPlan then
    planClear:SetText(self.pendingPlanClear==key and "Bestätigen?" or "Plan leeren")
    syncPlanFields(key)
    local choice=self:SelectedOption(key)
    planHint:SetText("Katalog "..self:CatalogCount(key).." Rezepte")
    autoRouteButton:SetEnabled(self:Catalog(key)~=nil)
    autoRouteButton:SetText(self.db.ui.knownRecipesOnly and "Auto: nur erlernt" or "Auto-Route")
  end
  contentPanel:ClearAllPoints()
  contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,
    settingsView and -250 or (isPlan and -423 or ((isTrainers or isRecipes or isMats) and -395 or -358)))
  contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,49)

  local lines={}
  if tab=="settings" or tab=="help" then
    section:SetText("Einstellungen · anklicken zum Ändern")
    setVisualCards(self:SettingsCards())
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
    section:SetText("Skill-Etappen · eine Karte anklicken, um diesen Bereich zu planen")
    local cards={}
    for _,segment in ipairs(D.stages[key] or {}) do
      local first,last,description=segment[1],segment[2],segment[3]
      local done=skill>=last
      local active=skill>=first and skill<last
      cards[#cards+1]={
        title=string.format("Skill %d–%d  ·  %s",first,last,
          done and "ERLEDIGT" or (active and "JETZT" or "SPÄTER")),
        detail=description,
        footer=prof.gathering and "Sammelbereich ohne garantierte Erntemenge"
          or ("Klicken -> Einkaufsplan für "..first.."–"..last),
        icon=prof.gathering and "Interface\\Icons\\INV_Misc_Herb_07"
          or "Interface\\Icons\\INV_Misc_EngGizmos_17",
        color=done and "green" or (active and "gold" or "blue"),
        action=not prof.gathering and function()
          if CP:SetPlanRange(key,first,last) then CP:OpenTab("plan") end
        end or nil
      }
    end
    if not D.stages[key] then
      cards[#cards+1]={title="Noch keine geprüfte Etappenübersicht",
        detail="Skill und erlernte Rezepte werden aus dem Spielclient eingelesen.",
        footer="Für diesen Beruf wird kein vollständiger Skillweg behauptet.",
        icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"}
    end
    cards[#cards+1]={
      title="Orientierung, kein garantierter Rezeptweg",
      detail="Lehrerrezepte, Skillfarben und Materialpreise ändern sich.",
      footer="Im Einkaufsplan werden nur explizit ausgewählte Rezepte berechnet.",
      icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"
    }
    setVisualCards(cards)
  elseif tab=="plan" then
    section:SetText("Einkaufsplan · frei wählbarer Bereich · bekannte Rezepte")
    if gatheringOnly then
      setVisualCards({{
        title="Sammelberuf · kein Rezept-Einkaufsplan",
        detail="Kräuter und Erze haben keine feste Anzahl für garantierte Skillpunkte.",
        footer="Nutze die Etappen und Lehrerübersicht für deinen Sammelweg.",
        icon="Interface\\Icons\\INV_Misc_Herb_07",color="gold"
      }})
    else
      local route=self:AutoRouteShopping(key)
      if route then
        local cards={}
        cards[#cards+1]={
          title=string.format("AUTO-ROUTE · %d -> %d · berechnet bis %d",
            route.first,route.target,route.reached),
          detail=#route.steps.." Fertigungsetappen · geschätzter Zukauf "..gold(route.price),
          footer=route.blocked and ("Bei "..route.blocked.." fehlt ein geeignetes Trainerrezept.")
            or "Vorschlag aus Client-Katalog; keine garantierte oder mathematisch globale Optimum-Route.",
          icon="Interface\\Icons\\INV_Misc_Note_01",
          color=route.blocked and "red" or "gold"
        }
        if route.unpriced>0 or route.stale>0 or route.unknownAge>0 then
          cards[#cards+1]={
            title="Preiswarnungen",
            detail=route.unpriced.." ohne Preis · "..route.stale.." veraltet · "
              ..route.unknownAge.." mit unbekanntem Scan-Alter",
            footer="Vor Einkäufen Auctionator erneut scannen; Preise variieren.",
            icon="Interface\\Icons\\INV_Misc_Coin_01",color="red"
          }
        end
        cards[#cards+1]={
          title=self.db.ui.showSourceDetails and ("Datengrundlage: "..self.catalogBuild) or "Planungsgrundlage · Details aufklappen",
          detail=route.assumptions.." Schritte verwenden Lehrer-/Startrezepte ohne aktuelle Spielbestätigung.",
          footer=self.db.ui.showSourceDetails and (self.catalogUpstream.." · Hotfixes und Angebote im Spiel prüfen.") or "Früherer Forever-Datenstand; Trainerangebote im Spiel prüfen.",
          action=function() CP:ToggleSetting("showSourceDetails") end,
          icon="Interface\\Icons\\INV_Misc_Book_09",color="gold"
        }
        for _,step in ipairs(route.steps) do
          local stamp=step.source=="known" and "im Spiel gelernt"
            or (step.source=="trainer" and "beim Lehrer prüfen" or "Startrezept")
          cards[#cards+1]={
            title=string.format("%d–%d · %dx %s",step.first,step.last,
              step.crafts,step.name),
            detail="Skillchance aus früherem Forever-Client · "..stamp,
            footer="Zeitpunkt und Anzahl sind geschätzt; Skillfarbe im Spiel prüfen.",
            icon=self:RecipeIcon(key,step.id),
            color=step.uncertain and "gold" or "green"
          }
        end
        if #route.intermediates>0 then
          cards[#cards+1]={
            title="Herstellungs- und Zwischenproduktkette",
            detail="Rohstoffe werden entweder gekauft oder über günstigere bekannte Rezepte verarbeitet.",
            footer="Die Preiswahl berücksichtigt vorhandene Materialien einmalig je Plan.",
            icon="Interface\\Icons\\INV_Misc_Bag_08",color="blue"
          }
          for _,node in ipairs(route.intermediates) do
            cards[#cards+1]={
              title=node.count.."x "..node.name,
              detail="Im Plan hergestellte Einheit(en) oder Zwischenprodukt.",
              footer="Nur soweit eigene Berufe und Rezeptquellen dies erlauben.",
              icon=self:RecipeIcon(key,node.id),color="blue"
            }
          end
        end
        if #route.materials==0 then
          cards[#cards+1]={title="Kein Zukauf erkannt",detail="Laut zuletzt erfassten Beständen und den geschätzten Schritten.",
            footer="Auf unbekannte Zutaten und veraltete Bankdaten achten.",color="green"}
        end
        for _,mat in ipairs(route.materials) do
          local age=self:PriceFreshness(mat.id)
          cards[#cards+1]={
            title=string.format("%dx %s",mat.missing,mat.name),
            detail=mat.cost and ("Zukauf "..gold(mat.cost).." · "..mat.source)
              or "Preis fehlt – Kosten nicht vollständig",
            footer=age,
            icon=itemIcon(mat.id),
            color=(mat.freshness=="stale" or mat.freshness=="aging" or not mat.price)
              and "red" or "green"
          }
        end
        setVisualCards(cards)
      else
      local plan=self:PlanShopping(key)
      local cards={}
      local range=plan.last-plan.first
      local summary=string.format("Skill %d -> %d   ·   %d Herstellungen eingeplant",
        plan.first,plan.last,plan.crafts)
      local expected=plan.expectedSkillUps>0
        and string.format("Momentane Skillchance: Ø etwa %.1f mögliche Punkte",plan.expectedSkillUps)
        or "Skillzuwachs unbekannt, keine garantierte Zielerreichung"
      cards[#cards+1]={
        title=summary,
        detail=expected,
        footer="Zielbereich "..range.." Skillpunkte. Keine Prognose für ungeöffnete/künftige Rezepte.",
        icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"
      }
      if #plan.steps==0 then
        cards[#cards+1]={
          title="Schritt 1: Rezept auswählen",
          detail="In Jetzt skillen ein gelerntes Rezept anklicken, hier Menge wählen.",
          footer="Rezept + fügt es dem Plan hinzu; Schnellschritt +10 erstellt nur den ersten Entwurf.",
          icon="Interface\\Icons\\INV_Misc_Bag_08",color="blue"
        }
      else
        for _,step in ipairs(plan.steps) do
          local id=step.id
          cards[#cards+1]={
            title=step.quantity.." x "..step.name,
            detail="Dieser Schritt wird in die gemeinsame Materialliste eingerechnet.",
            footer="Klicken zum Entfernen dieses Rezepts aus dem Plan",
            icon=self:RecipeIcon(key,id),
            color="green",
            action=function() CP:ClearPlanCraft(key,id);CP:Render() end
          }
        end
      end
      if #plan.materials>0 then
        cards[#cards+1]={
          title="Zusammengefasste Materialien",
          detail="Bekannte Zukaufpreise: "..gold(plan.purchaseCopper)
            ..(plan.noPrice>0 and ("  ·  "..plan.noPrice.." Preise fehlen") or ""),
          footer="Bruttomengen für deine gewählten Herstellungen. Keine Zwischenprodukt-Verrechnung.",
          icon="Interface\\Icons\\INV_Misc_Bag_08",color="gold"
        }
        for _,m in ipairs(plan.materials) do
          local color=m.missing>0 and "red" or "green"
          local status=m.bankLive and "LIVE" or (m.bankKnown and "letzter Stand" or "unbekannt")
          local cost=m.missing>0 and
            (m.cost and ("Zukauf ca. "..gold(m.cost)) or "Preis unbekannt")
            or "Bestand ausreichend"
          cards[#cards+1]={
            title=m.name.." · benötigt "..m.required.." · fehlt "..m.missing,
            detail="Tasche "..m.bag.." · Bank "..m.bank.." ("..status..")",
            footer=cost,icon=itemIcon(m.id),color=color
          }
        end
      end
      setVisualCards(cards)
      end
    end
  elseif gatheringOnly then
    section:SetText(prof.name..": aktueller Sammelabschnitt")
    local current=self:CurrentStage(key)
    setVisualCards({
      {
        title=GOLD.."AKTUELL"..RESET.."  ·  Skill "..skill,
        detail=current and current[3] or "Für diesen Beruf ist noch keine geprüfte Sammelroute hinterlegt.",
        footer="Im Tab Etappen siehst du die nächsten Sammelgebiete.",
        icon=key=="herbalism" and "Interface\\Icons\\INV_Misc_Herb_07"
          or "Interface\\Icons\\INV_Ore_Copper_01",color="gold"
      },{
        title="Sammelweg statt Rezeptmenge",
        detail="Sammeln ergibt keine feste Menge für garantierte Skillpunkte.",
        footer="Deshalb erstellt CraftPilot hier keine künstliche Zutaten-Einkaufsliste.",
        icon="Interface\\Icons\\INV_Misc_Map_01",color="blue"
      }
    })
  else
    local chosen,options=self:SelectedOption(key)
    local captured=self.db.lastCapture
    local current=captured and captured.key==key and captured.skill==skill
    if tab=="mats" then
      section:SetText("Materialien: aktuelles, ausgewähltes Rezept")
      if not chosen then
        setVisualCards({{
          title="Noch kein Rezept eingelesen",
          detail="Einen erlernten Herstellungsberuf wählen und das Berufsfenster öffnen.",
          footer="Nach dem Einlesen ein Rezept in Jetzt skillen auswählen.",
          icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"
        }})
      else
        materialCards(chosen.mats,"Rezept: "..chosen.name)
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
    if tab=="now" then
      if current and #options>0 then
        setRecipeRows(key,options,chosen)
      else
        setRows(lines)
      end
    end
  end
  footer:SetText("CraftPilot 0.10.2 Alpha  |  Früherer Forever-Datenstand · Preisalter prüfen")
end

function CP:ToggleWindow()
  if frame:IsShown() then frame:Hide();return end
  self:Refresh(true)
  frame:Show()
end
