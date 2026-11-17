-- Stock on your other characters (twinks): bags and bank per character in an account-wide store.
-- Only counts are kept. Stock on same-realm, same-faction characters can be mailed and is planned
-- with by default; everything else is shown for information only.
local _,CP=...
local L=CP.L

local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c,d,e,f,g,h,i,j=pcall(fn,...)
  if ok then return a,b,c,d,e,f,g,h,i,j end
end

local function now() return type(time)=="function" and time() or 0 end

function CP:CharacterKey()
  local name=safe(UnitName,"player")
  local realm=safe(GetRealmName)
  if type(name)~="string" or name=="" then return nil end
  return name.."-"..(type(realm)=="string" and realm or "?"),name,realm
end

function CP:InitializeAlts()
  if type(CraftPilotAccountDB)~="table" then CraftPilotAccountDB={} end
  local account=CraftPilotAccountDB
  if type(account.characters)~="table" then account.characters={} end
  self.account=account
  local key,name,realm=self:CharacterKey()
  self.characterKey=key
  if not key then return end
  local entry=account.characters[key] or {}
  entry.name,entry.realm=name,realm
  entry.faction=safe(UnitFactionGroup,"player") or entry.faction
  local _,class=safe(UnitClass,"player")
  entry.class=class or entry.class
  entry.level=safe(UnitLevel,"player") or entry.level
  entry.bags=type(entry.bags)=="table" and entry.bags or {}
  entry.bank=type(entry.bank)=="table" and entry.bank or {}
  account.characters[key]=entry
  self.altIndex=nil
  if self.db and type(self.db.ui.includeAlts)~="boolean" then self.db.ui.includeAlts=true end
end

function CP:CurrentCharacter()
  return self.account and self.characterKey and self.account.characters[self.characterKey]
end

-- Count every item in the given containers. Works with C_Container and the older global API.
function CP:ScanContainers(bags)
  local counts={}
  local api=_G.C_Container
  for _,bag in ipairs(bags) do
    local slots=api and safe(api.GetContainerNumSlots,bag) or safe(_G.GetContainerNumSlots,bag) or 0
    for slot=1,(type(slots)=="number" and slots or 0) do
      local id,count
      if api and type(api.GetContainerItemInfo)=="function" then
        local info=safe(api.GetContainerItemInfo,bag,slot)
        if type(info)=="table" then id,count=info.itemID,info.stackCount end
      elseif type(_G.GetContainerItemInfo)=="function" then
        local _,n,_,_,_,_,_,_,_,itemID=safe(_G.GetContainerItemInfo,bag,slot)
        id,count=itemID,n
      end
      if type(id)=="number" and type(count)=="number" and count>0 then counts[id]=(counts[id] or 0)+count end
    end
  end
  return counts
end

