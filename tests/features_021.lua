-- 0.2.1: Endgame tab name, recipe wishlist with sources and tooltips, AH alarm, raid stock with reservation
-- and Auctionator export.
local CP,createdFrames=...

-- Tab name ----------------------------------------------------------------------------------------------------------
CP:OpenTab("endgame");assert(CP.db.ui.tab=="endgame")
CP:OpenTab("now")

-- Wishlist and sources ------------------------------------------------------------------------------------------------
local savedDrops=CP.QuestieItemDrops
CP.QuestieItemDrops=function(_,item)
  if item==13491 then return {{id=10001,name="Testboss",zone="Testdungeon"},{id=10002,name="Zweiter Boss"}} end
  return {}
end
local key,id=("alchemy"),17571 -- Elixir of the Mongoose, a drop recipe
CP.db.wishlist=nil;CP.wishIndex=nil;CP.wishItems=nil
assert(not CP:IsWished(key,id))
assert(CP:ToggleWish(key,id)==true and CP:IsWished(key,id))
local text=CP:RecipeSourceText(key,id)
assert(text:find("Testboss · Testdungeon",1,true) and text:find("Zweiter Boss",1,true),"Bosses from QuestieDB")
local cards=CP:WishlistCards(key)
local wished=false
for _,c in ipairs(cards) do if c.title and c.title:find("★",1,true) then wished=true;assert(c.detail:find("Testboss",1,true)) end end
assert(wished,"Wished recipe listed with its sources")
-- Tooltips
assert(CP:NpcIDFromGUID("Creature-0-3299-0-12-10001-0000ABCDEF")==10001)
assert(CP:NpcIDFromGUID("Player-123-ABC")==nil)
local lines=CP:WishUnitLines(10001)
assert(lines and lines[1]:find("Droppt dein Wunschrezept",1,true),"Boss tooltip names the wished recipe")
assert(CP:WishUnitLines(99999)==nil)
CP.tooltipCache=nil
local itemLines=CP:TooltipLines(13491)
local starred=false
for _,l in ipairs(itemLines or {}) do if l[1]:find("Rezept-Wunschliste",1,true) then starred=true end end
assert(starred,"Recipe item tooltip says it is on the wishlist")
-- Suggestions exclude wished and learned recipes.
for _,s in ipairs(CP:WishSuggestions(key,20)) do assert(s.id~=id) end
-- AH alarm: once per day
local savedApi=Auctionator.API.v1
Auctionator.API.v1={GetAuctionPriceByItemID=function(_,item) if item==13491 then return 50000 end end,GetAuctionAgeByItemID=function() return 0 end}
local said={}
local savedSay,savedNotice=CP.Say,CP.CompanionNotice
CP.Say=function(_,t) said[#said+1]=t end;CP.CompanionNotice=function() end
CP.db.alarmSeen=nil;CP.db.ui.ahAlarm=nil
local alarms=CP:AuctionAlarms()
assert(#alarms>=1 and alarms[1].text:find("Wunschrezept im AH",1,true))
assert(CP:CheckAuctionAlarms()>=1 and CP:CheckAuctionAlarms()==0,"Each find once per day")
CP.db.ui.ahAlarm=false
assert(#CP:AuctionAlarms()==0,"Alarm can be switched off")
CP.db.ui.ahAlarm=nil
Auctionator.API.v1=savedApi
CP:ToggleWish(key,id);assert(not CP:IsWished(key,id))
CP.QuestieItemDrops=savedDrops;CP.Say,CP.CompanionNotice=savedSay,savedNotice
print("PASS: 0.2.1 recipe wishlist with boss sources, tooltips and AH alarm")

-- Raid stock ----------------------------------------------------------------------------------------------------------
local P={[990201]=100,[990202]=50,[990300]=400}
Auctionator.API.v1={GetAuctionPriceByItemID=function(_,item) return P[item] end,GetAuctionAgeByItemID=function() return 0 end}
local savedInstant=C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant=function(item) if item==990300 or item==990301 then return item,"x","x","x",1,0 end return item,"x","x","x",1,7 end
CP.db.recipes.alchemy=CP.db.recipes.alchemy or {}
CP.db.recipes.alchemy[990400]={learned=true,name="Testtrank",outputItemID=990300,mats={{990201,2},{990202,1}}}
CP.db.recipes.alchemy[990401]={learned=true,name="Teurer Trank",outputItemID=990301,mats={{990201,10}}}
assert(CP:IsConsumable(990300) and not CP:IsConsumable(990201))
local found=false
for _,c in ipairs(CP:RaidStockCandidates("alchemy")) do if c.item==990300 then found=true end end
assert(found,"Learned consumable offered for the raid stock")
CP.db.raidStock=nil
CP:SetRaidStock(990300,"alchemy",990400,5)
CP:SetRaidStock(990301,"alchemy",990401,3)
P[990301]=300
local rows=CP:RaidStockRows()
assert(#rows==2)
local cheap,dear
for _,r in ipairs(rows) do if r.item==990300 then cheap=r else dear=r end end
assert(cheap.craft==250 and cheap.how=="craft" and cheap.missing==5,"Crafting is cheaper than the AH (250 < 400)")
assert(dear.craft==1000 and dear.how=="buy","Buying is cheaper than crafting (300 < 1000)")
local req=CP:RaidStockRequirements()
assert(req[990201]==10 and req[990202]==5,"Materials for five crafts are reserved")
assert(req[990300]==nil,"Nothing owned yet")
CP:InvalidateReservations();CP.reservedCache=nil
local order=CP:ReservationOrder()
assert(order[#order]=="raid" or order[#order-1]=="raid","Raid stock takes part in the shared reservation")
assert(CP:ReservedItems()[990201] and CP:ReservedItems()[990201].raid,"Materials marked as reserved for the raid")
local missing,total=CP:RaidStockShopping()
assert(missing[990201]==10 and missing[990202]==5 and missing[990301]==3,"Craft materials plus the items to buy")
assert(total==10*100+5*50+3*300)
local stockCards=CP:RaidStockCards("alchemy")
local slider=false
for _,c in ipairs(stockCards) do if c.slider then slider=true end end
assert(slider,"One slider per stocked item")
-- The slider cards show the item tooltip on hover.
CP.db.view="alchemy";CP:OpenTab("endgame")
local savedTip=CP.ShowCraftTooltip
local shownItem
CP.ShowCraftTooltip=function(_,_,_,_,item) shownItem=item end
local hovered=false
for _,b in ipairs(createdFrames) do
  local slider=rawget(b,"settingSlider")
  local enter=slider and b:IsShown() and slider:IsShown() and b:GetScript("OnEnter")
  if enter then enter();hovered=true;break end
end
CP.ShowCraftTooltip=savedTip
assert(hovered and (shownItem==990300 or shownItem==990301),"Raid stock card opens the item tooltip")
CP:OpenTab("now")
-- Export to Auctionator
local created
Auctionator.API.v1.ConvertToSearchString=function(_,t) return t.searchString..";"..t.quantity end
Auctionator.API.v1.CreateShoppingList=function(_,name,terms) created={name=name,terms=terms} end
CP.Say=function() end
local savedName=CP.ItemName
CP.ItemName=function(_,item) return "Item "..item end
local ok=CP:ExportToAuctionator("raid")
assert(ok and created and created.name:find("Raid-Vorrat",1,true) and #created.terms==3,"Raid stock list handed to Auctionator")
CP.ItemName=savedName;CP.Say=savedSay
-- Removing an entry
CP:SetRaidStock(990301,"alchemy",990401,0)
assert(#CP:RaidStockRows()==1)
CP.db.raidStock=nil;CP:InvalidateReservations();CP.reservedCache=nil
CP.db.recipes.alchemy[990400]=nil;CP.db.recipes.alchemy[990401]=nil
C_Item.GetItemInfoInstant=savedInstant;Auctionator.API.v1=savedApi
print("PASS: 0.2.1 raid stock: craft or buy, shared reservation and Auctionator export")
