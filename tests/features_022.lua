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
