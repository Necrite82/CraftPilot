-- 0.25: learn targets and tour, rank gates, specializations, gathering, cooldowns, bank and mail helpers,
-- session balance, plan sharing, sale value and twink crafting in the cheapest path, and the new UI pages.
local CP,createdFrames=...
local saved={}
for _,name in ipairs({"CheapestPath","RecipeVendorCatalog","TrainerRecipeFee","RecipeTeachers","RecipeVendors","PriceDetails","SetWaypoint",
  "TrainerChoices","SearchItems","ItemName","CurrentCharacter","Catalog","BuildOutputIndex"}) do saved[name]=CP[name] end
local savedProf,savedRecipes,savedPlans,savedView=CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.plans,CP.db.view
local savedAccount,savedKey=CP.account,CP.characterKey
local waypointsSet={}
CP.SetWaypoint=function(_,npc) waypointsSet[#waypointsSet+1]=npc;return true end
CP.ItemName=function(_,id) return "Item "..id end

-- Learn targets: trainer first, otherwise a vendor with a location, otherwise the AH for a drop recipe.
local T,V,D=98001,98002,98003
local catalog={recipes={
  [T]={name="Trainer one",learn=50,colors={50,60,70,80},mats={[52001]=1},get={{kind="trainer",cost=100}}},
  [V]={name="Vendor one",learn=55,colors={55,60,70,80},mats={[52002]=1},get={{kind="vendor",npc=1}}},
  [D]={name="Drop one",item=52999,learn=55,colors={55,65,70,80},mats={[52003]=1},get={{kind="drop",npcs=3}}},
},npcs={}}
CP.RecipeVendorCatalog=function() return catalog end
CP.TrainerRecipeFee=function(_,_,id) if id==T then return 100,false,true end end
local trainerNpc={name="Trainer Bob",zone="Ironforge",map=1455,x=.5,y=.5}
local vendorNpc={name="Vendor Sue",zone="Loch Modan",map=1432,x=.3,y=.4}
CP.RecipeTeachers=function(_,_,id) return id==T and {{name="Trainer Bob",location=trainerNpc}} or {} end
CP.RecipeVendors=function(_,_,id) return id==V and {{name="Vendor Sue",location=vendorNpc,cost=500}} or {} end
local ahPrices={[52999]=2000}
CP.PriceDetails=function(_,id) return {price=ahPrices[id] or 10,auction=ahPrices[id],freshness="fresh",ageDays=0} end
CP.db.recipes.engineering={}
CP.db.professions.engineering={skill=55,cap=75}
assert(CP:LearnTarget("engineering",T).kind=="trainer")
assert(CP:LearnTarget("engineering",V).kind=="vendor" and CP:LearnTarget("engineering",V).location==vendorNpc)
local drop=CP:LearnTarget("engineering",D)
assert(drop.kind=="ah" and drop.cost==2000 and drop.item==52999)
assert(CP:LearnTargetLabel(CP:LearnTarget("engineering",T))=="Weg zum Lehrer")
assert(CP:GoLearn("engineering",V) and waypointsSet[#waypointsSet]==vendorNpc)
local searched
CP.SearchItems=function(_,items) searched=items;return true end
assert(CP:GoLearn("engineering",D) and searched[1].id==52999,"A drop recipe is searched at the AH")
CP.db.recipes.engineering[T]={learned=true}
assert(CP:LearnTarget("engineering",T)==nil,"Learned recipes need no way")
CP.db.recipes.engineering[T]=nil

-- Learning tour: grouped by place, trainer first; a learned stop moves the tour on.
CP.CheapestPath=function() return {segments={
  {id=V,name="Vendor one",first=55,last=60,learned=false},
  {id=T,name="Trainer one",first=60,last=65,learned=false},
  {id=D,name="Drop one",first=65,last=75,learned=false}}} end
local stops=CP:LearnTourStops("engineering")
assert(#stops==3 and stops[1].kind=="trainer" and stops[2].kind=="vendor" and stops[3].kind=="ah")
waypointsSet={}
assert(CP:StartLearnTour("engineering") and waypointsSet[1]==trainerNpc and CP.tour.index==1)
CP.db.recipes.engineering[T]={learned=true}
CP:CheckLearnTour()
assert(CP.tour.index==2 and waypointsSet[2]==vendorNpc,"Learning at the trainer moves on to the vendor")
local tourCards=CP:LearnTourCards("engineering")
assert(tourCards[1].title:find("Halt 2 von",1,true))
CP.tour=nil;CP.db.recipes.engineering={}

-- Rank gates: level 40 in the test client; Artisan needs 35, so a low level is simulated.
local level=UnitLevel
UnitLevel=function() return 14 end
CP.db.professions.engineering={skill=145,cap=150}
local gate=CP:RankGate("engineering")
assert(gate and gate.cap==225 and not gate.levelOk and gate.text:find("20",1,true),"Expert needs level 20")
assert(CP:RankGateWarning("engineering",200) and not CP:RankGateWarning("engineering",150))
UnitLevel=level
assert(CP:RankGate("engineering").ok)

-- Specializations from the bundled Craft Ladder data.
CP.Catalog=saved.Catalog
CP.db.professions.engineering={skill=210,cap=225}
local specs=CP:Specializations("engineering")
assert(specs and #specs==2 and specs[1].ready and specs[1].current==1 and specs[1].where,"Gnomish step 1 with a quest giver")
local specCards=CP:SpecCards("engineering")
assert(#specCards==3 and specCards[2].action)
waypointsSet={};specCards[2].action();assert(waypointsSet[1] and waypointsSet[1].map)
assert(CP:SpecHint("engineering"),"A spec hint near the required skill")
assert(CP:Specializations("tailoring")==nil and #CP:SpecCards("tailoring")==1)

-- Gathering: zones from the generated data, gatherers on the account.
local copper=CP:GatherInfo(2770)
assert(copper and copper.prof=="mining" and copper.skill==1 and #copper.zones>=3)
local savedMining=CP.db.professions.mining
CP.db.professions.mining={skill=80,cap=150}
local owns=CP.OwnsProfession;CP.OwnsProfession=function(_,k) return k=="mining" or k=="engineering" end
local hint=CP:GatherHint(2770)
assert(hint and hint:find("du",1,true),"This character can mine copper")
local farm=CP:FarmCards({{id=2770,missing=20,cost=4000},{id=52001,missing=3,cost=30}})
assert(#farm==2 and farm[1].sectionHeader and farm[2].tooltipItem==2770,"Only gatherable materials")
CP.OwnsProfession=owns;CP.db.professions.mining=savedMining

-- Account fixtures: this character and a twink on the same realm and faction.
local clock=1000000
local savedTime=time;time=function() return clock end
local me={name="Main",realm="R",faction="Alliance",bags={},bank={}}
local twink={name="Twink",realm="R",faction="Alliance",bags={},bank={},professions={mining={skill=150,cap=150}},needs={[2840]=10}}
CP.account={characters={["Main-R"]=me,["Twink-R"]=twink}};CP.characterKey="Main-R"
CP.CurrentCharacter=function() return me end

-- Cooldowns: catalog cooldown recipes, time left from the client.
catalog.recipes[98010]={name="Mooncloth",cooldown=82800,mats={}}
CP.db.recipes.engineering={[98010]={name="Mooncloth",learned=true}}
local savedTS=C_TradeSkillUI.GetRecipeCooldown
C_TradeSkillUI.GetRecipeCooldown=function() return 3600 end
CP:SnapshotCooldowns("engineering")
local cds=CP:CooldownList()
assert(#cds==1 and not cds[1].ready and cds[1].left==3600)
assert(CP:FormatDuration(3600):find("1 Std",1,true))
clock=clock+3601
assert(CP:CooldownList()[1].ready and CP:ReadyCooldownText():find("Mooncloth",1,true))
C_TradeSkillUI.GetRecipeCooldown=savedTS

-- Mail: inbox items are stored; the mailbox suggests what a twink still needs.
GetInboxNumItems=function() return 1 end
GetInboxItem=function(i,j) if j==1 then return "Copper Bar",2840,nil,5 end end
CP:SnapshotMail()
assert(me.mail[2840]==5)
local prepared
SendMailNameEditBox={SetText=function(_,v) prepared=v end}
local savedCount=CP.RawItemCount;CP.RawItemCount=function(_,id,bank) return id==2840 and 7 or 0 end
local mailing=CP:MailForTwinks()
assert(#mailing==1 and mailing[1].name=="Twink" and mailing[1].items[1].count==7)
CP:ShowMailHelper();assert(CP.MailHelper and CP.MailHelper:IsShown())
assert(CP:PrepareMail("Twink",mailing[1].items) and prepared=="Twink")
GetInboxNumItems,GetInboxItem,SendMailNameEditBox=nil,nil,nil

-- Bank: take what the plans need and the bags lack.
local savedReq,savedBank=CP.PlanRequirements,CP.BankCount
CP.PlanRequirements=function(_,owner) return owner=="engineering" and {[2840]=10} or {} end
CP.BankCount=function(_,id) return id==2840 and 6 or 0,true,true end
CP.db.plans={engineering={start=1,target=10,crafts={}}}
local pickups=CP:BankPickups()
assert(#pickups==1 and pickups[1].count==3,"10 needed, 7 in bags, 3 from the bank")
CP:ShowBankHelper();assert(CP.BankHelper and CP.BankHelper:IsShown())
CP:SnapshotNeeds();assert(me.needs[2840]==nil,"Bags and bank cover the plan")
CP.PlanRequirements,CP.BankCount,CP.RawItemCount=savedReq,savedBank,savedCount

-- Session balance: money spent while the auction house is open, points against the path's average.
local money=10000
GetMoney=function() return money end
CP:StartSession()
CP.CheapestPath=function() return {from=210,reached=220,total=1000,segments={}} end
AuctionHouseFrame={IsShown=function() return true end}
money=9000;CP:TrackMoney()
AuctionHouseFrame=nil
money=8000;CP:TrackMoney()
CP.db.professions.engineering.skill=215
local balance=CP:SessionBalance("engineering")
assert(balance.gained==5 and balance.spent==1000 and balance.expected==500,"Only AH spending counts")
assert(CP:SessionText("engineering"):find("+5",1,true))
GetMoney=nil;CP.session=nil

-- Plan sharing: export and import round trip.
CP.db.plans={engineering={start=10,target=20,crafts={[3922]=4,[3923]=2}}}
local exported=CP:ExportPlan("engineering")
assert(exported=="CP1;engineering;10;20;3922=4,3923=2")
CP.db.plans.engineering=nil
local ok,key,n=CP:ImportPlan(" "..exported.." ")
assert(ok and key=="engineering" and n==2 and CP.db.plans.engineering.crafts[3922]==4)
assert(not CP:ImportPlan("hello"))
assert(CP:OpenShareWindow("engineering","export") and CP.shareWindow:IsShown())

-- Cheapest path: sale value lowers a recipe's cost; a twink making a material cheaper is noted.
CP.CheapestPath=saved.CheapestPath
CP.CurrentCharacter=function() return me end
local S1,S2=98101,98102
catalog.recipes={
  [S1]={name="Sells well",learn=1,colors={1,40,50,60},makes=52101,mats={[52011]=1}},
  [S2]={name="Sells badly",learn=1,colors={1,40,50,60},makes=52102,mats={[52012]=1}},
}
ahPrices={[52011]=100,[52012]=90,[52101]=200}
CP.db.recipes.engineering={[S1]={name="Sells well",learned=true,snapshotSkill=10,difficulty=0},[S2]={name="Sells badly",learned=true,snapshotSkill=10,difficulty=0}}
CP.db.professions.engineering={skill=10,cap=20}
CP.db.ui.countSales=false;CP.pathCache=nil
assert(CP:CheapestPath("engineering").segments[1].id==S2,"Without sales the cheaper craft wins")
CP.db.ui.countSales=true;CP.pathCache=nil
local withSales=CP:CheapestPath("engineering")
assert(withSales.segments[1].id==S1,"The sale of the product pays for the dearer craft")
CP.db.ui.countSales=false;CP.pathCache=nil
-- Twink crafting: the twink's mining makes material 52011 from 52020 at 30 instead of 100.
CP.BuildOutputIndex=function() return {[52011]={{key="mining",id=98200,recipe={learn=1,mats={[52020]=1},makes=52011}}}} end
ahPrices[52020]=30
CP.db.ui.includeAlts=true
twink.learned={mining={[98200]=true}}
local twinkPath=CP:CheapestPath("engineering")
assert(twinkPath.segments[1].id==S1 and #twinkPath.altCrafts==1 and twinkPath.altCrafts[1].alt=="Twink" and twinkPath.altCrafts[1].sure,
  "The twink's smelting makes the first recipe cheapest")
local lines=CP:PathSummaryLines(twinkPath)
local mentions=false;for _,l in ipairs(lines) do if l:find("Twink",1,true) then mentions=true end end
assert(mentions)
twink.learned={mining={}};CP.pathCache=nil
assert(#CP:CheapestPath("engineering").altCrafts==0,"A twink without the recipe does not count")
CP.BuildOutputIndex=saved.BuildOutputIndex;CP.pathCache=nil

-- UI: the Twinks tab, the learning tour and specialization pages render; unlearned rows get a map button.
CP.db.view="engineering";CP.db.professions.engineering={skill=210,cap=225}
CP:OpenTab("twinks");assert(CP.db.ui.tab=="twinks")
local twinkCards=CP:TwinkCards("engineering")
local hasCooldown,hasChar=false,false
for _,c in ipairs(twinkCards) do if c.title=="COOLDOWNS" then hasCooldown=true end if c.title=="CHARAKTERE" then hasChar=true end end
assert(hasCooldown and hasChar)
CP.db.ui.trainerPage="spec";CP.db.ui.vendorBrowser=false;CP:OpenTab("trainers")
CP.db.ui.trainerPage="tour";CP:Render()
CP.db.ui.trainerPage=nil
CP:OpenTab("now")

for name,fn in pairs(saved) do CP[name]=fn end
time=savedTime
CP.account,CP.characterKey=savedAccount,savedKey
CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.plans,CP.db.view=savedProf,savedRecipes,savedPlans,savedView
CP.pathCache=nil
print("PASS: 0.25 learn ways and tour, rank gates, specializations, gathering, cooldowns, bank/mail helpers, session, sharing, sales and twink crafting")
