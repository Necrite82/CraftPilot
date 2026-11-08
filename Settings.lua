-- Original CraftPilot settings and minimap integration; no external libraries.
local _,CP=...
local L=CP.L
local ICON="Interface\\AddOns\\CraftPilot\\Media\\CraftPilot"

function CP:FormatMoney(value)
  if type(value)~="number" then return L("Preis fehlt") end
  local amount=math.max(0,math.floor(value+.5))
  return string.format("%d|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t %d|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t %d|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t",
    math.floor(amount/10000),math.floor(amount%10000/100),amount%100)
end

function CP:InitializeControls()
  local ui=self.db.ui
  if type(ui.minimapAngle)~="number" or ui.minimapAngle~=ui.minimapAngle then ui.minimapAngle=225 end
  if type(ui.hideMinimap)~="boolean" then ui.hideMinimap=false end
  if type(ui.knownRecipesOnly)~="boolean" then ui.knownRecipesOnly=false end
  if type(ui.showSourceDetails)~="boolean" then ui.showSourceDetails=false end
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
    local b=CreateFrame("Button","CraftPilotMinimapButton",Minimap)
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

function CP:ToggleSetting(key)
  if not self.db then return end
  if key=="bank" then self.db.includeBank=not self.db.includeBank
  elseif key=="mode" then self.db.mode=self.db.mode=="cash" and "value" or "cash"
  elseif ({autoOpen=true,showAllProfessions=true,hideMinimap=true,knownRecipesOnly=true,showSourceDetails=true})[key] then
    self.db.ui[key]=not self.db.ui[key]
  else return end
  self.pendingSettingsReset=nil
  if key=="showAllProfessions" and not self.db.ui.showAllProfessions then self:PreferOwnedProfession() end
  self:UpdateMinimapButton()
  -- A different route policy must not leave an old automatic proposal visible.
  if key=="knownRecipesOnly" or key=="bank" or key=="mode" then
    for _,plan in pairs(self.db.plans) do plan.autoRoute=nil;plan.autoMode=nil end
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
  self:UpdateMinimapButton()
  self:Render()
  return true
end

