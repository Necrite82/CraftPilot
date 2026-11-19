-- 1.1.0: post packer attaches exact amounts (whole stacks, the last one split), within free attachment slots.
local CP=...
local saved={c=_G.C_Container,g=_G.GetSendMailItem,click=_G.ClickSendMailItemButton,name=_G.SendMailNameEditBox,timer=_G.C_Timer,say=CP.Say}
local bags={[0]={[1]={itemID=3860,stackCount=20},[2]={itemID=3860,stackCount=20},[3]={itemID=4338,stackCount=7}}}
local actions={}
_G.C_Container={GetContainerNumSlots=function(bag) return bag==0 and 3 or 0 end,
  GetContainerItemInfo=function(bag,slot) return bags[bag] and bags[bag][slot] end,
  SplitContainerItem=function(b,s,n) actions[#actions+1]="split"..s..":"..n end,
  PickupContainerItem=function(b,s) actions[#actions+1]="pick"..s end}
local attached=0
_G.GetSendMailItem=function(i) return i<=attached and "x" or nil end
_G.ClickSendMailItemButton=function(i) attached=attached+1;actions[#actions+1]="att"..i end
_G.C_Timer=nil
local plan,short=CP:MailAttachmentPlan({{id=3860,count=25},{id=4338,count=7}})
assert(#plan==3 and not plan[1].split and plan[2].split and plan[2].take==5 and not plan[3].split and not short,"20 + 5 split + 7")
_G.SendMailNameEditBox={SetText=function(_,n) assert(n=="Schmelzi") end}
local said;CP.Say=function(_,t) said=t end
CP:PrepareMail("Schmelzi",{{id=3860,count=25,name="Mithrilbarren"},{id=4338,count=7,name="Magiestoff"}})
assert(table.concat(actions,",")=="pick1,att1,split2:5,att2,pick3,att3" and said:find("3",1,true),"Attached in order, one by one")
attached=11
plan,short=CP:MailAttachmentPlan({{id=3860,count=40}})
assert(#plan==1 and short,"Only one free slot left: the rest waits for the next mail")
_G.C_Container,_G.GetSendMailItem,_G.ClickSendMailItemButton,_G.SendMailNameEditBox,_G.C_Timer,CP.Say=saved.c,saved.g,saved.click,saved.name,saved.timer,saved.say
print("PASS: 1.1.0 post packer: exact amounts, split stacks, free slots, attached one by one")
