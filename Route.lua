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
  return {stock=shallow(s.stock),bought=shallow(s.bought),
    crafted=shallow(s.crafted), spent=s.spent,missing=shallow(s.missing),
    stale=shallow(s.stale),notes=shallow(s.notes),ownedRemaining=shallow(s.ownedRemaining),usedOwned=shallow(s.usedOwned)}
end
local function baseState()
  return {stock={},bought={},crafted={},spent=0,missing={},stale={},notes={},ownedRemaining={},usedOwned={}}
end
local function countSet(t)
  local n=0 for _ in pairs(t) do n=n+1 end return n
end
local function ingredientUnitCost(itemID,owner,skill,active,depth)
  depth=depth or 0
  if depth>8 or active[itemID] then return nil end
  active[itemID]=true
  local current=CP:PriceDetails(itemID).price
  for _,entry in ipairs(CP:RecipesMaking(itemID,owner,skill)) do
    local recipe=entry.recipe
    local total=0
    local possible=true
    for reagent,qty in pairs(recipe.mats or {}) do
      local cost=ingredientUnitCost(reagent,owner,skill,active,depth+1)
      if cost==nil then possible=false;break end
      total=total+cost*qty
    end
    if possible then
      local yield=math.max(1,tonumber(recipe.count or recipe.yield) or 1)
      local each=total/yield
      if current==nil or each<current then current=each end
    end
  end
  active[itemID]=nil
  return current
end

local function cheapestCraftFor(itemID,owner,skill)
  local lowest,lowestTotal
  for _,entry in ipairs(CP:RecipesMaking(itemID,owner,skill)) do
    local total=0
    local valid=true
    local path={[itemID]=true}
    for reagent,qty in pairs(entry.recipe.mats or {}) do
      local unit=ingredientUnitCost(reagent,owner,skill,path,1)
      if unit==nil then valid=false;break end
      total=total+qty*unit
    end
    if valid then
      local yield=math.max(1,tonumber(entry.recipe.count or entry.recipe.yield) or 1)
      total=total/yield
      if not lowestTotal or total<lowestTotal then lowest,lowestTotal=entry,total end
    end
  end
  return lowest,lowestTotal
end

local function consume(st,id,needed,owner,skill,active,depth)
  if needed<=0 then return end
  depth=depth or 0
  if st.stock[id]==nil then
    local total=CP:ItemAvailability(id)
    st.stock[id]=total
  end
  local available=math.min(needed,st.stock[id])
  if st.ownedRemaining[id]==nil then st.ownedRemaining[id]=CP:ItemAvailability(id) end
  local ownedUsed=math.min(available,st.ownedRemaining[id])
  st.ownedRemaining[id]=st.ownedRemaining[id]-ownedUsed
  if ownedUsed>0 then st.usedOwned[id]=(st.usedOwned[id] or 0)+ownedUsed end
  st.stock[id]=st.stock[id]-available
  local short=needed-available
  if short<=0 then return end
  local market=CP:PriceDetails(id)
  local recipe,craftCost
  if depth<8 and not active[id] then
    recipe,craftCost=cheapestCraftFor(id,owner,skill)
  end
  if recipe and craftCost and (not market.price or craftCost < market.price) then
    active[id]=true
    local output=math.max(1,tonumber(recipe.recipe.count or recipe.recipe.yield) or 1)
    local crafts=math.ceil(short/output)
    for reagent,qty in pairs(recipe.recipe.mats) do
      consume(st,reagent,qty*crafts,owner,skill,active,depth+1)
    end
    active[id]=nil
    st.crafted[recipe.id]=(st.crafted[recipe.id] or 0)+crafts
    local surplus=crafts*output-short
    st.stock[id]=st.stock[id]+surplus
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
    trial.stock[output]=(trial.stock[output] or CP:ItemAvailability(output))+crafts*units
  end
  trial.crafted[candidate.id]=(trial.crafted[candidate.id] or 0)+crafts
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

function CP:GenerateAutomaticRoute(key,first,last)
  local from=math.max(1,math.min(299,math.floor(tonumber(first) or 1)))
  local finish=math.max(from+1,math.min(300,math.floor(tonumber(last) or 300)))
  local state=baseState()
  local steps={}
  local skill=from
  local noCandidate
  local assumptions=0
  local catalog=self:Catalog(key)
  if not catalog then return nil,L("Für diesen Beruf ist kein Herstellungs-Katalog vorhanden.") end
  while skill<finish do
    local candidateRows=self:CatalogCandidateRecipes(key,skill)
    local selected,selectedTrial,ranking
    for _,candidate in ipairs(candidateRows) do
      local crafts=math.max(1,math.ceil(1/candidate.chance))
      local trial=evaluate(state,candidate,crafts,key,skill)
      local option={
        unknown=countSet(trial.missing)-countSet(state.missing),
        delta=trial.spent-state.spent,count=crafts,id=candidate.id,
        greenPenalty=(self.db.ui.preferReliableSkill and candidate.chance<.5) and 1 or 0
      }
      -- Unknown material prices must not accidentally win as zero-cost items.
      if option.unknown>0 then option.unknown=1000+countSet(trial.missing) end
      if better(option,ranking) then
        selected,selectedTrial,ranking=candidate,trial,option
      end
    end
    if not selected then noCandidate=skill;break end
    local old=steps[#steps]
    local crafts=ranking.count
    if old and old.id==selected.id then
      old.crafts=old.crafts+crafts
      old.last=skill+1
    else
      steps[#steps+1]={id=selected.id,key=key,name=self:RecipeName(key,selected.id,selected.recipe.name),
        first=skill,last=skill+1,crafts=crafts,
        source=selected.source,uncertain=selected.source~="known"}
    end
    if selected.source~="known" then assumptions=assumptions+1 end
    state=selectedTrial
    skill=skill+1
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
    local rec=catalog.recipes[recipeID] or
      (self:Catalog("mining") and self:Catalog("mining").recipes[recipeID])
    intermediates[#intermediates+1]={id=recipeID,
      name=rec and rec.name or (L("Rezept ")..recipeID),count=count}
  end
  table.sort(intermediates,function(a,b) return a.name<b.name end)
  return {
    first=from,target=finish,reached=skill,steps=steps,materials=materials,
    intermediates=intermediates,
    price=state.spent,unpriced=countSet(state.missing),
    stale=countSet(state.stale),unknownAge=countSet(state.notes),
    assumptions=assumptions,blocked=noCandidate,
    dataset=self.catalogBuild,source=self.catalogUpstream,
    isEstimate=true,ownedMaterials=shallow(state.usedOwned)
  }
end

function CP:BuildRouteForCurrentPlan(key)
  local p=self:PlanFor(key)
  if not p then return false end
  local route,errorText=self:GenerateAutomaticRoute(key,p.start,p.target)
  if not route then return false,errorText end
  p.autoRoute=route
  p.autoMode=true
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
