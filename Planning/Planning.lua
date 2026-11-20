-- Shared reservations and change detection for explicit profession/camping plans.
local _,CP=...
local L=CP.L
local function add(t,id,n)
  if type(id)=="number" and type(n)=="number" and n>0 then t[id]=(t[id] or 0)+n end
end
-- 1.4.3: the bag marks and item tooltips build on the reservations, so they are rebuilt with them – not on a timer.
function CP:InvalidateReservations()
  self.reservationCache=nil;self.reservedCache=nil;self.tooltipCache=nil;self.keepCache=nil;self.priceDetailCache=nil
  self.availabilityCache=nil
end
function CP:PlanRequirements(owner)
  local required,recipes={},{}
  local unknown=0
  if owner=="project" then
    -- 1.3.0: production projects (Features/Projects.lua).
    if self.ProjectRequirements then for id,n in pairs(self:ProjectRequirements()) do add(required,id,n) end end
    return required,unknown,recipes
  elseif owner=="raid" then
    -- 0.2.1: raid stock (Features/RaidStock.lua) – finished consumables you own plus materials to craft the rest.
    if self.RaidStockRequirements then for id,n in pairs(self:RaidStockRequirements()) do add(required,id,n) end end
    return required,unknown,recipes
  elseif owner=="camping" then
    for _,row in ipairs(self:CampingRecipes()) do
      local n=type(self.db.campingPlan)=="table" and self.db.campingPlan[row.object.item]
      if type(n)=="number" and n>0 then
        recipes[#recipes+1]={key=row.prof,id=row.id}
        if row.mats and next(row.mats) then for id,count in pairs(row.mats) do add(required,id,count*n) end else unknown=unknown+1 end
      end
    end
  else
    local plan=self.db.plans[owner]
    if type(plan)=="table" then
      if plan.autoMode and type(plan.autoRoute)=="table" then
        for _,mat in ipairs(plan.autoRoute.materials or {}) do add(required,mat.id,mat.missing) end
        for id,n in pairs(plan.autoRoute.ownedMaterials or {}) do add(required,id,n) end
        for _,step in ipairs(plan.autoRoute.steps or {}) do recipes[#recipes+1]={key=owner,id=step.id} end
      else
        for id,n in pairs(plan.crafts or {}) do
          if type(n)=="number" and n>0 then
            recipes[#recipes+1]={key=owner,id=id}
            local recipe=(self.db.recipes[owner] or {})[id]
            if recipe and recipe.mats then for _,mat in ipairs(recipe.mats) do add(required,mat[1],mat[2]*n) end else unknown=unknown+1 end
          end
        end
      end
    end
  end
  local books={}
  for _,row in ipairs(recipes) do
    local native,reference=self:CostRecipeData(row.key,row.id)
    if not (native and native.learned) and reference and reference.item and not books[reference.item]
      and self:ItemAvailability(reference.item)>0 then add(required,reference.item,1);books[reference.item]=true end
  end
  return required,unknown,recipes
end
function CP:ReservationOrder()
  local order,seen={},{}
  for _,key in ipairs(type(self.db.reservationOrder)=="table" and self.db.reservationOrder or {}) do
    if (key=="camping" or key=="raid" or key=="project" or self.Data.professions[key]) and not seen[key] then order[#order+1]=key;seen[key]=true end
  end
  for _,key in ipairs(self.Data.order) do if not seen[key] then order[#order+1]=key end end
  if not seen.camping then order[#order+1]="camping" end
  if not seen.raid then order[#order+1]="raid" end
  if not seen.project then order[#order+1]="project" end
  return order
end
function CP:ReservationLedger()
  if self.reservationCache then return self.reservationCache end
  local result={owners={},allocated={},stock={},total={},unknown=0}
  local remaining={}
  for _,owner in ipairs(self:ReservationOrder()) do
    local required,unknown=self:PlanRequirements(owner)
    result.owners[owner]=required;result.allocated[owner]={};result.unknown=result.unknown+unknown
    for id,n in pairs(required) do
      if remaining[id]==nil then local stock=self:ItemAvailability(id);remaining[id]=stock;result.stock[id]=stock end
      local used=math.min(n,remaining[id]);remaining[id]=remaining[id]-used
      result.allocated[owner][id]=used;result.total[id]=(result.total[id] or 0)+used
    end
  end
  self.reservationCache=result
  return result
end
function CP:AvailableForPlan(id,owner)
  local total,bag,bank,live,known=self:ItemAvailability(id)
  local ledger=self:ReservationLedger()
  local own=(ledger.allocated[owner] or {})[id] or 0
  local other=math.min(total,math.max(0,(ledger.total[id] or 0)-own))
  return math.max(0,total-other),bag,bank,live,known,other
end
function CP:PrioritizePlan(owner)
  local order={owner}
  for _,key in ipairs(self:ReservationOrder()) do if key~=owner then order[#order+1]=key end end
  self.db.reservationOrder=order;self:InvalidateReservations();self:StampPlan(owner)
end
function CP:PlanFingerprint(owner)
  local required,unknown,recipes=self:PlanRequirements(owner)
  local parts={"unknown="..unknown,"bank="..tostring(self.db.includeBank),"cut="..tostring(self.db.ui.economyCut),
    "policy="..self:SkillPolicyToken(),"mode="..tostring(self.db.mode),"known="..tostring(self.db.ui.knownRecipesOnly),"reliable="..tostring(self.db.ui.preferReliableSkill)}
  local watched={};for id in pairs(required) do watched[id]=true end
  if owner~="camping" and owner~="raid" and owner~="project" then
    local prof=self.db.professions[owner] or {}
    parts[#parts+1]="skill="..tostring(prof.skill)..":"..tostring(prof.cap)
    local plan=self.db.plans[owner] or {}
    parts[#parts+1]="range="..tostring(plan.start)..":"..tostring(plan.target)
    if plan.autoMode and plan.autoRoute then
      for _,nodes in ipairs({plan.autoRoute.steps or {},plan.autoRoute.intermediates or {}}) do
        for _,node in ipairs(nodes) do for item in pairs(node.mats or {}) do watched[item]=true end;if node.output then watched[node.output]=true end end
      end
    end
    local learned={}
    for id,record in pairs(self.db.recipes[owner] or {}) do
      if record.learned then
        learned[#learned+1]=id..":"..tostring(record.difficulty)..":"..tostring(record.disabled)..":"..tostring(record.outputItemID)..":"..tostring(record.outputMin)..":"..tostring(record.colorObservedStart)
        for _,mat in ipairs(record.mats or {}) do watched[mat[1]]=true;learned[#learned+1]=id..":mat:"..mat[1]..":"..mat[2] end
      end
    end
    table.sort(learned);parts[#parts+1]=table.concat(learned,",")
  end
  local ids={};for id in pairs(watched) do ids[#ids+1]=id end;table.sort(ids)
  for _,id in ipairs(ids) do
    local available=self:AvailableForPlan(id,owner)
    local price=self:PriceDetails(id)
    parts[#parts+1]=table.concat({id,required[id] or 0,available,tostring(price.price),tostring(price.auction),tostring(price.ageDays)},":")
  end
  for _,row in ipairs(recipes) do
    local fee,missing,age=self:RecipeAcquisitionCost(row.key,row.id,owner)
    parts[#parts+1]=row.key..":"..row.id..":"..fee..":"..tostring(missing)..":"..tostring(age)
  end
  table.sort(parts)
  return table.concat(parts,"|")
end
function CP:StampPlan(owner)
  self.db.planFingerprints=self.db.planFingerprints or {}
  self.db.planFingerprints[owner]=self:PlanFingerprint(owner)
end
function CP:PlanNeedsReview(owner)
  self.db.planFingerprints=self.db.planFingerprints or {}
  local previous=self.db.planFingerprints[owner]
  if not previous then self:StampPlan(owner);return false end
  return previous~=self:PlanFingerprint(owner)
end
function CP:ReevaluatePlan(owner,background)
  if owner~="camping" and owner~="raid" and owner~="project" then
    local plan=self:PlanFor(owner)
    if plan and plan.autoMode then
      local current=(self.db.professions[owner] or {}).skill or plan.start
      if current>=plan.target then plan.autoMode=false;plan.autoRoute=nil;plan.crafts={};plan.completed=true
      else
        plan.start=math.max(plan.start or 1,1,current)
        local ok,reason
        if background then ok,reason=self:RequestRouteBuild(owner) else ok,reason=self:BuildRouteForCurrentPlan(owner) end
        if not ok then self:Say(reason or L("Plan konnte nicht neu bewertet werden."));return false end
        plan.completedCrafts=0
        if self:RouteBuildPending(owner) then return true end
      end
    end
  end
  self:InvalidateReservations();self:StampPlan(owner)
  return true
end
function CP:PlanReviewCard(owner)
  local changed=self:PlanNeedsReview(owner)
  local plan=owner~="camping" and owner~="raid" and owner~="project" and self.db.plans[owner]
  local progress=plan and plan.completedCrafts or 0
  return {title=changed and L("Plan geändert · neu bewerten") or L("Planbewertung aktuell"),
    detail=progress>0 and (L("Herstellungen seit letzter Bewertung: ")..progress) or L("Preise, Bestände, Reservierungen und Skill werden berücksichtigt."),
    footer=L("Anklicken: neu bewerten; manuelle Rezeptwahl bleibt erhalten."),color=changed and "gold" or "blue",
    action=function() CP:ReevaluatePlan(owner,true);CP:Render() end}
end
-- Opens the plan a reservation belongs to: raid stock, camping shopping or a profession's plan.
function CP:OpenReservationPlan(owner)
  if owner=="raid" then self.db.ui.endgamePage="stock";self:OpenTab("endgame")
  elseif owner=="camping" then self.db.ui.campingPage="shopping";self:OpenTab("camping")
  elseif owner=="project" then self.db.ui.planPage="projects";self:OpenTab("plan")
  elseif self.Data.professions[owner] then self.db.view=owner;self:OpenTab("plan") end
end
local function itemIcon(id)
  if C_Item and type(C_Item.GetItemIconByID)=="function" then local ok,icon=pcall(C_Item.GetItemIconByID,id);if ok and icon then return icon end end
  if type(GetItemIcon)=="function" then local ok,icon=pcall(GetItemIcon,id);if ok and icon then return icon end end
  return nil
end
function CP:ReservationCards()
  local ledger=self:ReservationLedger()
  local order=self:ReservationOrder()
  local plans={}
  for _,owner in ipairs(order) do
    local count=0;for _,n in pairs(ledger.owners[owner] or {}) do count=count+n end
    if count>0 then plans[#plans+1]=owner end
  end
  local cards={{title=L("Gemeinsame Vorratsreservierung"),
    detail=L("Was deine Pläne aus Taschen, Bank und Twinks für sich zurücklegen. Reservierte Gegenstände sind in den Taschen markiert und warnen beim Verkaufen, Zerstören, Entzaubern und Verschicken."),
    footer=#plans>1 and L("Mehrere Pläne: wer weiter oben steht, bekommt Vorräte zuerst. „Nach vorn“ ändert die Reihenfolge.")
      or L("Nur vorhandene Bestände werden reserviert; fehlende Mengen bleiben Zukauf."),color="gold"}}
  if #plans==0 then
    cards[#cards+1]={title=L("Nichts reserviert"),detail=L("Sobald ein Plan, der Raid-Vorrat oder ein Camping-Einkauf Materialien braucht, die du besitzt, erscheinen sie hier."),color="blue"}
    return cards
  end
  for position,owner in ipairs(plans) do
    local key=owner
    local name=owner=="camping" and L("Camping-Einkauf · alle Berufe") or (owner=="raid" and L("Raid-Vorrat")) or (owner=="project" and L("Projekte")) or self.Data.professions[owner].name
    local needed,reserved,kinds=0,0,0
    for id,n in pairs(ledger.owners[owner]) do
      needed=needed+n
      local used=(ledger.allocated[owner] or {})[id] or 0
      reserved=reserved+used;if used>0 then kinds=kinds+1 end
    end
    local buttons={{label=L("Plan öffnen"),action=function() CP:OpenReservationPlan(key) end}}
    if position>1 then buttons[#buttons+1]={label=L("Nach vorn"),action=function() CP:PrioritizePlan(key);CP:Render() end} end
    cards[#cards+1]={sectionHeader=true,title=string.format("%d. %s",position,name)}
    cards[#cards+1]={title=name,detail=string.format(L("%d Gegenstände reserviert · %d von %d benötigten Einheiten aus deinem Vorrat"),kinds,reserved,needed),
      footer=L("Anklicken: Plan öffnen"),color="blue",action=function() CP:OpenReservationPlan(key) end,buttons=buttons}
    local rows={}
    for id,n in pairs(ledger.owners[owner]) do rows[#rows+1]={id=id,need=n,used=(ledger.allocated[owner] or {})[id] or 0} end
    table.sort(rows,function(x,y) if (x.used>0)~=(y.used>0) then return x.used>0 end return self:ItemName(x.id)<self:ItemName(y.id) end)
    for _,r in ipairs(rows) do
      local missing=r.need-r.used
      cards[#cards+1]={grid=true,showMarket=false,tooltipItem=r.id,icon=itemIcon(r.id),title=self:ItemName(r.id),
        detail=r.used>0 and string.format(L("%d reserviert von %d"),r.used,r.need) or string.format(L("0 von %d vorrätig"),r.need),
        footer=missing>0 and string.format(L("%d fehlen noch (Zukauf)"),missing) or L("vollständig vorrätig"),
        color=missing>0 and (r.used>0 and "gold" or "red") or "green",action=function() CP:OpenReservationPlan(key) end}
    end
  end
  return cards
end
function CP:RecordPlannedCraft(unit,guid,spell)
  if unit~="player" or type(spell)~="number" then return false end
  self.craftGuids=self.craftGuids or {};self.craftGuidOrder=self.craftGuidOrder or {}
  if type(guid)=="string" then
    if self.craftGuids[guid] then return false end
    self.craftGuids[guid]=true;self.craftGuidOrder[#self.craftGuidOrder+1]=guid
    if #self.craftGuidOrder>100 then self.craftGuids[table.remove(self.craftGuidOrder,1)]=nil end
  end
  for _,owner in ipairs(self:ReservationOrder()) do
    if owner=="camping" then
      for _,row in ipairs(self:CampingRecipes()) do
        local plan=type(self.db.campingPlan)=="table" and self.db.campingPlan or {}
        if row.id==spell and type(plan[row.object.item])=="number" and plan[row.object.item]>0 then
          self:AddCampingCraft(row.object.item,-1);return true
        end
      end
    else
      local plan=self.db.plans[owner]
      if type(plan)=="table" then
        if plan.autoMode and plan.autoRoute then
          for _,step in ipairs(plan.autoRoute.intermediates or {}) do
            if step.id==spell then
              plan.completedCrafts=(plan.completedCrafts or 0)+1
              self:InvalidateReservations();return true
            end
          end
        elseif type(plan.crafts)=="table" and type(plan.crafts[spell])=="number" and plan.crafts[spell]>0 then
          plan.crafts[spell]=plan.crafts[spell]-1
          if plan.crafts[spell]==0 then plan.crafts[spell]=nil end
          self:InvalidateReservations();return true
        end
      end
    end
  end
  return false
end
function CP:InitializePlanning()
  if self.planningTicker or not C_Timer or type(C_Timer.NewTicker)~="function" then return end
  self.planningTicker=C_Timer.NewTicker(5,function() self:PlanningTick() end)
end
-- 1.4.3: the check runs after something changed (bags, bank, mail, auction house, profession) or once a minute,
-- not every 5 seconds: rebuilding all reservations each time made a lot of garbage while the window was open.
function CP:PlanningTick()
  if not self.db or not ((self.frame and self.frame:IsShown()) or (self.costWindow and self.costWindow:IsShown())) then return end
  local now=type(GetTime)=="function" and GetTime() or 0
  if not self.planningDirty and self.planningCheckedAt and now-self.planningCheckedAt<60 then return end
  self.planningDirty=false;self.planningCheckedAt=now
  self:InvalidateReservations()
  local current={}
  for _,owner in ipairs(self:ReservationOrder()) do
    local required=self:PlanRequirements(owner)
    if next(required) then current[#current+1]=owner..self:PlanFingerprint(owner) end
  end
  local signature=table.concat(current,"|")
  if self.planningSignature~=signature then
    self.planningSignature=signature;self:Render();self:RefreshCostWindow()
  end
end

if type(CreateFrame)=="function" then
  local watch=CreateFrame("Frame")
  for _,event in ipairs({"BAG_UPDATE_DELAYED","PLAYERBANKSLOTS_CHANGED","BANKFRAME_OPENED","MAIL_INBOX_UPDATE",
    "AUCTION_HOUSE_CLOSED","TRADE_SKILL_LIST_UPDATE","SKILL_LINES_CHANGED","NEW_RECIPE_LEARNED"}) do
    pcall(watch.RegisterEvent,watch,event)
  end
  watch:SetScript("OnEvent",function() CP.planningDirty=true end)
end
