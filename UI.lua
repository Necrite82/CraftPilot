local _, CP = ...
local L=CP.L
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
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  CP:StyleActionButton(b)
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
  L("WoW Forever  |  Zwölf Berufe  |  Skill 1–300  |  Ziehen zum Verschieben"))
local build = text(header, "GameFontDisableSmall", W-175, -40, 105, "v0.20.1-alpha")
local economyButton=button(header,112,23,W-270,-10,L("Clever skillen"),function() CP:OpenTab("economy") end)
local costingButton=button(header,150,23,W-440,-10,L("Kostenkalkulation"),function() CP:OpenCurrentCostCalculation() end)
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
local skinButton = button(frame,170,23, W-198,-78,L("Design: Automatisch"),function()
  if not CP.db then return end
  local current=CP.db.ui.skin
  CP.db.ui.skin=current=="auto" and "dark" or (current=="dark" and "classic" or "auto")
  CP:ApplyTheme()
  CP:Render()
end)

local professionButtons={}
local professionOrder={}
local allProfessionsButton=button(frame,185,23,280,-78,L("Alle Berufe anzeigen"),function()
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
  {key="now", label=L("Jetzt skillen")},
  {key="stages", label=L("Etappen 1–300")},
  {key="mats", label=L("Materialien")},
  {key="plan", label=L("Einkaufsplan")},
  {key="trainers", label=L("Lehrer")},
  {key="camping", label=L("Camping")},
  {key="settings", label=L("Einstellungen")}
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
local priceText=text(summary,"GameFontDisableSmall",14,-64,(W-70)/2,"")
local auctionText=text(summary,"GameFontDisableSmall",W/2,-64,(W-70)/2,"")
local section=text(frame,"GameFontNormal",19,-334,W-50,"")

local trainerAction1=button(frame,196,25,18,-358,L("Empfohlenen Lehrer markieren"),function()
  CP:TrainerWaypoint()
end)
local trainerAction2=button(frame,186,25,220,-358,L("Nächsten markieren"),function()
  CP:TrainerWaypoint("nearest")
end)
local trainerInfo=text(frame,"GameFontDisableSmall",425,-361,285,"")
local sortButtons={}
local sorts={
  {key="cost",label=L("Preis")},
  {key="chance",label=L("Skillchance")},
  {key="missing",label=L("Zukaufmenge")},
  {key="name",label="Name"},
}
for i,item in ipairs(sorts) do
  sortButtons[item.key]=button(frame,115,25,18+(i-1)*119,-358,item.label,function()
    CP.db.ui.recipeSort=item.key
    CP:Render()
  end)
  sortButtons[item.key]:Hide()
end
local recipeViews={}
for i,view in ipairs({{key="useful",label=L("Sinnvolle Rezepte")},{key="unlearned",label=L("Nicht gelernt")},{key="merchants",label=L("Händlerrezepte")},{key="all",label=L("Alle Rezepte")}}) do
  recipeViews[i]=button(frame,170,25,18+(i-1)*178,-358,view.label,function()
    CP.db.ui.vendorBrowser=view.key=="merchants";CP.db.ui.vendorOnly=view.key=="unlearned";CP.db.ui.allRecipes=view.key=="all";CP:Render()
  end);recipeViews[i]:Hide()
end
-- Keep related controls in one table: Lua 5.1 limits captured locals per function.
local merchantUI={}
merchantUI.searchLabel=text(frame,"GameFontDisableSmall",18,-393,62,L("Suche"))
merchantUI.search=CreateFrame("EditBox",nil,frame,"InputBoxTemplate");merchantUI.search:SetAutoFocus(false);merchantUI.search:SetSize(250,24)
merchantUI.search:SetScript("OnTextChanged",function(box) if not box.craftSync and CP.db then CP.db.ui.vendorQuery=box:GetText();CP:Render() end end)
merchantUI.search:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
merchantUI.search:SetScript("OnEnterPressed",function(box) box:ClearFocus() end)
merchantUI.clear=button(frame,76,25,352,-390,L("Leeren"),function() CP.db.ui.vendorQuery="";CP:Render() end)
merchantUI.bySkill=button(frame,122,25,445,-390,L("Nach Skill"),function() CP.db.ui.vendorSort="skill";CP:Render() end)
merchantUI.byName=button(frame,138,25,575,-390,L("Nach Name"),function() CP.db.ui.vendorSort="name";CP:Render() end)
merchantUI.controls={merchantUI.searchLabel,merchantUI.search,merchantUI.clear,merchantUI.bySkill,merchantUI.byName}
for _,c in ipairs(merchantUI.controls) do c:Hide() end
local bankButton=button(frame,250,25,18,-358,L("Bank: einschalten"),function()
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
local rangeLabel=text(frame,"GameFontHighlightSmall",18,-362,42,L("Von"))
local rangeStart=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
rangeStart:SetSize(54,24)
rangeStart:SetPoint("TOPLEFT",frame,"TOPLEFT",52,-352)
local targetLabel=text(frame,"GameFontHighlightSmall",116,-362,42,L("Bis"))
local rangeEnd=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
rangeEnd:SetSize(54,24)
rangeEnd:SetPoint("TOPLEFT",frame,"TOPLEFT",149,-352)
local quantityLabel=text(frame,"GameFontHighlightSmall",215,-362,52,L("Menge"))
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
local rangeApply=button(frame,93,25,332,-352,L("Bereich OK"),function()
  local p=CP:PlanFor(CP.db.view)
  if CP:SetPlanRange(CP.db.view,fieldNumber(rangeStart,p.start),
      fieldNumber(rangeEnd,p.target)) then CP:Render()
  else CP:Say(L("Bereich 1–300: Start muss kleiner als Ziel sein.")) end
end)
local planAdd=button(frame,142,25,431,-352,L("Rezept +"),function()
  local key=CP.db.view
  if CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe then CP:Say(L("Erst das Kaufrezept lernen und den Beruf neu einlesen."));return end
  local p=CP:PlanFor(key)
  local a,z=fieldNumber(rangeStart,p.start),fieldNumber(rangeEnd,p.target)
  if (a~=p.start or z~=p.target) and not CP:SetPlanRange(key,a,z) then CP:Say(L("Ungültiger Bereich."));return end
  local chosen=CP:SelectedOption(key)
  if not chosen then CP:Say(L("Bitte erst ein aktuelles Rezept wählen."));return end
  if CP:AddPlanCraft(key,chosen.id,fieldNumber(rangeQty,1)) then CP:Render()
  else CP:Say(L("Rezept oder Menge ungültig.")) end
end)
local planDraft=button(frame,152,25,18,-383,L("Schnellschritt +10"),function()
  if CP:DraftPlanStep(CP.db.view) then CP:Render() end
end)
local planPrint=button(frame,132,25,177,-383,L("Liste im Chat"),function()
  CP:PrintPlanShopping(CP.db.view)
end)
local planClear=button(frame,112,25,314,-383,L("Plan leeren"),function()
  if CP.pendingPlanClear~=CP.db.view then
    CP.pendingPlanClear=CP.db.view
  else
    CP:ClearPlanCraft(CP.db.view)
    CP.pendingPlanClear=nil
  end
  CP:Render()
end)
local autoRouteButton=button(frame,142,25,435,-383,L("Auto-Route"),function()
  local key=CP.db.view
  local p=CP:PlanFor(key)
  if not CP:SetPlanRange(key,fieldNumber(rangeStart,p.start),
      fieldNumber(rangeEnd,p.target)) then
    CP:Say(L("Ungültiger Bereich."))
    return
  end
  local ok,route=CP:RequestRouteBuild(key)
  if not ok then CP:Say(route or L("Keine Kandidaten.")) end
  CP:Render()
end)
local planHint=text(frame,"GameFontDisableSmall",588,-386,150,L("GPL-Katalog"))
local planControls={rangeLabel,rangeStart,targetLabel,rangeEnd,quantityLabel,
 rangeQty,rangeApply,planAdd,planDraft,planPrint,planClear,autoRouteButton,planHint}
local planExport=button(frame,180,26,390,-250,L("An Auctionator"),function()
  local p=CP:PlanFor(CP.db.view)
  if fieldNumber(rangeStart,p.start)~=p.start or fieldNumber(rangeEnd,p.target)~=p.target then CP:Say(L("Bereich geändert · zuerst Plan erstellen."));return end
  CP:ExportToAuctionator(CP.db.view);CP:Render()
end)
local planPages={}
for i,page in ipairs({{key="shopping",label=L("Einkaufsvorschlag")},{key="crafts",label=L("Herstellen")},{key="details",label=L("Details & Kosten")}}) do
  planPages[i]=button(frame,160,26,18+(i-1)*166,-286,page.label,function()
    CP.db.ui.planPage=page.key;CP:Render()
  end)
end
local manualShoppingAction=button(frame,205,26,18,-630,L("Manuelle Einkaufsliste"),function() CP:OpenPersonalShopping() end)
manualShoppingAction:ClearAllPoints();manualShoppingAction:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,14);manualShoppingAction:Hide()
local syncedPlan
local campControls={}
for i,page in ipairs({{key="fires",label=L("Campfires")},{key="buffs",label=L("Buffs")},{key="objects",label=L("Objekte & Ausbauten")},{key="shopping",label=L("Einkauf")}}) do
  campControls[i]=button(frame,170,25,18+(i-1)*176,-358,page.label,function()
    CP.db.ui.campingPage=page.key;CP:Render()
  end)
end
local campingFilter=button(frame,170,25,546,-358,L("Nur gewählter Beruf"),function()
  CP.db.ui.campingAll=CP.db.ui.campingAll==false
  CP:Render()
end)
campControls[5]=campingFilter
for _,control in ipairs(campControls) do control:Hide() end
local function syncPlanFields(key)
  local p=CP:PlanFor(key)
  local selected=CP:SelectedOption(key)
  local selectedID=selected and selected.id
  local marker=key..":"..p.start..":"..p.target..":"..tostring(selectedID)..":"..tostring(selectedID and CP:RecipeQuantityOverride(key,selectedID))
  if marker==syncedPlan then return end
  syncedPlan=marker
  rangeStart:SetText(tostring(p.start))
  rangeEnd:SetText(tostring(p.target))
  rangeQty:SetText(tostring(selectedID and CP:RequestedRecipeQuantity(key,selectedID) or 1))
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
local vendorButtons={}
local visualCards={}
local function gold(value)
  return CP:FormatMoney(value)
end

local function clearRows()
  for _,r in ipairs(rows) do r:Hide() end
  for _,b in ipairs(trainerButtons) do b:Hide() end
  for _,b in ipairs(recipeButtons) do b:Hide() end
  for _,b in ipairs(vendorButtons) do b:Hide() end
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
    if npc==recommended then flags=GREEN..L("[EMPFOHLEN] ")..RESET end
    if npc==nearest then flags=flags..GOLD..L("[NAH] ")..RESET end
    if selected==npc.name then flags=flags..L("[GEWÄHLT] ") end
    local cap=entry.canTeach and (L("bis ")..npc.cap)
      or (MUTED..L("nur bis ")..npc.cap..RESET)
    local metric=entry.distance and string.format(L(" | Kartenabstand %.1f"),entry.distance)
      or (entry.inZone and L(" | gleiche Zone") or L(" | andere Zone"))
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
  local offset,vendorIndex=0,0
  for i,entry in ipairs(options) do
    local b=recipeButtons[i]
    if not b then
      b=CP:CreateFlatAction(content,W-113,80,function()
        if b.craftRecipe and CP.db then
          CP:ActivateRecipeRow(CP.db.view,b.craftRecipe)
        end
      end)
      b.nameLabel=text(b,"GameFontHighlight",48,-7,W-180,"")
      b.infoLabel=text(b,"GameFontDisableSmall",48,-30,W-180,"")
      b.rangeLabel=text(b,"GameFontDisableSmall",48,-54,W-180,"")
      b.stockLabel=text(b,"GameFontHighlightSmall",48,-76,W-180,"")
      b.marketLabel=text(b,"GameFontHighlightSmall",48,-100,W-180,"")
      b:SetScript("OnEnter",function()
        if not GameTooltip or not b.craftRecipe then return end
        GameTooltip:SetOwner(b,"ANCHOR_RIGHT");GameTooltip:ClearLines();GameTooltip:AddLine(b.craftRecipe.name or "CraftPilot")
        for line in CP:RecipeStockText(CP.db.view,b.craftRecipe.id):gmatch("[^\n]+") do GameTooltip:AddLine(line,.85,.85,.85,true) end
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
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
          marker:SetSize(3,68)
          marker:SetPoint("LEFT",b,"LEFT",1,0)
          b.craftStripe=marker
        end
      end
      recipeButtons[i]=b
    end
    b.craftRecipe=entry
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-offset)
    b:SetSize((type(content.GetWidth)=="function" and content:GetWidth() or (W-95))-8,122)
    if b.craftIcon and type(b.craftIcon.SetTexture)=="function" then
      local texture=entry.icon
      if not texture and entry.outputItemID and C_Item and type(C_Item.GetItemIconByID)=="function" then
        local ok,value=pcall(C_Item.GetItemIconByID,entry.outputItemID)
        if ok then texture=value end
      end
      b.craftIcon:SetTexture(texture or "Interface\\Icons\\INV_Misc_Note_01")
    end
    local active=entry.vendorRecipe and CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe==entry.id
      or (not entry.vendorRecipe and chosen and entry.id==chosen.id and not (CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe))
    b:SetBackdropBorderColor(active and .85 or .18,active and .64 or .25,active and .3 or .32,1)
    if b.craftStripe then b.craftStripe:SetColorTexture(active and .91 or .37,active and .68 or .48,active and .31 or .67,.95) end
    b.nameLabel:SetText((active and GOLD..L("AUSGEWÄHLT  ")..RESET or "")
      ..entry.name)
    local rowHeight=122
    if not entry.merchantBrowse then
    b.rangeLabel:SetText(CP:RecipeRangeText(key,entry.id))
    b.marketLabel:SetWidth((type(b.GetWidth)=="function" and b:GetWidth() or W-110)-65)
    b.stockLabel:SetWidth((type(b.GetWidth)=="function" and b:GetWidth() or W-110)-65)
    b.stockLabel:SetText(CP:RecipeStockText(key,entry.id,true))
    local stockHeight=b.stockLabel:GetStringHeight()
    stockHeight=type(stockHeight)=="number" and stockHeight or 16
    b.marketLabel:ClearAllPoints();b.marketLabel:SetPoint("TOPLEFT",b,"TOPLEFT",48,-(82+stockHeight))
    b.marketLabel:SetText(CP:RecipeMarketText(key,entry.id))
    local marketHeight=b.marketLabel:GetStringHeight()
    rowHeight=math.max(146,94+stockHeight+(type(marketHeight)=="number" and marketHeight or 34))
    b:SetHeight(rowHeight)
    if b.craftStripe then b.craftStripe:SetHeight(rowHeight-12) end
    end
    b:SetAlpha(entry.dimmed and .5 or 1)
    if entry.referenceOnly then
      b.infoLabel:SetText(entry.referenceStatus)
    elseif entry.trainerRecipe then
      b.nameLabel:SetText(L("LEHRERREZEPT: ")..entry.name)
      local c=entry.comparison
      local benefit=c.cashSaving and c.cashSaving>0 and (L(" · Günstiger inkl. Lernen: ")..gold(c.cashSaving)..L(" / erwartetem Punkt")) or L(" · Lernkosten im Vergleich enthalten")
      b.infoLabel:SetText(L("Lernen einmalig: ")..(c.cost.feeUnknown and L("unbekannt") or gold(c.cost.fee))..benefit)
    elseif entry.vendorRecipe then
      b.nameLabel:SetText(L("KAUFREZEPT: ")..entry.name)
      b.infoLabel:SetText(L("Noch nicht erlernt · Rezeptpreis ab ")..(entry.recipeCost and gold(entry.recipeCost) or L("unbekannt"))..L(" · Angebot prüfen"))
    else
    local price=entry.unknown and L("Preis unvollständig") or gold(entry.cost)
    local ids={}
    for _,mat in ipairs(entry.mats) do ids[#ids+1]=mat[1] end
    local summary=CP.PriceSummary and CP:PriceSummary(ids)
    local ageInfo=summary and (summary.stale>0 and L(" · AH ALT")
      or (summary.unknown>0 and L(" · Scan ?") or "")) or ""
    b.infoLabel:SetText(CP:RecipeColorLabel(key,entry.id).." | "..string.format(L("Chance ca. %.0f%% | %s / Punkt | %d fehlen%s"),
      entry.chance*100,price,entry.missing,ageInfo))
    end
    entry.active=active
    rowHeight=entry.merchantBrowse and CP:LayoutVendorRecipeCard(b,key,entry,(b:GetWidth() or W-110)) or CP:LayoutRecipeCard(b,key,entry,(type(b.GetWidth)=="function" and b:GetWidth() or W-110))
    b:SetHeight(rowHeight);if b.craftStripe then b.craftStripe:SetHeight(rowHeight-12) end
    CP:RecipeShoppingButton(b,key,entry,active)
    b:Show()
    offset=offset+rowHeight+4
    if entry.vendorRecipe and (entry.merchantBrowse or not entry.referenceOnly) and (active or entry.trainerRecipe) then
      if active and not entry.merchantBrowse then
      local comparison=CP:VendorSkillComparison(key,entry)
      vendorIndex=vendorIndex+1
      local calc=vendorButtons[vendorIndex]
      if not calc then
        calc=CP:CreateFlatAction(content,W-113,78,function() end)
        calc.nameLabel=text(calc,"GameFontHighlight",14,-7,W-155,"")
        calc.infoLabel=text(calc,"GameFontDisableSmall",14,-32,W-155,"")
        vendorButtons[vendorIndex]=calc
      end
      calc.vendorTarget=nil
      calc:ClearAllPoints();calc:SetPoint("TOPLEFT",content,"TOPLEFT",5,-offset)
      calc:SetSize((type(content.GetWidth)=="function" and content:GetWidth() or W-95)-8,78);calc:SetEnabled(true)
      calc.nameLabel:SetText(comparison.crafts..L("x herstellen + Rezept: ")
        ..(comparison.cost.cashComplete and "" or L("Bekannter Teil: "))..CP:FormatCostMoney(comparison.cost.cash))
      local advantage=(entry.trainerRecipe and comparison.cashSaving or comparison.saving) and (entry.trainerRecipe and comparison.cashSaving or comparison.saving)>0
        and (L("Möglicher Vorteil je erwartetem Skillpunkt: ")..CP:FormatCostMoney(entry.trainerRecipe and comparison.cashSaving or comparison.saving))
        or L("Kein gesicherter Kostenvorteil gegenüber erlernten Rezepten.")
      calc.infoLabel:SetText(advantage..L(" · Heutige Skillfarbe; Reise nicht enthalten. Klick: Kalkulation"))
      local recipeID,crafts=entry.id,comparison.crafts
      calc:SetScript("OnClick",function() CP:OpenCostCalculation("recipe",key,recipeID,crafts) end)
      calc:Show();offset=offset+82
      end
      local targets=entry.vendors
      if entry.trainerRecipe and not active then targets=entry.vendors[1] and {entry.vendors[1]} or {} end
      for _,vendor in ipairs(targets) do
        vendorIndex=vendorIndex+1
        local row=vendorButtons[vendorIndex]
        if not row then
          row=CP:CreateFlatAction(content,W-113,57,function() end)
          row.nameLabel=text(row,"GameFontHighlight",14,-7,W-155,"")
          row.infoLabel=text(row,"GameFontDisableSmall",14,-31,W-155,"")
          row:SetScript("OnClick",function() if row.vendorTarget then CP:SetWaypoint(row.vendorTarget) end end)
          vendorButtons[vendorIndex]=row
        end
        row.vendorTarget=vendor.location
        row:SetScript("OnClick",function() if row.vendorTarget then CP:SetWaypoint(row.vendorTarget) end end)
        row:ClearAllPoints();row:SetPoint("TOPLEFT",content,"TOPLEFT",5,-offset)
        row:SetSize((type(content.GetWidth)=="function" and content:GetWidth() or W-95)-8,57)
        row:SetEnabled(vendor.location~=nil)
        local place=vendor.location and string.format("%s %.1f / %.1f",vendor.location.zone,vendor.location.x*100,vendor.location.y*100) or L("Standort unbekannt")
        row.nameLabel:SetText(vendor.name.." | "..place)
        row.infoLabel:SetText(CP:VendorOfferPrice(vendor).." | "..(entry.trainerRecipe and L("Lehrer · Angebot prüfen · Klick: Wegpunkt") or L("Angebot prüfen · Klick: TomTom/Kartenwegpunkt"))..(CP:VendorOfferNotes(vendor)~="" and ("\n"..CP:VendorOfferNotes(vendor)) or ""))
        local measured=row.infoLabel:GetStringHeight();local h=math.max(57,37+(type(measured)=="number" and measured or 16)+10);row:SetHeight(h)
        row:Show();offset=offset+h+4
      end
    end
  end
  content:SetHeight(math.max(270,offset+16))
  if resetContentScroll and type(scroll.SetVerticalScroll)=="function" then scroll:SetVerticalScroll(0) end
end

-- Shared visual cards for stages, materials and shopping plans.
-- Graphics are composed from native flat textures and client-provided item icons.
local function setVisualCards(entries)
  clearRows()
  local settingsView=CP.db and (CP.db.ui.tab=="settings" or CP.db.ui.tab=="help" or CP.db.ui.tab=="audit" or CP.db.ui.tab=="reservations")
  local baseHeight=settingsView and 92 or 73
  local offset=0
  for i,entry in ipairs(entries) do
    local market=entry.recipeID and CP:RecipeMarketText(entry.recipeKey or CP.db.view,entry.recipeID)
      or (entry.tooltipItem and CP:ItemMarketText(entry.tooltipItem))
    local cardHeight=market and 122 or baseHeight
    local b=visualCards[i]
    if not b then
      b=CreateFrame("Button",nil,content,"BackdropTemplate")
      b:SetSize(W-110,cardHeight-5)
      b:SetBackdrop(backdrop)
      b.titleLabel=text(b,"GameFontNormal",55,-7,W-170,"")
      b.detailLabel=text(b,"GameFontHighlightSmall",55,-30,W-170,"")
      b.footLabel=text(b,"GameFontDisableSmall",55,-51,W-170,"")
      b.marketLabel=text(b,"GameFontHighlightSmall",55,-52,W-170,"")
      if type(b.CreateTexture)=="function" then
        b.artFrame=CreateFrame("Frame",nil,b)
        b.artFrame:SetAllPoints(b)
        b.craftIcon=b.artFrame:CreateTexture(nil,"ARTWORK")
        if b.craftIcon then
          b.craftIcon:SetSize(32,32)
          b.craftIcon:SetPoint("LEFT",b,"LEFT",12,3)
        end
        b.craftStripe=b.artFrame:CreateTexture(nil,"OVERLAY")
        if b.craftStripe then
          b.craftStripe:SetSize(3,52)
          b.craftStripe:SetPoint("LEFT",b,"LEFT",2,0)
        end
        b.craftDot=b.artFrame:CreateTexture(nil,"OVERLAY")
        if b.craftDot then
          b.craftDot:SetSize(8,8)
          b.craftDot:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",22,8)
        end
      end
      b:SetScript("OnClick",function()
        if type(b.craftAction)=="function" then b.craftAction() end
      end)
      b:SetScript("OnEnter",function()
        if not GameTooltip or (not b.tooltipItem and not b.tooltipSpell) then return end
        GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
        if b.tooltipItem and type(GameTooltip.SetItemByID)=="function" then pcall(GameTooltip.SetItemByID,GameTooltip,b.tooltipItem)
        elseif b.tooltipSpell and type(GameTooltip.SetSpellByID)=="function" then pcall(GameTooltip.SetSpellByID,GameTooltip,b.tooltipSpell) end
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
      visualCards[i]=b
      if CP.ellesmereSkin and type(CP.ellesmereSkin.Panel)=="function" then
        pcall(CP.ellesmereSkin.Panel,b)
      end
    end
    if rawget(b,"settingCheck") then b.settingCheck:Hide() end
    b.craftAction=entry.action
    b.tooltipItem=entry.tooltipItem
    b.tooltipSpell=entry.tooltipSpell
    if entry.slider then
      if not b.settingSlider then
        local slider=CreateFrame("Slider","CraftPilotSettingsSlider"..i,b)
        b.settingSlider=slider
        slider:SetPoint("TOPLEFT",b,"TOPLEFT",60,-32)
        slider:SetHeight(18)
        slider:SetOrientation("HORIZONTAL")
        slider:EnableMouse(true)
        slider.track=slider:CreateTexture(nil,"BACKGROUND")
        slider.track:SetPoint("LEFT",slider,"LEFT",0,0)
        slider.track:SetPoint("RIGHT",slider,"RIGHT",0,0)
        slider.track:SetHeight(8)
        slider.track:SetColorTexture(.18,.23,.28,1)
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb=slider:GetThumbTexture()
        if thumb then thumb:SetSize(16,24);thumb:SetVertexColor(.91,.68,.31,1) end
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
          if spec.kind~="toggle" then b.titleLabel:SetText(spec.label..value..spec.unit) end
        end)
      end
      local slider=b.settingSlider
      local spec=entry.slider
      slider.craftSync=true
      slider.craftSpec=spec
      slider:SetWidth(spec.kind=="toggle" and 48 or math.max(180,(type(b.GetWidth)=="function" and b:GetWidth() or W-110)-90))
      if spec.kind=="toggle" then slider.track:SetColorTexture(spec.value==1 and .16 or .24,spec.value==1 and .65 or .26,.35,1)
      else slider.track:SetColorTexture(.18,.23,.28,1) end
      slider:SetMinMaxValues(spec.min,spec.max)
      slider:SetValueStep(spec.step)
      if type(slider.SetObeyStepOnDrag)=="function" then slider:SetObeyStepOnDrag(true) end
      slider:SetValue(spec.value)
      slider.craftSync=false
      slider:Show()
      b.detailLabel:ClearAllPoints()
      b.detailLabel:SetPoint("TOPLEFT",b,"TOPLEFT",spec.kind=="toggle" and 125 or 55,-30)
      b.detailLabel:SetWidth(math.max(180,(type(b.GetWidth)=="function" and b:GetWidth() or W-110)-(spec.kind=="toggle" and 145 or 70)))
      b.detailLabel:SetShown(spec.kind=="toggle")
    else
      if b.settingSlider then b.settingSlider:Hide() end
      b.detailLabel:ClearAllPoints()
      b.detailLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-30)
      b.detailLabel:Show()
    end
    b.footLabel:ClearAllPoints()
    b.footLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,market and -100 or (settingsView and -72 or -51))
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-offset)
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
    b.titleLabel:SetFontObject(entry.emphasis and "GameFontNormalLarge" or "GameFontNormal")
    b.footLabel:SetText(entry.footer or "")
    b.marketLabel:SetWidth((type(b.GetWidth)=="function" and b:GetWidth() or W-110)-70)
    b.marketLabel:SetText(market or "");b.marketLabel:SetShown(market~=nil)
    if market then
      local measured=b.marketLabel:GetStringHeight()
      measured=type(measured)=="number" and measured or 34
      local footHeight=b.footLabel:GetStringHeight()
      footHeight=type(footHeight)=="number" and footHeight or 14
      cardHeight=math.max(cardHeight,52+measured+footHeight+24)
      b.footLabel:ClearAllPoints();b.footLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-(52+measured+8))
      b:SetHeight(cardHeight-5)
    end
    if entry.checkbox then CP:RenderCheckbox(b,entry.checkbox,(b:GetWidth() or W-110)) end
    if not entry.slider then
      cardHeight=CP:LayoutVisualCard(b,entry,(type(b.GetWidth)=="function" and b:GetWidth() or W-110))+5
      b:SetHeight(cardHeight-5)
    else
      for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
      if rawget(b,"dataTable") then b.dataTable:Hide() end
      b.titleLabel:Show();b.footLabel:Show()
    end
    offset=offset+cardHeight
    b:Show()
  end
  content:SetHeight(math.max(280,offset+15))
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
    title=caption,detail=L("Taschen live · Bank letzter Stand · AH-Preise aus gespeichertem Scan"),
    footer=L("Nicht erfasste Bankmaterialien gelten nicht als bestätigt vorhanden."),color="gold",
    icon="Interface\\Icons\\INV_Misc_Bag_08"}
  end
  local rows={}
  for _,m in ipairs(materials) do
    local id=m.id or m[1];local qty=m.required or m[2] or 0
    local total,bag,bank,live,known,reserved=CP:AvailableForPlan(id,CP.db.view)
    local missing=math.max(0,qty-total);local price=CP:Price(id)
    rows[#rows+1]={id=id,quantity=qty,bag=bag,bank=bank,bankKnown=known,missing=missing,reserved=reserved,buy=price and missing*price}
  end
  if #rows>0 then entries[#entries+1]={materialTable=rows} end
  if #entries==0 then entries[1]={
    title=L("Keine Materialien"),detail=L("Rezept im Tab Jetzt skillen auswählen."),
    icon="Interface\\Icons\\INV_Misc_Note_01"} end
  setVisualCards(entries)
