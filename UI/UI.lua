-- CraftPilot main window (0.21 layout): one header row, four tabs, list + detail for recipes.
-- All widgets live in the table U so render functions stay within Lua 5.1's upvalue limit.
local _, CP = ...
local L=CP.L
local D = CP.Data

local W, H = 750, 676
local GOLD = "|cffffd878"
local MUTED = "|cff9dabb8"
local RESET = "|r"
local SKILL_COLORS = {orange={1,.5,.25},yellow={1,.82,0},green={.25,.75,.25},grey={.62,.62,.62}}
-- The game font has no arrow glyphs; use client textures instead.
local ARROW_DOWN = "|TInterface\\Buttons\\Arrow-Down-Up:12:12:0:-3|t"
local ARROW_UP = "|TInterface\\Buttons\\Arrow-Up-Up:12:12:0:3|t"
local EXPAND = "|TInterface\\Buttons\\UI-PlusButton-Up:12:12:0:0|t "
local COLLAPSE = "|TInterface\\Buttons\\UI-MinusButton-Up:12:12:0:0|t "
local DOT = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local U = {buttons={}, rows={}, trainerRows={}, recipeRows={}, vendorRows={}, cards={}, listRows={},
  learnRows={}, stageButtons={}, profItems={}, filterItems={}, detail={}}

local flat = {bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1}
local PALETTE = {
  window={.078,.090,.110}, panel={.098,.114,.137}, raised={.122,.141,.172},
  border={.17,.196,.227}, gold={.88,.69,.31}, text={.91,.90,.87}, muted={.60,.64,.68},
}

local function text(parent, font, x, y, width, value)
  local node = parent:CreateFontString(nil, "OVERLAY", font)
  node:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  node:SetWidth(width)
  node:SetJustifyH("LEFT")
  node:SetText(value or "")
  return node
end

local function panel(parent, shade)
  local p = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  CP:Round(p)
  local c = PALETTE[shade or "panel"]
  p:SetBackdropColor(c[1], c[2], c[3], 1)
  p:SetBackdropBorderColor(PALETTE.border[1], PALETTE.border[2], PALETTE.border[3], 1)
  return p
end

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
  U.buttons[#U.buttons+1] = b
  if CP.ellesmereSkin and type(CP.ellesmereSkin.Button)=="function" then
    pcall(CP.ellesmereSkin.Button,b)
  end
  return b
end

-- Own-styled controls: never handed to EllesmereUI, so tabs, segments and primary actions keep the
-- CraftPilot look under every skin.
local function plain(parent,width,height,caption,callback)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  CP:StyleActionButton(b)
  b:SetSize(width,height)
  b:SetText(caption)
  b:SetScript("OnClick",callback)
  return b
end
local function segmentMarker(b)
  local m={on=false}
  function m:SetShown(v) self.on=v and true or false;CP:StyleSegment(b,self.on) end
  function m:Show() self:SetShown(true) end
  function m:Hide() self:SetShown(false) end
  function m:IsShown() return self.on end
  return m
end
local function segment(parent,width,height,caption,callback)
  local b=plain(parent,width,height,caption,callback)
  b.selectionMarker=segmentMarker(b)
  CP:StyleSegment(b,false)
  return b
end
local function primary(b)
  if CP.StylePrimaryButton then CP:StylePrimaryButton(b) end
  return b
end
local function primaryButton(parent,width,height,caption,callback)
  local b=plain(parent,width,height,caption,callback)
  b.selectionMarker={SetShown=function() end,Show=function() end,Hide=function() end,IsShown=function() return false end}
  return primary(b)
end
local function setPrimaryEnabled(b,on)
  b:SetEnabled(on)
  primary(b)
end
local function dot(texture,color)
  if type(texture.SetTexture)=="function" then texture:SetTexture(DOT) end
  if type(texture.SetVertexColor)=="function" then texture:SetVertexColor(color[1],color[2],color[3],1) end
end

local function place(c,x,y,w,h)
  c:ClearAllPoints();c:SetPoint("TOPLEFT",U.frame,"TOPLEFT",x,-y)
  if w then c:SetWidth(w) end
  if h then c:SetHeight(h) end
end

local function tooltip(owner,title,lines)
  owner:SetScript("OnEnter",function()
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_BOTTOM")
    GameTooltip:SetText(type(title)=="function" and title() or title)
    for _,line in ipairs(type(lines)=="function" and lines() or lines or {}) do
      if type(line)=="table" then
        local c=line.color or {1,1,1}
        if line.right then GameTooltip:AddDoubleLine(line.left,line.right,c[1],c[2],c[3],1,1,1)
        else GameTooltip:AddLine(line.left,c[1],c[2],c[3],line.wrap==true) end
      else GameTooltip:AddLine(line,1,1,1,true) end
    end
    GameTooltip:Show()
  end)
  owner:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

local function colorOf(entry)
  local chance=type(entry.chance)=="number" and entry.chance or 0
  if entry.referenceOnly then return "grey" end
  if chance>=.99 then return "orange" elseif chance>=.6 then return "yellow" elseif chance>0 then return "green" end
  return "grey"
end

function CP:CompactMoney(value)
  if type(value)~="number" then return "?" end
  local amount=math.max(0,math.floor(value+.5))
  local g,s,c=math.floor(amount/10000),math.floor(amount%10000/100),amount%100
  local icon=function(n,kind) return n.."|TInterface\\MoneyFrame\\UI-"..kind.."Icon:11:11:0:0|t" end
  if g>0 then return icon(g,"Gold")..(s>0 and (" "..icon(s,"Silver")) or "") end
  if s>0 then return icon(s,"Silver")..(c>0 and (" "..icon(c,"Copper")) or "") end
  return icon(c,"Copper")
end

-- Window ----------------------------------------------------------------------------------------------------
local frame = CreateFrame("Frame", "CraftPilotProMainFrame", UIParent, "BackdropTemplate")
U.frame=frame
frame:SetSize(W, H)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CP:Round(frame)
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
-- Above unit frames and action bars (MEDIUM/LOW), below dialogs and popups (DIALOG).
if type(frame.SetFrameStrata)=="function" then frame:SetFrameStrata("HIGH") end
if type(frame.SetToplevel)=="function" then frame:SetToplevel(true) end
frame:Hide()
CP.frame = frame
if type(UISpecialFrames)=="table" then
  table.insert(UISpecialFrames, "CraftPilotProMainFrame")
end

-- Header: logo, name, profession menu, skill bar, price status, settings, close ---------------------------------
local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
U.header=header
header:SetHeight(54)
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
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
local brandFrame=CreateFrame("Frame","CraftPilotProBrandFrame",header)
brandFrame:SetSize(30,30)
brandFrame:SetPoint("LEFT",header,"LEFT",12,0)
local brand=brandFrame:CreateTexture(nil,"ARTWORK")
brand:SetAllPoints(brandFrame)
brand:SetTexture("Interface\\AddOns\\CraftPilotPro\\Media\\CraftPilot")
U.title = text(header, "GameFontNormalLarge", 50, -17, 110, "CraftPilot")

U.profButton=button(header,180,30,160,-12,"",function()
  U.profMenu:SetShown(not U.profMenu:IsShown());U.filterMenu:Hide()
  if U.profMenu:IsShown() then CP:RenderProfessionMenu() end
end)
U.profMenu=panel(frame,"raised")
U.profMenu:SetFrameStrata("DIALOG")
U.profMenu:SetSize(230,40)
U.profMenu:Hide()
U.profMenu.ownLabel=text(U.profMenu,"GameFontDisableSmall",10,-8,200,L("Deine Berufe"))
U.profMenu.otherLabel=text(U.profMenu,"GameFontDisableSmall",10,-8,200,L("Weitere Berufe"))
for i,key in ipairs(D.order) do
  local item=button(U.profMenu,214,26,8,-8,"",function()
    U.profMenu:Hide()
    CP:ChangeView(key,false)
  end)
  item.professionKey=key
  U.profItems[i]=item
end

-- Opening the game's profession window is protected for addons. A secure spell button casts the
-- profession spell like a click in the spellbook would. These buttons hang on UIParent (never on
-- the CraftPilot window, which must stay closable in combat) and are hidden whenever combat starts.
local PROFESSION_SPELLS={alchemy=2259,blacksmithing=2018,enchanting=7411,engineering=4036,leatherworking=2108,
  tailoring=3908,cooking=2550,firstaid=3273,mining=2656}
function CP:ProfessionSpellName(key)
  local id=PROFESSION_SPELLS[key];if not id then return nil end
  local name
  if C_Spell and type(C_Spell.GetSpellName)=="function" then local ok,v=pcall(C_Spell.GetSpellName,id);if ok then name=v end end
  if not name and type(GetSpellInfo)=="function" then local ok,v=pcall(GetSpellInfo,id);if ok then name=v end end
  return type(name)=="string" and name~="" and name or nil
end
local function inCombat() return type(InCombatLockdown)=="function" and InCombatLockdown() end
U.secure={}
local function hideSecure()
  if inCombat() then return end
  -- Hide and unanchor: a secure button still anchored to the window makes the window itself protected in combat.
  for _,s in ipairs(U.secure) do s:Hide();if type(s.ClearAllPoints)=="function" then s:ClearAllPoints() end end
end
U.hideSecure=hideSecure
local function secureButton(i)
  local s=U.secure[i]
  if s then return s end
  s=CreateFrame("Button","CraftPilotProProfessionCast"..i,UIParent,"SecureActionButtonTemplate")
  if type(s.SetFrameStrata)=="function" then s:SetFrameStrata("DIALOG") end
  if type(s.SetFrameLevel)=="function" then s:SetFrameLevel(60) end
  if type(s.RegisterForClicks)=="function" then s:RegisterForClicks("AnyUp","AnyDown") end
  s:SetAttribute("type","spell")
  s:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local h=s:GetHighlightTexture();if h then h:SetVertexColor(.35,.55,.75,.16) end
  s:SetScript("PostClick",function(self,_,down)
    if down then return end
    U.profMenu:Hide()
    if self.professionKey then CP:ChangeView(self.professionKey,false) end
  end)
  s:Hide()
  U.secure[i]=s
  return s
end
U.profMenu:SetScript("OnHide",hideSecure)
local combatWatcher=CreateFrame("Frame")
pcall(combatWatcher.RegisterEvent,combatWatcher,"PLAYER_REGEN_DISABLED")
combatWatcher:SetScript("OnEvent",function()
  -- Still allowed while this event runs; afterwards secure frames are locked.
  for _,s in ipairs(U.secure) do s:Hide();if type(s.ClearAllPoints)=="function" then s:ClearAllPoints() end end
  if U.profMenu then U.profMenu:Hide() end
end)

U.skillBar=CreateFrame("StatusBar",nil,header)
U.skillBar:SetHeight(6)
if type(U.skillBar.SetStatusBarTexture)=="function" then U.skillBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") end
if type(U.skillBar.SetMinMaxValues)=="function" then U.skillBar:SetMinMaxValues(0,300) end
if type(U.skillBar.SetStatusBarColor)=="function" then U.skillBar:SetStatusBarColor(.88,.69,.31,1) end
U.skillTrack=U.skillBar:CreateTexture(nil,"BACKGROUND")
U.skillTrack:SetAllPoints(U.skillBar)
U.skillTrack:SetColorTexture(.15,.17,.2,1)
U.skillText=text(header,"GameFontHighlightSmall",0,0,90,"")
U.skillText:SetJustifyH("RIGHT")
U.skillHover=CreateFrame("Frame",nil,header)
U.skillHover:EnableMouse(true)
tooltip(U.skillHover,function() return U.skillTitle or "" end,function() return U.skillLines or {} end)

U.priceChip=CreateFrame("Frame",nil,header,"BackdropTemplate")
CP:Round(U.priceChip)
U.priceChip:SetSize(92,22)
U.priceChip:EnableMouse(true)
U.priceDot=U.priceChip:CreateTexture(nil,"OVERLAY")
U.priceDot:SetSize(7,7)
U.priceDot:SetPoint("LEFT",U.priceChip,"LEFT",8,0)
U.priceText=text(U.priceChip,"GameFontHighlightSmall",20,-5,68,"")
tooltip(U.priceChip,L("Auktionshauspreise"),function() return {U.priceDetail or "",U.bankDetail or ""} end)

U.gear=button(header,30,30,0,0,"|TInterface\\Icons\\INV_Misc_Gear_01:16:16|t",function() CP:ToggleSettings() end)
tooltip(U.gear,L("Einstellungen"))
U.help=button(header,30,30,0,0,"?",function() if CP.db.ui.tab=="help" then CP:OpenTab(CP.db.ui.lastMainTab or "now") else CP:OpenTab("help") end end)
tooltip(U.help,L("Hilfe"))
U.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
U.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -12)

local resizeGrip=CreateFrame("Button",nil,frame)
resizeGrip:SetSize(18,18)
resizeGrip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
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

-- Tabs ------------------------------------------------------------------------------------------------------
U.tabs={
  {key="now", label=L("Jetzt")},
  {key="plan", label=L("Plan & Einkauf")},
  {key="trainers", label=L("Lehrer & Händler")},
  {key="camping", label=L("Camping")},
  {key="twinks", label=L("Twinks")},
  {key="endgame", label=L("Endgame")},
  {key="items", label=L("Gegenstände")},
}
-- 0.2.2: navigation in a sidebar on the left of the window instead of tabs on top. The sidebar is a child of the
-- window, attached to its left edge: it moves, hides and scales with it, and the window keeps its own layout.
local SIDE=180
U.tabIcons={now="Interface\\Icons\\INV_Misc_PocketWatch_01",plan="Interface\\Icons\\INV_Misc_Note_01",
  trainers="Interface\\Icons\\INV_Misc_Map_01",camping="Interface\\Icons\\Spell_Fire_Fire",
  twinks="Interface\\Icons\\INV_Misc_Head_Human_01",endgame="Interface\\Icons\\INV_Misc_Coin_02",
  items="Interface\\Icons\\INV_Misc_Book_09",settings="Interface\\Icons\\INV_Misc_Gear_01",help="Interface\\Icons\\INV_Misc_QuestionMark"}
local side=CreateFrame("Frame","CraftPilotProSidebar",frame,"BackdropTemplate")
U.side=side
side:SetWidth(SIDE)
side:SetPoint("TOPRIGHT",frame,"TOPLEFT",1,0)
side:SetPoint("BOTTOMRIGHT",frame,"BOTTOMLEFT",1,0)
CP:Round(side)
-- Solid backing under the sidebar: it hangs outside the window, so a skin's see-through panel style (or a
-- translucent backdrop) would let unit frames and other addons show through. Inset keeps the round corners.
-- 1.2.1: its own frame below the sidebar, so no skin can hide or fade it.
U.sideBase=CreateFrame("Frame",nil,frame)
U.sideBase:SetPoint("TOPLEFT",side,"TOPLEFT",3,-3);U.sideBase:SetPoint("BOTTOMRIGHT",side,"BOTTOMRIGHT",-3,3)
if type(U.sideBase.SetFrameLevel)=="function" and type(side.GetFrameLevel)=="function" then U.sideBase:SetFrameLevel(math.max(0,(side:GetFrameLevel() or 1)-1)) end
U.sideBacking=U.sideBase:CreateTexture(nil,"BACKGROUND",nil,-8)
U.sideBacking:SetAllPoints(U.sideBase)
side:EnableMouse(true)
if type(side.RegisterForDrag)=="function" then side:RegisterForDrag("LeftButton") end
side:SetScript("OnDragStart",function() if type(frame.StartMoving)=="function" then frame:StartMoving() end end)
side:SetScript("OnDragStop",function()
  if type(frame.StopMovingOrSizing)=="function" then frame:StopMovingOrSizing() end
  if CP.SaveWindowPosition then CP:SaveWindowPosition() end
end)
-- The window stays on screen together with its sidebar.
if type(frame.SetClampRectInsets)=="function" then frame:SetClampRectInsets(-SIDE,0,0,0) end
U.sideBrand=CreateFrame("Frame",nil,side);U.sideBrand:SetSize(30,30);U.sideBrand:SetPoint("TOPLEFT",side,"TOPLEFT",14,-14)
local sideLogo=U.sideBrand:CreateTexture(nil,"ARTWORK");sideLogo:SetAllPoints(U.sideBrand)
sideLogo:SetTexture("Interface\\AddOns\\CraftPilotPro\\Media\\CraftPilot")
U.sideTitle=text(side,"GameFontNormalLarge",52,-14,SIDE-60,"CraftPilot")
U.sideSub=text(side,"GameFontDisableSmall",52,-33,SIDE-60,L("Berufsbegleiter"))
local function navButton(key,caption,callback)
  local b=CreateFrame("Button",nil,side)
  b:SetSize(SIDE-16,34)
  b.bg=b:CreateTexture(nil,"BACKGROUND");b.bg:SetAllPoints(b);b.bg:SetColorTexture(1,1,1,0)
  b.hl=b:CreateTexture(nil,"HIGHLIGHT");b.hl:SetAllPoints(b);b.hl:SetColorTexture(1,1,1,.05)
  b.iconBox=b:CreateTexture(nil,"BORDER");b.iconBox:SetSize(26,26);b.iconBox:SetPoint("LEFT",b,"LEFT",6,0);b.iconBox:SetColorTexture(.91,.68,.31,1)
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(20,20);b.icon:SetPoint("CENTER",b.iconBox,"CENTER",0,0)
  b.icon:SetTexture(U.tabIcons[key]);if type(b.icon.SetTexCoord)=="function" then b.icon:SetTexCoord(.08,.92,.08,.92) end
  local label=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
  label:SetPoint("LEFT",b,"LEFT",40,0);label:SetPoint("RIGHT",b,"RIGHT",-30,0);label:SetJustifyH("LEFT")
  if type(b.SetFontString)=="function" then b:SetFontString(label) end
  b.label=label;b:SetText(caption)
  b.badge=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");b.badge:SetPoint("RIGHT",b,"RIGHT",-8,0)
  b.badge:SetTextColor(.94,.82,.54)
  b.selectionMarker=b.iconBox
  b:SetScript("OnClick",callback)
  return b
