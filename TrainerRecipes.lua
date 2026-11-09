-- Unlearned trainer recipes are proposals, never treated as learned crafts.
local _,CP=...
local L=CP.L
function CP:TrainerRecipeFee(key,id)
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local prof=self.db.professions[key]
  if not recipe or not prof or recipe.spec or recipe.rep or recipe.unavailable or recipe.twin then return nil end
  local level=type(UnitLevel)=="function" and UnitLevel("player") or 0
  if (recipe.charLevel or recipe.reqLevel or 0)>level then return nil end
  local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  local best,uncertain,eligible
  for _,source in ipairs(recipe.get or {}) do
    local at=math.max(recipe.learn or 1,source.skill or source.classicSkill or recipe.learn or 1)
    if source.kind=="trainer" and at<=prof.skill and not source.event and not source.otherCost and not source.rep
      and (not source.faction or source.faction=="AH" or source.faction=="B" or source.faction==(faction=="Horde" and "H" or "A"))
      and (not source.reqLevel or source.reqLevel<=(type(UnitLevel)=="function" and UnitLevel("player") or 0)) then
      eligible=true
      local cost=source.cost
      if type(cost)=="number" and cost>=0 and (not best or cost<best) then
        best=cost;uncertain=source.costGuess==true or recipe.guess==true
      end
    end
  end
  return best,uncertain,eligible
