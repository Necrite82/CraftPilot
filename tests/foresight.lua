local CP,frames=...
local db,cat,making,price,stock=CP.db,CP.Catalog,CP.RecipesMaking,CP.PriceDetails,CP.ItemAvailability
local data={recipes={
 [97101]={name="Useful X",learn=50,colors={50,60,60,60},makes=97201,yield=2,mats={[97301]=1},get={{kind="start"}}},
 [97102]={name="Cheap Y",learn=50,colors={50,60,60,60},makes=97202,mats={[97302]=1},get={{kind="start"}}},
 [97103]={name="Next step",learn=60,colors={60,75,80,90},makes=97203,mats={[97201]=2,[97303]=1},get={{kind="trainer",cost=0}}}}}
CP.db={ui={selectedRecipes={},preferReliableSkill=false},professions={engineering={skill=50,cap=75}},recipes={engineering={}},plans={},includeBank=false}
CP.Catalog=function(_,key) return key=="engineering" and data or nil end
CP.RecipesMaking=function(_,item) return item==97201 and {{key="engineering",id=97101,recipe=data.recipes[97101]}} or {} end
CP.PriceDetails=function(_,id) return {price=({[97301]=5,[97302]=3,[97303]=1,[97201]=9})[id],ageDays=0} end
local have=0;CP.ItemAvailability=function(_,id) return id==97201 and have or 0,0,0,true,true end
CP:InitializeSkillPolicy();CP:InvalidateReservations()
CP.db.ui.planAhead=false
local direct=assert(CP:GenerateAutomaticRoute("engineering",50,70));assert(direct.price==90 and direct.steps[1].id==97102)
CP.db.ui.planAhead=true
local route=assert(CP:GenerateAutomaticRoute("engineering",50,70))
assert(route.price==60 and route.reached==70 and route.steps[1].id==97101 and route.steps[1].crafts==10)
assert(route.forwardPlan.saved==30 and route.forwardPlan.craftsSaved==10 and route.steps[1].forward)
local prefs={};for s=50,59 do prefs[s]=97102 end
assert(CP:GenerateAutomaticRoute("engineering",50,70,prefs).price==90,"Explicit user choice must survive forward planning")
have=20;CP:InvalidateReservations();route=CP:GenerateAutomaticRoute("engineering",50,70)
assert(route.price==40 and route.steps[1].id==97102,"Existing X must prevent unnecessary early replacement")
have=0;CP:InvalidateReservations()
-- Skill policy applies at colour-change offsets, including a route beginning mid-colour.
local colors={colors={50,60,65,70}}
CP.db.ui.yellowPoints=3;CP.db.ui.greenPoints=2
assert(CP:SkillPolicyAllows("engineering",1,colors,62,.67))
assert(not CP:SkillPolicyAllows("engineering",1,colors,63,.67))
assert(CP:SkillPolicyAllows("engineering",1,colors,66,.33))
assert(not CP:SkillPolicyAllows("engineering",1,colors,67,.33))
CP.db.ui.allowYellow=false;assert(not CP:SkillPolicyAllows("engineering",1,colors,60,.67))
CP.db.ui.allowGreen=false;assert(not CP:SkillPolicyAllows("engineering",1,colors,65,.33))
assert(CP:SkillPolicyAllows("engineering",1,colors,59,1))
CP.db.ui.allowYellow=true;CP.db.ui.allowGreen=true;CP.db.ui.yellowPoints=0;CP.db.ui.greenPoints=0
assert(CP:SkillPolicyAllows("engineering",1,colors,69,.33))
-- A yellow producer may be useful, but count rounding must not overproduce for the follow-up.
data.recipes[97101].colors={50,50,60,60}
route=CP:GenerateAutomaticRoute("engineering",50,70)
assert(route.price==72 and route.reached==70,"Forward comparison includes integer yellow batches and late make-or-buy needs")
CP.db.ui.yellowPoints=3
route=CP:GenerateAutomaticRoute("engineering",50,70)
assert(route.reached==70 and route.price<90 and route.price>=72)
CP.db.ui.allowYellow=false
route=CP:GenerateAutomaticRoute("engineering",50,70)
assert(route.steps[1].id==97102 and route.price==90,"Disallowed yellow cannot become a skill-producing forward step")
-- Fresh saved routes promote useful X in Now and provide the planned batch/follow-up quantities.
CP.db.ui.allowYellow=true;CP.db.ui.yellowPoints=0;data.recipes[97101].colors={50,60,60,60}
for _,id in ipairs({97101,97102}) do local r=data.recipes[id];CP.db.recipes.engineering[id]={name=r.name,learned=true,snapshotSkill=50,difficulty=0,mats={},outputItemID=r.makes,outputMin=r.yield or 1};for item,n in pairs(r.mats) do table.insert(CP.db.recipes.engineering[id].mats,{item,n}) end end
local p=CP:PlanFor("engineering");p.start=50;p.target=70;p.autoMode=true;p.autoRoute=CP:GenerateAutomaticRoute("engineering",50,70)
CP:StampPlan("engineering");CP.routeAdvice=nil;CP.db.ui.recipeSort="cost"
local selected,list=CP:SelectedOption("engineering");assert(selected.id==97101 and list[1].id==97101)
local advice=CP:CraftSuggestion("engineering",97101);assert(advice.planned and advice.count==10 and advice.target==60)
local needs=CP:FollowupNeeds("engineering",97101,10,advice);assert(#needs==1 and needs[1].next==20 and needs[1].made==20 and needs[1].short==0)
-- Real UI builds yield between bounded chunks, retain the old plan until complete, and cancel safely.
local clock,timer,render,refresh,say=GetTimePreciseSec,C_Timer,CP.Render,CP.RefreshCostWindow,CP.Say
local queue,now={},0
GetTimePreciseSec=function() now=now+.004;return now end
C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
CP.Render=function() end;CP.RefreshCostWindow=function() end;CP.Say=function() end
local function drain() local n=0 while #queue>0 do local f=table.remove(queue,1);f();n=n+1;assert(n<5000) end;return n end
local old=p.autoRoute;local done=0
assert(CP:RequestRouteBuild("engineering",function() done=done+1 end));assert(CP:RouteBuildPending("engineering") and p.autoRoute==old)
local ticks=drain();assert(ticks>1 and not CP:RouteBuildPending("engineering") and p.autoRoute.price==60 and done==1)
old=p.autoRoute;CP:RequestRouteBuild("engineering");CP:CancelRouteBuild();drain();assert(p.autoRoute==old)
CP:RequestRouteBuild("engineering");have=20;drain();assert(p.autoRoute==old,"A stock change during a deferred build must discard its result")
have=0;CP:InvalidateReservations()
CP:RequestRouteBuild("engineering");CP.db.ui.yellowPoints=2;drain();assert(p.autoRoute==old,"Changed policy must not commit an obsolete result")
CP.db.ui.yellowPoints=0
CP:RequestRouteBuild("engineering");CP.db.recipes.engineering[97101].mats[1][2]=2;drain();assert(p.autoRoute==old,"Changed client reagent quantities must invalidate a deferred result")
CP.db.recipes.engineering[97101].mats[1][2]=1
-- A requested export waits for recalculation and then writes exactly once.
local auctionator=Auctionator;local exports=0
Auctionator={API={v1={ConvertToSearchString=function(_,term) return term.searchString end,CreateShoppingList=function() exports=exports+1 end}}}
p.autoRoute=nil;p.autoMode=true
local ok,why=CP:ExportToAuctionator("engineering");assert(not ok and why=="pending" and exports==0)
drain();assert(exports==1 and p.autoRoute.price==60)
CP.db.professions.engineering.skill=70
ok,why=CP:ExportToAuctionator("engineering");assert(not ok and why=="complete" and exports==1)
CP.db.professions.engineering.skill=50;Auctionator=auctionator
GetTimePreciseSec,C_Timer,CP.Render,CP.RefreshCostWindow,CP.Say=clock,timer,render,refresh,say
CP.db.recipes.engineering[97101].colorObservedStart=50
CP.db.recipes.engineering[97101].snapshotSkill=55
CP.db.ui.yellowPoints=3
assert(not CP:SkillPolicyAllows("engineering",97101,nil,55,.7),"Unknown colour boundaries must retain their first observation instead of restarting the budget on every capture")
CP.routeAdvice=nil
CP.db,CP.Catalog,CP.RecipesMaking,CP.PriceDetails,CP.ItemAvailability=db,cat,making,price,stock
CP.unlockCache=nil;CP.marketUseCache=nil;CP:InvalidateReservations()
print("PASS: colour budgets from transitions, early X versus cheaper Y, whole-route savings, user overrides, existing stock, yellow rounding, saved-route advice and cancellable deferred builds")