end
U.tabButtons={}
for i,t in ipairs(U.tabs) do
  local b=navButton(t.key,t.label,function() CP:OpenTab(t.key) end)
  b:SetPoint("TOPLEFT",side,"TOPLEFT",8,-124-(i-1)*36)
  U.tabButtons[i]=b
end
U.sideSettings=navButton("settings",L("Einstellungen"),function() CP:ToggleSettings() end)
U.sideSettings.craftNav="settings"
U.sideSettings:SetPoint("BOTTOMLEFT",side,"BOTTOMLEFT",8,96)
U.sideHelp=navButton("help",L("Hilfe"),function() if CP.db.ui.tab=="help" then CP:OpenTab(CP.db.ui.lastMainTab or "now") else CP:OpenTab("help") end end)
U.sideHelp.craftNav="help"
U.sideHelp:SetPoint("BOTTOMLEFT",side,"BOTTOMLEFT",8,60)
U.sideLine=side:CreateTexture(nil,"ARTWORK");U.sideLine:SetHeight(1)
U.sideLine:SetPoint("BOTTOMLEFT",side,"BOTTOMLEFT",1,54);U.sideLine:SetPoint("BOTTOMRIGHT",side,"BOTTOMRIGHT",-1,54)
U.sideLine:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
U.sideFoot=text(side,"GameFontDisableSmall",14,0,SIDE-24,"")
U.sideFoot:ClearAllPoints();U.sideFoot:SetPoint("BOTTOMLEFT",side,"BOTTOMLEFT",14,12)
-- Discord: a quiet link above the version; click shows it ready to copy.
U.sideDiscord=CreateFrame("Button",nil,side)
U.sideDiscord:SetSize(SIDE-24,16);U.sideDiscord:SetPoint("BOTTOMLEFT",side,"BOTTOMLEFT",14,32)
U.sideDiscord.label=text(U.sideDiscord,"GameFontHighlightSmall",0,0,SIDE-24,"|cff8fa8ff"..L("Discord-Community").."|r")
U.sideDiscord:SetScript("OnClick",function() CP:OpenDiscordLink() end)
tooltip(U.sideDiscord,L("Discord-Community"),function() return {CP.discordURL,L("Anklicken: Link zum Kopieren")} end)
-- Page title where the tabs used to be.
U.tabLine=frame:CreateTexture(nil,"ARTWORK")
U.tabLine:SetHeight(1)
U.tabLine:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
-- On the header itself: text on the main frame would sit beneath the header's own background.
U.pageTitle=text(header,"GameFontNormalLarge",19,-60,W-200,"")
U.pageSub=text(header,"GameFontHighlightSmall",19,-80,W-200,"")
if type(U.pageSub.SetTextColor)=="function" then U.pageSub:SetTextColor(.72,.70,.66) end
-- 0.2.3: how many items are reserved for plans, keep-for-later and the raid stock; a click opens the list.
U.reservedChip=CreateFrame("Button",nil,header,"BackdropTemplate")
CP:Round(U.reservedChip,true);U.reservedChip:SetSize(150,22)
U.reservedText=text(U.reservedChip,"GameFontHighlightSmall",10,-5,132,"")
U.reservedChip:SetScript("OnClick",function() CP:OpenTab("reservations") end)
tooltip(U.reservedChip,L("Reservierte Gegenstände"),function() return {L("Markiert in Taschen und Bank, mit Warnung beim Verkaufen, Zerstören, Entzaubern und Verschicken."),L("Anklicken: Vorratsreservierung öffnen")} end)
-- Endgame: four sub-pages as segment buttons.
U.endgamePages={{key="profit",label=L("Gewinn")},{key="stock",label=L("Raid-Vorrat")},{key="wish",label=L("Sammlung")},{key="favor",label=L("Merchant's Favor")}}
U.endgameButtons={}
for i,p in ipairs(U.endgamePages) do
  local b=segment(frame,128,26,p.label,function() CP.db.ui.endgamePage=p.key;CP:Render() end)
  b:Hide()
  U.endgameButtons[i]=b
end
-- 1.2.0: item database – three pages, a search field and "back to the results".
U.itemPages={{key="search",label=L("Suchen")},{key="build",label=L("Jetzt herstellbar")},{key="watch",label=L("Merkliste")}}
U.itemButtons={}
for i,p in ipairs(U.itemPages) do
  local b=segment(frame,128,26,p.label,function() CP.db.ui.itemPage=p.key;CP:Render() end)
  b:Hide()
  U.itemButtons[i]=b
end
U.itemSearch=CreateFrame("EditBox","CraftPilotProItemSearch",frame,"InputBoxTemplate")
U.itemSearch:SetSize(260,24);U.itemSearch:SetAutoFocus(false);U.itemSearch:Hide()
U.itemSearch:SetScript("OnTextChanged",function(self,user)
  if not user then return end
  CP.db.ui.itemQuery=self:GetText();CP.db.ui.itemSelected=nil
  if CP.itemSearchTimer and CP.itemSearchTimer.Cancel then CP.itemSearchTimer:Cancel() end
  if C_Timer and type(C_Timer.NewTimer)=="function" then CP.itemSearchTimer=C_Timer.NewTimer(.25,function() CP:Render() end) else CP:Render() end
end)
U.itemSearch:SetScript("OnEnterPressed",function(self) self:ClearFocus();CP:Render() end)
U.itemSearch:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
CP.itemSearchBox=U.itemSearch
U.itemResults=segment(frame,150,26,L("Zu den Ergebnissen"),function() CP.db.ui.itemSelected=nil;CP:Render() end)
U.itemResults:Hide()
U.back=button(header,110,26,0,0,L("Zurück"),function() CP:OpenTab(CP.db.ui.lastMainTab or "now") end)
U.section=text(frame,"GameFontNormal",18,-104,W-50,"")

-- Generic scroll area, used by every view except the recipe list --------------------------------------------
U.contentPanel=CreateFrame("Frame",nil,frame)
U.scroll=CreateFrame("ScrollFrame","CraftPilotProScroll",U.contentPanel,"UIPanelScrollFrameTemplate")
U.scroll:SetPoint("TOPLEFT",U.contentPanel,"TOPLEFT",0,0)
U.scroll:SetPoint("BOTTOMRIGHT",U.contentPanel,"BOTTOMRIGHT",-24,0)
U.content=CreateFrame("Frame",nil,U.scroll)
U.content:SetWidth(W-96)
U.content:SetHeight(320)
U.scroll:SetScrollChild(U.content)
local content=U.content

-- Recipe list (left) and detail (right) for the Jetzt tab --------------------------------------------------
U.listPanel=panel(frame,"panel")
U.filterButton=button(U.listPanel,190,26,8,-8,"",function()
  U.filterMenu:SetShown(not U.filterMenu:IsShown());U.profMenu:Hide()
end)
U.countText=text(U.listPanel,"GameFontDisableSmall",0,-14,120,"")
U.countText:SetJustifyH("RIGHT")
U.filterMenu=panel(frame,"raised")
U.filterMenu:SetFrameStrata("DIALOG")
U.filterMenu:SetSize(240,128)
U.filterMenu:Hide()
for i,view in ipairs({{key="useful",label=L("Sinnvolle Rezepte"),hint=L("erlernt, gibt Punkte")},
    {key="unlearned",label=L("Nicht gelernt"),hint=L("beim Lehrer oder Händler")},
    {key="all",label=L("Alle Rezepte"),hint=L("inkl. grauer und zukünftiger")},
    {key="merchants",label=L("Händlerrezepte"),hint=L("vollständiges Verzeichnis")}}) do
  local item=button(U.filterMenu,224,26,8,-8-(i-1)*29,view.label,function()
    U.filterMenu:Hide()
    local ui=CP.db.ui
    ui.vendorBrowser=view.key=="merchants";ui.vendorOnly=view.key=="unlearned";ui.allRecipes=view.key=="all"
    if view.key=="merchants" then CP:OpenTab("trainers") else CP:Render() end
  end)
  item.viewKey=view.key;item.hint=view.hint
  U.filterItems[i]=item
end
U.sortCols={}
for i,col in ipairs({{key="name",label=L("Rezept")},{key="chance",label=L("Chance")},{key="cost",label=L("je Punkt")}}) do
  local b=CreateFrame("Button",nil,U.listPanel)
  b:SetHeight(18)
  local label=b:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  label:SetAllPoints(b);label:SetJustifyH(i==1 and "LEFT" or "RIGHT")
  if type(b.SetFontString)=="function" then b:SetFontString(label) end
  b.label=label;b.sortKey=col.key;b.baseLabel=col.label
  b:SetScript("OnClick",function() CP.db.ui.recipeSort=col.key;CP:Render() end)
  U.sortCols[i]=b
end
U.listLine=U.listPanel:CreateTexture(nil,"ARTWORK")
U.listLine:SetHeight(1)
U.listLine:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
U.listScroll=CreateFrame("ScrollFrame","CraftPilotProRecipeScroll",U.listPanel,"UIPanelScrollFrameTemplate")
U.listContent=CreateFrame("Frame",nil,U.listScroll)
U.listContent:SetSize(300,200)
U.listScroll:SetScrollChild(U.listContent)

