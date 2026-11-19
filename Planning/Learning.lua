-- Where to learn what: the way to a recipe's trainer or vendor, a learning tour along the cheapest path,
-- the character level each rank needs and the profession specializations. Advice only: nothing is learned
-- or bought automatically.
local _,CP=...
local L=CP.L

local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c=pcall(fn,...)
  if ok then return a,b,c end
end
local function side()
  local f=safe(UnitFactionGroup,"player")
  return f=="Horde" and "H" or "A"
end
local function fits(faction)
  return not faction or faction=="AH" or faction=="B" or faction:find(side(),1,true)~=nil
end

-- How an unlearned recipe is obtained right now: {kind, name, location, cost, item}.
function CP:LearnTarget(key,id)
  local native=(self.db.recipes[key] or {})[id]
  if native and native.learned then return nil end
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  if not recipe then return nil end
  local fee,_,eligible=self:TrainerRecipeFee(key,id,300)
  if eligible then
    local teacher=self:RecipeTeachers(key,id)[1]
    local location=teacher and teacher.location
    if not location then
      local _,_,recommended=self:TrainerChoices(key)
      location=recommended
    end
    return {kind="trainer",name=location and location.name or L("Lehrer"),location=location,cost=fee,learnAt=recipe.learn}
  end
  for _,vendor in ipairs(self:RecipeVendors(key,id)) do
    if not vendor.restricted and vendor.location then
      return {kind="vendor",name=vendor.name,location=vendor.location,cost=vendor.cost,learnAt=recipe.learn,limited=vendor.source and vendor.source.limited}
    end
  end
  if recipe.item then
    local d=self:PriceDetails(recipe.item)
    if d.auction then return {kind="ah",name=L("Auktionshaus"),item=recipe.item,cost=d.auction,learnAt=recipe.learn} end
  end
  return nil
end

function CP:LearnTargetLabel(target)
  if not target then return nil end
  if target.kind=="trainer" then return L("Weg zum Lehrer") end
  if target.kind=="vendor" then return L("Weg zum Händler") end
  return L("Rezept im AH suchen")
end

-- One click: a waypoint to the trainer or vendor, or an auction house search for a drop recipe.
function CP:GoLearn(key,id)
  local target=self:LearnTarget(key,id)
  if not target then self:Say(L("Kein Lernort für dieses Rezept hinterlegt."));return false end
  if target.kind=="ah" then
    return self:SearchItems({{id=target.item,quantity=1}},L("Rezepte"),L("Auctionator sucht das Rezept."))
  end
  if not target.location then return self:TrainerWaypoint() end
  return self:SetWaypoint(target.location)
end

