-- 0.28.2: readable path tooltip (one row per stretch, cost on the right) and the next recipe to learn ahead.
local CP=...
local savedName=CP.ItemName
CP.ItemName=function(_,id) return "Item "..id end
local path={from=207,target=300,reached=300,total=12345,unpriced=2,priceItems={},altCrafts={},segments={
  {id=1,name="Donnerbüchse",first=207,last=225,crafts=18,cost=5000,learned=true},
  {id=2,name="Zielfernrohr",first=225,last=230,crafts=5,cost=800,learned=false,fee=3000,source="trainer"},
  {id=3,name="Granate",first=230,last=300,crafts=66,cost=4545,learned=false,fee=9000,source="ah"},
}}
local rows=CP:PathTooltip(path)
assert(rows[1].left:find("Als Nächstes lernen: Zielfernrohr ab Skill 225",1,true),"The next recipe to learn comes first")
local stretches,learns,total=0,0,false
for _,r in ipairs(rows) do
  if r.right and r.left:find("×",1,true) then stretches=stretches+1 end
  if r.left:find("beim Lehrer lernen",1,true) or r.left:find("im AH kaufen",1,true) then learns=learns+1;assert(r.right~="") end
  if r.left:find("Gesamt bis Skill 300",1,true) then total=r.right~=nil end
end
assert(stretches==3 and learns==2 and total,"One row per stretch, learning on its own row, total with cost")
assert(CP:NextLearnStep(path).id==2)
path.segments[2].learned=true;path.segments[3].learned=true
assert(CP:NextLearnStep(path)==nil)
path.segments[2].learned=false;path.segments[3].learned=false
-- The tooltip helper draws two-column rows.
local drawn={}
local savedTip=GameTooltip
GameTooltip={SetOwner=function() end,SetText=function() end,Show=function() end,Hide=function() end,
  AddLine=function(_,t) drawn[#drawn+1]={t} end,AddDoubleLine=function(_,l,r) drawn[#drawn+1]={l,r} end}
CP.currentRecommendation={path=path}
local onEnter=CP.recBanner and CP.recBanner:GetScript("OnEnter")
assert(onEnter,"Banner tooltip");onEnter()
local doubles=0;for _,d in ipairs(drawn) do if d[2] then doubles=doubles+1 end end
assert(doubles==6,"Six two-column rows: three stretches, two learning rows, total")
GameTooltip=savedTip;CP.ItemName=savedName
print("PASS: 0.28.2 readable path tooltip and next recipe to learn")
