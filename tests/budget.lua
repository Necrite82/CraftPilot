-- 1.1.0: the budget is visible on "Jetzt", in the companion, and warns when the next step costs more.
local CP=...
local saved={path=CP.CheapestPath,gold=CP.db.ui.budgetGold,render=CP.Render}
local path={from=200,reached=250,target=250,total=200000,segments={
  {name="A",first=200,last=225,cost=50000,learned=true},{name="B",first=225,last=250,cost=150000,learned=true}}}
CP.CheapestPath=function() return path end
CP.Render=function() end
CP.db.ui.budgetGold=0
local line=CP:BudgetLine("engineering")
assert(line.off and line.text:find("250",1,true) and line.action:find("Budget",1,true),"Without a budget: whole way and an offer")
CP:SetBudget(10)
line=CP:BudgetLine("engineering",{buy=150000,buyComplete=true})
assert(not line.off and line.reach.reached<250 and line.over,"10 gold reaches part of the way; a 15 gold step is over budget")
assert(line.text:find("Budget 10 Gold",1,true) and line.short)
CP:SetBudget(25)
line=CP:BudgetLine("engineering",{buy=1000,buyComplete=true})
assert(line.reach.reached==250 and not line.over,"25 gold covers the whole way")
assert(CP:SetBudget(-3)==0 and CP:SetBudget("12")==12)
assert(CP:OpenBudgetWindow() and CP.budgetWindow)
CP.CheapestPath,CP.db.ui.budgetGold,CP.Render=saved.path,saved.gold,saved.render
print("PASS: 1.1.0 visible budget: whole way without budget, reach, over-budget warning, input window")
