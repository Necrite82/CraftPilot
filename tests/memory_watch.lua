-- 1.4.4: /cpp speicher wraps the main functions for a while and reports what they allocate; results and nils pass through.
local CP=...
local said={};local oldSay=CP.Say;CP.Say=function(_,m) said[#said+1]=m end
local oldAfter=C_Timer.After;local finish
C_Timer.After=function(_,fn) finish=fn end
local realRender=CP.Render
assert(CP:StartMemoryWatch(60))
assert(CP.Render~=realRender,"wrapped while measuring")
local ok,a,b=pcall(CP.RankSources,CP,"cooking")
CP:Render();CP:Render()
local x,y=CP:PlanRequirements("tailoring")
assert(type(x)=="table","results pass through")
finish()
assert(CP.Render==realRender and not CP.memoryWatch,"restored after the measurement")
local report=table.concat(said,"\n")
assert(report:find("Render",1,true) and report:find("2 Aufrufe",1,true),report)
C_Timer.After=oldAfter;CP.Say=oldSay
print("PASS: 1.4.4 /cpp speicher measures and restores the functions")
