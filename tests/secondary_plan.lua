-- 1.4.2: a plan from 1 to 300 for cooking and first aid (full catalog, start recipes, vendor recipes, no holiday vendors).
local CP=...
local saved={price=CP.PriceDetails,cook=CP.db.professions.cooking,aid=CP.db.professions.firstaid,
  rc=CP.db.recipes.cooking,ra=CP.db.recipes.firstaid,pc=CP.db.plans.cooking,pa=CP.db.plans.firstaid}
CP.PriceDetails=function(self,id) local d=saved.price(self,id) or {};if not d.price then d.price=100;d.auction=100 end;return d end
CP.pathCache=nil;CP.pathCaches={}
assert(CP:Catalog("cooking") and CP:Catalog("firstaid"),"full catalog for cooking and first aid")
assert(not CP.CatalogData.cooking.recipes[8604].unavailable,"Herb Baked Egg comes with the profession")
local cookie=CP.CatalogData.cooking.recipes[21143]
assert(cookie.get[1].event=="winterveil","Winter Veil vendor marked")
for _,key in ipairs({"cooking","firstaid"}) do
  CP.db.professions[key]={skill=1,cap=75};CP.db.recipes[key]={};CP.db.plans[key]=nil
  local p=CP:PlanFor(key)
  assert(CP:SetPlanRange(key,1,300))
  local route=assert(CP:GenerateAutomaticRoute(key,1,300,p.preferences,p.materialPreferences,{}))
  assert(route.reached==300,key.." plan reaches 300, got "..tostring(route.reached))
  for _,s in ipairs(route.steps) do assert(s.id~=21143 and s.id~=21144,"no holiday recipe in the plan") end
  if key=="firstaid" then
    local vendor=false
    for _,s in ipairs(route.steps) do if s.source=="vendor" then vendor=true end end
    assert(vendor,"first aid uses the vendor manuals between 180 and 240")
  end
end
CP.PriceDetails=saved.price
CP.db.professions.cooking,CP.db.professions.firstaid,CP.db.recipes.cooking,CP.db.recipes.firstaid,CP.db.plans.cooking,CP.db.plans.firstaid=
  saved.cook,saved.aid,saved.rc,saved.ra,saved.pc,saved.pa
CP.pathCache=nil;CP.pathCaches={};CP:InvalidateReservations()
print("PASS: 1.4.2 plan 1-300 for cooking and first aid: start and vendor recipes, no holiday vendors")
