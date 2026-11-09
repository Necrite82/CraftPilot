local CP,frames=...
local db,price,stock,item,cost=CP.db,CP.PriceDetails,CP.ItemAvailability,CP.ItemName,CP.CostCalculation
local tooltip,output=GameTooltip,C_TradeSkillUI.GetRecipeOutputItemData
local oldAuctionator=Auctionator
local actions={}
GameTooltip={SetOwner=function() end,ClearLines=function() actions[#actions+1]="clear" end,
 SetHyperlink=function(_,link) assert(link=="item:91001");actions[#actions+1]="native" end,
 AddLine=function(_,text) actions[#actions+1]=text end,AddDoubleLine=function(_,left,right) actions[#actions+1]=left..":"..right end,
 Show=function() actions[#actions+1]="show" end,Hide=function() end}
C_TradeSkillUI.GetRecipeOutputItemData=function() return {hyperlink="item:91001"} end
CP.ItemName=function(_,id) return "Fixture item "..id end
CP.ItemAvailability=function() return 3,2,1,true,true end
CP.PriceDetails=function() return {price=100,auction=100,ageDays=0} end
CP.db={manualShopping={},ui={economyCut=5},recipes={},professions={},plans={},view="engineering",includeBank=true}
local fixture={cash=500,buy=500,fee=0,cashComplete=true,economicComplete=true,economic=700,stockValue=200,missingStock=0,
 materials={{id=91001,quantity=8,bag=2,bank=1,bankKnown=true,missing=5,used=3,buy=500,reserved=0}},unknownRecipes=0}
CP.CostCalculation=function() return fixture end
CP:InvalidateReservations();CP.marketUseCache={}
CP:ShowCraftTooltip({},"engineering",123)
assert(actions[1]=="clear" and actions[2]=="native","Native tooltip must be populated before CraftPilot additions")
assert(actions[#actions]=="show")
local tableFrame=CreateFrame("Frame")
local h=CP:DrawMaterialTable(tableFrame,fixture.materials,730)
assert(tableFrame.tableHeaders[5].displayText=="Kaufen" and tableFrame.tableRows[1].cells[5].displayText=="5")
assert(tableFrame.tableRows[1].cells[3].displayText=="2" and tableFrame.tableRows[1].cells[4].displayText=="1")
assert(h>tableFrame.tableRows[1].height)
local lastX=-1
for _,header in ipairs(tableFrame.tableHeaders) do
 assert(header.point[4]>lastX);lastX=header.point[4]
 assert(header.point[4]+header.width<=738,"Material columns must fit the available width")
end
assert(CP:AddCostDeficits({kind="recipe",key="engineering",id=123,quantity=1}))
assert(CP.db.manualShopping[91001]==5 and next(CP.db.plans)==nil,"Personal quantities must not mutate skill plans")
assert(CP:AddCostDeficits({kind="recipe",key="engineering",id=123,quantity=1}))
assert(CP.db.manualShopping[91001]==10,"Adding snapshots is an explicit purchase increment")
CP:ChangePersonalShopping(91001,-7);assert(CP.db.manualShopping[91001]==3)
local requested
Auctionator={API={v1={ConvertToSearchString=function(_,term) requested=term.quantity;return term.searchString end,CreateShoppingList=function(_,name,terms) assert(name:find("CraftPilot",1,true));assert(#terms==1) end}}}
assert(CP:ExportPersonalShopping() and requested==3,"Manual purchases must not subtract bags/bank a second time")
CP:OpenPersonalShopping();assert(CP.personalShoppingWindow:IsShown())
local row=CP.personalShoppingWindow.list.tableRows[1]
row:GetScript("OnClick")();assert(CP.personalShoppingWindow.quantity.displayText=="3")
CP.personalShoppingWindow.removeButtons[1]:GetScript("OnClick")()
assert(CP.db.manualShopping[91001]==nil)
CP.personalShoppingWindow:Hide()
local found=false
for _,control in ipairs(frames) do
 if rawget(control,"displayText")=="Fehler melden" and control.point and control.point[1]=="LEFT" then found=true end
end
assert(found,"Report action must be directly adjacent to footer version")
local card=CreateFrame("Button")
for _,field in ipairs({"titleLabel","detailLabel","footLabel","marketLabel"}) do card[field]=CreateFrame("Frame") end
card.titleLabel.GetStringHeight=function() return 80 end
card.detailLabel.GetStringHeight=function() return 90 end
card.footLabel.GetStringHeight=function() return 60 end
local cardHeight=CP:LayoutVisualCard(card,{title="Long title",detail="Long detail",footer="Long note"},600)
assert(-card.detailLabel.point[5]>=90 and -card.footLabel.point[5]>=190)
assert(cardHeight>=262,"Wrapped titles/details/footers must reserve their full height")
CP.db,CP.PriceDetails,CP.ItemAvailability,CP.ItemName,CP.CostCalculation=db,price,stock,item,cost
GameTooltip,C_TradeSkillUI.GetRecipeOutputItemData,Auctionator=tooltip,output,oldAuctionator
CP.marketUseCache=nil;CP:InvalidateReservations()
print("PASS: aligned inventory columns, preserved native tooltip, personal shopping isolation/quantities/export and footer reporting")
