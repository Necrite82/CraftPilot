-- Cheapest skill path from the current skill to the training cap, point by point.
-- For every skill point the expected cost of each usable recipe is (cost of one craft at AH or vendor
-- prices) / (chance of a point at that skill: orange 100 %, yellow ~70 %, green ~35 %). Own stock is
-- valued at its price, so it never makes a recipe look free; the shopping list subtracts it later.
-- A recipe still to learn adds its fee once, and is only taken when it saves more than it costs.
local _,CP=...
local L=CP.L
local CACHE_SECONDS=30

local function now() return type(GetTime)=="function" and GetTime() or 0 end

-- Price of one item: AH or vendor, else the cost of making it from priced materials (two levels).
local function unitPrice(self,memo,item,depth)
  if memo[item]~=nil then return memo[item] or nil end
  local price=self:PriceDetails(item).price
  if not price and depth<2 and self.RecipesMaking then
    for _,maker in ipairs(self:RecipesMaking(item,self.db.view)) do
      local sum,known=0,true
      for mat,n in pairs(maker.recipe.mats or {}) do
        local p=type(n)=="number" and unitPrice(self,memo,mat,depth+1)
        if not p then known=false;break end
        sum=sum+p*n
      end
      local made=maker.recipe.count or 1
      if known and (not price or sum/made<price) then price=sum/made end
    end
  end
  memo[item]=price or false
  return price
end

local function materials(self,key,id,recipe)
  local native=(self.db.recipes[key] or {})[id]
  local out={}
  if native and type(native.mats)=="table" and #native.mats>0 then
    for _,mat in ipairs(native.mats) do if type(mat[1])=="number" then out[mat[1]]=(out[mat[1]] or 0)+mat[2] end end
  else
    for item,n in pairs(recipe and recipe.mats or {}) do if type(n)=="number" then out[item]=n end end
  end
  return out
end

-- How the recipe is obtained: learned already, or a trainer/vendor with fee and the skill to learn it at.
local function acquisition(self,key,id,recipe,target)
  local native=(self.db.recipes[key] or {})[id]
  if native and native.learned and not native.disabled then return {learned=true,fee=0,at=0} end
  if not recipe or recipe.unavailable or recipe.twin or recipe.spec or recipe.rep or recipe.cooldown then return nil end
  local fee,_,eligible=self:TrainerRecipeFee(key,id,target)
  if eligible then
    local at=recipe.learn or 1
    for _,source in ipairs(recipe.get or {}) do
      if source.kind=="trainer" then at=math.max(at,source.skill or source.classicSkill or at) end
    end
    return {learned=false,fee=fee,feeUnknown=fee==nil,at=at,source="trainer"}
  end
  local cheapest
  for _,vendor in ipairs(self:RecipeVendors(key,id)) do
    if not vendor.restricted and vendor.cost and (not cheapest or vendor.cost<cheapest.cost) then cheapest=vendor end
  end
  if cheapest then return {learned=false,fee=cheapest.cost,at=recipe.learn or 1,source="vendor",vendor=cheapest} end
  return nil
end

