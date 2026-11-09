-- Pure Lua smoke tests for CraftPilot (no WoW client required).
local unpackValues=unpack or table.unpack
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
    local point=rawget(t,"point");if point then return unpackValues(point) end
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
-- Load the same file order as the game client, including the full UI module.
for line in io.lines("CraftPilot.toc") do
  if line:match("%.lua$") then assert(loadfile((line:gsub("\\","/"))))("CraftPilot",CP) end
end
assert(type(CP.Render)=="function" and type(CP.OpenTab)=="function" and type(CP.ToggleWindow)=="function","TOC must load every window entry point before initialization")
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
  return unpackValues(rows[index])
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

-- Price status must follow the relevant material ages, not a fixed warning.
local savedRecipes=CP.db.recipes.statusTest
CP.db.recipes.statusTest={[1]={mats={{2589,2},{2840,1}}}}
local savedAge=Auctionator.API.v1.GetAuctionAgeByItemID
Auctionator.API.v1.GetAuctionAgeByItemID=function() return 0 end
local label,state=CP:ProfessionPriceStatus("statusTest")
assert(state=="fresh" and label:find("aktuell",1,true))
Auctionator.API.v1.GetAuctionAgeByItemID=function() return 4 end
label,state=CP:ProfessionPriceStatus("statusTest")
assert(state=="warning" and label:find("3 T.",1,true))
Auctionator.API.v1.GetAuctionAgeByItemID=nil
label,state=CP:ProfessionPriceStatus("statusTest")
assert(state=="warning" and label:find("ohne Datum",1,true))
Auctionator.API.v1.GetAuctionAgeByItemID=savedAge
CP.db.recipes.statusTest={[1]={mats={{999999999,1}}}}
label,state=CP:ProfessionPriceStatus("statusTest")
assert(state=="warning" and label:find("fehlen",1,true))
CP.db.recipes.statusTest={}
label,state=CP:ProfessionPriceStatus("statusTest")
assert(state=="unknown")
CP.db.recipes.statusTest=savedRecipes
local settingsCount=0
for _,control in ipairs(createdFrames) do
  if rawget(control,"displayText")=="Einstellungen" then settingsCount=settingsCount+1 end
end
assert(settingsCount==1,"Duplicate settings navigation")
print("PASS: price freshness states and single settings entry")

-- Every supported profession has camping objects; faction variants are deduplicated.
local campProf,items={},{}
local campRows=CP:CampingRecipes()
for _,row in ipairs(campRows) do
  assert(not items[row.object.item],"Duplicate camping object")
  items[row.object.item]=true;campProf[row.prof]=true
  for _,n in pairs(row.mats or {}) do assert(n>0 and n%1==0) end
