local _, CP = ...
_G.CraftPilot = CP
local D = CP.Data
local pending = false
local pendingCapture = false

local function safe(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  if ok then return value end
  return nil
end

function CP:Say(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffddb978CraftPilot:|r " .. tostring(message))
  end
end

function CP:Initialize()
  if type(CraftPilotDB) ~= "table" then CraftPilotDB = {} end
  local db = CraftPilotDB
  if type(db.professions) ~= "table" then db.professions = {} end
  if type(db.recipes) ~= "table" then db.recipes = {} end
  if not D.professions[db.view] then db.view = "engineering" end
  if db.mode ~= "cash" and db.mode ~= "value" then db.mode = "cash" end
  if type(db.includeBank) ~= "boolean" then db.includeBank = false end
  if type(db.ui) ~= "table" then db.ui = {} end
  if db.ui.skin ~= "auto" and db.ui.skin ~= "dark" and db.ui.skin ~= "classic" then
    db.ui.skin = "auto"
  end
  if type(db.ui.selectedTrainers) ~= "table" then db.ui.selectedTrainers = {} end
  if type(db.ui.position) ~= "table" then db.ui.position = nil end
  self.db = db
  self:Refresh(false)
end

function CP:ItemCount(itemID)
  local includeBank = self.db and self.db.includeBank or false
  local n
  if C_Item then n = safe(C_Item.GetItemCount, itemID, includeBank, false) end
  if type(n) ~= "number" then n = safe(GetItemCount, itemID, includeBank, false) end
  return type(n) == "number" and math.max(0,n) or 0
end

function CP:ItemName(itemID)
  local name
  if C_Item then name = safe(C_Item.GetItemNameByID,itemID) end
  if not name then name = safe(GetItemInfo,itemID) end
  return type(name) == "string" and name or ("Item #" .. tostring(itemID))
end

function CP:Price(itemID)
  local a = _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
  local p = a and safe(a.GetAuctionPriceByItemID, "CraftPilot", itemID)
  if type(p) == "number" and p > 0 then return p end
  return nil
end

-- Gathering skill is obtained from the character profession list: it does not
-- require an open crafting window to display current rank or skill.
function CP:RefreshProfessionSkills()
  if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then return end
  local ok,first,second=pcall(GetProfessions)
  if not ok then return end
  for _,index in ipairs({first or false,second or false}) do
    if type(index)=="number" then
      local success,name,icon,skill,cap,abilities,spellOffset,skillLine=pcall(GetProfessionInfo,index)
      if success and type(skill)=="number" and type(cap)=="number" then
        for key,meta in pairs(D.professions) do
          if meta.id==skillLine then
            self.db.professions[key]={skill=math.max(0,skill),cap=math.max(0,cap),
              name=type(name)=="string" and name or meta.name}
            break
          end
        end
      end
    end
  end
end

function CP:RankCharacterLevel(key,rank)
  if not rank then return 0 end
  local exceptions=D.rankLevelExceptions and D.rankLevelExceptions[key]
  return (exceptions and exceptions[rank.cap]) or rank.level
end

function CP:DetectProfession()
  local T = _G.C_TradeSkillUI
  if not T then return nil end
  if safe(T.IsTradeSkillLinked) or safe(T.IsTradeSkillGuild) or safe(T.IsNPCCrafting) then return nil end
  local info = safe(T.GetBaseProfessionInfo)
  if type(info) ~= "table" then return nil end
  local id = info.professionID or info.skillLineID or info.parentProfessionID
  local name = type(info.professionName) == "string" and info.professionName:lower() or ""
  for key, meta in pairs(D.professions) do
    if id == meta.id then return key, info end
  end
  local patterns = {
    engineering={"ingenieur","engineer"}, mining={"bergbau","mining"},
    blacksmithing={"schmiede","blacksmith"}, enchanting={"verzauber","enchant"},
    herbalism={"kräuter","kraeuter","herbal"}, alchemy={"alchem"},
    tailoring={"schneid","tailor"}, leatherworking={"lederverarbeit","leatherwork"},
  }
  for key, names in pairs(patterns) do
    for _,needle in ipairs(names) do
      if name:find(needle,1,true) then return key,info end
    end
  end
  return nil
end

-- Do not estimate a price when the client reports an optional/multiple-choice
-- reagent: such a recipe cannot be scored accurately from a single item.
local function schematicMats(T,recipeID)
  local schematic = safe(T.GetRecipeSchematic,recipeID,false)
  if type(schematic) ~= "table" or type(schematic.reagentSlotSchematics) ~= "table" then
    return nil
  end
  local mats={}
  for _,slot in ipairs(schematic.reagentSlotSchematics) do
    local qty = slot.quantityRequired or 0
    if qty > 0 then
      if slot.reagentType ~= nil and slot.reagentType ~= 1 then return nil end
      if type(slot.reagents) ~= "table" or #slot.reagents ~= 1
          or type(slot.reagents[1].itemID) ~= "number" then return nil end
      mats[#mats+1] = {slot.reagents[1].itemID,qty}
    end
  end
  if #mats == 0 then return nil end
  return mats
end

function CP:CaptureProfession()
  local key, info = self:DetectProfession()
  if not key then return false end
  local skill=math.max(0,tonumber(info.skillLevel) or 0)
  local cap=math.max(0,tonumber(info.maxSkillLevel) or 0)
  self.db.professions[key] = {skill=skill,cap=cap,name=info.professionName or D.professions[key].name}
  self.db.view=key
  local T=C_TradeSkillUI
  local ids=safe(T.GetAllRecipeIDs)
  local filtered=false
  if type(ids)~="table" or #ids==0 then
    ids=safe(T.GetFilteredRecipeIDs)
    filtered=true
  end
  if type(ids)~="table" then return true end
  local known=self.db.recipes[key] or {}
  self.db.recipes[key]=known
  local count=0
  for _,id in ipairs(ids) do
    local detail=safe(T.GetRecipeInfo,id)
    if type(detail)=="table" and type(id)=="number" then
      local old=known[id] or {}
      old.name=detail.name or old.name or ("Rezept "..id)
      old.learned=detail.learned == true
      old.disabled=detail.disabled == true
      old.canSkillUp=detail.canSkillUp
      old.difficulty=detail.relativeDifficulty
      old.snapshotSkill=skill
      local mats=schematicMats(T,id)
      if mats then old.mats=mats end
      known[id]=old
      count=count+1
    end
  end
  self.db.lastCapture={key=key,skill=skill,filtered=filtered,count=count}
  return true
end

local odds={ [0]=1, [1]=0.70, [2]=0.35, [3]=0 }
function CP:Options(profession)
  local p=self.db.professions[profession]
  if not p or D.professions[profession].gathering then return {} end
  local values={}
  -- Recipe difficulty refers only to the skill at the time of capture.
  for id,recipe in pairs(self.db.recipes[profession] or {}) do
    local chance=odds[recipe.difficulty]
    if recipe.learned and not recipe.disabled and recipe.canSkillUp ~= false
       and recipe.snapshotSkill == p.skill and chance and chance > 0
       and type(recipe.mats)=="table" then
      local cost,missing,unknown=0,0,{}
      for _,mat in ipairs(recipe.mats) do
        local item,needed=mat[1],mat[2]
        local owned=self:ItemCount(item)
        local deficit=math.max(0,needed-owned)
        missing=missing+deficit
        local pricedQty=self.db.mode=="value" and needed or deficit
        if pricedQty>0 then
          local price=self:Price(item)
          if price then cost=cost+price*pricedQty else unknown[#unknown+1]=item end
        end
      end
      values[#values+1]={id=id, name=recipe.name, mats=recipe.mats,
        chance=chance, cost=cost/chance, missing=missing,
        unknown=#unknown>0, unknownItems=unknown}
    end
  end
  table.sort(values,function(a,b)
    if a.unknown~=b.unknown then return not a.unknown end
    if a.cost~=b.cost then return a.cost<b.cost end
    if a.missing~=b.missing then return a.missing<b.missing end
    if a.chance~=b.chance then return a.chance>b.chance end
    return a.id<b.id
  end)
  return values
end

function CP:CurrentStage(key)
  local skill=(self.db.professions[key] or {}).skill or 1
  for _,stage in ipairs(D.stages[key] or {}) do
    if skill>=stage[1] and skill<stage[2] then return stage end
  end
  return (D.stages[key] or {})[#(D.stages[key] or {})]
end

function CP:NextRank(key)
  local p=self.db.professions[key] or {}
  local cap=p.cap or 0
  for _,rank in ipairs(D.ranks) do
    if rank.cap > cap then return rank end
  end
  return nil
end

local function playerMap()
  return C_Map and safe(C_Map.GetBestMapForUnit,"player") or nil
end
local function playerFaction()
  return safe(UnitFactionGroup,"player") or "B"
end

-- A map distance is NOT travel distance. Only compare positions on the SAME
-- UiMapID. Do not invent distances between cities, continents or dungeon floors.
function CP:TrainerChoices(key)
  local rank=self:NextRank(key)
  local required=rank and rank.cap or 300
  local faction=playerFaction()
  local map=playerMap()
  local position
  if map and C_Map then position=safe(C_Map.GetPlayerMapPosition,map,"player") end
  local px,py
  if position and type(position.GetXY)=="function" then
    local ok,x,y=pcall(position.GetXY,position)
    if ok then px,py=x,y end
  end
  local entries={}
  local nearest,nearDist
  for _,npc in ipairs(D.trainers) do
    if npc.profession==key and (npc.faction==faction or npc.faction=="B") then
      local inZone=(npc.map==map)
      local distance
      if inZone and type(px)=="number" and type(py)=="number" then
        local dx,dy=(npc.x-px)*100,(npc.y-py)*100
        distance=math.sqrt(dx*dx+dy*dy)
      end
      local entry={
        npc=npc, canTeach=npc.cap>=required,
        inZone=inZone,distance=distance
      }
      entries[#entries+1]=entry
      if distance and (not nearDist or distance<nearDist) then
        nearDist,nearest=distance,npc
      end
    end
  end
  table.sort(entries,function(a,b)
    if a.canTeach~=b.canTeach then return a.canTeach end
    if a.inZone~=b.inZone then return a.inZone end
    if a.distance and b.distance and a.distance~=b.distance then
      return a.distance<b.distance
    end
    if a.npc.cap~=b.npc.cap then return a.npc.cap>b.npc.cap end
    return a.npc.name<b.npc.name
  end)
  local recommended
  for _,entry in ipairs(entries) do
    if entry.canTeach then recommended=entry.npc;break end
  end
  return entries,rank,recommended,nearest
end

function CP:FindTrainer(key)
  local entries,rank,recommended=self:TrainerChoices(key)
  return recommended,rank
end

function CP:SetWaypoint(npc)
  if not npc then return self:Say("Kein passender Standort hinterlegt.") end
  local title="CraftPilot: "..npc.name.." ("..npc.zone..")"
  local t=_G.TomTom
  if t and type(t.AddWaypoint)=="function" then
    local ok,uid=pcall(t.AddWaypoint,t,npc.map,npc.x,npc.y,
      {title=title,crazy=true,persistent=false})
    if ok and uid~=false and uid~=nil then
      self:Say("Wegpunkt: "..title)
      if npc.indoor then self:Say("Achtung: Zielmarkierung ist nur der Instanzeingang.") end
      return true
    end
  end
  if _G.UiMapPoint and type(UiMapPoint.CreateFromCoordinates)=="function"
     and C_Map and type(C_Map.SetUserWaypoint)=="function" then
    local point=safe(UiMapPoint.CreateFromCoordinates,npc.map,npc.x,npc.y)
    if point then
      local ok=pcall(C_Map.SetUserWaypoint,point)
      if ok then
        if C_SuperTrack then safe(C_SuperTrack.SetSuperTrackedUserWaypoint,true) end
        self:Say("Kartenmarkierung: "..title)
        if npc.indoor then self:Say("Achtung: Zielmarkierung ist nur der Instanzeingang.") end
        return true
      end
    end
  end
  self:Say(string.format("%s, %s: %.1f / %.1f (Karte %d). TomTom empfohlen.",
    npc.name,npc.zone,npc.x*100,npc.y*100,npc.map))
  return false
end

function CP:TrainerWaypoint(which)
  local choices,rank,recommended,nearest=self:TrainerChoices(self.db.view)
  local npc = which=="nearest" and nearest or recommended
  if which=="nearest" and not nearest then
    return self:Say("Der nächste Lehrer ist kartenübergreifend nicht zuverlässig bestimmbar. Bitte in der Lehrerübersicht selbst auswählen.")
  end
  if rank then
    local p=self.db.professions[self.db.view] or {}
    if (p.skill or 0)<rank.min then self:Say("Rang "..rank.name.." ab Skill "..rank.min..".") end
    local requiredLevel=self:RankCharacterLevel(self.db.view,rank)
    if (safe(UnitLevel,"player") or 0)<requiredLevel then
      self:Say("Rang "..rank.name.." benötigt Charakterstufe "..requiredLevel..".")
    end
  end
  self:SetWaypoint(npc)
end

function CP:ShowShopping()
  local options=self:Options(self.db.view)
  if #options==0 then
    return self:Say("Kein auswertbares gelerntes Rezept. Berufsfenster öffnen.")
  end
  local best=options[1]
  self:Say("Nächstes Rezept: "..best.name.." (1 Herstellung; Preisstand: letzter Auctionator-Scan)")
  for _,mat in ipairs(best.mats) do
    local required=mat[2]
    local missing=math.max(0,required-self:ItemCount(mat[1]))
    if missing>0 then
      local price=self:Price(mat[1])
      self:Say(string.format("%d x %s%s",missing,self:ItemName(mat[1]),
        price and string.format(" (ca. %d Kupfer/Stk.)",price) or " (kein AH-Preis)"))
    end
  end
end

function CP:ChangeView(key)
  if not D.professions[key] then return end
  self.db.view=key
  self:Refresh(false)
end

function CP:Refresh(capture)
  if not self.db then return end
  self:RefreshProfessionSkills()
  if capture then self:CaptureProfession() end
  if self.Render then self:Render() end
end

local aliases={
  ingi="engineering", engineering="engineering",
  bergbau="mining", mining="mining",
  schmied="blacksmithing", blacksmithing="blacksmithing",
  vz="enchanting", verzauberung="enchanting", enchanting="enchanting",
  schneider="tailoring", tailoring="tailoring",
  leder="leatherworking", leatherworking="leatherworking",
  kraeuter="herbalism", ["kräuter"]="herbalism", kraut="herbalism", herbalism="herbalism",
  alchemie="alchemy", alchemy="alchemy",
}
local function command(input)
  if not CP.db then return end
  local text=(input or ""):match("^%s*(.-)%s*$"):lower()
  if text=="" or text=="show" then
    if CP.ToggleWindow then CP:ToggleWindow() end
  elseif aliases[text] then
    CP:ChangeView(aliases[text])
    if CP.frame then CP.frame:Show() end
  elseif text=="refresh" then
    CP:Refresh(true); CP:Say("Aktualisiert.")
  elseif text=="trainer" then CP:TrainerWaypoint()
  elseif text=="naechster" or text=="nächster" then CP:TrainerWaypoint("nearest")
  elseif text=="lehrer" or text=="lehrerlist" then
    if CP.OpenTab then CP:OpenTab("trainers") end
  elseif text=="etappen" then
    if CP.OpenTab then CP:OpenTab("stages") end
  elseif text=="hilfe" or text=="help" then
    if CP.OpenTab then CP:OpenTab("help") end
  elseif text=="resetpos" then
    if CP.ResetWindowPosition then CP:ResetWindowPosition() end
  elseif text=="skin auto" or text=="skin dark" or text=="skin classic" then
    CP.db.ui.skin=text:sub(6)
    if CP.ApplyTheme then CP:ApplyTheme() end
    CP:Refresh(false)
    CP:Say("Darstellung: "..CP.db.ui.skin)
  elseif text=="liste" or text=="list" then CP:ShowShopping()
  elseif text=="mode cash" or text=="mode value" then
    CP.db.mode=text:sub(6);CP:Refresh(false)
  elseif text=="bank on" or text=="bank off" then
    CP.db.includeBank=text=="bank on";CP:Refresh(false)
  else
    CP:Say("Hilfe im Addon: /cp hilfe. Direkt: /cp lehrer | etappen | trainer | naechster | liste | resetpos | skin auto|dark|classic.")
  end
end

local events=CreateFrame("Frame")
local names={"PLAYER_LOGIN","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE",
  "TRADE_SKILL_DATA_SOURCE_CHANGED","BAG_UPDATE_DELAYED","PLAYER_LEVEL_UP"}
for _,name in ipairs(names) do pcall(events.RegisterEvent,events,name) end
local function schedule(capture)
  pendingCapture=pendingCapture or capture
  if pending then return end
  pending=true
  local function run()
    pending=false
    local requested=pendingCapture
    pendingCapture=false
    if CP.db then CP:Refresh(requested) end
  end
  if C_Timer and type(C_Timer.After)=="function" then
    C_Timer.After(0.3,run)
  else
    run()
  end
end
events:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then
    CP:Initialize()
    SLASH_CRAFTPILOT1="/cp"
    SLASH_CRAFTPILOT2="/craftpilot"
    SlashCmdList.CRAFTPILOT=command
  elseif CP.db and (event~="BAG_UPDATE_DELAYED" or (CP.frame and CP.frame:IsShown())) then
    schedule(event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_LIST_UPDATE"
      or event=="TRADE_SKILL_DATA_SOURCE_CHANGED")
  end
end)
