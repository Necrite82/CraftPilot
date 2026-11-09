-- CraftPilot: prospective profession routes and recursive make-or-buy costs.
-- Original implementation; recipe records are GPL-3.0 data with separate credits.
local _,CP=...
local L=CP.L
local function shallow(t)
  local out={}
  for k,v in pairs(t or {}) do out[k]=v end
  return out
end
local function stateClone(s)
  return {skillEffort=shallow(s.skillEffort),stock=shallow(s.stock),bought=shallow(s.bought),
    crafted=shallow(s.crafted), spent=s.spent,missing=shallow(s.missing),
    stale=shallow(s.stale),notes=shallow(s.notes),ownedRemaining=shallow(s.ownedRemaining),usedOwned=shallow(s.usedOwned),materialPrefs=s.materialPrefs,producerKeys=shallow(s.producerKeys),producerSkills=shallow(s.producerSkills),producerRecipes=shallow(s.producerRecipes),ignoredMaterials=shallow(s.ignoredMaterials),training=s.training,feesCharged=shallow(s.feesCharged),learningUnknown=shallow(s.learningUnknown)}
end
local function baseState(materialPrefs)
  return {skillEffort={},stock={},bought={},crafted={},spent=0,missing={},stale={},notes={},ownedRemaining={},usedOwned={},materialPrefs=materialPrefs,producerKeys={},producerSkills={},producerRecipes={},ignoredMaterials={},training=0,feesCharged={},learningUnknown={}}
end
local function countSet(t)
  local n=0 for _ in pairs(t) do n=n+1 end return n
end
local function chargeLearning(st,key,id,skill)
  local marker=key..":"..id
  if st.feesCharged[marker] then return end
  local fee,unknown=CP:RecipeAcquisitionCost(key,id,key,skill)
  st.training=st.training+fee;st.feesCharged[marker]=true
  if unknown then st.learningUnknown[marker]=true end
end

local function consume(st,id,needed,owner,skill,active,depth)
  if needed<=0 then return end
  depth=depth or 0
  if st.stock[id]==nil then
    local total=CP:AvailableForPlan(id,owner)
    st.stock[id]=total
  end
  local available=math.min(needed,st.stock[id])
  if st.ownedRemaining[id]==nil then st.ownedRemaining[id]=CP:AvailableForPlan(id,owner) end
  local ownedUsed=math.min(available,st.ownedRemaining[id])
  st.ownedRemaining[id]=st.ownedRemaining[id]-ownedUsed
  if ownedUsed>0 then st.usedOwned[id]=(st.usedOwned[id] or 0)+ownedUsed end
  st.stock[id]=st.stock[id]-available
  local short=needed-available
  if short<=0 then return end
  local market=CP:PriceDetails(id)
  local preference=st.materialPrefs and st.materialPrefs[id]
  local chosen,chosenState,chosenCost,chosenUnknown
  if depth<8 and not active[id] and preference~=0 then
    active[id]=true
    for _,recipe in ipairs(CP:RecipesMaking(id,owner,skill)) do
      local trial=stateClone(st)
      local output=math.max(1,tonumber(recipe.recipe.count or recipe.recipe.yield) or 1)
      local crafts=math.ceil(short/output)
      local at=recipe.key==owner and skill or (CP.db.professions[recipe.key] or {}).skill
      chargeLearning(trial,recipe.key,recipe.id,at)
      for reagent,qty in pairs(recipe.recipe.mats or {}) do consume(trial,reagent,qty*crafts,owner,skill,active,depth+1) end
      trial.crafted[recipe.id]=(trial.crafted[recipe.id] or 0)+crafts
      trial.producerRecipes[recipe.id]=recipe.recipe
      trial.producerKeys[recipe.id]=recipe.key;trial.producerSkills[recipe.id]=trial.producerSkills[recipe.id] or at
      trial.stock[id]=trial.stock[id]+crafts*output-short
      local cost=trial.spent+trial.training-st.spent-st.training
      local unknown=countSet(trial.missing)+countSet(trial.learningUnknown)-countSet(st.missing)-countSet(st.learningUnknown)
      local preferred=preference==recipe.id
      local bestPreferred=chosen and preference==chosen.id
      if not chosen or (preferred and not bestPreferred) or (preferred==bestPreferred and (unknown<chosenUnknown or (unknown==chosenUnknown and (cost<chosenCost or (cost==chosenCost and recipe.id<chosen.id))))) then
        chosen,chosenState,chosenCost,chosenUnknown=recipe,trial,cost,unknown
      end
    end
    active[id]=nil
  end
  if preference and preference~=0 and (not chosen or chosen.id~=preference) then st.ignoredMaterials[id]=true end
  if chosen and (preference==chosen.id or (chosenUnknown==0 and (not market.price or chosenCost<market.price*short))) then
    if preference and preference~=0 and chosen.id~=preference then chosenState.ignoredMaterials[id]=true end
    for k,v in pairs(chosenState) do st[k]=v end
  else
    st.bought[id]=(st.bought[id] or 0)+short
    if market.price then st.spent=st.spent+market.price*short
    else st.missing[id]=true end
    if market.freshness=="aging" or market.freshness=="stale" then st.stale[id]=true end
    if market.freshness=="unknown" then st.notes[id]=true end
  end
