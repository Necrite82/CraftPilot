-- Original CraftPilot settings and minimap integration; no external libraries.
local _,CP=...
local L=CP.L
local ICON="Interface\\AddOns\\CraftPilotPro\\Media\\CraftPilot"

function CP:FormatMoney(value)
  if type(value)~="number" then return L("Preis fehlt") end
  local amount=math.max(0,math.floor(value+.5))
  return string.format("%d|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t %d|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t %d|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t",
    math.floor(amount/10000),math.floor(amount%10000/100),amount%100)
end

function CP:InitializeControls()
  local ui=self.db.ui
  ui.useQuestieDB=nil -- QuestieDB is required since 0.29; the old switch is gone.
  if type(ui.showVendorRecipes)~="boolean" then ui.showVendorRecipes=true end
  if type(ui.preferReliableSkill)~="boolean" then ui.preferReliableSkill=true end
  self:InitializeSkillPolicy()
  if ui.skillPolicyVersion~=1 then
    for _,plan in pairs(self.db.plans) do plan.autoRoute=nil;plan.autoMode=nil end
    ui.skillPolicyVersion=1
  end
  if type(ui.economyCut)~="number" or ui.economyCut~=ui.economyCut then ui.economyCut=5 end
  ui.economyCut=math.max(0,math.min(30,ui.economyCut))
  if type(ui.favorRate)~="number" or ui.favorRate~=ui.favorRate or ui.favorRate<0 then ui.favorRate=0 end
  if type(ui.minimapAngle)~="number" or ui.minimapAngle~=ui.minimapAngle then ui.minimapAngle=225 end
  if type(ui.hideMinimap)~="boolean" then ui.hideMinimap=false end
  if type(ui.knownRecipesOnly)~="boolean" then ui.knownRecipesOnly=false end
  if type(ui.showSourceDetails)~="boolean" then ui.showSourceDetails=false end
  self:MigrateSettings()
  self:RefreshProfessionSkills()
  if not ui.showAllProfessions then self:PreferOwnedProfession() end
  self:UpdateMinimapButton()
end

function CP:PreferOwnedProfession()
  if self:OwnsProfession(self.db.view) then return end
  for _,key in ipairs(self.Data.order) do
    if self:OwnsProfession(key) then self.db.view=key;return end
  end
end

function CP:PositionMinimapButton()
  local b=self.minimapButton
  if not b or not self.db then return end
  local angle=math.rad(self.db.ui.minimapAngle)
  local width=type(Minimap.GetWidth)=="function" and Minimap:GetWidth() or 140
  local height=type(Minimap.GetHeight)=="function" and Minimap:GetHeight() or 140
  local radius=math.max(40,math.min(160,math.max(tonumber(width) or 140,tonumber(height) or 140)/2+8))
  b:ClearAllPoints()
  b:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
end

function CP:UpdateMinimapButton()
  if not self.db or not Minimap then return end
  if not self.minimapButton then
    local b=CreateFrame("Button","CraftPilotProMinimapButton",Minimap)
    self.minimapButton=b
    b:SetSize(32,32)
    b:SetFrameStrata("MEDIUM")
    b:SetNormalTexture(ICON)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function(_,mouse)
      if b.dragged==true then b.dragged=false;return end
      if mouse=="RightButton" then CP:OpenTab("settings") else CP:ToggleWindow() end
    end)
    b:SetScript("OnEnter",function()
      if GameTooltip then
        GameTooltip:SetOwner(b,"ANCHOR_LEFT")
        GameTooltip:SetText("CraftPilot")
        GameTooltip:AddLine(L("Linksklick: öffnen / schließen"),1,1,1)
        GameTooltip:AddLine(L("Rechtsklick: Einstellungen"),1,1,1)
        GameTooltip:AddLine(L("Ziehen: Position ändern"),.7,.8,.9)
        GameTooltip:Show()
      end
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnDragStart",function()
      b.dragged=true
      if GameTooltip then GameTooltip:Hide() end
      b:SetScript("OnUpdate",function()
        if type(GetCursorPosition)~="function" or type(Minimap.GetCenter)~="function" then return end
        local x,y=GetCursorPosition()
        local cx,cy=Minimap:GetCenter()
        local scale=type(Minimap.GetEffectiveScale)=="function" and Minimap:GetEffectiveScale() or 1
        if not cx or not cy or not scale or scale<=0 then return end
        local dx,dy=x/scale-cx,y/scale-cy
        local angle
        if math.atan2 then angle=math.atan2(dy,dx)
        elseif dx>0 then angle=math.atan(dy/dx)
        elseif dx<0 then angle=math.atan(dy/dx)+(dy>=0 and math.pi or -math.pi)
        elseif dy~=0 then angle=dy>0 and math.pi/2 or -math.pi/2
        else return end
        CP.db.ui.minimapAngle=math.deg(angle)%360
        CP:PositionMinimapButton()
      end)
    end)
    b:SetScript("OnDragStop",function()
      b:SetScript("OnUpdate",nil)
      if C_Timer and type(C_Timer.After)=="function" then
        C_Timer.After(0,function() b.dragged=nil end)
      else b.dragged=nil end
    end)
    b:SetScript("OnHide",function() b:SetScript("OnUpdate",nil) end)
  end
  self:PositionMinimapButton()
  self.minimapButton:SetShown(not self.db.ui.hideMinimap)
