local CP=...
local savedDB=CP.db
local oldStock,oldPrices,oldCamping=CP.ItemAvailability,CP.PriceDetails,CP.CampingRecipes
local stock={[77001]=5};local price=100
CP.ItemAvailability=function(_,id) return stock[id] or 0,stock[id] or 0,0,true,true end
CP.PriceDetails=function() return {price=price,auction=price,ageDays=0,source="Auctionator"} end
CP.CampingRecipes=function() return {{id=77003,prof="cooking",object={item=77004},mats={[77001]=2}}} end
CP.db={professions={engineering={skill=10,cap=75},tailoring={skill=10,cap=75}},
 recipes={engineering={[77002]={learned=true,mats={{77001,2}},snapshotSkill=10,difficulty=0}},
 tailoring={[77005]={learned=true,mats={{77001,3}},snapshotSkill=10,difficulty=0}}},
 plans={engineering={crafts={[77002]=2},start=10,target=20},tailoring={crafts={[77005]=1},start=10,target=20}},
 campingPlan={[77004]=1},ui={economyCut=5,tab="plan"},view="engineering",includeBank=false}
CP:InvalidateReservations()
local ledger=CP:ReservationLedger()
assert(ledger.total[77001]==5,"Never reserve more stock than physically exists")
assert(CP:AvailableForPlan(77001,"engineering")==4)
assert(CP:AvailableForPlan(77001,"tailoring")==1)
assert(CP:AvailableForPlan(77001,"camping")==0)
local engineering=CP:CostCalculation("plan","engineering")
local tailoring=CP:CostCalculation("plan","tailoring")
local camping=CP:CostCalculation("camping","cooking")
assert(engineering.buy==0 and tailoring.buy==200 and camping.buy==200)
assert(tailoring.materials[1].reserved==4 and camping.materials[1].reserved==5)
CP:PrioritizePlan("camping")
assert(CP:AvailableForPlan(77001,"camping")==2 and CP:AvailableForPlan(77001,"engineering")==3)
CP:StampPlan("engineering");assert(not CP:PlanNeedsReview("engineering"))
price=200;assert(CP:PlanNeedsReview("engineering"),"Changed price requires review")
CP:ReevaluatePlan("engineering");assert(not CP:PlanNeedsReview("engineering"))
stock[77001]=4;CP:InvalidateReservations();assert(CP:PlanNeedsReview("engineering"))
CP:StampPlan("engineering");CP.db.professions.engineering.skill=11
assert(CP:PlanNeedsReview("engineering"),"Changed skill requires review")
assert(not CP:RecordPlannedCraft("target","foreign",77002))
assert(CP:RecordPlannedCraft("player","craft-one",77002))
assert(CP.db.plans.engineering.crafts[77002]==1)
assert(not CP:RecordPlannedCraft("player","craft-one",77002),"Duplicate event cannot consume two crafts")
assert(CP:RecordPlannedCraft("player","craft-two",77002))
assert(CP.db.plans.engineering.crafts[77002]==nil)
assert(CP:RecordPlannedCraft("player","camp-one",77003) and CP.db.campingPlan[77004]==nil)
-- A new choice, priority change and clear must immediately release old reservations.
assert(CP:AddPlanCraft("engineering",77002,1))
CP:ClearPlanCraft("engineering")
assert(CP:AvailableForPlan(77001,"tailoring")==4)
local oldName,oldSecret,oldGrabber=UnitName,issecretvalue,BugGrabber
UnitName=function() return "TestPlayer" end
CP.db.diagnostics={};CP.diagnosticNotice=nil
assert(not CP:CaptureDiagnostic("OtherAddon failure","other.lua:1"))
assert(CP:CaptureDiagnostic("CraftPilot TestPlayer failure user@example.com","C:\\Users\\Person\\secret.lua\nCraftPilot/Core.lua:1"))
local report=CP:BuildDiagnosticReport()
assert(not report:find("TestPlayer",1,true) and not report:find("user@example",1,true) and not report:find("Person",1,true))
assert(report:find("CraftPilot/Core.lua:1",1,true))
assert(CP:CaptureDiagnostic("CraftPilot TestPlayer failure user@example.com","C:\\Users\\Person\\secret.lua\nCraftPilot/Core.lua:1"))
assert(#CP.db.diagnostics==1 and CP.db.diagnostics[1].count==2)
for i=1,25 do CP:CaptureDiagnostic("CraftPilot issue "..i,"") end
assert(#CP.db.diagnostics==20)
issecretvalue=function(value) return value=="secret" end
assert(not CP:CaptureDiagnostic("secret","CraftPilot"));issecretvalue=oldSecret
BugGrabber={GetDB=function() return {{message="CraftPilot imported",stack="CraftPilot/UI.lua:1",locals="DO NOT COLLECT"}} end}
CP:ImportBugGrabberDiagnostics()
report=CP:BuildDiagnosticReport();assert(not report:find("DO NOT COLLECT",1,true))
local link=CP:DiagnosticIssueURL(string.rep("CraftPilot ä\n",5000))
assert(#link<6100 and link:find("https://github.com/Necrite82/CraftPilot/issues/new?",1,true)==1)
local oldHandler,oldReady=AddLuaErrorHandler,CP.diagnosticsReady
local listener
AddLuaErrorHandler=function(callback) listener=callback end
CP.diagnosticsReady=nil;CP:InitializeDiagnostics();assert(type(listener)=="function")
listener("Native failure","CraftPilot/Core.lua:44")
assert(CP.db.diagnostics[#CP.db.diagnostics].message=="Native failure")
local oldTicker,oldFrame,oldRender,oldRefresh=C_Timer.NewTicker,CP.frame,CP.Render,CP.RefreshCostWindow
local oldPlanningTicker=CP.planningTicker
local tick,renders
renders=0;C_Timer.NewTicker=function(_,callback) tick=callback;return {} end
CP.frame={IsShown=function() return true end};CP.Render=function() renders=renders+1 end;CP.RefreshCostWindow=function() end
CP.planningTicker=nil;CP:InitializePlanning();assert(type(tick)=="function")
tick();local priorRenders=renders;tick();assert(renders==priorRenders,"Unchanged polling must preserve active UI edits")
price=333;tick();assert(renders==priorRenders+1)
C_Timer.NewTicker,CP.frame,CP.Render,CP.RefreshCostWindow=oldTicker,oldFrame,oldRender,oldRefresh
CP.planningTicker=oldPlanningTicker;CP.planningSignature=nil
AddLuaErrorHandler,CP.diagnosticsReady=oldHandler,oldReady;CP.nativeDiagnostics=nil
CP:OpenDiagnosticReport();assert(CP.diagnosticWindow:IsShown());CP.diagnosticWindow:Hide()
UnitName,issecretvalue,BugGrabber=oldName,oldSecret,oldGrabber
CP.ItemAvailability,CP.PriceDetails,CP.CampingRecipes=oldStock,oldPrices,oldCamping
CP.db=savedDB;CP:InvalidateReservations();CP.craftGuids=nil;CP.craftGuidOrder=nil
print("PASS: cross-plan stock allocation, priority, changed plan detection, craft progress and bounded private diagnostics")
