-- 1.2.0: item database: uses, producers, chain, search, verdict, buildable, watchlist, planning, pages.
local CP=...
local saved={recipes=CP.db.recipes.engineering,eng=CP.db.professions.engineering,mining=CP.db.professions.mining,avail=CP.ItemAvailability,
  price=CP.PriceDetails,path=CP.CheapestPath,watch=CP.db.itemWatch,page=CP.db.ui.itemPage,sel=CP.db.ui.itemSelected,q=CP.db.ui.itemQuery,tab=CP.db.ui.tab,
  drops=CP.QuestieItemDrops,raw=CP.RawStock}
CP:ResetItemIndex()
local uses=CP:ItemUses(3860)
assert(#uses>5,"Mithril bars are used in many recipes")
local profs={};for _,u in ipairs(uses) do profs[u.key]=true end
assert(profs.engineering and profs.blacksmithing,"across professions")
assert(#CP:ItemProducers(3860)>=1,"made by smelting")
local down,up=CP:ItemChain(3860)
assert(down[1]==3858,"Chain starts at Mithril Ore")
assert(CP:ItemChainText(3860))
-- Search by name
local results=CP:SearchItems_DB(CP:ItemName(3860))
assert(results[1] and results[1].id==3860,"Exact name first")
assert(#CP:SearchItems_DB("x")==0,"Two letters minimum")
-- Verdict
CP.CheapestPath=function() return {quantities={[3860]=10}} end
CP.db.professions.engineering={skill=200,cap=225}
local v=CP:ItemVerdict(3860)
assert(v and v:find("Behalten",1,true),"On the path: keep")
CP.CheapestPath=function() return {quantities={}} end
CP.db.professions.engineering=nil
CP.PriceDetails=function() return {auction=900,price=900} end
local own=CP.db.professions
local stash={};for k,val in pairs(own) do stash[k]=val;own[k]=nil end
v=CP:ItemVerdict(3860)
assert(v and v:find("andere Berufe",1,true),"No own profession: only for others with AH price")
for k,val in pairs(stash) do own[k]=val end
-- Buildable now
CP.db.professions.engineering={skill=200,cap=225}
CP.db.recipes.engineering={[12594]={learned=true}}
CP.RawStock=function() return 50 end
local b=CP:BuildableNow()
local found;for _,x in ipairs(b) do if x.key=="engineering" and x.id==12594 then found=x end end
assert(found and found.runs>0,"A learned recipe with all materials on hand is buildable")
assert(#CP:BuildableCards()>1)
-- Watchlist, alarms and drop lines
CP.db.itemWatch=nil
assert(CP:ToggleWatch(3860)==true and CP:IsWatched(3860))
CP.PriceDetails=function() return {auction=900,price=900,ageDays=0} end
local alarms=CP:WatchAlarms()
assert(#alarms==1 and alarms[1].kind=="watch")
CP.QuestieItemDrops=function(_,item) return item==3860 and {{id=777,name="Boss"}} or {} end
CP.watchDropIndex=nil
assert(CP:WatchUnitLines(777)[1]:find(CP:ItemName(3860),1,true))
assert(#CP:WatchCards()==1)
assert(CP:ToggleWatch(3860)==false)
-- Detail cards: own unlearned recipe gets a learn source line
local cards=CP:ItemDetailCards(3860)
assert(#cards>5 and cards[1].title==CP:ItemName(3860))
local unlearned;for _,c in ipairs(cards) do if c.footer and c.footer:find("Noch nicht gelernt",1,true) then unlearned=c end end
assert(unlearned,"Own profession recipe not learned yet shows where to learn it")
-- Pages and opening
CP.db.ui.itemPage="search";CP.db.ui.itemSelected=nil;CP.db.ui.itemQuery="mi"
assert(#CP:ItemDBCards()>0)
assert(CP:OpenItemInDB(3860) and CP.db.ui.tab=="items" and CP.db.ui.itemSelected==3860)
CP:Render()
CP.db.recipes.engineering,CP.db.professions.engineering,CP.db.professions.mining,CP.ItemAvailability,CP.PriceDetails,CP.CheapestPath=saved.recipes,saved.eng,saved.mining,saved.avail,saved.price,saved.path
CP.db.itemWatch,CP.db.ui.itemPage,CP.db.ui.itemSelected,CP.db.ui.itemQuery,CP.db.ui.tab,CP.QuestieItemDrops,CP.RawStock=saved.watch,saved.page,saved.sel,saved.q,saved.tab,saved.drops,saved.raw
CP.watchDropIndex=nil
print("PASS: 1.2.0 item database: uses across professions, producers, chain, search, verdict, buildable, watchlist, pages")
