-- Pure Lua smoke tests for CraftPilot (no WoW client required).
local methods = {}
methods.__index = function(self,key)
  if key=="CreateFontString" then return function() return setmetatable({},methods) end end
  if key=="IsShown" then return function(t) return t.visible or false end end
  if key=="Show" then return function(t) t.visible=true end end
  if key=="Hide" then return function(t) t.visible=false end end
  return function() end
end
local waypoints={}
UIParent={}
UISpecialFrames={}
SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function CreateFrame() return setmetatable({},methods) end
function UnitLevel() return 40 end
function UnitFactionGroup() return "Alliance" end
C_Timer={After=function(_,f) f() end}
C_Map={
  GetBestMapForUnit=function() return 1453 end,
  SetUserWaypoint=function(p) waypoints[#waypoints+1]=p end,
}
UiMapPoint={CreateFromCoordinates=function(map,x,y)
  return {map=map,x=x,y=y}
end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function() end}
local owned={ [2589]=2, [2840]=1 }
C_Item={
  GetItemCount=function(id) return owned[id] or 0 end,
  GetItemNameByID=function(id) return "Item "..id end,
}
local prices={ [2589]=20, [2840]=50 }
Auctionator={API={v1={GetAuctionPriceByItemID=function(_,id) return prices[id] end}}}
local observedSkill=110
local observedID=197
C_TradeSkillUI={
  GetBaseProfessionInfo=function()
    return {professionID=observedID,professionName="Tailoring",
      skillLevel=observedSkill,maxSkillLevel=150}
  end,
  GetAllRecipeIDs=function() return {2963,2964} end,
  GetRecipeInfo=function(id)
    return {name="Mock recipe "..id, learned=id==2964,
      relativeDifficulty=0,canSkillUp=true}
  end,
  GetRecipeSchematic=function(id)
    return {reagentSlotSchematics={
      {quantityRequired=3,reagentType=1,reagents={{itemID=2589}}},
      {quantityRequired=1,reagentType=1,reagents={{itemID=2840}}},
    }}
  end,
}
local CP={}
for _,path in ipairs({"Data.lua","Core.lua","UI.lua"}) do
  local chunk=assert(loadfile(path))
  chunk("CraftPilot",CP)
end
CP:Initialize()
for _,key in ipairs(CP.Data.order) do
  assert(CP.Data.professions[key],"Missing profession "..key)
  local stages=CP.Data.stages[key]
  assert(stages[1][1]==1 and stages[#stages][2]==300,
    "Incomplete milestone coverage: "..key)
  for i=2,#stages do
    assert(stages[i][1]==stages[i-1][2],"Gap in "..key)
  end
end
assert(#CP.Data.order==6)
assert(CP:CaptureProfession())
assert(CP.db.professions.tailoring.skill==110)
local options=CP:Options("tailoring")
assert(#options==1 and options[1].id==2964)
assert(options[1].missing==1 and options[1].unknown==false)
assert(options[1].cost==20)
CP.db.mode="value"
options=CP:Options("tailoring")
assert(options[1].cost==110)
CP.db.mode="cash"
CP.db.view="tailoring"
local npc,rank=CP:FindTrainer("tailoring")
assert(rank.cap==225 and npc.name=="Georgio Bolero")
CP:TrainerWaypoint()
assert(#waypoints==1 and waypoints[1].map==1453)
CP.db.professions.enchanting={skill=205,cap=225,name="Enchanting"}
local target=CP:FindTrainer("enchanting")
assert(target.name:find("Annora") and target.indoor)
CP.db.professions.leatherworking={skill=210,cap=225,name="Leatherworking"}
assert(CP:FindTrainer("leatherworking").name=="Drakk Stonehand")
CP.db.professions.blacksmithing={skill=215,cap=225,name="Blacksmithing"}
assert(CP:FindTrainer("blacksmithing").name=="Brikk Keencraft")
CP:ChangeView("leatherworking")
CP:Render()
-- Never score ambiguous optional/multi-choice reagents.
C_TradeSkillUI.GetRecipeSchematic=function()
  return {reagentSlotSchematics={{
    quantityRequired=2,reagentType=1,
    reagents={{itemID=2589},{itemID=2840}}
  }}}
end
observedID=165
observedSkill=150
CP:CaptureProfession()
assert(CP.db.recipes.leatherworking[2964].mats==nil)
print("PASS: 6 professions, 1-300 stages, recipe capture, scoring, trainer pins")
