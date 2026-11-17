-- 0.26: keep for later steps, price limits, budget, leftovers, vendor helper and item tooltips.
local CP,createdFrames=...
local saved={}
for _,name in ipairs({"AutoRouteShopping","CheapestPath","ItemAvailability","ItemName","PriceDetails","RawItemCount","RecipeVendorCatalog",
  "PlanRequirements","AltStock","AltProfessions","OwnsProfession","SearchItems","Say"}) do saved[name]=CP[name] end
local savedPlans,savedRecipes,savedProf,savedUI=CP.db.plans,CP.db.recipes.engineering,CP.db.professions.engineering,{budget=CP.db.ui.budgetGold,tooltips=CP.db.ui.tooltips}
CP.ItemName=function(_,id) return "Item "..id end
local stock={}
CP.ItemAvailability=function(_,id) return stock[id] or 0 end
CP.AltStock=function() return {} end

-- Keep for later: a saved route makes 10 tubes at 50 and uses 2 per craft in 3 crafts from 60.
local route={steps={
  {id=1,name="Tube",first=50,last=60,crafts=10,output=70010,yield=1,mats={[70001]=1}},
  {id=2,name="Gadget",first=60,last=70,crafts=3,output=70011,yield=1,mats={[70010]=2,[70002]=1}},
},intermediates={}}
CP.AutoRouteShopping=function() return route end
CP.keepCache=nil
local keep=CP:KeepList("engineering")
assert(#keep==1 and keep[1].item==70010 and keep[1].need==6 and keep[1].keep==6 and not keep[1].enough)
assert(keep[1].uses[1].name=="Gadget" and keep[1].uses[1].at==60)
assert(CP:KeepText(keep[1]):find("Behalten: 6",1,true) and CP:KeepText(keep[1]):find("nicht verkaufen",1,true))
local cards=CP:KeepCards("engineering")
assert(#cards==2 and cards[1].sectionHeader and cards[2].color=="gold")
stock[70010]=8;CP.keepCache=nil
keep=CP:KeepList("engineering")
assert(keep[1].enough and CP:KeepText(keep[1]):find("nicht erneut herstellen",1,true),"Enough in stock: do not craft again")
stock[70010]=nil;CP.keepCache=nil

-- Without a saved route the cheapest path's segments are used.
CP.AutoRouteShopping=function() return nil end
local catalog={recipes={[11]={makes=70020,mats={[70003]=1}},[12]={makes=70021,mats={[70020]=3}}}}
CP.RecipeVendorCatalog=function() return catalog end
CP.CheapestPath=function() return {from=1,reached=20,segments={
  {id=11,name="Bar",first=1,last=10,crafts=12,cost=1000,learned=true},
  {id=12,name="Plate",first=10,last=20,crafts=8,cost=4000,learned=false,fee=500}}} end
keep=CP:KeepList("engineering")
assert(#keep==1 and keep[1].item==70020 and keep[1].need==24 and keep[1].keep==12,"12 made, 24 needed later: keep all")

-- Budget: 1000 for points 1–10, a fee of 500, then 400 per point.
local reach=CP:BudgetReach(CP:CheapestPath("engineering"),1000+500+400*3)
assert(reach.reached==13 and reach.spent==2700 and reach.dear[1].name=="Plate")
assert(CP:BudgetReach(CP:CheapestPath("engineering"),0)==nil)
CP.db.ui.budgetGold=1
local budget=CP:BudgetCards("engineering")
assert(#budget==3 and budget[2].slider and budget[3].title:find("Skill",1,true))
CP.db.ui.budgetGold=savedUI.budget

-- Price limits from the real path: orange A costs 10 per point, orange B 12. A's material may cost up to 12.
CP.CheapestPath=saved.CheapestPath
local A,B=97501,97502
catalog={recipes={
  [A]={name="Cheap",learn=1,colors={1,40,50,60},mats={[51101]=1}},
  [B]={name="Dear",learn=1,colors={1,40,50,60},mats={[51102]=1}},
}}
local prices={[51101]=10,[51102]=12}
CP.PriceDetails=function(_,id) return {price=prices[id],auction=prices[id],freshness="fresh",ageDays=0} end
CP.db.recipes.engineering={[A]={name="Cheap",learned=true,snapshotSkill=10,difficulty=0},[B]={name="Dear",learned=true,snapshotSkill=10,difficulty=0}}
CP.db.professions.engineering={skill=10,cap=20}
CP.pathCache=nil
local path=CP:CheapestPath("engineering")
local limit=path.priceLimits[51101]
assert(path.segments[1].id==A and limit and math.abs(limit.price-12)<0.01 and limit.alt=="Dear","Cheap stays best up to 12")
assert(CP:PriceLimit("engineering",51101).price==limit.price)
local limitCards=CP:PriceLimitCards("engineering",{51101})
assert(#limitCards==2 and limitCards[2].color=="green")
prices[51101]=15
assert(CP:PriceLimitCards("engineering",{51101})[2].color=="red","Above the limit is marked")
prices[51101]=10;CP.pathCache=nil

-- Leftovers: 5 crafted, nothing keeps them; the AH pays more than the vendor.
CP.AutoRouteShopping=function() return nil end
catalog={recipes={[21]={makes=70030,mats={}}}}
CP.db.plans={}
CP.db.recipes.engineering={}
CP.RawItemCount=function(_,id) return id==70030 and 5 or 0 end
prices={[70030]=100}
CP.AltProfessions=function() return {} end
CP.OwnsProfession=function() return false end
local left=CP:Leftovers("engineering")
assert(#left==1 and left[1].count==5 and left[1].how=="ah" and left[1].ah==95)
local leftCards=CP:LeftoverCards("engineering")
local searchedItems
CP.SearchItems=function(_,items) searchedItems=items;return true end
assert(leftCards[2].action);leftCards[2].action();assert(searchedItems[1].id==70030)
-- Kept for a plan: never offered for sale.
CP.PlanRequirements=function(_,owner) return owner=="engineering" and {[70030]=5} or {} end
CP.db.plans={engineering={start=1,target=20,crafts={}}}
assert(#CP:Leftovers("engineering")==0,"Planned items are not leftovers")

-- Vendor helper: the plan misses 7 thread; the vendor sells single threads.
CP.PlanRequirements=function(_,owner) return owner=="engineering" and {[2320]=10} or {} end
stock[2320]=3
GetMerchantNumItems=function() return 2 end
GetMerchantItemID=function(i) return i==1 and 2320 or 9999 end
GetMerchantItemInfo=function(i) return i==1 and "Coarse Thread" or "Other",nil,10,1,-1 end
GetMerchantItemMaxStack=function() return 20 end
local bought={}
BuyMerchantItem=function(i,n) bought[#bought+1]={i,n} end
GetMoney=function() return 100000 end
local offers=CP:MerchantOffers()
assert(#offers==1 and offers[1].count==7 and offers[1].cost==70)
assert(CP:BuyMerchantOffer(offers[1]) and bought[1][1]==1 and bought[1][2]==7)
CP:ShowMerchantHelper();assert(CP.MerchantHelper and CP.MerchantHelper:IsShown())
-- Presold stacks of 5: two purchases for 7 missing.
GetMerchantItemInfo=function(i) return "Coarse Thread",nil,50,5,-1 end
bought={}
offers=CP:MerchantOffers()
assert(offers[1].purchases==2 and offers[1].count==10 and offers[1].cost==100)
CP:BuyMerchantOffer(offers[1]);assert(#bought==2 and bought[1][2]==1)
GetMoney=function() return 50 end
CP.Say=function() end
assert(not CP:BuyMerchantOffer(offers[1]),"Not enough gold")
GetMerchantNumItems,GetMerchantItemID,GetMerchantItemInfo,GetMerchantItemMaxStack,BuyMerchantItem,GetMoney=nil,nil,nil,nil,nil,nil
stock[2320]=nil

-- Tooltips: keep warning, plan need and price limit on the item.
CP.AutoRouteShopping=function() return route end
CP.keepCache=nil;CP.tooltipCache=nil
CP.PlanRequirements=function(_,owner) return owner=="engineering" and {[70010]=6} or {},0,{} end
CP.db.view="engineering";CP.db.ui.tooltips=nil
local lines=CP:TooltipLines(70010)
assert(lines and lines[1][1]:find("Nicht verkaufen",1,true) and lines[2][1]:find("6 nötig",1,true))
local added={}
CP:AddTooltipLines({AddLine=function(_,text) added[#added+1]=text end},70010)
assert(added[1]=="CraftPilot" and #added==3)
assert(CP:TooltipLines(99999)==nil)
CP.db.ui.tooltips=false;CP.tooltipCache=nil
assert(CP:TooltipLines(70010)==nil,"Tooltips can be switched off")
CP.db.ui.tooltips=savedUI.tooltips

-- UI: the new plan pages render.
CP.db.ui.planPage="leftovers";CP:OpenTab("plan")
CP.db.ui.planPage="details";CP:Render()
CP.db.ui.planPage="crafts";CP:Render()
CP.db.ui.planPage="shopping";CP:OpenTab("now")

for name,fn in pairs(saved) do CP[name]=fn end
CP.db.plans,CP.db.recipes.engineering,CP.db.professions.engineering=savedPlans,savedRecipes,savedProf
CP.keepCache=nil;CP.tooltipCache=nil;CP.pathCache=nil
print("PASS: 0.26 keep for later, price limits, budget, leftovers, vendor helper and item tooltips")