function CP:SettingsCards()
  local ui=self.db.ui
  local toggleKeys={}
  local function toggle(key)
    local action=function() CP:ToggleSetting(key) end
    toggleKeys[action]=key
    return action
  end
  local function enabled(key)
    if key=="bank" then return self.db.includeBank end
    if key=="hideMinimap" then return not ui.hideMinimap end
    return ui[key]==true
  end
  local function state(value) return value and L("AN") or L("AUS") end
  local function card(title,detail,action,icon,footer)
    local row={title=title,detail=detail,footer=footer or L("Anklicken zum Ändern"),action=action,icon=icon or ICON,color="blue"}
    local key=toggleKeys[action]
    if key and key~="mode" then
      row.slider={kind="toggle",key=key,value=enabled(key) and 1 or 0,min=0,max=1,step=1,apply=function(value)
        if (value==1)~=enabled(key) then CP:ToggleSetting(key) end
      end}
      row.footer=L("Schalter ziehen oder anklicken: AN / AUS")
    end
    return row
  end
  local function slider(label,value,min,max,step,unit,apply)
    return {title=label..value..unit,footer=L("Regler ziehen: ")..min..L(" bis ")..max..unit,
      icon=ICON,color="blue",slider={label=label,value=value,min=min,max=max,step=step,unit=unit,apply=apply}}
  end
  return {
    card(L("Sprache: ")..(CP.locale=="deDE" and "Deutsch" or "English"),L("Automatisch nach Clientsprache; andere Sprachen verwenden Englisch."),nil),
    card(L("Minimap-Button: ")..state(not ui.hideMinimap),L("Links öffnet CraftPilot, rechts die Einstellungen; ziehen verschiebt ihn."),toggle("hideMinimap")),
    slider(L("Minimap-Position: "),math.floor(ui.minimapAngle),0,359,1,L(" Grad"),function(value)
      ui.minimapAngle=value;CP:PositionMinimapButton()
    end),
    slider(L("Fensterbreite: "),ui.width,750,1100,10," px",function(value)
      ui.width=value;CP.frame:SetWidth(value)
    end),
    slider(L("Fensterhöhe: "),ui.height,570,930,10," px",function(value)
      ui.height=value;CP.frame:SetHeight(value)
    end),
    card(L("Berufsfenster automatisch öffnen: ")..state(ui.autoOpen),L("Beim Anklicken eines erlernten Berufs; im Kampf möglicherweise gesperrt."),toggle("autoOpen")),
    card(L("Berufsauswahl: ")..(ui.showAllProfessions and L("alle Berufe") or L("eigene zuerst")),L("Weitere Berufe bleiben über die Umschaltung erreichbar."),toggle("showAllProfessions")),
    card(L("Bankbestände berücksichtigen: ")..state(self.db.includeBank),self:BankStatus(),toggle("bank"),"Interface\\Icons\\INV_Misc_Bag_08"),
    card(L("Kostenvergleich: ")..(self.db.mode=="cash" and L("fehlende Materialien") or L("gesamter Materialwert")),L("Zukauf bewertet Fehlmengen; Materialwert bewertet auch eigene Vorräte."),toggle("mode"),"Interface\\Icons\\INV_Misc_Coin_01"),
    card(L("Auto-Route: ")..(ui.knownRecipesOnly and L("nur erlernte Rezepte") or L("Katalogvorschläge zulassen")),L("Katalogvorschläge können noch zu lernende Rezepte enthalten; nur erlernt schränkt sie ein."),toggle("knownRecipesOnly")),
    card(L("Quelldetails: ")..state(ui.showSourceDetails),L("Zusätzlichen Datenstand im Einkaufsplan anzeigen; Unsicherheiten bleiben immer sichtbar."),toggle("showSourceDetails")),
    card(L("Design: ")..ui.skin,L("Automatisch mit EllesmereUI, Dunkel oder Klassisch."),function()
      ui.skin=ui.skin=="auto" and "dark" or (ui.skin=="dark" and "classic" or "auto")
      CP:ApplyTheme();CP:Render()
    end),
    card(L("Rezeptsortierung: ")..({cost=L("Preis"),chance=L("Skillchance"),missing=L("Fehlmenge"),name="Name"})[ui.recipeSort],L("Gilt für die Rezeptauswahl im Bereich Jetzt skillen."),function()
      local nextSort={cost="chance",chance="missing",missing="name",name="cost"}
      ui.recipeSort=nextSort[ui.recipeSort] or "cost";CP:Render()
    end),
    card(L("Berufsdaten aktualisieren"),L("Aktuelles eigenes Berufsfenster und Bestände erneut einlesen."),function() CP:Refresh(true) end),
    card(L("Einkaufsplan öffnen"),L("Bereich und Mengen wählen; bekannte Rezepte hinzufügen oder Auto-Route prüfen."),function() CP:OpenTab("plan") end),
    card(L("Geplante Einkaufsliste im Chat"),L("Materialien des aktuellen mehrstufigen Einkaufsplans ausgeben."),function() CP:PrintPlanShopping(CP.db.view) end),
    card(L("Materialliste des gewählten Rezepts im Chat"),L("Fehlende Materialien für eine Herstellung des gewählten Rezepts ausgeben."),function() CP:ShowShopping() end),
    card(self.pendingSettingsReset and L("Zurücksetzen bestätigen – erneut anklicken") or L("Fenster und Minimap-Position zurücksetzen"),
      L("Stellt Position und Fenstergröße wieder her; Pläne und Rezeptdaten bleiben erhalten."),function() CP:ConfirmWindowReset() end),
    card(L("Bedienung"),L("Beruf wählen → Rezepte prüfen → Einkaufsplan erstellen."),nil,ICON,
      L("Alle Funktionen sind über Schaltflächen erreichbar. Slash-Befehle bleiben optional.")),
  }
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
