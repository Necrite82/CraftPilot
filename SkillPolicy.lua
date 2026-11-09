-- User limits for automatic skill suggestions; browsing remains complete.
local _,CP=...
local L=CP.L
function CP:InitializeSkillPolicy()
  local ui=self.db.ui
  for _,key in ipairs({"allowYellow","allowGreen","planAhead"}) do if type(ui[key])~="boolean" then ui[key]=true end end
  for _,key in ipairs({"yellowPoints","greenPoints"}) do
    local n=ui[key];if type(n)~="number" or n~=n or n==math.huge or n==-math.huge then n=0 end
    ui[key]=math.max(0,math.min(75,math.floor(n)))
  end
end
function CP:SkillPolicyToken()
  local ui=self.db.ui
  return table.concat({tostring(ui.allowYellow~=false),tostring(ui.yellowPoints or 0),tostring(ui.allowGreen~=false),tostring(ui.greenPoints or 0),tostring(ui.planAhead~=false)},":")
end
function CP:SkillPolicyAllows(key,id,recipe,skill,chance)
  chance=chance or self:RecipeChanceAt(key,id,recipe,skill)
  if not chance or chance<=0 then return false end
  if chance>=.99 then return true end
  local green=chance<.5;local ui=self.db.ui
  if (green and ui.allowGreen==false) or (not green and ui.allowYellow==false) then return false end
  local limit=tonumber(ui[green and "greenPoints" or "yellowPoints"]) or 0
  if limit<=0 then return true end
  local colors=recipe and recipe.colors
  if not colors then colors=self:RecipeRangeData(key,id) end
  local start
  if self:ValidSkillColors(colors) then
    local expected=self:CatalogSkillChance({colors=colors},skill)
    if (green and expected>0 and expected<.5) or (not green and expected>=.5 and expected<.99) then start=colors[green and 3 or 2] end
  end
  local native=(self.db.recipes[key] or {})[id]
  -- A conflicting snapshot supplies no verified colour-change boundary.
  start=start or (native and (native.colorObservedStart or native.snapshotSkill)) or skill
  return skill<start+limit
end
function CP:SkillPolicyChanged()
  self:CancelRouteBuild();self.routeAdvice=nil;self.unlockCache=nil;self:InvalidateReservations();self:Render()
end
