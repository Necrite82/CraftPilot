-- 1.1.0: price sources TSM and Auctioneer next to Auctionator, preferred source first, quiet fallback.
local CP=...
local saved={a=_G.Auctionator,t=_G.TSM_API,u=_G.AucAdvanced,pref=CP.db.ui.priceSource,vendor=CP.CatalogVendorPrice}
CP.CatalogVendorPrice=function() return nil end
_G.Auctionator=nil
_G.TSM_API={GetCustomPriceValue=function(str,item) assert(item=="i:2770");return 120 end}
_G.AucAdvanced={API={GetMarketValue=function() return 150 end}}
CP.db.ui.priceSource="auto"
local p=CP:PriceDetails(2770)
assert(p.price==120 and p.source=="TradeSkillMaster" and p.freshness=="unknown","TSM fills in without Auctionator")
CP.db.ui.priceSource="auctioneer"
assert(CP:PriceDetails(2770).source=="Auctioneer","Chosen source asked first")
_G.AucAdvanced={API={GetMarketValue=function() error("boom") end}}
assert(CP:PriceDetails(2770).source=="TradeSkillMaster","A failing source is skipped quietly")
_G.TSM_API={GetCustomPriceValue=function() return nil end}
assert(CP:PriceDetails(2770).price==nil,"No price anywhere")
_G.Auctionator={API={v1={GetAuctionPriceByItemID=function() return 90 end,GetAuctionAgeByItemID=function() return 1 end}}}
CP.db.ui.priceSource="auto"
p=CP:PriceDetails(2770)
assert(p.price==90 and p.source=="Auctionator" and p.freshness=="fresh")
assert(#CP:AvailablePriceSources()==3)
_G.Auctionator,_G.TSM_API,_G.AucAdvanced,CP.db.ui.priceSource,CP.CatalogVendorPrice=saved.a,saved.t,saved.u,saved.pref,saved.vendor
print("PASS: 1.1.0 price sources: TSM and Auctioneer as fallbacks, preferred source, failing source skipped")