-- Recommendation banner above the list: the single next step, ready to act on.
U.rec=panel(frame,"raised")
U.rec.stripe=U.rec:CreateTexture(nil,"OVERLAY");U.rec.stripe:SetWidth(3)
U.rec.stripe:SetPoint("TOPLEFT",U.rec,"TOPLEFT",0,0);U.rec.stripe:SetPoint("BOTTOMLEFT",U.rec,"BOTTOMLEFT",0,0)
U.rec.stripe:SetColorTexture(.88,.69,.31,1)
U.rec.icon=U.rec:CreateTexture(nil,"ARTWORK");U.rec.icon:SetSize(32,32);U.rec.icon:SetPoint("LEFT",U.rec,"LEFT",12,0)
U.rec.title=text(U.rec,"GameFontNormal",54,-9,400,"");U.rec.title:SetWordWrap(false)
U.rec.detail=text(U.rec,"GameFontHighlightSmall",54,-28,400,"");U.rec.detail:SetWordWrap(false)
U.rec.extra=text(U.rec,"GameFontHighlightSmall",54,-44,400,"");U.rec.extra:SetWordWrap(false)
U.rec.search=primaryButton(U.rec,150,28,L("Im AH suchen"),function() CP:SearchRecommendation() end)
U.rec.pick=button(U.rec,110,28,0,0,L("Auswählen"),function()
  local r=CP.currentRecommendation;if not r then return end
  CP.db.ui.selectedVendorRecipe=nil;CP.db.ui.selectedVendorKey=nil
  CP.db.ui.selectedRecipes[r.key]=r.id;CP:Render()
end)
U.rec.prices=button(U.rec,120,28,0,0,L("Preise prüfen"),function()
  local r=CP.currentRecommendation;if not (r and r.path) then return end
  local items={};for _,id in ipairs(r.path.priceItems or {}) do items[#items+1]={id=id,quantity=1} end
  if not CP:AuctionHouseOpen() then CP:Say(L("Am Auktionshaus scannt Auctionator genau diese Materialien neu."));return end
  CP:SearchItems(items,L("Preise"),L("Auctionator scannt die Materialien deines Weges."))
end)
U.rec.prices:Hide()
-- 1.3.0: switch between your plan and the cheapest path; it stays a suggestion.
U.rec.switch=button(U.rec,140,28,0,0,"",function()
  local r=CP.currentRecommendation;if not (r and r.alternative) then return end
  CP.db.ui.recSource=type(CP.db.ui.recSource)=="table" and CP.db.ui.recSource or {}
  CP.db.ui.recSource[r.key]=r.alternative.source
  CP:Render()
end)
U.rec.switch:Hide()
U.rec:Hide()
-- 1.1.0: the budget, visible on "Jetzt" right below the recommendation; a click opens the input.
U.budget=CreateFrame("Button",nil,frame,"BackdropTemplate")
CP:Round(U.budget,true);U.budget:SetBackdropColor(.098,.114,.137,1)
U.budget.icon=U.budget:CreateTexture(nil,"ARTWORK");U.budget.icon:SetSize(16,16);U.budget.icon:SetPoint("LEFT",U.budget,"LEFT",12,0)
if type(U.budget.icon.SetTexture)=="function" then U.budget.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02") end
U.budget.text=U.budget:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");U.budget.text:SetPoint("LEFT",U.budget,"LEFT",36,0);U.budget.text:SetJustifyH("LEFT");U.budget.text:SetWordWrap(false)
U.budget.action=U.budget:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");U.budget.action:SetPoint("RIGHT",U.budget,"RIGHT",-12,0);U.budget.action:SetJustifyH("RIGHT")
U.budget:SetScript("OnClick",function() CP:OpenBudgetWindow() end)
CP.budgetStrip=U.budget
U.budget:Hide()

U.detailPanel=panel(frame,"panel")
U.detailScroll=CreateFrame("ScrollFrame","CraftPilotProDetailScroll",U.detailPanel,"UIPanelScrollFrameTemplate")
U.detailContent=CreateFrame("Frame",nil,U.detailScroll)
U.detailContent:SetSize(300,200)
U.detailScroll:SetScrollChild(U.detailContent)
CP.recipeDetail=U.detail
CP.recBanner=U.rec

-- Plan & Einkauf controls -------------------------------------------------------------------------------------
U.plan={}
U.plan.rangeLabel=text(frame,"GameFontHighlightSmall",18,0,36,L("Von"))
U.plan.rangeStart=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
U.plan.rangeStart:SetSize(46,24)
U.plan.targetLabel=text(frame,"GameFontHighlightSmall",0,0,28,L("bis"))
U.plan.rangeEnd=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
U.plan.rangeEnd:SetSize(46,24)
U.plan.quantityLabel=text(frame,"GameFontHighlightSmall",0,0,52,L("Menge"))
U.plan.rangeQty=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
U.plan.rangeQty:SetSize(46,24)
for _,field in ipairs({U.plan.rangeStart,U.plan.rangeEnd,U.plan.rangeQty}) do
  if type(field.SetNumeric)=="function" then field:SetNumeric(true) end
  if type(field.SetAutoFocus)=="function" then field:SetAutoFocus(false) end
  field:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  field:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
end
local function fieldNumber(field,fallback)
  local value=type(field.GetText)=="function" and field:GetText() or nil
  return tonumber(value) or fallback
end
U.plan.build=primaryButton(frame,130,26,L("Plan erstellen"),function()
  local key=CP.db.view
  local p=CP:PlanFor(key)
  if not CP:SetPlanRange(key,fieldNumber(U.plan.rangeStart,p.start),fieldNumber(U.plan.rangeEnd,p.target)) then
    CP:Say(L("Ungültiger Bereich."))
    return
  end
  local ok,route=CP:RequestRouteBuild(key)
  if not ok then CP:Say(route or L("Keine Kandidaten.")) end
  CP:Render()
end)
U.plan.add=button(frame,200,26,0,0,L("Gewähltes Rezept hinzufügen"),function()
  local key=CP.db.view
  if CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe then CP:Say(L("Erst das Kaufrezept lernen und den Beruf neu einlesen."));return end
  local p=CP:PlanFor(key)
  local a,z=fieldNumber(U.plan.rangeStart,p.start),fieldNumber(U.plan.rangeEnd,p.target)
  if (a~=p.start or z~=p.target) and not CP:SetPlanRange(key,a,z) then CP:Say(L("Ungültiger Bereich."));return end
  local chosen=CP:SelectedOption(key)
  if not chosen then CP:Say(L("Bitte erst ein aktuelles Rezept wählen."));return end
  if CP:AddPlanCraft(key,chosen.id,fieldNumber(U.plan.rangeQty,1)) then CP:Render()
  else CP:Say(L("Rezept oder Menge ungültig.")) end
end)
U.plan.draft=button(frame,150,26,0,0,L("Schnellschritt +10"),function()
  if CP:DraftPlanStep(CP.db.view) then CP:Render() end
end)
U.plan.print=button(frame,130,30,0,0,L("Im Chat ausgeben"),function() CP:PrintPlanShopping(CP.db.view) end)
U.plan.clear=button(frame,120,26,0,0,L("Plan leeren"),function()
  if CP.pendingPlanClear~=CP.db.view then
    CP.pendingPlanClear=CP.db.view
  else
    CP:ClearPlanCraft(CP.db.view)
    CP.pendingPlanClear=nil
  end
  CP:Render()
end)
U.plan.export=primaryButton(frame,150,30,L("An Auctionator"),function()
  local p=CP:PlanFor(CP.db.view)
  if fieldNumber(U.plan.rangeStart,p.start)~=p.start or fieldNumber(U.plan.rangeEnd,p.target)~=p.target then CP:Say(L("Bereich geändert · zuerst Plan erstellen."));return end
  CP:ExportToAuctionator(CP.db.view);CP:Render()
end)
U.plan.manual=button(frame,150,30,0,0,L("Eigene Liste bearbeiten"),function() CP:OpenPersonalShopping() end)
U.plan.totalLabel=text(frame,"GameFontDisableSmall",0,0,200,L("Zukauf gesamt"))
U.plan.total=text(frame,"GameFontNormalLarge",0,0,220,"")
U.plan.footerLine=frame:CreateTexture(nil,"ARTWORK")
U.plan.footerLine:SetHeight(1)
U.plan.footerLine:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
U.plan.pages={}
for i,page in ipairs({{key="shopping",label=L("Einkaufen")},{key="crafts",label=L("Herstellen")},{key="leftovers",label=L("Verwerten")},{key="details",label=L("Details")},{key="projects",label=L("Projekte")}}) do
  U.plan.pages[i]=segment(frame,96,24,page.label,function() CP.db.ui.planPage=page.key;CP:Render() end)
  U.plan.pages[i].pageKey=page.key
end
U.plan.controls={U.plan.rangeLabel,U.plan.rangeStart,U.plan.targetLabel,U.plan.rangeEnd,U.plan.quantityLabel,U.plan.rangeQty,
  U.plan.build,U.plan.add,U.plan.draft,U.plan.print,U.plan.clear,U.plan.export,U.plan.manual,U.plan.totalLabel,U.plan.total,
  U.plan.footerLine,U.plan.pages[1],U.plan.pages[2],U.plan.pages[3],U.plan.pages[4],U.plan.pages[5]}
local syncedPlan
local function syncPlanFields(key)
  local p=CP:PlanFor(key)
  local selected=CP:SelectedOption(key)
  local selectedID=selected and selected.id
  local marker=key..":"..p.start..":"..p.target..":"..tostring(selectedID)..":"..tostring(selectedID and CP:RecipeQuantityOverride(key,selectedID))
  if marker==syncedPlan then return end
  syncedPlan=marker
  U.plan.rangeStart:SetText(tostring(p.start))
  U.plan.rangeEnd:SetText(tostring(p.target))
  U.plan.rangeQty:SetText(tostring(selectedID and CP:RequestedRecipeQuantity(key,selectedID) or 1))
end

-- Lehrer & Händler controls ------------------------------------------------------------------------------------
U.trainer={}
U.trainer.pages={}
for i,page in ipairs({{key="trainers",label=L("Lehrer")},{key="merchants",label=L("Händlerrezepte")},{key="tour",label=L("Lerntour")},{key="spec",label=L("Spezialisierung")}}) do
  U.trainer.pages[i]=segment(frame,130,24,page.label,function()
    CP.db.ui.vendorBrowser=page.key=="merchants";CP.db.ui.trainerPage=page.key;CP:Render()
  end)
  U.trainer.pages[i].pageKey=page.key
end
U.trainer.info=text(frame,"GameFontHighlightSmall",0,0,300,"")
U.trainer.recommend=primaryButton(frame,190,26,L("Empfohlenen markieren"),function() CP:TrainerWaypoint() end)
U.trainer.nearest=button(frame,150,26,0,0,L("Nächsten markieren"),function() CP:TrainerWaypoint("nearest") end)
U.merchant={}
U.merchant.searchLabel=text(frame,"GameFontDisableSmall",0,0,50,L("Suche"))
U.merchant.search=CreateFrame("EditBox",nil,frame,"InputBoxTemplate");U.merchant.search:SetAutoFocus(false);U.merchant.search:SetSize(220,24)
U.merchant.search:SetScript("OnTextChanged",function(box) if not box.craftSync and CP.db then CP.db.ui.vendorQuery=box:GetText();CP:Render() end end)
U.merchant.search:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
U.merchant.search:SetScript("OnEnterPressed",function(box) box:ClearFocus() end)
U.merchant.clear=button(frame,70,26,0,0,L("Leeren"),function() CP.db.ui.vendorQuery="";CP:Render() end)
U.merchant.bySkill=button(frame,100,26,0,0,L("Nach Skill"),function() CP.db.ui.vendorSort="skill";CP:Render() end)
U.merchant.byName=button(frame,100,26,0,0,L("Nach Name"),function() CP.db.ui.vendorSort="name";CP:Render() end)
U.merchant.controls={U.merchant.searchLabel,U.merchant.search,U.merchant.clear,U.merchant.bySkill,U.merchant.byName}
U.trainer.controls={U.trainer.info,U.trainer.recommend,U.trainer.nearest,U.trainer.pages[1],U.trainer.pages[2],U.trainer.pages[3],U.trainer.pages[4]}

-- Camping controls --------------------------------------------------------------------------------------------
U.camp={}
for i,page in ipairs({{key="fires",label=L("Lagerfeuer")},{key="buffs",label=L("Buffs")},{key="objects",label=L("Objekte")},{key="shopping",label=L("Einkauf")}}) do
  U.camp[i]=segment(frame,110,24,page.label,function()
    CP.db.ui.campingPage=page.key;CP:Render()
  end)
  U.camp[i].pageKey=page.key
end
U.campFilter=button(frame,170,26,0,0,L("Nur gewählter Beruf"),function()
  CP.db.ui.campingAll=CP.db.ui.campingAll==false
  CP:Render()
end)

U.segBg={}
for _,name in ipairs({"plan","trainer","camp","items","endgame"}) do
  local bg=panel(frame,"raised")
  bg:SetFrameLevel(math.max(0,(frame:GetFrameLevel() or 1)))
  bg:Hide()
  U.segBg[name]=bg
end
local function segmentGroup(name,buttons)
  local first,last=buttons[1],buttons[#buttons]
  local bg=U.segBg[name]
  local x1,y1=select(4,first:GetPoint(1)),select(5,first:GetPoint(1))
  local x2=select(4,last:GetPoint(1))
  if type(x1)~="number" or type(x2)~="number" or type(y1)~="number" then return end
  local w=(x2-x1)+(last:GetWidth() or 0)
  bg:ClearAllPoints();bg:SetPoint("TOPLEFT",frame,"TOPLEFT",x1-3,y1+3);bg:SetSize(w+6,(first:GetHeight() or 24)+6)
  bg:Show()
  for _,b in ipairs(buttons) do if type(b.SetFrameLevel)=="function" then b:SetFrameLevel((bg:GetFrameLevel() or 0)+2) end end
end
U.segmentGroup=segmentGroup

-- Settings header -----------------------------------------------------------------------------------------------
U.settingsTitle=text(frame,"GameFontNormalLarge",18,0,300,L("Einstellungen"))
U.settingsDone=button(frame,90,26,0,0,L("Fertig"),function() CP:ToggleSettings() end)

-- Footer --------------------------------------------------------------------------------------------------------
U.footer=text(frame,"GameFontDisableSmall",19,0,W-200,"")
U.report=button(frame,110,22,0,0,L("Fehler melden"),function() CP:OpenDiagnosticReport() end)
U.footerLine=frame:CreateTexture(nil,"ARTWORK")
U.footerLine:SetHeight(1)
U.footerLine:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)

-- Shared renderers ----------------------------------------------------------------------------------------------
local resetContentScroll=true
local lastContentContext
local function gold(value) return CP:FormatMoney(value) end
local function width() return (type(frame.GetWidth)=="function" and frame:GetWidth()) or W end

local function clearRows()
  for _,r in ipairs(U.rows) do r:Hide() end
  for _,b in ipairs(U.trainerRows) do b:Hide() end
  for _,b in ipairs(U.recipeRows) do b:Hide() end
  for _,b in ipairs(U.vendorRows) do b:Hide() end
  for _,b in ipairs(U.cards) do b:Hide() end
  for _,b in ipairs(U.learnRows) do b:Hide() end
  if U.rows.learnTitle then U.rows.learnTitle:Hide() end
end

local function finishContent(height)
  content:SetHeight(math.max(200,height))
  if resetContentScroll and type(U.scroll.SetVerticalScroll)=="function" then U.scroll:SetVerticalScroll(0) end
end

local function setRows(lines)
  clearRows()
  for i,entry in ipairs(lines) do
    local row=U.rows[i]
    if not row then
      row=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
      row:SetJustifyV("TOP")
      row:SetJustifyH("LEFT")
      row:SetWordWrap(true)
      U.rows[i]=row
    end
    row:ClearAllPoints();row:SetPoint("TOPLEFT",content,"TOPLEFT",5,-(i-1)*35)
    row:SetWidth((content:GetWidth() or W-96)-10);row:SetHeight(35)
    row:SetText(entry)
    row:Show()
  end
  finishContent(#lines*35+16)
end

local function learnRow(i,offset,entry,key)
  local r=U.learnRows[i]
  if not r then
    r=CP:CreateFlatAction(content,W-120,44,function() end)
    r.dot=r:CreateTexture(nil,"OVERLAY");r.dot:SetSize(8,8);r.dot:SetPoint("LEFT",r,"LEFT",12,0)
    r.nameLabel=text(r,"GameFontHighlight",28,-6,300,"")
    r.infoLabel=text(r,"GameFontDisableSmall",28,-24,300,"")
    r.fee=text(r,"GameFontHighlightSmall",0,-15,110,"");r.fee:SetJustifyH("RIGHT")
    r.go=button(r,90,24,0,0,L("Wegpunkt"),function() if r.go.waypoint then CP:SetWaypoint(r.go.waypoint) end end)
    r.sep=r:CreateTexture(nil,"ARTWORK");r.sep:SetHeight(1)
    r.sep:SetPoint("BOTTOMLEFT",r,"BOTTOMLEFT",8,0);r.sep:SetPoint("BOTTOMRIGHT",r,"BOTTOMRIGHT",-8,0)
    U.learnRows[i]=r
  end
  local w=(content:GetWidth() or W-96)-8
  r:ClearAllPoints();r:SetPoint("TOPLEFT",content,"TOPLEFT",4,-offset);r:SetSize(w,44)
  r:SetBackdropColor(0,0,0,0);r:SetBackdropBorderColor(0,0,0,0)
  r.sep:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
  dot(r.dot,SKILL_COLORS[colorOf(entry)])
  local vendor=entry.vendors and entry.vendors[1]
  r.go.waypoint=vendor and vendor.location
  r.craftRecipe=entry
  r.nameLabel:SetWidth(w-260);r.nameLabel:SetText(entry.name)
  local source=vendor and (vendor.name..(vendor.location and (" · "..vendor.location.zone) or "")) or L("Bezugsquelle unbekannt")
  r.infoLabel:SetWidth(w-260);r.infoLabel:SetText((entry.trainerRecipe and L("Lehrer · ") or L("Händler · "))..source)
  local fee=entry.trainerRecipe and entry.comparison and entry.comparison.cost and (entry.comparison.cost.feeUnknown and L("unbekannt") or CP:CompactMoney(entry.comparison.cost.fee))
    or (entry.recipeCost and CP:CompactMoney(entry.recipeCost)) or L("Preis prüfen")
  r.fee:ClearAllPoints();r.fee:SetPoint("RIGHT",r,"RIGHT",-108,0);r.fee:SetText(fee)
  r.go:ClearAllPoints();r.go:SetPoint("RIGHT",r,"RIGHT",-8,0);r.go:SetEnabled(r.go.waypoint~=nil)
  r:SetScript("OnClick",function() CP.db.ui.tab="now";CP:ActivateRecipeRow(key,entry) end)
  r:Show()
  return 44
end

local function setTrainerRows(choices,recommended,nearest,selected,offers,key)
  clearRows()
  local offset=0
  local w=(content:GetWidth() or W-96)-8
  for i,entry in ipairs(choices) do
    local b=U.trainerRows[i]
    if not b then
      b=CP:CreateFlatAction(content,W-120,44,function()
        local current=b.craftTrainer
        if current then
          CP.db.ui.selectedTrainers[CP.db.view]=current.name
          CP:SetWaypoint(current)
          CP:Render()
        end
      end)
      b.nameLabel=text(b,"GameFontHighlight",12,-6,300,"")
      b.infoLabel=text(b,"GameFontDisableSmall",12,-24,300,"")
      b.capLabel=text(b,"GameFontHighlightSmall",0,-15,140,"");b.capLabel:SetJustifyH("RIGHT")
      b.sep=b:CreateTexture(nil,"ARTWORK");b.sep:SetHeight(1)
      b.sep:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",8,0);b.sep:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-8,0)
      U.trainerRows[i]=b
    end
    local npc=entry.npc
    b.craftTrainer=npc
    b:ClearAllPoints();b:SetPoint("TOPLEFT",content,"TOPLEFT",4,-offset);b:SetSize(w,44)
    b:SetBackdropColor(0,0,0,0);b:SetBackdropBorderColor(0,0,0,0)
    b.sep:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
    local flags=""
    if npc==recommended then flags=flags.."  |cff7fd99a"..L("Empfohlen")..RESET end
    if npc==nearest then flags=flags.."  "..GOLD..L("Am nächsten")..RESET end
    if selected==npc.name then flags=flags.."  |cfff0d08a"..L("Wegpunkt gesetzt")..RESET end
    b.nameLabel:SetWidth(w-170);b.nameLabel:SetText(npc.name..flags)
    local metric=entry.distance and string.format(L(" · Kartenabstand %.1f"),entry.distance)
      or (entry.inZone and L(" · gleiche Zone") or "")
    b.infoLabel:SetWidth(w-170);b.infoLabel:SetText(npc.zone..string.format(" · %.1f / %.1f",npc.x*100,npc.y*100)..metric)
    b.capLabel:ClearAllPoints();b.capLabel:SetPoint("RIGHT",b,"RIGHT",-12,0)
    b.capLabel:SetText(entry.canTeach and (L("lehrt bis ")..npc.cap) or (MUTED..L("nur bis ")..npc.cap..RESET))
    b:Show()
    offset=offset+44
  end
  if #choices==0 then
    setRows({L("Für deine Fraktion ist noch kein Lehrer hinterlegt."),L("Bitte einen fehlenden Lehrerstandort als GitHub-Issue melden.")})
    offset=80
  end
  if offers and #offers>0 then
    local label=U.rows.learnTitle or content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    U.rows.learnTitle=label
    label:ClearAllPoints();label:SetPoint("TOPLEFT",content,"TOPLEFT",6,-(offset+12));label:SetText(L("Rezepte zum Lernen"));label:Show()
    offset=offset+38
    for i,entry in ipairs(offers) do offset=offset+learnRow(i,offset,entry,key) end
  elseif U.rows.learnTitle then U.rows.learnTitle:Hide() end
  finishContent(offset+12)
end

-- Merchant directory cards (Lehrer & Händler → Händlerrezepte). Recipe icons come from the game client.
local function setRecipeRows(key,options,chosen)
  clearRows()
  local offset=0
  for i,entry in ipairs(options) do
    local b=U.recipeRows[i]
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
      if type(b.CreateTexture)=="function" then
        local icon=b:CreateTexture(nil,"ARTWORK")
        if icon then
          icon:SetSize(32,32)
          icon:SetPoint("TOPLEFT",b,"TOPLEFT",9,-8)
          b.craftIcon=icon
        end
        local stripe=b:CreateTexture(nil,"OVERLAY")
        if stripe then
          stripe:SetSize(2,68)
          stripe:SetPoint("LEFT",b,"LEFT",1,0)
          b.craftStripe=stripe
        end
      end
      U.recipeRows[i]=b
    end
    b.craftRecipe=entry
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",content,"TOPLEFT",4,-offset)
    b:SetSize((content:GetWidth() or (W-95))-8,122)
    if b.craftIcon and type(b.craftIcon.SetTexture)=="function" then
      local texture=entry.icon
      if not texture and entry.outputItemID and C_Item and type(C_Item.GetItemIconByID)=="function" then
        local ok,value=pcall(C_Item.GetItemIconByID,entry.outputItemID)
        if ok then texture=value end
      end
      b.craftIcon:SetTexture(texture or "Interface\\Icons\\INV_Misc_Note_01")
    end
    local active=entry.vendorRecipe and CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe==entry.id
    b:SetBackdropBorderColor(active and .85 or PALETTE.border[1],active and .64 or PALETTE.border[2],active and .3 or PALETTE.border[3],1)
    b.nameLabel:SetText(entry.name)
    b:SetAlpha(entry.dimmed and .5 or 1)
    if entry.referenceOnly then b.infoLabel:SetText(entry.referenceStatus or "") end
    entry.active=active
    local rowHeight=entry.merchantBrowse and CP:LayoutVendorRecipeCard(b,key,entry,(b:GetWidth() or W-110))
      or CP:LayoutRecipeCard(b,key,entry,(b:GetWidth() or W-110))
    b:SetHeight(rowHeight)
    if b.craftStripe then
      b.craftStripe:SetHeight(rowHeight-12)
      b.craftStripe:SetColorTexture(active and .91 or .37,active and .68 or .48,active and .31 or .67,.95)
    end
    b:Show()
    offset=offset+rowHeight+6
  end
  finishContent(offset+16)
end

-- Cards for plan, camping, settings, economy and data views.
-- 0.2.2: optional controls on a card: a stepper (minus, value, plus) at the top right, a progress bar and up to
-- two buttons at the bottom right. Returns the extra height the card needs.
function CP:CardControls(b,entry,cardWidth,height)
  local extra=0
  local st=entry.stepper
  if st and not rawget(b,"stepMinus") then
    b.stepMinus=button(b,26,24,0,0,"-",function() local s=b.stepSpec;if s then s.apply(math.max(s.min,s.value-(s.step or 1))) end end)
    b.stepPlus=button(b,26,24,0,0,"+",function() local s=b.stepSpec;if s then s.apply(math.min(s.max,s.value+(s.step or 1))) end end)
    b.stepValue=b:CreateFontString(nil,"OVERLAY","GameFontNormal");b.stepValue:SetWidth(30);b.stepValue:SetJustifyH("CENTER")
  end
  if rawget(b,"stepMinus") then
    b.stepSpec=st
    b.stepMinus:SetShown(st~=nil);b.stepPlus:SetShown(st~=nil);b.stepValue:SetShown(st~=nil)
    if st then
      b.stepPlus:ClearAllPoints();b.stepPlus:SetPoint("TOPRIGHT",b,"TOPRIGHT",-10,-8)
      b.stepValue:ClearAllPoints();b.stepValue:SetPoint("RIGHT",b.stepPlus,"LEFT",-2,0)
      b.stepMinus:ClearAllPoints();b.stepMinus:SetPoint("RIGHT",b.stepValue,"LEFT",-2,0)
      b.stepValue:SetText(tostring(st.value))
      if b.titleLabel and type(b.titleLabel.SetWidth)=="function" then b.titleLabel:SetWidth(math.max(80,cardWidth-170)) end
    end
  end
  local p=entry.progress
  if p and not rawget(b,"progBg") then
    b.progBg=b:CreateTexture(nil,"ARTWORK");b.progBg:SetHeight(5);b.progBg:SetColorTexture(.15,.17,.2,1)
    b.progFill=b:CreateTexture(nil,"OVERLAY");b.progFill:SetHeight(5)
  end
  if rawget(b,"progBg") then
    b.progBg:SetShown(p~=nil);b.progFill:SetShown(p~=nil and p>0)
    if p then
      local w=math.max(40,cardWidth-80)
      b.progBg:ClearAllPoints();b.progBg:SetPoint("TOPLEFT",b,"TOPLEFT",55,-(height-6));b.progBg:SetWidth(w)
      b.progFill:ClearAllPoints();b.progFill:SetPoint("TOPLEFT",b.progBg,"TOPLEFT",0,0);b.progFill:SetWidth(math.max(1,w*math.min(1,p)))
      if p>=1 then b.progFill:SetColorTexture(.37,.79,.54,1) else b.progFill:SetColorTexture(.88,.69,.31,1) end
      extra=extra+10
    end
  end
  local list=entry.buttons
  b.cardButtons=rawget(b,"cardButtons") or {}
  for i=1,2 do
    local item=list and list[i]
    local cb=b.cardButtons[i]
    if item and not cb then
      cb=button(b,150,24,0,0,"",function() local spec=b.cardButtons[i].spec;if spec and spec.action then spec.action() end end)
      b.cardButtons[i]=cb
    end
    if cb then
      cb.spec=item
      cb:SetShown(item~=nil)
      if item then
        cb:SetText(item.label)
        cb:ClearAllPoints()
        if i==1 then cb:SetPoint("TOPRIGHT",b,"TOPRIGHT",-10,-(height+extra-4))
        else cb:SetPoint("RIGHT",b.cardButtons[1],"LEFT",-6,0) end
      end
    end
  end
  if list and #list>0 then extra=extra+28 end
  return extra
end

local function setVisualCards(entries)
  clearRows()
  local ui=CP.db and CP.db.ui
  local settingsView=ui and (ui.tab=="settings" or ui.tab=="audit" or ui.tab=="reservations")
  local baseHeight=settingsView and 92 or 73
  local offset=0
  -- 0.2.3: cards marked grid sit side by side, two or three per row depending on the width.
  local gridCol,gridRow,gridCols=0,0,2
  for i,entry in ipairs(entries) do
    if not entry.grid and gridCol>0 then offset=offset+gridRow+8;gridCol,gridRow=0,0 end
    local market=not entry.metrics and not entry.bars and entry.showMarket~=false and (entry.recipeID and CP:RecipeMarketText(entry.recipeKey or CP.db.view,entry.recipeID)
      or (entry.tooltipItem and CP:ItemMarketText(entry.tooltipItem))) or nil
    local cardHeight=market and 122 or baseHeight
    local b=U.cards[i]
    if not b then
      b=CreateFrame("Button",nil,content,"BackdropTemplate")
      b:SetSize(W-110,cardHeight-5)
      CP:Round(b)
      b.titleLabel=text(b,"GameFontNormal",55,-7,W-170,"")
      b.detailLabel=text(b,"GameFontHighlightSmall",55,-30,W-170,"")
      b.footLabel=text(b,"GameFontDisableSmall",55,-51,W-170,"")
      b.marketLabel=text(b,"GameFontHighlightSmall",55,-52,W-170,"")
      if type(b.CreateTexture)=="function" then
        b.artFrame=CreateFrame("Frame",nil,b)
        b.artFrame:SetAllPoints(b)
        b.craftIcon=b.artFrame:CreateTexture(nil,"ARTWORK")
        if b.craftIcon then
          b.craftIcon:SetSize(30,30)
          b.craftIcon:SetPoint("TOPLEFT",b,"TOPLEFT",12,-9)
        end
        b.craftStripe=b.artFrame:CreateTexture(nil,"OVERLAY")
        if b.craftStripe then
          b.craftStripe:SetSize(3,52)
          b.craftStripe:SetPoint("LEFT",b,"LEFT",1,0)
        end
        b.craftDot=b.artFrame:CreateTexture(nil,"OVERLAY")
        if b.craftDot then
          b.craftDot:SetSize(1,1)
          b.craftDot:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",22,8)
        end
      end
      -- 0.2.1: right-click runs a card's second action (e.g. wishlist on/off), left-click the first.
      if type(b.RegisterForClicks)=="function" then b:RegisterForClicks("LeftButtonUp","RightButtonUp") end
      b:SetScript("OnClick",function(_,button)
        if button=="RightButton" and type(b.craftRightAction)=="function" then b.craftRightAction()
        elseif type(b.craftAction)=="function" then b.craftAction() end
      end)
      U.cards[i]=b
      if CP.ellesmereSkin and type(CP.ellesmereSkin.Panel)=="function" then
        pcall(CP.ellesmereSkin.Panel,b)
      end
    end
    -- Parts a card drew for an earlier page (value bars, metric panels, tables) go before it is reused.
    for _,row in ipairs(rawget(b,"barRows") or {}) do for _,part in pairs(row) do part:Hide() end end
    for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
    if rawget(b,"dataTable") then b.dataTable:Hide() end
    CP:CardControls(b,{},0,0)
    if rawget(b,"settingCheck") then b.settingCheck:Hide() end
    b.craftAction=entry.action
    b.craftRightAction=entry.rightAction
    b.tooltipItem=entry.tooltipItem
    b.tooltipSpell=entry.tooltipSpell
    if entry.sectionHeader then
      -- A plain group heading between cards, no frame.
      if type(b.SetBackdropColor)=="function" then b:SetBackdropColor(0,0,0,0);b:SetBackdropBorderColor(0,0,0,0) end
      for _,name in ipairs({"detailLabel","footLabel","marketLabel","craftIcon","craftStripe","craftDot"}) do if rawget(b,name) then b[name]:Hide() end end
      for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
      if rawget(b,"dataTable") then b.dataTable:Hide() end
      if b.settingSlider then b.settingSlider:Hide() end
      CP:CardControls(b,{},0,0)
      b.titleLabel:Show();b.titleLabel:SetFontObject("GameFontDisableSmall")
      b.titleLabel:ClearAllPoints();b.titleLabel:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",4,4)
      b.titleLabel:SetText(entry.title or "")
      b:ClearAllPoints();b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-offset)
      b:SetSize((content:GetWidth() or W-95)-8,30)
      offset=offset+32
      b:Show()
    else
    b.titleLabel:ClearAllPoints();b.titleLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-7)
    if type(b.SetBackdropColor)=="function" and not CP.ellesmereSkin then
      b:SetBackdropColor(PALETTE.panel[1],PALETTE.panel[2],PALETTE.panel[3],1)
      b:SetBackdropBorderColor(PALETTE.panel[1],PALETTE.panel[2],PALETTE.panel[3],1)
    end
    if entry.slider then
      if not b.settingSlider then
        local slider=CreateFrame("Slider","CraftPilotProSettingsSlider"..i,b)
        b.settingSlider=slider
        slider:SetPoint("TOPLEFT",b,"TOPLEFT",60,-32)
        slider:SetHeight(18)
        slider:SetOrientation("HORIZONTAL")
        slider:EnableMouse(true)
        slider.track=slider:CreateTexture(nil,"BACKGROUND")
        slider.track:SetPoint("LEFT",slider,"LEFT",0,0)
        slider.track:SetPoint("RIGHT",slider,"RIGHT",0,0)
        slider.track:SetHeight(6)
        slider.track:SetColorTexture(.18,.21,.25,1)
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb=slider:GetThumbTexture()
        if thumb then thumb:SetSize(14,20);thumb:SetVertexColor(.88,.69,.31,1) end
        for _,part in ipairs({"Low","High","Text"}) do
          local label=rawget(slider,part) or _G["CraftPilotProSettingsSlider"..i..part]
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
      slider:SetMinMaxValues(spec.min,spec.max)
      slider:SetValueStep(spec.step)
      if type(slider.SetObeyStepOnDrag)=="function" then slider:SetObeyStepOnDrag(true) end
      slider:SetValue(spec.value)
      slider.craftSync=false
      slider:Show()
      b.detailLabel:ClearAllPoints()
      b.detailLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-30)
      b.detailLabel:SetShown(false)
    else
      if b.settingSlider then b.settingSlider:Hide() end
      b.detailLabel:ClearAllPoints()
      b.detailLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-30)
      b.detailLabel:Show()
    end
    b.footLabel:ClearAllPoints()
    b.footLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,market and -100 or (settingsView and -72 or -51))
    b:ClearAllPoints()
    local fullW=(content:GetWidth() or W-95)-8
    if entry.grid then
      gridCols=fullW>=900 and 3 or 2
      local colW=math.floor((fullW-(gridCols-1)*8)/gridCols)
      b:SetPoint("TOPLEFT",content,"TOPLEFT",5+gridCol*(colW+8),-offset)
      b:SetSize(colW,cardHeight-5)
    else
      b:SetPoint("TOPLEFT",content,"TOPLEFT",5,-offset)
      b:SetSize(fullW,cardHeight-5)
    end
    if entry.tint and type(b.SetBackdropColor)=="function" and not CP.ellesmereSkin then b:SetBackdropColor(entry.tint[1],entry.tint[2],entry.tint[3],1) end
    local r,g,bl=.32,.47,.69
    if entry.color=="green" then r,g,bl=.19,.75,.55 end
    if entry.color=="gold" then r,g,bl=.90,.69,.28 end
    if entry.color=="red" then r,g,bl=.93,.42,.36 end
    if b.craftStripe and type(b.craftStripe.SetColorTexture)=="function" then
      b.craftStripe:SetColorTexture(r,g,bl,1)
      if entry.grid and type(b.craftStripe.Hide)=="function" then b.craftStripe:Hide() end
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
      cardHeight=cardHeight+CP:CardControls(b,entry,(type(b.GetWidth)=="function" and b:GetWidth() or W-110),cardHeight)
      b:SetHeight(cardHeight-5)
    else
      CP:CardControls(b,{},0,0)
      for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
      if rawget(b,"dataTable") then b.dataTable:Hide() end
      b.titleLabel:Show();b.footLabel:Show()
      -- 0.2.1: slider cards with an item (raid stock) show its tooltip like every other item card.
      local item=entry.tooltipItem
      b:SetScript("OnEnter",item and function() CP:ShowCraftTooltip(b,entry.recipeKey or CP.db.view,entry.recipeID,item) end or nil)
      b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
      if b.settingSlider and type(b.settingSlider.SetScript)=="function" then
        b.settingSlider:SetScript("OnEnter",item and function() CP:ShowCraftTooltip(b,entry.recipeKey or CP.db.view,entry.recipeID,item) end or nil)
        b.settingSlider:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
      end
    end
    if entry.grid then
      gridRow=math.max(gridRow,cardHeight);gridCol=gridCol+1
      if gridCol>=gridCols then offset=offset+gridRow+8;gridCol,gridRow=0,0 end
    else
      offset=offset+cardHeight+1
    end
    b:Show()
    end
  end
  if gridCol>0 then offset=offset+gridRow+8 end
  finishContent(offset+15)
