-- Read-only consumer of the QuestieDB addon's public API. QuestieDB is optional (recommended) since 1.3.0:
-- trainer names, positions and factions, vendor places, boss drops and the gathering nodes are read from it at
-- runtime. Without it CraftPilot uses its hand-kept trainer list and leaves those extras out.
local _,CP=...
local L=CP.L
local function call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok then return value end
end
function CP:QuestieProvider()
  local lib=_G.LibQuestieDB
  if type(lib)~="table" then return nil,"absent" end
  if call(lib.RequireContract,1)~=true then return nil,"incompatible" end
  local status=lib.ModeIndicator and call(lib.ModeIndicator.GetStatus)
  local mode=type(status)=="table" and status.mode or lib.readMode
  local expansion=type(status)=="table" and status.expansion
  -- Upstream GetStatus reads expansion from read.source, which is absent in baked
  -- packages. Read the same loaded TOC marker the baked backend uses instead.
  if not expansion and mode=="baked" then
    local metadata=(_G.C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    expansion=call(metadata,type(lib.addonName)=="string" and lib.addonName or "QuestieDB","X-Flavor")
  end
  if not expansion then return nil,"unknownFlavor" end
  if expansion~="Forever" then return nil,"flavor",expansion end
  if type(lib.Npc)~="table" or type(lib.Npc.Get)~="function" then return nil,"incompatible" end
  return lib,mode
end
function CP:QuestieStatus()
  local lib,mode,flavor=self:QuestieProvider()
  if lib then return "QuestieDB: "..(mode=="source" and L("aktiv · Entwicklungsmodus") or L("aktiv · Forever")) end
  if mode=="disabled" then return L("QuestieDB: ausgeschaltet") end
  if mode=="absent" then return L("QuestieDB: nicht installiert · empfohlen für alle Lehrer, Sammelgebiete und Boss-Quellen") end
  if mode=="incompatible" then return L("QuestieDB: öffentliche API fehlt oder ist inkompatibel") end
  if mode=="flavor" then return L("QuestieDB: falscher Datenstand · ")..tostring(flavor) end
  return L("QuestieDB: installiert, Forever-Paketkennung fehlt")
end
function CP:QuestieItemVendors(item)
  local lib=self:QuestieProvider()
  if not lib or not lib.Item or type(lib.Item.Get)~="function" then return {} end
  local vendors=call(lib.Item.Get,item,"vendors")
  return type(vendors)=="table" and vendors or {}
end
-- NPCs that drop an item (0.2.1, recipe sources): {id, name}; the zone comes from QuestieNpcZone.
function CP:QuestieItemDrops(item)
  local lib=self:QuestieProvider()
  if not lib or not lib.Item or type(lib.Item.Get)~="function" or type(item)~="number" then return {} end
  local npcs=call(lib.Item.Get,item,"npcDrops")
  local out={}
  for _,id in ipairs(type(npcs)=="table" and npcs or {}) do
    if type(id)=="number" and id>0 then
      local name=call(lib.Npc.Get,id,"name")
      out[#out+1]={id=id,name=type(name)=="string" and name or ("NPC #"..id),zone=self:QuestieNpcZone(id)}
    end
  end
  return out
end
local cachedLib,cachedMaps
local function readMaps(lib)
  if cachedLib==lib and cachedMaps then return cachedMaps end
  local zone=lib.Support and call(lib.Support.Get,"ZoneDB")
  local serialized=type(zone)=="table" and type(zone.private)=="table" and zone.private.areaIdToUiMapId
  if type(serialized)~="string" then return nil end
  -- Public support data is a numeric Lua table string. Parse numeric pairs only;
  -- do not execute it or infer that AreaIDs are UiMapIDs.
  local maps={}
  for area,map in serialized:gmatch("%[(%d+)%]%s*=%s*(%d+)") do
    area,map=tonumber(area),tonumber(map)
    if area>0 and map>0 then maps[area]=map end
  end
  if next(maps) then cachedLib,cachedMaps=lib,maps end
  return maps
end
-- All usable positions of an NPC (UiMap coordinates 0-1), sorted by map and position.
function CP:QuestieNpcPoints(id)
  local lib=self:QuestieProvider()
  if not lib then return {},nil end
  local name=call(lib.Npc.Get,id,"name")
  if type(name)~="string" or name=="" then name=nil end
  local spawns=call(lib.Npc.Get,id,"spawns")
  local maps=readMaps(lib)
  local points={}
  if type(spawns)~="table" or not maps then return points,name end
  for area,locations in pairs(spawns) do
    local map=maps[area]
    if map and type(locations)=="table" then
      for _,point in ipairs(locations) do
        local x,y=type(point)=="table" and point[1],type(point)=="table" and point[2]
        if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (point[3]==nil or point[3]==0) then
          points[#points+1]={map=map,x=x/100,y=y/100}
        end
      end
    end
  end
  table.sort(points,function(a,b)
    if a.map~=b.map then return a.map<b.map end
    if a.x~=b.x then return a.x<b.x end
    return a.y<b.y
  end)
  return points,name
end

-- A trainer record for CraftPilot's trainer list: name, faction, title and one stable position.
local FACTIONS={A="Alliance",H="Horde",AH="B",HA="B"}
function CP:QuestieNpcRecord(id)
  local lib=self:QuestieProvider()
  if not lib then return nil end
  local points,name=self:QuestieNpcPoints(id)
  if not name or #points==0 then return nil end
  local faction=call(lib.Npc.Get,id,"friendlyToFaction")
  local title=call(lib.Npc.Get,id,"subName")
  return {name=name,faction=FACTIONS[faction] or "B",title=type(title)=="string" and title or "",point=points[1]}
end

-- Node counts per UiMap for a list of objects (gathering nodes), from QuestieDB spawns.
function CP:QuestieObjectZones(objects)
  local lib=self:QuestieProvider()
  if not lib or type(lib.Object)~="table" or type(lib.Object.Get)~="function" then return nil end
  local maps=readMaps(lib)
  if not maps then return nil end
  local zones={}
  for obj,skill in pairs(objects) do
    local spawns=call(lib.Object.Get,obj,"spawns")
    for area,locations in pairs(type(spawns)=="table" and spawns or {}) do
      local map=maps[area]
      if map and type(locations)=="table" and #locations>0 then
        local z=zones[map] or {map=map,nodes=0,skill=skill}
        z.nodes=z.nodes+#locations;z.skill=math.min(z.skill,skill)
        zones[map]=z
      end
    end
  end
  return zones
end

function CP:QuestieItemObjects(item)
  local lib=self:QuestieProvider()
  if not lib or type(lib.Item)~="table" or type(lib.Item.Get)~="function" then return {} end
  local drops=call(lib.Item.Get,item,"objectDrops")
  return type(drops)=="table" and drops or {}
end

function CP:QuestieNpcLocation(id,fallback)
  local lib=self:QuestieProvider()
  if not lib then return nil,nil end
  local name=call(lib.Npc.Get,id,"name")
  if type(name)~="string" or name=="" then name=nil end
  local spawns=call(lib.Npc.Get,id,"spawns")
  if type(spawns)~="table" then return nil,name end
  local maps=readMaps(lib)
  if not maps then return nil,name end
  local current=C_Map and call(C_Map.GetBestMapForUnit,"player")
  local points={}
  for area,locations in pairs(spawns) do
    local map=maps[area]
    if map and type(locations)=="table" then
      local info=C_Map and call(C_Map.GetMapInfo,map)
      local usable=not (C_Map and type(C_Map.GetMapInfo)=="function") or type(info)=="table"
      if usable then
        for _,point in ipairs(locations) do
          local x,y=type(point)=="table" and point[1],type(point)=="table" and point[2]
          if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (point[3]==nil or point[3]==0) then
            points[#points+1]={name=name or (fallback and fallback.name) or ("NPC #"..id),
              zone=(info and info.name) or (fallback and fallback.map==map and fallback.zone) or (L("Karte ")..map),
              map=map,x=x/100,y=y/100}
          end
        end
      end
    end
  end
  table.sort(points,function(a,b)
    if (a.map==current)~=(b.map==current) then return a.map==current end
    if fallback and (a.map==fallback.map)~=(b.map==fallback.map) then return a.map==fallback.map end
    if a.map~=b.map then return a.map<b.map end
    if a.x~=b.x then return a.x<b.x end
    return a.y<b.y
  end)
  return points[1],name
end

-- Zone name of an NPC (instance or world) from its QuestieDB zoneID, via the client map name when known.
function CP:QuestieNpcZone(id)
  local lib=self:QuestieProvider()
  if not lib then return nil end
  local area=call(lib.Npc.Get,id,"zoneID")
  if type(area)~="number" or area<=0 then return nil end
  local maps=readMaps(lib)
  local map=maps and maps[area]
  local info=map and C_Map and call(C_Map.GetMapInfo,map)
  return type(info)=="table" and type(info.name)=="string" and info.name or nil
end
