-- 1.1.0: own gathering pace and farm-or-buy.
local CP=...
local saved={items=CP.GatheringItems,rate=(CP.account or CP.db).farmRate,price=CP.PriceDetails,zone=CP.ZoneName,last=CP.lastGatherAt,
  self1=_G.LOOT_ITEM_SELF,selfm=_G.LOOT_ITEM_SELF_MULTIPLE}
CP.GatheringItems={[3858]="mining"}
;(CP.account or CP.db).farmRate=nil;CP.lastGatherAt=nil
CP.ZoneName=function() return "Arathi" end
CP.PriceDetails=function() return {price=500} end
for i=0,20 do CP:RecordGather(3858,2,1417,1000+i*60) end      -- 42 ore in 20 minutes
CP:RecordGather(3858,2,1417,1000+20*60+3600)                  -- after a break: no time counted
assert(not CP:RecordGather(2589,1,1417,9999),"Only gathering items")
local pace=CP:FarmPace(3858)
assert(pace and pace.map==1417 and math.floor(pace.perHour+.5)==132,"44 ore over 20 measured minutes")
local text,f=CP:FarmOrBuyText(3858,66)
assert(f.minutes==30 and f.buy==33000 and f.perHour==66000 and text:find("Arathi",1,true))
_G.LOOT_ITEM_SELF="You receive loot: %s.";_G.LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
local id,n=CP:ParseOwnLoot("You receive loot: |cffffffff|Hitem:3858::::::::60:::::|h[Mithril Ore]|h|rx3.")
assert(id==3858 and n==3,"Own loot with count")
assert(CP:ParseOwnLoot("Bob receives loot: |Hitem:3858|h[Mithril Ore]|h.")==nil,"Other players' loot ignored")
CP.GatheringItems,CP.PriceDetails,CP.ZoneName,CP.lastGatherAt=saved.items,saved.price,saved.zone,saved.last
;(CP.account or CP.db).farmRate=saved.rate
_G.LOOT_ITEM_SELF,_G.LOOT_ITEM_SELF_MULTIPLE=saved.self1,saved.selfm
print("PASS: 1.1.0 own gathering pace, breaks not counted, farm or buy, own loot parsing")
