-- Current-colour estimates and explicit quantity overrides. Never crafts automatically.
local _,CP=...
local L=CP.L
function CP:RecipeQuantityOverride(key,id)
  local all=self.db.ui.recipeQuantities
  local n=type(all)=="table" and type(all[key])=="table" and all[key][id]
  return type(n)=="number" and n>=1 and n<=9999 and n%1==0 and n or nil
end
function CP:CostQuantityControls(f,context)
  if not rawget(f,"quantityEdit") then
    f.quantityTitle=self:DisplayLabel(f,"GameFontNormalSmall",475,22,52,L("Menge"))
    local function change(value)
      local c=CP.costContext
      if not c or (c.kind~="recipe" and c.kind~="economy") then return end
      if not CP:SetRecipeQuantity(c.key,c.id,value) then f.quantityEdit:SetText(tostring(c.quantity or 1));CP:Say(L("Menge 1–9999 eingeben."));return end
      c.quantity=value;CP:Render();CP:RefreshCostWindow()
    end
    local function button(x,w,label,action)
      local b=CreateFrame("Button",nil,f,"BackdropTemplate");CP:StyleActionButton(b);b:SetSize(w,24);b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-16);b:SetText(label);b:SetScript("OnClick",action);return b
    end
    f.quantityMinus=button(532,24,"-",function() change(math.max(1,(CP.costContext.quantity or 1)-1)) end)
    f.quantityEdit=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.quantityEdit:SetSize(60,24);f.quantityEdit:SetPoint("TOPLEFT",f,"TOPLEFT",567,-16);f.quantityEdit:SetAutoFocus(false);f.quantityEdit:SetNumeric(true)
    f.quantityEdit:SetScript("OnEnterPressed",function(box) box:ClearFocus() end)
    f.quantityEdit:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    f.quantityEdit:SetScript("OnEditFocusLost",function(box)
      local n=tonumber(box:GetText());if n~=CP.costContext.quantity then change(n or 0) end
    end)
    f.quantityPlus=button(637,24,"+",function() change(math.min(9999,(CP.costContext.quantity or 1)+1)) end)
    f.quantitySuggest=button(670,95,L("Vorschlag"),function() local c=CP.costContext;CP:SetRecipeQuantity(c.key,c.id,nil);c.quantity=CP:CraftSuggestion(c.key,c.id).count;CP:Render();CP:RefreshCostWindow() end)
  end
  local show=context.kind=="recipe" or context.kind=="economy"
  for _,name in ipairs({"quantityTitle","quantityMinus","quantityEdit","quantityPlus","quantitySuggest"}) do f[name]:SetShown(show) end
  if show and not f.quantityEdit:HasFocus() then f.quantityEdit:SetText(tostring(context.quantity or 1)) end
end
function CP:SetRecipeQuantity(key,id,value)
  if value~=nil and (type(value)~="number" or value<1 or value>9999 or value%1~=0) then return false end
  self.db.ui.recipeQuantities=self.db.ui.recipeQuantities or {};self.db.ui.recipeQuantities[key]=self.db.ui.recipeQuantities[key] or {}
  self.db.ui.recipeQuantities[key][id]=value;return true
end
function CP:NextRecipeUnlock(key,skill,cap)
  local catalog=self:RecipeVendorCatalog(key)
  local best
  local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  local level=type(UnitLevel)=="function" and UnitLevel("player") or 0
  for id,recipe in pairs(catalog and catalog.recipes or {}) do
    local native=(self.db.recipes[key] or {})[id]
    if not (native and (native.learned or native.disabled)) and not recipe.spec and not recipe.rep and not recipe.cooldown and not recipe.unavailable and not recipe.twin and type(recipe.mats)=="table" and next(recipe.mats) then
      local unlock
      for _,source in ipairs(recipe.get or {}) do
        local at=math.max(recipe.learn or 1,source.skill or source.classicSkill or recipe.learn or 1)
        if (source.kind=="trainer" or source.kind=="start") and at>skill and at<=cap
          and not source.event and not source.rep and not source.otherCost
          and (source.reqLevel or recipe.charLevel or recipe.reqLevel or 0)<=level
          and (not source.faction or source.faction=="AH" or source.faction=="B" or source.faction==(faction=="Horde" and "H" or "A")) then
          if not unlock or at<unlock then unlock=at end
        end
      end
      if unlock and self:SkillPolicyAllows(key,id,recipe,unlock) and self:CatalogSkillChance(recipe,unlock)>=.5 and (not best or unlock<=best.skill) then
        local fee,unknown=self:RecipeAcquisitionCost(key,id,key,unlock)
        local chance=self:CatalogSkillChance(recipe,unlock);local crafts=math.ceil(5/chance);local cost=fee
        for item,n in pairs(recipe.mats or {}) do local price=self:Price(item);if price then cost=cost+price*n*crafts else unknown=true end end
        cost=cost/(crafts*chance)
        if not best or unlock<best.skill or (unlock==best.skill and ((best.unknown and not unknown) or (best.unknown==unknown and (cost<best.cost or (cost==best.cost and id<best.id))))) then best={id=id,skill=unlock,recipe=recipe,cost=cost,unknown=unknown} end
      end
    end
  end
  return best