end

-- Recipe list rows ----------------------------------------------------------------------------------------------
local function listRow(i)
  local r=U.listRows[i]
  if r then return r end
  r=CreateFrame("Button",nil,U.listContent,"BackdropTemplate")
  CP:Round(r,true)
  r:SetHeight(38)
  r.stripe=r:CreateTexture(nil,"OVERLAY");r.stripe:SetWidth(2)
  r.stripe:SetPoint("TOPLEFT",r,"TOPLEFT",0,0);r.stripe:SetPoint("BOTTOMLEFT",r,"BOTTOMLEFT",0,0)
  r.stripe:SetColorTexture(.91,.68,.31,1)
  r.dot=r:CreateTexture(nil,"OVERLAY");r.dot:SetSize(8,8);r.dot:SetPoint("TOPLEFT",r,"TOPLEFT",10,-10)
  r.nameLabel=text(r,"GameFontHighlight",24,-5,200,"");r.nameLabel:SetWordWrap(false)
  r.subLabel=text(r,"GameFontDisableSmall",24,-21,200,"");r.subLabel:SetWordWrap(false)
  r.chanceLabel=text(r,"GameFontHighlightSmall",0,-12,54,"");r.chanceLabel:SetJustifyH("RIGHT")
  r.costLabel=text(r,"GameFontHighlightSmall",0,-12,80,"");r.costLabel:SetJustifyH("RIGHT")
  -- Unlearned trainer, vendor or AH recipe: one click to the way there.
  r.go=CreateFrame("Button",nil,r)
  r.go:SetSize(20,20)
  r.go:SetNormalTexture("Interface\\Icons\\INV_Misc_Map_01")
  r.go:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  r.go:SetScript("OnClick",function() if r.craftRecipe and CP.db then CP:GoLearn(CP.db.view,r.craftRecipe.id) end end)
  r.go:SetScript("OnEnter",function()
    if not (r.craftRecipe and CP.db and GameTooltip) then return end
    local target=CP:LearnTarget(CP.db.view,r.craftRecipe.id)
    GameTooltip:SetOwner(r.go,"ANCHOR_RIGHT")
    GameTooltip:SetText(CP:LearnTargetLabel(target) or L("Kein Lernort hinterlegt"))
    if target then
      local where=target.location and target.location.zone and (target.name..", "..target.location.zone) or target.name
      GameTooltip:AddLine(where,1,1,1)
      if target.cost then GameTooltip:AddLine(L("Kosten: ")..CP:FormatCostMoney(target.cost),.8,.8,.8) end
      if target.learnAt then GameTooltip:AddLine(string.format(L("Lernbar ab Skill %d"),target.learnAt),.8,.8,.8) end
    end
    GameTooltip:Show()
  end)
  r.go:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  r:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local h=r:GetHighlightTexture();if h then h:SetVertexColor(.35,.55,.75,.10) end
  r:SetScript("OnClick",function() if r.craftRecipe and CP.db then CP:ActivateRecipeRow(CP.db.view,r.craftRecipe) end end)
  r:SetScript("OnEnter",function() if r.craftRecipe then CP:ShowCraftTooltip(r,CP.db.view,r.craftRecipe.id) end end)
  r:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  U.listRows[i]=r
  return r
end

local function isActive(key,entry,chosen)
  if entry.vendorRecipe then return CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe==entry.id end
  return chosen and entry.id==chosen.id and not (CP.db.ui.selectedVendorKey==key and CP.db.ui.selectedVendorRecipe) or false
end

