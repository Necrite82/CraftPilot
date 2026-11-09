local CP,frames=...
local db=CP.db
local oldContext=CP.costContext
local oldChooser=CP.routeChooser
local catalog,provider,stock,price,making=CP.Catalog,CP.RecipeVendorCatalog,CP.ItemAvailability,CP.PriceDetails,CP.RecipesMaking
local prices={[96001]=10,[96002]=100,[96003]=1,[96004]=100}
local data={recipes={
 [96101]={name="Cheap",learn=1,colors={1,70,80,90},mats={[96001]=1},makes=97001,get={{kind="start"}}},
 [96102]={name="Preferred",learn=1,colors={1,70,80,90},mats={[96002]=1},makes=97002,get={{kind="start"}}},
 [96103]={name="Material maker",learn=1,colors={1,2,3,4},mats={[96001]=2},makes=96004,get={{kind="start"}}},
 [96104]={name="Consumer",learn=1,colors={1,70,80,90},mats={[96004]=1},makes=97004,get={{kind="start"}}},
 [96105]={name="Learning pays off",learn=50,colors={50,70,80,90},mats={[96003]=1},makes=97005,get={{kind="trainer",cost=20}}}}}
CP.Catalog=function(_,key) return key=="engineering" and data or nil end
CP.RecipeVendorCatalog=CP.Catalog
CP.ItemAvailability=function() return 0,0,0,true,true end
CP.PriceDetails=function(_,id) return {price=prices[id],auction=prices[id],ageDays=0} end
CP.db={ui={selectedRecipes={},preferReliableSkill=true},professions={engineering={skill=50,cap=75}},recipes={engineering={}},plans={},includeBank=false}
for id,r in pairs(data.recipes) do if id~=96105 then CP.db.recipes.engineering[id]={name=r.name,learned=true,snapshotSkill=50,difficulty=id==96103 and 3 or 0,mats={},outputItemID=r.makes,outputMin=1} for item,n in pairs(r.mats) do table.insert(CP.db.recipes.engineering[id].mats,{item,n}) end end end
CP.RecipesMaking=function(_,item) return item==96004 and {{key="engineering",id=96103,recipe=data.recipes[96103]}} or {} end
CP:InvalidateReservations()
local r=assert(CP:GenerateAutomaticRoute("engineering",50,55))
assert(r.steps[1].id==96105 and r.learning==20 and r.price==5,"One-time learning must be amortized over the route instead of always selecting the already-learned recipe")
data.recipes[96102].get={{kind="trainer",cost=1,reqLevel=999}}
-- Learned client recipes remain trusted; unlearned sources must satisfy their level gates.
local preferredNative=CP.db.recipes.engineering[96102];CP.db.recipes.engineering[96102]=nil
assert(CP:CatalogSource("engineering",96102,50)==nil)
data.recipes[96102].get={{kind="start"}};CP.db.recipes.engineering[96102]=preferredNative
local prefs={};for s=50,54 do prefs[s]=96102 end
r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs));assert(r.steps[1].id==96102 and r.preferencesApplied==5)
prefs[50]=999999;r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs));assert(r.steps[1].id~=999999 and r.ignoredPreferences==1)
for s=50,54 do prefs[s]=96104 end
r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs));assert(r.price==100)
local made=false;for _,node in ipairs(r.intermediates) do if node.id==96103 then made=true;assert(node.key=="engineering" and node.output==96004 and node.count==5) end end;assert(made)
r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs,{[96004]=0}));assert(r.price==500,"Explicit buy preference must update materials and whole-route cost")
-- A low ingredient price must not hide a high intermediate-recipe learning fee.
local maker=CP.db.recipes.engineering[96103];CP.db.recipes.engineering[96103]=nil
data.recipes[96103].get={{kind="trainer",cost=1000}}
r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs));assert(r.price==500 and r.learning==0,"Buying must beat an intermediate whose learning fee exceeds the savings")
r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs,{[96004]=96103}));assert(r.price==100 and r.learning==1000,"Explicit intermediate choice may be dearer but must include its fee once")
CP.db.recipes.engineering[96103]=maker;data.recipes[96103].get={{kind="start"}}
CP.ItemAvailability=function(_,id) return id==96001 and 10 or 0,0,0,true,true end
CP:InvalidateReservations();r=assert(CP:GenerateAutomaticRoute("engineering",50,55,prefs));assert(r.price==0,"Intermediate comparison must use available stock")
CP.ItemAvailability=function() return 0,0,0,true,true end;CP:InvalidateReservations()
local plan=CP:PlanFor("engineering");plan.start=50;plan.target=55;plan.preferences=nil;plan.materialPreferences=nil
assert(CP:ChooseRouteRecipe("engineering",50,55,96102));assert(plan.autoRoute.steps[1].id==96102)
assert(CP:ChooseRouteRecipe("engineering",50,55,nil));assert(plan.autoRoute.steps[1].id==96105)
CP:OpenRouteAlternatives("engineering",50,55);assert(CP.routeChooser:IsShown());CP.routeChooser:Hide()
CP.db.professions.engineering.skill=35
CP:ReevaluatePlan("engineering");assert(plan.start==50,"Reviewing a future range must not move its start backwards to current skill")
-- Quantity proposal: 15 current crafts, then twenty produced units needed in the next example batch.
CP.db.professions.engineering={skill=10,cap=75}
data.recipes={
 [96201]={name="Intermediate",learn=1,colors={1,25,30,40},makes=98001,mats={[96001]=1},get={{kind="start"}}},
 [96202]={name="Next orange",learn=25,colors={25,35,40,50},makes=98002,mats={[98001]=2},get={{kind="trainer",cost=10}}}}
