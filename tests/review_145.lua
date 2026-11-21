-- Project export and quantities across recipe batches, project steps and reservation owners.
local CP=...
local saved={db=CP.db,avail=CP.ItemAvailability,name=CP.ItemName,price=CP.PriceDetails,
  catalog=CP.RecipeVendorCatalog,producers=CP.ItemProducers,auction=Auctionator}
local stock={}
local catalog={recipes={
  [3973]={makes=4404,yield=5,mats={[2842]=1}},
  [91001]={makes=92001,yield=1,mats={[93001]=8}},
  [91002]={makes=92002,yield=1,mats={[93001]=8}},
  [91003]={makes=93001,yield=1,mats={[93002]=1}},
}}
CP.db={ui={},professions={},recipes={engineering={
  [3973]={learned=true,mats={{2842,1}},outputMin=5},
  [91001]={learned=true,mats={{93001,8}},outputMin=1},
  [91002]={learned=true,mats={{93001,8}},outputMin=1},
  [91003]={learned=true,mats={{93002,1}},outputMin=1},
},tailoring={[91004]={learned=true,mats={{93001,6}}}}},plans={},projects={}}
CP.ItemAvailability=function(_,id) local n=stock[id] or 0;return n,n,0,true,true end
CP.ItemName=function(_,id) return "Material "..id end
CP.PriceDetails=function() return {price=100,auction=100,ageDays=0} end
CP.RecipeVendorCatalog=function(_,key) return key=="engineering" and catalog or {recipes={}} end
CP.ItemProducers=function(_,id) return id==93001 and {{key="engineering",id=91003}} or {} end

local p={id=1,steps={{type="item",item=4404,count=5,key="engineering",id=3973}}}
CP.db.projects={p}
assert(CP:ProjectRequirements()[2842]==1,"Five contacts are one craft, not five")
CP.db.recipes.engineering[3973].outputMin=nil
assert(CP:ProjectRequirements()[2842]==1,"Use catalog yield when the client has no quantity")
CP.db.recipes.engineering[3973].outputMin=2
assert(CP:ProjectRequirements()[2842]==3,"Current client quantity takes precedence over catalog yield")
CP.db.recipes.engineering[3973].outputMin=5

p.steps={{type="item",item=92001,count=1,key="engineering",id=91001},
  {type="item",item=92002,count=1,key="engineering",id=91002}}
stock[93001]=10
local st=CP:ProjectStatus(p)
assert(st.required[93001]==10 and st.required[93002]==6,"The same ten bars are shared by both steps")
assert(#st.intermediates==1 and st.intermediates[1].count==6,"Smelt the six missing bars")
local created,terms=0,nil
Auctionator={API={v1={ConvertToSearchString=function(caller,term)
  assert(caller=="CraftPilot" and term.isExact)
  return term.searchString..":"..term.quantity
end,CreateShoppingList=function(_,_,list) created=created+1;terms=list end}}}
CP:InvalidateReservations()
assert(CP:ExportToAuctionator("project"))
assert(created==1 and #terms==1 and terms[1]=="Material 93002:6","Export raw materials and quantities")

-- The earlier profession plan keeps six bars; the project can only consume four.
CP.db.plans.tailoring={crafts={[91004]=1}}
CP.db.reservationOrder={"tailoring","project"}
CP:InvalidateReservations()
st=CP:ProjectStatus(p)
assert(st.required[93001]==4 and st.required[93002]==12,"Respect the earlier owner's reserved bars")
assert(CP:ExportToAuctionator("project") and terms[1]=="Material 93002:12")
CP.db.reservationOrder={"project","tailoring"}
CP:InvalidateReservations()
assert(CP:ExportToAuctionator("project") and terms[1]=="Material 93002:6","Project priority changes the same shared allocation")

-- A finished stack cannot complete two separate projects at once.
CP.db.plans={};CP.db.reservationOrder=nil
stock={[4404]=4}
p.steps={{type="item",item=4404,count=4,key="engineering",id=3973}}
local second={id=2,steps={{type="item",item=4404,count=4,key="engineering",id=3973}}}
CP.db.projects={p,second}
assert(CP:ProjectStatus(p).done and not CP:ProjectStatus(second).done)
local req=CP:ProjectRequirements()
assert(req[4404]==4 and req[2842]==1,"Reserve the existing stack once and plan the second project's craft")
CP:InvalidateReservations()
assert(CP:ExportToAuctionator("project") and #terms==1 and terms[1]=="Material 2842:1")

-- Cover the last deficit: the exact same Auctionator list is cleared, not left stale.
stock[2842]=1;CP:InvalidateReservations()
assert(CP:ExportToAuctionator("project") and #terms==0)

CP.db,CP.ItemAvailability,CP.ItemName,CP.PriceDetails,CP.RecipeVendorCatalog,CP.ItemProducers,Auctionator=
  saved.db,saved.avail,saved.name,saved.price,saved.catalog,saved.producers,saved.auction
CP:InvalidateReservations()
print("PASS: 1.4.5 project export, client batch yields, shared step/project stock and reservation priority")
