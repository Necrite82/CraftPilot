-- 0.28: crafting from the companion, the shopping round at the auction house, first start and help.
local CP=...
local saved={missing=CP.MissingForPlans,count=CP.RawItemCount,name=CP.ItemName,search=CP.SearchItems,ah=CP.AuctionHouseOpen,say=CP.Say,
  price=CP.PriceDetails,limit=CP.PriceLimit,craft=C_TradeSkillUI.CraftRecipe,info=C_TradeSkillUI.GetRecipeInfo,rec=CP.currentCompanionRecommendation}
CP.ItemName=function(_,id) return "Item "..id end
local said={}
CP.Say=function(_,t) said[#said+1]=t end

-- Crafting: the recommended count, limited by the materials; one click, one call.
local crafted
C_TradeSkillUI.CraftRecipe=function(id,n) crafted={id,n} end
local available=3
C_TradeSkillUI.GetRecipeInfo=function() return {numAvailable=available} end
CP.currentCompanionRecommendation={key="engineering",id=3922,count=8}
assert(select(1,CP:CraftableCount(CP.currentCompanionRecommendation))==3)
assert(CP:CraftRecommendation(false) and crafted[1]==3922 and crafted[2]==3,"Limited by materials")
assert(CP:CraftRecommendation(true) and crafted[2]==1,"Single craft")
available=0;crafted=nil
assert(not CP:CraftRecommendation(false) and crafted==nil,"No call without materials")
CP.currentCompanionRecommendation={key="engineering",id=3922,count=8,learn={}}
assert(not CP:CraftRecommendation(false),"Not before learning")
C_TradeSkillUI.CraftRecipe=nil
CP.currentCompanionRecommendation={key="engineering",id=3922,count=8}
available=5
assert(not CP:CraftRecommendation(false) and said[#said]:find("nicht verfügbar",1,true),"Clear message when the client lacks crafting")

-- Shopping round: item by item, bought amounts counted from the bags, finished items skipped.
local bags={[2840]=0,[2589]=0}
CP.RawItemCount=function(_,id) return bags[id] or 0 end
CP.MissingForPlans=function() return {[2589]=10,[2840]=4} end
local searches={}
CP.SearchItems=function(_,items) searches[#searches+1]=items[1];return true end
CP.AuctionHouseOpen=function() return true end
CP.PriceDetails=function() return {price=100} end
CP.PriceLimit=function(_,_,id) return id==2589 and {price=120} or nil end
assert(CP:StartShoppingRound() and CP.shopRound.index==1)
assert(searches[1].id==2589 and searches[1].quantity==10,"Sorted by name: Item 2589 first")
assert(CP.RoundPanel:IsShown() and CP.RoundPanel.item.displayText:find("Noch 10",1,true))
assert(CP.RoundPanel.info.displayText:find("lohnt sich bis",1,true))
bags[2589]=6;CP:CheckRound()
assert(CP.shopRound.index==1 and CP.RoundPanel.item.displayText:find("Noch 4",1,true))
bags[2589]=10;CP:CheckRound()
assert(CP.shopRound.index==2 and searches[#searches].id==2840,"Bought up: on to the next item")
CP:AdvanceRound(-1);assert(CP.shopRound.index==1)
bags[2840]=4;CP:AdvanceRound(1)
assert(CP.shopRound==nil and said[#said]:find("fertig",1,true),"Everything bought: round finished")
CP:ShowRoundPanel()
assert(CP.RoundPanel.start:IsShown(),"Offers a new round while materials are missing")
CP.MissingForPlans=function() return {} end
assert(not CP:StartShoppingRound())

-- First start: the help with a welcome card; "Los geht's" marks it seen.
local savedFirst=CP.db.ui.firstRunDone
CP.db.ui.firstRunDone=nil
if CP.frame:IsShown() then CP.frame:Hide() end
CP:ToggleWindow()
assert(CP.db.ui.tab=="help" and CP.db.ui.firstRunDone==false)
local welcome=CP:HelpCards()[1]
assert(welcome.title:find("Willkommen",1,true) and welcome.action)
welcome.action()
assert(CP.db.ui.firstRunDone==true and CP.db.ui.tab=="now")
assert(not CP:HelpCards()[1].title:find("Willkommen",1,true))
CP.db.ui.firstRunDone=savedFirst==nil and true or savedFirst

CP.MissingForPlans,CP.RawItemCount,CP.ItemName,CP.SearchItems,CP.AuctionHouseOpen,CP.Say=saved.missing,saved.count,saved.name,saved.search,saved.ah,saved.say
CP.PriceDetails,CP.PriceLimit,C_TradeSkillUI.CraftRecipe,C_TradeSkillUI.GetRecipeInfo=saved.price,saved.limit,saved.craft,saved.info
CP.currentCompanionRecommendation=saved.rec;CP.shopRound=nil
print("PASS: 0.28 crafting from the companion, shopping round, first start with help")