end
function CP:ExpectedCrafts(key,id,recipe,first,last)
  local casts,reached=0,first
  for skill=first,last-1 do
    local chance=self:RecipeChanceAt(key,id,recipe,skill)
    if chance<=0 or not self:SkillPolicyAllows(key,id,recipe,skill,chance) then break end
    casts=casts+1/chance;reached=skill+1
  end
  return math.min(9999,math.max(1,math.ceil(casts-1e-9))),reached,casts
end
function CP:CraftSuggestion(key,id)
  local p=self.db.professions[key] or {};local current,cap=p.skill or 0,p.cap or 0
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local native=(self.db.recipes[key] or {})[id]
  if not recipe or current>=cap then return {count=1,target=current,reference=false} end
  local planned,nextPlanned=self:ForwardRouteStep(key)
  if planned and planned.id==id then
    local effective={colors=recipe.colors,mats=planned.mats or recipe.mats}
    local count,reached=self:ExpectedCrafts(key,id,effective,current,planned.last)
    if current==planned.first then count=planned.crafts end
    local nextRecipe=nextPlanned and catalog.recipes[nextPlanned.id]
    return {count=count,target=reached,reference=true,planned=true,forward=planned.forward,nextStep=nextRecipe and {id=nextPlanned.id,skill=nextPlanned.first,crafts=nextPlanned.crafts,recipe={colors=nextRecipe.colors,mats=nextPlanned.mats or nextRecipe.mats}} or nil}
  end
  self.unlockCache=self.unlockCache or {}
  local token=key..":"..current..":"..cap
  if self.unlockCache[token]==nil then self.unlockCache[token]=self:NextRecipeUnlock(key,current,cap) or false end
  local nextStep=self.unlockCache[token] or nil
  local colors=recipe.colors
  local fallback=current+1
  if self:ValidSkillColors(colors) then
    if current<colors[3] then fallback=colors[3] elseif current<colors[4] then fallback=colors[4] end
  end
  local target=math.min(cap,nextStep and nextStep.skill or fallback,fallback)
  local count,reached=self:ExpectedCrafts(key,id,recipe,current,math.max(current+1,target))
  return {count=count,target=reached,nextStep=nextStep and nextStep.skill==reached and nextStep or nil,reference=true,
    futureNative=native and native.snapshotSkill~=current or false}
end
function CP:RequestedRecipeQuantity(key,id,fallback)
  return self:RecipeQuantityOverride(key,id) or fallback or self:CraftSuggestion(key,id).count
