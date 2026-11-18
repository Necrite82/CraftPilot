-- CraftPilot catalog bridge.
-- The catalog (Data/Catalog/*.lua) is CraftPilot's own, built by tools/catalog from the WoW Forever client's
-- tables, CMaNGOS classic-db, QuestieDB and AllTheThings; sources and checksums in Data/Catalog/SOURCES.json.
local _, CP = ...
local L=CP.L
local D=CP.Data
-- professions whose full catalog drives planning; cooking and first aid use the client's own list
-- plus the derived tables below
local ids={
  engineering=true, mining=true, blacksmithing=true, enchanting=true,
  tailoring=true, leatherworking=true, alchemy=true,
}
local sourceKeys={
  engineering=true,blacksmithing=true,enchanting=true,
  tailoring=true,leatherworking=true,alchemy=true
}
CP.CatalogData=CP.CatalogData or {}
do
  local any=CP.CatalogData.alchemy
  CP.catalogBuild=any and ("Forever "..tostring(any.build).." ("..tostring(any.built)..")") or "?"
  CP.catalogUpstream="CraftPilot (tools/catalog)"
end

-- Cooking and first aid: skill colours of every recipe, the recipes vendors sell, and the camp recipes of
-- every profession that makes camp objects, all derived from the catalog.
CP.SecondarySkillRanges={}
CP.VendorRecipeCatalogs={}
CP.CampingRecipeData={}
for _,key in ipairs({"cooking","firstaid"}) do
  local data=CP.CatalogData[key]
  local ranges,vendorRecipes={},{}
  if data then
    for id,recipe in pairs(data.recipes or {}) do
      ranges[id]=recipe.colors
      if not recipe.unavailable then
        for _,source in ipairs(recipe.get or {}) do
          if source.kind=="vendor" then vendorRecipes[id]=recipe;break end
        end
      end
    end
  end
  CP.SecondarySkillRanges[key]=ranges
  CP.VendorRecipeCatalogs[key]={recipes=vendorRecipes,npcs=data and data.npcs or {}}
end
for _,key in ipairs({"cooking","firstaid","herbalism","skinning","fishing"}) do
  local data=CP.CatalogData[key]
  CP.CampingRecipeData[key]=data and data.recipes or {}
end

-- A reputation standing (1 Hated .. 8 Exalted) in the client's language, e.g. for Merchant's Favor offers.
local STANDINGS={"Hasserfüllt","Feindselig","Unfreundlich","Neutral","Freundlich","Wohlwollend","Respektvoll","Ehrfürchtig"}
function CP:StandingName(standing)
  local label=type(_G)=="table" and _G["FACTION_STANDING_LABEL"..tostring(standing)]
  if type(label)=="string" and label~="" then return label end
  return L(STANDINGS[standing] or tostring(standing))
end

function CP:Catalog(key)
  local entry=ids[key] and self.CatalogData[key]
  if type(entry)=="table" and type(entry.recipes)=="table" then return entry end
  return nil
end

function CP:CatalogCount(key)
  local data=self:Catalog(key)
  local n=0
  for _ in pairs(data and data.recipes or {}) do n=n+1 end
  return n
end

function CP:CatalogSkillChance(recipe,skill)
  local colors=recipe and recipe.colors
  if not self:ValidSkillColors(colors) or type(skill)~="number" then return 0 end
  local start,yellow,green,grey=colors[1],colors[2],colors[3],colors[4]
  if not start or not yellow or not green or not grey or skill<start or skill>=grey then return 0 end
  if skill<yellow then return 1 end
  if skill<green then return .67 end
  return .33
end

function CP:CatalogSource(key,recipeID,skill)
  local data=self:Catalog(key)
  local recipe=data and data.recipes[recipeID]
  if not recipe then return nil end
  local old=self.db and self.db.recipes[key] and self.db.recipes[key][recipeID]
  if old and old.learned and old.disabled~=true then return "known",recipe end
  if old and old.disabled then return nil end
  if (recipe.learn or 1)>skill then return nil end
  if self.db and self.db.ui.knownRecipesOnly then return nil end
  if key=="mining" and not self:OwnsProfession("mining") then return nil end
  if recipe.spec or recipe.cooldown or recipe.rep or recipe.tools or recipe.unavailable or recipe.twin then return nil end
  local level=type(UnitLevel)=="function" and UnitLevel("player") or 0
  if (recipe.charLevel or recipe.reqLevel or 0)>level then return nil end
  local side=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")=="Horde" and "H" or "A"
  local knownTrainer
  for _,source in ipairs(recipe.get or {}) do
    local eligible=not source.event and not source.rep and not source.otherCost and (source.reqLevel or 0)<=level
      and (not source.faction or source.faction=="AH" or source.faction=="B" or source.faction==side)
    if eligible and source.kind=="start" then return "start",recipe end
    if eligible and source.kind=="trainer" then
      local trainAt=math.max(recipe.learn or 1,tonumber(source.skill or source.classicSkill) or recipe.learn or 1)
      if trainAt<=skill and source.event==nil then knownTrainer=true end
    end
  end
  if knownTrainer then return "trainer",recipe end
  return nil
end

local function withClientMaterials(self,key,id,recipe)
  local native=(self.db.recipes[key] or {})[id]
  if not native or not native.learned then return recipe end
  if type(native.mats)~="table" or #native.mats==0 then return nil end
  local effective={}
  for k,v in pairs(recipe) do effective[k]=v end
  effective.mats={}
  for _,mat in ipairs(native.mats) do effective.mats[mat[1]]=(effective.mats[mat[1]] or 0)+mat[2] end
  effective.name=native.name or recipe.name
  if native.outputKnown then effective.makes=native.outputItemID
  else effective.makes=native.outputItemID or recipe.makes end
  if type(native.outputMin)=="number" and native.outputMin>0 then effective.count=native.outputMin end
  return effective
end
function CP:CatalogCandidateRecipes(key,skill)
  local data=self:Catalog(key)
  local out={}
  if not data then return out end
  for id,recipe in pairs(data.recipes) do
    local chance=self:RecipeChanceAt(key,id,recipe,skill)
    if chance>0 and self:SkillPolicyAllows(key,id,recipe,skill,chance) and type(recipe.mats)=="table" and next(recipe.mats) then
      local source=self:CatalogSource(key,id,skill)
      local effective=recipe
      if source=="known" then
        effective=withClientMaterials(self,key,id,recipe)
        if not effective then source=nil end
      end
      if source then out[#out+1]={id=id,recipe=effective,chance=chance,source=source} end
    end
  end
  table.sort(out,function(a,b)
    if a.chance~=b.chance then return a.chance>b.chance end
    return a.id<b.id
  end)
  return out
end

local outputIndex
function CP:BuildOutputIndex()
  if outputIndex then return outputIndex end
  outputIndex={}
  for key in pairs(ids) do
    local cat=self:Catalog(key)
    if cat then
      for id,recipe in pairs(cat.recipes) do
        local item=recipe.makes
        if type(item)=="number" and type(recipe.mats)=="table" and next(recipe.mats)
           and item>0 then
          outputIndex[item]=outputIndex[item] or {}
          outputIndex[item][#outputIndex[item]+1]={key=key,id=id,recipe=recipe}
        end
      end
    end
  end
  return outputIndex
end

function CP:RecipesMaking(itemID,owner,skill)
  local out={}
  for _,entry in ipairs(self:BuildOutputIndex()[itemID] or {}) do
    local qualified=(entry.key==owner) or
      (entry.key=="mining" and self:OwnsProfession("mining"))
    local effective=entry.key==owner and skill or
      ((self.db.professions[entry.key] or {}).skill or 0)
    if qualified and self:CatalogSource(entry.key,entry.id,effective) then
      local recipe=withClientMaterials(self,entry.key,entry.id,entry.recipe)
      if recipe and recipe.makes==itemID then out[#out+1]={key=entry.key,id=entry.id,recipe=recipe} end
    end
  end
  return out
end

function CP:CatalogVendorPrice(itemID)
  local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  local side=faction=="Horde" and "H" or "A"
  local best
  for key in pairs(ids) do
    local cat=self:Catalog(key)
    local pair=cat and cat.vendorPrices and cat.vendorPrices[itemID]
    if type(pair)=="table" then
      local price=tonumber(pair[side]) or tonumber(pair.A) or tonumber(pair.H)
      if price and price>0 and (not best or price<best) then best=price end
    elseif type(pair)=="number" and pair>0 and (not best or pair<best) then best=pair end
  end
  return best
end

function CP:CatalogNotice(key)
  if not sourceKeys[key] then return L("Kein vollständiger Rezeptkatalog; aktuelle Rezepte aus dem Berufsfenster verwenden.") end
  local count=self:CatalogCount(key)
  return string.format(L("%d Rezepte aus Datenstand %s; Trainerverfügbarkeit nicht live bestätigt."),
    count,self.catalogBuild)
end
