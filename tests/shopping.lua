local CP=...
local db=CP.db
local oldStock,oldName,oldPrice,oldAuction,oldCamping,oldBuild=CP.ItemAvailability,CP.ItemName,CP.PriceDetails,Auctionator,CP.CampingRecipes,CP.BuildRouteForCurrentPlan
local stock={[87001]=1,[87002]=1}
CP.ItemAvailability=function(_,id) return stock[id] or 0,stock[id] or 0,0,true,true end
CP.ItemName=function(_,id) return "Material "..id end
CP.PriceDetails=function() return {price=100,auction=100,ageDays=0} end
CP.CampingRecipes=function() return {} end
CP.db={ui={},view="engineering",professions={engineering={skill=10,cap=75}},recipes={engineering={
 [87011]={name="Smelt",learned=true,mats={{87001,2}},outputItemID=87002,outputMin=1,outputMax=1},
 [87012]={name="Tool",learned=true,mats={{87002,2}},outputItemID=87003,outputMin=1,outputMax=1}},
 tailoring={[87013]={learned=true,mats={{87001,2}}}}},
 plans={engineering={start=10,target=20,crafts={[87011]=3,[87012]=2}}},includeBank=false}
CP:InvalidateReservations()
local resolved=assert(CP:ResolveManualPlan("engineering"))
assert(resolved.bought[87001]==5 and not resolved.bought[87002],"One owned bar plus three produced bars must avoid buying intermediates")
assert(resolved.requirements[87001]==6 and resolved.requirements[87002]==1)
assert(resolved.order[1]==87011 and resolved.order[2]==87012)
local catalog=CP:Catalog("engineering")
for id,recipe in pairs(catalog.recipes) do
 if type(recipe.makes)=="number" and type(recipe.mats)=="table" and next(recipe.mats) then
  CP.db.recipes.engineering[id]={learned=true,mats={{87001,9}},outputItemID=recipe.makes,outputKnown=true,outputMin=3}
  local found=false
  for _,producer in ipairs(CP:RecipesMaking(recipe.makes,"engineering",10)) do
   if producer.id==id then assert(producer.recipe.mats[87001]==9 and producer.recipe.count==3);found=true end
  end
  assert(found,"Recursive auto-route producers must use current materials and minimum output")
  CP.db.recipes.engineering[id]=nil
  break
 end
end
local converted,created={},{}
Auctionator={API={v1={ConvertToSearchString=function(caller,term)
 assert(caller=="CraftPilot" and term.isExact and term.quantity>0)
 converted[#converted+1]=term;return term.searchString.."/quantity="..term.quantity
end,CreateShoppingList=function(caller,name,terms)
 assert(caller=="CraftPilot");created[#created+1]={name=name,terms=terms}
end}}}
local ok,name,terms=CP:ExportToAuctionator("engineering")
assert(ok and name:find("10-20",1,true) and #terms==1 and converted[1].quantity==5)
assert(#created==1 and created[1].terms[1]:find("87001",1,true))
local text=CP:RecipeStockText("engineering",87011)
assert(text:find("Tasche 1",1,true) and text:find("Bank 0",1,true))
-- Missing output quantity, missing names, cycles and partial routes never write partial lists.
CP.db.recipes.engineering[87011].outputMin=nil
assert(not CP:ExportToAuctionator("engineering") and #created==1)
CP.db.recipes.engineering[87011].outputMin=1
CP.ItemName=function(_,id) return "Item #"..id end
assert(not CP:ExportToAuctionator("engineering") and #created==1)
CP.ItemName=function(_,id) return "Material "..id end
CP.db.recipes.engineering[87011].mats={{87003,1}}
assert(not CP:ExportToAuctionator("engineering") and #created==1)
CP.db.recipes.engineering[87011].mats={{87001,2}}
CP.db.plans.tailoring={crafts={[87013]=1},start=10,target=20}
CP.db.reservationOrder={"tailoring","engineering"};CP:InvalidateReservations()
resolved=assert(CP:ResolveManualPlan("engineering"));assert(resolved.bought[87001]==6,"Other plans' stock must not be exported as owned")
CP.db.plans.tailoring=nil;CP:InvalidateReservations()
stock[87001]=100
ok,name,terms=CP:ExportToAuctionator("engineering")
assert(ok and #terms==0 and #created==2,"Empty deficits must clear a stale own list")
local plan=CP.db.plans.engineering;plan.autoMode=true;plan.autoRoute={}
CP.BuildRouteForCurrentPlan=function()
 local route={first=10,target=20,reached=19,blocked=19,materials={{id=87001,missing=7}}}
 plan.autoRoute=route;return true,route
end
assert(not CP:ExportToAuctionator("engineering") and #created==2)
CP.BuildRouteForCurrentPlan=function()
 local route={first=10,target=20,reached=20,materials={{id=87001,missing=7}}}
 plan.autoRoute=route;return true,route
end
-- Skip review because the fixture stub intentionally does not stamp its route.
CP:StampPlan("engineering")
ok,name,terms=CP:ExportToAuctionator("engineering")
assert(ok and #terms==1 and converted[#converted].quantity==7)
Auctionator={API={v1={}}};assert(not CP:ExportToAuctionator("engineering"))
CP.ItemAvailability,CP.ItemName,CP.PriceDetails,Auctionator,CP.CampingRecipes,CP.BuildRouteForCurrentPlan=oldStock,oldName,oldPrice,oldAuction,oldCamping,oldBuild
CP.db=db;CP.marketUseCache=nil;CP:InvalidateReservations()
print("PASS: exact Auctionator quantity export, owned/produced intermediates, reservations, preflight failures and stale-list clearing")