end
for _,key in ipairs(CP.Data.order) do assert(campProf[key],"Missing camping profession: "..key) end
assert(#campRows==38,"Unexpected faction-filtered camping count")
local newObjects=0
for _,row in ipairs(campRows) do
  if row.object.item==279938 then
    newObjects=newObjects+1
    assert(row.mats[4470]==2 and row.mats[4234]==4 and row.mats[3575]==1)
    assert(row.object.useSkill==300 and row.recipe.item==273109)
    assert(row.source:find("Beta",1,true))
  end
  if row.id==1283400 then assert(row.source:find("Lord Serpentis",1,true) and row.useSkill==140) end
  if row.id==1263041 then assert(row.source:find("Gilnid",1,true)) end
  if row.id==1263034 then assert(row.source:find("Sneed",1,true)) end
  if row.id==1263031 then assert(row.source:find("Razorclaw",1,true) and row.mats[2321]==3) end
end
assert(newObjects==1)
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

-- Compact checkboxes exercise both directions, including inverted minimap visibility.
CP:OpenTab("settings")
for _,key in ipairs({"hideMinimap","autoOpen","showAllProfessions","bank","knownRecipesOnly","showSourceDetails","preferReliableSkill","showVendorRecipes","useQuestieDB","allowYellow","allowGreen","planAhead"}) do
 local control
 for _,candidate in ipairs(createdFrames) do local spec=rawget(candidate,"craftCheckSpec");if spec and spec.key==key then control=candidate end end
 assert(control,"Missing checkbox: "..key)
 local before=control.craftCheckSpec.checked
 control:GetScript("OnClick")(control);assert(control.craftCheckSpec.checked~=before)
 control:GetScript("OnClick")(control);assert(control.craftCheckSpec.checked==before)
end

-- Economic comparison: valuable owned silver can lose to a cheap purchased substitute.
local savedProf,savedRecs,savedPlan=CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.plans.engineering
CP.db.professions.engineering={skill=10,cap=75}
CP.db.recipes.engineering={
 [900001]={name="Use silver",learned=true,snapshotSkill=10,difficulty=0,mats={{50001,4}}},
 [900002]={name="Buy substitute",learned=true,snapshotSkill=10,difficulty=0,mats={{50002,2},{50002,2}}},
 [900003]={name="Not learned",learned=false,snapshotSkill=10,difficulty=0,mats={{50002,1}}},
 [900004]={name="Gray",learned=true,snapshotSkill=10,difficulty=3,mats={{50002,1}}},
}
owned[50001]=4;prices[50001]=1000;prices[50002]=100
CP.db.ui.economyCut=5
local comparison=CP:EconomyComparison("engineering")
assert(#comparison.rows==2 and comparison.baseline.id==900001)
local alternative=comparison.rows[1]
assert(alternative.id==900002 and alternative.buy==400 and alternative.advantage==3400 and alternative.reliable)
assert(#alternative.materials==1 and alternative.materials[1].missing==4)
assert(alternative.preserve[1].quantity==4 and alternative.preserve[1].net==3800)
local liquid=CP:CostCalculation("economy","engineering",900002,1)
assert(liquid.cash==400 and liquid.sale==3800 and liquid.balance==-3400 and liquid.economic==400)
local marketAge=Auctionator.API.v1.GetAuctionAgeByItemID
Auctionator.API.v1.GetAuctionAgeByItemID=function(_,id) return id==50001 and 10 or 0 end
liquid=CP:CostCalculation("economy","engineering",900002,1)
assert(liquid.cash==400 and liquid.sale==0 and liquid.saleBlocked)
Auctionator.API.v1.GetAuctionAgeByItemID=marketAge

assert(owned[50001]==4,"Comparison changed inventory")
CP.db.plans.engineering={start=10,target=20,crafts={[900001]=2}}
assert(CP:ChooseEconomyRecipe("engineering",900002))
assert(CP.db.ui.selectedRecipes.engineering==900002 and CP.db.plans.engineering.crafts[900001]==2)
assert(not CP:ChooseEconomyRecipe("engineering",900003))
CP.db.view="engineering";CP:OpenTab("economy")
local economyCards=CP:EconomyCards("engineering")
for _,card in ipairs(economyCards) do
 if card.title=="Diese Variante als Einkaufsplan übernehmen" then card.action() end
end
assert(CP.db.plans.engineering.crafts[900002]==1 and CP.db.plans.engineering.crafts[900001]==nil)
assert(CP:UndoEconomyPlan("engineering"))
assert(CP.db.plans.engineering.crafts[900001]==2 and CP.db.plans.engineering.crafts[900002]==nil)
local oldAge=Auctionator.API.v1.GetAuctionAgeByItemID
Auctionator.API.v1.GetAuctionAgeByItemID=function() return 10 end
comparison=CP:EconomyComparison("engineering")
for _,row in ipairs(comparison.rows) do assert(not row.reliable) end
Auctionator.API.v1.GetAuctionAgeByItemID=oldAge
prices[50001]=nil
comparison=CP:EconomyComparison("engineering")
for _,row in ipairs(comparison.rows) do assert(not row.reliable) end
prices[50001]=1000
CP.db.ui.economyCut=30
comparison=CP:EconomyComparison("engineering")
assert(comparison.rows[1].advantage==2400)
CP.db.professions.engineering.cap=10
assert(#CP:EconomyComparison("engineering").rows==0,"No skill-ups at the profession cap")
CP.db.ui.economyCut=5
CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.plans.engineering=savedProf,savedRecs,savedPlan
owned[50001]=nil;prices[50001]=nil;prices[50002]=nil

-- Shared camping plan multiplies quantities and subtracts stock once across professions.
local originalCampPlan=CP.db.campingPlan
CP.db.campingPlan={}
assert(CP:AddCampingCraft(279981,5))
assert(CP:AddCampingCraft(279938,2))
assert(not CP:AddCampingCraft(0,1) and not CP:AddCampingCraft(279981,1.5))
local oldWood=owned[4470]
owned[4470]=3
local shopping=CP:CampingShopping()
local foundWood
for _,mat in ipairs(shopping.materials) do if mat.id==4470 then foundWood=mat end end
assert(#shopping.steps==2 and foundWood.quantity==9 and foundWood.missing==6)
assert(CP:AddCampingCraft(279981,-5))
assert(#CP:CampingShopping().steps==1)
CP.db.ui.campingPage="shopping";CP:OpenTab("camping")
assert(#CP:CampingShoppingCards()>2)
CP.db.campingPlan=originalCampPlan;owned[4470]=oldWood
print("PASS: Clever skillen opportunity costs, sale deductions, stale/missing safeguards and shared camping shopping")

-- Color interval boundaries are inclusive at the beginning and exclusive at the next color.
assert(CP:ValidSkillColors({1,10,20,30}))
for skill,difficulty in pairs({[1]=0,[9]=0,[10]=1,[19]=1,[20]=2,[29]=2,[30]=3}) do
 assert(CP:ReferenceDifficulty({1,10,20,30},skill)==difficulty)
end
assert(not CP:ValidSkillColors({65,50,62,75}))
assert(not CP:ValidSkillColors({1,10,0/0,30}))
assert(CP:CatalogSkillChance({colors={65,50,62,75}},65)==0)
local secondaryCount=0
for _,map in pairs(CP.SecondarySkillRanges) do
 for _,colors in pairs(map) do assert(CP:ValidSkillColors(colors));secondaryCount=secondaryCount+1 end
end
assert(secondaryCount==162)
local oldProf,oldRecipes=CP.db.professions.engineering,CP.db.recipes.engineering
local priorCostMode=CP.db.mode;CP.db.mode="cash"
local oldStock,oldP1,oldP2=owned[50001],prices[50001],prices[50002]
local oldSelected=CP.db.ui.selectedRecipes.engineering
CP.db.professions.engineering={skill=10,cap=75}
CP.db.recipes.engineering={
 [990001]={name="Cheap green",learned=true,snapshotSkill=10,difficulty=2,mats={{50001,1}}},
 [990002]={name="Orange alternative",learned=true,snapshotSkill=10,difficulty=0,mats={{50002,1}}},
}
owned[50001]=1;prices[50001]=100;prices[50002]=100
CP.db.ui.preferReliableSkill=true
assert(CP:Options("engineering")[1].id==990002)
CP.db.ui.preferReliableSkill=false
assert(CP:Options("engineering")[1].id==990001)
CP.db.ui.preferReliableSkill=true
prices[50002]=nil
assert(CP:Options("engineering")[1].id==990001,"Unpriced orange must not win")
prices[50002]=100
CP.db.ui.selectedRecipes.engineering=990001
assert(CP:SelectedOption("engineering").id==990001,"Explicit green selection must remain usable")
local fakeCatalog=CP:Catalog("engineering")
fakeCatalog.recipes[990001]={name="Old recipe",learn=1,colors={1,20,30,40},mats={[50001]=99},get={{kind="trainer"}}}
local _,conflict=CP:RecipeRangeData("engineering",990001)
assert(conflict and CP:RecipeRangeText("engineering",990001):find("abweichend",1,true))
local foundLive,foundFuture
for _,candidate in ipairs(CP:CatalogCandidateRecipes("engineering",10)) do
 if candidate.id==990001 then foundLive=candidate end
end
for _,candidate in ipairs(CP:CatalogCandidateRecipes("engineering",11)) do
 if candidate.id==990001 then foundFuture=candidate end
end
assert(foundLive and foundLive.chance==.35 and foundLive.recipe.mats[50001]==1)
assert(not foundFuture,"A conflicting reference must not extrapolate future colors")
local realCatalogRecipes=fakeCatalog.recipes
fakeCatalog.recipes={
 [990001]={learn=1,colors={1,1,1,40},mats={[50001]=1},get={{kind="trainer"}}},
 [990002]={learn=1,colors={1,40,50,60},mats={[50002]=1},get={{kind="trainer"}}},
}
owned[50001]=3
CP.db.ui.preferReliableSkill=false
assert(CP:GenerateAutomaticRoute("engineering",10,11).steps[1].id==990001)
CP.db.ui.preferReliableSkill=true
assert(CP:GenerateAutomaticRoute("engineering",10,11).steps[1].id==990002)
fakeCatalog.recipes=realCatalogRecipes
owned[50001]=1

CP.db.recipes.engineering[990001].difficulty=0
fakeCatalog.recipes[990001].colors={1,10,20,30}
local ranges=CP:RecipeRangeText("engineering",990001)
assert(ranges:find("1-9",1,true) and ranges:find("10-19",1,true) and ranges:find("20-29",1,true) and ranges:find("ab 30",1,true))
CP.db.recipes.engineering[990001].mats=nil
for _,candidate in ipairs(CP:CatalogCandidateRecipes("engineering",10)) do assert(candidate.id~=990001) end
CP.db.recipes.engineering[990001].mats={{50001,1}}
local priorCapture=CP.db.lastCapture
CP.db.lastCapture={key="engineering",skill=10}
CP.db.view="engineering";CP:OpenTab("now")
local rangeSeen=false
for _,control in ipairs(createdFrames) do
 local recipe=rawget(control,"craftRecipe")
 if recipe and recipe.id==990001 then
  assert(control.rangeLabel.displayText and control.height>=164)
  rangeSeen=true
 end
end
assert(rangeSeen)
CP.db.lastCapture=priorCapture
assert(#CP:ProfessionAuditCards()==13)
CP:OpenTab("audit")
fakeCatalog.recipes[990001]=nil
CP.db.professions.engineering,CP.db.recipes.engineering=oldProf,oldRecipes
CP.db.mode=priorCostMode
CP.db.ui.selectedRecipes.engineering=oldSelected
owned[50001],prices[50001],prices[50002]=oldStock,oldP1,oldP2
print("PASS: all color boundaries, secondary subset, green policy, live conflicts, native materials and audit view")

-- Old saved settings, selected view and reversible plans survive the module rename.
local beforeMigration=CP.db
local backup={crafts={[900001]=3},start=10,target=20}
CP.db={recipes={},professions={engineering={skill=10,cap=75}},ui={godCut=17,godRecipe=900002,tab="god"},plans={engineering={godPrevious=backup,crafts={[900002]=1}}}}
CP:MigrateEconomyState()
assert(CP.db.ui.economyCut==17 and CP.db.ui.economyRecipe==900002 and CP.db.ui.tab=="economy")
assert(CP.db.ui.godCut==nil and CP.db.ui.godRecipe==nil)
assert(CP.db.plans.engineering.economyPrevious==backup and CP.db.plans.engineering.godPrevious==nil)
CP.db.ui.godCut=5;CP.db.ui.godRecipe=1
CP:MigrateEconomyState()
assert(CP.db.ui.economyCut==17 and CP.db.ui.economyRecipe==900002)
assert(CP:UndoEconomyPlan("engineering"))
assert(CP.db.plans.engineering.crafts[900001]==3)
CP.db=beforeMigration
print("PASS: renamed economy module preserves settings, selected view and previous plan")

-- Vendor recipes use existing records, respect faction/restrictions and expose one-click waypoints.
local originalCatalog=CP:Catalog("engineering")
local oldRecipeTable,oldNpcTable=originalCatalog.recipes,originalCatalog.npcs
local oldProfession,oldNative=CP.db.professions.engineering,CP.db.recipes.engineering
local savedFaction,savedProfessions,savedProfessionInfo=UnitFactionGroup,GetProfessions,GetProfessionInfo
local savedLastCapture=CP.db.lastCapture
UnitFactionGroup=function() return "Alliance" end
GetProfessions=function() return 1 end
GetProfessionInfo=function() return "Engineering",0,10,75,1,0,202 end
CP.db.professions.engineering={skill=10,cap=75}
CP.db.recipes.engineering={[99100]={name="Learned",learned=true,snapshotSkill=10,difficulty=0,mats={{2589,1}}}}
originalCatalog.recipes={
 [99101]={name="Vendor recipe",item=999331,learn=10,colors={10,20,30,40},mats={[2589]=1},get={
 {kind="vendor",npc=991,cost=500,faction="A"},{kind="vendor",npc=992,cost=10,faction="H"},{kind="vendor",npc=993,npcName="Unknown place",faction="AH"}}},
 [99102]={name="Reputation",item=999332,learn=1,colors={1,20,30,40},rep={1,4},get={{kind="vendor",npc=991}}},
 [99103]={name="Holiday",item=999333,learn=1,colors={1,20,30,40},get={{kind="vendor",npc=991,event="Holiday"}}},
 [99104]={name="Currency",item=999334,learn=1,colors={1,20,30,40},get={{kind="vendor",npc=991,otherCost={1,2}}}},
 [99105]={name="Gray",item=999335,learn=1,colors={1,1,1,10},get={{kind="vendor",npc=991}}},
}
originalCatalog.npcs={[991]={name="Vendor A",faction="A",map=1453,zone="Stormwind",x=50,y=75},
 [992]={name="Vendor H",faction="H",map=1454,zone="Orgrimmar",x=40,y=60}}
local offers=CP:VendorRecipeOptions("engineering")
assert(#offers==1 and offers[1].id==99101 and #offers[1].vendors==2 and offers[1].recipeCost==500)
local vendorCost=CP:VendorSkillComparison("engineering",offers[1])
assert(vendorCost.cost.fee==500 and vendorCost.crafts==1 and vendorCost.points==1)
assert(not vendorCost.saving or vendorCost.saving<=0,"An extra book fee alone cannot create a saving")
assert(offers[1].vendors[1].location.x==.5 and offers[1].vendors[1].location.y==.75)
CP.db.lastCapture={key="engineering",skill=10};CP.db.view="engineering";CP:OpenTab("now")
local vendorRecipeButton
for _,control in ipairs(createdFrames) do
 local row=rawget(control,"craftRecipe")
 if row and row.id==99101 then vendorRecipeButton=control end
end
assert(vendorRecipeButton)
local filters={}
for _,control in ipairs(createdFrames) do
 local text=rawget(control,"displayText")
 if text=="Sinnvolle Rezepte" or text=="Nicht gelernt" or text=="Alle Rezepte" or text=="Händlerrezepte" then filters[text]=control end
end
filters["Nicht gelernt"]:GetScript("OnClick")();assert(CP.db.ui.vendorOnly)
filters["Alle Rezepte"]:GetScript("OnClick")();assert(not CP.db.ui.vendorOnly and CP.db.ui.allRecipes)
filters["Händlerrezepte"]:GetScript("OnClick")();assert(CP.db.ui.vendorBrowser)
filters["Sinnvolle Rezepte"]:GetScript("OnClick")();assert(not CP.db.ui.allRecipes and not CP.db.ui.vendorBrowser)
vendorRecipeButton:GetScript("OnClick")(vendorRecipeButton)
assert(CP.db.ui.selectedVendorRecipe==99101)
local targetButton
for _,control in ipairs(createdFrames) do if type(rawget(control,"vendorTarget"))=="table" and control.vendorTarget.name=="Vendor A" then targetButton=control end end
assert(targetButton)
local tomTarget,savedTomTom
savedTomTom=TomTom
TomTom={AddWaypoint=function(_,map,x,y) tomTarget={map,x,y};return "uid" end}
targetButton:GetScript("OnClick")(targetButton)
assert(tomTarget[1]==1453 and tomTarget[2]==.5 and tomTarget[3]==.75)
TomTom=savedTomTom
-- Protected recipe opening stays in the direct user-click path.
local originalOpenRecipe=C_TradeSkillUI.OpenRecipe
local opened=0
C_TradeSkillUI.OpenRecipe=function(id)
 for level=2,14 do local info=debug.getinfo(level,"n");if not info then break end;assert(info.name~="pcall") end
 assert(id==99100);opened=opened+1
end
local learnedButton
for _,control in ipairs(createdFrames) do local row=rawget(control,"craftRecipe");if row and row.id==99100 then learnedButton=control end end
assert(learnedButton)
learnedButton:GetScript("OnClick")(learnedButton)
assert(opened==1 and CP.db.ui.selectedVendorRecipe==nil)
assert(not CP:OpenLearnedRecipe("engineering",99101))
InCombatLockdown=function() return true end
assert(not CP:OpenLearnedRecipe("engineering",99100) and opened==1)
InCombatLockdown=nil
local fallbackOpens=0
local savedGeneralOpen=CP.OpenOwnedProfession
C_TradeSkillUI.OpenRecipe=nil
CP.OpenOwnedProfession=function(_,key) assert(key=="engineering");fallbackOpens=fallbackOpens+1;return true end
assert(CP:OpenLearnedRecipe("engineering",99100) and fallbackOpens==1)
CP.OpenOwnedProfession=savedGeneralOpen
CP.db.ui.selectedVendorKey="engineering";CP.db.ui.selectedVendorRecipe=99101;CP.db.ui.vendorOnly=true
local savedBase,savedIDs,savedInfo=C_TradeSkillUI.GetBaseProfessionInfo,C_TradeSkillUI.GetAllRecipeIDs,C_TradeSkillUI.GetRecipeInfo
C_TradeSkillUI.GetBaseProfessionInfo=function() return {professionID=202,professionName="Engineering",skillLevel=10,maxSkillLevel=75} end
C_TradeSkillUI.GetAllRecipeIDs=function() return {99101} end
C_TradeSkillUI.GetRecipeInfo=function() return {name="Now learned",learned=true,relativeDifficulty=0} end
assert(CP:CaptureProfession())
assert(CP.db.ui.selectedVendorRecipe==nil and CP.db.ui.selectedRecipes.engineering==99101 and CP.db.ui.vendorOnly==false)
assert(#CP:VendorRecipeOptions("engineering")==0)
C_TradeSkillUI.GetBaseProfessionInfo,C_TradeSkillUI.GetAllRecipeIDs,C_TradeSkillUI.GetRecipeInfo=savedBase,savedIDs,savedInfo
local secondaryVendors=0
for _,catalog in pairs(CP.VendorRecipeCatalogs) do
 for _,record in pairs(catalog.recipes) do assert(record.item and record.colors and record.mats);secondaryVendors=secondaryVendors+1 end
end
assert(secondaryVendors==71)
C_TradeSkillUI.OpenRecipe=originalOpenRecipe
originalCatalog.recipes,originalCatalog.npcs=oldRecipeTable,oldNpcTable
CP.db.professions.engineering,CP.db.recipes.engineering=oldProfession,oldNative
CP.db.lastCapture=savedLastCapture
UnitFactionGroup,GetProfessions,GetProfessionInfo=savedFaction,savedProfessions,savedProfessionInfo
CP.db.ui.selectedVendorRecipe=nil;CP.db.ui.selectedVendorKey=nil
print("PASS: vendor eligibility, flat row actions, TomTom coordinates and protected direct recipe opening")

-- Optional QuestieDB API is read-only and refuses another flavor or invalid coordinates.
assert(CP:QuestieProvider()==nil)
local providerGets=0
LibQuestieDB={RequireContract=function(version) return version==1 end,
 ModeIndicator={GetStatus=function() return {expansion="Forever",mode="baked"} end},
 Npc={Get=function(id,key)
  providerGets=providerGets+1
  if key=="name" then return "Localized vendor" end
  if key=="spawns" then return {[1519]={{-1,-1},{55,65},{10,20,123}},[999999]={{40,40}}} end
 end},
 Support={Get=function(name) assert(name=="ZoneDB");return {private={areaIdToUiMapId="return {[1519]=1453}"}} end}}
local qLocation,qName=CP:QuestieNpcLocation(991)
assert(qName=="Localized vendor" and qLocation.map==1453 and qLocation.x==.55 and qLocation.y==.65)
LibQuestieDB.Item={Get=function(item,key) assert(key=="vendors");return {994,0} end}
local c=CP:Catalog("engineering")
local priorRecord,priorNPC=c.recipes[99107],c.npcs[994]
local savedSide=UnitFactionGroup
UnitFactionGroup=function() return "Alliance" end
c.recipes[99107]={item=999333,get={}}
c.npcs[994]={name="Known neutral vendor",faction="AH",map=1453,zone="Stormwind",x=50,y=60}
local extraVendors=CP:RecipeVendors("engineering",99107)
assert(#extraVendors==1 and extraVendors[1].id==994 and extraVendors[1].location.x==.55 and extraVendors[1].cost==nil)
c.recipes[99107],c.npcs[994]=priorRecord,priorNPC
UnitFactionGroup=savedSide

assert(CP:QuestieStatus():find("aktiv",1,true))
LibQuestieDB.ModeIndicator.GetStatus=function() return {expansion="Vanilla",mode="baked"} end
assert(CP:QuestieNpcLocation(991)==nil)
LibQuestieDB.ModeIndicator.GetStatus=function() return {expansion="Forever",mode="source"} end
assert(CP:QuestieStatus():find("Entwicklungsmodus",1,true))
CP.db.ui.useQuestieDB=false
local readsBefore=providerGets
assert(CP:QuestieNpcLocation(991)==nil and providerGets==readsBefore)
CP.db.ui.useQuestieDB=true
LibQuestieDB.RequireContract=function() return false end
assert(CP:QuestieNpcLocation(991)==nil)
LibQuestieDB=nil
print("PASS: optional QuestieDB contract/flavor checks, normalized valid points and safe fallback")
assert(loadfile("tests/compatibility.lua"))(CP,createdFrames)

-- Flat cost calculation distinguishes cash, owned value and conditional sale proceeds.
local savedCostMode,savedCut=CP.db.mode,CP.db.ui.economyCut
CP.db.ui.economyCut=5
local savedStock,savedPrice=owned[55001],prices[55001]
owned[55001]=2;prices[55001]=100
local cost=CP:CalculateMaterialCosts({[55001]=5},200,false)
assert(cost.buy==300 and cost.stockValue==190 and cost.cash==500 and cost.economic==690)
assert(cost.cashComplete and cost.economicComplete)
prices[55001]=nil
cost=CP:CalculateMaterialCosts({[55001]=5},200,false)
assert(not cost.cashComplete and not cost.economicComplete and cost.missingBuy==1 and cost.missingStock==1)
prices[55001]=100
local savedCostNative,savedCostProf,savedCostPlan=CP.db.recipes.engineering,CP.db.professions.engineering,CP.db.plans.engineering
local costCatalog=CP:Catalog("engineering")
local oldCostRecipe=costCatalog.recipes[99201]
costCatalog.recipes[99201]={name="Cost recipe",item=55002,colors={1,20,30,40},mats={[55001]=1},get={}}
local savedBookPrice=prices[55002];prices[55002]=200
CP.db.recipes.engineering={}
CP.db.professions.engineering={skill=10,cap=75}
cost=CP:CostCalculation("recipe","engineering",99201,5)
assert(cost.cash==500 and cost.fee==200,"Book fee must be charged once per recipe, not per craft")
local priorBookStock=owned[55002]
owned[55002]=1
cost=CP:CostCalculation("recipe","engineering",99201,5)
assert(cost.fee==0 and cost.cash==300 and cost.stockValue==380)
owned[55002]=priorBookStock

CP.db.recipes.engineering[99201]={name="Learned",learned=true,mats={{55001,1}},snapshotSkill=10,difficulty=0}
cost=CP:CostCalculation("recipe","engineering",99201,5)
assert(cost.fee==0 and cost.cash==300)
CP.db.plans.engineering={start=10,target=20,crafts={[99201]=5}}
cost=CP:CostCalculation("plan","engineering")
assert(cost.cash==300 and cost.stockValue==190)
CP.db.recipes.engineering[99202]={learned=true,mats={{55001,2}}}
CP.db.plans.engineering.crafts={[99201]=2,[99202]=2}
cost=CP:CostCalculation("plan","engineering")
assert(cost.buy==400 and cost.materials[1].quantity==6,"Shared stock must be consumed once across plan steps")
CP.db.plans.engineering.crafts={[99201]=5}

CP.db.plans.engineering.autoMode=true
CP.db.plans.engineering.autoRoute={steps={{id=99201}},materials={{id=55001,missing=3}},ownedMaterials={[55001]=2}}
cost=CP:CostCalculation("plan","engineering")
assert(cost.cash==300,"Auto-route stock must not be subtracted twice")
CP.db.plans.engineering.autoRoute.ownedMaterials=nil
cost=CP:CostCalculation("plan","engineering")
assert(not cost.cashComplete and cost.unknownRecipes>0)
CP:InitializeCostingState()
assert(CP.db.plans.engineering.autoRoute==nil and CP.db.plans.engineering.crafts[99201]==5)
CP:OpenCostCalculation("recipe","engineering",99201,5)
assert(CP.costWindow:IsShown() and CP.costSnapshot.cash==300)
prices[55001]=150;CP:RefreshCostWindow()
assert(CP.costSnapshot.cash==450)
CP.costWindow:Hide()
CP.db.recipes.engineering[99201].mats=nil
cost=CP:CostCalculation("recipe","engineering",99201,5)
assert(not cost.cashComplete,"Missing current materials must not fall back to old quantities")
costCatalog.recipes[99201]=oldCostRecipe
CP.db.recipes.engineering,CP.db.professions.engineering,CP.db.plans.engineering=savedCostNative,savedCostProf,savedCostPlan
owned[55001],prices[55001],prices[55002]=savedStock,savedPrice,savedBookPrice
CP.db.mode=savedCostMode;CP.db.ui.economyCut=savedCut
assert(type(midRange.ownedMaterials)=="table")
local previousTab,previousPage,previousCamp=CP.db.ui.tab,CP.db.ui.campingPage,CP.db.ui.campingRecipe
CP.db.ui.tab="camping";CP.db.ui.campingPage="fires";CP.db.ui.campingRecipe=CP.CAMP.fires[1].item
CP:OpenCurrentCostCalculation()
assert(CP.costContext.key=="cooking" and CP.costContext.id==CP.CAMP.fires[1].maker)
CP.costWindow:Hide()
CP.db.ui.tab,CP.db.ui.campingPage,CP.db.ui.campingRecipe=previousTab,previousPage,previousCamp

print("PASS: cash versus economic costs, one-time book fees, missing prices, route stock and cost popup refresh")

assert(loadfile("tests/planning.lua"))(CP)
assert(loadfile("tests/market.lua"))(CP)
assert(loadfile("tests/shopping.lua"))(CP)
assert(loadfile("tests/trainer_recipes.lua"))(CP)
assert(loadfile("tests/presentation.lua"))(CP,createdFrames)
assert(loadfile("tests/plan_ux.lua"))(CP,createdFrames)
assert(loadfile("tests/vendor_browser.lua"))(CP,createdFrames)
assert(loadfile("tests/foresight.lua"))(CP,createdFrames)

-- Version gossip is bounded, sanitized and does not confuse lexical version ordering.
assert(CP:IsNewerVersion("0.19.1-alpha","0.11.9-alpha"))
assert(CP:IsNewerVersion("0.19.1","0.19.1-alpha"))
assert(not CP:IsNewerVersion("0.9.0-alpha","0.19.1-alpha"))
assert(not CP:IsNewerVersion("|Hbad|h","0.19.1-alpha"))
local priorSay=CP.Say
local notices=0
CP.Say=function(_,text) notices=notices+1;assert(not text:find("evil",1,true)) end
assert(not CP:ReceiveVersion("other","V|0.99.0-alpha","GUILD"))
assert(not CP:ReceiveVersion("CraftPilotVer","V|0.99.0-alpha","WHISPER"))
assert(not CP:ReceiveVersion("CraftPilotVer","V|0.99.0-alpha|evil","GUILD"))
assert(CP:ReceiveVersion("CraftPilotVer","V|0.99.0-alpha","GUILD"))
assert(CP:ReceiveVersion("CraftPilotVer","V|0.99.0-alpha","GUILD"))
assert(notices==1 and CP.db.latestSeenVersion=="0.99.0-alpha")
assert(CP:VersionStatus():find("0.99.0",1,true))
local sent={}
C_ChatInfo={RegisterAddonMessagePrefix=function(prefix) assert(prefix=="CraftPilotVer");return true end,
 SendAddonMessage=function(prefix,payload,channel) sent[#sent+1]={prefix,payload,channel} end}
CP:InitializeVersionChecks()
assert(CP.versionChecksReady)
assert(CP:SendVersion("GUILD",true))
assert(not CP:SendVersion("GUILD",true) and not CP:SendVersion("SAY",true))
assert(#sent==1 and sent[1][2]=="Q|"..CP.version)
CP:ReceiveVersion("CraftPilotVer","Q|0.11.1-alpha","GUILD")
CP:ReceiveVersion("CraftPilotVer","Q|0.11.1-alpha","GUILD")
assert(#sent==2 and sent[2][2]=="V|"..CP.version)
CP:OpenReleaseLink()
assert(CP.releaseLinkEdit.displayText==CP.releaseURL)
CP.Say=priorSay;C_ChatInfo=nil
print("PASS: semantic version comparison, one-time notices, message filtering, throttling and copy link")

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
    for _,tab in ipairs({"now","stages","mats","plan","trainers","camping","economy","audit","settings"}) do translated:OpenTab(tab) end
  end
  for _,page in ipairs({"fires","objects","buffs","shopping"}) do
    translated.db.ui.campingPage=page
    for _,card in ipairs(translated:CampingCards("cooking")) do
      assert(not (card.title or ""):find("Nicht als erlernt",1,true))
    end
  end
  translated.db.ui.vendorBrowser=true
  for _,key in ipairs({"engineering","blacksmithing","tailoring","leatherworking","alchemy","enchanting","cooking","firstaid"}) do translated.db.view=key;translated:OpenTab("now") end
  local englishScope=translated:VendorRecipeBrowseOptions("engineering","3979")
  assert(#englishScope==1 and not englishScope[1].requirements:find("Beruf",1,true))
  for german,english in pairs(translated.English) do
    local function placeholders(s)
      local values={};for value in s:gmatch("%%[sdif]") do values[#values+1]=value end
      return table.concat(values,",")
    end
    assert(placeholders(german)==placeholders(english),"Translation format mismatch: "..german)
  end
end
print("PASS: camping coverage, native-data precedence, all toggle sliders and English/fallback UI rendering")
