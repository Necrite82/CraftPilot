-- Pure Lua smoke tests for CraftPilot (no WoW client required).
function GetLocale() return "deDE" end
local methods = {}
local createdTextures={}
methods.__index = function(self,key)
  if key=="CreateFontString" then return function() return setmetatable({},methods) end end
  if key=="CreateTexture" then return function()
    local t=setmetatable({parent=self,alpha=1},methods)
    createdTextures[#createdTextures+1]=t
    return t
  end end
  if key=="settingSlider" or key=="craftSpec" or key=="craftSync" then return nil end
  if key=="SetTexture" then return function(t,value) t.texture=value end end
  if key=="SetAlpha" then return function(t,value) t.alpha=value end end
  if key=="SetHeight" then return function(t,value) t.height=value end end

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
local createdFrames={}
function CreateFrame(kind,name,parent)
  local f=setmetatable({kind=kind,frameName=name,parent=parent},methods)
  createdFrames[#createdFrames+1]=f
  return f
end
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
Auctionator={API={v1={
  GetAuctionPriceByItemID=function(_,id) return prices[id] end,
  GetAuctionAgeByItemID=function(_,id) return id==2589 and 9 or 0 end
}}}
EllesmereUI={
  RegisterSkin=function(name,fn)
    registeredSkinName=name
    local api={}
    for _,key in ipairs({"Shell","Panel","CloseButton","Button","Tab","ScrollBar",
      "ApplyBarFill","SquareIcon","SetTabSelection"}) do
      api[key]=function(frame)
        if key=="Panel" or key=="Shell" then
          for _,texture in ipairs(createdTextures) do
            if texture.parent==frame then texture:SetAlpha(0) end
          end
        end
      end
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
for _,path in ipairs({
  "Locale.lua","Locales/enUS.lua","Data.lua",
  "ThirdParty/CraftLadder/Camp.lua","ThirdParty/CraftLadder/CampingRecipes.lua",
  "ThirdParty/CraftLadder/Alchemy.lua",
  "ThirdParty/CraftLadder/Blacksmithing.lua",
  "ThirdParty/CraftLadder/Enchanting.lua",
  "ThirdParty/CraftLadder/Engineering.lua",
  "ThirdParty/CraftLadder/Leatherworking.lua",
  "ThirdParty/CraftLadder/Tailoring.lua",
  "ThirdParty/CraftLadder/MiningSmelting.lua",
  "Core.lua","Catalog.lua","PriceHistory.lua","Route.lua","UI.lua","Settings.lua","Camping.lua"}) do
  local chunk=assert(loadfile(path))
  chunk("CraftPilot",CP)
end
CP:Initialize()
assert(registeredSkinName=="CraftPilot" and CP.ellesmereSkin)
assert(CP:CatalogCount("tailoring")>300)
assert(CP:CatalogCount("engineering")>150)
assert(CP:CatalogCount("alchemy")>120)
assert(CP:Catalog("mining").recipes[2657].makes==2840)
assert(CP:Catalog("herbalism")==nil)
local _,price=CP:PriceFreshness(2589)
assert(price.price and price.ageDays==9 and price.freshness=="stale")
assert(CP:PriceDetails(999999).freshness=="missing")
local candidates=CP:CatalogCandidateRecipes("tailoring",1)
assert(#candidates>0)
local provisional=CP:GenerateAutomaticRoute("tailoring",1,4)
assert(provisional and provisional.reached>1 and #provisional.steps>0)
local benchmarkStart=os.clock()
local midRange=CP:GenerateAutomaticRoute("tailoring",30,100)
assert(midRange and midRange.first==30 and midRange.target==100)
assert(midRange.reached>30 and #midRange.steps>0)
print(string.format("Benchmark: tailoring 30–100 reached %d, %.3f seconds, %d steps",
  midRange.reached,os.clock()-benchmarkStart,#midRange.steps))


assert(CP.db.includeBank==true)
assert(CP.db.ui.recipeSort=="cost")
for _,key in ipairs(CP.Data.order) do
  assert(CP.Data.professions[key],"Missing profession "..key)
  local stages=CP.Data.stages[key] or {}
  if #stages>0 then
  assert(stages[1][1]==1 and stages[#stages][2]==300,
    "Incomplete milestone coverage: "..key)
  for i=2,#stages do
    assert(stages[i][1]==stages[i-1][2],"Gap in "..key)
  end
  end
  for _,segment in ipairs(stages) do
    assert(segment[2]-segment[1]<=50,"Stage over 50 points: "..key)
  end
end
assert(#CP.Data.order==12)
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
assert(CP.db.ui.tab=="settings" and CP.frame.visible==true)
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
-- Cross-profession copper smelting only when Mining is actually learned.
local realGetProfessionInfo=GetProfessionInfo
GetProfessionInfo=function(i)
  if i==2 then return "Mining",0,90,150,1,0,186,0 end
  if i==3 then return "Engineering",0,90,150,1,0,202,0 end
end
CP.db.professions.mining={skill=90,cap=150,name="Mining"}
assert(CP:OwnsProfession("mining"))
assert(#CP:RecipesMaking(2840,"engineering",90)>0)
GetProfessionInfo=realGetProfessionInfo

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
assert(CP.db.ui.tab=="settings")
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
print("PASS: GPL catalog, smelting, scan freshness, recursive route, profession UI and shopping plans")

-- Secondary slots must survive nil primary slots.
GetProfessions=function() return nil,3,nil,4,5,6 end
GetProfessionInfo=function(index)
  local rows={
    [3]={"Skinning",0,90,150,1,0,393},
    [4]={"Fishing",0,65,150,1,0,356},
    [5]={"Cooking",0,80,150,1,0,185},
    [6]={"First Aid",0,100,150,1,0,129},
  }
  return table.unpack(rows[index])
end
CP:RefreshProfessionSkills()
for _,key in ipairs({"skinning","fishing","cooking","firstaid"}) do
  assert(CP:OwnsProfession(key),"Profession not detected: "..key)
  assert(CP.db.professions[key].cap==150)
  assert(CP:NextRank(key)==nil,"Do not invent rank requirements")
  observedID=CP.Data.professions[key].id
  assert(CP:CaptureProfession())
  assert(#CP:Options(key)>0,"Native crafting recipes should work: "..key)
  assert(CP:OpenOwnedProfession(key))
  for _,tab in ipairs({"now","stages","mats","plan","trainers","help"}) do
    CP:OpenTab(tab)
    CP:Render()
  end
end
CP.db.view="cooking"
CP.db.ui.showAllProfessions=false
assert(#CP:VisibleProfessions()==4)
CP.db.ui.showAllProfessions=true
local visible=CP:VisibleProfessions()
assert(#visible==12 and visible[1]=="skinning")
assert(CP.Data.professions.jewelcrafting==nil and CP.Data.professions.inscription==nil)
print("PASS: 12 professions, secondary slots, native capture and every new profession tab")

-- Exercise real settings callbacks rather than only invoking implementation helpers.
CP:OpenTab("settings")
local function clickSetting(prefix)
  for _,row in ipairs(CP:SettingsCards()) do
    if row.title:sub(1,#prefix)==prefix then assert(row.action);row.action();return end
  end
  error("Missing setting: "..prefix)
end
local bankBefore=CP.db.includeBank
clickSetting("Bankbestände")
assert(CP.db.includeBank~=bankBefore)
local oldMode=CP.db.mode
clickSetting("Kostenvergleich")
assert(CP.db.mode~=oldMode)
local oldSort=CP.db.ui.recipeSort
clickSetting("Rezeptsortierung")
assert(CP.db.ui.recipeSort~=oldSort)
local recipeTable=CP.db.recipes
local planTable=CP.db.plans
CP.db.ui.position={point="CENTER",relPoint="CENTER",x=50,y=25}
clickSetting("Fenster und Minimap")
assert(CP.db.ui.position.x==50 and CP.pendingSettingsReset)
clickSetting("Zurücksetzen bestätigen")
assert(CP.db.ui.position==nil and CP.db.ui.width==750 and CP.db.ui.height==676)
assert(CP.db.recipes==recipeTable and CP.db.plans==planTable)

-- Known-only policy cannot keep a previously computed catalog proposal.
CP.db.plans.tailoring={autoRoute={steps={}},autoMode=true,start=1,target=10,crafts={}}
CP.db.recipes.tailoring[2963]=nil
assert(CP:CatalogSource("tailoring",2963,1)~=nil)
clickSetting("Auto-Route")
assert(CP.db.ui.knownRecipesOnly and CP:CatalogSource("tailoring",2963,1)==nil)
assert(CP.db.plans.tailoring.autoRoute==nil and not CP.db.plans.tailoring.autoMode)
CP.db.recipes.tailoring[2963]={learned=true,disabled=false}
assert(CP:CatalogSource("tailoring",2963,1)=="known")
clickSetting("Auto-Route")

-- Independent settings access remains available with the minimap hidden.
Minimap={GetWidth=function() return 140 end,GetHeight=function() return 140 end,
  GetCenter=function() return 400,300 end,GetEffectiveScale=function() return 2 end}
CP:UpdateMinimapButton()
local mini=CP.minimapButton
assert(mini and mini:IsShown())
mini:GetScript("OnClick")(mini,"RightButton")
assert(CP.db.ui.tab=="settings" and CP.frame:IsShown())
mini:GetScript("OnClick")(mini,"LeftButton")
assert(not CP.frame:IsShown())
mini:GetScript("OnClick")(mini,"LeftButton")
assert(CP.frame:IsShown())
local timer
local oldAfter=C_Timer.After
C_Timer.After=function(_,fn) timer=fn end
GetCursorPosition=function() return 900,600 end
mini:GetScript("OnDragStart")(mini)
mini:GetScript("OnUpdate")(mini)
assert(math.abs(CP.db.ui.minimapAngle)<.001 and math.abs(mini.point[4]-78)<.001)
mini:GetScript("OnDragStop")(mini)
assert(mini:GetScript("OnUpdate")==nil)
mini:GetScript("OnClick")(mini,"LeftButton")
assert(CP.frame:IsShown(),"Dragging must not toggle the main window")
timer();C_Timer.After=oldAfter
CP:OpenTab("settings")
clickSetting("Minimap-Button")
assert(not mini:IsShown() and CP.db.ui.hideMinimap)
local settingsEntry
for _,b in ipairs(createdFrames) do
  if b.displayText=="Einstellungen" and b:GetScript("OnClick") then settingsEntry=b end
end
assert(settingsEntry)
settingsEntry:GetScript("OnClick")(settingsEntry)
assert(CP.db.ui.tab=="settings")
clickSetting("Minimap-Button")
assert(mini:IsShown())
assert(CP:FormatMoney(12345):find("UI%-GoldIcon") and CP:FormatMoney(12345):find("23"))
assert(CP:FormatMoney(0):find("UI%-CopperIcon"))
assert(CP:FormatMoney(nil)=="Preis fehlt")
CP.db.recipes.cooking[123]={icon=456}
assert(CP:RecipeIcon("cooking",123)==456)
CP.db.view="engineering"
CP.db.ui.showAllProfessions=true
clickSetting("Berufsauswahl")
assert(CP:OwnsProfession(CP.db.view),"Switching to own professions should select an owned profession")
-- Refreshing a recipe with ambiguous reagents must clear an older material list.
observedID=185
C_TradeSkillUI.GetRecipeSchematic=function()
  return {reagentSlotSchematics={{quantityRequired=1,reagents={{itemID=1}}}}}
end
CP:CaptureProfession()
assert(CP.db.recipes.cooking[2964].mats)
C_TradeSkillUI.GetRecipeSchematic=function()
  return {reagentSlotSchematics={{quantityRequired=1,reagents={{itemID=1},{itemID=2}}}}}
end
CP:CaptureProfession()
assert(CP.db.recipes.cooking[2964].mats==nil)
print("PASS: settings callbacks, reset confirmation, route policy, money icons and draggable minimap control")

-- The restricted API must be called without a pcall frame, before rendering.
local calls={}
local oldRender=CP.Render
local oldOpen=C_TradeSkillUI.OpenTradeSkill
CP.Render=function() calls[#calls+1]="render" end
C_TradeSkillUI.OpenTradeSkill=function(id)
  for level=2,12 do
    local info=debug.getinfo(level,"n")
    if not info then break end
    assert(info.name~="pcall","Restricted profession API wrapped in pcall")
  end
  calls[#calls+1]="open"
  assert(id==185)
  return true
end
CP.db.ui.autoOpen=true
CP:ChangeView("cooking",true)
assert(calls[1]=="open" and calls[2]=="render")
InCombatLockdown=function() return true end
assert(not CP:OpenOwnedProfession("cooking"))
assert(#calls==2,"No protected open in combat")
InCombatLockdown=nil
CP.Render=oldRender
C_TradeSkillUI.OpenTradeSkill=oldOpen

-- EUI's region fading must leave the logo on its child frame visible.
local logo
for _,texture in ipairs(createdTextures) do
  if texture.parent.frameName=="CraftPilotBrandFrame" then logo=texture end
end
assert(logo and logo.alpha==1 and logo.texture:find("Media"))
CP:OpenTab("settings")
local sliders={}
for _,control in ipairs(createdFrames) do
  local spec=rawget(control,"craftSpec")
  if spec and spec.label then sliders[spec.label]=control end
end
for label,value in pairs({["Fensterbreite: "]=1060,["Fensterhöhe: "]=800,["Minimap-Position: "]=270}) do
  local control=assert(sliders[label],"Missing slider: "..label)
  control:GetScript("OnValueChanged")(control,value)
end
assert(CP.db.ui.width==1060 and CP.db.ui.height==800 and CP.db.ui.minimapAngle==270)
assert(CP.frame.width==1060 and CP.frame.height==800)
CP:Render()
for _,control in ipairs(createdFrames) do
  local label=rawget(control,"displayText")
  if type(label)=="string" then
    assert(not label:find("●",1,true) and not label:find("✓",1,true),"Unsupported indicator glyph")
  end
end
print("PASS: direct click-only profession open, skin-safe branding, graphic indicators and settings sliders")

-- Every supported profession has camping objects; faction variants are deduplicated.
local campProf,items={},{}
local campRows=CP:CampingRecipes()
for _,row in ipairs(campRows) do
  assert(not items[row.object.item],"Duplicate camping object")
  items[row.object.item]=true;campProf[row.prof]=true
  for _,n in pairs(row.mats or {}) do assert(n>0 and n%1==0) end
end
for _,key in ipairs(CP.Data.order) do assert(campProf[key],"Missing camping profession: "..key) end
assert(#campRows==37,"Unexpected faction-filtered camping count")
assert(#CP.CAMP.fires==3 and CP.CAMP.fires[1].slots==3 and CP.CAMP.fires[2].slots==5 and CP.CAMP.fires[3].slots==10)
for _,page in ipairs({"fires","objects","buffs"}) do
  CP.db.ui.campingPage=page
  CP.db.ui.campingAll=true
  CP:OpenTab("camping")
  local cards=CP:CampingCards("cooking")
  assert(#cards>3)
  for _,card in ipairs(cards) do if card.action then card.action() end end
  CP:Render()
end
CP.db.ui.campingPage="buffs"
CP.db.ui.campingAll=false
CP.db.ui.campingBuff=CP.CAMP.features[1].item
local buffCards=CP:CampingCards(CP.CAMP.features[1].prof)
local levels=0
for _,card in ipairs(buffCards) do if (card.title or ""):find("Bis Charakterstufe",1,true) then levels=levels+1 end end
assert(levels==#CP.CAMP.features[1].gives,"Expanded buff levels missing")
local originalSpell=C_Spell
C_Spell={GetSpellDescription=function() return "Current native description" end,GetSpellName=function() return "Current native name" end}
buffCards=CP:CampingCards(CP.CAMP.features[1].prof)
assert(buffCards[2].detail=="Current native description" and buffCards[2].title:find("Current native name",1,true))
C_Spell=originalSpell
CP.db.ui.campingAll=false
for _,row in ipairs(CP:CampingRecipes("skinning")) do assert(row.prof=="skinning") end
local sample=CP.CAMP.fires[1]
local prior=CP.db.recipes.cooking[sample.maker]
CP.db.recipes.cooking[sample.maker]={name="Native camp name",learned=true,mats={{4470,7}}}
local native=CP:CampingRecipes("cooking")[1]
for _,row in ipairs(CP:CampingRecipes("cooking")) do if row.id==sample.maker then native=row end end
assert(native.name=="Native camp name" and native.mats[4470]==7 and native.materialsLive)
CP.db.recipes.cooking[sample.maker].mats=nil
for _,row in ipairs(CP:CampingRecipes("cooking")) do if row.id==sample.maker then assert(row.mats==nil) end end
CP.db.recipes.cooking[sample.maker]=prior

-- Real slider callbacks exercise both directions, including inverted minimap visibility.
CP:OpenTab("settings")
for _,key in ipairs({"hideMinimap","autoOpen","showAllProfessions","bank","knownRecipesOnly","showSourceDetails"}) do
  local control
  for _,candidate in ipairs(createdFrames) do
    local spec=rawget(candidate,"craftSpec")
    if spec and spec.key==key then control=candidate end
  end
  assert(control,"Missing on/off slider: "..key)
  local before=control.craftSpec.value
  control:GetScript("OnValueChanged")(control,1-before)
  assert(control.craftSpec.value==1-before,"Switch did not update")
  control:GetScript("OnValueChanged")(control,before)
  assert(control.craftSpec.value==before,"Switch did not restore")
end

-- Load the actual TOC into fresh addon tables to test language at construction time.
for _,locale in ipairs({"enUS","enGB","frFR"}) do
  GetLocale=function() return locale end
  CraftPilotDB={}
  local translated={}
  for line in io.lines("CraftPilot.toc") do
    if line:match("%.lua$") then assert(loadfile((line:gsub("\\","/"))))("CraftPilot",translated) end
  end
  translated:Initialize()
  assert(translated.locale=="enUS" and translated.L("Einstellungen")=="Settings")
  assert(translated.Data.professions.cooking.name=="Cooking")
  for _,key in ipairs(translated.Data.order) do
    translated.db.view=key
    for _,tab in ipairs({"now","stages","mats","plan","trainers","camping","settings"}) do translated:OpenTab(tab) end
  end
  for _,page in ipairs({"fires","objects","buffs"}) do
    translated.db.ui.campingPage=page
    for _,card in ipairs(translated:CampingCards("cooking")) do
      assert(not (card.title or ""):find("Nicht als erlernt",1,true))
    end
  end
  for german,english in pairs(translated.English) do
    local function placeholders(s)
      local values={};for value in s:gmatch("%%[sdif]") do values[#values+1]=value end
      return table.concat(values,",")
    end
    assert(placeholders(german)==placeholders(english),"Translation format mismatch: "..german)
  end
end
print("PASS: camping coverage, native-data precedence, all toggle sliders and English/fallback UI rendering")
