-- Complete browsing of the bundled merchant records, separate from skill recommendations.
local _,CP=...
local L=CP.L
local function factionFits(value)
  local side=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  return not value or value=="AH" or value=="B" or value==(side=="Horde" and "H" or "A")
end
function CP:VendorOfferNotes(vendor)
  local s=vendor.source or {};local notes={}
  if not factionFits(vendor.faction) then notes[#notes+1]=L("Andere Fraktion") end
  if s.reqLevel then notes[#notes+1]=L("Charakterstufe ")..s.reqLevel end
  if s.rep then notes[#notes+1]=L("Rufvoraussetzung prüfen") end
  if s.event then notes[#notes+1]=L("Ereignis: ")..(type(s.event)=="string" and s.event or L("Angebot zeitlich begrenzt")) end
  if s.favor then notes[#notes+1]=L("Merchant's Favor: ")..(type(s.favor)=="number" and s.favor or L("Preis unbekannt")) end
  if s.favorLevel then notes[#notes+1]=L("Favor-Stufe ")..s.favorLevel end
  if s.otherCost then notes[#notes+1]=L("Zusätzliche Währung erforderlich") end
  if vendor.unverified then notes[#notes+1]=L("Zusatzangebot · Voraussetzungen prüfen") end
  return table.concat(notes," · ")
end
function CP:VendorOfferPrice(vendor)
  local s=vendor.source or {}
  if s.otherCost then return L("Zusätzliche Währung erforderlich") end
  if s.favor and not vendor.cost then return L("Merchant's Favor: ")..(type(s.favor)=="number" and s.favor or L("Preis unbekannt")) end
  return vendor.cost and self:FormatCostMoney(vendor.cost) or L("Preis fehlt")
end
function CP:VendorRecipeBrowseOptions(key,query,sort)
  local catalog=self:RecipeVendorCatalog(key);local out={}
  local p=self.db.professions[key];local skill=p and p.skill or 0
  local level=type(UnitLevel)=="function" and UnitLevel("player") or 0
  query=type(query)=="string" and query:lower():match("^%s*(.-)%s*$") or ""
  for id,recipe in pairs(catalog and catalog.recipes or {}) do
    local vendors=self:RecipeVendors(key,id,true)
    if #vendors>0 then
      local native=(self.db.recipes[key] or {})[id];local learned=native and native.learned
      local at=recipe.learn or (recipe.colors and recipe.colors[1]) or 1
      local blocked=false;local notes={}
      if not p or skill<=0 then notes[#notes+1]=L("Beruf noch nicht erlernt");blocked=true
      elseif skill<at then notes[#notes+1]=string.format(L("Berufsskill %d erforderlich · aktuell %d"),at,skill);blocked=true
      else notes[#notes+1]=L("Ab Berufsskill ")..at end
      if (recipe.charLevel or recipe.reqLevel or 0)>level then notes[#notes+1]=L("Charakterstufe ")..(recipe.charLevel or recipe.reqLevel);blocked=true end
      if recipe.rep then notes[#notes+1]=L("Rufvoraussetzung prüfen");blocked=true end
      if recipe.spec then notes[#notes+1]=L("Spezialisierung erforderlich");blocked=true end
      if recipe.unavailable or recipe.twin then notes[#notes+1]=L("Verfügbarkeit ungeklärt");blocked=true end
      local unrestricted=false;for _,v in ipairs(vendors) do if not v.restricted then unrestricted=true end end
      if not unrestricted then notes[#notes+1]=L("Händlerbedingungen beachten");blocked=true end
      if recipe.tools then notes[#notes+1]=L("Werkzeugvoraussetzung prüfen") end
      if recipe.cooldown then notes[#notes+1]=L("Herstellung mit Abklingzeit") end
      local chance=self:RecipeChanceAt(key,id,recipe,skill)
      local status=learned and L("Bereits erlernt") or (blocked and L("Noch nicht nutzbar") or L("Noch nicht gelernt"))
      if skill>=at and chance==0 then status=status..L(" · keine Skillpunkte") end
      local mats={};for item,n in pairs(recipe.mats or {}) do mats[#mats+1]={item,n} end
      local entry={id=id,name=self:RecipeName(key,id,recipe.name),mats=mats,chance=chance,merchantBrowse=true,vendorRecipe=true,
        referenceOnly=true,dimmed=blocked,requiredSkill=at,recipeItem=recipe.item,outputItemID=recipe.item or recipe.makes,
        vendors=vendors,learned=learned,status=status,requirements=table.concat(notes," · ")}
      local words={entry.name,recipe.name or "",recipe.item and self:ItemName(recipe.item) or "",tostring(id),tostring(recipe.item or "")}
      for _,v in ipairs(vendors) do words[#words+1]=v.name;words[#words+1]=v.location and v.location.zone or "" end
      if query=="" or table.concat(words," "):lower():find(query,1,true) then out[#out+1]=entry end
    end
  end
  table.sort(out,function(a,b)
    if sort~="name" and a.requiredSkill~=b.requiredSkill then return a.requiredSkill<b.requiredSkill end
    if a.name~=b.name then return a.name<b.name end
    return a.id<b.id
  end)
  return out
end
local function measured(t,fallback)
  local n=t:GetStringHeight();return type(n)=="number" and n>0 and n or fallback
end
function CP:LayoutVendorRecipeCard(b,key,entry,width)
  for _,name in ipairs({"rangeLabel","stockLabel","marketLabel","stockSummary","quantityLabel","quantityInput","quantityReset","quantityCaption","followupNote"}) do if rawget(b,name) then b[name]:Hide() end end
  for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
  if not rawget(b,"merchantLocation") then
    b.merchantLocation=self:DisplayLabel(b,"GameFontHighlightSmall",48,0,width-65,"")
    b.merchantRequirements=self:DisplayLabel(b,"GameFontDisableSmall",48,0,width-65,"")
    b.merchantWaypoint=CreateFrame("Button",nil,b,"BackdropTemplate");self:StyleActionButton(b.merchantWaypoint);b.merchantWaypoint:SetSize(108,24);b.merchantWaypoint:SetPoint("TOPRIGHT",b,"TOPRIGHT",-8,-8)
    b.merchantWaypoint:SetText(L("Wegpunkt"))
  end
  local v=entry.vendors[1];local location=v.location
  b.nameLabel:SetWidth(width-182);b.nameLabel:SetText(entry.name)
  b.infoLabel:ClearAllPoints();local y=math.max(30,12+measured(b.nameLabel,16));b.infoLabel:SetPoint("TOPLEFT",b,"TOPLEFT",48,-y);b.infoLabel:SetWidth(width-65);b.infoLabel:SetText(entry.status);y=y+measured(b.infoLabel,16)+6
  b.merchantLocation:ClearAllPoints();b.merchantLocation:SetPoint("TOPLEFT",b,"TOPLEFT",48,-y);b.merchantLocation:SetWidth(width-65)
  local place=location and string.format("%s · %.1f / %.1f",location.zone,location.x*100,location.y*100) or L("Standort unbekannt")
  b.merchantLocation:SetText(v.name.." · "..place.." · "..self:VendorOfferPrice(v));b.merchantLocation:Show();y=y+measured(b.merchantLocation,18)+6
  b.merchantRequirements:ClearAllPoints();b.merchantRequirements:SetPoint("TOPLEFT",b,"TOPLEFT",48,-y);b.merchantRequirements:SetWidth(width-65)
  local extra=self:VendorOfferNotes(v)
  b.merchantRequirements:SetText(entry.requirements..(extra~="" and ("\n"..extra) or "")..(#entry.vendors>1 and string.format(L(" · %d Händler · Klick: alle Angebote"),#entry.vendors) or ""));b.merchantRequirements:Show()
  b.merchantWaypoint:SetEnabled(location~=nil);b.merchantWaypoint:SetShown(true)
  b.merchantWaypoint:SetScript("OnClick",function() CP:SetWaypoint(location) end)
  b:SetScript("OnEnter",function() CP:ShowCraftTooltip(b,key,nil,entry.recipeItem or entry.outputItemID) end)
  return y+measured(b.merchantRequirements,18)+12
end