end
function CP:FollowupNeeds(key,id,quantity,advice)
  local nextStep=advice.nextStep;if not nextStep then return {} end
  local c=self:CostCalculation("recipe",key,id,quantity)
  local currentUse={};for _,m in ipairs(c.materials) do currentUse[m.id]=m.quantity end
  local recipe=nextStep.recipe
  local cap=(self.db.professions[key] or {}).cap or nextStep.skill+1
  local target=math.min(cap,nextStep.skill+10,recipe.colors and recipe.colors[3] or nextStep.skill+1)
  local count=nextStep.crafts or self:ExpectedCrafts(key,nextStep.id,recipe,nextStep.skill,math.max(nextStep.skill+1,target))
  local output=self:RecipeMarketOutput(key,id)
  local native=(self.db.recipes[key] or {})[id]
  local catalog=self:RecipeVendorCatalog(key)
  local current=catalog and catalog.recipes[id]
  local yield=native and native.outputMin or (current and (current.count or current.yield)) or 1
  local rows={}
  for item,n in pairs(recipe.mats or {}) do
    if currentUse[item] or item==output then
      local available=self:AvailableForPlan(item,key)
      local after=math.max(0,available-(currentUse[item] or 0))
      if item==output then after=after+quantity*math.max(0,yield) end
      rows[#rows+1]={id=item,now=currentUse[item] or 0,made=item==output and quantity*math.max(0,yield) or 0,next=n*count,after=after,short=math.max(0,n*count-after),crafts=count,nextID=nextStep.id}
    end
  end
  table.sort(rows,function(a,b) return a.id<b.id end);return rows
end
function CP:QuantityControl(b,key,id,active,y,width)
  if not rawget(b,"quantityLabel") then
    b.quantityLabel=self:DisplayLabel(b,"GameFontDisableSmall",48,0,380,"")
    b.quantityInput=CreateFrame("EditBox",nil,b,"InputBoxTemplate");b.quantityInput:SetSize(62,22);b.quantityInput:SetAutoFocus(false);b.quantityInput:SetNumeric(true)
    b.quantityInput:SetScript("OnEditFocusLost",function(box)
      local n=tonumber(box:GetText());local k,r=box.recipeKey,box.recipeID
      if n and n==CP:RecipeQuantityOverride(k,r) then return end
      if CP:SetRecipeQuantity(k,r,n or -1) then CP:Render() else box:SetText(tostring(CP:RequestedRecipeQuantity(k,r)));CP:Say(L("Menge 1–9999 eingeben.")) end
    end)
    b.quantityInput:SetScript("OnEnterPressed",function(box) box:ClearFocus() end)
    b.quantityInput:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    b.quantityReset=CreateFrame("Button",nil,b,"BackdropTemplate");CP:StyleActionButton(b.quantityReset);b.quantityReset:SetSize(116,22);b.quantityReset:SetText(L("Vorschlag nutzen"))
  end
  local advice=self:CraftSuggestion(key,id)
  b.quantityLabel:Show();b.quantityLabel:ClearAllPoints();b.quantityLabel:SetPoint("TOPLEFT",b,"TOPLEFT",48,-y);b.quantityLabel:SetWidth(width-65)
  b.quantityLabel:SetText((advice.forward and (L("Für Folgeschritte eingeplant · ")) or "")..(advice.target>((self.db.professions[key] or {}).skill or 0) and string.format(L("Vorschlag: ca. %d Herstellungen bis Skill %d"),advice.count,advice.target) or L("Menge frei wählen · kein belastbarer Skillweg")))
  b.quantityInput.recipeKey=key;b.quantityInput.recipeID=id
  b.quantityInput:ClearAllPoints();b.quantityInput:SetPoint("TOPLEFT",b,"TOPLEFT",112,-(y+23))
  b.quantityReset:ClearAllPoints();b.quantityReset:SetPoint("TOPLEFT",b,"TOPLEFT",186,-(y+23))
  if not b.quantityInput:HasFocus() then b.quantityInput:SetText(tostring(self:RequestedRecipeQuantity(key,id))) end
  b.quantityInput:SetShown(active);b.quantityReset:SetShown(active)
  b.quantityReset:SetScript("OnClick",function() CP:SetRecipeQuantity(key,id,nil);CP:Render() end)
  if not rawget(b,"quantityCaption") then b.quantityCaption=self:DisplayLabel(b,"GameFontNormalSmall",48,0,64,L("Menge")) end
  b.quantityCaption:ClearAllPoints();b.quantityCaption:SetPoint("TOPLEFT",b,"TOPLEFT",48,-(y+28));b.quantityCaption:SetShown(active)
  local h=active and y+52 or y+24
  if not rawget(b,"followupNote") then b.followupNote=self:DisplayLabel(b,"GameFontHighlightSmall",48,0,width-65,"") end
  local notes={}
  if active then for _,n in ipairs(self:FollowupNeeds(key,id,self:RequestedRecipeQuantity(key,id),advice)) do
    notes[#notes+1]=n.made>0 and string.format(L("%s: jetzt ca. %d hergestellt · Folgeschritt braucht ca. %d · zusätzlich einplanen %d"),self:ItemName(n.id),n.made,n.next,n.short)
      or string.format(L("%s: jetzt %d · Folgeschritt %d · danach vorhanden ca. %d · zusätzlich %d"),self:ItemName(n.id),n.now,n.next,n.after,n.short)
  end end
  if active and #notes>0 then notes[#notes+1]=advice.planned and L("Folgebedarf aus dem nächsten Schritt deiner gespeicherten Route.") or L("Folgebedarf: Beispiel für bis zu 10 weitere Skillpunkte, keine feste Reservierung.") end
  b.followupNote:SetWidth(width-65);b.followupNote:ClearAllPoints();b.followupNote:SetPoint("TOPLEFT",b,"TOPLEFT",48,-h);b.followupNote:SetText(table.concat(notes,"\n"));b.followupNote:SetShown(#notes>0)
  local measured=b.followupNote:GetStringHeight();if #notes>0 then h=h+(type(measured)=="number" and measured or #notes*16)+8 end
  return h+8
end
