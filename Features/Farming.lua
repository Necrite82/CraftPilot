-- Gather instead of buy: for ores, stones and herbs, the zones with the most nodes (read from the QuestieDB
-- addon; node IDs and skills in ThirdParty/Gathering) and who on the account can gather them.
local _,CP=...
local L=CP.L

function CP:ZoneName(map)
  if C_Map and type(C_Map.GetMapInfo)=="function" then
    local ok,info=pcall(C_Map.GetMapInfo,map)
    if ok and type(info)=="table" and type(info.name)=="string" then return info.name end
  end
  return L("Karte ")..tostring(map)
end

-- Where an ore, stone or herb can be gathered: the item's nodes (bundled IDs and skills) with their spawns
-- from the QuestieDB addon, the four zones with the most nodes first. Cached per item.
function CP:GatherInfo(item)
  local prof=self.GatheringItems and self.GatheringItems[item]
  if not prof then return nil end
  self.gatherCache=self.gatherCache or {}
  local cached=self.gatherCache[item]
  if cached~=nil then return cached or nil end
  local nodes,low={},nil
  for _,obj in ipairs(self:QuestieItemObjects(item)) do
    local node=self.GatheringNodes and self.GatheringNodes[obj]
    if node then nodes[obj]=node[2];low=math.min(low or node[2],node[2]) end
  end
  local zones=low and self:QuestieObjectZones(nodes)
  local list={}
  for _,z in pairs(zones or {}) do list[#list+1]=z end
  table.sort(list,function(a,b) if a.nodes~=b.nodes then return a.nodes>b.nodes end return a.map<b.map end)
  for i=#list,5,-1 do list[i]=nil end
  local info=#list>0 and {prof=prof,skill=low,zones=list} or false
  -- Do not remember a miss while QuestieDB is not readable yet.
  if info or self:QuestieProvider() then self.gatherCache[item]=info end
  return info or nil
end

-- Who can gather at least the given skill: this character first, then twinks on the same realm and faction.
function CP:Gatherers(prof,need)
  local out={}
  local own=self.db.professions[prof]
  if own and self:OwnsProfession(prof) and (own.skill or 0)>=need then out[#out+1]={name=L("du"),skill=own.skill,me=true} end
  local me=self.CurrentCharacter and self:CurrentCharacter()
  for charKey,c in pairs(self.account and self.account.characters or {}) do
    local p=c.professions and c.professions[prof]
    if charKey~=self.characterKey and me and p and c.realm==me.realm and c.faction==me.faction and (p.skill or 0)>=need then
      out[#out+1]={name=c.name or charKey,skill=p.skill}
    end
  end
  table.sort(out,function(a,b) if a.me~=b.me then return a.me==true end return (a.skill or 0)>(b.skill or 0) end)
  return out
end

function CP:GatherHint(item)
  local info=self:GatherInfo(item)
  if not info then return nil end
  local profName=(self.Data.professions[info.prof] or {}).name or info.prof
  local who=self:Gatherers(info.prof,info.skill)
  local best=who[1] and who[1].skill or info.skill
  local zones={}
  for _,z in ipairs(info.zones) do if z.skill<=best and #zones<3 then zones[#zones+1]=self:ZoneName(z.map) end end
  local names={};for i,w in ipairs(who) do if i<=2 then names[#names+1]=w.name end end
  local text=string.format(L("Selbst sammeln (%s %d): %s"),profName,info.skill,table.concat(zones,", "))
  if #names>0 then text=text.." · "..L("kann: ")..table.concat(names,", ") end
  return text,info,who
end

-- Cards for the plan: the gatherable materials still to buy, most expensive first.
function CP:FarmCards(materials)
  local rows={}
  for _,m in ipairs(materials or {}) do
    if (m.missing or 0)>0 and self:GatherInfo(m.id) then rows[#rows+1]=m end
  end
  if #rows==0 then return {} end
  table.sort(rows,function(a,b) return (a.cost or 0)>(b.cost or 0) end)
  local cards={{sectionHeader=true,title=L("SELBST FARMEN STATT KAUFEN")}}
  for i,m in ipairs(rows) do
    if i>5 then break end
    local text,info,who=self:GatherHint(m.id)
    local pace=self.FarmOrBuyText and self:FarmOrBuyText(m.id,m.missing)
    text=text.."\n"..(pace or L("Eigenes Sammeltempo: noch nicht gemessen – CraftPilot misst beim Sammeln mit."))
    local map=info.zones[1] and info.zones[1].map
    cards[#cards+1]={title=m.missing.."× "..self:ItemName(m.id)..(m.cost and (" · "..L("spart ca. ")..self:FormatCostMoney(m.cost)) or ""),
      detail=text,footer=#who==0 and L("Niemand auf dem Account hat den Sammelberuf hoch genug.") or (map and L("Klick: Gebiet auf der Weltkarte zeigen") or ""),
      color=#who>0 and "green" or "blue",tooltipItem=m.id,icon=self.Data.professionIcons and self.Data.professionIcons[info.prof],
      action=map and function() CP:ShowZoneOnMap(map) end or nil}
  end
  return cards
end

function CP:ShowZoneOnMap(map)
  local w=_G.WorldMapFrame
  if type(w)~="table" then return false end
  if type(ToggleWorldMap)=="function" and type(w.IsShown)=="function" and not w:IsShown() then pcall(ToggleWorldMap) end
  if type(w.SetMapID)=="function" then pcall(w.SetMapID,w,map) end
  return true
end