local function setRecipeList(key,entries,chosen)
  for _,r in ipairs(U.listRows) do r:Hide() end
  local w=(U.listScroll:GetWidth() or 300)
  if type(w)~="number" or w<=0 then w=300 end
  U.listContent:SetWidth(w)
  local active
  for i,entry in ipairs(entries) do
    local r=listRow(i)
    r.craftRecipe=entry
    r:ClearAllPoints();r:SetPoint("TOPLEFT",U.listContent,"TOPLEFT",0,-(i-1)*40);r:SetWidth(w)
    local on=isActive(key,entry,chosen)
    if on then active=entry end
    entry.active=on
    r:SetBackdropColor(on and .16 or 0,on and .18 or 0,on and .22 or 0,on and 1 or 0)
    r:SetBackdropBorderColor(0,0,0,0)
    r.stripe:SetShown(on)
    dot(r.dot,SKILL_COLORS[colorOf(entry)]);r.dot:Show()
    local learnable=(entry.vendorRecipe or entry.trainerRecipe) and not entry.referenceOnly
    r.nameLabel:SetWidth(w-(learnable and 196 or 170));r.subLabel:SetWidth(w-(learnable and 196 or 170))
    r.go:ClearAllPoints();r.go:SetPoint("TOPRIGHT",r,"TOPRIGHT",-150,-9);r.go:SetShown(learnable==true)
    r.nameLabel:SetText(entry.name)
    r.nameLabel:SetTextColor(entry.vendorRecipe and .78 or .93,entry.vendorRecipe and .76 or .92,entry.vendorRecipe and .72 or .88)
    local sub
    if entry.referenceOnly then sub=entry.referenceStatus or ""
    elseif entry.trainerRecipe then sub=L("Lehrerrezept · noch lernen")
    elseif entry.vendorRecipe then sub=L("Kaufrezept · ab ")..(entry.recipeCost and CP:CompactMoney(entry.recipeCost) or L("Preis unbekannt"))
    elseif colorOf(entry)=="grey" then sub=L("gibt keine Punkte mehr")
    elseif (entry.missing or 0)==1 then sub=L("1 Teil fehlt")
    elseif (entry.missing or 0)>1 then sub=string.format(L("%d Teile fehlen"),entry.missing)
    elseif entry.fromStorage then sub=L("vorrätig · erst aus Bank/von Twinks holen")
    else sub=L("alles in der Tasche") end
    r.subLabel:SetText(sub)
    r.chanceLabel:ClearAllPoints();r.chanceLabel:SetPoint("TOPRIGHT",r,"TOPRIGHT",-92,-12)
    r.chanceLabel:SetText((entry.chance or 0)>0 and string.format("%.0f%%",entry.chance*100) or "—")
    r.costLabel:ClearAllPoints();r.costLabel:SetPoint("TOPRIGHT",r,"TOPRIGHT",-8,-12)
    r.costLabel:SetText(CP:ListCostText(entry))
    r:SetAlpha(entry.dimmed and .55 or 1)
    r:Show()
  end
  U.listContent:SetHeight(math.max(40,#entries*40))
  if resetContentScroll and type(U.listScroll.SetVerticalScroll)=="function" then U.listScroll:SetVerticalScroll(0) end
  return active
end

-- Recipe detail (right pane) ----------------------------------------------------------------------------------------
local function detailLabel(name,font)
  local d=U.detail
  if not d[name] then d[name]=U.detailContent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall");d[name]:SetJustifyH("LEFT");d[name]:SetJustifyV("TOP") end
  return d[name]
end
local function detailButton(name,w,h,caption,fn,isPrimary)
  local d=U.detail
  if not d[name] then d[name]=isPrimary and primaryButton(U.detailContent,w,h,caption,fn) or button(U.detailContent,w,h,0,0,caption,fn) end
  return d[name]
end
local function textHeight(node,fallback)
  local n=node:GetStringHeight();return type(n)=="number" and n>0 and n or fallback
end

local function hideDetail()
  for _,v in pairs(U.detail) do if type(v)=="table" and type(v.Hide)=="function" then v:Hide() end end
  for _,r in ipairs(U.detail.matRows or {}) do r:Hide() end
  for _,r in ipairs(U.detail.costRows or {}) do r:Hide() end
  for _,h in ipairs(U.detail.matHeaders or {}) do h:Hide() end
  for _,r in ipairs(U.detail.vendorRows or {}) do r:Hide() end
  for _,p in ipairs(rawget(U.detailContent,"metricPanels") or {}) do p:Hide() end
end

local function renderDetail(key,entry)
  hideDetail()
  local d=U.detail
  local w=(U.detailScroll:GetWidth() or 300)
  if type(w)~="number" or w<=0 then w=300 end
  U.detailContent:SetWidth(w)
  local inner=w-24
  local y=12
  local function put(node,x,height)
    node:ClearAllPoints();node:SetPoint("TOPLEFT",U.detailContent,"TOPLEFT",x or 12,-y);node:Show()
    y=y+(height or textHeight(node,16))
  end
  if not entry then
    local empty=detailLabel("empty","GameFontHighlight")
    empty:SetWidth(inner);empty:SetText(L("Rezept links auswählen."))
    put(empty,12,20)
    local hint=detailLabel("emptyHint","GameFontDisableSmall")
    hint:SetWidth(inner);hint:SetText(L("Berufsfenster öffnen, damit CraftPilot erlernte Rezepte und Skillfarben einliest."))
    put(hint,12)
    U.detailContent:SetHeight(y+12)
    return
  end
  d.entry=entry
  local name=detailLabel("name","GameFontNormalLarge");name:SetWidth(inner)
  name:SetText((entry.trainerRecipe and L("Lehrerrezept: ") or (entry.vendorRecipe and not entry.referenceOnly and L("Kaufrezept: ") or ""))..entry.name)
  put(name,12);y=y+4
  local colorLine=detailLabel("color","GameFontHighlightSmall");colorLine:SetWidth(inner)
  local chance=(entry.chance or 0)>0 and string.format(L(" · Skillchance ca. %.0f%%"),entry.chance*100) or ""
  colorLine:SetText((entry.referenceOnly and (entry.referenceStatus or "") or CP:RecipeColorLabel(key,entry.id))..chance)
  put(colorLine,12);y=y+4
  local rangeLabel=detailLabel("rangeLabel","GameFontDisableSmall");rangeLabel:SetWidth(inner)
  local observed=CP.SkillObservationText and CP:SkillObservationText(key,entry.id)
  rangeLabel:SetText(CP:RecipeRangeText(key,entry.id)..(observed and ("\n|cff8fd6a6"..observed.."|r") or ""))
  put(rangeLabel,12);y=y+12

  if entry.vendorRecipe or entry.referenceOnly then
    local info=detailLabel("learnInfo","GameFontHighlightSmall");info:SetWidth(inner)
    if entry.referenceOnly then
      info:SetText(entry.referenceStatus or "")
    elseif entry.trainerRecipe then
      local c=entry.comparison
      info:SetText(L("Noch nicht erlernt · Lernen einmalig: ")..(c.cost.feeUnknown and L("unbekannt") or gold(c.cost.fee))
        ..(c.cashSaving and c.cashSaving>0 and ("\n"..L("Günstiger inkl. Lernen: ")..gold(c.cashSaving)..L(" / erwartetem Punkt")) or ""))
    else
      info:SetText(L("Noch nicht erlernt · Rezeptpreis ab ")..(entry.recipeCost and gold(entry.recipeCost) or L("unbekannt"))..L(" · Angebot prüfen"))
    end
    put(info,12);y=y+10
    if not entry.referenceOnly then
      local target=CP:LearnTarget(key,entry.id)
      local go=detailButton("goLearn",inner,30,"",function() end,true)
      go:SetText(CP:LearnTargetLabel(target) or L("Kein Lernort hinterlegt"))
      local recipeID=entry.id
      go:SetScript("OnClick",function() CP:GoLearn(key,recipeID) end)
      setPrimaryEnabled(go,target~=nil)
      go:SetWidth(inner);put(go,12,36)
    end
    if entry.vendorRecipe and not entry.referenceOnly and entry.active then
      local comparison=CP:VendorSkillComparison(key,entry)
      local calc=detailButton("calc",inner,40,"",function() end)
      calc:SetText(comparison.crafts..L("x herstellen + Rezept: ")..(comparison.cost.cashComplete and "" or L("Bekannter Teil: "))..CP:FormatCostMoney(comparison.cost.cash))
      local recipeID,crafts=entry.id,comparison.crafts
      calc:SetScript("OnClick",function() CP:OpenCostCalculation("recipe",key,recipeID,crafts) end)
      calc:SetWidth(inner);put(calc,12,46)
    end
    d.vendorRows=d.vendorRows or {}
    for i,vendor in ipairs(entry.vendors or {}) do
      local row=d.vendorRows[i]
      if not row then
        row=CP:CreateFlatAction(U.detailContent,inner,50,function() end)
        row.nameLabel=text(row,"GameFontHighlightSmall",10,-6,inner-20,"")
        row.infoLabel=text(row,"GameFontDisableSmall",10,-24,inner-20,"")
        row:SetScript("OnClick",function() if row.vendorTarget then CP:SetWaypoint(row.vendorTarget) end end)
        d.vendorRows[i]=row
      end
      row.vendorTarget=vendor.location
      row:SetEnabled(vendor.location~=nil)
      local place=vendor.location and string.format("%s %.1f / %.1f",vendor.location.zone,vendor.location.x*100,vendor.location.y*100) or L("Standort unbekannt")
      row.nameLabel:SetWidth(inner-20);row.infoLabel:SetWidth(inner-20)
      row.nameLabel:SetText(vendor.name.." · "..place)
      row.infoLabel:SetText(CP:VendorOfferPrice(vendor).." · "..L("Klick: Wegpunkt")..(CP:VendorOfferNotes(vendor)~="" and ("\n"..CP:VendorOfferNotes(vendor)) or ""))
      local h=math.max(46,28+textHeight(row.infoLabel,14)+6)
      row:SetSize(inner,h)
      put(row,12,h+4)
    end
    U.detailContent:SetHeight(y+12)
    return
  end

  -- Learned recipe: quantity, materials, actions, cost details.
  local qty=CP:RequestedRecipeQuantity(key,entry.id)
  local advice=CP:CraftSuggestion(key,entry.id)
  local qtyBox=d.qtyBox or panel(U.detailContent,"raised");d.qtyBox=qtyBox
  local qtyHint=d.qtyHint or text(qtyBox,"GameFontHighlightSmall",10,-8,inner-20,"");d.qtyHint=qtyHint
  qtyHint:SetWidth(inner-20)
  qtyHint:SetText((advice.forward and L("Für Folgeschritte eingeplant · ") or "")..(advice.target>((CP.db.professions[key] or {}).skill or 0)
    and string.format(L("Vorschlag: ca. %d× bis Skill %d"),advice.count,advice.target) or L("Menge frei wählen")))
  local qtyInput=d.qtyInput
  if not qtyInput then
    qtyInput=CreateFrame("EditBox",nil,qtyBox,"InputBoxTemplate");qtyInput:SetSize(46,22);qtyInput:SetAutoFocus(false);qtyInput:SetNumeric(true)
    qtyInput:SetScript("OnEditFocusLost",function(box)
      local n=tonumber(box:GetText());local k,r=box.recipeKey,box.recipeID
      if n and n==CP:RecipeQuantityOverride(k,r) then return end
      if CP:SetRecipeQuantity(k,r,n or -1) then CP:Render() else box:SetText(tostring(CP:RequestedRecipeQuantity(k,r)));CP:Say(L("Menge 1–9999 eingeben.")) end
    end)
    qtyInput:SetScript("OnEnterPressed",function(box) box:ClearFocus() end)
    qtyInput:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    d.qtyInput=qtyInput
    d.qtyMinus=button(qtyBox,24,22,0,0,"-",function()
      local e=U.detail.entry;if not e then return end
      CP:SetRecipeQuantity(CP.db.view,e.id,math.max(1,CP:RequestedRecipeQuantity(CP.db.view,e.id)-1));CP:Render()
    end)
    d.qtyPlus=button(qtyBox,24,22,0,0,"+",function()
      local e=U.detail.entry;if not e then return end
      CP:SetRecipeQuantity(CP.db.view,e.id,CP:RequestedRecipeQuantity(CP.db.view,e.id)+1);CP:Render()
    end)
    d.qtyReset=button(qtyBox,90,20,0,0,L("Vorschlag"),function()
      local e=U.detail.entry;if not e then return end
      CP:SetRecipeQuantity(CP.db.view,e.id,nil);CP:Render()
    end)
  end
  qtyInput.recipeKey=key;qtyInput.recipeID=entry.id
  if not qtyInput:HasFocus() then qtyInput:SetText(tostring(qty)) end
  local hintHeight=textHeight(qtyHint,14)
  qtyBox:SetSize(inner,hintHeight+44)
  local row=-(hintHeight+14)
  d.qtyMinus:ClearAllPoints();d.qtyMinus:SetPoint("TOPLEFT",qtyBox,"TOPLEFT",10,row)
  qtyInput:ClearAllPoints();qtyInput:SetPoint("TOPLEFT",qtyBox,"TOPLEFT",44,row)
  d.qtyPlus:ClearAllPoints();d.qtyPlus:SetPoint("TOPLEFT",qtyBox,"TOPLEFT",96,row)
  d.qtyReset:ClearAllPoints();d.qtyReset:SetPoint("TOPRIGHT",qtyBox,"TOPRIGHT",-10,row)
  for _,c in ipairs({qtyHint,qtyInput,d.qtyMinus,d.qtyPlus,d.qtyReset}) do c:Show() end
  put(qtyBox,12,hintHeight+52)

  local cost=CP:CostCalculation("recipe",key,entry.id,qty)
  local cols={{L("Material"),.46,"LEFT"},{L("Bedarf"),.18,"RIGHT"},{L("Vorrat"),.18,"RIGHT"},{L("Kaufen"),.18,"RIGHT"}}
  d.matHeaders=d.matHeaders or {}
  local x=12
  for i,c in ipairs(cols) do
    local h=d.matHeaders[i] or U.detailContent:CreateFontString(nil,"OVERLAY","GameFontDisableSmall");d.matHeaders[i]=h
    h:ClearAllPoints();h:SetPoint("TOPLEFT",U.detailContent,"TOPLEFT",x,-y);h:SetWidth(inner*c[2]-6);h:SetJustifyH(c[3]);h:SetText(c[1]);h:Show()
    x=x+inner*c[2]
  end
  y=y+18
  d.matRows=d.matRows or {}
  for i,mat in ipairs(cost.materials) do
    local row=d.matRows[i]
    if not row then
      row=CreateFrame("Button",nil,U.detailContent);row:SetHeight(22);row.cells={}
      row.line=row:CreateTexture(nil,"ARTWORK");row.line:SetHeight(1);row.line:SetPoint("TOPLEFT",row,"TOPLEFT",0,0);row.line:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
      row.line:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
      for j=1,4 do row.cells[j]=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall") end
      row:SetScript("OnEnter",function() if row.itemID and GameTooltip then GameTooltip:SetOwner(row,"ANCHOR_RIGHT");if type(GameTooltip.SetItemByID)=="function" then pcall(GameTooltip.SetItemByID,GameTooltip,row.itemID) end;GameTooltip:Show() end end)
      row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
      d.matRows[i]=row
    end
    row.itemID=mat.id
    local values={CP:ItemName(mat.id),mat.quantity,mat.bag+(mat.bankKnown and mat.bank or 0)+CP:AltReachable(mat.id),mat.missing}
    x=0
    for j,c in ipairs(cols) do
      local cell=row.cells[j];cell:ClearAllPoints();cell:SetPoint("TOPLEFT",row,"TOPLEFT",x,-5);cell:SetWidth(inner*c[2]-6);cell:SetJustifyH(c[3]);cell:SetWordWrap(false)
      cell:SetText(tostring(values[j]))
      cell:SetTextColor(1,1,1)
      if j==4 then cell:SetTextColor(mat.missing>0 and .94 or .44,mat.missing>0 and .70 or .75,mat.missing>0 and .35 or .54) end
      x=x+inner*c[2]
    end
    row:SetWidth(inner)
    put(row,12,22)
  end
  if #cost.materials==0 then
    local none=detailLabel("noMats","GameFontDisableSmall");none:SetWidth(inner);none:SetText(L("Materialien unbekannt · Berufsfenster aktualisieren."))
    put(none,12)
  end
  y=y+8
  local pickups={}
  for _,mat in ipairs(cost.materials) do
    if (mat.alts or 0)>0 then pickups[#pickups+1]=CP:AltPickupText(mat.id,mat.alts) end
  end
  if #pickups>0 then
    local pickup=detailLabel("altPickup","GameFontHighlightSmall");pickup:SetWidth(inner)
    pickup:SetText("|cff8fd6a6"..L("Von Twinks holen: ")..RESET..table.concat(pickups,", "))
    put(pickup,12);y=y+8
  end
  -- Raw materials one step back: ore for missing bars, cloth for bolts, ...
  local raw=CP.RawMaterialHints and CP:RawMaterialHints(cost.materials,3) or {}
  if #raw>0 then
    local rawLine=detailLabel("rawHint","GameFontHighlightSmall");rawLine:SetWidth(inner)
    rawLine:SetText("|cff8fd6a6"..L("Selbst herstellen: ")..RESET..table.concat(raw,"\n"))
    put(rawLine,12);y=y+8
  end
  -- Made for a later step: say clearly to keep it (or that enough is already there).
  local output=CP:RecipeMarketOutput(key,entry.id)
  local keep=output and CP:KeepEntry(key,output)
  if keep then
    local keepLine=detailLabel("keepLine","GameFontHighlightSmall");keepLine:SetWidth(inner)
    keepLine:SetText((keep.enough and "|cff8fd6a6" or "|cffffd200")..CP:KeepText(keep)..RESET)
    put(keepLine,12);y=y+8
  end
  if advice.nextStep and advice.nextStep.id then
    local nextLine=detailLabel("nextStep","GameFontDisableSmall");nextLine:SetWidth(inner)
    nextLine:SetText(L("Danach: ")..CP:RecipeName(key,advice.nextStep.id)..L(" ab Skill ")..tostring(advice.nextStep.skill or "?"))
    put(nextLine,12);y=y+8
  end
  y=y+2

  local openNative=detailButton("open",160,32,L("Berufsfenster öffnen"),function()
    local e=U.detail.entry;if e then CP:OpenLearnedRecipe(CP.db.view,e.id) end
  end,true)
  local addList=detailButton("addList",160,32,L("Auf Einkaufsliste"),function()
    local e=U.detail.entry;if not e then return end
    CP:AddCostDeficits({kind="recipe",key=CP.db.view,id=e.id,quantity=CP:RequestedRecipeQuantity(CP.db.view,e.id)})
    CP:Render()
  end)
  local half=(inner-8)/2
  openNative:SetWidth(half);addList:SetWidth(half)
  openNative:ClearAllPoints();openNative:SetPoint("TOPLEFT",U.detailContent,"TOPLEFT",12,-y);openNative:Show()
  addList:ClearAllPoints();addList:SetPoint("TOPLEFT",U.detailContent,"TOPLEFT",20+half,-y);addList:Show()
  y=y+42

  local open=CP.db.ui.detailsOpen==true
  local toggle=detailButton("detailsToggle",inner,22,"",function() CP.db.ui.detailsOpen=not CP.db.ui.detailsOpen;CP:Render() end)
  toggle:SetText((open and COLLAPSE or EXPAND)..L("Kosten-Details"))
  toggle:SetWidth(inner);put(toggle,12,28)
  if open then
    local data=CP:RecipeDisplayData(key,entry.id)
    -- Label left, amount right: readable in the narrow detail pane (the three-box strip wrapped).
    local costRows={
      {string.format(L("Zukauf für %d×"),qty),(data.cost.missingBuy==0 and data.cost.unknownRecipes==0) and CP:DisplayMoney(data.cost.buy) or L("unvollständig"),{1,.84,.46}},
    }
    -- What the crafts bring back: the vendor's price is certain, an AH sale only possible, so it is never
    -- counted in costs. Both for the whole quantity.
    local recipe=(CP:RecipeVendorCatalog(key) or {recipes={}}).recipes[entry.id]
    local native=(CP.db.recipes[key] or {})[entry.id]
    local made=qty*math.max(1,(native and native.outputMin) or (recipe and (recipe.count or recipe.yield)) or 1)
    local vendor=data.market and data.market.vendor
    local net=data.market and not data.market.bound and data.market.net
    costRows[#costRows+1]={string.format(L("Händler zahlt sicher (%d×)"),made),vendor and CP:DisplayMoney(vendor*made) or "—",{.91,.90,.87}}
    costRows[#costRows+1]={string.format(L("AH vielleicht (%d×, nicht eingerechnet)"),made),net and CP:DisplayMoney(net*made) or "—",{.55,.9,.7}}
    d.costRows=d.costRows or {}
    for i,row in ipairs(costRows) do
      local line=d.costRows[i]
      if not line then
        line=CreateFrame("Frame",nil,U.detailContent);line:SetHeight(22)
        line.label=line:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");line.label:SetPoint("LEFT",line,"LEFT",0,0);line.label:SetJustifyH("LEFT")
        line.value=line:CreateFontString(nil,"OVERLAY","GameFontHighlight");line.value:SetPoint("RIGHT",line,"RIGHT",0,0);line.value:SetJustifyH("RIGHT")
        line.sep=line:CreateTexture(nil,"ARTWORK");line.sep:SetHeight(1);line.sep:SetPoint("BOTTOMLEFT",line,"BOTTOMLEFT",0,0);line.sep:SetPoint("BOTTOMRIGHT",line,"BOTTOMRIGHT",0,0)
        line.sep:SetColorTexture(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
        d.costRows[i]=line
      end
      line:SetWidth(inner);line.label:SetWidth(inner*.64);line.value:SetWidth(inner*.36)
      line.label:SetText(row[1]);line.value:SetText(row[2]);line.value:SetTextColor(row[3][1],row[3][2],row[3][3])
      put(line,12,24)
    end
    y=y+6
    local stock=detailLabel("stock","GameFontDisableSmall");stock:SetWidth(inner)
    stock:SetText(string.format(L("Vorrat genutzt: Tasche %d · Bank %s · Zukauf %d"),data.bag,not CP.db.includeBank and L("aus") or (data.bankUnknown and "?" or tostring(data.bank)),data.buy))
    put(stock,12);y=y+8
    local notes={}
    for _,n in ipairs(CP:FollowupNeeds(key,entry.id,qty,advice)) do
      notes[#notes+1]=n.short>0 and string.format(L("%s: Folgeschritt braucht ca. %d · zusätzlich einplanen %d"),CP:ItemName(n.id),n.next,n.short)
        or string.format(L("%s: Folgeschritt braucht ca. %d · Vorrat reicht"),CP:ItemName(n.id),n.next)
    end
    if #notes>0 then
      local follow=detailLabel("follow","GameFontHighlightSmall");follow:SetWidth(inner);follow:SetText(table.concat(notes,"\n"))
      put(follow,12);y=y+8
    end
    local calc=detailButton("costCalc",(inner-8)/2,26,L("Kostenkalkulation"),function()
      local e=U.detail.entry;if e then CP:OpenCostCalculation("recipe",CP.db.view,e.id,CP:RequestedRecipeQuantity(CP.db.view,e.id)) end
    end)
    local eco=detailButton("economy",(inner-8)/2,26,L("Clever skillen"),function() CP:OpenTab("economy") end)
    calc:SetWidth((inner-8)/2);eco:SetWidth((inner-8)/2)
    calc:ClearAllPoints();calc:SetPoint("TOPLEFT",U.detailContent,"TOPLEFT",12,-y);calc:Show()
    eco:ClearAllPoints();eco:SetPoint("TOPLEFT",U.detailContent,"TOPLEFT",20+(inner-8)/2,-y);eco:Show()
    y=y+34
    local note=detailLabel("note","GameFontDisableSmall");note:SetWidth(inner)
    note:SetText(L("Preise sind gespeicherte AH-Scans, keine Live-Angebote."))
    put(note,12)
  end
  U.detailContent:SetHeight(y+12)
  if resetContentScroll and type(U.detailScroll.SetVerticalScroll)=="function" then U.detailScroll:SetVerticalScroll(0) end
end

-- Theme -----------------------------------------------------------------------------------------------------------
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
    -- The sidebar hangs outside the window: it needs the opaque window style, not the see-through inner panel.
    useSkin(S,"Shell",U.side)
    useSkin(S,"Panel",U.listPanel)
    useSkin(S,"Panel",U.detailPanel)
    useSkin(S,"CloseButton",U.close)
    for _,b in ipairs(U.buttons) do useSkin(S,"Button",b) end
    for _,s in ipairs({U.scroll,U.listScroll,U.detailScroll}) do if s.ScrollBar then useSkin(S,"ScrollBar",s.ScrollBar) end end
    useSkin(S,"ApplyBarFill",U.skillBar)
    if CP.db then CP:ApplyTheme() end
  end)
end

local function paint(f,c,alpha)
  if f and type(f.SetBackdropColor)=="function" then
    f:SetBackdropColor(c[1],c[2],c[3],alpha or 1)
    f:SetBackdropBorderColor(PALETTE.border[1],PALETTE.border[2],PALETTE.border[3],1)
  end
end

function CP:ApplyTheme()
  if not self.db then return end
  -- A skin may reset the strata; keep the window above unit frames and action bars.
  -- Only when needed and never in combat (ADDON_ACTION_BLOCKED if the window counts as protected).
  if type(frame.SetFrameStrata)=="function" and not inCombat()
    and not (type(frame.GetFrameStrata)=="function" and frame:GetFrameStrata()=="HIGH") then frame:SetFrameStrata("HIGH") end
  local pref=self.db.ui.skin or "auto"
  local hasEUI=pref=="auto" and type(self.ellesmereSkin)=="table"
  if pref=="classic" then
    PALETTE.window={.16,.115,.07};PALETTE.panel={.20,.145,.085};PALETTE.raised={.24,.175,.10};PALETTE.border={.45,.33,.19}
  else
    PALETTE.window={.078,.090,.110};PALETTE.panel={.098,.114,.137};PALETTE.raised={.122,.141,.172};PALETTE.border={.17,.196,.227}
  end
  local sideColor={PALETTE.window[1]*.8,PALETTE.window[2]*.8,PALETTE.window[3]*.8}
  if U.sideBacking and type(U.sideBacking.SetColorTexture)=="function" then
    U.sideBacking:SetColorTexture(sideColor[1],sideColor[2],sideColor[3],1)
  end
  -- Leave Ellesmere surfaces alone in Auto; it manages its own theme.
  if not hasEUI then
    paint(frame,PALETTE.window,1)
    paint(U.side,sideColor,1)
    if type(header.SetBackdrop)=="function" then header:SetBackdrop(nil) end
    paint(U.listPanel,PALETTE.panel)
    paint(U.detailPanel,PALETTE.panel)
    paint(U.profMenu,PALETTE.raised)
    paint(U.filterMenu,PALETTE.raised)
  end
end

-- Window position ---------------------------------------------------------------------------------------------------
local restored=false
function CP:RestoreWindowPosition()
  if restored or not self.db then return end
  restored=true
  local w=math.max(750,math.min(1100,self.db.ui.width or W))
  local h=math.max(570,math.min(930,self.db.ui.height or H))
  frame:SetSize(w,h)
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
  local w=type(frame.GetWidth)=="function" and frame:GetWidth()
  local h=type(frame.GetHeight)=="function" and frame:GetHeight()
  if type(w)=="number" then self.db.ui.width=math.max(750,math.min(1100,w)) end
  if type(h)=="number" then self.db.ui.height=math.max(570,math.min(930,h)) end
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

-- Static layout (depends on window size only) -----------------------------------------------------------------------
local function layout()
  local w=width()
  local h=type(frame.GetHeight)=="function" and frame:GetHeight() or H
  if type(h)~="number" then h=H end
  local inner=w-36
  U.title:ClearAllPoints();U.title:SetPoint("LEFT",header,"LEFT",50,0)
  U.profButton:ClearAllPoints();U.profButton:SetPoint("LEFT",header,"LEFT",14,0)
  U.profMenu:ClearAllPoints();U.profMenu:SetPoint("TOPLEFT",U.profButton,"BOTTOMLEFT",0,-4)
  U.close:ClearAllPoints();U.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-12)
  U.gear:ClearAllPoints();U.gear:SetPoint("RIGHT",header,"RIGHT",-44,0)
  U.help:ClearAllPoints();U.help:SetPoint("RIGHT",U.gear,"LEFT",-6,0)
  U.priceChip:ClearAllPoints();U.priceChip:SetPoint("RIGHT",U.help,"LEFT",-10,0)
  U.skillText:ClearAllPoints();U.skillText:SetPoint("RIGHT",U.priceChip,"LEFT",-10,0)
  U.skillBar:ClearAllPoints();U.skillBar:SetPoint("LEFT",U.profButton,"RIGHT",14,0);U.skillBar:SetPoint("RIGHT",U.skillText,"LEFT",-8,0)
  U.skillHover:ClearAllPoints();U.skillHover:SetPoint("TOPLEFT",U.skillBar,"TOPLEFT",0,10);U.skillHover:SetPoint("BOTTOMRIGHT",U.skillText,"BOTTOMRIGHT",0,-10)
  -- 0.2.3: brand, profession and skill in the sidebar; page title and status fields in the header.
  if U.title then U.title:Hide() end
  if brandFrame then brandFrame:Hide() end
  header:SetHeight(92)
  U.profButton:ClearAllPoints();U.profButton:SetPoint("TOPLEFT",side,"TOPLEFT",8,-54);U.profButton:SetSize(SIDE-16,30)
  U.profMenu:ClearAllPoints();U.profMenu:SetPoint("TOPLEFT",U.profButton,"TOPRIGHT",6,0)
  if type(U.profMenu.SetFrameLevel)=="function" and type(side.GetFrameLevel)=="function" then
    local level=side:GetFrameLevel();if type(level)=="number" then U.profMenu:SetFrameLevel(level+30) end
  end
  U.skillBar:ClearAllPoints();U.skillBar:SetPoint("TOPLEFT",side,"TOPLEFT",12,-92);U.skillBar:SetPoint("TOPRIGHT",side,"TOPRIGHT",-12,-92)
  U.skillText:ClearAllPoints();U.skillText:SetPoint("TOPRIGHT",side,"TOPRIGHT",-12,-100);U.skillText:SetWidth(SIDE-24)
  U.skillHover:ClearAllPoints();U.skillHover:SetPoint("TOPLEFT",U.skillBar,"TOPLEFT",0,6);U.skillHover:SetPoint("BOTTOMRIGHT",U.skillText,"BOTTOMRIGHT",0,-2)
  U.priceChip:ClearAllPoints();U.priceChip:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-48,-30)
  U.reservedChip:ClearAllPoints();U.reservedChip:SetPoint("RIGHT",U.priceChip,"LEFT",-8,0)
  U.pageTitle:ClearAllPoints();U.pageTitle:SetPoint("TOPLEFT",frame,"TOPLEFT",19,-26)
  U.pageSub:ClearAllPoints();U.pageSub:SetPoint("TOPLEFT",frame,"TOPLEFT",19,-50)
  U.pageTitle:SetWidth(inner-290);U.pageSub:SetWidth(inner-60)
  for i,b in ipairs(U.endgameButtons) do b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(i-1)*134,-104) end
  for i,b in ipairs(U.itemButtons) do b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(i-1)*134,-104) end
  U.itemSearch:ClearAllPoints();U.itemSearch:SetPoint("TOPLEFT",frame,"TOPLEFT",432,-105)
  U.itemResults:ClearAllPoints();U.itemResults:SetPoint("TOPLEFT",frame,"TOPLEFT",704,-104)
  U.tabLine:ClearAllPoints();U.tabLine:SetPoint("TOPLEFT",frame,"TOPLEFT",1,-94);U.tabLine:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-1,-94)
  U.back:ClearAllPoints();U.back:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-18,-62)
  U.footerLine:ClearAllPoints();U.footerLine:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",1,32);U.footerLine:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,32)
  U.footer:ClearAllPoints();U.footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",18,12);U.footer:SetWidth(inner-140)
  U.report:ClearAllPoints();U.report:SetPoint("LEFT",U.footer,"RIGHT",10,0)
  U.section:SetWidth(inner)
  content:SetWidth(inner-26)
  for _,r in ipairs(U.rows) do if type(r.SetWidth)=="function" then r:SetWidth(inner-36) end end
