local _,CP=...
local L=CP.L
function CP:PlanPageCards(key,page)
  local plan=self:PlanFor(key);local route=self:AutoRouteShopping(key)
  local c=self:CostCalculation("plan",key)
  if page=="details" then
    local cards={self:CostSummaryCard("plan",key),self:PlanReviewCard(key),{title=L("Vorräte und Preise"),detail=self:BankStatus(),footer=L("Scanpreise und Skillfarben sind Schätzungen. Ausbildungsränge und Wege ggf. zusätzlich."),color="blue"}}
    if c.stale>0 or c.unknownAge>0 then cards[#cards+1]={title=L("Preiswarnungen"),detail=c.stale..L(" veraltet · ")..c.unknownAge..L(" mit unbekanntem Scan-Alter"),footer=L("Vor Einkäufen Auctionator erneut scannen; Preise variieren."),color="gold"} end
    if route and route.ignoredPreferences and route.ignoredPreferences>0 then cards[#cards+1]={title=L("Nicht passende Vorgaben übersprungen"),detail=L("Für inzwischen ungeeignete Rezepte wurde wieder eine gültige Alternative vorgeschlagen."),color="gold"} end
    if next(plan.preferences or {}) or next(plan.materialPreferences or {}) then cards[#cards+1]={title=L("Alle eigenen Vorgaben zurücksetzen"),detail=L("Wieder automatisch Rezepte und Zwischenprodukte vorschlagen."),action=function() plan.preferences=nil;plan.materialPreferences=nil;CP:BuildRouteForCurrentPlan(key);CP:Render() end,color="gold"} end
    cards[#cards+1]={title=L("Priorität der Vorräte ändern"),detail=L("Bestände zwischen Berufs- und Campingplänen aufteilen."),action=function() CP:OpenTab("reservations") end,color="blue"}
    return cards
  end
  local cards={}
  if self:PlanNeedsReview(key) then cards[#cards+1]=self:PlanReviewCard(key) end
  if route and route.plannerVersion~=2 then cards[#cards+1]={title=L("Gespeicherte Route aktualisieren"),detail=L("Oben Plan erstellen wählen, um Lernkosten und neue Routenvorgaben vollständig neu zu berechnen."),color="gold"} end
  if route and route.blocked then cards[#cards+1]={title=L("Route unvollständig"),detail=string.format(L("Berechnet bis %d statt %d · Rezeptdaten oder Bereich prüfen."),route.reached,route.target),color="gold"} end
  if page=="crafts" then
    local rows={}
    if route then
      local roots={}
      for _,s in ipairs(route.steps) do roots[s.id]=true;rows[#rows+1]={id=s.id,quantity=s.crafts,first=s.first,last=s.last,name=s.name,preferred=s.preferred,automatic=true} end
      for _,s in ipairs(route.intermediates or {}) do if not roots[s.id] then rows[#rows+1]={id=s.id,key=s.key,quantity=s.count,first=s.skill,last=s.skill and s.skill+1,name=s.name,automatic=true,materialID=s.output,units=s.units,intermediate=true} end end
    else
      for _,s in ipairs(self:PlanShopping(key).steps) do rows[#rows+1]={id=s.id,quantity=s.quantity,name=s.name} end
    end
    if #rows==0 then return {{title=L("Noch keine Herstellungen geplant"),detail=L("Oben einen Bereich planen oder in Jetzt skillen ein Rezept wählen und hier hinzufügen."),color="blue"}} end
    if route and ((route.preferencesApplied or 0)>0 or next(plan.materialPreferences or {})) then
      local baseline=self:GenerateAutomaticRoute(key,plan.start,plan.target)
      local b=baseline and self:CostCalculation("plan",key,nil,nil,baseline)
      cards[#cards+1]={title=L("Deine Rezeptwahl · Rest der Route neu berechnet"),
        detail=b and b.cashComplete and c.cashComplete and (L("Mehr-/Minderkosten zum automatischen Vorschlag: ")..self:FormatCostMoney(c.cash-b.cash)) or L("Preisvergleich unvollständig · Details prüfen"),
        footer=L("Empfehlung bleibt eine Schätzung, kein garantiertes globales Optimum."),color="gold"}
    end
    cards[#cards+1]={productionRows=rows,recipeKey=key};return cards
  end
  if not route and not next(plan.crafts) then return {{title=L("1. Bereich wählen → 2. Plan erstellen → 3. Einkaufen"),
    detail=L("Die Route und alle fehlenden Zutaten werden für den gewählten Skillbereich berechnet."),footer=L("Unter Herstellen kannst du die Rezeptschritte anschließend austauschen."),color="blue"}} end
  local rows={};for _,m in ipairs(c.materials) do if m.missing>0 then rows[#rows+1]=m end end
  if #rows==0 then cards[#cards+1]={title=L("Alles für diesen Plan vorhanden"),detail=L("Keine zusätzlichen Materialkäufe erkannt. Unbekannte Angaben unter Details beachten."),color="green"}
  else cards[#cards+1]={materialTable=rows} end
  if not c.cashComplete then cards[#cards+1]={title=L("Kalkulation unvollständig"),detail=L("Fehlende Preise oder Rezeptangaben unter Details prüfen."),color="gold"} end
  return cards
end
function CP:DrawProductionTable(parent,rows,key,width)
  parent.productionRows=rawget(parent,"productionRows") or {};parent.productionHeaders=rawget(parent,"productionHeaders") or {}
  local cols={{L("Rezept"),.43},{L("Skill"),.15},{L("Menge"),.12},{L("Status"),.19},{"",.11}}
  local x=8
  for i,c in ipairs(cols) do local t=parent.productionHeaders[i] or self:DisplayLabel(parent,"GameFontNormalSmall",0,0,50,"");parent.productionHeaders[i]=t;t:ClearAllPoints();t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-4);t:SetWidth(width*c[2]-8);t:SetText(c[1]);t:Show();x=x+width*c[2] end
  for _,r in ipairs(parent.productionRows) do r:Hide() end
  local y=28
  for i,row in ipairs(rows) do
    local r=parent.productionRows[i]
    if not r then r=self:CreateFlatAction(parent,width,52,function() end);r.cells={};r.edit=CreateFrame("Button",nil,r,"BackdropTemplate");self:StyleActionButton(r.edit);r.edit:SetSize(68,24);r.edit:SetPoint("RIGHT",r,"RIGHT",-6,0);parent.productionRows[i]=r end
    local recipeKey=row.key or key
    local native=(self.db.recipes[recipeKey] or {})[row.id]
    local values={row.name,row.intermediate and L("Zwischenprodukt") or (row.first and (row.first.."–"..row.last) or "—"),tostring(row.quantity),row.preferred and L("Deine Wahl") or (native and native.learned and L("Erlernt") or L("Noch lernen"))}
    x=8
    for j=1,4 do local t=r.cells[j] or self:DisplayLabel(r,"GameFontHighlightSmall",0,0,50,"");r.cells[j]=t;t:ClearAllPoints();t:SetPoint("TOPLEFT",r,"TOPLEFT",x,-12);t:SetWidth(width*cols[j][2]-8);t:SetText(values[j]);x=x+width*cols[j][2] end
    local measured=r.cells[1]:GetStringHeight();local h=math.max(52,(type(measured)=="number" and measured or 16)+24)
    r:ClearAllPoints();r:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-y);r:SetSize(width,h);r:Show()
    local record=row
    r:SetScript("OnClick",function() if native and native.learned then CP:OpenLearnedRecipe(recipeKey,record.id) else CP:OpenCostCalculation("recipe",recipeKey,record.id,record.quantity) end end)
    r:SetScript("OnEnter",function() CP:ShowCraftTooltip(r,recipeKey,record.id) end);r:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    r.edit:SetText(row.automatic and L("Ändern") or L("Entfernen"))
    r.edit:SetEnabled(not record.intermediate or record.materialID~=nil)
    r.edit:SetScript("OnClick",function() if record.automatic then CP:OpenRouteAlternatives(key,record.first,record.last,record.materialID,record.units) else CP:ClearPlanCraft(key,record.id);CP:Render() end end)
    y=y+h+4
  end
  parent:SetSize(width,y);return y
end
function CP:ChooseRouteRecipe(key,first,last,id)
  local p=self:PlanFor(key)
  local valid=id==nil
  for _,c in ipairs(self:CatalogCandidateRecipes(key,first)) do if c.id==id then valid=true end end
  if not valid then return false end
  local previous=p.preferences;local prefs={};for s,r in pairs(previous or {}) do prefs[s]=r end
  for s=math.max(p.start,first),math.min(p.target,last)-1 do prefs[s]=id end
  p.preferences=prefs
  local ok=self:BuildRouteForCurrentPlan(key)
  if not ok then p.preferences=previous;return false end
  return true
end
function CP:ChooseMaterialRecipe(key,item,id,skill)
  local valid=id==nil or id==0
  for _,c in ipairs(self:RecipesMaking(item,key,skill)) do if c.id==id then valid=true end end
  if not valid then return false end
  local p=self:PlanFor(key);local old=p.materialPreferences;local prefs={};for k,v in pairs(old or {}) do prefs[k]=v end
  prefs[item]=id;p.materialPreferences=prefs
  if not self:BuildRouteForCurrentPlan(key) then p.materialPreferences=old;return false end
  return true
end
function CP:OpenRouteAlternatives(key,first,last,materialItem,units)
  local f=self.routeChooser
  if not f then
    f=CreateFrame("Frame","CraftPilotRouteChooser",UIParent,"BackdropTemplate");f:SetSize(780,590);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});f:SetBackdropColor(.035,.055,.075,.99);f:SetBackdropBorderColor(.3,.45,.55,1)
    f.title=self:DisplayLabel(f,"GameFontNormalLarge",22,20,710,"")
    self:DisplayLabel(f,"GameFontDisableSmall",22,55,710,L("Rezept wählen: Der Rest der Route und der Einkauf werden neu berechnet. Preise für diesen Schritt sind nur eine Vorschau."))
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",f,"TOPLEFT",22,-100);scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-44,68)
    f.list=CreateFrame("Frame",nil,scroll);f.list:SetSize(710,100);scroll:SetScrollChild(f.list);f.rows={}
    f.reset=CreateFrame("Button",nil,f,"BackdropTemplate");self:StyleActionButton(f.reset);f.reset:SetSize(260,26);f.reset:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,20);f.reset:SetText(L("Automatische Empfehlung verwenden"))
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-5,-5);close:SetScript("OnClick",function() f:Hide() end)
    UISpecialFrames[#UISpecialFrames+1]="CraftPilotRouteChooser";self.routeChooser=f
  end
  f.title:SetText(materialItem and (L("Zwischenprodukt: ")..self:ItemName(materialItem)) or string.format(L("Rezept für Skill %d–%d austauschen"),first,last))
  f.reset:SetScript("OnClick",function() if materialItem then CP:ChooseMaterialRecipe(key,materialItem,nil,first) else CP:ChooseRouteRecipe(key,first,last,nil) end;f:Hide();CP:Render() end)
  for _,r in ipairs(f.rows) do r:Hide() end
  local entries={}
  local candidates=materialItem and self:RecipesMaking(materialItem,key,first) or self:CatalogCandidateRecipes(key,first)
  for _,c in ipairs(candidates) do
    local recipeKey=c.key or key
    local count,reached=self:ExpectedCrafts(recipeKey,c.id,c.recipe,first,last)
    if materialItem then count=math.max(1,math.ceil((units or 1)/math.max(1,c.recipe.count or c.recipe.yield or 1)));reached=first end
    local req={};for id,n in pairs(c.recipe.mats or {}) do req[id]=n*count end
    local fee,unknown,age,auction,book=self:RecipeAcquisitionCost(recipeKey,c.id,key,first);if book then req[book]=(req[book] or 0)+1 end
    local estimate=self:CalculateMaterialCosts(req,fee,unknown,key)
    entries[#entries+1]={id=c.id,key=recipeKey,name=self:RecipeName(recipeKey,c.id,c.recipe.name),chance=c.chance,count=count,reached=reached,cost=estimate}
  end
  if materialItem then
    local p=self:PriceDetails(materialItem);local n=math.max(1,units or 1)
    entries[#entries+1]={id=0,key=key,name=L("Kaufen statt herstellen"),count=n,reached=first,cost={cash=(p.price or 0)*n,cashComplete=p.price~=nil}}
  end
  table.sort(entries,function(a,b) if a.cost.cashComplete~=b.cost.cashComplete then return a.cost.cashComplete end;if a.cost.cash~=b.cost.cash then return a.cost.cash<b.cost.cash end;return a.id<b.id end)
  for i,c in ipairs(entries) do
    local r=f.rows[i]
    if not r then r=self:CreateFlatAction(f.list,710,68,function() end);r.title=self:DisplayLabel(r,"GameFontHighlight",12,10,680,"");r.note=self:DisplayLabel(r,"GameFontDisableSmall",12,36,680,"");f.rows[i]=r end
    r:ClearAllPoints();r:SetPoint("TOPLEFT",f.list,"TOPLEFT",0,-(i-1)*72);r.title:SetText(c.name)
    r.note:SetText(c.id==0 and (c.count..L(" Stück · Zukauf: ")..self:DisplayMoney(c.cost.cash)..(c.cost.cashComplete and "" or " + ?")) or ((c.chance and (math.floor(c.chance*100).."% · ") or "")..c.count..L(" Herstellungen · Zukauf + Lernen: ")..self:DisplayMoney(c.cost.cash)..(c.cost.cashComplete and "" or " + ?")..L(" · Vorschau bis Skill ")..c.reached))
    local id=c.id;local candidateKey=c.key;r:SetScript("OnClick",function()
      local ok;if materialItem then ok=CP:ChooseMaterialRecipe(key,materialItem,id,first) else ok=CP:ChooseRouteRecipe(key,first,last,id) end
      if ok then f:Hide();CP:Render() end
    end)
    r:SetScript("OnEnter",function() CP:ShowCraftTooltip(r,candidateKey,id~=0 and id or nil,materialItem) end);r:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end);r:Show()
  end
  f.list:SetHeight(math.max(80,#entries*72));f:Show()
end