CP.db.recipes.engineering={[96201]={learned=true,name="Intermediate",snapshotSkill=10,difficulty=0,mats={{96001,1}},outputItemID=98001,outputMin=1}}
CP.db.plans={};CP.unlockCache=nil;CP:InvalidateReservations()
local a=CP:CraftSuggestion("engineering",96201);assert(a.count==15 and a.target==25 and a.nextStep.id==96202)
local follow=CP:FollowupNeeds("engineering",96201,15,a)
assert(#follow==1 and follow[1].made==15 and follow[1].next==20 and follow[1].short==5)
assert(CP:SetRecipeQuantity("engineering",96201,7));assert(CP:RequestedRecipeQuantity("engineering",96201)==7)
assert(not CP:SetRecipeQuantity("engineering",96201,0));CP:SetRecipeQuantity("engineering",96201,nil);assert(CP:RequestedRecipeQuantity("engineering",96201)==15)
local recycled=CreateFrame("Button");CP:QuantityControl(recycled,"engineering",96201,false,160,600);recycled.quantityLabel:Hide()
CP:QuantityControl(recycled,"engineering",96201,false,160,600);assert(recycled.quantityLabel:IsShown(),"Quantity suggestion must reappear on a recycled reference row")
-- Fractional skill chances round the combined effort, not every single point.
CP.db.recipes.engineering[96201].difficulty=1;data.recipes[96201].colors={1,1,30,40}
local yellow=CP:GenerateAutomaticRoute("engineering",10,20)
assert(yellow.steps[1].crafts==15,"Ten yellow points at estimated 67% need about 15 crafts, not 20")
local f=CreateFrame("Frame");CP.costContext={kind="recipe",key="engineering",id=96201,quantity=2}
local oldRender,oldRefresh=CP.Render,CP.RefreshCostWindow
CP.Render=function() end;CP.RefreshCostWindow=function() end
CP:CostQuantityControls(f,CP.costContext);f.quantityPlus:GetScript("OnClick")();assert(CP.costContext.quantity==3 and CP:RecipeQuantityOverride("engineering",96201)==3)
CP.Render,CP.RefreshCostWindow=oldRender,oldRefresh
CP.db,CP.Catalog,CP.RecipeVendorCatalog,CP.ItemAvailability,CP.PriceDetails,CP.RecipesMaking=db,catalog,provider,stock,price,making
CP.unlockCache=nil;CP.marketUseCache=nil;CP.costContext=oldContext;CP.routeChooser=oldChooser;CP:InvalidateReservations()
CP:OpenTab("plan");assert(CP:PlanPageCards(CP.db.view,"shopping"))
local create,export
for _,b in ipairs(frames) do local t=rawget(b,"displayText");if t=="Plan erstellen" and b:IsShown() then create=b end;if t=="An Auctionator" and b:IsShown() then export=b end end
assert(create and export and create.point[5]==-250 and export.point[5]==-250,"Primary plan actions must remain above the scroll area")
print("PASS: editable route constraints, intermediate buy preference, learning-fee lookahead, batch quantities/follow-up stock and pinned actions")
