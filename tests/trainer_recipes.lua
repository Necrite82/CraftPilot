local CP=...
local db,cat,price,stock,own=CP.db,CP.RecipeVendorCatalog,CP.PriceDetails,CP.ItemAvailability,CP.OwnsProfession
local side,map,pos=UnitFactionGroup,C_Map.GetBestMapForUnit,C_Map.GetPlayerMapPosition
UnitFactionGroup=function() return "Alliance" end
C_Map.GetBestMapForUnit=function() return 1453 end
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return .5,.5 end} end
local fee=100
local catalog={recipes={
 [98101]={name="Cheap trainer",learn=10,colors={10,50,60,70},mats={[98201]=1},get={{kind="trainer",cost=fee}}},
 [98102]={name="Future",learn=80,colors={80,100,110,120},mats={[98201]=1},get={{kind="trainer",cost=500}}},
 [98103]={name="Too late",learn=10,colors={10,50,60,70},mats={[98201]=1},get={{kind="trainer",skill=50,cost=100}}},
 [98104]={name="Specialized",learn=10,spec=99,colors={10,50,60,70},mats={[98201]=1},get={{kind="trainer",cost=1}}}}}
CP.db={ui={selectedRecipes={},economyCut=5},view="engineering",includeBank=false,
 professions={engineering={skill=25,cap=75}},recipes={engineering={[98100]={learned=true,name="Expensive learned",snapshotSkill=25,difficulty=0,mats={{98200,1}}},[98101]={learned=false}}},plans={}}
CP.RecipeVendorCatalog=function() return catalog end
CP.PriceDetails=function(_,id) return {price=id==98200 and 1000 or 10,auction=id==98200 and 1000 or 10,ageDays=0} end
CP.ItemAvailability=function() return 0,0,0,true,true end
CP.OwnsProfession=function() return true end
CP:InvalidateReservations()
local rows=CP:TrainerRecipeOptions("engineering")
assert(#rows==1 and rows[1].id==98101)
assert(rows[1].comparison.cost.fee==100 and rows[1].comparison.cost.cash==150)
assert(rows[1].comparison.cashSaving>0 and rows[1].comparison.crafts==5)
assert(rows[1].vendors[1] and rows[1].vendors[1].location.map==1453,"Prefer a compatible teacher on the current map")
local all=CP:AllRecipeOptions("engineering",CP:Options("engineering"),rows)
local future
for _,r in ipairs(all) do if r.id==98102 then future=r end end
assert(future and future.dimmed and future.referenceOnly and future.requiredSkill==80)
catalog.recipes[98101].get[1].cost=10000
rows=CP:TrainerRecipeOptions("engineering");assert(rows[1].comparison.cashSaving<0,"Learning fee must prevent a false saving")
catalog.recipes[98101].get[1].cost=nil
rows=CP:TrainerRecipeOptions("engineering");assert(rows[1].comparison.cashSaving==nil and rows[1].comparison.cost.feeUnknown)
catalog.recipes[98101].get[1].cost=100;catalog.recipes[98101].get[1].costGuess=true
assert(CP:TrainerRecipeOptions("engineering")[1].comparison.cashSaving==nil)
CP.db.recipes.engineering[98101].learned=true
assert(#CP:TrainerRecipeOptions("engineering")==0,"Learned recipe must leave the unlearned proposals")
CP.db,CP.RecipeVendorCatalog,CP.PriceDetails,CP.ItemAvailability,CP.OwnsProfession=db,cat,price,stock,own
UnitFactionGroup,C_Map.GetBestMapForUnit,C_Map.GetPlayerMapPosition=side,map,pos
CP.marketUseCache=nil;CP:InvalidateReservations()
print("PASS: unlearned trainer cost comparison, unknown fees, nearby teachers and grey future catalog recipes")
