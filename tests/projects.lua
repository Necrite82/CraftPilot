-- 1.3.0: production projects: skill goal + items, intermediates one level down, shared reservation, next step.
local CP=...
local saved={projects=CP.db.projects,active=CP.db.activeProject,seq=CP.db.projectSeq,eng=CP.db.professions.engineering,min=CP.db.professions.mining,
  rec=CP.db.recipes.engineering,mrec=CP.db.recipes.mining,avail=CP.ItemAvailability,path=CP.CheapestPath,plans=CP.db.plans.engineering}
CP.db.projects=nil;CP.db.activeProject=nil;CP.db.plans.engineering=nil
CP.db.professions.engineering={skill=200,cap=225};CP.db.professions.mining={skill=200,cap=225}
-- Mithril Tube (12589? any recipe using mithril bars) – use a catalog engineering recipe that needs Mithril Bar 3860
local tubeID,tubeItem
for id,r in pairs(CP.CatalogData.engineering.recipes) do if r.mats and r.mats[3860] and r.makes then tubeID,tubeItem=id,r.makes;break end end
assert(tubeID,"an engineering recipe with mithril bars")
CP.db.recipes.engineering={[tubeID]={learned=true}}
CP.db.recipes.mining={[10097]={learned=true}}
local stock={}
CP.ItemAvailability=function(_,id) return stock[id] or 0 end
CP.CheapestPath=function() return {quantities={[2840]=10}} end
local p=CP:CreateProject("Rohre")
CP:AddProjectSkill(p,"engineering",225)
CP:AddProjectItem(p,tubeItem,4)
local st=CP:ProjectStatus(p)
assert(#st.steps==2 and not st.steps[1].done and st.next.index==1)
assert(#st.intermediates==1 and st.intermediates[1].item==3860 and st.intermediates[1].key=="mining","Bars are smelted, not bought")
assert(st.required[3858] and st.required[3858]>0 and not st.required[3860],"Ore planned instead of bars")
assert(st.required[2840]==10,"Skill goal materials from the path")
-- shared reservation knows the owner
local req=CP:PlanRequirements("project")
assert(req[3858],"Project owner in the reservation")
local order=CP:ReservationOrder();local has=false;for _,o in ipairs(order) do if o=="project" then has=true end end
assert(has)
-- next step text, progress
assert(CP:ProjectNextText():find("Rohre",1,true))
CP.db.professions.engineering.skill=225
stock[tubeItem]=4
st=CP:ProjectStatus(p)
assert(st.done and CP:ProjectNextText():find("abgeschlossen",1,true))
assert(#CP:ProjectCards("engineering")>3)
CP:DeleteProject(p.id)
assert(#CP:Projects()==0 and CP.db.activeProject==nil)
CP.db.projects,CP.db.activeProject,CP.db.projectSeq=saved.projects,saved.active,saved.seq
CP.db.professions.engineering,CP.db.professions.mining,CP.db.recipes.engineering,CP.db.recipes.mining,CP.ItemAvailability,CP.CheapestPath,CP.db.plans.engineering=
  saved.eng,saved.min,saved.rec,saved.mrec,saved.avail,saved.path,saved.plans
CP:InvalidateReservations()
print("PASS: 1.3.0 production projects: skill goal and items, intermediates, shared reservation, next step, progress")
