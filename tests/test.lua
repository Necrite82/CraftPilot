-- Pure Lua smoke tests for CraftPilot (no WoW client required).
local methods = {}
methods.__index = function(self,key)
  if key=="CreateFontString" then return function() return setmetatable({},methods) end end
  if key=="CreateTexture" then return function() return setmetatable({},methods) end end

  if key=="SetSize" then return function(t,w,h) t.width=w;t.height=h end end
  if key=="SetWidth" then return function(t,w) t.width=w end end
  if key=="GetWidth" then return function(t) return rawget(t,"width") end end
  if key=="GetHeight" then return function(t) return rawget(t,"height") end end
  if key=="SetShown" then return function(t,shown) t.visible=shown end end
  if key=="SetPoint" then return function(t,...) t.point={...} end end
  if key=="GetPoint" then return function(t)
    local point=rawget(t,"point");if point then return table.unpack(point) end
  end end
  if key=="ClearAllPoints" then return function(t) t.point=nil end end
  if key=="SetScript" then return function(t,event,fn)
    local scripts=rawget(t,"scripts") or {};t.scripts=scripts;scripts[event]=fn
  end end
  if key=="GetScript" then return function(t,event) local scripts=rawget(t,"scripts");return scripts and scripts[event] end end
  if key=="SetText" then return function(t,v) t.displayText=v end end
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
  GetPlayerMapPosition=function(map)
    if map==1453 then return {GetXY=function() return .50,.75 end} end
  end,
  SetUserWaypoint=function(p) waypoints[#waypoints+1]=p end,
}
UiMapPoint={CreateFromCoordinates=function(map,x,y)
  return {map=map,x=x,y=y}
end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function() end}
local owned={ [2589]=2, [2840]=1 }
local bankOwned={ [2589]=5, [2840]=0 }
function time() return 1794140000 end
local registeredSkinName
C_Item={
  GetItemCount=function(id,withBank)
    return (owned[id] or 0)+(withBank and (bankOwned[id] or 0) or 0)
  end,
  GetItemNameByID=function(id) return "Item "..id end,
}
local prices={ [2589]=20, [2840]=50 }
Auctionator={API={v1={GetAuctionPriceByItemID=function(_,id) return prices[id] end}}}
EllesmereUI={
  RegisterSkin=function(name,fn)
    registeredSkinName=name
    local api={}
    for _,key in ipairs({"Shell","Panel","CloseButton","Button","Tab","ScrollBar",
      "ApplyBarFill","SquareIcon","SetTabSelection"}) do
      api[key]=function() end
    end
    fn(api)
  end
}
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
assert(registeredSkinName=="CraftPilot" and CP.ellesmereSkin)
assert(CP.db.includeBank==true)
assert(CP.db.ui.recipeSort=="cost")
for _,key in ipairs(CP.Data.order) do
  assert(CP.Data.professions[key],"Missing profession "..key)
  local stages=CP.Data.stages[key]
  assert(stages[1][1]==1 and stages[#stages][2]==300,
    "Incomplete milestone coverage: "..key)
  for i=2,#stages do
    assert(stages[i][1]==stages[i-1][2],"Gap in "..key)
  end
  for _,segment in ipairs(stages) do
    assert(segment[2]-segment[1]<=50,"Stage over 50 points: "..key)
  end
end
assert(#CP.Data.order==8)
assert(CP:CaptureProfession())
assert(CP.db.professions.tailoring.skill==110)
local options=CP:Options("tailoring")
assert(#options==1 and options[1].id==2964)
assert(options[1].missing==1 and options[1].unknown==false)
assert(options[1].cost==20)
assert(CP:BankStatus():find("unbekannt"))
CP.bankIsOpen=true
CP:SnapshotBankMaterials()
assert(CP.db.bank.items[2589]==5)
assert(CP:BankStatus()=="Bank LIVE")
assert(CP:ItemCount(2589)==7)
CP.bankIsOpen=false
bankOwned[2589]=0 -- The saved bank snapshot must not silently change.
assert(CP:ItemCount(2589)==7)
assert(CP:BankStatus():find("zuletzt erfasst"))
assert(CP:Options("tailoring")[1].cost==0)
CP.db.includeBank=false
assert(CP:ItemCount(2589)==2)
assert(CP:Options("tailoring")[1].cost==20)
CP.db.includeBank=true
CP.db.mode="value"
options=CP:Options("tailoring")
assert(options[1].cost==110)
CP.db.ui.selectedRecipes.tailoring=2964
assert(CP:SelectedOption("tailoring").id==2964)
CP.db.ui.recipeSort="name"
assert(CP:SortedOptions("tailoring")[1].name=="Mock recipe 2964")
CP.db.ui.recipeSort="cost"
CP.db.mode="cash"
CP.db.view="tailoring"
local npc,rank=CP:FindTrainer("tailoring")
assert(rank.cap==225 and npc.name=="Georgio Bolero")
local trainerList,nextRank,recommended,nearest=CP:TrainerChoices("tailoring")
assert(#trainerList>=4 and nextRank.cap==225)
assert(recommended.name=="Georgio Bolero")
assert(nearest.name=="Lawrence Schneider")
assert(trainerList[1].canTeach and trainerList[1].inZone)
assert(type(trainerList[1].distance)=="number")
CP:TrainerWaypoint()
assert(#waypoints==1 and waypoints[1].map==1453)
CP:TrainerWaypoint("nearest")
assert(#waypoints==2 and waypoints[2].map==1453)
CP:OpenTab("help")
assert(CP.db.ui.tab=="help" and CP.frame.visible==true)
CP:OpenTab("trainers")
assert(CP.db.ui.tab=="trainers")
CP.frame:SetPoint("CENTER",UIParent,"CENTER",112,-42)
CP:SaveWindowPosition()
assert(CP.db.ui.position.x==112 and CP.db.ui.position.y==-42)
CP:ResetWindowPosition()
assert(CP.db.ui.position==nil and CP.frame.point[4]==0)
CP.db.ui.skin="classic"
CP:ApplyTheme()
CP.db.ui.skin="dark"
CP:ApplyTheme()
CP.db.ui.skin="auto"
CP:ApplyTheme()
CP.frame:SetSize(945,780)
CP:SaveWindowPosition()
assert(CP.db.ui.width==945 and CP.db.ui.height==780)
local oldPos=CP.db.ui.position
CP:ResetWindowPosition()
assert(CP.db.ui.position==nil)

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

-- Skill-level fallback works for professions without a recipe window.
function GetProfessions() return 2,3 end
function GetProfessionInfo(index)
  if index==2 then return "Herbalism",0,208,225,1,0,182,0 end
  if index==3 then return "Alchemy",0,130,150,1,0,171,0 end
end
CP:RefreshProfessionSkills()
assert(CP.db.professions.herbalism.skill==208 and CP.db.professions.herbalism.cap==225)
assert(CP.db.professions.alchemy.skill==130 and CP.db.professions.alchemy.cap==150)
assert(CP:RankCharacterLevel("herbalism",CP.Data.ranks[4])==0)
assert(CP:RankCharacterLevel("alchemy",CP.Data.ranks[4])==35)
CP.db.view="herbalism"
local herbTrainer,herbRank=CP:FindTrainer("herbalism")
assert(herbRank.cap==300 and herbTrainer.name=="Tannysa")
CP:TrainerWaypoint()
assert(waypoints[#waypoints].map==1453)
CP.db.view="alchemy"
local alchemyTrainer,alchemyRank=CP:FindTrainer("alchemy")
assert(alchemyRank.cap==225 and alchemyTrainer.name=="Ainethil")
observedID=171
observedSkill=130
C_TradeSkillUI.GetRecipeSchematic=function()
  return {reagentSlotSchematics={{
    quantityRequired=2,reagentType=1,reagents={{itemID=2589}}
  }}}
end
assert(CP:CaptureProfession())
assert(CP.db.professions.alchemy.skill==130)
assert(#CP:Options("alchemy")==1 and #CP:Options("herbalism")==0)
CP:ChangeView("herbalism")
CP:Render()
-- Horde trainer routing must not choose an Alliance-only NPC.
UnitFactionGroup=function() return "Horde" end
C_Map.GetBestMapForUnit=function() return 1454 end
CP.db.professions.herbalism={skill=202,cap=225,name="Herbalism"}
CP.db.professions.alchemy={skill=210,cap=225,name="Alchemy"}
assert(CP:FindTrainer("herbalism").name=="Jandi")
assert(CP:FindTrainer("alchemy").name=="Rogvar")

-- Hardware-event-bound opening: learned primary professions only.
local opened={}
C_TradeSkillUI.OpenTradeSkill=function(id)
  opened[#opened+1]=id
  return true
end
assert(CP:OwnsProfession("alchemy")==true)
assert(CP:OwnsProfession("tailoring")==false)
CP.db.ui.autoOpen=true
CP:ChangeView("alchemy",true)
assert(opened[#opened]==171)
local openings=#opened
CP:ChangeView("tailoring",true)
assert(#opened==openings)
CP.db.ui.autoOpen=false
CP:ChangeView("alchemy",true)
assert(#opened==openings)
CP.db.ui.autoOpen=true

-- Range and explicit multi-craft material aggregation.
assert(CP:SetPlanRange("alchemy",30,100))
local plan=CP:PlanFor("alchemy")
assert(plan.start==30 and plan.target==100)
assert(CP:AddPlanCraft("alchemy",2964,3))
local basket=CP:PlanShopping("alchemy")
assert(basket.first==30 and basket.last==100)
assert(basket.crafts==3 and #basket.steps==1)
assert(#basket.materials==1 and basket.materials[1].required==6)
assert(basket.materials[1].missing==0)
CP.db.includeBank=false
basket=CP:PlanShopping("alchemy")
assert(basket.materials[1].missing==4 and basket.purchaseCopper==80)
CP.db.includeBank=true
CP:PrintPlanShopping("alchemy")
CP:OpenTab("plan")
assert(CP.db.ui.tab=="plan")
CP:OpenTab("stages")
assert(CP.db.ui.tab=="stages")
CP:OpenTab("mats")
assert(CP.db.ui.tab=="mats")
CP:OpenTab("help")
assert(CP.db.ui.tab=="help")
CP:ClearPlanCraft("alchemy",2964)
assert(CP:PlanShopping("alchemy").crafts==0)
assert(not CP:SetPlanRange("alchemy",100,30))
assert(not CP:AddPlanCraft("alchemy",999999,4))

-- A short provisional draft stops at 10 points and cannot promise the full
-- target range when future recipe difficulties are unknown.
observedSkill=130
CP.db.professions.alchemy={skill=130,cap=150,name="Alchemy"}
assert(CP:SetPlanRange("alchemy",130,180))
assert(CP:DraftPlanStep("alchemy")==true)
assert(CP:PlanShopping("alchemy").crafts==10)
assert(CP:PlanShopping("alchemy").first==130)


C_Map.GetBestMapForUnit=function() return 999 end
local trainers,rank3,best3,nearest3=CP:TrainerChoices("alchemy")
assert(#trainers>0 and nearest3==nil)
print("PASS: professions, bank, native profession click, stages/material cards, partial range planner and shopping aggregation")
