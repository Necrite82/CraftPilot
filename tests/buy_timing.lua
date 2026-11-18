-- 1.1.0: buy timing from the own daily price notes against what the path still needs.
local CP=...
local saved={path=CP.CheapestPath,price=CP.PriceDetails,avail=CP.ItemAvailability,time=_G.time,trend=(CP.account or CP.db).priceTrend}
local clock=100*86400
_G.time=function() return clock end
local prices={[3860]=1000}
CP.PriceDetails=function(_,id) return {auction=prices[id],price=prices[id],source="Auctionator"} end
CP.ItemAvailability=function() return 10 end
CP.CheapestPath=function() return {quantities={[3860]=70.4}} end
;(CP.account or CP.db).priceTrend=nil
for day=96,99 do clock=day*86400;CP:RecordPrice(3860,1000) end
clock=100*86400
prices[3860]=600
local deals=CP:BuyTimingDeals("engineering")
assert(#deals==1 and deals[1].need==61 and deals[1].percent==40 and deals[1].saving==61*400,"40 % below usual, 61 still to buy")
assert(CP:BuyTimingText(deals[1]):find("40",1,true))
assert(#CP:BuyTimingCards("engineering")==2)
prices[3860]=900
assert(#CP:BuyTimingDeals("engineering")==0,"10 % below is no deal")
CP:RecordPrice(3860,700);CP:RecordPrice(3860,800)
local s=(CP.account or CP.db).priceTrend
local realmStore;for _,v in pairs(s) do realmStore=v end
assert(realmStore[3860][100]==600,"Lowest price of the day is kept")
clock=120*86400;CP:RecordPrice(3860,500)
assert(realmStore[3860][96]==nil,"Older than two weeks dropped")
CP.CheapestPath,CP.PriceDetails,CP.ItemAvailability,_G.time=saved.path,saved.price,saved.avail,saved.time
;(CP.account or CP.db).priceTrend=saved.trend
print("PASS: 1.1.0 buy timing: daily lowest price, usual price, deals for what the path still needs")
