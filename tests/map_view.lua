-- 1.4.0: map window points, rank books/quests of the secondary professions, trainer page and tour on the map.
local CP=...
local saved=CP.db.professions.cooking
local savedFaction=UnitFactionGroup
UnitFactionGroup=function() return "Alliance" end
CP.db.professions.cooking={skill=140,cap=150}
assert(CP.MapOverlays and CP.MapOverlays.maps[1411],"map pieces loaded")
-- Expert cooking: book from Shandrina (Alliance), not from Wulan (Horde)
local entries,rank,recommended=CP:TrainerChoices("cooking")
assert(rank.cap==225 and recommended and recommended.name=="Shandrina" and recommended.how=="book","Expert cookbook vendor recommended")
for _,e in ipairs(entries) do assert(e.npc.name~="Wulan","Horde vendor hidden for Alliance") end
local gate=CP:RankGate("cooking")
assert(gate.how and gate.text:find(gate.how,1,true),"rank gate says how to learn")
local points=CP:TrainerMapPoints("cooking")
local book,trainer
for _,p in ipairs(points) do if p.kind=="book" then book=p end;if p.kind=="trainer" then trainer=p end end
assert(book and book.map==1440 and book.location.name=="Shandrina","book vendor on the map")
assert(trainer,"usual trainers on the map too")
-- Artisan: needs 225, quest for first aid
CP.db.professions.cooking={skill=225,cap=225}
local artisan=CP:NextRank("cooking");assert(artisan.cap==300 and artisan.min==225)
assert(CP:RankSources("cooking")[1].name=="Dirge Quikcleave")
local savedAid=CP.db.professions.firstaid
CP.db.professions.firstaid={skill=225,cap=225}
local quest=CP:RankSources("firstaid")
assert(quest[1].how=="quest" and CP:RankQuestName(quest[1])=="Triage")
CP.db.professions.firstaid=savedAid
-- the window: points without a place are left out, a click sets the waypoint
local ok,n=CP:ShowMap("Test",{{map=1453,x=.5,y=.5,kind="vendor",title="A",location={name="A",zone="Z",map=1453,x=.5,y=.5}},{kind="vendor",title="ohne Ort"}})
assert(ok and n==1,"only points with a place")
assert(not CP:ShowMap("Leer",{}),"empty map says so instead of opening")
-- tour stops numbered
local stops={{kind="vendor",name="V",location={name="V",zone="Z",map=1453,x=.4,y=.4},recipes={{name="R1"},{name="R2"}}}}
local sp=CP:StopMapPoints(stops)
assert(#sp==1 and sp[1].label=="1" and sp[1].sub:find("R1",1,true))
assert(type(CP:CollectionMapPoints("cooking"))=="table" and type(CP:VendorMapPoints("cooking"))=="table")
-- 1.4.4: a merchant recipe card opens the map with all its vendors
local browse=CP:VendorRecipeBrowseOptions("cooking","","skill")
local many
for _,e in ipairs(browse) do if #e.vendors>1 then many=e;break end end
assert(many,"a cooking recipe sold by several vendors")
local shownTitle,shownPoints
local realShow=CP.ShowMap;CP.ShowMap=function(_,title,points) shownTitle,shownPoints=title,points;return true end
CP:ActivateRecipeRow("cooking",many)
assert(shownTitle and shownTitle:find(many.name,1,true) and #shownPoints>=1,"click on a merchant card shows its vendors on the map")
assert(CP.db.ui.selectedVendorRecipe==many.id)
CP.ShowMap=realShow;CP.db.ui.selectedVendorRecipe=nil;CP.db.ui.selectedVendorKey=nil
CP.db.professions.cooking=saved
UnitFactionGroup=savedFaction
print("PASS: 1.4.0 map: trainers, rank books and quests, vendors, tour stops; secondary professions Expert/Artisan")
