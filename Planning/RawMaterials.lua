-- 1.0.0: raw materials one step back. When a material is missing but what it is made from is in the bags, the
-- bank, the mailbox or on a twink (ore for bars, cloth for bolts, ...), say so: "bis 21 Mithrilbarren aus 21 Mithrilerz".
-- Display only; the cost plan still treats the material as missing.
local _,CP=...
local L=CP.L
local D=CP.Data

-- makes item -> { {key, id, recipe}, ... } over the whole catalog, built once.
local producers
local function producerIndex()
  if producers then return producers end
  producers={}
  for key,data in pairs(CP.CatalogData or {}) do
    if type(data)=="table" and type(data.recipes)=="table" then
      for id,recipe in pairs(data.recipes) do
        if type(recipe)=="table" and recipe.makes and type(recipe.mats)=="table" and next(recipe.mats) and not recipe.unavailable then
          local list=producers[recipe.makes];if not list then list={};producers[recipe.makes]=list end
          list[#list+1]={key=key,id=id,recipe=recipe}
        end
      end
    end
  end
  for _,list in pairs(producers) do table.sort(list,function(a,b) return a.id<b.id end) end
  return producers
end
function CP:ResetRawMaterialIndex() producers=nil end
function CP:ItemProducers(item) return producerIndex()[item] or {} end

-- What this character can use: bags, bank (if counted), own mailbox and twinks that can mail it.
function CP:RawStock(itemID)
  local total=self:ItemAvailability(itemID) or 0
  local me=self.CurrentCharacter and self:CurrentCharacter()
  return total+((me and me.mail or {})[itemID] or 0)
end

-- Who can make it: this character, else a twink with the profession high enough, else nobody known.
local function maker(self,key,recipe)
  local need=recipe.learn or 1
  local mine=self.db and self.db.professions and self.db.professions[key]
  if mine and (mine.skill or 0)>=need then return "me" end
  if self.AltProfessions then
    for _,alt in ipairs(self:AltProfessions(key)) do
      if (alt.skill or 0)>=need then return alt.name end
    end
  end
  return nil
end

-- Options to make `itemID` from stock: { {key, id, recipe, count, mats={{id,have,per}}, who}, ... }, most first.
function CP:RawMaterialOptions(itemID)
  local out={}
  for _,p in ipairs(producerIndex()[itemID] or {}) do
    local runs,mats=math.huge,{}
    for mat,per in pairs(p.recipe.mats) do
      local have=self:RawStock(mat)
      runs=math.min(runs,math.floor(have/math.max(1,per)))
      mats[#mats+1]={id=mat,have=have,per=per}
    end
    if runs~=math.huge and runs>0 then
      table.sort(mats,function(a,b) return a.id<b.id end)
      out[#out+1]={key=p.key,id=p.id,recipe=p.recipe,count=runs*(p.recipe.yield or 1),mats=mats,who=maker(self,p.key,p.recipe)}
    end
  end
  table.sort(out,function(a,b) if a.count~=b.count then return a.count>b.count end return a.id<b.id end)
  return out
end

local function professionName(key)
  local p=D and D.professions and D.professions[key]
  return p and p.name or key
end

-- "bis 21 Mithrilbarren aus 21 Mithrilerz (Bergbau)" for the best option, or nil.
function CP:RawMaterialText(itemID)
  local o=self:RawMaterialOptions(itemID)[1]
  if not o then return nil end
  local parts={}
  for _,m in ipairs(o.mats) do parts[#parts+1]=m.have.." "..self:ItemName(m.id) end
  local who
  if o.who=="me" then who=professionName(o.key)
  elseif o.who then who=string.format(L("%s kann es"),o.who)
  else who=string.format(L("braucht %s"),professionName(o.key)) end
  return string.format(L("bis %d %s aus %s (%s)"),o.count,self:ItemName(itemID),table.concat(parts," + "),who)
end

-- Hints for the missing materials of a cost calculation, at most `limit`.
function CP:RawMaterialHints(materials,limit)
  local out={}
  for _,mat in ipairs(materials or {}) do
    if (mat.missing or 0)>0 then
      local text=self:RawMaterialText(mat.id)
      if text then out[#out+1]=text end
      if limit and #out>=limit then break end
    end
  end
  return out
end
