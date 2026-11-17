local _,CP=...
local locale=type(GetLocale)=="function" and GetLocale() or "enUS"
CP.locale=locale=="deDE" and "deDE" or "enUS"
CP.English={}
function CP.L(text)
  if CP.locale=="deDE" then return text end
  return CP.English[text] or text
end

local L=CP.L
function CP:RecipeName(key,id,fallback)
  local native=(self.db.recipes[key] or {})[id]
  if native and native.name then return native.name end
  if C_Spell and type(C_Spell.GetSpellName)=="function" then
    local ok,name=pcall(C_Spell.GetSpellName,id)
    if ok and type(name)=="string" and name~="" then return name end
  end
  return fallback or (L("Rezept ")..tostring(id))
end
