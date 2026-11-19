local CP=...
local db=CP.db
local oldItem,oldPrice,oldStock,oldOwns,oldCatalog=C_Item.GetItemInfo,CP.PriceDetails,CP.ItemAvailability,CP.OwnsProfession,CP.RecipeVendorCatalog
local auction,age,vendor,bind=1000,0,80,0
local stock={[88002]=10}
C_Item.GetItemInfo=function() return "Test item",nil,1,1,1,"","",20,"",123,vendor,0,0,bind end
CP.PriceDetails=function() return {auction=auction,ageDays=age,price=20,source="Haendler"} end
CP.ItemAvailability=function(_,id) return stock[id] or 0,stock[id] or 0,0,true,true end
CP.OwnsProfession=function(_,key) return key=="engineering" end
local reference={recipes={[88012]={name="Future intermediate",learn=20,makes=88005,mats={[88003]=1}}}}
CP.RecipeVendorCatalog=function(_,key) return key=="engineering" and reference or nil end
CP.db={ui={economyCut=5},professions={engineering={skill=10,cap=75}},recipes={engineering={
 [88011]={name="Current craft",learned=true,snapshotSkill=10,difficulty=0,mats={{88002,2}},outputKnown=true,outputItemID=88003}}},
 plans={},includeBank=false}
CP:InvalidateReservations();CP.marketUseCache=nil
local m=CP:ItemMarket(88001)
assert(m.auction==1000 and m.net==950 and m.vendor==80 and m.channel=="auction","AH and vendor SELL must be distinct from cheapest purchase price")
auction=80;m=CP:ItemMarket(88001);assert(m.net==76 and m.channel=="vendor","Compare vendor sale with AH AFTER cut")
auction=1000;age=4;assert(CP:ItemMarket(88001).channel=="unknown")
age=nil;assert(CP:ItemMarket(88001).channel=="unknown")
age=0;auction=nil;assert(CP:ItemMarket(88001).channel=="unknown","Missing AH is not a zero-price sale")
auction=1000;vendor=nil;assert(CP:ItemMarket(88001).channel=="unknown","Do not claim vendor comparison without cached item info")
vendor=80;bind=1;m=CP:ItemMarket(88001);assert(m.channel=="vendor" and m.bound)
bind=0;vendor=0;m=CP:ItemMarket(88001);assert(m.vendor==0 and m.channel=="auction","A known zero vendor price is distinct from missing info")
CP.db.plans.engineering={start=10,target=30,crafts={[88011]=3}}
CP:InvalidateReservations();CP.marketUseCache=nil
m=CP:ItemMarket(88002)
assert(m.required==6 and m.keep==6 and m.surplus==4 and m.advice:find("Für Pläne",1,true))
assert(m.advice:find("Weitere Rezeptverwendung",1,true),"Unplanned follow-up demand must protect surplus advice")
m=CP:ItemMarket(88003)
assert(#m.uses==1 and m.uses[1].id==88012 and m.uses[1].reference and m.advice:find("Referenz",1,true))
assert(CP:RecipeMarketOutput("engineering",88011)==88003)
CP.db.recipes.engineering[88011].outputItemID=nil
reference.recipes[88011]={makes=88099}
assert(CP:RecipeMarketOutput("engineering",88011)==nil,"Fresh non-item output must not regain an old catalog result")
CP.db.recipes.engineering[88011].outputItemID=88003
local lines=CP:MarketCostLines({kind="plan",key="engineering"})
assert(#lines==1 and lines[1]:find("AH/St.",1,true))
local requested=0;local oldRequest=C_Item.RequestLoadItemDataByID
C_Item.GetItemInfo=function() end
C_Item.RequestLoadItemDataByID=function() requested=requested+1 end
CP.marketRequested=nil
CP:MarketItemData(88001);CP:MarketItemData(88001)
assert(requested==1,"Uncached item requests must not loop during rendering")
C_Item.GetItemInfo,C_Item.RequestLoadItemDataByID=oldItem,oldRequest
CP.PriceDetails,CP.ItemAvailability,CP.OwnsProfession,CP.RecipeVendorCatalog=oldPrice,oldStock,oldOwns,oldCatalog
CP.db=db;CP.marketUseCache=nil;CP.marketRequested=nil;CP:InvalidateReservations()
print("PASS: AH unit versus buy/vendor prices, net deductions, stale/bound safeguards, keep quantities and follow-up recipes")
