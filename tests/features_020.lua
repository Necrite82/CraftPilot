-- 0.2: Endgame tab (profit per recipe, Favor recipes), Merchant's Favor in gold, fastest path, more warnings
-- for reserved items, client zone names and English command aliases.
local CP,createdFrames=...

-- Profit per craft -----------------------------------------------------------------------------------------------
local savedApi=Auctionator.API.v1
local P={[990001]=100,[990002]=300,[990009]=1000}
Auctionator.API.v1={GetAuctionPriceByItemID=function(_,id) return P[id] end,GetAuctionAgeByItemID=function() return 1 end}
local savedCut=CP.db.ui.economyCut
CP.db.ui.economyCut=5
CP.db.recipes.engineering=CP.db.recipes.engineering or {}
CP.db.recipes.engineering[990100]={learned=true,name="Testbombe",outputItemID=990009,mats={{990001,2},{990002,1}}}
local r=CP:RecipeProfit("engineering",990100)
assert(r and r.missing==0,"Complete prices")
assert(r.buy==500,"Materials bought: 2×100 + 300")
assert(r.sale==950,"Result sold at AH minus 5 %")
assert(r.own==2*95+285,"Own materials count at what selling them would bring")
assert(r.profitBuy==450 and r.profitOwn==950-475)
local rows=CP:ProfitList("engineering")
local found=false
for _,row in ipairs(rows) do if row.id==990100 then found=true end end
assert(found,"Learned recipe with complete prices is listed")
local cards=CP:EndgameCards("engineering")
assert(cards[1].title:find("Endgame",1,true))
local card
for _,c in ipairs(cards) do if c.title and c.title:find("Testbombe",1,true) then card=c end end
assert(card and card.metrics and #card.metrics==3 and card.tooltipItem==990009,"Profit card with three figures")
assert(card.color=="green")
-- A result worth less than the materials: selling the materials is better.
P[990009]=200
local bad=CP:RecipeProfit("engineering",990100)
assert(bad.profitBuy<0 and bad.profitOwn<0)
cards=CP:EndgameCards("engineering")
for _,c in ipairs(cards) do if c.title and c.title:find("Testbombe",1,true) then card=c end end
assert(card.footer:find("Materialien direkt verkaufen",1,true) and card.color=="red")
-- Missing price: not listed with a number.
P[990002]=nil
local missing=CP:RecipeProfit("engineering",990100)
assert(missing.missing==1)
local _,incomplete=CP:ProfitList("engineering")
assert(incomplete>=1)
CP.db.recipes.engineering[990100]=nil
Auctionator.API.v1=savedApi;CP.db.ui.economyCut=savedCut

-- The tab exists and renders.
CP:OpenTab("after300")
assert(CP.db.ui.tab=="endgame","Old tab name leads to Endgame")
CP:OpenTab("now")
print("PASS: 0.2 profit per craft, opportunity value of own materials and the Nach-300 tab")

-- Merchant's Favor ---------------------------------------------------------------------------------------------------
local savedRate=CP.db.ui.favorRate
CP.db.ui.favorRate=0
assert(CP:FavorInGold(30)==nil,"No conversion without a rate")
local favorVendor
for _,v in ipairs(CP:RecipeVendors("cooking",1249963,true)) do if v.source and v.source.favor then favorVendor=v end end
assert(favorVendor and favorVendor.cost==nil and not favorVendor.favorEstimate,"Favor recipe has no gold price by default")
assert(CP:VendorOfferPrice(favorVendor):find("Merchant's Favor",1,true))
CP.db.ui.favorRate=5000
assert(CP:FavorInGold(30)==150000)
for _,v in ipairs(CP:RecipeVendors("cooking",1249963,true)) do if v.source and v.source.favor then favorVendor=v end end
assert(favorVendor.favorEstimate and favorVendor.cost==150000,"Favor converted at the player's rate")
assert(CP:VendorOfferPrice(favorVendor):find("ca. ",1,true))
local favorList=CP:FavorRecipes("cooking")
assert(#favorList>0 and favorList[1].favor,"Favor recipes of the profession are listed")
local favorCards=CP:EndgameCards("cooking")
local favorHeader=false
for _,c in ipairs(favorCards) do if c.sectionHeader and c.title:find("Merchant's Favor",1,true) then favorHeader=true end end
assert(favorHeader,"Favor section on Endgame")
CP.db.ui.favorRate=savedRate or 0
print("PASS: 0.2 Merchant's Favor recipes, optional conversion into gold")

-- Fastest path --------------------------------------------------------------------------------------------------------
local function crafts(path)
  local n=0
  for _,s in ipairs(path and path.segments or {}) do n=n+(s.crafts or 0) end
  return n
end
CP:SetSkillPath("cheapest");CP.pathCache=nil
local cheap=CP:CheapestPath("tailoring",30,100)
CP:SetSkillPath("fastest");CP.pathCache=nil
assert(CP:SkillPath()=="fastest" and CP.db.ui.fastestSkill==true)
local fast=CP:CheapestPath("tailoring",30,100)
assert(cheap and fast,"Both paths computed")
assert(crafts(fast)<=crafts(cheap),"Fastest needs no more crafts than cheapest")
print(string.format("Info: tailoring 30–100 cheapest %d crafts / %s, fastest %d crafts / %s",crafts(cheap),tostring(cheap.total),crafts(fast),tostring(fast.total)))
CP:SetSkillPath("reliable");CP.pathCache=nil
assert(CP.db.ui.fastestSkill==false)
print("PASS: 0.2 fastest skill path")

-- More warnings for reserved items -----------------------------------------------------------------------------------
local savedReserved,savedSay,savedName=CP.ReservedItems,CP.Say,CP.ItemName
local said={}
CP.ReservedItems=function() return {[990001]={kind="plan",need=2}} end
CP.Say=function(_,t) said[#said+1]=t end
CP.ItemName=function(_,id) return "Item "..id end
CP.protectionWarned=nil
assert(CP:WarnReserved("destroy",990001) and said[#said]:find("nicht zerstören",1,true))
assert(CP:WarnReserved("destroy",990001) and #said==1,"Same warning only once within a few seconds")
assert(CP:WarnReserved("disenchant",990001) and said[#said]:find("nicht entzaubern",1,true))
assert(not CP:WarnReserved("destroy",990002),"Items that are not reserved are left alone")
CP.account=CP.account or {characters={}}
local savedChars=CP.account.characters
CP.account.characters={["Anna-Realm"]={name="Anna",realm="Realm"}}
local savedCurrent=CP.CurrentCharacter
CP.CurrentCharacter=function() return {realm="Realm"} end
assert(CP:IsOwnCharacter("Anna") and CP:IsOwnCharacter("anna Smith") and CP:IsOwnCharacter("Anna-Realm"))
assert(not CP:IsOwnCharacter("Bob") and not CP:IsOwnCharacter("Annabelle") and not CP:IsOwnCharacter(""))
SendMailNameEditBox={GetText=function() return "Bob Stranger" end}
ATTACHMENTS_MAX_SEND=2
GetSendMailItem=function(i) if i==1 then return "Item",990001 end end
CP.protectionWarned=nil
local before=#said
CP:CheckMailAttachments()
assert(#said==before+1 and said[#said]:find("keiner deiner Charaktere",1,true),"Reserved item mailed to a stranger")
SendMailNameEditBox={GetText=function() return "Anna" end}
CP.protectionWarned=nil;before=#said
CP:CheckMailAttachments()
assert(#said==before,"Mail to an own character is fine")
SendMailNameEditBox,ATTACHMENTS_MAX_SEND,GetSendMailItem=nil,nil,nil
CP.account.characters=savedChars;CP.CurrentCharacter=savedCurrent
CP.ReservedItems,CP.Say,CP.ItemName=savedReserved,savedSay,savedName
print("PASS: 0.2 warnings for destroying, disenchanting and mailing reserved items")

-- English command aliases --------------------------------------------------------------------------------------------
local opened
local savedOpen=CP.OpenTab
CP.OpenTab=function(_,tab) opened=tab end
CP.SlashCommand("stages")
assert(opened=="stages")
CP.OpenTab=savedOpen
print("PASS: 0.2 English command aliases")
