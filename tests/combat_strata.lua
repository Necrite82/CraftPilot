-- 1.1.1: no SetFrameStrata on the main window in combat; secure buttons are unanchored when hidden.
local CP=...
local main=CP.frame
assert(main,"main frame exists")
local saved={combat=_G.InCombatLockdown,set=main.SetFrameStrata,get=main.GetFrameStrata}
local calls=0
main.SetFrameStrata=function() calls=calls+1 end
main.GetFrameStrata=function() return "MEDIUM" end
_G.InCombatLockdown=function() return true end
CP:ApplyTheme()
assert(calls==0,"Not in combat")
_G.InCombatLockdown=function() return false end
CP:ApplyTheme()
assert(calls==1,"Outside combat when needed")
main.GetFrameStrata=function() return "HIGH" end
CP:ApplyTheme()
assert(calls==1,"Not again when already HIGH")
_G.InCombatLockdown,main.SetFrameStrata,main.GetFrameStrata=saved.combat,saved.set,saved.get
print("PASS: 1.1.1 no protected strata call in combat")
