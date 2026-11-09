-- Optional read-only consumer of the installed QuestieDB public API.
local _,CP=...
local L=CP.L
local function call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok then return value end
end
function CP:QuestieProvider()
  if self.db and self.db.ui.useQuestieDB==false then return nil,"disabled" end
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
  if mode=="absent" then return L("QuestieDB: nicht installiert (optional)") end
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
