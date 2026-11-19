-- 1.1.0: confirmed skill colours from real play. After every craft CraftPilot notes the skill it was made at and
-- whether a point came. Players can copy the notes as a short code and share it (Discord); tools/catalog turns
-- the collected codes into confirmed colour ranges for the catalog. Only profession, recipe, skill and counts are
-- kept: no names, realms or anything else.
local _,CP=...
local L=CP.L
local FORMAT="CPSKILL1"

local spellIndex
local function professionOf(spell)
  if not spellIndex then
    spellIndex={}
    for key,data in pairs(CP.CatalogData or {}) do
      if type(data)=="table" and type(data.recipes)=="table" then
        for id in pairs(data.recipes) do if type(id)=="number" then spellIndex[id]=key end end
      end
    end
  end
  return spellIndex[spell]
end
function CP:ResetSkillLogIndex() spellIndex=nil end

local function root(self)
  local r=self.account or self.db
  if not r then return nil end
  r.skillLog=r.skillLog or {}
  return r.skillLog
end

-- log[key][spell][skill] = {n = crafts, u = crafts that gave a point, en = exported n, eu = exported u}
function CP:RecordSkillObservation(key,spell,skill,gained)
  local log=root(self);if not log or type(skill)~="number" then return end
  log[key]=log[key] or {}
  log[key][spell]=log[key][spell] or {}
  local e=log[key][spell][skill] or {n=0,u=0}
  log[key][spell][skill]=e
  e.n=e.n+1
  if gained then e.u=e.u+1 end
end

local function liveSkill(self,key)
  if self.RefreshProfessionSkills then pcall(self.RefreshProfessionSkills,self) end
  local p=self.db and self.db.professions and self.db.professions[key]
  return p and p.skill,p and p.cap
end

-- A cast is settled when the next one starts or a moment later, whichever comes first.
function CP:SettleSkillCast()
  local pending=self.pendingSkillCast
  if not pending then return end
  self.pendingSkillCast=nil
  local now=liveSkill(self,pending.key)
  if type(now)=="number" then self:RecordSkillObservation(pending.key,pending.spell,pending.skill,now>pending.skill) end
end

function CP:NoteCraftCast(spell)
  if not self.db or self.db.ui.skillLog==false or type(spell)~="number" then return false end
  local key=professionOf(spell)
  if not key then return false end
  self:SettleSkillCast()
  local skill,cap=liveSkill(self,key)
  -- At the cap no point can come; that says nothing about the colour.
  if type(skill)~="number" or (type(cap)=="number" and skill>=cap) then return false end
  local token={}
  self.pendingSkillCast={key=key,spell=spell,skill=skill,token=token}
  local function settle() if CP.pendingSkillCast and CP.pendingSkillCast.token==token then CP:SettleSkillCast() end end
  if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(1.5,settle) end
  return true
end

