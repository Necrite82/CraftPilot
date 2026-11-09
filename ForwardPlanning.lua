-- Bounded whole-route comparisons for useful early production. No speculative resale credits.
local _,CP=...
local L=CP.L
local function copy(t) local out={} for k,v in pairs(t or {}) do out[k]=v end return out end
local function casts(route) local n=0 for _,v in ipairs(route.intermediates or {}) do n=n+v.count end return n end
local function cash(route) return route.price+route.learning end
local function better(self,a,b)
  if not a or a.reached<b.reached or a.unpriced>0 then return false end
  if self.db.ui.preferReliableSkill and a.greenPoints>b.greenPoints then return false end
  return cash(a)<cash(b) or (cash(a)==cash(b) and casts(a)<casts(b))
end
local function futureNeeds(route,after)
  local demands,makers={},{}
  for _,s in ipairs(route.intermediates or {}) do if s.output then makers[s.output]=s end end
  local function add(item,n,path,depth)
    demands[item]=(demands[item] or 0)+n
    local maker=makers[item]
    if not maker or path[item] or depth>=8 then return end
    path[item]=true
    local count=math.ceil(n/math.max(1,maker.yield or 1))
    for id,q in pairs(maker.mats or {}) do add(id,q*count,path,depth+1) end
    path[item]=nil
  end
  for _,s in ipairs(route.steps) do if s.first>=after then
    for id,n in pairs(s.mats or {}) do add(id,n*s.crafts,{},0) end
  end end
  return demands
end
local function withReference(self,route,key,first,last,preferences,materialPrefs,work)
  if next(preferences or {}) or next(materialPrefs or {}) then
    local reference=self:GenerateAutomaticRoute(key,first,last,nil,nil,work)
    route.automaticReference=reference and {cash=cash(reference),complete=reference.unpriced==0,reached=reference.reached}
  end
  return route
