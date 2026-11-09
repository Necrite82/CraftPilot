local _, CP = ...
local L=CP.L
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
  if type(db.includeBank) ~= "boolean" then db.includeBank = true end
  if type(db.ui) ~= "table" then db.ui = {} end
  if db.ui.skin ~= "auto" and db.ui.skin ~= "dark" and db.ui.skin ~= "classic" then
    db.ui.skin = "auto"
  end
  if type(db.ui.selectedTrainers) ~= "table" then db.ui.selectedTrainers = {} end
  if type(db.ui.selectedRecipes) ~= "table" then db.ui.selectedRecipes = {} end
  if type(db.plans) ~= "table" then db.plans = {} end
  if type(db.ui.autoOpen) ~= "boolean" then db.ui.autoOpen = true end
  if type(db.bank) ~= "table" then db.bank = {} end
  if type(db.bank.items) ~= "table" then db.bank.items = {} end
  if not ({cost=true,chance=true,missing=true,name=true})[db.ui.recipeSort] then
    db.ui.recipeSort="cost"
  end
  if type(db.ui.width) ~= "number" then db.ui.width=750 end
  if type(db.ui.height) ~= "number" then db.ui.height=676 end
  if type(db.ui.position) ~= "table" then db.ui.position = nil end
  self.db = db
  if self.MigrateEconomyState then self:MigrateEconomyState() end
  if self.InitializeCostingState then self:InitializeCostingState() end
  if self.InitializeControls then self:InitializeControls() end
  if self.InitializeVersionChecks then self:InitializeVersionChecks() end
  self:Refresh(false)
end

-- Bank stock is a saved snapshot from the last actual bank visit.
-- Closed-bank data is never labelled as live.
function CP:RawItemCount(itemID, includeBank)
  local n
  if C_Item then n=safe(C_Item.GetItemCount,itemID,includeBank,false) end
  if type(n)~="number" then n=safe(GetItemCount,itemID,includeBank,false) end
  return type(n)=="number" and math.max(0,n) or 0
end

function CP:BankCount(itemID)
  if not self.db then return 0,false end
  local bank=self.db.bank
  if self.bankIsOpen then
    local value=math.max(0,self:RawItemCount(itemID,true)-self:RawItemCount(itemID,false))
    bank.items[itemID]=value
    if type(time)=="function" then bank.scannedAt=time() end
    return value,true,true
  end
  local cached=bank.items[itemID]
  return type(cached)=="number" and math.max(0,cached) or 0,false,
    type(cached)=="number"
end

function CP:ItemAvailability(itemID)
  local bags=self:RawItemCount(itemID,false)
  if self.db and self.db.includeBank then
    local bank,live,known=self:BankCount(itemID)
    return bags+bank,bags,bank,live,known
  end
  return bags,bags,0,false,true
end

function CP:ItemCount(itemID)
  local count=self:ItemAvailability(itemID)
  return count
end

function CP:BankStatus()
  if not self.db then return L("Bank nicht erfasst") end
  if not self.db.includeBank then return L("Bank aus") end
  if self.bankIsOpen then return "Bank LIVE" end
  if self.db.bank.scannedAt then
    local stamp=type(date)=="function" and date("%d.%m. %H:%M",self.db.bank.scannedAt)
    return L("Bank zuletzt erfasst")..(stamp and (" "..stamp) or "")
  end
  return L("Bank unbekannt – einmal öffnen")
end

function CP:SnapshotBankMaterials()
  if not self.bankIsOpen or not self.db then return end
  local items={}
  for _,recipes in pairs(self.db.recipes) do
    for _,recipe in pairs(recipes) do
      if type(recipe.mats)=="table" then
        for _,mat in ipairs(recipe.mats) do
          if type(mat[1])=="number" then items[mat[1]]=true end
        end
      end
    end
  end
  for itemID in pairs(items) do self:BankCount(itemID) end
  if type(time)=="function" then self.db.bank.scannedAt=time() end
end

function CP:ItemName(itemID)
  local name
  if C_Item then name = safe(C_Item.GetItemNameByID,itemID) end
  if not name then name = safe(GetItemInfo,itemID) end
  return type(name) == "string" and name or ("Item #" .. tostring(itemID))
