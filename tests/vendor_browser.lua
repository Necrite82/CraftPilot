local CP,frames=...
local db,provider=CP.db,CP.RecipeVendorCatalog
local oldLevel,oldSide=UnitLevel,UnitFactionGroup
local questie=CP.QuestieItemVendors
UnitLevel=function() return 5 end;UnitFactionGroup=function() return "Alliance" end
CP.QuestieItemVendors=function() return {} end
CP.db={ui={selectedRecipes={},showVendorRecipes=false,knownRecipesOnly=true},professions={engineering={skill=10,cap=10}},recipes={engineering={}},plans={},view="engineering",includeBank=false}
-- Regression from the bundled records: the Booty Bay scope exists, but tools and skill filters used to hide it.
local real=CP:VendorRecipeBrowseOptions("engineering","3979")
assert(#real==1 and real[1].recipeItem==13310 and real[1].dimmed)
assert(real[1].vendors[1].id==2685 and real[1].vendors[1].location.map==1434 and real[1].requiredSkill==180)
local total=0
for _,key in ipairs({"engineering","blacksmithing","tailoring","leatherworking","alchemy","enchanting","cooking","firstaid"}) do
 local c=CP:RecipeVendorCatalog(key);local expected=0
 for _,r in pairs(c and c.recipes or {}) do for _,s in ipairs(r.get or {}) do if s.kind=="vendor" and type(s.npc)=="number" then expected=expected+1;break end end end
 assert(#CP:VendorRecipeBrowseOptions(key)==expected,"No bundled merchant recipe may disappear because of skill, profession ownership or restrictions: "..key)
 total=total+expected
end
local catalog={recipes={
 [99201]={name="Future Scope",item=99301,learn=180,colors={180,200,210,220},tools={14,15},mats={[2840]=1},get={{kind="vendor",npc=99801,cost=2000}}},
 [99202]={name="Already learned",item=99302,learn=1,colors={1,2,3,4},get={{kind="vendor",npc=99801,cost=100}}},
 [99203]={name="Holiday currency",item=99303,learn=1,rep={1,4},spec=9,cooldown=100,get={{kind="vendor",npc=99802,event="Winter",otherCost={1,2},reqLevel=50,cost=1}}},
 [99204]={name="Other side",item=99304,learn=1,get={{kind="vendor",npc=99803,faction="H",cost=10}}},
 [99205]={name="Trainer only",learn=1,get={{kind="trainer",cost=10}}},
 [99206]={name="Unknown location",learn=20,get={{kind="vendor",npc=99804,npcName="Unknown merchant"}}}},
 npcs={[99801]={name="Fixture merchant",zone="Fixture zone",map=1434,x=28.5,y=75.1},[99802]={name="Holiday merchant"},[99803]={name="Other faction",faction="H"}}}
CP.RecipeVendorCatalog=function() return catalog end
CP.db.recipes.engineering[99202]={learned=true,name="Already learned",mats={}}
CP:InvalidateReservations()
local rows=CP:VendorRecipeBrowseOptions("engineering");assert(#rows==5)
local all=CP:AllRecipeOptions("engineering",{{id=99202}},{{id=99201}});local unique={}
assert(#all==6,"Existing learned and offer rows must not be duplicated by the complete merchant directory")
for _,r in ipairs(all) do assert(not unique[r.id],"All-recipes view must not duplicate merchant entries");unique[r.id]=true end
local byID={};for _,r in ipairs(rows) do byID[r.id]=r end
assert(byID[99201].dimmed and byID[99201].requirements:find("180",1,true))
assert(byID[99202].learned and byID[99202].status:find("erlernt",1,true))
assert(byID[99203].dimmed and byID[99203].vendors[1].cost==nil,"Special currency is not a cheap gold price")
assert(CP:VendorOfferNotes(byID[99203].vendors[1]):find("Winter",1,true))
assert(byID[99204].dimmed and CP:VendorOfferNotes(byID[99204].vendors[1]):find("Andere Fraktion",1,true))
assert(#CP:RecipeVendors("engineering",99203)==0 and #CP:RecipeVendors("engineering",99204)==0,"Browsing restrictions must not leak into actionable acquisition prices")
assert(#CP:VendorRecipeBrowseOptions("engineering","fixture zone")==2)
assert(#CP:VendorRecipeBrowseOptions("engineering","unknown merchant")==1)
assert(#CP:VendorRecipeBrowseOptions("engineering","99301")==1)
assert(#CP:VendorRecipeBrowseOptions("engineering","%[does not exist")==0,"Search treats punctuation literally")
CP.db.professions.engineering=nil;assert(#CP:VendorRecipeBrowseOptions("engineering")==5)
CP.db.professions.engineering={skill=300,cap=300};assert(#CP:VendorRecipeBrowseOptions("engineering")==5)
CP.db.professions.engineering={skill=10,cap=75}
CP.db.ui.vendorBrowser=true;CP.db.ui.vendorQuery="Future Scope";CP:OpenTab("now")
local card,manual,proposal
for _,f in ipairs(frames) do local r=rawget(f,"craftRecipe");if r and r.id==99201 and f:IsShown() then card=f end end
assert(card and card.alpha==.5 and card.merchantLocation.displayText:find("Fixture merchant",1,true))
local oldWaypoint=CP.SetWaypoint;local target
CP.SetWaypoint=function(_,where) target=where end
card.merchantWaypoint:GetScript("OnClick")();assert(target.map==1434 and target.x==.285)
card:GetScript("OnClick")();assert(CP.db.ui.selectedVendorRecipe==99201,"Future recipe remains clickable to reveal all vendors")
CP.SetWaypoint=oldWaypoint
-- Switching back must restore recycled normal cards and keep custom purchases below the proposal.
CP.db.ui.vendorBrowser=false;CP.db.ui.vendorQuery=nil;CP.db.ui.allRecipes=false
CP:OpenTab("plan")
for _,f in ipairs(frames) do
 if rawget(f,"displayText")=="Manuelle Einkaufsliste" and f:IsShown() and f.point and f.point[1]=="BOTTOMRIGHT" then manual=f end
 if rawget(f,"displayText")=="Einkaufsvorschlag" and f:IsShown() then proposal=f end
end
assert(manual and proposal and proposal.point[5]==-286,"Manual list is a secondary footer action; the automatic proposal is the primary plan page")
for _,page in ipairs({"shopping","crafts","details"}) do for _,c in ipairs(CP:PlanPageCards("engineering",page)) do assert(not (c.title or ""):find("Manuelle Einkaufsliste",1,true)) end end
CP:LayoutRecipeCard(card,"engineering",{id=99201,chance=0,referenceOnly=true},650)
assert(card.rangeLabel:IsShown() and card.stockSummary:IsShown() and not card.merchantWaypoint:IsShown(),"Returning from browsing restores normal-card fields")
CP.db,CP.RecipeVendorCatalog,UnitLevel,UnitFactionGroup,CP.QuestieItemVendors=db,provider,oldLevel,oldSide,questie
CP.marketUseCache=nil;CP:InvalidateReservations()
print("PASS: all "..total.." bundled merchant recipes, Booty Bay scope, future/capped/learned/restricted browsing, search, waypoints and secondary manual-list placement")
