-- 1.1.0: skill notes per craft, own hint, export of what is new, nothing at the cap.
local CP=...
local saved={refresh=CP.RefreshProfessionSkills,mining=CP.db.professions.mining,log=(CP.account or CP.db).skillLog,timer=_G.C_Timer,pending=CP.pendingSkillCast}
local skill=180
CP.RefreshProfessionSkills=function(self) self.db.professions.mining={skill=skill,cap=225} end
_G.C_Timer=nil
;(CP.account or CP.db).skillLog=nil
assert(CP:NoteCraftCast(10097),"Smelt Mithril is a mining recipe")
skill=181
assert(CP:NoteCraftCast(10097))      -- settles the first: a point came
CP:SettleSkillCast()                  -- second: no point
local rows=CP:SkillObservations("mining",10097)
assert(#rows==2 and rows[1].skill==180 and rows[1].u==1 and rows[2].skill==181 and rows[2].u==0)
assert(CP:SkillObservationText("mining",10097):find("2×",1,true))
assert(not CP:NoteCraftCast(1),"Unknown spells are ignored")
skill=225
assert(not CP:NoteCraftCast(10097),"Nothing is noted at the cap")
local code=CP:SkillLogExport(true)
assert(code:find("^CPSKILL1;") and code:find("mining:10097:180:1:1",1,true) and code:find("mining:10097:181:1:0",1,true))
assert(CP:SkillLogExport(false)==nil,"Shared data is not exported twice")
skill=181;CP:NoteCraftCast(10097);CP:SettleSkillCast()
assert(CP:SkillLogExport(false):find("mining:10097:181:1:0",1,true),"Only the new craft")
assert(CP:SkillLogStats().crafts==3 and CP:SkillLogCard().title)
CP.db.ui.skillLog=false;assert(not CP:NoteCraftCast(10097));CP.db.ui.skillLog=nil
CP.RefreshProfessionSkills,CP.db.professions.mining,_G.C_Timer,CP.pendingSkillCast=saved.refresh,saved.mining,saved.timer,saved.pending
;(CP.account or CP.db).skillLog=saved.log
local priorObserved=CP.ObservedSkill
CP.ObservedSkill={engineering={[3922]={crafts=40,points=12,status="confirmed",lastPoint=59}}}
assert(CP:RecipeRangeText("engineering",3922):find("bestätigt",1,true),"Player data confirms the colours")
CP.ObservedSkill={engineering={[3922]={crafts=9,points=2,status="conflict",lastPoint=63}}}
assert(CP:RecipeRangeText("engineering",3922):find("63",1,true))
CP.ObservedSkill=priorObserved
print("PASS: 1.1.0 skill notes: point or not per skill, own hint, export only new data, off switch")
