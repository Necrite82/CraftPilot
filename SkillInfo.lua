-- Current client colors and separately marked historical skill thresholds.
local _,CP=...
local L=CP.L
local labels={L("Orange"),L("Gelb"),L("Grün"),L("Grau")}
local inks={"|cffffa040","|cffffff50","|cff60df70","|cffaaaaaa"}
local odds={[0]=1,[1]=.70,[2]=.35,[3]=0}
function CP:ValidSkillColors(colors)
  if type(colors)~="table" then return false end
  for i=1,4 do
    local n=colors[i]
    if type(n)~="number" or n~=n or n<0 or n>1000 or n%1~=0 or (i>1 and n<colors[i-1]) then return false end
  end
  return true
end
function CP:ReferenceDifficulty(colors,skill)
  if not self:ValidSkillColors(colors) or type(skill)~="number" or skill<colors[1] then return nil end
  if skill>=colors[4] then return 3 end
  if skill>=colors[3] then return 2 end
  if skill>=colors[2] then return 1 end
  return 0
end
function CP:RecipeRangeData(key,id)
  local catalog=self:Catalog(key)
  local recipe=catalog and catalog.recipes[id]
  local ranges=recipe and recipe.colors or (self.SecondarySkillRanges[key] or {})[id]
  if not self:ValidSkillColors(ranges) then return nil,false end
  local native=(self.db.recipes[key] or {})[id]
  local conflict=native and native.snapshotSkill and odds[native.difficulty]~=nil and
    self:ReferenceDifficulty(ranges,native.snapshotSkill)~=native.difficulty
  return ranges,conflict==true
end
function CP:RecipeColorLabel(key,id)
  local native=(self.db.recipes[key] or {})[id]
  local skill=(self.db.professions[key] or {}).skill
  if not native or native.snapshotSkill~=skill or odds[native.difficulty]==nil then return L("Farbe neu einlesen") end
  local index=native.difficulty+1
  return inks[index]..labels[index].."|r"
end
function CP:RecipeRangeText(key,id)
  local colors,conflict=self:RecipeRangeData(key,id)
  if not colors then return L("Farbbereiche unbekannt oder widersprüchlich") end
  local parts={}
  for i=1,3 do
    local ending=colors[i+1]-1
    parts[#parts+1]=inks[i]..labels[i].." "..(ending>=colors[i] and (colors[i].."-"..ending) or "-").."|r"
  end
  parts[#parts+1]=inks[4]..labels[4]..L(" ab ")..colors[4].."|r"
  return table.concat(parts," | ")..(conflict and L(" · Grenzen abweichend") or L(" · Grenzen unbestätigt"))
end
function CP:RecipeChanceAt(key,id,recipe,skill)
  local native=(self.db.recipes[key] or {})[id]
  if native and native.learned and not native.disabled then
    if native.canSkillUp==false then return 0 end
    if skill==native.snapshotSkill then return native.canSkillUp~=false and (odds[native.difficulty] or 0) or 0 end
    local _,conflict=self:RecipeRangeData(key,id)
    if conflict or odds[native.difficulty]==nil then return 0 end
  end
  return self:CatalogSkillChance(recipe,skill)
end
function CP:ProfessionAuditCards()
  local cards={{title=L("Berufsdaten · alle zwölf Berufe"),
    detail=L("Aktuelle Farbe kommt aus deinem Berufsfenster. Vollständige Farbgrenzen sind nicht live bestätigt."),
    footer=L("Eigene Berufe anklicken, um ihren aktuellen Stand einzulesen."),color="gold"}}
  for _,key in ipairs(self.Data.order) do
    local profession=key
    local catalog=self:Catalog(key)
    local references=catalog and catalog.recipes or self.SecondarySkillRanges[key] or {}
    local total,invalid,known,conflicts=0,0,0,0
    for _,record in pairs(references) do
      total=total+1
      if not self:ValidSkillColors(record.colors or record) then invalid=invalid+1 end
    end
    for id,record in pairs(self.db.recipes[key] or {}) do
      if record.learned then known=known+1 end
      local _,conflict=self:RecipeRangeData(key,id)
      if conflict then conflicts=conflicts+1 end
    end
    cards[#cards+1]={title=self.Data.professions[key].name,
      detail=string.format(L("%d Farbreferenzen · %d ungültig · %d erlernte Clientrezepte"),total,invalid,known),
      footer=conflicts>0 and (conflicts..L(" Abweichungen zur eingelesenen Farbe"))
        or (total==0 and L("Keine gesicherten Rezeptgrenzen; Sammeln ist keine Herstellungsroute.") or L("Referenzgrenzen aus älterem Build; aktuelle Farbe separat prüfen.")),
      icon=self.Data.professionIcons[key],color=conflicts>0 and "gold" or "blue",
      action=self:OwnsProfession(key) and function() CP:ChangeView(profession,true) end or nil}
  end
  return cards
end
