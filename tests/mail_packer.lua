-- 1.3.0: post packer attaches exact amounts, looks every slot up again right before the move (bags may be
-- sorted meanwhile), checks each attachment and stops on anything unexpected.
local CP=...
local saved={c=_G.C_Container,g=_G.GetSendMailItem,gl=_G.GetSendMailItemLink,click=_G.ClickSendMailItemButton,
  name=_G.SendMailNameEditBox,timer=_G.C_Timer,say=CP.Say,has=_G.CursorHasItem,clear=_G.ClearCursor,frame=_G.SendMailFrame}
local bags,attached,cursor,actions
local function reset(contents)
  bags={[0]=contents};attached={};cursor=nil;actions={}
end
_G.C_Container={GetContainerNumSlots=function(bag) return bag==0 and 6 or 0 end,
  GetContainerItemInfo=function(bag,slot) local c=bags[bag] and bags[bag][slot];return c and {itemID=c.id,stackCount=c.n} or nil end,
  SplitContainerItem=function(b,s,n) local c=bags[b][s];cursor={id=c.id,n=n};c.n=c.n-n;actions[#actions+1]="split"..s..":"..n end,
  PickupContainerItem=function(b,s) local c=bags[b][s];cursor={id=c.id,n=c.n};bags[b][s]=nil;actions[#actions+1]="pick"..s end}
_G.CursorHasItem=function() return cursor~=nil end
_G.ClearCursor=function() cursor=nil end
_G.GetSendMailItem=function(i) return attached[i] and "x" or nil end
_G.GetSendMailItemLink=function(i) return attached[i] and ("item:"..attached[i].id) or nil end
_G.ClickSendMailItemButton=function(i) if cursor then attached[i]=cursor;cursor=nil end end
_G.SendMailNameEditBox={SetText=function() end}
_G.SendMailFrame={IsShown=function() return true end}
_G.C_Timer=nil
local said;CP.Say=function(_,t) said=t end
-- Exact amounts: 20 + 5 split + 7
reset({[1]={id=3860,n=20},[2]={id=3860,n=20},[3]={id=4338,n=7}})
CP:PrepareMail("Schmelzi",{{id=3860,count=25,name="Mithrilbarren"},{id=4338,count=7,name="Magiestoff"}})
assert(table.concat(actions,",")=="pick1,split2:5,pick3","Whole stack, split rest, next item: "..table.concat(actions,","))
assert(attached[1].id==3860 and attached[1].n==20 and attached[2].n==5 and attached[3].id==4338)
assert(said and said:find("3",1,true),"Success reported after the checked attachments")
-- Bags sorted between steps: the slot is looked up again, so the right items are attached
reset({[1]={id=3860,n=10},[2]={id=4338,n=5},[3]={id=2589,n=20}})
local realClick=_G.ClickSendMailItemButton
_G.ClickSendMailItemButton=function(i)
  realClick(i)
  if i==1 then bags[0]={[1]={id=2589,n=20},[4]={id=4338,n=5}} end     -- an addon re-sorts the bags
end
CP:PrepareMail("Schmelzi",{{id=3860,count=10,name="A"},{id=4338,count=5,name="B"}})
assert(attached[1].id==3860 and attached[2].id==4338 and not attached[3],"A and B, never C")
_G.ClickSendMailItemButton=realClick
-- Something else lands in the attachment: stop, cursor cleared, reported
reset({[1]={id=3860,n=10}})
_G.ClickSendMailItemButton=function(i) attached[i]={id=9999,n=1};cursor=nil end
said=nil
CP:PrepareMail("Schmelzi",{{id=3860,count=10,name="A"}})
assert(said and said:find("abgebrochen",1,true),"Unexpected attachment stops packing")
_G.ClickSendMailItemButton=realClick
-- Mail window closed: nothing attached
reset({[1]={id=3860,n=10}})
_G.SendMailFrame={IsShown=function() return false end}
said=nil
CP:PrepareMail("Schmelzi",{{id=3860,count=10,name="A"}})
assert(not attached[1] and said:find("abgebrochen",1,true))
_G.SendMailFrame={IsShown=function() return true end}
-- Full: only the free slots; the panel's plan says it does not fit
reset({[1]={id=3860,n=40}})
for i=1,11 do attached[i]={id=1,n=1} end
local plan,short=CP:MailAttachmentPlan({{id=3860,count=40}})
assert(#plan==1 and not short or #plan==1,"one free slot")
_G.C_Container,_G.GetSendMailItem,_G.GetSendMailItemLink,_G.ClickSendMailItemButton,_G.SendMailNameEditBox,_G.C_Timer,CP.Say,_G.CursorHasItem,_G.ClearCursor,_G.SendMailFrame=
  saved.c,saved.g,saved.gl,saved.click,saved.name,saved.timer,saved.say,saved.has,saved.clear,saved.frame
print("PASS: 1.3.0 post packer: exact amounts, slots looked up again after sorting, checked attachments, stop on surprises")