end

function CP:Price(itemID)
  if type(self.PriceDetails)=="function" then
    local data=self:PriceDetails(itemID)
    return data and data.price
  end
  local a = _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
  local p = a and safe(a.GetAuctionPriceByItemID, "CraftPilot", itemID)
  if type(p) == "number" and p > 0 then return p end
  return nil
end

-- Gathering skill is obtained from the character profession list: it does not
-- require an open crafting window to display current rank or skill.
function CP:RefreshProfessionSkills()
  if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then return end
  local ok,first,second,archaeology,fishing,cooking,firstaid=pcall(GetProfessions)
  if not ok then return end
  for _,index in ipairs({first or false,second or false,fishing or false,cooking or false,firstaid or false}) do
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
    skinning={"kürschner","kuerschner","skinning"}, cooking={"kochen","cooking"},
    firstaid={"erste hilfe","first aid"}, fishing={"angeln","fishing"},
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
      old.name=detail.name or old.name or (L("Rezept ")..id)
      if detail.icon or detail.iconID then old.icon=detail.icon or detail.iconID end
      local output=safe(T.GetRecipeOutputItemData,id)
      if type(output)=="table" then
        old.outputItemID=output.itemID or old.outputItemID
        old.icon=output.icon or output.iconID or old.icon
      end
      old.learned=detail.learned == true
      old.disabled=detail.disabled == true
      old.canSkillUp=detail.canSkillUp
      old.difficulty=detail.relativeDifficulty
      old.snapshotSkill=skill
      local mats=schematicMats(T,id)
      old.mats=mats
      known[id]=old
      count=count+1
    end
  end
  self.db.lastCapture={key=key,skill=skill,filtered=filtered,count=count}
  local selected=self.db.ui.selectedVendorRecipe
  if self.db.ui.selectedVendorKey==key and known[selected] and known[selected].learned then
    self.db.ui.selectedRecipes[key]=selected
    self.db.ui.selectedVendorRecipe=nil;self.db.ui.selectedVendorKey=nil
    self.db.ui.vendorOnly=false
  end
  if self.bankIsOpen then self:SnapshotBankMaterials() end
  return true
end