end

-- 0.25: three combined choices replace the separate color, bank, twink and recipe switches. The old
-- keys stay the internal state (the route planners read them); these setters keep them consistent.
CP.SkillPaths={"cheapest","reliable","orangeYellow","fastest"}
CP.StockScopes={"bags","bank","alts"}
function CP:SkillPath()
  local ui=self.db.ui
  if ui.fastestSkill then return "fastest" end
  if ui.allowGreen==false then return "orangeYellow" end
  return ui.preferReliableSkill and "reliable" or "cheapest"
end
function CP:StockScope()
  if not self.db.includeBank then return "bags" end
  return self.db.ui.includeAlts==false and "bank" or "alts"
end
function CP:LearnRecipesEnabled()
  local ui=self.db.ui
  return ui.showVendorRecipes~=false and not ui.knownRecipesOnly
end
local function resetRoutes(self)
  self:CancelRouteBuild()
  for _,plan in pairs(self.db.plans) do plan.autoRoute=nil;plan.autoMode=nil end
  self.pathCache=nil
end
function CP:SetSkillPath(mode)
  local ui=self.db.ui
  ui.fastestSkill=false
  if mode=="orangeYellow" then ui.allowYellow=true;ui.allowGreen=false;ui.preferReliableSkill=true
  elseif mode=="reliable" then ui.allowYellow=true;ui.allowGreen=true;ui.preferReliableSkill=true
  elseif mode=="fastest" then ui.allowYellow=true;ui.allowGreen=true;ui.preferReliableSkill=false;ui.fastestSkill=true
  else mode="cheapest";ui.allowYellow=true;ui.allowGreen=true;ui.preferReliableSkill=false end
  ui.skillPath=mode
  resetRoutes(self);self:SkillPolicyChanged()
end
function CP:SetStockScope(scope)
  self.db.includeBank=scope~="bags"
  self.db.ui.includeAlts=scope=="alts"
  resetRoutes(self);self:Refresh(false)
end
function CP:MigrateSettings()
  local ui=self.db.ui
  if ui.settingsVersion==2 then return end
  -- Keep what the player chose before: green off → orange/yellow only; "prefer reliable" → safe colors.
  ui.skillPath=self:SkillPath()
  if ui.allowYellow==false then ui.allowYellow=true end
  if type(ui.countSales)~="boolean" then ui.countSales=false end
  ui.settingsVersion=2
