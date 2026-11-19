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
print("PASS: 1.3.0 review fixes: stock subtracted once, depth-safe cost cache, unconfirmed twink recipes only as a hint, plan first with a switch")
