-- 1.3.0: scan detection for price sources without their own age (TSM, Auctioneer) and "Automatisch" by newest data.
local CP=...
local saved={tsm=_G.TSM_API,auc=_G.Auctionator,acc=(CP.account or CP.db).priceSeen,store=CP.priceSeenStore,order=CP.priceOrderCache,
  sample=CP.PriceSampleItems,src=CP.db.ui.priceSource,upd=CP.OnPriceDataUpdated,time=_G.time,ahu=CP.db.auctionatorUpdated}
local clock=1000000
_G.time=function() return clock end
local root=CP.account or CP.db;root.priceSeen=nil;CP.priceSeenStore=nil;CP.priceOrderCache=nil;CP.db.auctionatorUpdated=nil
local tsm={}
for i=1,10 do tsm[i]=100*i end
_G.TSM_API={GetCustomPriceValue=function(_,s) return tsm[tonumber(s:match("%d+"))] end}
_G.Auctionator={API={v1={GetAuctionPriceByItemID=function(_,id) return id==1 and 50 or nil end,GetAuctionAgeByItemID=function() return 9 end}},SavedState={TimeOfLastGetAllScan=clock-9*86400}}
CP.PriceSampleItems=function() return {1,2,3,4,5,6,7,8,9,10} end
local fired;CP.OnPriceDataUpdated=function(_,k) fired=k end
CP.db.ui.priceSource="auto"
-- first look: snapshot only, no scan claimed
assert(#CP:DetectPriceScans()==0 and CP:EstimatedPriceAge("tsm",2)==nil)
-- a single changed price: only that item is fresh
clock=clock+3600;tsm[2]=150
assert(CP:CheckPriceScans()[1]=="tsm" and fired=="tsm")
assert(CP:EstimatedPriceAge("tsm",2)==0 and CP:EstimatedPriceAge("tsm",3)==nil)
-- many changes: a full scan, every item fresh
clock=clock+86400*2
for i=1,10 do tsm[i]=tsm[i]+1 end
CP:DetectPriceScans()
assert(CP:EstimatedPriceAge("tsm",3)==0)
-- TSM has newer data than Auctionator's 9-day-old scan: automatic asks TSM first, with an estimated age
CP.priceOrderCache=nil
assert(CP:ActivePriceSource().key=="tsm")
local p=CP:PriceDetails(1)
assert(p.provider=="TradeSkillMaster" and p.ageDays==0 and p.ageEstimated,"TSM price with estimated age")
-- a chosen source still comes first
CP.db.ui.priceSource="auctionator"
p=CP:PriceDetails(1)
assert(p.provider=="Auctionator" and p.ageDays==9 and not p.ageEstimated)
_G.TSM_API,_G.Auctionator,root.priceSeen,CP.priceSeenStore,CP.priceOrderCache,CP.PriceSampleItems,CP.db.ui.priceSource,CP.OnPriceDataUpdated,_G.time,CP.db.auctionatorUpdated=
  saved.tsm,saved.auc,saved.acc,saved.store,saved.order,saved.sample,saved.src,saved.upd,saved.time,saved.ahu
print("PASS: 1.3.0 price scan detection: TSM/Auctioneer age estimated, automatic picks the newest data")
