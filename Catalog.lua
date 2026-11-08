-- CraftPilot catalog bridge.
-- Bundled Craft Ladder data is GPL-3.0, independently attributed in
-- ThirdParty/CraftLadder/SOURCE.md and the preserved CREDITS.txt.
-- This module is original CraftPilot integration code.
local _, CP = ...
local L=CP.L
local D=CP.Data
local ids={
  engineering="ENGINEERING", mining="MINING",
  blacksmithing="BLACKSMITHING", enchanting="ENCHANTING",
  tailoring="TAILORING", leatherworking="LEATHERWORKING",
  alchemy="ALCHEMY"
}
local sourceKeys={
  engineering=true,blacksmithing=true,enchanting=true,
  tailoring=true,leatherworking=true,alchemy=true
}
CP.catalogBuild="Forever 1.60.1.70425–70450 (2026-10)"
CP.catalogUpstream="saintmodx/craft-ladder @ b9c61346"

function CP:Catalog(key)
  local field=ids[key]
  local entry=field and self[field]
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
  if type(colors)~="table" or type(skill)~="number" then return 0 end
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
  if (recipe.learn or 1)>skill then return nil end
  local old=self.db and self.db.recipes[key] and self.db.recipes[key][recipeID]
  if old and old.learned and old.disabled~=true then return "known",recipe end
  if self.db and self.db.ui.knownRecipesOnly then return nil end
  if key=="mining" and not self:OwnsProfession("mining") then return nil end
  if recipe.spec or recipe.cooldown or recipe.rep or recipe.tools then return nil end
  local knownTrainer
  for _,source in ipairs(recipe.get or {}) do
    if source.kind=="start" then return "start",recipe end
    if source.kind=="trainer" then
      local trainAt=tonumber(source.skill or source.classicSkill) or recipe.learn or 1
      if trainAt<=skill and source.event==nil then knownTrainer=true end
    end
  end
  if knownTrainer then return "trainer",recipe end
  return nil
end

function CP:CatalogCandidateRecipes(key,skill)
  local data=self:Catalog(key)
  local out={}
  if not data then return out end
  for id,recipe in pairs(data.recipes) do
    local chance=self:CatalogSkillChance(recipe,skill)
    if chance>0 and type(recipe.mats)=="table" and next(recipe.mats) then
      local source=self:CatalogSource(key,id,skill)
      if source then out[#out+1]={id=id,recipe=recipe,chance=chance,source=source} end
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
      out[#out+1]=entry
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
