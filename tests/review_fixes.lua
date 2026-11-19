-- 1.3.0: cases from the external review, across functions.
local CP=...
-- (2) Vendor helper: 10 needed, 3 in stock -> 7 missing (stock subtracted once)
do
  local saved={rec=CP.currentRecommendation,avail=CP.ItemAvailability,plans=CP.db.plans}
  CP.db.plans={}
  CP.currentRecommendation={key="engineering",materials={{id=4359,quantity=7,required=10}}}
  CP.ItemAvailability=function() return 3 end
  assert(CP:MissingForPlans()[4359]==7,"7 missing, not 4")
  CP.currentRecommendation,CP.ItemAvailability,CP.db.plans=saved.rec,saved.avail,saved.plans
end
-- (3)+(4) Cost cache independent of order; unconfirmed twink recipes never lower the price
do
  local saved={makers=CP.ItemMakers,price=CP.PriceDetails}
  -- X costs 100 at the AH, or is made from 1 Y (price 1). Y is also a material two levels down elsewhere.
  CP.PriceDetails=function(_,id) local t={[1]=100,[2]=1,[3]=500};return {price=t[id]} end
  CP.ItemMakers=function(_,id)
    if id==1 then return {{key="engineering",id=900001,recipe={mats={[2]=1}}}} end
    if id==3 then return {{key="engineering",id=900002,recipe={mats={[4]=1}}}} end
    if id==4 then return {{key="engineering",id=900003,recipe={mats={[1]=1}}}} end
    return {}
  end
  local up=CP.UnitPriceForTest
  assert(type(up)=="function","test hook")
  local memo={items={},notes={}}
  up(CP,memo,3,0)             -- reaches item 1 at depth 2 first (no making there)
  assert(up(CP,memo,1,0)==1,"Later direct lookup still finds the made price (1, not 100)")
  -- Unconfirmed twink maker
  CP.ItemMakers=function(_,id) if id==1 then return {{key="engineering",id=900001,alt="Twinky",altSure=false,recipe={mats={[2]=1}}}} end return {} end
  memo={items={},notes={}}
  assert(up(CP,memo,1,0)==100,"Unconfirmed twink recipe does not lower the price")
  assert(memo.maybe and memo.maybe[1] and memo.maybe[1].alt=="Twinky","…but is kept as a hint")
  CP.ItemMakers,CP.PriceDetails=saved.makers,saved.price
end
-- (5) Your active plan first, the cheaper path as an alternative; switching is the player's choice
do
  local saved={path=CP.CheapestPath,step=CP.ForwardRouteStep,cap=CP.db.lastCapture,eng=CP.db.professions.engineering,
    rec=CP.db.recipes.engineering,src=CP.db.ui.recSource,sugg=CP.CraftSuggestion}
  CP.db.professions.engineering={skill=207,cap=300}
  CP.db.lastCapture={key="engineering",skill=207}
  CP.db.recipes.engineering={[12594]={learned=true},[12595]={learned=true}}
  CP.CheapestPath=function() return {segments={{id=12594,name="A",crafts=5,last=215,learned=true}},perPointNow={[12594]=100,[12595]=300},priceItems={},total=1000,reached=300,from=207} end
  CP.ForwardRouteStep=function() return {id=12595,name="B",first=200,last=220} end
  CP.CraftSuggestion=function() return {count=4,target=215} end
  CP.db.ui.recSource=nil
  local rec=CP:Recommendation("engineering")
  assert(rec and rec.source=="plan" and rec.id==12595,"Active plan comes first")
  assert(rec.alternative and rec.alternative.source=="cheapest" and rec.alternative.id==12594 and rec.alternative.perPointGap==200)
  assert(rec.extra and rec.extra:find("A",1,true),"Cheaper path offered next to it")
  CP.db.ui.recSource={engineering="cheapest"}
  rec=CP:Recommendation("engineering")
  assert(rec.source=="cheapest" and rec.id==12594 and rec.alternative.source=="plan","Player switched to the cheapest path")
  CP.ForwardRouteStep=function() return nil end
  rec=CP:Recommendation("engineering")
  assert(rec.source=="cheapest" and not rec.alternative,"Without a plan: cheapest path")
  CP.CheapestPath,CP.ForwardRouteStep,CP.db.lastCapture,CP.db.professions.engineering,CP.db.recipes.engineering,CP.db.ui.recSource,CP.CraftSuggestion=
    saved.path,saved.step,saved.cap,saved.eng,saved.rec,saved.src,saved.sugg
end
-- 1.3.0 features: why this recipe, budget reserve, twink stock age, path change after a scan
do
  local path={segments={{id=1,name="A",first=200,last=210,expected=20,cost=20000,learned=true},{id=2,name="B",first=210,last=220,expected=10,cost=10000,learned=false}},
    total=30000,reached=220,optionsNow={{id=1,name="A",perPoint=1000,chance=.5,learned=true},{id=3,name="C",perPoint=1500,chance=1,learned=false,fee=5000},{id=4,name="D",perPoint=900,chance=.25,learned=true}},quantities={}}
  local saved=CP.CheapestPath
  CP.CheapestPath=function() return path end
  local why=CP:WhyRecipe("engineering",1)
  assert(why and why.chosen.id==1 and #why.others==2 and why.others[1].id==4,"Two best alternatives by cost per point")
  assert(CP:WhyRecipeLines("engineering",1)[1].left:find("Warum",1,true))
  assert(CP:PathReserve(path)>0,"Yellow/green steps need a reserve")
  assert(CP:PathReserve({segments={{first=1,last=11,expected=10,cost=1000}}})==0,"Orange needs none")
  local before={total=30000,ids={[1]="A"},visits=0}
  local after={total=28000,ids={[1]="A",[5]="E"},visits=1}
  local text=CP:PathChangeText(CP:PathChange(before,after))
  assert(text and text:find("spart",1,true) and text:find("E",1,true) and text:find("1 Lehrer",1,true))
  assert(CP:PathChange(before,{total=30050,ids={[1]="A"},visits=0})==nil,"Tiny price moves are no news")
  CP.CheapestPath=saved
  -- twink stock age
  local acct=CP.account;local savedChars=acct and acct.characters
  local savedAge=CP.db.ui.altMaxAge
  if acct then
    local me=CP:CurrentCharacter()
    acct.characters={[CP.characterKey]=me,["old-x"]={name="Alt",realm=me and me.realm,faction=me and me.faction,bags={[2770]=5},updated=(time and time() or 0)-40*86400}}
    CP.altIndex=nil;CP.db.ui.altMaxAge=14
    assert(CP:AltReachable(2770)==0,"40-day-old stock is not planned with")
    assert(CP:AltStock(2770)[1].tooOld,"…but still shown")
    CP.db.ui.altMaxAge=0;CP.altIndex=nil
    assert(CP:AltReachable(2770)==5,"0 = always")
    acct.characters=savedChars;CP.altIndex=nil;CP.db.ui.altMaxAge=savedAge
  end
end
print("PASS: 1.3.0 review fixes: stock subtracted once, depth-safe cost cache, unconfirmed twink recipes only as a hint, plan first with a switch")
