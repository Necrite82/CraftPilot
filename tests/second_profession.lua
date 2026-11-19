-- 1.1.0: two professions together: make intermediates with the second profession, saving and points.
local CP=...
local saved={path=CP.CheapestPath,price=CP.PriceDetails,avail=CP.ItemAvailability,mining=CP.db.professions.mining}
CP.CheapestPath=function() return {quantities={[3860]=40.2}} end
local prices={[3860]=1200,[3858]=700}
CP.PriceDetails=function(_,id) return {price=prices[id]} end
CP.ItemAvailability=function() return 0 end
CP.db.professions.mining={skill=180,cap=225}
local options=CP:SecondProfessionOptions("engineering")
assert(#options==1 and options[1].prof=="mining" and options[1].need==41 and options[1].saving==41*500,"Smelting your own bars saves 5 silver each")
assert(options[1].points>=0 and options[1].crafts==41)
assert(CP:SecondProfessionText(options[1]):find("41",1,true))
assert(#CP:SecondProfessionCards("engineering")==2)
CP.db.professions.mining={skill=100,cap=150}
assert(#CP:SecondProfessionOptions("engineering")==0,"Smelt Mithril needs mining 175")
CP.CheapestPath,CP.PriceDetails,CP.ItemAvailability,CP.db.professions.mining=saved.path,saved.price,saved.avail,saved.mining
print("PASS: 1.1.0 second profession: own intermediates with saving and points, skill requirement")
