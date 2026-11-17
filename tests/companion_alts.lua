-- Twink stock across the account and the companion panel beside the profession window.
local CP=...
local saved={account=CraftPilotAccountDB,unitName=UnitName,realm=GetRealmName,faction=UnitFactionGroup,container=C_Container,
  bankOpen=CP.bankIsOpen,includeAlts=CP.db.ui.includeAlts,prof=CP.db.professions.engineering,recipes=CP.db.recipes.engineering,
  capture=CP.db.lastCapture,tradeFrame=TradeSkillFrame,cost=CP.CostCalculation,offers=CP.TrainerRecipeOptions,name=CP.ItemName,
  companion=CP.db.ui.companion,errors=UIErrorsFrame}
UnitName=function() return "Main" end
GetRealmName=function() return "Forever" end
UnitFactionGroup=function() return "Horde" end
CraftPilotAccountDB={characters={
  ["Twink-Forever"]={name="Twink",realm="Forever",faction="Horde",bags={[60001]=2},bank={[60001]=3}},
  ["Ally-Forever"]={name="Ally",realm="Forever",faction="Alliance",bags={[60001]=7},bank={}},
  ["Far-Other"]={name="Far",realm="Other",faction="Horde",bags={[60001]=9},bank={}},
}}
CP:InitializeAlts()
assert(CP.characterKey=="Main-Forever" and CraftPilotAccountDB.characters["Main-Forever"])
local stock=CP:AltStock(60001)
assert(#stock==3 and stock[1].name=="Twink" and stock[1].reachable and stock[1].count==5,"Mailable twinks come first")
assert(not stock[2].reachable and not stock[3].reachable,"Other faction or realm is information only")
CP.db.ui.includeAlts=true
assert(CP:AltReachable(60001)==5)
local total,bags,bank,live,known,alts=CP:ItemAvailability(60001)
assert(alts==5 and total>=5,"Reachable twink stock counts for planning")
CP.ItemName=function(_,id) return "Fixture "..id end
assert(CP:AltPickupText(60001,4)=="4 Fixture 60001 (Twink)")
CP.db.ui.includeAlts=false
assert(CP:AltReachable(60001)==0 and select(6,CP:ItemAvailability(60001))==0,"Switching twinks off removes them from planning")
CP.db.ui.includeAlts=true

-- Container scan: bags now, bank only while it is open.
C_Container={GetContainerNumSlots=function(bag) return (bag==0 or bag==-1) and 2 or 0 end,
  GetContainerItemInfo=function(bag,slot) if slot==1 then return {itemID=bag==-1 and 70002 or 70001,stackCount=4} end end}
CP:SnapshotCharacterBags()
assert(CraftPilotAccountDB.characters["Main-Forever"].bags[70001]==4)
CP.bankIsOpen=false;CP:SnapshotCharacterBank()
assert(next(CraftPilotAccountDB.characters["Main-Forever"].bank)==nil,"No bank scan without an open bank")
CP.bankIsOpen=true;CP:SnapshotCharacterBank()
assert(CraftPilotAccountDB.characters["Main-Forever"].bank[70002]==4)
CP.bankIsOpen=saved.bankOpen

-- Companion: shown beside the open profession window with crafts to the next color.
CP.TrainerRecipeOptions=function() return {} end;CP.trainerOfferCache=nil
CP.db.professions.engineering={skill=10,cap=75}
CP.db.recipes.engineering={[95101]={name="Companion step",learned=true,snapshotSkill=10,difficulty=0,mats={{60001,2}}}}
CP.db.lastCapture={key="engineering",skill=10}
CP.CostCalculation=function() return {materials={{id=60001,quantity=2,bag=0,bank=0,bankKnown=true,missing=0,used=2,alts=2}},cashComplete=true,buy=0,missingBuy=0,unknownRecipes=0} end
local hostShown=true
TradeSkillFrame={IsShown=function() return hostShown end}
local errors={}
UIErrorsFrame={AddMessage=function(_,msg) errors[#errors+1]=msg end}
CP.db.ui.companion=true
CP:UpdateCompanion()
local panel=CP.companion
assert(panel and panel:IsShown() and panel.title.displayText:find("Companion step",1,true))
assert(panel.detail.displayText:find("Twinks",1,true),"Recommendation names the twink pickup")
CP.db.recipes.engineering[95101].difficulty=1
CP:UpdateCompanion()
assert(errors[#errors] and errors[#errors]:find("Gelb",1,true),"A color change raises a notice")
CP.db.professions.engineering={skill=75,cap=75}
CP.db.lastCapture={key="engineering",skill=75}
CP:UpdateCompanion()
assert(errors[#errors]:find("Ausbildungsgrenze 75",1,true),"Reaching the training cap raises a notice")
-- Minimize, close and a remembered position.
CP.db.ui.companionCollapsed=true;CP:UpdateCompanion()
assert(panel:IsShown() and panel.height==34 and not panel.title:IsShown(),"Minimized to the header row")
panel.minimize:GetScript("OnClick")();assert(not CP.db.ui.companionCollapsed and panel.title:IsShown())
panel:SetPoint("TOPLEFT",UIParent,"TOPLEFT",300,-200);panel:GetScript("OnDragStop")()
assert(CP.db.ui.companionPos and CP.db.ui.companionPos.x==300)
CP:UpdateCompanion();assert(panel.point[2]==UIParent and panel.point[4]==300,"Saved position wins over docking")
CP.db.ui.companionPos=nil
panel.close:GetScript("OnClick")();assert(not panel:IsShown())
CP:UpdateCompanion();assert(not panel:IsShown(),"Closed until the profession window opens again")
CP.companionClosed=nil
CP.db.ui.companion=false;CP:UpdateCompanion();assert(not panel:IsShown())
CP.db.ui.companion=true;hostShown=false;CP:UpdateCompanion();assert(not panel:IsShown(),"Hidden without a profession window")

CraftPilotAccountDB,UnitName,GetRealmName,UnitFactionGroup,C_Container=saved.account,saved.unitName,saved.realm,saved.faction,saved.container
CP.db.ui.includeAlts,CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.lastCapture=saved.includeAlts,saved.prof,saved.recipes,saved.capture
TradeSkillFrame,CP.CostCalculation,CP.TrainerRecipeOptions,CP.ItemName,CP.db.ui.companion,UIErrorsFrame=saved.tradeFrame,saved.cost,saved.offers,saved.name,saved.companion,saved.errors
CP.account=nil;CP.characterKey=nil;CP.db.ui.companionCollapsed=nil;CP.db.ui.companionPos=nil;CP.trainerOfferCache=nil;CP.companionState=nil;CP.companionNotice=nil
print("PASS: twink stock (mailable vs. information only, toggle, bag and bank scans) and companion panel with color and cap notices")