local odds={ [0]=1, [1]=0.70, [2]=0.35, [3]=0 }
function CP:Options(profession)
  local p=self.db.professions[profession]
  if not p or (type(p.cap)=="number" and p.skill>=p.cap) or (D.professions[profession].gathering and not D.professions[profession].crafting) then return {} end
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
      values[#values+1]={id=id, name=recipe.name, icon=recipe.icon, outputItemID=recipe.outputItemID, mats=recipe.mats,
        chance=chance, difficulty=recipe.difficulty, cost=cost/chance, missing=missing,
        unknown=#unknown>0, unknownItems=unknown}
    end
  end
  table.sort(values,function(a,b)
    if a.unknown~=b.unknown then return not a.unknown end
    if self.db.ui.preferReliableSkill and (a.chance<.5)~=(b.chance<.5) then return a.chance>=.5 end
    if a.cost~=b.cost then return a.cost<b.cost end
    if a.missing~=b.missing then return a.missing<b.missing end
    if a.chance~=b.chance then return a.chance>b.chance end
    return a.id<b.id
  end)
  return values
end

function CP:SortedOptions(profession)
  local items=self:Options(profession)
  local mode=self.db.ui.recipeSort
  if mode=="cost" then return items end
  table.sort(items,function(a,b)
    if mode=="chance" and a.chance~=b.chance then return a.chance>b.chance end
    if mode=="missing" and a.missing~=b.missing then return a.missing<b.missing end
    if mode=="name" and a.name~=b.name then return a.name<b.name end
    if a.unknown~=b.unknown then return not a.unknown end
    if a.cost~=b.cost then return a.cost<b.cost end
    return a.id<b.id
  end)
  return items
end

function CP:SelectedOption(profession)
  local list=self:SortedOptions(profession)
  local selected=self.db.ui.selectedRecipes[profession]
  if type(selected)=="number" then
    for _,entry in ipairs(list) do
      if entry.id==selected then return entry,list end
    end
  end
  return list[1],list
end

function CP:CurrentStage(key)
  local skill=(self.db.professions[key] or {}).skill or 1
  for _,stage in ipairs(D.stages[key] or {}) do
    if skill>=stage[1] and skill<stage[2] then return stage end
  end
  return (D.stages[key] or {})[#(D.stages[key] or {})]
end

function CP:NextRank(key)
  if D.professions[key].ranksUnverified then return nil end
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
    if a.canTeach and b.canTeach then
      local aExact=a.npc.cap==required
      local bExact=b.npc.cap==required
      if aExact~=bExact then return aExact end
    end
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
  if not npc then return self:Say(L("Kein passender Standort hinterlegt.")) end
  local title="CraftPilot: "..npc.name.." ("..npc.zone..")"
  local t=_G.TomTom
  if t and type(t.AddWaypoint)=="function" then
    local ok,uid=pcall(t.AddWaypoint,t,npc.map,npc.x,npc.y,
      {title=title,crazy=true,persistent=false})
    if ok and uid~=false and uid~=nil then
      self:Say(L("Wegpunkt: ")..title)
      if npc.indoor then self:Say(L("Achtung: Zielmarkierung ist nur der Instanzeingang.")) end
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
        self:Say(L("Kartenmarkierung: ")..title)
        if npc.indoor then self:Say(L("Achtung: Zielmarkierung ist nur der Instanzeingang.")) end
        return true
      end
    end
  end
  self:Say(string.format(L("%s, %s: %.1f / %.1f (Karte %d). TomTom empfohlen."),
    npc.name,npc.zone,npc.x*100,npc.y*100,npc.map))
  return false
end

function CP:TrainerWaypoint(which)
  local choices,rank,recommended,nearest=self:TrainerChoices(self.db.view)
  local npc = which=="nearest" and nearest or recommended
  if which=="nearest" and not nearest then
    return self:Say(L("Der nächste Lehrer ist kartenübergreifend nicht zuverlässig bestimmbar. Bitte in der Lehrerübersicht selbst auswählen."))
  end
  if rank then
    local p=self.db.professions[self.db.view] or {}
    if (p.skill or 0)<rank.min then self:Say(L("Rang ")..rank.name..L(" ab Skill ")..rank.min..".") end
    local requiredLevel=self:RankCharacterLevel(self.db.view,rank)
    if (safe(UnitLevel,"player") or 0)<requiredLevel then
      self:Say(L("Rang ")..rank.name..L(" benötigt Charakterstufe ")..requiredLevel..".")
    end
  end
  self:SetWaypoint(npc)
end

function CP:ShowShopping()
  local chosen,options=self:SelectedOption(self.db.view)
  if #options==0 then
    return self:Say(L("Kein auswertbares gelerntes Rezept. Berufsfenster öffnen."))
  end
  local best=chosen
  self:Say(L("Rezept: ")..best.name..L(" (1 Herstellung; Preisstand: letzter Auctionator-Scan)"))
  for _,mat in ipairs(best.mats) do
    local required=mat[2]
    local missing=math.max(0,required-self:ItemCount(mat[1]))
    if missing>0 then
      local price=self:Price(mat[1])
      self:Say(string.format("%d x %s%s",missing,self:ItemName(mat[1]),
        price and string.format(L(" (ca. %d Kupfer/Stk.)"),price) or L(" (kein AH-Preis)")))
    end
  end
end


-- Opening a profession is hardware-event restricted. Call only from a user
-- click, never from deferred timers, rendering, login or item update events.
function CP:OwnsProfession(key)
  if not self.db or not D.professions[key] then return false end
  if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then return false end
  local success,first,second,archaeology,fishing,cooking,firstaid=pcall(GetProfessions)
  if not success then return false end
  for _,index in ipairs({first or false,second or false,fishing or false,cooking or false,firstaid or false}) do
    if type(index)=="number" then
      local ok,name,icon,skill,cap,abilities,spellOffset,skillLine=
        pcall(GetProfessionInfo,index)
      if ok and skillLine==D.professions[key].id then return true end
    end
  end
  return false
end

function CP:VisibleProfessions()
  local owned,others={},{}
  for _,key in ipairs(D.order) do
    local list=self:OwnsProfession(key) and owned or others
    list[#list+1]=key
  end
  if self.db.ui.showAllProfessions or #owned==0 then
    for _,key in ipairs(others) do owned[#owned+1]=key end
  elseif not self:OwnsProfession(self.db.view) then
    -- Keep explicitly selected reference professions reachable without switching
    -- the player's view during refresh or opening a profession automatically.
    owned[#owned+1]=self.db.view
  end
  return owned
end

function CP:OpenOwnedProfession(key)
  if not self:OwnsProfession(key) then return false end
  if type(InCombatLockdown)=="function" and InCombatLockdown() then
    self:Say(L("Berufsfenster kann im Kampf gesperrt sein."))
    return false
  end
  local T=_G.C_TradeSkillUI
  if T and type(T.OpenTradeSkill)=="function" then
    -- Restricted hardware-event API: call directly from the click path, not pcall.
    if T.OpenTradeSkill(D.professions[key].id)==true then return true end
  end
  -- Gathering without a crafting panel can still be selected in CraftPilot.
  self:Say(L("Berufsfenster konnte nicht geöffnet werden. Skillplan bleibt nutzbar."))
  return false
end

-- This planner intentionally never promises a complete skill-up route. Recipe
-- quantities are explicit decisions; reagents form an exact gross shopping list
-- for those crafts, while future skill-ups remain uncertain.
local function clampSkill(n)
  n=math.floor(tonumber(n) or 1)
  return math.max(1,math.min(300,n))
end
function CP:PlanFor(key)
  if not self.db or not D.professions[key] then return nil end
  local current=(self.db.professions[key] or {}).skill or 1
  local p=self.db.plans[key]
  if type(p)~="table" then
    p={start=math.max(1,math.min(299,math.floor(current))),target=math.min(300,math.max(2,math.floor(current)+25)),crafts={}}
    self.db.plans[key]=p
  end
  if type(p.crafts)~="table" then p.crafts={} end
  if type(p.autoMode)~="boolean" then p.autoMode=false end
  p.start=clampSkill(p.start)
  p.target=clampSkill(p.target)
  if p.start>=p.target then p.target=math.min(300,p.start+1) end
  if p.start>=p.target then p.start=299;p.target=300 end
  return p
end

function CP:SetPlanRange(key,first,last)
  local p=self:PlanFor(key)
  if not p then return false end
  local a,b=clampSkill(first),clampSkill(last)
  if a>=b then return false end
  p.start,p.target=a,b
  p.autoRoute=nil
  p.autoMode=false
  return true
end

function CP:AddPlanCraft(key,recipeID,quantity)
  local p=self:PlanFor(key)
  local recipe=self.db.recipes[key] and self.db.recipes[key][recipeID]
  local count=math.floor(tonumber(quantity) or 0)
  if not p or not recipe or not recipe.learned
     or type(recipe.mats)~="table" or #recipe.mats==0
     or count<1 or count>999 then return false end
  p.crafts[recipeID]=math.min(9999,(p.crafts[recipeID] or 0)+count)
  p.autoMode=false
  return true
end

function CP:ClearPlanCraft(key,recipeID)
  local p=self:PlanFor(key)
  if not p then return end
  if type(recipeID)=="number" then p.crafts[recipeID]=nil
  else p.crafts={} end
  p.autoMode=false
  p.autoRoute=nil
end

function CP:DraftPlanStep(key)
  local p=self:PlanFor(key)
  if not p or (D.professions[key].gathering and not D.professions[key].crafting) then return false end
  local current=(self.db.professions[key] or {}).skill or 0
  if current~=p.start then
    self:Say(L("Schnellvorschlag nur ab aktuellem Skill. Startwert anpassen."))
    return false
  end
  local choice=self:SelectedOption(key)
  if not choice or not choice.chance or choice.chance<=0 then
    self:Say(L("Noch kein auswertbares Rezept. Berufsfenster öffnen."))
    return false
  end
  local rank=(self.db.professions[key] or {}).cap or 0
  local points=math.min(10,p.target-current,math.max(0,rank-current))
  if points<=0 then
    self:Say(L("Erst den nächsten Ausbildungsrang lernen."))
    return false
  end
  local expectedCrafts=math.max(1,math.ceil(points/choice.chance))
  local ok=self:AddPlanCraft(key,choice.id,expectedCrafts)
  if ok then
    self:Say(L("Unverbindlicher erster Schritt: ")..expectedCrafts.."x "..choice.name
      ..L(" (ca. ")..points..L(" Skillpunkte bei heutiger Skillfarbe)."))
  end
  return ok
end

function CP:PlanShopping(key)
  local p=self:PlanFor(key)
  if not p then return nil end
  local aggregate={}
  local steps={}
  local craftCount=0
  local expected=0
  local uncertainSkills=false
  for id,qty in pairs(p.crafts) do
    if type(qty)=="number" and qty>0 then
      local recipe=self.db.recipes[key] and self.db.recipes[key][id]
      if recipe and type(recipe.mats)=="table" then
        steps[#steps+1]={id=id,name=self:RecipeName(key,id,recipe.name),quantity=qty}
        craftCount=craftCount+qty
        local snapshot=(self.db.professions[key] or {}).skill or 0
        local chances={ [0]=1,[1]=.70,[2]=.35,[3]=0 }
        local chance=chances[recipe.difficulty]
        if recipe.snapshotSkill==snapshot and chance then
          expected=expected+qty*chance
        else uncertainSkills=true end
        for _,mat in ipairs(recipe.mats) do
          if type(mat[1])=="number" and type(mat[2])=="number" then
            aggregate[mat[1]]=(aggregate[mat[1]] or 0)+qty*mat[2]
          end
        end
      end
    end
  end
  table.sort(steps,function(a,b) return a.name<b.name end)
  local materials={}
  local purchaseCopper=0
  local noPrice=0
  local unknownBank=0
  for id,required in pairs(aggregate) do
    local total,bag,bank,live,known=self:ItemAvailability(id)
    local missing=math.max(0,required-total)
    local price=self:Price(id)
    local estimate=missing>0 and price and price*missing or nil
    if estimate then purchaseCopper=purchaseCopper+estimate end
    if missing>0 and not price then noPrice=noPrice+1 end
    if self.db.includeBank and not known then unknownBank=unknownBank+1 end
    materials[#materials+1]={
      id=id,name=self:ItemName(id),required=required,bag=bag,bank=bank,
      bankKnown=known,bankLive=live,missing=missing,price=price,
      cost=estimate
    }
  end
  table.sort(materials,function(a,b) return a.name<b.name end)
  return {
    first=p.start,last=p.target,steps=steps,materials=materials,
    crafts=craftCount,purchaseCopper=purchaseCopper,noPrice=noPrice,
    unknownBank=unknownBank,expectedSkillUps=expected,
    uncertainSkills=uncertainSkills
  }
end

function CP:PrintPlanShopping(key)
  local plan=self:PlanFor(key)
  if plan and plan.autoMode and self:PrintRouteShopping(key) then return end
  local result=self:PlanShopping(key)
  if not result then return end
  self:Say((L("Einkaufsliste %s, Skill %d–%d: %d geplante Herstellungen"))
    :format(D.professions[key].name,result.first,result.last,result.crafts))
  if #result.steps==0 then return self:Say(L("Noch keine Rezepte im Plan. Im Planer hinzufügen.")) end
  for _,mat in ipairs(result.materials) do
    if mat.missing>0 then
      local total=mat.cost and (math.floor(mat.cost/10000).."g "..math.floor(mat.cost%10000/100).."s") or L("Preis fehlt")
      self:Say(mat.missing.."x "..mat.name..L(" (ca. ")..total..")")
    end
  end
  self:Say(L("Achtung: Liste deckt nur ausdrücklich ausgewählte Rezepte ab. Kein garantierter Skillweg."))
end

function CP:ChangeView(key,openNative)
  if not D.professions[key] then return end
  self.db.view=key
  if self.db.ui.tab=="settings" or self.db.ui.tab=="help" then self.db.ui.tab="now" end
  if openNative and self.db.ui.autoOpen then self:OpenOwnedProfession(key) end
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
  kuerschner="skinning", ["kürschner"]="skinning", skinning="skinning",
  kochen="cooking", cooking="cooking", erstehilfe="firstaid", firstaid="firstaid",
  angeln="fishing", fishing="fishing",
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
    CP:Refresh(true); CP:Say(L("Aktualisiert."))
  elseif text=="trainer" then CP:TrainerWaypoint()
  elseif text=="naechster" or text=="nächster" then CP:TrainerWaypoint("nearest")
  elseif text=="lehrer" or text=="lehrerlist" then
    if CP.OpenTab then CP:OpenTab("trainers") end
  elseif text=="etappen" then
    if CP.OpenTab then CP:OpenTab("stages") end
  elseif text=="plan" or text=="einkaufsliste" then
    if CP.OpenTab then CP:OpenTab("plan") end
  elseif text=="einkauf" then
    CP:PrintPlanShopping(CP.db.view)
  elseif text=="autoplan" then
    local ok,result=CP:BuildRouteForCurrentPlan(CP.db.view)
    if ok then
      CP:Say(L("Vorschlag erstellt: ")..#result.steps..L(" Schritte, bis Skill ")..result.reached..".")
      CP:Refresh(false)
    else CP:Say(result or L("Kein geeigneter Rezeptkatalog.")) end
  elseif text=="autoopen on" or text=="autoopen off" then
    CP.db.ui.autoOpen=text=="autoopen on"
    CP:Say(L("Berufsfenster automatisch öffnen: ")..(CP.db.ui.autoOpen and L("AN") or L("AUS")))
  elseif text=="hilfe" or text=="help" then
    if CP.OpenTab then CP:OpenTab("help") end
  elseif text=="resetpos" then
    if CP.ResetWindowPosition then CP:ResetWindowPosition() end
  elseif text=="skin auto" or text=="skin dark" or text=="skin classic" then
    CP.db.ui.skin=text:sub(6)
    if CP.ApplyTheme then CP:ApplyTheme() end
    CP:Refresh(false)
    CP:Say(L("Darstellung: ")..CP.db.ui.skin)
  elseif text=="liste" or text=="list" then CP:ShowShopping()
  elseif text=="mode cash" or text=="mode value" then
    CP.db.mode=text:sub(6);CP:Refresh(false)
  elseif text=="bank on" or text=="bank off" then
    CP.db.includeBank=text=="bank on";CP:Refresh(false)
  elseif text=="sort cost" or text=="sort chance" or text=="sort missing" or text=="sort name" then
    CP.db.ui.recipeSort=text:sub(6);CP:Refresh(false)
  else
    CP:Say(L("Hilfe im Addon: /cp hilfe. Direkt: /cp lehrer | etappen | trainer | naechster | liste | resetpos | skin auto|dark|classic."))
  end
end

local events=CreateFrame("Frame")
local names={"PLAYER_LOGIN","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE",
  "TRADE_SKILL_DATA_SOURCE_CHANGED","NEW_RECIPE_LEARNED","BAG_UPDATE_DELAYED","PLAYER_LEVEL_UP",
  "BANKFRAME_OPENED","BANKFRAME_CLOSED","PLAYERBANKSLOTS_CHANGED"}
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
  elseif event=="BANKFRAME_OPENED" then
    CP.bankIsOpen=true
    CP:SnapshotBankMaterials()
    if CP.db then CP:Refresh(false) end
  elseif event=="BANKFRAME_CLOSED" then
    CP.bankIsOpen=false
    if CP.db then CP:Refresh(false) end
  elseif event=="PLAYERBANKSLOTS_CHANGED" then
    if CP.bankIsOpen then CP:SnapshotBankMaterials() end
    if CP.db then CP:Refresh(false) end
  elseif CP.db and (event~="BAG_UPDATE_DELAYED" or (CP.frame and CP.frame:IsShown())) then
    schedule(event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_LIST_UPDATE"
      or event=="TRADE_SKILL_DATA_SOURCE_CHANGED" or event=="NEW_RECIPE_LEARNED")
  end
end)