end
local function cycle(list,current)
  for i,v in ipairs(list) do if v==current then return list[i%#list+1] end end
  return list[1]
end

function CP:ToggleSetting(key)
  if not self.db then return end
  if key=="bank" then self.db.includeBank=not self.db.includeBank
  elseif key=="mode" then self.db.mode=self.db.mode=="cash" and "value" or "cash"
  elseif key=="learnRecipes" then
    local on=not self:LearnRecipesEnabled()
    self.db.ui.showVendorRecipes=on;self.db.ui.knownRecipesOnly=not on
  elseif ({allowYellow=true,allowGreen=true,planAhead=true})[key] then
    self.db.ui[key]=not self.db.ui[key];self:SkillPolicyChanged();return
  elseif ({autoOpen=true,showAllProfessions=true,hideMinimap=true,knownRecipesOnly=true,showSourceDetails=true,preferReliableSkill=true,showVendorRecipes=true,useQuestieDB=true,includeAlts=true,companion=true,countSales=true,tooltips=true,itemMarks=true,ahAlarm=true,bankHelper=true,mailHelper=true,skillLog=true,itemVerdict=true,itemAltClick=true})[key] then
    -- Companion and twinks default to on (nil): the first click turns them off.
    if key=="companion" or key=="includeAlts" or key=="tooltips" or key=="itemMarks" or key=="ahAlarm" or key=="bankHelper" or key=="mailHelper" or key=="skillLog" or key=="itemVerdict" or key=="itemAltClick" then self.db.ui[key]=self.db.ui[key]==false
    else self.db.ui[key]=not self.db.ui[key] end
  else return end
  self.pendingSettingsReset=nil
  if (key=="showVendorRecipes" or key=="learnRecipes") and not self.db.ui.showVendorRecipes then self.db.ui.vendorOnly=nil end
  if key=="showAllProfessions" and not self.db.ui.showAllProfessions then self:PreferOwnedProfession() end
  self:UpdateMinimapButton()
  if key=="companion" and self.UpdateCompanion then self:UpdateCompanion() end
  if key=="itemMarks" and self.UpdateItemMarks then self:UpdateItemMarks(true) end
  -- A different route policy must not leave an old automatic proposal visible.
  if ({preferReliableSkill=true,knownRecipesOnly=true,bank=true,mode=true,includeAlts=true,learnRecipes=true,countSales=true,showVendorRecipes=true})[key] then
    resetRoutes(self)
  end
  self:Refresh(false)
end

function CP:ConfirmWindowReset()
  if not self.pendingSettingsReset then
    self.pendingSettingsReset=true
    self:Render()
    return false
  end
  self.pendingSettingsReset=nil
  self.db.ui.width=750
  self.db.ui.height=676
  self.frame:SetSize(750,676)
  self:ResetWindowPosition()
  self.db.ui.minimapAngle=225
  self.db.ui.hideMinimap=false
  self.db.ui.companionPos=nil
  self:UpdateMinimapButton()
  self:Render()
  return true
end

function CP:SettingsCards()
  local ui=self.db.ui
  local function check(key,title,detail,checked,group,icon)
    return {title=title,detail=detail,footer="",icon=icon or ICON,color="blue",group=group,action=function() CP:ToggleSetting(key) end,
      checkbox={key=key,checked=checked,apply=function(value) if value~=checked then CP:ToggleSetting(key) end end}}
  end
  local function choice(title,value,detail,action,group,icon)
    return {title=title..": "..value,detail=detail,footer=L("Anklicken zum Wechseln"),action=action,icon=icon or ICON,color="blue",group=group}
  end
  local function slider(label,value,min,max,step,unit,apply)
    return {title=label..value..unit,footer=L("Regler ziehen: ")..min..L(" bis ")..max..unit,group="advanced",
      icon=ICON,color="blue",slider={label=label,value=value,min=min,max=max,step=step,unit=unit,apply=apply}}
  end
  local pathNames={cheapest=L("Günstigster Weg"),reliable=L("Sichere Farben bevorzugen"),orangeYellow=L("Nur Orange und Gelb"),fastest=L("Schnellster Weg")}
  local pathDetails={
    cheapest=L("Rein nach AH-Preisen: Grün wird genommen, wenn es pro Skillpunkt billiger ist."),
    reliable=L("Orange und Gelb vor Grün, solange Grün nicht deutlich (über 25 %) billiger ist."),
    orangeYellow=L("Grüne Rezepte werden nie vorgeschlagen; weniger Herstellungen, oft teurer."),
    fastest=L("So wenige Herstellungen wie möglich: Gelb oder Grün nur, wenn es ein Vielfaches billiger ist."),
  }
  local stockNames={bags=L("nur Taschen"),bank=L("Taschen und Bank"),alts=L("Taschen, Bank und Twinks")}
  local path,scope=self:SkillPath(),self:StockScope()
  local rows={
    -- General
    choice(L("Vorräte"),stockNames[scope],self:BankStatus().."\n"..(self.AltStatus and self:AltStatus() or ""),
      function() CP:SetStockScope(cycle(CP.StockScopes,CP:StockScope())) end,"general","Interface\\Icons\\INV_Misc_Bag_08"),
    choice(L("Preisquelle"),CP:PriceSourceName(ui.priceSource),CP:PriceSourceDetail(),
      function() ui.priceSource=cycle({"auto","auctionator","tsm","auctioneer"},ui.priceSource or "auto");CP.pathCache=nil;CP:Render() end,"general","Interface\\Icons\\INV_Misc_Coin_02"),
    check("companion",L("Begleitfenster am Berufsfenster"),L("Empfehlung, verbleibende Herstellungen, Sitzungsbilanz und Cooldowns direkt neben dem Berufsfenster."),ui.companion~=false,"general"),
    check("autoOpen",L("Berufsfenster beim Wechsel öffnen"),L("Ein Klick im Berufsmenü öffnet auch das Berufsfenster des erlernten Berufs; im Kampf nicht möglich."),ui.autoOpen==true,"general"),
    check("tooltips",L("Hinweise in Gegenstands-Tooltips"),L("Bedarf deines Plans, „nicht verkaufen“, Twink-Bestände und Preisgrenze direkt am Gegenstand."),ui.tooltips~=false,"general"),
    check("itemMarks",L("Markierung in Taschen und Bank"),L("Gold: für einen späteren Schritt aufheben · Blau: dein Plan braucht es. Funktioniert mit den üblichen Taschen-Addons."),ui.itemMarks~=false,"general"),
    check("ahAlarm",L("AH-Alarm"),L("Nach einem Auctionator-Scan: Wunschrezepte im AH und Raid-Vorrat, der im AH deutlich günstiger ist als Herstellen. Jeder Fund einmal am Tag."),ui.ahAlarm~=false,"general","Interface\\Icons\\INV_Misc_Bell_01"),
    check("bankHelper",L("Hinweis an der Bank"),L("Zeigt an der Bank, was deine Pläne von dort brauchen. Schließen blendet ihn aus, bis sich die Liste ändert."),ui.bankHelper~=false,"general","Interface\\Icons\\INV_Misc_Bag_10_Blue"),
    check("mailHelper",L("Hinweis am Briefkasten"),L("Zeigt am Briefkasten, was deine Twinks für ihre Pläne brauchen. Schließen blendet ihn aus, bis sich die Liste ändert."),ui.mailHelper~=false,"general","Interface\\Icons\\INV_Letter_15"),
    check("itemVerdict",L("Behalten oder verkaufen im Tooltip"),L("Zeigt bei Gegenständen, ob sie Zutat für deinen Weg, deine Berufe oder deine Twinks sind – oder nur verkauft werden können."),ui.itemVerdict~=false,"general","Interface\\Icons\\INV_Misc_Bag_10"),
    check("itemAltClick",L("Alt-Klick öffnet Gegenstand"),L("Alt-Klick auf einen Gegenstand in Taschen, Bank oder Chat-Links öffnet ihn in CraftPilot › Gegenstände."),ui.itemAltClick~=false,"general","Interface\\Icons\\INV_Misc_Book_09"),
    check("skillLog",L("Skilldaten mitschreiben"),L("Merkt sich bei jedem Herstellen Skill und ob ein Punkt kam – für eigene Hinweise und zum Teilen (Hilfe › Skilldaten teilen). Keine Namen."),ui.skillLog~=false,"general","Interface\\Icons\\INV_Misc_Note_02"),
    check("hideMinimap",L("Minimap-Button"),L("Links öffnet CraftPilot, rechts die Einstellungen; ziehen verschiebt ihn."),not ui.hideMinimap,"general"),
    -- Route
    choice(L("Skillweg"),pathNames[path],pathDetails[path].."\n"..L("Gilt für Empfehlung, Begleitfenster und Plan erstellen."),
      function() CP:SetSkillPath(cycle(CP.SkillPaths,CP:SkillPath())) end,"route","Interface\\Icons\\INV_Misc_Map_01"),
    check("learnRecipes",L("Rezepte zum Lernen einbeziehen"),L("Lehrer-, Händler- und AH-Rezepte zählen mit, wenn sie den Weg trotz Lernkosten billiger machen."),self:LearnRecipesEnabled(),"route"),
    check("countSales",L("Händlererlös gegenrechnen"),L("Was ein Händler sicher für hergestellte Dinge zahlt, senkt die Kosten eines Rezepts. Mögliche AH-Erlöse werden nur angezeigt, nie eingerechnet."),ui.countSales==true,"route","Interface\\Icons\\INV_Misc_Coin_01"),
    -- Display
    choice(L("Design"),({auto=L("Automatisch"),dark=L("Dunkel"),classic=L("Klassisch")})[ui.skin] or ui.skin,L("Automatisch übernimmt EllesmereUI, wenn es installiert ist."),function()
      ui.skin=ui.skin=="auto" and "dark" or (ui.skin=="dark" and "classic" or "auto")
      CP:ApplyTheme();CP:Render()
    end,"display"),
    {title=self.pendingSettingsReset and L("Zurücksetzen bestätigen – erneut anklicken") or L("Fenster und Minimap-Position zurücksetzen"),
      detail=L("Stellt Position und Größe von Fenster, Begleitfenster und Minimap-Button wieder her; Pläne und Rezeptdaten bleiben."),
      footer=L("Anklicken zum Ändern"),icon=ICON,color="blue",group="display",action=function() CP:ConfirmWindowReset() end},
    -- Advanced
    {title=L("Punktgrenzen pro Rezept"),detail=L("Ab dem Wechsel auf Gelb oder Grün. 0 = ganze Farbphase."),footer=L("Geänderte Einstellungen: bestehende Routen im Einkaufsplan neu bewerten."),icon=ICON,color="blue",group="advanced"},
    slider(L("Gelb: weitere Skillpunkte "),ui.yellowPoints or 0,0,75,1,"",function(value) ui.yellowPoints=value;CP.pathCache=nil;CP:SkillPolicyChanged() end),
    slider(L("Grün: weitere Skillpunkte "),ui.greenPoints or 0,0,75,1,"",function(value) ui.greenPoints=value;CP.pathCache=nil;CP:SkillPolicyChanged() end),
    check("planAhead",L("Vorausschauend planen"),L("Vergleicht früh hergestellte Zwischenprodukte mit ihrem Bedarf in späteren Schritten."),ui.planAhead~=false,"advanced"),
    slider(L("AH-Abzug beim Verkauf "),tonumber(ui.economyCut) or 5,0,30,1,"%",function(value) ui.economyCut=value;CP.pathCache=nil;CP:Render() end),
    {title=L("Merchant's Favor in Gold umrechnen"),detail=L("Was dich 1 Favor beim Füllen der Waylaid Crates kostet. Dann zählen Favor-Rezepte im günstigsten Weg mit. 0 = nicht umrechnen."),footer="",icon=ICON,color="blue",group="advanced"},
    slider(L("Silber je Favor "),math.floor((tonumber(ui.favorRate) or 0)/100),0,200,1,"s",function(value) ui.favorRate=value*100;CP.pathCache=nil;CP:SkillPolicyChanged() end),
    {title=self:QuestieStatus(),detail=L("Liefert Lehrer, Händlerstandorte und Sammelgebiete. Wird über die CurseForge-App automatisch mitinstalliert."),footer="",icon=ICON,color=self:QuestieProvider() and "green" or "red",group="advanced"},
    {title=L("Vorratsreservierungen"),detail=L("Gemeinsame Bestände aller Berufs- und Campingpläne; Priorität ändern."),footer=L("Anklicken zum Öffnen"),icon=ICON,color="blue",group="advanced",action=function() CP:OpenTab("reservations") end},
    {title=L("Berufsdaten prüfen"),detail=L("Alle zwölf Berufe, Farbgrenzen und Abweichungen zum Client anzeigen."),footer=L("Anklicken zum Öffnen"),icon=ICON,color="blue",group="advanced",action=function() CP:OpenTab("audit") end},
    {title=CP:VersionStatus(),detail=L("Versionsvergleich mit Gruppe und Gilde; kein direkter GitHub-Abruf."),footer=L("Anklicken: Release-Link kopieren"),icon=ICON,color="blue",group="advanced",action=function() CP:OpenReleaseLink() end},
  }
  return rows
end

function CP:RecipeIcon(key,id)
  local recipe=self.db.recipes[key] and self.db.recipes[key][id]
  if recipe and recipe.icon then return recipe.icon end
  if C_Spell and type(C_Spell.GetSpellTexture)=="function" then
    local ok,texture=pcall(C_Spell.GetSpellTexture,id)
    if ok and texture then return texture end
  end
  local cat=self:Catalog(key)
  local record=cat and cat.recipes[id]
  local item=(recipe and recipe.outputItemID) or (record and record.makes)
  if item and C_Item and type(C_Item.GetItemIconByID)=="function" then
    local ok,texture=pcall(C_Item.GetItemIconByID,item)
    if ok and texture then return texture end
  end
  return CP.Data.professionIcons[key] or ICON
end
