-- 0.28.1: findings from the in-game screenshots.
local CP=...
-- No mark on CraftPilot's own rows (material table in the detail pane).
local saved={count=CP.RawItemCount,recipes=CP.db.recipes.engineering,reserved=CP.ReservedItems,catalog=CP.Catalog}
CP.ReservedItems=function() return {[2840]={kind="plan"}} end
local own={GetName=function() return nil end,GetParent=function() return {GetName=function() return "CraftPilotMainFrame" end,GetParent=function() end} end,
  IsObjectType=function() return true end,itemID=2840,IsVisible=function() return true end}
local foreign={GetName=function() return "ContainerFrame1Item1" end,GetParent=function() end,IsObjectType=function() return true end,itemID=2840,IsVisible=function() return true end}
local frames={own,foreign}
EnumerateFrames=function(f) if f==nil then return frames[1] end for i,x in ipairs(frames) do if x==f then return frames[i+1] end end end
CP:UpdateItemMarks(true)
assert(CP.itemMarks[own]==nil,"Own rows stay unmarked")
assert(CP.itemMarks[foreign] and CP.itemMarks[foreign]:IsShown(),"Bag buttons are marked")
EnumerateFrames=nil;CP.ReservedItems=saved.reserved

-- A color the recipe skips is not shown as "Orange -".
CP.Catalog=function() return {recipes={[99901]={colors={200,200,220,240}}}} end
CP.db.recipes.engineering={}
local text=CP:RecipeRangeText("engineering",99901)
assert(not text:find("Orange",1,true) and text:find("200-219",1,true),"Empty orange range left out")
CP.Catalog=saved.catalog

-- Crafting count from the bags when the client does not report numAvailable; bank stock does not count.
local savedInfo=C_TradeSkillUI.GetRecipeInfo
C_TradeSkillUI.GetRecipeInfo=function() return {} end
CP.db.recipes.engineering={[3922]={learned=true,mats={{2840,3},{2589,1}}}}
local bags={[2840]=7,[2589]=10}
CP.RawItemCount=function(_,id) return bags[id] or 0 end
local count,available=CP:CraftableCount({key="engineering",id=3922,count=8})
assert(available==2 and count==2,"7 bars for 3 each: two crafts")
bags[2840]=0
count,available=CP:CraftableCount({key="engineering",id=3922,count=8})
assert(available==0,"Nothing in the bags: material missing")
C_TradeSkillUI.GetRecipeInfo=savedInfo
CP.RawItemCount,CP.db.recipes.engineering=saved.count,saved.recipes
print("PASS: 0.28.1 own rows unmarked, skipped colors hidden, craft count from bags")