end
-- Re-render once after resizing settles instead of on every size step.
local resizeToken=0
frame:SetScript("OnSizeChanged",function()
  layout()
  if not (CP.db and frame:IsShown()) then return end
  resizeToken=resizeToken+1
  local token=resizeToken
  if C_Timer and type(C_Timer.After)=="function" then
    C_Timer.After(.15,function() if token==resizeToken and frame:IsShown() then CP:Render() end end)
  end
end)
layout()
registerEllesmereUI()

-- Navigation ----------------------------------------------------------------------------------------------------
local MAIN={now=true,plan=true,trainers=true,camping=true,twinks=true,endgame=true,items=true}
function CP:OpenTab(tab)
  if not self.db then return end
  local alias={stages="plan",mats="now",after300="endgame"}
  tab=alias[tab] or tab
  local valid={now=true,plan=true,trainers=true,camping=true,twinks=true,endgame=true,items=true,economy=true,audit=true,reservations=true,settings=true,help=true}
  if not valid[tab] then return end
  if MAIN[tab] then self.db.ui.lastMainTab=tab end
  self.db.ui.tab=tab
  if U.profMenu then U.profMenu:Hide();U.filterMenu:Hide() end
  frame:Show()
  self:Render()
end

function CP:ToggleSettings()
  if not self.db then return end
  if self.db.ui.tab=="settings" then self:OpenTab(self.db.ui.lastMainTab or "now") else self:OpenTab("settings") end
end