local function bagList()
  local list={0}
  for bag=1,(tonumber(_G.NUM_BAG_SLOTS) or 4) do list[#list+1]=bag end
  if type(_G.REAGENTBAG_CONTAINER)=="number" then list[#list+1]=_G.REAGENTBAG_CONTAINER end
  return list
end

local function bankList()
  local list={type(_G.BANK_CONTAINER)=="number" and _G.BANK_CONTAINER or -1}
  local first=(tonumber(_G.NUM_BAG_SLOTS) or 4)+1
  for bag=first,first+(tonumber(_G.NUM_BANKBAGSLOTS) or 6)-1 do list[#list+1]=bag end
  return list
end

function CP:SnapshotCharacterBags()
  local entry=self:CurrentCharacter();if not entry then return end
  entry.bags=self:ScanContainers(bagList())
  entry.updated=now()
  entry.level=safe(UnitLevel,"player") or entry.level
  local profs={}
  entry.learned=type(entry.learned)=="table" and entry.learned or {}
  for key in pairs(self.Data.professions) do
    local p=self.db and self.db.professions[key]
    if p and self:OwnsProfession(key) then
      profs[key]={skill=p.skill,cap=p.cap}
      -- Learned recipe IDs, so other characters know what this one can make for them.
      local learned={}
      for id,r in pairs(self.db.recipes[key] or {}) do if r.learned then learned[id]=true end end
      if next(learned) then entry.learned[key]=learned end
    end
  end
  entry.professions=profs
end

function CP:SnapshotCharacterBank()
  if not self.bankIsOpen then return end
  local entry=self:CurrentCharacter();if not entry then return end
  entry.bank=self:ScanContainers(bankList())
  entry.bankScanned=now()
end

-- Other characters holding an item: {name, realm, faction, bags, bank, count, reachable}.
function CP:AltStock(itemID)
  local out={}
  local me=self:CurrentCharacter()
  for key,c in pairs(self.account and self.account.characters or {}) do
    if key~=self.characterKey then
      local bags=(c.bags or {})[itemID] or 0
      local bank=(c.bank or {})[itemID] or 0
      local mail=(c.mail or {})[itemID] or 0
      if bags+bank+mail>0 then
        out[#out+1]={name=c.name or key,realm=c.realm,faction=c.faction,bags=bags,bank=bank,mail=mail,count=bags+bank+mail,
          reachable=me~=nil and c.realm==me.realm and c.faction==me.faction}
      end
    end
  end
  table.sort(out,function(a,b)
    if a.reachable~=b.reachable then return a.reachable end
    if a.count~=b.count then return a.count>b.count end
    return a.name<b.name
  end)
  return out
end

-- Stock on twinks that can be mailed to this character; 0 when planning with twinks is off.
-- Planning asks this very often, so the per-item totals are indexed once per data change.
function CP:AltReachable(itemID)
  if not self.db or self.db.ui.includeAlts==false or not self.account then return 0 end
  if not self.altIndex then
    local index={}
    local me=self:CurrentCharacter()
    for key,c in pairs(self.account.characters) do
      if key~=self.characterKey and me and c.realm==me.realm and c.faction==me.faction then
        for _,store in ipairs({c.bags or {},c.bank or {},c.mail or {}}) do
          for id,n in pairs(store) do index[id]=(index[id] or 0)+n end
        end
      end
    end
    self.altIndex=index
  end
  return self.altIndex[itemID] or 0
end

-- "3 Jade (Name)" for the part of a need that comes from twinks, largest holders first.
function CP:AltPickupText(itemID,needed)
  local parts,left={},needed
  for _,alt in ipairs(self:AltStock(itemID)) do
    if left<=0 then break end
    if alt.reachable then
      local take=math.min(left,alt.count)
      parts[#parts+1]=take.." "..self:ItemName(itemID).." ("..alt.name..")"
      left=left-take
    end
  end
  return table.concat(parts,", ")
end

-- Who on the account can craft for this profession (for later use in the UI and tooltips).
function CP:AltProfessions(key)
  local out={}
  for charKey,c in pairs(self.account and self.account.characters or {}) do
    local p=c.professions and c.professions[key]
    if charKey~=self.characterKey and p then out[#out+1]={name=c.name or charKey,skill=p.skill,cap=p.cap,realm=c.realm,faction=c.faction} end
  end
  table.sort(out,function(a,b) return (a.skill or 0)>(b.skill or 0) end)
  return out
end

function CP:AltStatus()
  local n=0
  for key in pairs(self.account and self.account.characters or {}) do if key~=self.characterKey then n=n+1 end end
  if n==0 then return L("Noch keine Twinks erfasst · einmal mit jedem Twink einloggen und die Bank öffnen.") end
  return string.format(L("%d Twinks erfasst · Bestände vom letzten Login bzw. Bankbesuch."),n)
end

local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","BAG_UPDATE_DELAYED","BANKFRAME_OPENED","PLAYERBANKSLOTS_CHANGED","PLAYER_LOGOUT"}) do
  pcall(frame.RegisterEvent,frame,event)
end
local pending=false
frame:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then
    CP:InitializeAlts()
    CP:SnapshotCharacterBags()
  elseif not CP.account then
    return
  elseif event=="BAG_UPDATE_DELAYED" then
    if pending then return end
    pending=true
    local function run() pending=false;CP:SnapshotCharacterBags() end
    if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(2,run) else run() end
  elseif event=="PLAYER_LOGOUT" then
    CP:SnapshotCharacterBags()
  else
    -- Bank events arrive before or after Core sets bankIsOpen; scan on the next frame.
    if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(0,function() CP:SnapshotCharacterBank() end)
    else CP:SnapshotCharacterBank() end
  end
end)
