-- 0.2.2: navigation in a sidebar instead of tabs on top, page title, Endgame sub-pages.
local CP,createdFrames=...
local side
for _,f in ipairs(createdFrames) do if f.frameName=="CraftPilotSidebar" then side=f end end
assert(side and side.parent==CP.frame,"Sidebar is part of the window")
local nav={}
for _,b in ipairs(createdFrames) do
  if b.parent==side and rawget(b,"iconBox") then nav[#nav+1]=b end
end
assert(#nav==8,"Six pages plus settings and help in the sidebar")
-- Clicking a sidebar entry opens its page and marks it.
local endgame
for _,b in ipairs(nav) do if b.displayText=="Endgame" then endgame=b end end
assert(endgame,"Endgame entry")
endgame:GetScript("OnClick")(endgame)
assert(CP.db.ui.tab=="endgame" and endgame.iconBox.visible==true,"Endgame opened and marked")
-- Settings and help keep a single entry each.
local settings,help=0,0
for _,b in ipairs(createdFrames) do
  if rawget(b,"craftNav")=="settings" then settings=settings+1 end
  if rawget(b,"craftNav")=="help" then help=help+1 end
end
assert(settings==1 and help==1)
CP:OpenTab("now")
assert(endgame.iconBox.visible==false,"Only the open page is marked")
print("PASS: 0.2.2 sidebar navigation")

-- 0.2.3: rounded surfaces, profession in the sidebar, reserved chip, profit cards side by side with value bars.
assert(CP.ROUND_BACKDROP and CP.ROUND_BACKDROP.edgeFile:find("Round",1,true))
assert(rawget(CP.frame,"craftRound"),"Window has round corners")
local savedApi=Auctionator.API.v1
local P={[990501]=100,[990502]=300,[990509]=1000,[990519]=900}
Auctionator.API.v1={GetAuctionPriceByItemID=function(_,id) return P[id] end,GetAuctionAgeByItemID=function() return 1 end}
CP.db.recipes.engineering=CP.db.recipes.engineering or {}
CP.db.recipes.engineering[990600]={learned=true,name="Gitterbombe",outputItemID=990509,mats={{990501,2}}}
CP.db.recipes.engineering[990601]={learned=true,name="Gitterzünder",outputItemID=990519,mats={{990502,1}}}
CP.db.view="engineering";CP.db.ui.endgamePage="profit";CP:OpenTab("endgame")
local placed={}
for _,b in ipairs(createdFrames) do
  if b:IsShown() and rawget(b,"barRows") and b.point then placed[#placed+1]=b.point end
end
assert(#placed>=2,"Profit cards drawn with bars")
local sameRow=false
for i=1,#placed do for j=i+1,#placed do
  if placed[i][5]==placed[j][5] and placed[i][4]~=placed[j][4] then sameRow=true end
end end
assert(sameRow,"Two profit cards side by side")
CP.db.recipes.engineering[990600]=nil;CP.db.recipes.engineering[990601]=nil
Auctionator.API.v1=savedApi;CP.db.ui.endgamePage=nil
CP:OpenTab("now")
print("PASS: 0.2.3 round corners, grid cards with value bars")