end

local footer=text(frame,"GameFontDisableSmall",19,-645,W-40,
  L("Alpha: Keine automatischen Käufe oder Herstellungsaktionen. Preise sind AH-Snapshots."))

local reportButton=button(frame,124,23,0,0,L("Fehler melden"),function() CP:OpenDiagnosticReport() end)
reportButton:ClearAllPoints();reportButton:SetPoint("LEFT",footer,"RIGHT",6,0)

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
  local name=pref=="classic" and L("Klassisch") or (pref=="dark" and L("Dunkel") or L("Automatisch"))
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
  skinButton:SetText(L("Design: ")..name)
  themeName:SetText(L("Oberfläche: ")..(hasEUI and "EllesmereUI"
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
  self:Say(L("Fensterposition zurückgesetzt."))
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
  costingButton:ClearAllPoints()
  costingButton:SetPoint("TOPRIGHT",header,"TOPRIGHT",-272,-10)
  economyButton:ClearAllPoints()
  economyButton:SetPoint("TOPRIGHT",header,"TOPRIGHT",-150,-10)
  subtitle:SetWidth(math.max(240,width-300))
  build:ClearAllPoints()
  build:SetPoint("TOPRIGHT",header,"TOPRIGHT",-42,-40)
  skinButton:ClearAllPoints()
  skinButton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-18,-78)
  status:SetWidth(inner-26)
  rankText:SetWidth(inner-26)
  priceText:SetWidth((inner-42)/2)
  auctionText:ClearAllPoints()
  auctionText:SetPoint("TOPLEFT",summary,"TOPLEFT",inner/2+7,-64)
  auctionText:SetWidth((inner-42)/2)
  section:SetWidth(inner)
  footer:ClearAllPoints()
  footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",19,22)
  footer:SetWidth(168)
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
  local tabWidth=(inner-4*(#tabs-1))/#tabs
  for i,control in ipairs(campControls) do
    control:ClearAllPoints()
    control:SetSize((inner-6*(#campControls-1))/#campControls,25)
    control:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(i-1)*((inner-6*(#campControls-1))/#campControls+6),-358)
  end
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
    if b.rangeLabel then b.rangeLabel:SetWidth(width-180) end
  end
  for _,b in ipairs(vendorButtons) do
    b:SetWidth(width-113);b.nameLabel:SetWidth(width-150);b.infoLabel:SetWidth(width-150)
  end
  for _,b in ipairs(visualCards) do
    b:SetWidth(width-113)
    if b.titleLabel then b.titleLabel:SetWidth(width-175) end
    if b.detailLabel then
      local toggle=b.settingSlider and b.settingSlider.craftSpec.kind=="toggle" and b.settingSlider:IsShown()
      b.detailLabel:SetWidth(width-(toggle and 258 or 175))
    end
    if b.footLabel then b.footLabel:SetWidth(width-175) end
    if b.settingSlider then b.settingSlider:SetWidth(b.settingSlider.craftSpec.kind=="toggle" and 48 or math.max(180,width-203)) end
  end
end
frame:SetScript("OnSizeChanged",function() layout() end)
layout()
registerEllesmereUI()

function CP:OpenTab(tab)
  if not self.db then return end
  local valid={now=true,stages=true,mats=true,plan=true,trainers=true,camping=true,economy=true,audit=true,reservations=true,settings=true,help=true}
  if tab=="help" then tab="settings" end
  if not valid[tab] then return end
  self.db.ui.tab=tab
  frame:Show()
  self:Render()
end



function CP:Render()
  self:InvalidateReservations();self.marketUseCache=nil;self.unlockCache=nil;self.routeAdvice=nil
  if not self.db then return end
  self:RestoreWindowPosition()
  self:ApplyTheme()
  local key=self.db.view
  local prof=D.professions[key]
  local record=self.db.professions[key]
  local skill=record and record.skill or 0
  local cap=record and record.cap or 0
  local tab=self.db.ui.tab or "now"
  economyButton.selectionMarker:SetShown(tab=="economy")
  local context=key..":"..tab..":"..tostring(self.db.ui.campingPage)..":"..tostring(self.db.ui.campingAll)..":"..tostring(self.db.ui.vendorOnly)..":"..tostring(self.db.ui.planPage)..":"..tostring(self.db.ui.vendorBrowser)..":"..tostring(self.db.ui.vendorQuery)..":"..tostring(self.db.ui.vendorSort)
  resetContentScroll=context~=lastContentContext
  lastContentContext=context
  if tab~="plan" then self.pendingPlanClear=nil end
  if tab~="settings" and tab~="help" then self.pendingSettingsReset=nil end
  local settingsView=tab=="settings" or tab=="help" or tab=="audit" or tab=="reservations"
  local merchantView=tab=="now" and not (prof.gathering and not prof.crafting) and self.db.ui.vendorBrowser==true
  summary:SetShown(not settingsView and tab~="plan" and not merchantView)
  stageProgress:SetShown(not settingsView and tab~="plan" and not merchantView)
  section:ClearAllPoints()
  section:SetPoint("TOPLEFT",frame,"TOPLEFT",19,(settingsView or tab=="plan" or merchantView) and -226 or -334)
  if type(stageProgress.SetValue)=="function" then
    stageProgress:SetValue(math.max(0,math.min(300,skill)))
  end

  allProfessionsButton:SetText(self.db.ui.showAllProfessions and L("Nur eigene Berufe") or L("Alle Berufe anzeigen"))
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

  status:SetText(GOLD..prof.name..RESET.."  |  "..(record and (skill.." / "..cap) or L("Skill noch nicht eingelesen"))
    ..L("  |  Zielskill 300"))
  local nextRank=self:NextRank(key)
  if nextRank then
    local playerLevel=type(UnitLevel)=="function" and UnitLevel("player") or 0
    local needLevel=self:RankCharacterLevel(key,nextRank)
    local notices={}
    if skill<nextRank.min then notices[#notices+1]=L("ab Berufsskill ")..nextRank.min end
    if playerLevel<needLevel then notices[#notices+1]=L("Charakterstufe ")..needLevel..L(" erforderlich") end
    local qualification=#notices>0 and (" ("..table.concat(notices,", ")..")") or ""
    rankText:SetText(L("Nächster Ausbildungsrang: ")..nextRank.name..L(" bis ")..nextRank.cap..qualification)
  else
    rankText:SetText(prof.ranksUnverified and L("Ausbildungsanforderungen bitte im Spiel prüfen")
      or record and L("Höchster Ausbildungsrang erreicht")
      or L("Berufsfenster oder Berufeübersicht öffnen, um Daten einzulesen"))
  end
  priceText:SetText(self:BankStatus())
  local priceStatus,priceState=self:ProfessionPriceStatus(key)
  auctionText:SetText(priceStatus)
  auctionText:SetTextColor(priceState=="fresh" and .45 or .95,priceState=="fresh" and .85 or .72,.55)

  local isTrainers=tab=="trainers"
  local gatheringOnly=prof.gathering and not prof.crafting
  local isRecipes=tab=="now" and not gatheringOnly
  local vendorOffers=isRecipes and not merchantView and self:VendorRecipeOptions(key) or {}
  if isRecipes and not merchantView then for _,entry in ipairs(self:TrainerRecipeOptions(key)) do vendorOffers[#vendorOffers+1]=entry end end
  local viewKey=merchantView and "merchants" or (self.db.ui.allRecipes and "all" or (self.db.ui.vendorOnly and "unlearned" or "useful"))
  local toolbarY=merchantView and 250 or 358
  local inner=(frame:GetWidth() or W)-36
  for i,b in ipairs(recipeViews) do b:SetShown(isRecipes);b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(i-1)*(inner+6)/4,-toolbarY);b:SetWidth((inner-18)/4);b.selectionMarker:SetShown(({"useful","unlearned","merchants","all"})[i]==viewKey) end
  for _,c in ipairs(merchantUI.controls) do c:SetShown(isRecipes and merchantView) end
  merchantUI.searchLabel:ClearAllPoints();merchantUI.searchLabel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-(toolbarY+39))
  merchantUI.search:ClearAllPoints();merchantUI.search:SetPoint("TOPLEFT",frame,"TOPLEFT",86,-(toolbarY+32))
  for _,v in ipairs({{merchantUI.clear,352},{merchantUI.bySkill,445},{merchantUI.byName,575}}) do v[1]:ClearAllPoints();v[1]:SetPoint("TOPLEFT",frame,"TOPLEFT",v[2],-(toolbarY+32)) end
  if not merchantUI.search:HasFocus() then merchantUI.search.craftSync=true;merchantUI.search:SetText(self.db.ui.vendorQuery or "");merchantUI.search.craftSync=nil end
  merchantUI.bySkill.selectionMarker:SetShown(self.db.ui.vendorSort~="name");merchantUI.byName.selectionMarker:SetShown(self.db.ui.vendorSort=="name")
  local isMats=tab=="mats" and not gatheringOnly
  local isPlan=tab=="plan" and not gatheringOnly
  trainerAction1:SetShown(isTrainers)
  trainerAction2:SetShown(isTrainers)
  trainerInfo:SetShown(isTrainers)
  for sortIndex,mode in ipairs(sorts) do
    local b=sortButtons[mode.key]
    b:SetShown(isRecipes and not merchantView)
    b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(sortIndex-1)*119,-390)
    b.selectionMarker:SetShown(self.db.ui.recipeSort==mode.key)
    b:SetText(mode.label)
  end
  bankButton:SetShown(isMats)
  bankDetails:SetShown(isMats)
  bankButton:SetText(L("Bankmaterialien: ")..(self.db.includeBank and L("AN") or L("AUS")))
  bankDetails:SetText(self:BankStatus())
  for _,control in ipairs(planControls) do control:SetShown(isPlan) end
  planExport:SetShown(isPlan);manualShoppingAction:SetShown(isPlan)
  for _,b in ipairs(planPages) do b:SetShown(isPlan) end
  for _,control in ipairs(campControls) do control:SetShown(tab=="camping") end
  campingFilter:SetText(self.db.ui.campingAll==false and L("Alle Camping-Berufe") or L("Nur gewählter Beruf"))
  if isPlan then
    if not ({shopping=true,crafts=true,details=true})[self.db.ui.planPage] then self.db.ui.planPage="shopping" end
    local page=self.db.ui.planPage
    syncPlanFields(key)
    local inner=(frame:GetWidth() or W)-36
    local function place(c,x,y,w) c:ClearAllPoints();c:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-y);if w then c:SetWidth(w) end end
    place(rangeLabel,18,256);place(rangeStart,54,250);place(targetLabel,120,256);place(rangeEnd,150,250)
    place(autoRouteButton,220,250,156);autoRouteButton:SetText(self:RouteBuildPending(key) and L("Berechne…") or L("Plan erstellen"));autoRouteButton:SetEnabled(self:Catalog(key)~=nil and not self:RouteBuildPending(key))
    place(planExport,388,250,180);planExport:SetEnabled(not self:RouteBuildPending(key))
    rangeApply:Hide();planDraft:Hide();planPrint:Hide();planClear:Hide();planAdd:Hide();rangeQty:Hide();quantityLabel:Hide()
    if page=="crafts" then
      place(quantityLabel,18,326);place(rangeQty,83,320,55);place(planAdd,150,320,200);place(planClear,362,320,135);place(planDraft,509,320,inner-491)
      quantityLabel:Show();rangeQty:Show();planAdd:Show();planClear:Show();planDraft:Show()
      local p=self:PlanFor(key);local choice=self:SelectedOption(key)
      planAdd:SetText(L("Gewähltes Rezept hinzufügen"));planAdd:SetEnabled(choice~=nil and not p.autoMode and not (self.db.ui.selectedVendorKey==key and self.db.ui.selectedVendorRecipe))
    elseif page=="details" then
      place(planPrint,18,320,150);place(planClear,180,320,150);planPrint:Show();planClear:Show()
    end
    planClear:SetText(self.pendingPlanClear==key and L("Bestätigen?") or L("Plan leeren"))
    local c=self:CostCalculation("plan",key)
    place(planHint,580,257,math.max(120,inner-562));planHint:SetText(self:RouteBuildPending(key) and L("Berechne…") or ((c.cashComplete and L("Kosten: ") or L("Ab: "))..self:FormatCostMoney(c.cash)))
    local tabWidth=(inner-12)/3
    for i,b in ipairs(planPages) do place(b,18+(i-1)*(tabWidth+6),286,tabWidth);b.selectionMarker:SetShown(({"shopping","crafts","details"})[i]==page) end
  end

  contentPanel:ClearAllPoints()
  contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,
    merchantView and -318 or (isRecipes and -427 or (settingsView and -250 or (isPlan and ((self.db.ui.planPage=="crafts" or self.db.ui.planPage=="details") and -360 or -326) or ((isTrainers or isRecipes or isMats or tab=="camping") and -395 or -358)))))
  contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,49)

  local lines={}
  if tab=="settings" or tab=="help" then
    section:SetText(L("Einstellungen · anklicken zum Ändern"))
    setVisualCards(self:SettingsCards())
  elseif tab=="reservations" then
    section:SetText(L("Gemeinsame Vorratsreservierung"))
    setVisualCards(self:ReservationCards())
  elseif tab=="audit" then
    section:SetText(L("Berufsdaten · Farbgrenzen und Clientabgleich"))
    setVisualCards(self:ProfessionAuditCards())
  elseif tab=="economy" then
    section:SetText(L("Clever skillen · verkaufen, behalten oder anders skillen"))
    setVisualCards(self:EconomyCards(key))
  elseif tab=="camping" then
    section:SetText(L("Camping · Objekte, Ausbauten und Materialien"))
    setVisualCards(self:CampingCards(key))
  elseif tab=="trainers" then
    local choices,rank,recommended,nearest=self:TrainerChoices(key)
    section:SetText(L("Lehrer für ")..prof.name..L("  |  Eintrag anklicken = Wegpunkt"))
    trainerAction1:SetEnabled(recommended~=nil)
    trainerAction2:SetEnabled(nearest~=nil)
    trainerInfo:SetText(nearest and L("NAH: gleicher Kartenabschnitt")
      or L("Andere Zonen: Entfernung unbekannt"))
    if #choices==0 then
      setRows({L("Für deine Fraktion ist noch kein Lehrer hinterlegt."),
        L("Bitte einen fehlenden Lehrerstandort als GitHub-Issue melden.")})
    else
      setTrainerRows(choices,recommended,nearest,self.db.ui.selectedTrainers[key])
      if self.db.ui.skin=="auto" then self:ApplyTheme() end
    end
  elseif tab=="stages" then
    section:SetText(L("Skill-Etappen · eine Karte anklicken, um diesen Bereich zu planen"))
    local cards={}
    for _,segment in ipairs(D.stages[key] or {}) do
      local first,last,description=segment[1],segment[2],segment[3]
      local done=skill>=last
      local active=skill>=first and skill<last
      cards[#cards+1]={
        title=string.format(L("Skill %d–%d  ·  %s"),first,last,
          done and L("ERLEDIGT") or (active and L("JETZT") or L("SPÄTER"))),
        detail=description,
        footer=prof.gathering and L("Sammelbereich ohne garantierte Erntemenge")
          or (L("Klicken -> Einkaufsplan für ")..first.."–"..last),
        icon=prof.gathering and "Interface\\Icons\\INV_Misc_Herb_07"
          or "Interface\\Icons\\INV_Misc_EngGizmos_17",
        color=done and "green" or (active and "gold" or "blue"),
        action=not prof.gathering and function()
          if CP:SetPlanRange(key,first,last) then CP:OpenTab("plan") end
        end or nil
      }
    end
    if not D.stages[key] then
      for _,option in ipairs(self:Options(key)) do
        local recipeID=option.id
        cards[#cards+1]={title=self:RecipeName(key,recipeID,option.name),
          detail=L("Aktuell erlernt · Skillchance ")..math.floor(option.chance*100).."%",
          footer=L("Aktueller Schritt aus dem Client; kein vorausberechneter Skillweg."),
          recipeKey=key,recipeID=recipeID,icon=self:RecipeIcon(key,recipeID),color="blue",
          action=function() CP.db.ui.selectedRecipes[key]=recipeID;CP:OpenTab("plan") end}
      end
      cards[#cards+1]={title=L("Noch keine geprüfte Etappenübersicht"),
        detail=L("Skill und erlernte Rezepte werden aus dem Spielclient eingelesen."),
        footer=L("Für diesen Beruf wird kein vollständiger Skillweg behauptet."),
        icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"}
    end
    cards[#cards+1]={
      title=L("Orientierung, kein garantierter Rezeptweg"),
      detail=L("Lehrerrezepte, Skillfarben und Materialpreise ändern sich."),
      footer=L("Im Einkaufsplan werden nur explizit ausgewählte Rezepte berechnet."),
      icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"
    }
    setVisualCards(cards)
  elseif tab=="plan" then
    section:SetText(prof.name..L(" · Einkaufsplan · Skill ")..skill)
    if gatheringOnly then setVisualCards({{title=L("Sammelberuf · kein Rezept-Einkaufsplan"),detail=L("Nutze die Etappen und Lehrerübersicht für deinen Sammelweg."),color="blue"}})
    else setVisualCards(self:PlanPageCards(key,self.db.ui.planPage or "shopping")) end
  elseif gatheringOnly then
    section:SetText(prof.name..L(": aktueller Sammelabschnitt"))
    local current=self:CurrentStage(key)
    setVisualCards({
      {
        title=GOLD..L("AKTUELL")..RESET.."  ·  Skill "..skill,
        detail=current and current[3] or L("Für diesen Beruf ist noch keine geprüfte Sammelroute hinterlegt."),
        footer=L("Im Tab Etappen siehst du die nächsten Sammelgebiete."),
        icon=key=="herbalism" and "Interface\\Icons\\INV_Misc_Herb_07"
          or "Interface\\Icons\\INV_Ore_Copper_01",color="gold"
      },{
        title=L("Sammelweg statt Rezeptmenge"),
        detail=L("Sammeln ergibt keine feste Menge für garantierte Skillpunkte."),
        footer=L("Deshalb erstellt CraftPilot hier keine künstliche Zutaten-Einkaufsliste."),
        icon="Interface\\Icons\\INV_Misc_Map_01",color="blue"
      }
    })
  else
    local chosen,options
    if merchantView then options={} else chosen,options=self:SelectedOption(key) end
    local captured=self.db.lastCapture
    local current=captured and captured.key==key and captured.skill==skill
    if tab=="mats" then
      section:SetText(L("Materialien: aktuelles, ausgewähltes Rezept"))
      if not chosen then
        setVisualCards({{
          title=L("Noch kein Rezept eingelesen"),
          detail=L("Einen erlernten Herstellungsberuf wählen und das Berufsfenster öffnen."),
          footer=L("Nach dem Einlesen ein Rezept in Jetzt skillen auswählen."),
          icon="Interface\\Icons\\INV_Misc_Note_01",color="gold"
        }})
      else
        materialCards(chosen.mats,L("Rezept: ")..chosen.name)
      end
    else
      section:SetText(L("Erlernte Rezepte – geschätzte Kosten je Skillpunkt"))
      if not current then
        lines[#lines+1]=L("Berufsfenster öffnen und Aktualisieren drücken.")
        lines[#lines+1]=L("Nur aktuelle Skillfarben lassen sich sinnvoll vergleichen.")
      elseif #options==0 then
        lines[#lines+1]=L("Keine aktuell auswertbaren Rezepte mit eindeutigen Materialien.")
      else
        section:SetText(L("Rezept anklicken = auswählen  |  Sortierung oben ändern"))
      end
    end
    if not record then
      lines[#lines+1]=L("Beruf noch nicht auf diesem Charakter erfasst.")
    end
    if tab=="now" then
      local offers=vendorOffers
      if self.db.ui.vendorBrowser then
        local rows=self:VendorRecipeBrowseOptions(key,self.db.ui.vendorQuery,self.db.ui.vendorSort)
        section:SetText(string.format(L("Händlerrezepte · %d Treffer · alle Skillstufen"),#rows))
        if #rows>0 then setRecipeRows(key,rows,nil) else setRows({L("Keine hinterlegten Händlerrezepte für diese Suche."),L("Suche leeren oder einen anderen Beruf wählen. Der Datenbestand ist nicht vollständig live bestätigt.")}) end
      elseif self.db.ui.allRecipes then
        setRecipeRows(key,self:AllRecipeOptions(key,options,offers),chosen)
      elseif self.db.ui.vendorOnly then
        if #offers>0 then setRecipeRows(key,offers,nil)
        else setRows({L("Keine passenden Kaufrezepte für diesen Skill hinterlegt.")}) end
      elseif (current and #options>0) or #offers>0 then
        local overview={}
        for _,entry in ipairs(offers) do if entry.trainerRecipe and entry.comparison.cashSaving and entry.comparison.cashSaving>0 then overview[#overview+1]=entry end end
        if current then for _,entry in ipairs(options) do overview[#overview+1]=entry end end
        for _,entry in ipairs(offers) do if not (entry.trainerRecipe and entry.comparison.cashSaving and entry.comparison.cashSaving>0) then overview[#overview+1]=entry end end
        section:SetText(L("Rezeptklick: Beruf öffnen · Kaufrezeptklick: Händler zeigen"))
        setRecipeRows(key,overview,chosen)
      else
        setRows(lines)
      end
    end
  end
  footer:SetText("CraftPilot 0.20.1 Alpha")
  local footerWidth=footer:GetStringWidth();if type(footerWidth)=="number" and footerWidth>0 then footer:SetWidth(footerWidth) end
end

function CP:ToggleWindow()
  if frame:IsShown() then frame:Hide();return end
  self:Refresh(true)
  frame:Show()
end