end

local function evaluate(st,candidate,crafts,owner,skill)
  local trial=stateClone(st)
  for reagent,qty in pairs(candidate.recipe.mats or {}) do
    consume(trial,reagent,qty*crafts,owner,skill,{},0)
  end
  local output=candidate.recipe.makes
  if type(output)=="number" then
    local units=math.max(1,tonumber(candidate.recipe.count or candidate.recipe.yield) or 1)
    trial.stock[output]=(trial.stock[output] or CP:AvailableForPlan(output,owner))+crafts*units
  end
  trial.crafted[candidate.id]=(trial.crafted[candidate.id] or 0)+crafts
  trial.producerRecipes[candidate.id]=candidate.recipe
  trial.producerKeys[candidate.id]=owner;trial.producerSkills[candidate.id]=trial.producerSkills[candidate.id] or skill
  chargeLearning(trial,owner,candidate.id,skill)
  return trial
end

local function better(a,b)
  if not b then return true end
  if a.unknown~=b.unknown then return a.unknown<b.unknown end
  if (a.greenPenalty or 0)~=(b.greenPenalty or 0) then return (a.greenPenalty or 0)<(b.greenPenalty or 0) end
  if a.delta~=b.delta then return a.delta<b.delta end
  if a.count~=b.count then return a.count<b.count end
  return a.id<b.id
end

