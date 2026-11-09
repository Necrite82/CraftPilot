local CP,frames=...
local oldLib,oldAddons,oldMetadata=LibQuestieDB,C_AddOns,GetAddOnMetadata
local oldToggle=CP.db.ui.useQuestieDB
CP.db.ui.useQuestieDB=true
local flavor="Forever"
LibQuestieDB={addonName="QuestieDB",readMode="baked",RequireContract=function(v) return v==1 end,
 ModeIndicator={GetStatus=function() return {mode="baked",contractVersion=4} end},
 Npc={Get=function() end}}
C_AddOns={GetAddOnMetadata=function(addon,key) assert(addon=="QuestieDB" and key=="X-Flavor");return flavor end}
assert(CP:QuestieProvider()==LibQuestieDB,"Real baked status omits expansion; loaded X-Flavor must identify Forever")
assert(CP:QuestieStatus():find("aktiv",1,true))
flavor="Vanilla";assert(CP:QuestieProvider()==nil)
assert(CP:QuestieStatus():find("Vanilla",1,true))
flavor=nil;local _,reason=CP:QuestieProvider();assert(reason=="unknownFlavor")
flavor="Forever";C_AddOns=nil;GetAddOnMetadata=function() return flavor end
assert(CP:QuestieProvider()==LibQuestieDB,"Legacy metadata API is supported")
LibQuestieDB.ModeIndicator.GetStatus=function() return {mode="baked",expansion="Vanilla"} end
assert(CP:QuestieProvider()==nil,"Metadata must not override an explicit different provider flavor")
LibQuestieDB.ModeIndicator.GetStatus=function() return {mode="source"} end
assert(CP:QuestieProvider()==nil,"Baked metadata cannot certify an unidentified source tree")
LibQuestieDB.ModeIndicator.GetStatus=function() return {mode="baked"} end
LibQuestieDB.RequireContract=function() return false end
assert(CP:QuestieProvider()==nil and CP:QuestieStatus():find("API",1,true))
LibQuestieDB,C_AddOns,GetAddOnMetadata=oldLib,oldAddons,oldMetadata;CP.db.ui.useQuestieDB=oldToggle

local oldList,oldInfo=GetProfessions,GetProfessionInfo
local oldNative,oldLinked=C_TradeSkillUI.GetProfessionInfoBySkillLineID,C_TradeSkillUI.IsTradeSkillLinked
local oldFirstAid,oldTailoring=CP.db.professions.firstaid,CP.db.professions.tailoring
GetProfessions=function() return nil end
GetProfessionInfo=function() error("No index supplied") end
local skill=25
C_TradeSkillUI.GetProfessionInfoBySkillLineID=function(id)
 return {professionID=id,professionName="First Aid",skillLevel=id==129 and skill or 0,maxSkillLevel=id==129 and 75 or 0}
end
C_TradeSkillUI.IsTradeSkillLinked=function() return false end
CP:RefreshProfessionSkills()
assert(CP.db.professions.firstaid.skill==25 and CP.db.professions.firstaid.cap==75)
assert(CP:OwnsProfession("firstaid"),"Learned First Aid must count even when legacy secondary slots omit it")
skill=35;CP:RefreshProfessionSkills()
assert(CP.db.professions.firstaid.skill==35 and CP:OwnsProfession("firstaid"),"Reported live 129 / 35 / 75 tuple must be owned")
local oldView,oldShowAll=CP.db.view,CP.db.ui.showAllProfessions
CP.db.view="firstaid";CP.db.ui.showAllProfessions=false;CP:Render()
local marked=false
for _,control in ipairs(frames) do
 local label=rawget(control,"displayText")
 if type(label)=="string" and label:find("ReadyCheck-Ready",1,true) and label:find("Erste Hilfe",1,true) and control:IsShown() then marked=true end
end
assert(marked,"Own-only profession UI must show First Aid with the green ready texture")
CP.db.view,CP.db.ui.showAllProfessions=oldView,oldShowAll
CP.db.professions.tailoring={skill=300,cap=300}
assert(not CP:OwnsProfession("tailoring"),"Saved reference skills never establish ownership")
skill=0;assert(not CP:OwnsProfession("firstaid"),"An unlearned native reference must not receive a checkmark")
skill=25;C_TradeSkillUI.IsTradeSkillLinked=function() return true end
assert(not CP:OwnsProfession("firstaid"),"Linked profession data must not establish ownership")
C_TradeSkillUI.IsTradeSkillLinked=function() return false end
C_TradeSkillUI.GetProfessionInfoBySkillLineID=nil
GetProfessions=function() return nil,nil,nil,nil,nil,nil,77 end
GetProfessionInfo=function(index) assert(index==77);return "First Aid",0,25,75,1,0,129 end
assert(CP:OwnsProfession("firstaid"),"Inspect all returned slots rather than relying on one client layout")
GetProfessions=function() return nil end
assert(not CP:OwnsProfession("firstaid"),"Unlearning must not leave a stale owned checkmark")
GetProfessions,GetProfessionInfo=oldList,oldInfo
C_TradeSkillUI.GetProfessionInfoBySkillLineID,C_TradeSkillUI.IsTradeSkillLinked=oldNative,oldLinked
CP.db.professions.firstaid,CP.db.professions.tailoring=oldFirstAid,oldTailoring
print("PASS: packaged QuestieDB flavor detection and live First Aid ownership at skill 25")