end
function CP:GenerateAutomaticRoute(key,first,last,preferences,materialPrefs,work)
  local context={candidates={},yield=work and work.yield}
  local base,err=self:GenerateLocalRoute(key,first,last,preferences,materialPrefs,nil,context)
  if not base then return nil,err end
  base.forwardPlan={enabled=self.db.ui.planAhead~=false,trials=0,saved=0,craftsSaved=0}
  if self.db.ui.planAhead==false or base.unpriced>0 then base.forwardPlan.missingPrices=base.unpriced>0;return withReference(self,base,key,first,last,preferences,materialPrefs,work) end
  local best,hints=base,{}
  local attempts,limit=0,24
  local function proposals(route)
    local out={}
    for _,step in ipairs(route.steps) do
      local need=futureNeeds(route,step.last);local seen={}
      for at=step.first,step.last-1 do
        for _,candidate in ipairs(context.candidates[at] or {}) do
          local item=candidate.recipe.makes
          if item and need[item] and need[item]>0 and candidate.id~=step.id and not seen[candidate.id] and not (preferences and preferences[at]) then
            seen[candidate.id]=true
            out[#out+1]={candidate=candidate,first=at,last=step.last,item=item,needed=need[item]}
          end
        end
      end
    end
    return out
  end
  for pass=1,2 do
    local changed=false
    for _,proposal in ipairs(proposals(best)) do
      local c=proposal.candidate
      local finish=proposal.first
      while finish<proposal.last do
        local valid=false
        for _,v in ipairs(context.candidates[finish] or {}) do if v.id==c.id then valid=true;break end end
        if not valid or (preferences and preferences[finish]) then break end
        finish=finish+1
      end
      local wanted=math.max(1,proposal.needed-self:AvailableForPlan(proposal.item,key))
      local effort,neededEnd=0,finish
      for skill=proposal.first,finish-1 do
        effort=effort+1/self:RecipeChanceAt(key,c.id,c.recipe,skill)
        if math.ceil(effort-1e-9)*math.max(1,c.recipe.count or c.recipe.yield or 1)>=wanted then neededEnd=skill+1;break end
      end
      local tried={};local originalHints=copy(hints)
      for _,ending in ipairs({neededEnd,neededEnd-1,finish,proposal.first+1}) do
        if ending>proposal.first and ending<=finish and not tried[ending] then
          tried[ending]=true
          if attempts>=limit then break end
          local choice=copy(originalHints)
          for at=proposal.first,ending-1 do choice[at]=c.id end
          attempts=attempts+1
          local trial=self:GenerateLocalRoute(key,first,last,preferences,materialPrefs,choice,context)
          if better(self,trial,best) then best,hints=trial,choice;changed=true end
          if context.yield then context.yield() end
        end
      end
      if attempts>=limit then break end
    end
    if not changed or attempts>=limit then break end
  end
  best.forwardPlan={enabled=true,trials=attempts,limited=attempts>=limit,saved=cash(base)-cash(best),craftsSaved=casts(base)-casts(best)}
  return withReference(self,best,key,first,last,preferences,materialPrefs,work)
end

local function mapToken(t)
  local rows={} for k,v in pairs(t or {}) do rows[#rows+1]=tostring(k).."="..tostring(v) end
  table.sort(rows);return table.concat(rows,",")
end
function CP:RouteInputSignature(key)
  self:InvalidateReservations()
  local items,definitions={},{}
  for _,profession in ipairs({key,"mining"}) do
    local catalog=self:Catalog(profession)
    for _,r in pairs(catalog and catalog.recipes or {}) do
      for item in pairs(r.mats or {}) do items[item]=true end
      if r.makes then items[r.makes]=true end;if r.item then items[r.item]=true end
    end
    for id,r in pairs(self.db.recipes[profession] or {}) do
      local mats={}
      for _,m in ipairs(r.mats or {}) do items[m[1]]=true;mats[#mats+1]=m[1]..":"..m[2] end
      table.sort(mats)
      definitions[#definitions+1]=table.concat({profession,id,tostring(r.learned),tostring(r.disabled),tostring(r.canSkillUp),tostring(r.difficulty),tostring(r.snapshotSkill),tostring(r.outputItemID),tostring(r.outputMin),tostring(r.colorObservedStart),table.concat(mats,",")},":")
      if r.outputItemID then items[r.outputItemID]=true end
    end
  end
  local ids={} for id in pairs(items) do ids[#ids+1]=id end;table.sort(ids)
  table.sort(definitions)
  local rows={table.concat(definitions,"|"),tostring(type(UnitLevel)=="function" and UnitLevel("player") or 0)}
  for _,id in ipairs(ids) do local p=self:PriceDetails(id);rows[#rows+1]=id..":"..self:AvailableForPlan(id,key)..":"..tostring(p.price)..":"..tostring(p.auction)..":"..tostring(p.ageDays) end
  return table.concat(rows,"|")
end
function CP:CanDeferRouteBuild()
  return type(GetTimePreciseSec)=="function" and C_Timer and type(C_Timer.After)=="function"
end
function CP:RouteBuildPending(key) return self.routeBuildJob and self.routeBuildJob.key==key or false end
function CP:CancelRouteBuild(key)
  if self.routeBuildJob and (not key or self.routeBuildJob.key==key) then self.routeBuildJob=nil end
end
function CP:RequestRouteBuild(key,done)
  if not self:CanDeferRouteBuild() then
    local ok,route=self:BuildRouteForCurrentPlan(key);if ok and done then done(route) end;return ok,route
  end
  local p=self:PlanFor(key)
  if not p or not self:Catalog(key) then return false,L("Für diesen Beruf ist kein Herstellungs-Katalog vorhanden.") end
  local job={key=key,plan=p,db=self.db,first=p.start,last=p.target,preferences=copy(p.preferences),materials=copy(p.materialPreferences),fingerprint=self:PlanFingerprint(key),inputs=self:RouteInputSignature(key)}
  self.routeBuildJob=job
  local slice,iterations=GetTimePreciseSec(),0
  local co=coroutine.create(function()
    return self:GenerateAutomaticRoute(key,job.first,job.last,job.preferences,job.materials,{yield=function()
      iterations=iterations+1
      if iterations>=8 or GetTimePreciseSec()-slice>.01 then iterations=0;coroutine.yield() end
    end})
  end)
  local function resume()
    if self.routeBuildJob~=job then return end
    slice=GetTimePreciseSec()
    local ok,route,err=coroutine.resume(co)
    if not ok then self.routeBuildJob=nil;self:Render();error(route);return end
    if coroutine.status(co)~="dead" then C_Timer.After(.001,resume);return end
    self.routeBuildJob=nil
    if self.db~=job.db or self.db.plans[key]~=p or p.start~=job.first or p.target~=job.last
      or mapToken(p.preferences)~=mapToken(job.preferences) or mapToken(p.materialPreferences)~=mapToken(job.materials)
      or self:PlanFingerprint(key)~=job.fingerprint or self:RouteInputSignature(key)~=job.inputs then
      self:Say(L("Plan oder Bestände während der Berechnung geändert · bitte neu planen."));self:Render();return
    end
    if not route then self:Say(err or L("Plan konnte nicht neu bewertet werden."));self:Render();return end
    p.autoRoute=route;p.autoMode=true;self:InvalidateReservations();self:StampPlan(key)
    self:Render();self:RefreshCostWindow();if done then done(route) end
  end
  C_Timer.After(0,resume)
  return true
end
function CP:ForwardRouteStep(key)
  local p=self.db.plans[key];local route=p and p.autoMode and p.autoRoute
  local skill=(self.db.professions[key] or {}).skill or 0
  if not route or route.plannerVersion~=3 or route.policyToken~=self:SkillPolicyToken() or self:RouteBuildPending(key) then return nil end
  local cache=self.routeAdvice
  if not cache or cache.db~=self.db or cache.route~=route or cache.skill~=skill then
    cache={db=self.db,route=route,skill=skill};self.routeAdvice=cache
    if not self:PlanNeedsReview(key) then
      for i,s in ipairs(route.steps) do if skill>=s.first and skill<s.last then cache.step=s;cache.nextStep=route.steps[i+1];break end end
    end
  end
  return cache.step,cache.nextStep
end
