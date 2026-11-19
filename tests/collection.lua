-- 1.3.0: recipe collection: progress, missing with sources, filters, zone tour.
local CP=...
local saved={rec=CP.db.recipes.engineering,zone=CP.CurrentZoneName,goto_=CP.RecipeGoTo,way=CP.SetWaypoint,f=CP.db.ui.collectFilter,z=CP.db.ui.collectZone,tour=CP.tour}
CP.db.recipes.engineering={}
local c=CP:RecipeCollection("engineering")
assert(c.total>50 and c.learned>0 and #c.missing>0 and c.learned+#c.missing==c.total,"Start recipes count as learned, the rest is missing")
local kinds={}
for _,row in ipairs(c.missing) do for k in pairs(row.kinds) do kinds[k]=true end end
assert(kinds.trainer and kinds.vendor,"Sources classified")
-- learning one moves it out of missing
local first=c.missing[1].id
CP.db.recipes.engineering={[first]={learned=true}}
assert(CP:RecipeCollection("engineering").learned==c.learned+1)
-- filter and cards
CP.db.ui.collectFilter="vendor";CP.db.ui.collectZone=false
local cards=CP:CollectionCards("engineering")
assert(cards[1].title:find("Sammlung",1,true))
-- zone tour
CP.CurrentZoneName=function() return "Tanaris" end
CP.RecipeGoTo=function(_,_,id) return {label="Vendor",kind="vendor",location={name="Vendor",zone="Tanaris",map=1,x=.5,y=.5}} end
local waypoint;CP.SetWaypoint=function(_,loc) waypoint=loc;return true end
local stops=CP:CollectionZoneStops("engineering")
assert(#stops==1 and #stops[1].recipes>0,"One place in Tanaris")
assert(CP:StartCollectionTour("engineering") and CP.tour.collection and waypoint and waypoint.zone=="Tanaris")
CP.db.recipes.engineering,CP.CurrentZoneName,CP.RecipeGoTo,CP.SetWaypoint,CP.db.ui.collectFilter,CP.db.ui.collectZone,CP.tour=saved.rec,saved.zone,saved.goto_,saved.way,saved.f,saved.z,saved.tour
print("PASS: 1.3.0 recipe collection: progress, sources, filters, zone tour; wishlist part of it")