-- Learning tour: every recipe the cheapest path learns on the way, grouped by where it is learned.
-- Trainer first (one visit teaches all), then vendors on the current map, then the others by zone.
function CP:LearnTourStops(key)
  local path=self.CheapestPath and self:CheapestPath(key)
  local stops,byPlace={},{}
  local map=C_Map and safe(C_Map.GetBestMapForUnit,"player")
  for _,s in ipairs(path and path.segments or {}) do
    if not s.learned then
      local target=self:LearnTarget(key,s.id)
      if target then
        local place=target.kind=="trainer" and "trainer" or (target.kind=="ah" and "ah" or (target.location and (target.location.name..":"..tostring(target.location.map))))
        local stop=byPlace[place]
        if not stop then
          stop={kind=target.kind,name=target.name,location=target.location,recipes={},seen={},cost=0}
          byPlace[place]=stop;stops[#stops+1]=stop
        end
        if not stop.seen[s.id] then
          stop.seen[s.id]=true;stop.recipes[#stop.recipes+1]={id=s.id,name=s.name,at=s.first,cost=target.cost}
          stop.cost=stop.cost+(target.cost or 0)
        end
      end
    end
  end
  local order={trainer=1,vendor=2,ah=3}
  table.sort(stops,function(a,b)
    if a.kind~=b.kind then return order[a.kind]<order[b.kind] end
    local am=a.location and a.location.map==map or false
    local bm=b.location and b.location.map==map or false
    if am~=bm then return am end
    return (a.location and a.location.zone or a.name)<(b.location and b.location.zone or b.name)
  end)
  return stops
end

local function stopDone(self,key,stop)
  for _,r in ipairs(stop.recipes) do
    local native=(self.db.recipes[key] or {})[r.id]
    if not (native and native.learned) then return false end
  end
  return true
end

function CP:StartLearnTour(key)
  local stops=self:LearnTourStops(key)
  if #stops==0 then self:Say(L("Für den günstigsten Weg musst du nichts dazulernen."));return false end
  self.tour={key=key,stops=stops,index=1}
  self:GoTourStop()
  return true
end

function CP:GoTourStop()
  local tour=self.tour;if not tour then return false end
  local stop=tour.stops[tour.index]
  if not stop then self.tour=nil;self:Say(L("Lerntour abgeschlossen."));return false end
  local names={};for _,r in ipairs(stop.recipes) do names[#names+1]=r.name end
  self:Say(string.format(L("Lerntour %d/%d: %s · %s"),tour.index,#tour.stops,stop.name,table.concat(names,", ")))
  if stop.kind=="ah" then
    local items={}
    local catalog=self:RecipeVendorCatalog(tour.key)
    for _,r in ipairs(stop.recipes) do
      local recipe=catalog and catalog.recipes[r.id]
      if recipe and recipe.item then items[#items+1]={id=recipe.item,quantity=1} end
    end
    return self:SearchItems(items,L("Rezepte"),L("Auctionator sucht die Rezepte."))
  end
  if stop.kind=="trainer" and not stop.location then return self:TrainerWaypoint() end
  return self:SetWaypoint(stop.location)
end

function CP:NextTourStop()
  local tour=self.tour;if not tour then return false end
  tour.index=tour.index+1
  return self:GoTourStop()
end

-- Called after the profession window was read: a finished stop moves the tour on by itself.
function CP:CheckLearnTour()
  local tour=self.tour
  if not tour then return end
  local stop=tour.stops[tour.index]
  if stop and stopDone(self,tour.key,stop) then
    if self.CompanionNotice then self:CompanionNotice(string.format(L("Gelernt bei %s · weiter zum nächsten Halt."),stop.name)) end
    self:NextTourStop()
  end
end

-- Character level and skill each next rank needs, and whether this character can learn it now.
function CP:RankGate(key)
  local record=self.db.professions[key]
  if not record then return nil end
  local rank=self:NextRank(key)
  if not rank then return nil end
  local level=safe(UnitLevel,"player") or 0
  local needLevel=self:RankCharacterLevel(key,rank)
  local needSkill=rank.min or 0
  local gate={rank=rank,name=rank.name,cap=rank.cap,needLevel=needLevel,needSkill=needSkill,level=level,skill=record.skill or 0,
    levelOk=level>=needLevel,skillOk=(record.skill or 0)>=needSkill}
  gate.ok=gate.levelOk and gate.skillOk
  if not gate.levelOk then
    gate.text=string.format(L("%s (bis %d) erst ab Charakterstufe %d · du bist %d."),gate.name,gate.cap,needLevel,level)
  elseif not gate.skillOk then
    gate.text=string.format(L("%s (bis %d) ab Skill %d lernbar."),gate.name,gate.cap,needSkill)
  else
    gate.text=string.format(L("%s (bis %d) jetzt beim Lehrer lernbar."),gate.name,gate.cap)
  end
  return gate
end

-- The warning that matters before buying: skill points beyond the current cap need a rank this
-- character cannot learn yet.
function CP:RankGateWarning(key,target)
  local record=self.db.professions[key]
  if not record or not target or target<=(record.cap or 0) then return nil end
  local gate=self:RankGate(key)
  if not gate or gate.levelOk then return nil end
  return gate
end

-- Specializations (catalog specGuides): requirements, the current step and its quest giver.
local function specKnown(spec)
  if type(IsPlayerSpell)=="function" then local ok,known=pcall(IsPlayerSpell,spec);if ok and known then return true end end
  if type(IsSpellKnown)=="function" then local ok,known=pcall(IsSpellKnown,spec);if ok and known then return true end end
  return false
end
local function questDone(q)
  if C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted)=="function" then
    local ok,done=pcall(C_QuestLog.IsQuestFlaggedCompleted,q);if ok then return done==true end
  end
  if type(IsQuestFlaggedCompleted)=="function" then local ok,done=pcall(IsQuestFlaggedCompleted,q);if ok then return done==true end end
  return false
end
CP.SpecQuestDone=questDone

function CP:Specializations(key)
  local catalog=self:Catalog(key)
  local guides=catalog and catalog.specGuides
  if not guides or #guides==0 then return nil end
  local out={}
  local level=safe(UnitLevel,"player") or 0
  local skill=(self.db.professions[key] or {}).skill or 0
  for _,g in ipairs(guides) do
    local entry={spec=g.spec,name=(catalog.specs or {})[g.spec] or ("#"..g.spec),known=specKnown(g.spec),level=g.level,skill=g.skill,
      note=g.note,steps=#(g.steps or {}),icon=g.icon}
    entry.ready=level>=(g.level or 0) and skill>=(g.skill or 0)
    for i,step in ipairs(g.steps or {}) do
      local quests,done={},false
      for _,q in ipairs(step.quests or {}) do
        local info=(catalog.quests or {})[q]
        if info and fits(info.faction) then quests[#quests+1]=q;if questDone(q) then done=true end end
      end
      if not done and not entry.current and (#quests>0 or step.talk or step.pick) then
        entry.current=i
        local where
        for _,q in ipairs(quests) do
          local info=catalog.quests[q]
          local npc=(catalog.npcs or {})[info.giver]
          if npc and type(npc.map)=="number" then
            where={name=info.giverName or npc.name,zone=npc.zone,map=npc.map,x=npc.x/100,y=npc.y/100,quest=info.name};break
          end
        end
        for _,id in ipairs(step.talk or {}) do
          local npc=(catalog.npcs or {})[id]
          if not where and npc and fits(npc.faction) and type(npc.map)=="number" then
            where={name=npc.name,zone=npc.zone,map=npc.map,x=npc.x/100,y=npc.y/100}
          end
        end
        entry.where=where
        entry.stepNote=step.note
        local items={}
        for _,it in ipairs(step.items or {}) do items[#items+1]=it.n.." "..self:ItemName(it.item) end
        entry.stepItems=table.concat(items,", ")
      end
    end
    out[#out+1]=entry
  end
  return out
end

function CP:SpecHint(key)
  local specs=self:Specializations(key)
  if not specs then return nil end
  local skill=(self.db.professions[key] or {}).skill or 0
  for _,s in ipairs(specs) do if s.known then return nil end end
  local first=specs[1]
  if not first or skill<(first.skill or 0)-25 then return nil end
  return string.format(L("Spezialisierung ab Skill %d und Stufe %d möglich: siehe Lehrer & Händler, Bereich Spezialisierung."),first.skill or 0,first.level or 0)
end

function CP:SpecCards(key)
  local specs=self:Specializations(key)
  if not specs then
    return {{title=L("Keine Spezialisierung für diesen Beruf"),detail=L("In WoW Forever haben Schmiedekunst, Ingenieurskunst und Lederverarbeitung Spezialisierungen."),color="blue"}}
  end
  local cards={{title=L("Wähle mit Bedacht"),detail=L("Eine Spezialisierung schaltet eigene Rezepte frei; ein Wechsel kostet Gold und die Rezepte der alten. Die Schritte stammen aus den Questdaten (QuestieDB, CMaNGOS)."),color="gold"}}
  for _,s in ipairs(specs) do
    local status
    if s.known then status=L("Erlernt")
    elseif not s.ready then status=string.format(L("Ab Skill %d und Stufe %d"),s.skill or 0,s.level or 0)
    elseif s.current then status=string.format(L("Schritt %d von %d"),s.current,s.steps)
    else status=L("Bereit") end
    local detail={}
    if s.where then detail[#detail+1]=(s.where.quest and (L("Quest: ")..s.where.quest.." · ") or "")..s.where.name..", "..(s.where.zone or "") end
    if s.stepItems and s.stepItems~="" then detail[#detail+1]=L("Benötigt: ")..s.stepItems end
    if s.stepNote then detail[#detail+1]=s.stepNote end
    local where=s.where
    cards[#cards+1]={title=s.name.." · "..status,detail=#detail>0 and table.concat(detail,"\n") or (s.note or ""),
      footer=where and not s.known and L("Klick: Wegpunkt zum nächsten Schritt") or (s.note and s.known and "" or ""),
      color=s.known and "green" or (s.ready and "gold" or "blue"),icon=s.icon,
      action=where and not s.known and function() CP:SetWaypoint(where) end or nil}
  end
  return cards
end

function CP:LearnTourCards(key)
  local stops=self:LearnTourStops(key)
  if #stops==0 then
    return {{title=L("Nichts zu lernen"),detail=L("Der günstigste Weg bis zur Ausbildungsgrenze kommt mit deinen erlernten Rezepten aus."),color="green"}}
  end
  local total=0;for _,s in ipairs(stops) do total=total+s.cost end
  local tour=self.tour and self.tour.key==key and self.tour
  local cards={{title=tour and string.format(L("Lerntour läuft · Halt %d von %d"),tour.index,#tour.stops) or string.format(L("Lerntour starten · %d Halte · %s"),#stops,self:FormatCostMoney(total)),
    detail=tour and L("Nach dem Lernen springt der Wegpunkt beim nächsten Öffnen des Berufsfensters weiter.") or L("Setzt den Wegpunkt zum ersten Halt; nach dem Lernen geht es automatisch weiter."),
    footer=tour and L("Klick: nächster Halt") or L("Klick: Tour starten"),color="gold",emphasis=true,
    action=function() if CP.tour and CP.tour.key==key then CP:NextTourStop() else CP:StartLearnTour(key) end;CP:Render() end}}
  for i,stop in ipairs(stops) do
    local names={}
    for _,r in ipairs(stop.recipes) do names[#names+1]=r.name..L(" (ab ")..r.at..")" end
    local place=stop.location and (stop.location.zone and (stop.location.zone..string.format(" %.1f / %.1f",stop.location.x*100,stop.location.y*100)) or "") or ""
    local kind=stop.kind=="trainer" and L("Lehrer") or (stop.kind=="vendor" and L("Händler") or L("Auktionshaus"))
    local who=(stop.kind=="ah" or stop.name==kind) and kind or (kind..": "..stop.name)
    cards[#cards+1]={title=i..". "..who..(stop.cost>0 and (" · "..self:FormatCostMoney(stop.cost)) or ""),
      detail=table.concat(names,", ")..(place~="" and ("\n"..place) or ""),
      footer=stop.kind=="ah" and L("Klick: im AH suchen") or L("Klick: Wegpunkt"),
      color=(tour and tour.index==i) and "gold" or "blue",
      action=function() CP.tour={key=key,stops=stops,index=i};CP:GoTourStop();CP:Render() end}
  end
  return cards
end
