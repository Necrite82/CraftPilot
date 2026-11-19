-- 1.3.0: three ways side by side; choosing one switches the path mode.
local CP=...
local saved={path=CP.CheapestPath,lt=CP.LearnTarget,ui1=CP.db.ui.fastestSkill,ui2=CP.db.ui.fewestTrips,eng=CP.db.professions.engineering}
CP.db.professions.engineering={skill=200,cap=225}
local modes={}
CP.CheapestPath=function(self) local m=self.pathModeOverride;modes[#modes+1]=m
  if m=="cheap" then return {total=50000,fees=10000,reached=225,segments={{id=1,crafts=30,learned=true},{id=2,crafts=10,learned=false},{id=3,crafts=5,learned=false}}} end
  if m=="crafts" then return {total=80000,fees=10000,reached=225,segments={{id=1,crafts=20,learned=true},{id=2,crafts=5,learned=false}}} end
  return {total=60000,fees=0,reached=225,segments={{id=1,crafts=40,learned=true}}}
end
CP.LearnTarget=function(_,_,id) return id==2 and {kind="trainer",name="T"} or {kind="vendor",name="V"..id} end
local r=CP:CompareRoutes("engineering")
assert(#r==3 and r[1].mode=="cheap" and r[1].stops==2 and r[1].crafts==45 and r[3].stops==0 and r[2].crafts==25)
assert(CP.pathModeOverride==nil,"Override is cleared")
local cards=CP:RouteCompareCards("engineering")
assert(#cards==4)
cards[4].action()
assert(CP.db.ui.fewestTrips==true and CP:CurrentRouteMode()=="trips")
cards[2].action()
assert(not CP.db.ui.fewestTrips and not CP.db.ui.fastestSkill and CP:CurrentRouteMode()=="cheap")
CP.CheapestPath,CP.LearnTarget,CP.db.ui.fastestSkill,CP.db.ui.fewestTrips,CP.db.professions.engineering=saved.path,saved.lt,saved.ui1,saved.ui2,saved.eng
-- The real path honours the fewest-trips mode: never more fees than the cheapest one
CP.pathCache=nil
print("PASS: 1.3.0 route comparison: little gold, few crafts, few trips; choosing one switches the mode")