-- Own notes for one recipe: crafts and points per skill, sorted.
function CP:SkillObservations(key,spell)
  local log=root(self)
  local rows={}
  for skill,e in pairs(log and log[key] and log[key][spell] or {}) do rows[#rows+1]={skill=skill,n=e.n,u=e.u} end
  table.sort(rows,function(a,b) return a.skill<b.skill end)
  return rows
end

function CP:SkillObservationText(key,spell)
  local rows=self:SkillObservations(key,spell)
  if #rows==0 then return nil end
  local n,u=0,0
  for _,r in ipairs(rows) do n=n+r.n;u=u+r.u end
  return string.format(L("Eigene Daten: %d× hergestellt bei Skill %d–%d, %d Punkte"),n,rows[1].skill,rows[#rows].skill,u)
end

function CP:SkillLogStats()
  local log=root(self)
  local crafts,recipes,new=0,0,0
  for _,spells in pairs(log or {}) do
    for _,skills in pairs(spells) do
      recipes=recipes+1
      for _,e in pairs(skills) do crafts=crafts+e.n;new=new+(e.n-(e.en or 0)) end
    end
  end
  return {crafts=crafts,recipes=recipes,new=new}
end

-- Code with everything not shared yet: CPSKILL1;<client build>;key:spell:skill:n:u,...
-- markExported moves the counts into the "already shared" part.
function CP:SkillLogExport(markExported)
  local log=root(self)
  local parts={}
  local keys={};for key in pairs(log or {}) do keys[#keys+1]=key end;table.sort(keys)
  for _,key in ipairs(keys) do
    local spells={};for spell in pairs(log[key]) do spells[#spells+1]=spell end;table.sort(spells)
    for _,spell in ipairs(spells) do
      local skills={};for skill in pairs(log[key][spell]) do skills[#skills+1]=skill end;table.sort(skills)
      for _,skill in ipairs(skills) do
        local e=log[key][spell][skill]
        local n,u=e.n-(e.en or 0),e.u-(e.eu or 0)
        if n>0 then
          parts[#parts+1]=key..":"..spell..":"..skill..":"..n..":"..u
          if markExported then e.en,e.eu=e.n,e.u end
        end
      end
    end
  end
  if #parts==0 then return nil end
  local build=type(GetBuildInfo)=="function" and select(2,GetBuildInfo()) or "?"
  return FORMAT..";"..tostring(build)..";"..table.concat(parts,",")
end

function CP:OpenSkillLogWindow()
  local text=self:SkillLogExport(false)
  if not text then self:Say(L("Noch keine neuen Skilldaten · einfach weiter herstellen."));return false end
  local f=self.skillLogWindow
  if not f then
    f=CreateFrame("Frame","CraftPilotProSkillLogWindow",UIParent,"BackdropTemplate")
    f:SetSize(460,190);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    if type(f.SetBackdrop)=="function" then
      f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f:SetBackdropColor(.07,.08,.10,.97);f:SetBackdropBorderColor(.88,.69,.31,.9)
    end
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",12,-10);f.title:SetText(L("Skilldaten teilen"))
    f.hint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall");f.hint:SetPoint("TOPLEFT",f,"TOPLEFT",12,-30);f.hint:SetWidth(436);f.hint:SetJustifyH("LEFT")
    f.hint:SetText(L("Code kopieren (Strg+C) und im CraftPilot-Discord im Kanal für Skilldaten posten. Enthalten sind nur Beruf, Rezept, Skill und Anzahl – keine Namen."))
    f.box=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.box:SetSize(430,26);f.box:SetPoint("TOPLEFT",f,"TOPLEFT",16,-86);f.box:SetAutoFocus(false)
    if type(f.box.SetMaxLetters)=="function" then f.box:SetMaxLetters(0) end
    f.box:SetScript("OnEscapePressed",function() f:Hide() end)
    f.done=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.done:SetSize(200,24);f.done:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",12,12)
    f.done:SetText(L("Geteilt – als gesendet merken"))
    f.done:SetScript("OnClick",function() CP:SkillLogExport(true);f:Hide();CP:Say(L("Danke! Neue Daten kommen beim nächsten Mal dazu."));if CP.Render then CP:Render() end end)
    f.close=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.close:SetSize(100,24);f.close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-12,12)
    f.close:SetText(L("Schließen"));f.close:SetScript("OnClick",function() f:Hide() end)
    self.skillLogWindow=f
  end
  f.box:SetText(text)
  f:Show()
  if type(f.box.SetFocus)=="function" then f.box:SetFocus() end
  if type(f.box.HighlightText)=="function" then f.box:HighlightText() end
  return true
end

function CP:SkillLogCard()
  local s=self:SkillLogStats()
  return {title=L("Skilldaten teilen"),
    detail=string.format(L("CraftPilot merkt sich bei jedem Herstellen, bei welchem Skill es einen Punkt gab. Geteilt machen diese Daten die Farbgrenzen für alle genauer. Bisher: %d Herstellungen bei %d Rezepten, %d neu."),s.crafts,s.recipes,s.new),
    footer=s.new>0 and L("Klick: Code zum Kopieren") or L("Noch nichts Neues zum Teilen"),color=s.new>0 and "green" or "blue",
    action=function() CP:OpenSkillLogWindow() end}
end

local events=CreateFrame("Frame")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:SetScript("OnEvent",function(_,_,unit,_,spell)
  if unit=="player" and CP.db then CP:NoteCraftCast(spell) end
end)