function CP:CheapestPath(key)
  local record=self.db and self.db.professions[key]
  local prof=self.Data.professions[key]
  if not record or not prof or (prof.gathering and not prof.crafting) then return nil end
  local skill,target=record.skill or 0,record.cap or 0
  if target<=skill then return nil end
  local token=table.concat({key,skill,target,tostring(self.SkillPolicyToken and self:SkillPolicyToken()),tostring(self.db.ui.knownRecipesOnly)},":")
  local cache=self.pathCache
  if cache and cache.token==token and now()-cache.at<CACHE_SECONDS then return cache.path end

  local catalog=self:RecipeVendorCatalog(key)
  local recipes={}
  for id,r in pairs(catalog and catalog.recipes or {}) do recipes[id]=r end
  local ranges=self.SecondarySkillRanges and self.SecondarySkillRanges[key] or {}
  for id,native in pairs(self.db.recipes[key] or {}) do
    if not recipes[id] and native.learned and ranges[id] then recipes[id]={colors=ranges[id],name=native.name} end
  end

  local memo,candidates,unpriced={},{},0
  for id,recipe in pairs(recipes) do
    local how=acquisition(self,key,id,recipe,target)
    if how and (how.learned or not self.db.ui.knownRecipesOnly) then
      local cost,known=0,true
      for item,n in pairs(materials(self,key,id,recipe)) do
        local p=unitPrice(self,memo,item,0)
        if not p then known=false;break end
        cost=cost+p*n
      end
      if not known or cost<=0 then unpriced=unpriced+1
      else
        local perPoint,chances={},{}
        for k=math.max(skill,how.at or 0),target-1 do
          local chance=self:RecipeChanceAt(key,id,recipe,k)
          if chance>0 and self:SkillPolicyAllows(key,id,recipe,k,chance) then perPoint[k]=cost/chance;chances[k]=chance end
        end
        if next(perPoint) then
          candidates[#candidates+1]={id=id,name=self:RecipeName(key,id,recipe.name),cost=cost,perPoint=perPoint,chances=chances,
            learned=how.learned,fee=how.fee or 0,feeUnknown=how.feeUnknown,source=how.source,vendor=how.vendor}
        end
      end
    end
  end

  -- Best recipe per point among an allowed set; ties go to the higher chance (fewer crafts).
  local function solve(allowed)
    local pick,total={},0
    for k=skill,target-1 do
      local best,bestCost
      for _,c in ipairs(allowed) do
        local v=c.perPoint[k]
        if v and (not bestCost or v<bestCost*0.995 or (v<=bestCost*1.005 and c.chances[k]>best.chances[k])) then best,bestCost=c,v end
      end
      if not best then return pick,total,k end
      pick[k]=best;total=total+bestCost
    end
    return pick,total,target
  end
  local allowed={}
  local pending={}
  for _,c in ipairs(candidates) do if c.learned then allowed[#allowed+1]=c elseif not c.feeUnknown then pending[#pending+1]=c end end
  local pick,total,reached=solve(allowed)
  local fees=0
  -- Add recipes to learn one at a time while one pays for its fee or extends the reachable range.
  -- Adding one recipe can only lower the per-point minimum, so its gain is a single pass over the points.
  for _=1,6 do
    local bestGain,bestIndex
    for i,c in ipairs(pending) do
      local gain,used=0,false
      for k=skill,reached-1 do
        local v=c.perPoint[k]
        local current=pick[k] and pick[k].perPoint[k]
        if v and current and v<current*0.995 then gain=gain+(current-v);used=true end
      end
      if c.perPoint[reached] then gain,used=math.huge,true end
      gain=gain-c.fee
      if used and gain>0 and (not bestGain or gain>bestGain) then bestGain,bestIndex=gain,i end
    end
    if not bestIndex then break end
    local c=table.remove(pending,bestIndex)
    allowed[#allowed+1]=c;fees=fees+c.fee
    pick,total,reached=solve(allowed)
  end

  local segments={}
  for k=skill,reached-1 do
    local c=pick[k]
    local last=segments[#segments]
    if last and last.id==c.id then
      last.last=k+1;last.expected=last.expected+1/c.chances[k];last.cost=last.cost+c.perPoint[k]
    else
      segments[#segments+1]={id=c.id,name=c.name,first=k,last=k+1,expected=1/c.chances[k],cost=c.perPoint[k],
        learned=c.learned,fee=c.learned and 0 or c.fee,source=c.source,vendor=c.vendor,color=self:ReferenceDifficulty(
          (self:RecipeRangeData(key,c.id)),k)}
    end
  end
  -- Count each learned-on-the-way fee once, only for recipes the final path really uses.
  fees=0
  local charged={}
  for _,s in ipairs(segments) do
    s.crafts=math.max(1,math.ceil(s.expected-1e-9))
    if not s.learned and not charged[s.id] then charged[s.id]=true;fees=fees+(s.fee or 0) end
  end
  local perPointNow={}
  for _,c in ipairs(candidates) do perPointNow[c.id]=c.perPoint[skill] end
  local path={key=key,from=skill,target=target,reached=reached,segments=segments,total=total+fees,fees=fees,
    unpriced=unpriced,perPointNow=perPointNow}
  self.pathCache={token=token,at=now(),path=path}
  return path
end

-- Market cost per expected point at the current skill, as used by the path (nil when not priced).
function CP:PathPointCost(key,id)
  local path=self:CheapestPath(key)
  return path and path.perPointNow[id]
end

function CP:PathSummaryLines(path)
  local lines={}
  for _,s in ipairs(path.segments) do
    lines[#lines+1]=string.format(L("Skill %d–%d: ca. %d× %s"),s.first,s.last,s.crafts,s.name)
      ..(s.learned and "" or (" · "..L("lernen")..(s.fee>0 and (" "..self:FormatCostMoney(s.fee)) or "")))
      .."  ·  "..self:FormatCostMoney(s.cost+(s.fee or 0))
  end
  lines[#lines+1]=string.format(L("Gesamt bis %d: ca. %s"),path.reached,self:FormatCostMoney(path.total))
  if path.reached<path.target then lines[#lines+1]=string.format(L("Ab %d fehlen Preise oder Rezepte für einen sicheren Weg."),path.reached) end
  if path.unpriced>0 then lines[#lines+1]=string.format(L("%d Rezepte ohne vollständige Preise nicht verglichen · AH scannen."),path.unpriced) end
  return lines
end
