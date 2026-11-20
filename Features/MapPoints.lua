-- 1.4.0: what the map window shows. Trainers (with rank books and quests of the secondary professions), recipe
-- vendors of a profession, tour stops and the missing recipes of the collection. Every point carries the
-- destination CP:SetWaypoint takes, so a click on the map sets the waypoint.
local _,CP=...
local L=CP.L

local function side()
  local f=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  return f=="Horde" and "H" or "A"
end
local function factionFits(value)
  if not value or value=="B" or value=="AH" then return true end
  local mine=side()
  return value==mine or (mine=="A" and value=="Alliance") or (mine=="H" and value=="Horde")
end
local function profName(self,key) return (self.Data.professions[key] or {}).name or key end
local function point(location,kind,title,sub,label)
  if type(location)~="table" or type(location.map)~="number" then return nil end
  return {map=location.map,x=location.x,y=location.y,kind=kind,title=title or location.name,sub=sub,label=label,location=location}
end
local function list(names,limit)
  local shown={}
  for i=1,math.min(#names,limit) do shown[i]=names[i] end
  return table.concat(shown,", ")..(#names>limit and string.format(L(" (+%d)"),#names-limit) or "")
end

-- Trainers of the profession for your faction; for the next rank the book vendors, quest givers and world
-- trainers that teach it.
function CP:TrainerMapPoints(key)
  local out={}
  local entries=self:TrainerChoices(key)
  for _,entry in ipairs(entries) do
    local npc=entry.npc
    local kind=npc.how=="book" and "book" or npc.how=="quest" and "quest" or "trainer"
    local how=npc.how=="book" and string.format(L("Buch „%s“ kaufen und lesen"),self:ItemName(npc.book))
      or npc.how=="quest" and string.format(L("Quest „%s“ abschließen"),self:RankQuestName(npc)) or nil
    local sub=(how and (how.." · ") or "")..(entry.canTeach and string.format(L("bis %d"),npc.cap) or string.format(L("nur bis %d"),npc.cap))
    local p=point(npc,kind,npc.name,sub)
    if p then out[#out+1]=p end
  end
  return out
end

-- Vendors that sell recipes of the profession you do not know yet, one point per vendor with its recipes.
function CP:VendorMapPoints(key)
  local out,byVendor={},{}
  for _,entry in ipairs(self.VendorRecipeBrowseOptions and self:VendorRecipeBrowseOptions(key,"","skill") or {}) do
    if not entry.learned then
      for _,v in ipairs(entry.vendors or {}) do
        if v.location and factionFits(v.faction) then
          local id=v.id or v.name
          local slot=byVendor[id]
          if not slot then
            slot={vendor=v,recipes={}}
            byVendor[id]=slot;out[#out+1]=slot
          end
          slot.recipes[#slot.recipes+1]=entry.name..(entry.requiredSkill and (" ("..entry.requiredSkill..")") or "")
        end
      end
    end
  end
  local points={}
  for _,slot in ipairs(out) do
    local p=point(slot.vendor.location,"vendor",slot.vendor.name,string.format(L("%d Rezepte: %s"),#slot.recipes,list(slot.recipes,4)))
    if p then points[#points+1]=p end
  end
  return points
end

function CP:ShowTrainerMap(key)
  local points={}
  for _,p in ipairs(self:TrainerMapPoints(key)) do points[#points+1]=p end
  for _,p in ipairs(self:VendorMapPoints(key)) do points[#points+1]=p end
  return self:ShowMap(string.format(L("Lehrer & Händler · %s"),profName(self,key)),points)
end

-- Tour stops (learning tour, collection tour) numbered in order.
function CP:StopMapPoints(stops)
  local points={}
  for i,stop in ipairs(stops or {}) do
    local names={}
    for _,r in ipairs(stop.recipes or {}) do names[#names+1]=r.name end
    local kind=stop.kind=="trainer" and "trainer" or stop.kind=="drop" and "drop" or "vendor"
    local location=stop.location
    if stop.kind=="trainer" and not location then location=select(3,self:TrainerChoices(self.db.view)) end
    local p=point(location,kind,stop.name,list(names,5),tostring(i))
    if p then points[#points+1]=p end
  end
  return points
end
function CP:ShowLearnTourMap(key)
  return self:ShowMap(string.format(L("Lerntour · %s"),profName(self,key)),self:StopMapPoints(self:LearnTourStops(key)))
end

-- Collection: every missing recipe with a known place, one point per place.
function CP:CollectionMapPoints(key)
  local stops,byPlace={},{}
  for _,row in ipairs(self:RecipeCollection(key).missing) do
    local go=self.RecipeGoTo and self:RecipeGoTo(key,row.id)
    if go and go.location and go.location.map then
      local place=(go.label or "")..":"..tostring(go.location.map)..":"..tostring(go.location.x)
      local stop=byPlace[place]
      if not stop then
        stop={kind=go.kind=="vendor" and "vendor" or "drop",name=go.label,location=go.location,recipes={}}
        byPlace[place]=stop;stops[#stops+1]=stop
      end
      stop.recipes[#stop.recipes+1]={name=self:RecipeName(key,row.id,row.recipe.name)}
    end
  end
  local points=self:StopMapPoints(stops)
  for _,p in ipairs(points) do p.label=nil end
  return points
end
function CP:ShowCollectionMap(key)
  return self:ShowMap(string.format(L("Fehlende Rezepte · %s"),profName(self,key)),self:CollectionMapPoints(key))
end