function CP:RenderProfessionMenu()
  local key=self.db.view
  local own,others={},{}
  for _,k in ipairs(D.order) do
    if self:OwnsProfession(k) then own[#own+1]=k else others[#others+1]=k end
  end
  local byKey={}
  for _,item in ipairs(U.profItems) do byKey[item.professionKey]=item;item:Hide() end
  local y=8
  U.profMenu.ownLabel:ClearAllPoints();U.profMenu.ownLabel:SetPoint("TOPLEFT",U.profMenu,"TOPLEFT",10,-y);U.profMenu.ownLabel:SetShown(#own>0)
  if #own>0 then y=y+18 end
  local function add(k,owned)
    local item=byKey[k]
    local record=self.db.professions[k]
    item:ClearAllPoints();item:SetPoint("TOPLEFT",U.profMenu,"TOPLEFT",8,-y)
    item:SetText((owned and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t " or "").."|T"..D.professionIcons[k]..":14|t "..D.professions[k].name
      ..(owned and record and ("  "..MUTED..record.skill.."/"..record.cap..RESET) or ""))
    item.selectionMarker:SetShown(k==key)
    item:Show()
    y=y+28
  end
  for _,k in ipairs(own) do add(k,true) end
  U.profMenu.otherLabel:ClearAllPoints();U.profMenu.otherLabel:SetPoint("TOPLEFT",U.profMenu,"TOPLEFT",10,-(y+4));U.profMenu.otherLabel:SetShown(#others>0)
  if #others>0 then y=y+22 end
  for _,k in ipairs(others) do add(k,false) end
  U.profMenu:SetHeight(y+8)
  -- Owned crafting professions open the game window through a secure spell button on top.
  if inCombat() then return end
  for i,item in ipairs(U.profItems) do
    local k=item.professionKey
    local spell=self.db.ui.autoOpen~=false and self:OwnsProfession(k) and item:IsShown() and self:ProfessionSpellName(k)
    local s=secureButton(i)
    if spell then
      s:SetAttribute("spell",spell)
      s.castSpell=spell
      s.professionKey=k
      s:ClearAllPoints();s:SetPoint("TOPLEFT",item,"TOPLEFT",0,0);s:SetPoint("BOTTOMRIGHT",item,"BOTTOMRIGHT",0,0)
      s:Show()
    else
      s.castSpell=nil
      s:Hide()
    end
  end
end

-- Render ----------------------------------------------------------------------------------------------------------
local function hideAll()
  for _,c in ipairs(U.plan.controls) do c:Hide() end
  for _,c in ipairs(U.trainer.controls) do c:Hide() end
  for _,c in ipairs(U.merchant.controls) do c:Hide() end
  for _,c in ipairs(U.camp) do c:Hide() end
  for _,b in ipairs(U.stageButtons) do b:Hide() end
  U.campFilter:Hide();U.settingsTitle:Hide();U.settingsDone:Hide();U.back:Hide()
  U.listPanel:Hide();U.detailPanel:Hide();U.contentPanel:Hide();U.section:Hide();U.rec:Hide();U.budget:Hide()
  for _,bg in pairs(U.segBg) do bg:Hide() end
end

local function showContent(top,bottom)
  U.contentPanel:ClearAllPoints()
  U.contentPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-top)
  U.contentPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-12,bottom or 42)
  U.contentPanel:Show()
end

local function renderHeader(self,key,prof,record)
  local skill=record and record.skill or 0
  local cap=record and record.cap or 0
  local owned=self:OwnsProfession(key)
  U.profButton:SetText((owned and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t " or "").."|T"..D.professionIcons[key]..":16|t "..prof.name.."  "..ARROW_DOWN)
  if type(U.skillBar.SetMinMaxValues)=="function" then U.skillBar:SetMinMaxValues(0,math.max(75,cap>0 and cap or 300)) end
  if type(U.skillBar.SetValue)=="function" then U.skillBar:SetValue(math.max(0,skill)) end
  U.skillText:SetText(record and (skill.." / "..cap) or L("nicht eingelesen"))
  local nextRank=self:NextRank(key)
  U.skillTitle=prof.name..(record and ("  "..skill.." / "..cap) or "")
  if nextRank then
    local playerLevel=type(UnitLevel)=="function" and UnitLevel("player") or 0
    local needLevel=self:RankCharacterLevel(key,nextRank)
    local notices={}
    if skill<nextRank.min then notices[#notices+1]=L("ab Berufsskill ")..nextRank.min end
    if playerLevel<needLevel then notices[#notices+1]=L("Charakterstufe ")..needLevel..L(" erforderlich") end
    U.rankText=L("Nächster Rang: ")..nextRank.name..L(" bis ")..nextRank.cap..(#notices>0 and (" ("..table.concat(notices,", ")..")") or "")
  else
    U.rankText=prof.ranksUnverified and L("Ausbildungsanforderungen bitte im Spiel prüfen")
      or record and L("Höchster Ausbildungsrang erreicht")
      or L("Berufsfenster oder Berufeübersicht öffnen, um Daten einzulesen")
  end
  U.skillLines={U.rankText}
  local priceStatus,priceState=self:ProfessionPriceStatus(key)
  U.priceDetail=priceStatus
  U.bankDetail=self:BankStatus()
  local fresh=priceState=="fresh"
  U.priceDot:SetColorTexture(fresh and .30 or .95,fresh and .77 or .70,fresh and .48 or .30,1)
  U.priceText:SetText(fresh and L("AH aktuell") or (priceState=="unknown" and L("AH ohne Scan") or L("AH prüfen")))
  if type(U.priceChip.SetBackdropColor)=="function" then
    U.priceChip:SetBackdropColor(fresh and .10 or .16,fresh and .16 or .14,fresh and .13 or .09,1)
    U.priceChip:SetBackdropBorderColor(0,0,0,0)
  end
  -- 0.2.2: settings and help live in the sidebar.
  U.gear:Hide();U.help:Hide()
  U.profButton:Show();U.priceChip:Show()
  local reserved=0
  for _ in pairs(self.ReservedItems and self:ReservedItems() or {}) do reserved=reserved+1 end
  U.reservedText:SetText(string.format(L("%d Gegenstände reserviert"),reserved))
  U.reservedChip:SetBackdropColor(PALETTE.raised[1],PALETTE.raised[2],PALETTE.raised[3],1)
  U.reservedChip:SetShown(reserved>0)
end

-- 0.2.2: sidebar navigation, page title and subtitle.
local PAGE_SUB={
  now=L("Empfehlung und Rezepte für deinen nächsten Skillschritt"),
  plan=L("Skillbereich planen, Einkaufsliste und Herstellungsschritte"),
  trainers=L("Lehrer, Händlerrezepte, Lerntour und Spezialisierung"),
  camping=L("Lagerfeuer, Buffs und Camp-Objekte aller Berufe"),
  twinks=L("Bestände, Cooldowns und Hersteller deiner Charaktere"),
  items=L("Wofür ein Gegenstand gebraucht wird, wer ihn herstellt und was du jetzt bauen kannst"),
  help=L("So funktioniert CraftPilot"),
}
local ENDGAME_SUB={
  profit=L("Was deine erlernten Rezepte einbringen · eigene Materialien zählen mit ihrem Verkaufswert"),
  stock=L("Tränke, Fläschchen und Essen für den Raid · reserviert und gegen Verkauf geschützt"),
  wish=L("Rezepte, die dir fehlen, und woher sie kommen"),
  favor=L("Rezepte für Merchant's Favor und wann sie sich bezahlt machen"),
}
local function navState(b,on)
  if b.bg and type(b.bg.SetColorTexture)=="function" then
    if on then b.bg:SetColorTexture(PALETTE.raised[1],PALETTE.raised[2],PALETTE.raised[3],1) else b.bg:SetColorTexture(1,1,1,0) end
  end
  b.iconBox:SetShown(on)
  if b.label and type(b.label.SetTextColor)=="function" then
    if on then b.label:SetTextColor(.95,.94,.91) else b.label:SetTextColor(.72,.74,.76) end
  end
end
local function renderTabs(self,tab)
  local mainTab=MAIN[tab] and tab or nil
  local alarms=self.AuctionAlarms and #self:AuctionAlarms() or 0
  for i,b in ipairs(U.tabButtons) do
    local key=U.tabs[i].key
    navState(b,key==mainTab)
    b:SetText(U.tabs[i].label)
    b.badge:SetText(key=="endgame" and alarms>0 and tostring(alarms) or "")
    b:Show()
  end
  navState(U.sideSettings,tab=="settings")
  navState(U.sideHelp,tab=="help")
  U.side:Show()
  for _,b in ipairs(U.endgameButtons) do b:Hide() end
  for _,b in ipairs(U.itemButtons) do b:Hide() end
  U.itemSearch:Hide();U.itemResults:Hide()
  local titles={items=L("Gegenstände"),now=L("Jetzt"),plan=L("Plan & Einkauf"),trainers=L("Lehrer & Händler"),camping=L("Camping"),twinks=L("Twinks"),
    endgame=L("Endgame"),help=L("Hilfe"),economy=L("Clever skillen"),audit=L("Berufsdaten"),reservations=L("Vorratsreservierung")}
  local sub=PAGE_SUB[tab]
  if tab=="endgame" then sub=ENDGAME_SUB[self.db.ui.endgamePage or "profit"] or ENDGAME_SUB.profit end
  U.pageTitle:SetText(titles[tab] or "");U.pageSub:SetText(sub or "")
  U.pageTitle:SetShown(tab~="settings");U.pageSub:SetShown(tab~="settings")
  local status=self.ProfessionPriceStatus and select(2,self:ProfessionPriceStatus(self.db.view))
  U.sideFoot:SetText("CraftPilot "..tostring(self.version or ""))
end

local function recipeEntries(self,key,chosen,options,current)
  local ui=self.db.ui
  local offers=self:VendorRecipeOptions(key)
  for _,entry in ipairs(self:TrainerOffersCached(key)) do offers[#offers+1]=entry end
  if ui.allRecipes then return self:AllRecipeOptions(key,options,offers),"all" end
  if ui.vendorOnly then return offers,"unlearned" end
  local overview={}
  for _,entry in ipairs(offers) do if entry.trainerRecipe and entry.comparison.cashSaving and entry.comparison.cashSaving>0 then overview[#overview+1]=entry end end
  if current then for _,entry in ipairs(options) do overview[#overview+1]=entry end end
  for _,entry in ipairs(offers) do if not (entry.trainerRecipe and entry.comparison.cashSaving and entry.comparison.cashSaving>0) then overview[#overview+1]=entry end end
  return overview,"useful"
end

local function renderNow(self,key,prof,record,inner)
  local gatheringOnly=prof.gathering and not prof.crafting
  if gatheringOnly then
    showContent(108)
    local skill=record and record.skill or 0
    local current=self:CurrentStage(key)
    setVisualCards({
      {title=GOLD..L("AKTUELL")..RESET.."  ·  Skill "..skill,
        detail=current and current[3] or L("Für diesen Beruf ist noch keine geprüfte Sammelroute hinterlegt."),
        footer=L("Unter Plan & Einkauf stehen die nächsten Sammelgebiete."),
        icon=key=="herbalism" and "Interface\\Icons\\INV_Misc_Herb_07" or "Interface\\Icons\\INV_Ore_Copper_01",color="gold"},
      {title=L("Sammelweg statt Rezeptmenge"),
        detail=L("Sammeln ergibt keine feste Menge für garantierte Skillpunkte."),
        footer=L("Deshalb erstellt CraftPilot hier keine künstliche Zutaten-Einkaufsliste."),
        icon="Interface\\Icons\\INV_Misc_Map_01",color="blue"}})
    return
  end
  local h=type(frame.GetHeight)=="function" and frame:GetHeight() or H
  local leftW=math.floor((inner-12)*.53)
  local rightW=inner-12-leftW
  local top=106
  local recHeight=CP:RenderRecommendation(key,inner)
  if recHeight then top=top+recHeight+8 end
  local budgetLine=CP:BudgetLine(key,CP.currentRecommendation)
  if budgetLine then
    U.budget:ClearAllPoints();U.budget:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-top);U.budget:SetSize(inner,28);U.budget:Show()
    U.budget.text:SetWidth(inner-180);U.budget.text:SetText(budgetLine.text)
    U.budget.action:SetText(budgetLine.action)
    top=top+36
  else U.budget:Hide() end
  U.listPanel:ClearAllPoints();U.listPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-top);U.listPanel:SetSize(leftW,h-top-44);U.listPanel:Show()
  U.detailPanel:ClearAllPoints();U.detailPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",30+leftW,-top);U.detailPanel:SetSize(rightW,h-top-44);U.detailPanel:Show()
  U.countText:ClearAllPoints();U.countText:SetPoint("TOPRIGHT",U.listPanel,"TOPRIGHT",-12,-15)
  U.filterMenu:ClearAllPoints();U.filterMenu:SetPoint("TOPLEFT",U.filterButton,"BOTTOMLEFT",0,-4)
  -- Header columns line up with the row labels: rows sit 4 px into the panel and are leftW-30 wide.
  local colX={28,leftW-172,leftW-114}
  local colW={leftW-210,54,80}
  for i,b in ipairs(U.sortCols) do
    b:ClearAllPoints();b:SetPoint("TOPLEFT",U.listPanel,"TOPLEFT",colX[i],-42);b:SetWidth(colW[i])
    local on=self.db.ui.recipeSort==b.sortKey
    b:SetText(b.baseLabel..(on and (b.sortKey=="chance" and (" "..ARROW_DOWN) or (" "..ARROW_UP)) or ""))
    if b.label and type(b.label.SetTextColor)=="function" then if on then b.label:SetTextColor(.88,.69,.31) else b.label:SetTextColor(.56,.60,.64) end end
  end
  U.listLine:ClearAllPoints();U.listLine:SetPoint("TOPLEFT",U.listPanel,"TOPLEFT",1,-62);U.listLine:SetPoint("TOPRIGHT",U.listPanel,"TOPRIGHT",-1,-62)
  U.listScroll:ClearAllPoints();U.listScroll:SetPoint("TOPLEFT",U.listPanel,"TOPLEFT",4,-64);U.listScroll:SetPoint("BOTTOMRIGHT",U.listPanel,"BOTTOMRIGHT",-26,4)
  U.detailScroll:ClearAllPoints();U.detailScroll:SetPoint("TOPLEFT",U.detailPanel,"TOPLEFT",0,-2);U.detailScroll:SetPoint("BOTTOMRIGHT",U.detailPanel,"BOTTOMRIGHT",-24,2)
  if type(U.listScroll.SetWidth)=="function" then U.listScroll:SetWidth(leftW-30) end
  if type(U.detailScroll.SetWidth)=="function" then U.detailScroll:SetWidth(rightW-24) end

  local chosen,options=self:SelectedOption(key)
  local captured=self.db.lastCapture
  local skill=record and record.skill or 0
  local current=captured and captured.key==key and captured.skill==skill
  local entries,viewKey=recipeEntries(self,key,chosen,options or {},current)
  local labels={useful=L("Sinnvolle Rezepte"),unlearned=L("Nicht gelernt"),all=L("Alle Rezepte")}
  U.filterButton:SetText(labels[viewKey].."  "..ARROW_DOWN)
  for _,item in ipairs(U.filterItems) do item.selectionMarker:SetShown(item.viewKey==viewKey) end
  U.countText:SetText(string.format(#entries==1 and L("%d Rezept") or L("%d Rezepte"),#entries))
  local active=setRecipeList(key,entries,chosen)
  if not active and #entries>0 and not (self.db.ui.selectedVendorKey==key and self.db.ui.selectedVendorRecipe) then active=chosen end
  if #entries==0 then
    local row=listRow(1)
    row.craftRecipe=nil
    row:ClearAllPoints();row:SetPoint("TOPLEFT",U.listContent,"TOPLEFT",0,0);row:SetWidth(leftW-30)
    row.nameLabel:SetText(not record and L("Beruf noch nicht auf diesem Charakter erfasst.")
      or (not current and L("Berufsfenster öffnen und aktualisieren.") or L("Keine passenden Rezepte.")))
    row.subLabel:SetText(not current and L("Nur aktuelle Skillfarben lassen sich sinnvoll vergleichen.") or L("Filter oben ändern oder alle Rezepte anzeigen."))
    row.chanceLabel:SetText("");row.costLabel:SetText("");row.stripe:Hide();row.dot:Hide()
    row:SetBackdropColor(0,0,0,0);row:SetBackdropBorderColor(0,0,0,0)
    row:Show()
  end
  renderDetail(key,active)
end

local function renderPlan(self,key,prof,record,inner)
  local ui=self.db.ui
  local gatheringOnly=prof.gathering and not prof.crafting
  local skill=record and record.skill or 0
  local y=106
  local stages=D.stages[key]
  if stages then
    local n=#stages
    local bw=(inner-(n-1)*3)/n
    for i,segment in ipairs(stages) do
      local b=U.stageButtons[i]
      if not b then
        b=button(frame,60,26,0,0,"",function() end)
        U.stageButtons[i]=b
      end
      local first,last,description=segment[1],segment[2],segment[3]
      local done=skill>=last
      local active=skill>=first and skill<last
      b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",18+(i-1)*(bw+3),-y);b:SetSize(bw,26)
      b:SetText((done and "|cff7fc898" or (active and "|cfff0d08a" or "|cff9aa3ad"))..first.."–"..last..RESET)
      local p=self:PlanFor(key)
      b.selectionMarker:SetShown(p.start<last and p.target>first and not gatheringOnly)
      tooltip(b,first.."–"..last..(done and (" · "..L("erledigt")) or (active and (" · "..L("jetzt")) or "")),{description,
        gatheringOnly and L("Sammelbereich ohne garantierte Erntemenge") or L("Klick: Bereich für den Plan übernehmen")})
      b:SetScript("OnClick",function()
        if not gatheringOnly and CP:SetPlanRange(key,math.max(first,math.min(skill,last-1)),last) then CP:Render() end
      end)
      b:Show()
    end
    y=y+36
  end
  if gatheringOnly then
    showContent(y)
    setVisualCards({{title=L("Sammelberuf · kein Rezept-Einkaufsplan"),detail=L("Die Etappen oben zeigen Sammelgebiete; Lehrer stehen unter Lehrer & Händler."),color="blue"}})
    return
  end
  if not ({shopping=true,crafts=true,leftovers=true,details=true,projects=true})[ui.planPage] then ui.planPage="shopping" end
  local page=ui.planPage
  syncPlanFields(key)
  local pending=self:RouteBuildPending(key)
  place(U.plan.rangeLabel,18,y+7);U.plan.rangeLabel:Show()
  place(U.plan.rangeStart,48,y+1);U.plan.rangeStart:Show()
  place(U.plan.targetLabel,102,y+7);U.plan.targetLabel:Show()
  place(U.plan.rangeEnd,124,y+1);U.plan.rangeEnd:Show()
  place(U.plan.build,182,y,130);U.plan.build:Show()
  U.plan.build:SetText(pending and L("Berechne…") or (self:AutoRouteShopping(key) and L("Neu berechnen") or L("Plan erstellen")))
  setPrimaryEnabled(U.plan.build,self:Catalog(key)~=nil and not pending)
  local segW=92
  for i,b in ipairs(U.plan.pages) do
    place(b,18+inner-#U.plan.pages*segW-3+(i-1)*segW,y+1,segW);b:Show()
    b.selectionMarker:SetShown(b.pageKey==page)
  end
  segmentGroup("plan",U.plan.pages)
  y=y+38
  if page=="crafts" then
    local p=self:PlanFor(key);local choice=self:SelectedOption(key)
    place(U.plan.quantityLabel,18,y+7);U.plan.quantityLabel:Show()
    place(U.plan.rangeQty,70,y+1);U.plan.rangeQty:Show()
    place(U.plan.add,126,y,210);U.plan.add:Show()
    U.plan.add:SetEnabled(choice~=nil and not p.autoMode and not (ui.selectedVendorKey==key and ui.selectedVendorRecipe))
    place(U.plan.draft,344,y,150);U.plan.draft:Show()
    place(U.plan.clear,502,y,120);U.plan.clear:Show()
    y=y+36
  elseif page=="details" then
    place(U.plan.clear,18,y,140);U.plan.clear:Show()
    y=y+36
  end
  U.plan.clear:SetText(self.pendingPlanClear==key and L("Bestätigen?") or L("Plan leeren"))
  local bottomBar=page=="shopping"
  showContent(y,bottomBar and 92 or 42)
  local cards=self:PlanPageCards(key,page)
  if page=="shopping" then
    local manual=self:PersonalShopping()
    local rows={}
    for id,n in pairs(manual) do
      local _,bag,bank,live,known=self:ItemAvailability(id);local price=self:PriceDetails(id)
      rows[#rows+1]={id=id,quantity=n,bag=bag,bank=bank,bankKnown=known,missing=n,buy=price.price and price.price*n}
    end
    if #rows>0 then
      cards[#cards+1]={sectionHeader=true,title=L("SELBST HINZUGEFÜGT")}
      cards[#cards+1]={materialTable=rows}
    end
  end
  setVisualCards(cards)
  if bottomBar then
    local h=type(frame.GetHeight)=="function" and frame:GetHeight() or H
    U.plan.footerLine:ClearAllPoints();U.plan.footerLine:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-(h-86));U.plan.footerLine:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-18,-(h-86));U.plan.footerLine:Show()
    local c=self:CostCalculation("plan",key)
    place(U.plan.totalLabel,18,h-80);U.plan.totalLabel:Show()
    place(U.plan.total,18,h-66,260);U.plan.total:Show()
    U.plan.total:SetText(pending and L("Berechne…") or ((c.cashComplete and "" or L("Ab "))..self:FormatCostMoney(c.cash)))
    place(U.plan.export,18+inner-150,h-80,150);U.plan.export:Show();setPrimaryEnabled(U.plan.export,not pending)
    place(U.plan.print,18+inner-150-8-140,h-80,140);U.plan.print:Show()
    place(U.plan.manual,18+inner-150-8-140-8-150,h-80,150);U.plan.manual:Show()
  end
end

local function renderTrainers(self,key,prof,inner)
  local ui=self.db.ui
  local merchants=ui.vendorBrowser==true and not (prof.gathering and not prof.crafting)
  local page=merchants and "merchants" or ((ui.trainerPage=="tour" or ui.trainerPage=="spec") and ui.trainerPage or "trainers")
  local y=106
  for i,b in ipairs(U.trainer.pages) do
    place(b,18+(i-1)*130,y+1,130);b:Show();b.selectionMarker:SetShown(b.pageKey==page)
  end
  segmentGroup("trainer",U.trainer.pages)
  if page=="tour" or page=="spec" then
    showContent(y+36)
    setVisualCards(page=="tour" and self:LearnTourCards(key) or self:SpecCards(key))
    return
  end
  if merchants then
    y=y+36
    place(U.merchant.searchLabel,18,y+7);place(U.merchant.search,70,y+1,220);place(U.merchant.clear,300,y,70)
    place(U.merchant.bySkill,18+inner-208,y,100);place(U.merchant.byName,18+inner-100,y,100)
    for _,c in ipairs(U.merchant.controls) do c:Show() end
    if not U.merchant.search:HasFocus() then U.merchant.search.craftSync=true;U.merchant.search:SetText(ui.vendorQuery or "");U.merchant.search.craftSync=nil end
    U.merchant.bySkill.selectionMarker:SetShown(ui.vendorSort~="name");U.merchant.byName.selectionMarker:SetShown(ui.vendorSort=="name")
    y=y+36
    showContent(y+22)
    local rows=self:VendorRecipeBrowseOptions(key,ui.vendorQuery,ui.vendorSort)
    U.section:ClearAllPoints();U.section:SetPoint("TOPLEFT",frame,"TOPLEFT",19,-y);U.section:Show()
    U.section:SetText(string.format(L("Händlerrezepte · %d Treffer · alle Skillstufen"),#rows))
    if #rows>0 then setRecipeRows(key,rows,nil) else setRows({L("Keine hinterlegten Händlerrezepte für diese Suche."),L("Suche leeren oder einen anderen Beruf wählen. Der Datenbestand ist nicht vollständig live bestätigt.")}) end
    return
  end
  local choices,rank,recommended,nearest=self:TrainerChoices(key)
  -- Four page segments fill the first row; the trainer actions sit on the second next to the rank text.
  y=y+36
  place(U.trainer.nearest,18+inner-150,y,150);U.trainer.nearest:Show();U.trainer.nearest:SetEnabled(nearest~=nil)
  place(U.trainer.recommend,18+inner-150-8-190,y,190);U.trainer.recommend:Show();setPrimaryEnabled(U.trainer.recommend,recommended~=nil)
  place(U.trainer.info,18,y+6,inner-360);U.trainer.info:Show()
  local gate=self.RankGate and self:RankGate(key)
  U.trainer.info:SetText(gate and gate.text or (U.rankText or ""))
  y=y+34
  showContent(y)
  local offers={}
  if not (prof.gathering and not prof.crafting) then
    for _,entry in ipairs(self:VendorRecipeOptions(key)) do offers[#offers+1]=entry end
    for _,entry in ipairs(self:TrainerOffersCached(key)) do offers[#offers+1]=entry end
  end
  setTrainerRows(choices,recommended,nearest,ui.selectedTrainers[key],offers,key)
end

local function renderCamping(self,key,inner)
  local y=106
  local w=(inner-16-180)/4
  for i,b in ipairs(U.camp) do
    place(b,18+(i-1)*w,y+1,w);b:Show();b.selectionMarker:SetShown(self.db.ui.campingPage==b.pageKey)
  end
  segmentGroup("camp",U.camp)
  place(U.campFilter,18+inner-180,y,180);U.campFilter:Show()
  U.campFilter:SetText(self.db.ui.campingAll==false and L("Alle Camping-Berufe") or L("Nur gewählter Beruf"))
  showContent(y+36)
  setVisualCards(self:CampingCards(key))
end

local function settingsList(self)
  local groups={general={},route={},display={},advanced={}}
  local order={general=L("ALLGEMEIN"),route=L("REZEPTWAHL UND ROUTE"),display=L("DARSTELLUNG"),advanced=L("ERWEITERT")}
  for _,card in ipairs(self:SettingsCards()) do
    local g=groups[card.group or "advanced"] or groups.advanced
    g[#g+1]=card
  end
  local out={}
  for _,name in ipairs({"general","route","display"}) do
    if #groups[name]>0 then
      out[#out+1]={sectionHeader=true,title=order[name]}
      for _,card in ipairs(groups[name]) do out[#out+1]=card end
    end
  end
  local open=self.db.ui.settingsAdvanced==true
  out[#out+1]={title=(open and COLLAPSE or EXPAND)..L("Erweitert · Punktgrenzen, Vorausschau, Datenquellen"),
    detail=L("Feineinstellungen für Routen, Datenquellen und Prüfwerkzeuge."),footer="",color="gold",
    action=function() CP.db.ui.settingsAdvanced=not CP.db.ui.settingsAdvanced;CP:Render() end}
  if open then for _,card in ipairs(groups.advanced) do out[#out+1]=card end end
  return out
end

function CP:RenderRecommendation(key,inner)
  local rec=self:Recommendation(key)
  self.currentRecommendation=rec
  if not rec then U.rec:Hide();return false end
  -- Two text lines below the title when there is a saving tip or a whole-way cost, so nothing gets cut off.
  local height=rec.extra and 64 or 54
  U.rec:ClearAllPoints();U.rec:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-106);U.rec:SetSize(inner,height);U.rec:Show()
  if type(U.rec.icon.SetTexture)=="function" then U.rec.icon:SetTexture(self:RecipeIcon(key,rec.id)) end
  local w=inner-54-150-110-30
  U.rec.title:SetWidth(w);U.rec.detail:SetWidth(w);U.rec.extra:SetWidth(w)
  U.rec.title:ClearAllPoints();U.rec.title:SetPoint("TOPLEFT",U.rec,"TOPLEFT",54,rec.extra and -8 or -9)
  U.rec.detail:ClearAllPoints();U.rec.detail:SetPoint("TOPLEFT",U.rec,"TOPLEFT",54,rec.extra and -26 or -28)
  U.rec.extra:ClearAllPoints();U.rec.extra:SetPoint("TOPLEFT",U.rec,"TOPLEFT",54,-43)
  U.rec.title:SetText(rec.title)
  U.rec.detail:SetText(rec.detail)
  U.rec.extra:SetText(rec.extra or "");U.rec.extra:SetShown(rec.extra~=nil)
  U.rec.search:ClearAllPoints();U.rec.search:SetPoint("RIGHT",U.rec,"RIGHT",-12,0)
  U.rec.pick:ClearAllPoints();U.rec.pick:SetPoint("RIGHT",U.rec.search,"LEFT",-8,0)
  if rec.learn then
    U.rec.search:SetText(rec.learn.source=="ah" and L("Rezept im AH suchen") or L("Wegpunkt zum Lernen"))
    U.rec.search:SetScript("OnClick",function()
      local r=CP.currentRecommendation;if not r or not r.learn then return end
      if r.learn.source=="vendor" and r.learn.vendor and r.learn.vendor.location then CP:SetWaypoint(r.learn.vendor.location)
      elseif r.learn.source=="ah" then CP:GoLearn(r.key,r.id)
      else CP:TrainerWaypoint() end
    end)
  else
    U.rec.search:SetText(rec.missing>0 and L("Im AH suchen") or L("Berufsfenster öffnen"))
    U.rec.search:SetScript("OnClick",rec.missing>0 and function() CP:SearchRecommendation() end
      or function() local r=CP.currentRecommendation;if r then CP:OpenLearnedRecipe(r.key,r.id) end end)
  end
  primary(U.rec.search)
  local chosen=self:SelectedOption(key)
  U.rec.pick:SetShown(not rec.learn and not (chosen and chosen.id==rec.id and not self.db.ui.selectedVendorRecipe))
  -- Old or missing prices on the way: offer a targeted Auctionator scan of exactly those materials.
  local p=rec.prices
  local doubtful=p and (p.stale+p.missing+p.unknown)>0
  U.rec.prices:ClearAllPoints()
  U.rec.prices:SetPoint("RIGHT",U.rec.pick:IsShown() and U.rec.pick or U.rec.search,"LEFT",-8,0)
  U.rec.prices:SetShown(doubtful==true)
  if doubtful then
    U.rec.prices:SetText(p.missing>0 and string.format(L("%d ohne Preis"),p.missing) or L("Preise alt"))
    local tw=inner-54-150-30-(U.rec.pick:IsShown() and 118 or 0)-128
    U.rec.title:SetWidth(tw);U.rec.detail:SetWidth(tw);U.rec.extra:SetWidth(tw)
  end
  U.rec.switch:ClearAllPoints()
  U.rec.switch:SetShown(rec.alternative~=nil)
  if rec.alternative then
    local left=U.rec.prices:IsShown() and U.rec.prices or (U.rec.pick:IsShown() and U.rec.pick or U.rec.search)
    U.rec.switch:SetPoint("RIGHT",left,"LEFT",-8,0)
    U.rec.switch:SetText(rec.alternative.source=="cheapest" and L("Günstigsten nehmen") or L("Meinen Plan nehmen"))
    local sw=(U.rec.title:GetWidth() or 0)-148
    if sw>120 then U.rec.title:SetWidth(sw);U.rec.detail:SetWidth(sw);U.rec.extra:SetWidth(sw) end
  end
  -- 1.2.1: only as many hints as fit; the rest stays in the tooltip and the companion.
  local parts=rec.extraParts or {}
  if #parts>1 and type(U.rec.extra.GetStringWidth)=="function" then
    local avail=U.rec.extra:GetWidth()
    if type(avail)=="number" and avail>0 and (U.rec.extra:GetStringWidth() or 0)>avail then U.rec.extra:SetText(parts[1]) end
  end
  -- Hover: the whole cheapest path, step by step.
  U.rec:EnableMouse(true)
  tooltip(U.rec,L("Günstigster Weg nach AH-Preisen"),function()
    local r=CP.currentRecommendation
    local lines=r and r.path and CP:PathTooltip(r.path) or {L("Keine Preise für einen Wegvergleich · AH scannen.")}
    -- 1.3.0: why this recipe, compared with the two best alternatives right now.
    local why=r and CP.WhyRecipeLines and CP:WhyRecipeLines(r.key,r.id)
    if why then for i=#why,1,-1 do table.insert(lines,1,why[i]) end end
    -- Hints that did not fit into the banner.
    if r and r.allExtra and r.allExtra~=r.extra then
      local all={}
      for part in (r.allExtra.."  ·  "):gmatch("(.-)  ·  ") do all[#all+1]=part end
      for i=#all,1,-1 do table.insert(lines,1,all[i]) end
    end
    return lines
  end)
  return height
end

function CP:Render()
  self:InvalidateReservations();self.marketUseCache=nil;self.unlockCache=nil;self.routeAdvice=nil;self.trainerOfferCache=nil
  if not self.db then return end
  self:RestoreWindowPosition()
  self:ApplyTheme()
  local ui=self.db.ui
  local key=self.db.view
  local prof=D.professions[key]
  local record=self.db.professions[key]
  local tab=ui.tab or "now"
  if tab=="stages" then tab="plan" elseif tab=="mats" then tab="now" end
  ui.tab=tab
  local context=key..":"..tab..":"..tostring(ui.campingPage)..":"..tostring(ui.campingAll)..":"..tostring(ui.vendorOnly)..":"..tostring(ui.allRecipes)..":"..tostring(ui.planPage)..":"..tostring(ui.vendorBrowser)..":"..tostring(ui.vendorQuery)..":"..tostring(ui.vendorSort)..":"..tostring(ui.trainerPage)
  resetContentScroll=context~=lastContentContext
  lastContentContext=context
  if tab~="plan" then self.pendingPlanClear=nil end
  if tab~="settings" then self.pendingSettingsReset=nil end
  local inner=width()-36

  renderHeader(self,key,prof,record)
  renderTabs(self,tab)
  hideAll()
  clearRows()

  if tab=="settings" then
    place(U.settingsTitle,18,70);U.settingsTitle:Show()
    place(U.settingsDone,18+inner-90,64,90);U.settingsDone:Show()
    showContent(106)
    setVisualCards(settingsList(self))
  elseif tab=="help" then
    U.back:Show()
    U.section:ClearAllPoints();U.section:SetPoint("TOPLEFT",frame,"TOPLEFT",19,-106);U.section:SetText(L("Hilfe · so funktioniert CraftPilot"));U.section:Show()
    showContent(132)
    setVisualCards(self:HelpCards())
  elseif tab=="economy" or tab=="audit" or tab=="reservations" then
    U.back:Show()
    local titles={economy=L("Clever skillen · verkaufen, behalten oder anders skillen"),audit=L("Berufsdaten · Farbgrenzen und Clientabgleich"),reservations=L("Gemeinsame Vorratsreservierung")}
    U.section:ClearAllPoints();U.section:SetPoint("TOPLEFT",frame,"TOPLEFT",19,-106);U.section:SetText(titles[tab]);U.section:Show()
    showContent(132)
    if tab=="economy" then setVisualCards(self:EconomyCards(key))
    elseif tab=="audit" then setVisualCards(self:ProfessionAuditCards())
    else setVisualCards(self:ReservationCards()) end
  elseif tab=="plan" then
    renderPlan(self,key,prof,record,inner)
  elseif tab=="trainers" then
    renderTrainers(self,key,prof,inner)
  elseif tab=="camping" then
    renderCamping(self,key,inner)
  elseif tab=="twinks" then
    showContent(106)
    setVisualCards(self:TwinkCards(key))
  elseif tab=="items" then
    local page=ui.itemPage or "search"
    for i,b in ipairs(U.itemButtons) do
      b:Show()
      if b.selectionMarker then b.selectionMarker:SetShown(U.itemPages[i].key==page) end
    end
    segmentGroup("items",U.itemButtons)
    if page=="search" then
      if self.RequestItemNames then self:RequestItemNames() end
      U.itemSearch:Show()
      if not (type(U.itemSearch.HasFocus)=="function" and U.itemSearch:HasFocus()) then U.itemSearch:SetText(ui.itemQuery or "") end
      U.itemResults:SetShown(ui.itemSelected~=nil)
    end
    showContent(140)
    setVisualCards(self:ItemDBCards())
  elseif tab=="endgame" then
    local page=ui.endgamePage or "profit"
    for i,b in ipairs(U.endgameButtons) do
      b:Show()
      if b.selectionMarker then b.selectionMarker:SetShown(U.endgamePages[i].key==page) end
    end
    segmentGroup("endgame",U.endgameButtons)
    showContent(140)
    setVisualCards(self:EndgameCards(key,page))
  else
    renderNow(self,key,prof,record,inner)
  end
  U.footer:SetText("CraftPilot "..tostring(self.version or "").."  ·  "..L("Kauft, lernt und stellt nichts automatisch her."))
  local footerWidth=U.footer:GetStringWidth();if type(footerWidth)=="number" and footerWidth>0 then U.footer:SetWidth(footerWidth) end
end

function CP:ToggleWindow()
  if frame:IsShown() then frame:Hide();return end
  -- First start: the help with the three first steps; "Los geht's" marks it as seen.
  if self.db and self.db.ui.firstRunDone==nil then self.db.ui.firstRunDone=false;self.db.ui.tab="help" end
  self:Refresh(true)
  frame:Show()
end
