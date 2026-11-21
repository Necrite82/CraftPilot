-- Recommendation banner, list cost column and Auctionator search for the missing materials.
local CP=...
local saved={prof=CP.db.professions.engineering,recipes=CP.db.recipes.engineering,capture=CP.db.lastCapture,view=CP.db.view,
  say=CP.Say,name=CP.ItemName,auctionator=Auctionator,ahFrame=AuctionHouseFrame,offers=CP.TrainerRecipeOptions,cost=CP.CostCalculation}
local said={}
CP.Say=function(_,msg) said[#said+1]=msg end

-- Cost column: per point incl. training, stock, unknown, reference and vendor rows.
assert(CP:ListCostText({referenceOnly=true})=="—")
assert(CP:ListCostText({vendorRecipe=true,recipeCost=5000})=="—")
assert(CP:ListCostText({cost=0,missing=0})=="vorrätig","A recipe fully in stock costs nothing extra")
assert(CP:ListCostText({cost=120,unknown=true})=="?")
assert(CP:ListCostText({cost=250}):find("Silver",1,true))
local trainer={trainerRecipe=true,comparison={points=4,cost={cashComplete=true,cash=40}}}
assert(CP:ListCostText(trainer):find("^10|T",1) and CP:ListCostText(trainer):find("Copper",1,true),"Training fee is spread over the expected points")
trainer.comparison.cost.cashComplete=false
assert(CP:ListCostText(trainer)=="?")

-- Recommendation: the cheapest learned option with its suggested count and missing materials.
CP.TrainerRecipeOptions=function() return {} end
CP.trainerOfferCache=nil
CP.db.professions.engineering={skill=10,cap=75}
CP.db.recipes.engineering={
  [95001]={name="Cheap step",learned=true,snapshotSkill=10,difficulty=0,mats={{50001,2}}},
  [95002]={name="Dear step",learned=true,snapshotSkill=10,difficulty=0,mats={{50002,50}}},
}
CP.db.lastCapture={key="engineering",skill=10}
CP.CostCalculation=function(_,kind,key,id,count)
  return {materials={{id=60001,quantity=3,bag=0,bank=0,bankKnown=true,missing=3,used=0},
    {id=60002,quantity=4,bag=2,bank=1,bankKnown=true,missing=0,used=4,fromBags=2,fromBank=1,alts=1,bankLive=false}},
    cashComplete=true,buy=1234,missingBuy=0,unknownRecipes=0}
end
local rec=CP:Recommendation("engineering")
assert(rec and rec.key=="engineering" and rec.missing==1 and rec.materials[1].id==60001 and rec.materials[1].quantity==3)
assert(rec.title:find("Empfehlung",1,true) and rec.detail:find("Fehlt",1,true))
CP.db.lastCapture={key="engineering",skill=9}
assert(CP:Recommendation("engineering")==nil,"No advice from outdated skill colors")
CP.db.lastCapture={key="engineering",skill=10}

-- Search: without Auctionator, at an open auction house, and as a shopping list elsewhere.
CP.ItemName=function(_,id) return "Fixture "..id end
CP.currentRecommendation=rec
Auctionator=nil
assert(not CP:SearchRecommendation() and said[#said]:find("Fixture 60001",1,true))
local searched,listName,listTerms
Auctionator={API={v1={
  MultiSearchExact=function(caller,terms) assert(caller=="CraftPilot");searched=terms end,
  ConvertToSearchString=function(_,term) return term.searchString.."#"..term.quantity end,
  CreateShoppingList=function(_,name,terms) listName,listTerms=name,terms end}}}
AuctionHouseFrame={IsShown=function() return true end}
assert(CP:SearchRecommendation() and searched[1]=="Fixture 60001" and listName==nil)
AuctionHouseFrame={IsShown=function() return false end}
assert(CP:SearchRecommendation() and listName:find("Empfehlung",1,true) and listTerms[1]=="Fixture 60001#3")
CP.currentRecommendation={materials={}}
assert(not CP:SearchRecommendation())

-- Rendering the tab with a recommendation must work in both languages' code paths.
CP.db.view="engineering";CP:OpenTab("now")
assert(CP.recBanner.kicker.displayText=="Nächster Schritt")
assert(CP.recBanner.search.displayText=="3 fehlende Teile zur Liste")
local addDeficits=CP.AddCostDeficits
local purchase
CP.AddCostDeficits=function(_,context) purchase=context end
CP.recBanner.search:GetScript("OnClick")()
assert(purchase and purchase.id==CP.currentRecommendation.id and purchase.quantity==CP.currentRecommendation.count,
  "The next step adds deficits for the recommended quantity")
CP.AddCostDeficits=addDeficits
local overview=CP.recipeDetail.overview
assert(overview:IsShown() and overview.readouts[2].value.displayText=="2 / 1 / 1")
assert(overview.readouts[3].value.displayText=="3 Einheiten")
assert(overview.note.displayText:find("Bankstand gespeichert",1,true))
local showTooltip=CP.ShowCraftTooltip
local hoverRecipe
CP.ShowCraftTooltip=function(_,owner,key,id)
  assert(owner==CP.recipeDetail.iconButton and key=="engineering")
  hoverRecipe=id
end
CP.recipeDetail.iconButton:GetScript("OnEnter")(CP.recipeDetail.iconButton)
assert(hoverRecipe==CP.recipeDetail.entry.id)
CP.ShowCraftTooltip=showTooltip
local priorDetails=CP.db.ui.detailsOpen
CP.db.ui.detailsOpen=true;CP:OpenTab("now")
local rows=CP.recipeDetail.costRows
assert(rows and #rows==3 and rows[1].label.displayText:find("Zukauf",1,true) and rows[1].value.displayText,"Cost details are label/value rows")
CP.db.ui.detailsOpen=priorDetails

CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.lastCapture,CP.db.view=saved.prof,saved.recipes,saved.capture,saved.view
CP.Say,CP.ItemName,Auctionator,AuctionHouseFrame,CP.TrainerRecipeOptions,CP.CostCalculation=saved.say,saved.name,saved.auctionator,saved.ahFrame,saved.offers,saved.cost
CP.currentRecommendation=nil;CP.trainerOfferCache=nil
print("PASS: recommendation banner, per-point training costs, stock label and Auctionator search or shopping list")
