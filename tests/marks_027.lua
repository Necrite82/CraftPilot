-- 0.27: marks on reserved items in any bag view, buyback rescue after selling, auction house warning.
local CP=...
local saved={plan=CP.PlanRequirements,keep=CP.KeepList,count=CP.RawItemCount,name=CP.ItemName,ah=CP.AuctionHouseOpen,say=CP.Say,notice=CP.CompanionNotice,
  container=C_Container,errors=UIErrorsFrame,plans=CP.db.plans}
CP.ItemName=function(_,id) return "Item "..id end
CP.Say=function() end
local slots={[0]={[1]=2840,[2]=70010,[3]=4306}}
C_Container={GetContainerItemID=function(bag,slot) return slots[bag] and slots[bag][slot] end,
  GetContainerItemInfo=function(bag,slot) return {isLocked=true} end}

-- Item buttons are recognized by what they expose, whatever addon draws them.
assert(CP:ButtonItem({GetBagID=function() return 0 end,GetID=function() return 1 end})==2840,"Default/EllesmereUI style")
assert(CP:ButtonItem({bagID=0,slotID=2})==70010,"bagID/slotID fields")
assert(CP:ButtonItem({GetSlotAndBagID=function() return 3,0 end})==4306,"slot and bag from one call")
assert(CP:ButtonItem({GetItemID=function() return 1234 end})==1234)
assert(CP:ButtonItem({itemLink="|cffffffff|Hitem:5678::::::::|h[x]|h|r"})==5678)
assert(CP:ButtonItem({})==nil and CP:ButtonItem(nil)==nil)

-- Reserved: plan need (blue) and kept for later (gold, wins).
CP.db.plans={engineering={start=1,target=20,crafts={}}}
CP.PlanRequirements=function(_,owner) return owner=="engineering" and {[2840]=10,[4306]=4} or {},0,{} end
CP.KeepList=function() return {{item=70010,need=6,uses={{name="Gadget",at=60}},enough=true}} end
CP.reservedCache=nil
local reserved=CP:ReservedItems()
assert(reserved[2840].kind=="plan" and reserved[70010].kind=="keep" and reserved[70010].use.at==60)

-- Marks: buttons found by scanning frames; reserved ones get a dot, others none.
local function itemButton(bag,slot)
  return {GetBagID=function() return bag end,GetID=function() return slot end,IsObjectType=function(_,t) return t=="Button" end,
    GetSize=function() return 37,37 end,IsVisible=function() return true end,GetFrameLevel=function() return 3 end}
end
local frames={itemButton(0,1),itemButton(0,2),itemButton(0,5),{IsObjectType=function() return false end}}
EnumerateFrames=function(f)
  if f==nil then return frames[1] end
  for i,x in ipairs(frames) do if x==f then return frames[i+1] end end
end
CP:UpdateItemMarks(true)
assert(rawget(frames[1],"craftPilotMark") and frames[1].craftPilotMark:IsShown(),"Plan item marked")
assert(frames[2].craftPilotMark:IsShown(),"Kept item marked")
assert(rawget(frames[3],"craftPilotMark")==nil,"Empty slot unmarked")
CP.db.ui.itemMarks=false;CP:UpdateItemMarks(true)
assert(not frames[1].craftPilotMark:IsShown(),"Marks can be switched off")
CP.db.ui.itemMarks=nil
EnumerateFrames=nil

-- Rescue: a reserved item sold at a vendor; the buyback button buys it back.
local counts={[2840]=10}
CP.RawItemCount=function(_,id) return counts[id] or 0 end
local notice
CP.CompanionNotice=function(_,text) notice=text end
CP.merchantCounts={[2840]=10,[70010]=0,[4306]=0}
counts[2840]=4
GetNumBuybackItems=function() return 1 end
GetBuybackItemLink=function() return "|Hitem:2840::|h" end
local boughtBack
BuybackItem=function(i) boughtBack=i end
CP:CheckSoldReserved()
assert(notice and notice:find("6× Item 2840 verkauft",1,true),"Selling a reserved item is reported")
assert(CP.BuybackHelper:IsShown())
CP.BuybackHelper.buy:GetScript("OnClick")()
assert(boughtBack==1 and not CP.BuybackHelper:IsShown())
notice=nil;CP:CheckSoldReserved();assert(notice==nil,"Only new sales are reported")
GetNumBuybackItems,GetBuybackItemLink,BuybackItem=nil,nil,nil

-- Auction house: picking up a reserved item warns; an unreserved one does not.
CP.AuctionHouseOpen=function() return true end
local warned
UIErrorsFrame={AddMessage=function(_,text) warned=text end}
CP:CheckAuctionPick(0,2)
assert(warned and warned:find("Nicht einstellen",1,true) and warned:find("Gadget",1,true))
warned=nil;slots[0][6]=9999;CP:CheckAuctionPick(0,6);assert(warned==nil)

CP.PlanRequirements,CP.KeepList,CP.RawItemCount,CP.ItemName,CP.AuctionHouseOpen,CP.Say,CP.CompanionNotice=saved.plan,saved.keep,saved.count,saved.name,saved.ah,saved.say,saved.notice
C_Container,UIErrorsFrame,CP.db.plans=saved.container,saved.errors,saved.plans
CP.reservedCache=nil;CP.merchantCounts=nil
print("PASS: 0.27 marks in any bag view, buyback rescue after selling reserved items, auction house warning")
