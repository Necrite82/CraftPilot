-- Direct recipe actions and a focused view of existing vendor records.
local _,CP=...
local L=CP.L
local odds={[0]=1,[1]=.70,[2]=.35,[3]=0}
local function factionFits(value)
  local side=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  return not value or value=="AH" or value=="B" or value==(side=="Horde" and "H" or "A")
end
function CP:RecipeVendorCatalog(key)
  return self:Catalog(key) or (self.VendorRecipeCatalogs and self.VendorRecipeCatalogs[key])
end
function CP:RecipeVendors(key,id)
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local vendors,seen,listed={},{},{}
  if not recipe or recipe.rep or recipe.spec then return vendors end
  for _,source in ipairs(recipe.get or {}) do
    if source.kind=="vendor" and source.npc then listed[source.npc]=true end
    local npc=(catalog.npcs or {})[source.npc]
    if source.kind=="vendor" and type(source.npc)=="number" and not seen[source.npc]
      and (not source.reqLevel or source.reqLevel<=(type(UnitLevel)=="function" and UnitLevel("player") or 0))
      and not source.event and not source.otherCost and not source.rep
      and factionFits(source.faction) and (not npc or factionFits(npc.faction)) then
      seen[source.npc]=true
      local location
      if npc and type(npc.map)=="number" and npc.map>0 and type(npc.x)=="number" and type(npc.y)=="number"
        and npc.x>=0 and npc.x<=100 and npc.y>=0 and npc.y<=100 then
        location={name=npc.name or source.npcName or ("NPC #"..source.npc),zone=npc.zone or L("unbekannt"),
          map=npc.map,x=npc.x/100,y=npc.y/100}
      end
      local extra,localizedName=self:QuestieNpcLocation(source.npc,location)
      if extra then location=extra end
      if location and localizedName then location.name=localizedName end
      vendors[#vendors+1]={id=source.npc,name=localizedName or (npc and npc.name) or source.npcName or ("NPC #"..source.npc),
        location=location,cost=type(source.cost)=="number" and source.cost>=0 and source.cost or nil}
    end
  end
  for _,id in ipairs(self:QuestieItemVendors(recipe.item)) do
    local npc=(catalog.npcs or {})[id]
    if type(id)=="number" and id>0 and not seen[id] and not listed[id]
      and npc and npc.faction and factionFits(npc.faction) then
      local fallback
      if type(npc.map)=="number" and type(npc.x)=="number" and type(npc.y)=="number"
        and npc.x>=0 and npc.x<=100 and npc.y>=0 and npc.y<=100 then
        fallback={name=npc.name,zone=npc.zone,map=npc.map,x=npc.x/100,y=npc.y/100}
      end
      local location,name=self:QuestieNpcLocation(id,fallback)
      vendors[#vendors+1]={id=id,name=name or npc.name or ("NPC #"..id),location=location or fallback}
      seen[id]=true
    end
  end
  local map=C_Map and type(C_Map.GetBestMapForUnit)=="function" and C_Map.GetBestMapForUnit("player")
  table.sort(vendors,function(a,b)
    local sameA=a.location and a.location.map==map or false
    local sameB=b.location and b.location.map==map or false
    if sameA~=sameB then return sameA end
    if (a.location~=nil)~=(b.location~=nil) then return a.location~=nil end
    if a.cost and b.cost and a.cost~=b.cost then return a.cost<b.cost end
    return a.id<b.id
  end)
  return vendors
end
function CP:VendorRecipeOptions(key)
  local out={}
  local catalog=self:RecipeVendorCatalog(key)
  local profession=self.db.professions[key]
  if self.db.ui.showVendorRecipes==false or not catalog or not profession or profession.skill>=profession.cap then return out end
  local skill=profession.skill
  for id,recipe in pairs(catalog.recipes) do
    local native=(self.db.recipes[key] or {})[id]
    local chance=self:CatalogSkillChance(recipe,skill)
    if native and native.snapshotSkill==skill and odds[native.difficulty]~=nil then chance=odds[native.difficulty] end
    if chance>0 and (recipe.learn or 1)<=skill and recipe.item and not recipe.cooldown and not recipe.tools and not recipe.twin and not recipe.unavailable
      and not (native and (native.learned or native.disabled)) then
      local vendors=self:RecipeVendors(key,id)
      if #vendors>0 then
        local mats={}
        for item,n in pairs(recipe.mats or {}) do mats[#mats+1]={item,n} end
        local cheapest
        for _,vendor in ipairs(vendors) do if vendor.cost and (not cheapest or vendor.cost<cheapest) then cheapest=vendor.cost end end
        out[#out+1]={id=id,name=self:RecipeName(key,id,recipe.name),mats=mats,chance=chance,
          vendorRecipe=true,outputItemID=recipe.item,vendors=vendors,recipeItem=recipe.item,recipeCost=cheapest}
      end
    end
  end
  table.sort(out,function(a,b)
    if a.chance~=b.chance then return a.chance>b.chance end
    if a.recipeCost and b.recipeCost and a.recipeCost~=b.recipeCost then return a.recipeCost<b.recipeCost end
    return a.id<b.id
  end)
  return out
end
function CP:OpenLearnedRecipe(key,id)
  local recipe=(self.db.recipes[key] or {})[id]
  if not recipe or not recipe.learned or recipe.disabled or not self:OwnsProfession(key) then return false end
  if type(InCombatLockdown)=="function" and InCombatLockdown() then
    self:Say(L("Berufsfenster kann im Kampf gesperrt sein."));return false
  end
  local api=C_TradeSkillUI
  if api and type(api.OpenRecipe)=="function" then
    -- Hardware-event restricted: deliberately direct, never pcall or a timer.
    api.OpenRecipe(id)
    return true
  end
  local opened=self:OpenOwnedProfession(key)
  self:Say(L("Direkte Rezeptwahl nicht verfügbar; Rezept im Berufsfenster auswählen."))
  return opened
end
-- Equal expected-point comparison of integer batches at today's skill colour.
-- Recipe acquisition is charged once; travel and future colour changes are excluded.
function CP:VendorSkillComparison(key,entry)
  local count=math.max(1,math.ceil(1/entry.chance))
  local cost=self:CostCalculation("recipe",key,entry.id,count)
  local points=count*entry.chance
  local best
  for _,option in ipairs(self:Options(key)) do
    local n=math.max(1,math.ceil(1/option.chance))
    local baseline=self:CostCalculation("recipe",key,option.id,n)
    if baseline.economicComplete and baseline.stale==0 and baseline.unknownAge==0 and baseline.unknownBank==0 then
      local unit=baseline.economic/(n*option.chance)
      if not best or unit<best then best=unit end
    end
  end
  local reliable=cost.economicComplete and cost.stale==0 and cost.unknownAge==0 and cost.unknownBank==0
  return {cost=cost,crafts=count,points=points,unit=cost.economic/points,
    saving=reliable and best and best-cost.economic/points or nil}
end
function CP:ActivateRecipeRow(key,entry)
  if entry.vendorRecipe then
    self.db.ui.selectedVendorRecipe=(self.db.ui.selectedVendorKey~=key or self.db.ui.selectedVendorRecipe~=entry.id) and entry.id or nil
    self.db.ui.selectedVendorKey=key
  else
    self.db.ui.selectedVendorRecipe=nil
    self.db.ui.selectedVendorKey=nil
    self.db.ui.selectedRecipes[key]=entry.id
    self:OpenLearnedRecipe(key,entry.id)
  end
  self:Render()
end