function CP:GenerateLocalRoute(key,first,last,preferences,materialPrefs,hints,context)
  self:InvalidateReservations()
  local from=math.max(1,math.min(299,math.floor(tonumber(first) or 1)))
  local finish=math.max(from+1,math.min(300,math.floor(tonumber(last) or 300)))
  local state=baseState(materialPrefs)
  local steps={}
  local skill=from
  local noCandidate
  local assumptions,greenPoints=0,0
  local ignoredPreferences={}
  local preferencesApplied=0
  local catalog=self:Catalog(key)
  if not catalog then return nil,L("Für diesen Beruf ist kein Herstellungs-Katalog vorhanden.") end
  while skill<finish do
    local candidateRows
    if context then
      candidateRows=context.candidates[skill]
      if not candidateRows then candidateRows=self:CatalogCandidateRecipes(key,skill);context.candidates[skill]=candidateRows end
    else candidateRows=self:CatalogCandidateRecipes(key,skill) end
    local desired=(preferences and preferences[skill]) or (hints and hints[skill])
    local selected,selectedTrial,ranking
    for _,candidate in ipairs(candidateRows) do
      local effort=state.skillEffort[candidate.id] or 0
      local nextEffort=effort+1/candidate.chance
      local crafts=math.max(1,math.ceil(nextEffort-1e-9)-math.ceil(effort-1e-9))
      local trial=evaluate(state,candidate,crafts,key,skill)
      trial.skillEffort[candidate.id]=nextEffort
      local quote,points=trial,1
      local colors=candidate.recipe.colors
      local horizon=finish
      if colors then horizon=math.min(horizon,skill<(colors[3] or skill) and colors[3] or colors[4] or finish) end
      if preferences then for at=skill+1,horizon-1 do if preferences[at] and preferences[at]~=candidate.id then horizon=at;break end end end
      if CP.ExpectedCrafts and horizon>skill+1 then
        local batch,reached,exact=CP:ExpectedCrafts(key,candidate.id,candidate.recipe,skill,horizon)
        if exact then batch=math.max(1,math.ceil(effort+exact-1e-9)-math.ceil(effort-1e-9)) end
        if reached>skill+1 then quote=evaluate(state,candidate,batch,key,skill);points=reached-skill end
      end
      local option={
        preferred=desired==candidate.id,userPreferred=preferences and preferences[skill]==candidate.id or false,forward=hints and hints[skill]==candidate.id and not (preferences and preferences[skill]) or false,
        unknown=countSet(quote.missing)-countSet(state.missing)+countSet(quote.learningUnknown)-countSet(state.learningUnknown),
        delta=(quote.spent+quote.training-state.spent-state.training)/points,count=crafts,id=candidate.id,
        greenPenalty=(self.db.ui.preferReliableSkill and candidate.chance<.5) and 1 or 0
      }
      -- Unknown material prices must not accidentally win as zero-cost items.
      if option.unknown>0 then option.unknown=1000+countSet(quote.missing)+countSet(quote.learningUnknown) end
      if not ranking or (option.preferred and not ranking.preferred) or (option.preferred==ranking.preferred and better(option,ranking)) then
        selected,selectedTrial,ranking=candidate,trial,option
      end
    end
    if preferences and preferences[skill] and not (ranking and ranking.preferred) then ignoredPreferences[skill]=preferences[skill] end
    if not selected then noCandidate=skill;break end
    if ranking.userPreferred then preferencesApplied=preferencesApplied+1 end
    if selected.chance<.5 then greenPoints=greenPoints+1 end
    local old=steps[#steps]
    local crafts=ranking.count
    if old and old.id==selected.id then
      old.crafts=old.crafts+crafts
      old.last=skill+1;old.preferred=old.preferred or ranking.userPreferred;old.forward=old.forward or ranking.forward
    else
      steps[#steps+1]={id=selected.id,key=key,name=self:RecipeName(key,selected.id,selected.recipe.name),
        first=skill,last=skill+1,crafts=crafts,
        source=selected.source,uncertain=selected.source~="known",preferred=ranking.userPreferred,forward=ranking.forward,
        mats=shallow(selected.recipe.mats),output=selected.recipe.makes,yield=selected.recipe.count or selected.recipe.yield or 1}
    end
    if selected.source~="known" then assumptions=assumptions+1 end
    state=selectedTrial
    skill=skill+1
    if context and context.yield then context.yield() end
  end
  local materials={}
  for itemID,quantity in pairs(state.bought) do
    local info=self:PriceDetails(itemID)
    materials[#materials+1]={
      id=itemID,name=self:ItemName(itemID),missing=quantity,
      price=info.price,cost=info.price and quantity*info.price or nil,
      freshness=info.freshness,ageDays=info.ageDays,source=info.source
    }
  end
  table.sort(materials,function(a,b) return a.name<b.name end)
  local intermediates={}
  for recipeID,count in pairs(state.crafted) do
    local producerKey=state.producerKeys[recipeID] or key
    local rec=state.producerRecipes[recipeID] or (self:Catalog(producerKey) and self:Catalog(producerKey).recipes[recipeID]) or catalog.recipes[recipeID] or
      (self:Catalog("mining") and self:Catalog("mining").recipes[recipeID])
    intermediates[#intermediates+1]={id=recipeID,key=producerKey,skill=state.producerSkills[recipeID],output=rec and rec.makes,units=rec and (rec.count or rec.yield or 1)*count,
      name=rec and rec.name or (L("Rezept ")..recipeID),count=count,mats=rec and shallow(rec.mats),yield=rec and (rec.count or rec.yield or 1)}
  end
  table.sort(intermediates,function(a,b) return a.name<b.name end)
  return {
    first=from,target=finish,reached=skill,steps=steps,materials=materials,plannerVersion=3,greenPoints=greenPoints,policyToken=self:SkillPolicyToken(),
    intermediates=intermediates,
    price=state.spent,learning=state.training,unpriced=countSet(state.missing)+countSet(state.learningUnknown),
    stale=countSet(state.stale),unknownAge=countSet(state.notes),
    assumptions=assumptions,blocked=noCandidate,preferencesApplied=preferencesApplied,ignoredPreferences=countSet(ignoredPreferences)+countSet(state.ignoredMaterials),
    dataset=self.catalogBuild,source=self.catalogUpstream,
    isEstimate=true,ownedMaterials=shallow(state.usedOwned)
  }
end

function CP:BuildRouteForCurrentPlan(key)
  local p=self:PlanFor(key)
  if not p then return false end
  local route,errorText=self:GenerateAutomaticRoute(key,p.start,p.target,p.preferences,p.materialPreferences)
  if not route then return false,errorText end
  p.autoRoute=route
  p.autoMode=true
  self:InvalidateReservations();self:StampPlan(key)
  return true,route
end

function CP:AutoRouteShopping(key)
  local p=self:PlanFor(key)
  return p and p.autoMode and p.autoRoute
end

function CP:PrintRouteShopping(key)
  local route=self:AutoRouteShopping(key)
  if not route then return false end
  self:Say(string.format(L("Auto-Entwurf %d–%d, vorläufig bis %d, %d Rezeptschritte."),
    route.first,route.target,route.reached,#route.steps))
  for _,mat in ipairs(route.materials) do
    local info=self:FormatMoney(mat.cost)
    self:Say(string.format("%d x %s – %s (%s)",mat.missing,mat.name,info,
      self:PriceFreshness(mat.id)))
  end
  if route.blocked then self:Say(L("ABBRUCH: Ab Skill ")..route.blocked..L(" kein geeignetes zugängliches Rezept bekannt.")) end
  self:Say(L("Schätzung mit GPL-3.0-Katalog; Trainer/Farben/Preise und zukünftige Verfügbarkeit prüfen."))
  return true
end
