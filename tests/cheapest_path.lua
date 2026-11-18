-- Cheapest path: per-point expected cost with color chances, fees once, stock not distorting.
local CP=...
local saved={prof=CP.db.professions.engineering,recipes=CP.db.recipes.engineering,catalog=CP.Catalog,vendorCatalog=CP.RecipeVendorCatalog,
  fee=CP.TrainerRecipeFee,vendors=CP.RecipeVendors,price=CP.PriceDetails,making=CP.RecipesMaking,cache=CP.pathCache,known=CP.db.ui.knownRecipesOnly}
local A,B,C=97001,97002,97003
local recipes={
  [A]={name="Yellow cheap",learn=90,colors={90,100,105,110},mats={[51001]=1}},
  [B]={name="Orange dear",learn=95,colors={95,108,109,110},mats={[51002]=1}},
  [C]={name="Trainer bargain",learn=100,colors={100,110,110,110},mats={[51003]=1},get={{kind="trainer",cost=0}}},
}
local catalog={recipes=recipes,npcs={}}
CP.Catalog=function() return catalog end
CP.RecipeVendorCatalog=function() return catalog end
local fee=1000
CP.TrainerRecipeFee=function(_,key,id) if id==C then return fee,false,true end end
CP.RecipeVendors=function() return {} end
local prices={[51001]=10,[51002]=12,[51003]=1}
CP.PriceDetails=function(_,id) return {price=prices[id]} end
CP.RecipesMaking=function() return {} end
CP.db.ui.knownRecipesOnly=false
CP.db.professions.engineering={skill=100,cap=110}
CP.db.recipes.engineering={
  [A]={name="Yellow cheap",learned=true,snapshotSkill=100,difficulty=1,mats={{51001,1}}},
  [B]={name="Orange dear",learned=true,snapshotSkill=100,difficulty=0,mats={{51002,1}}},
}
-- Yellow A costs 10/0.7 = 14.3 per point, orange B 12 per point: B is cheaper even though A is cheaper per craft.
CP.pathCache=nil
local path=CP:CheapestPath("engineering")
assert(path and path.reached==110,"Path reaches the training cap")
assert(path.segments[1].id==B and path.segments[1].first==100,"Orange 12 beats yellow 10/0.7 per point")
local before=path.total
-- A trainer recipe at 1 per craft saves about 11 per point over 10 points, less than a 1000 fee: not taken.
for _,s in ipairs(path.segments) do assert(s.id~=C,"Expensive fee must not pay off") end
-- With a fee of 50 it pays for itself and becomes the first step, learned once.
fee=50;CP.pathCache=nil
path=CP:CheapestPath("engineering")
assert(path.segments[1].id==C and not path.segments[1].learned and path.fees==50,"Cheap training is used and charged once")
assert(path.total<before)
-- Own stock never makes a recipe look free: the per-point value uses market prices.
assert(math.abs(CP:PathPointCost("engineering",A)-10/0.7)<0.01)
-- The recommendation follows the path: learn first, then craft.
local savedOffers,savedCost=CP.TrainerRecipeOptions,CP.CostCalculation
CP.TrainerRecipeOptions=function() return {} end;CP.trainerOfferCache=nil
CP.CostCalculation=function() return {materials={},cashComplete=true,buy=0,missingBuy=0,unknownRecipes=0} end
local priorCapture=CP.db.lastCapture
CP.db.lastCapture={key="engineering",skill=100}
local rec=CP:Recommendation("engineering")
assert(rec and rec.id==C and rec.learn and rec.title:find("Erst lernen",1,true),"Recommendation starts with learning the bargain")
assert(rec.detail:find("Ganzer Weg bis 110",1,true))
-- Saving tip: a far cheaper option per point than the pick is named.
local fakePath={segments={{id=A,name="Pick",crafts=10,last=110,learned=true}},perPointNow={[A]=100,[C]=20},reached=110,total=1000,
  optionsNow={{id=C,name="Bargain",perPoint=20,learned=false},{id=A,name="Pick",perPoint=100,learned=true}}}
local savedPath=CP.CheapestPath;CP.CheapestPath=function() return fakePath end
local tipRec=CP:Recommendation("engineering")
assert(tipRec.tip and tipRec.tip.id==C and tipRec.detail:find("Spartipp: Bargain",1,true),"Cheaper option named as saving tip")
CP.CheapestPath=savedPath
assert(#CP:PathSummaryLines(path)>=2)
-- Missing prices are reported rather than guessed.
prices[51003]=nil;CP.pathCache=nil
path=CP:CheapestPath("engineering")
assert(path.unpriced==1 and path.segments[1].id==B)
CP.db.lastCapture=priorCapture
CP.TrainerRecipeOptions,CP.CostCalculation=savedOffers,savedCost
CP.db.professions.engineering,CP.db.recipes.engineering,CP.Catalog,CP.RecipeVendorCatalog=saved.prof,saved.recipes,saved.catalog,saved.vendorCatalog
CP.TrainerRecipeFee,CP.RecipeVendors,CP.PriceDetails,CP.RecipesMaking,CP.pathCache,CP.db.ui.knownRecipesOnly=saved.fee,saved.vendors,saved.price,saved.making,nil,saved.known
CP.trainerOfferCache=nil
print("PASS: cheapest path by expected cost per point (orange vs yellow), fees once and only when they pay off, unpriced recipes reported")