end
function CP:AllRecipeOptions(key,learned,offers)
  local out,seen={},{}
  for _,rows in ipairs({learned,offers}) do for _,entry in ipairs(rows) do out[#out+1]=entry;seen[entry.id]=true end end
  local catalog=self:RecipeVendorCatalog(key)
  local recipes={}
  for id,r in pairs(catalog and catalog.recipes or {}) do recipes[id]=r end
  for id,r in pairs(self.db.recipes[key] or {}) do if not recipes[id] then recipes[id]=r end end
  local skill=(self.db.professions[key] or {}).skill or 0
  local remaining={}
  for id,recipe in pairs(recipes) do if not seen[id] then
    local native=(self.db.recipes[key] or {})[id]
    local at=recipe.learn or (recipe.colors and recipe.colors[1]) or 1
    local mats={};for item,n in pairs(recipe.mats or {}) do
      if type(n)=="number" then mats[#mats+1]={item,n} end
    end
    remaining[#remaining+1]={id=id,name=self:RecipeName(key,id,recipe.name),mats=mats,chance=0,cost=0,missing=0,unknown=true,
      vendorRecipe=not (native and native.learned),referenceOnly=true,dimmed=true,requiredSkill=at,
      referenceStatus=(native and native.learned and L("Bereits erlernt · aktuell keine Skilloption") or L("Noch nicht gelernt"))..L(" · ab Skill ")..at
        ..(at>skill and L(" · zukünftig") or L(" · Lernquelle im Berufsfenster prüfen"))}
  end end
  table.sort(remaining,function(a,b) if a.requiredSkill~=b.requiredSkill then return a.requiredSkill<b.requiredSkill end;return a.id<b.id end)
  for _,entry in ipairs(remaining) do out[#out+1]=entry end
  return out
end
function CP:TrainerProposalCards(key)
  local cards={}
  for _,entry in ipairs(self:TrainerRecipeOptions(key)) do
    local c=entry.comparison
    local target=entry.vendors[1]
    local money=type(GetMoney)=="function" and GetMoney()
    local funds=type(money)=="number" and c.cost.cashComplete and money<c.cost.cash and (L(" · Gold fehlt: ")..self:FormatCostMoney(c.cost.cash-money)) or ""
    cards[#cards+1]={title=L("LEHRERREZEPT: ")..entry.name,
      detail=L("Lernen + Material-Zukauf: ")..(c.cost.cashComplete and self:FormatCostMoney(c.cost.cash) or L("unvollständig"))..funds..L(" · Vergleich bei heutiger Skillfarbe (ca. 5 Punkte)"),
      footer=(c.cashSaving and c.cashSaving>0 and (L("Möglicher Zukaufvorteil/Punkt: ")..self:FormatCostMoney(c.cashSaving)) or L("Kein gesicherter Zukaufvorteil"))
        .." · "..(target and (target.name..L(" · Klick: Wegpunkt")) or L("Lehrerstandort unbekannt")),color=c.cashSaving and c.cashSaving>0 and "gold" or "blue",
      action=target and function() CP:SetWaypoint(target.location) end or nil}
  end
  return cards
end
function CP:RecipeTeachers(key,id)
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local fee,uncertain,eligible=self:TrainerRecipeFee(key,id)
  if not eligible then return {} end
  local out={}
  local function add(npc,identity)
    local location=npc
    if identity then
      location=self:QuestieNpcLocation(identity,npc) or npc
    end
    out[#out+1]={name=location.name,location=location,cost=not uncertain and fee or nil}
  end
  if recipe.trainers then
    for _,npcID in ipairs(recipe.trainers) do
      local npc=(catalog.npcs or {})[npcID]
      local side=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
      if npc and (not npc.faction or npc.faction=="AH" or npc.faction=="B" or npc.faction==(side=="Horde" and "H" or "A"))
        and type(npc.map)=="number" and npc.map>0 and type(npc.x)=="number" and type(npc.y)=="number"
        and npc.x>=0 and npc.x<=100 and npc.y>=0 and npc.y<=100 then
        add({name=npc.name,zone=npc.zone,map=npc.map,x=npc.x/100,y=npc.y/100},npcID)
      end
    end
  else
    local side=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
    for _,npc in ipairs(self.Data.trainers) do
      if npc.profession==key and npc.cap>=(recipe.learn or 1) and (npc.faction==side or npc.faction=="B") then add(npc) end
    end
  end
  local map=C_Map and type(C_Map.GetBestMapForUnit)=="function" and C_Map.GetBestMapForUnit("player")
  local pos=map and C_Map and type(C_Map.GetPlayerMapPosition)=="function" and C_Map.GetPlayerMapPosition(map,"player")
  local px,py;if pos and type(pos.GetXY)=="function" then px,py=pos:GetXY() end
  local function distance(row)
    local n=row.location
    if n.map==map and type(px)=="number" and type(py)=="number" then return (n.x-px)^2+(n.y-py)^2 end
    return math.huge
  end
  table.sort(out,function(a,b)
    if (a.location.map==map)~=(b.location.map==map) then return a.location.map==map end
    if distance(a)~=distance(b) then return distance(a)<distance(b) end
    return a.name<b.name
  end)
  return out
end
function CP:TrainerRecipeOptions(key)
  local catalog=self:RecipeVendorCatalog(key)
  local prof=self.db.professions[key]
  local out={}
  if not catalog or not prof or prof.skill>=prof.cap then return out end
  for id,recipe in pairs(catalog.recipes) do
    local native=(self.db.recipes[key] or {})[id]
    local _,_,eligible=self:TrainerRecipeFee(key,id)
    local chance=self:RecipeChanceAt(key,id,recipe,prof.skill)
    if eligible and chance>0 and not recipe.cooldown and not (native and (native.learned or native.disabled))
      and type(recipe.mats)=="table" and next(recipe.mats) then
      local mats={};for item,n in pairs(recipe.mats) do mats[#mats+1]={item,n} end
      local fee=self:TrainerRecipeFee(key,id)
      local entry={id=id,name=self:RecipeName(key,id,recipe.name),mats=mats,chance=chance,
        vendorRecipe=true,trainerRecipe=true,vendors=self:RecipeTeachers(key,id),recipeCost=fee,outputItemID=recipe.makes,
        comparePoints=math.min(5,prof.cap-prof.skill)}
      local comparison=self:VendorSkillComparison(key,entry)
      entry.comparison=comparison
      out[#out+1]=entry
    end
  end
  table.sort(out,function(a,b)
    local ac,bc=a.comparison.cashSaving,b.comparison.cashSaving
    if (ac~=nil)~=(bc~=nil) then return ac~=nil end
    if ac and bc and ac~=bc then return ac>bc end
    return a.id<b.id
  end)
  return out
end
