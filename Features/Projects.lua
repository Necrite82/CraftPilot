-- 1.3.0: production projects. One flow instead of separate lists, e.g. "Engineering to 225, then 20 bombs and two
-- scopes". Steps are skill goals or items to make; materials are planned together with intermediates one level
-- down (bars you can smelt yourself are made, not bought), stock is shared with the other plans through the
-- reservation (owner "project"). Progress and the next step survive logout. Existing plans stay as they are.
local _,CP=...
local L=CP.L
local D=CP.Data

local function profName(key) return (D.professions[key] or {}).name or key end

function CP:Projects()
  self.db.projects=type(self.db.projects)=="table" and self.db.projects or {}
  return self.db.projects
end
function CP:ActiveProject()
  local list=self:Projects()
  for _,p in ipairs(list) do if p.id==self.db.activeProject then return p end end
  return list[1]
end
function CP:CreateProject(name)
  local list=self:Projects()
  self.db.projectSeq=(self.db.projectSeq or 0)+1
  local p={id=self.db.projectSeq,name=name or string.format(L("Projekt %d"),self.db.projectSeq),steps={}}
  list[#list+1]=p
  self.db.activeProject=p.id
  self:InvalidateReservations()
  return p
end
function CP:DeleteProject(id)
  local list=self:Projects()
  for i,p in ipairs(list) do if p.id==id then table.remove(list,i);break end end
  if self.db.activeProject==id then self.db.activeProject=list[1] and list[1].id or nil end
  self:InvalidateReservations()
end
function CP:AddProjectSkill(project,key,target)
  project.steps[#project.steps+1]={type="skill",key=key,target=target}
  self:InvalidateReservations()
end
-- Item step: which recipe makes it (own learned first, else any), how many.
function CP:AddProjectItem(project,item,count,key,id)
  if not key then
    for _,p in ipairs(self.ItemProducers and self:ItemProducers(item) or {}) do
      local native=(self.db.recipes[p.key] or {})[p.id]
      if native and native.learned then key,id=p.key,p.id;break end
      key,id=key or p.key,id or p.id
    end
  end
  for _,s in ipairs(project.steps) do
    if s.type=="item" and s.item==item then s.count=s.count+(count or 1);self:InvalidateReservations();return s end
  end
  local step={type="item",item=item,count=count or 1,key=key,id=id}
  project.steps[#project.steps+1]=step
  self:InvalidateReservations()
  return step
end
function CP:RemoveProjectStep(project,index)
  table.remove(project.steps,index)
  self:InvalidateReservations()
end

local function recipeMats(self,key,id)
  local native=(self.db.recipes[key] or {})[id]
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  local yield=math.max(1,(native and native.outputMin) or (recipe and (recipe.count or recipe.yield)) or 1)
  if native and native.mats then
    local m={};for _,mat in ipairs(native.mats) do m[mat[1]]=(m[mat[1]] or 0)+mat[2] end
    return m,yield
  end
  return recipe and recipe.mats or {},yield
end
-- An own learned recipe that makes this item (for intermediates), or nil.
local function ownMaker(self,item)
  for _,p in ipairs(self.ItemProducers and self:ItemProducers(item) or {}) do
    local native=(self.db.recipes[p.key] or {})[p.id]
    if native and native.learned and not native.disabled then return p end
  end
  return nil
end

-- Projects share the stock left by higher-priority plans. Do not ask the reservation ledger here: it calls
-- ProjectRequirements itself. The earlier owners' gross requirements give the same remaining stock.
local function projectPool(self)
  local pool={blocked={}}
  for _,owner in ipairs(self:ReservationOrder()) do
    if owner=="project" then break end
    for id,n in pairs(self:PlanRequirements(owner)) do pool.blocked[id]=(pool.blocked[id] or 0)+n end
  end
  return pool
end
local function takeStock(self,pool,id,n)
  if pool[id]==nil then pool[id]=math.max(0,(self:ItemAvailability(id) or 0)-(pool.blocked[id] or 0)) end
  local used=math.min(n,pool[id]);pool[id]=pool[id]-used
  return used
end

-- Status of each step; one stock pool is consumed in project/step order, including intermediate ingredients.
local function projectStatus(self,project,pool)
  local out={steps={},required={},intermediates={}}
  local function need(id,n) if n>0 then out.required[id]=(out.required[id] or 0)+n end end
  for i,s in ipairs(project.steps) do
    local st={index=i,step=s}
    if s.type=="skill" then
      local p=self.db.professions[s.key]
      st.current=p and p.skill or 0
      st.done=st.current>=s.target
      st.text=string.format(L("%s auf %d (jetzt %d)"),profName(s.key),s.target,st.current)
      if not st.done and not self.db.plans[s.key] then
        local path=self.CheapestPath and self:CheapestPath(s.key,nil,s.target)
        for id,q in pairs(path and path.quantities or {}) do
          local n=math.ceil(q);takeStock(self,pool,id,n);need(id,n)
        end
      end
    else
      st.have=takeStock(self,pool,s.item,s.count)
      st.done=st.have>=s.count
      st.text=string.format(L("%d× %s herstellen (%d/%d)"),s.count,self:ItemName(s.item),st.have,s.count)
      -- The finished items you already own stay reserved, so they are not sold.
      need(s.item,st.have)
      local left=s.count-st.have
      if left>0 and s.key and s.id then
        local mats,yield=recipeMats(self,s.key,s.id)
        local crafts=math.ceil(left/yield)
        for mat,n in pairs(mats) do
          local total=n*crafts
          local stock=takeStock(self,pool,mat,total)
          local maker=total>stock and ownMaker(self,mat)
          if maker then
            -- Intermediate: make the missing part yourself, plan its materials instead.
            local missing=total-stock
            need(mat,stock)
            local subMats,subYield=recipeMats(self,maker.key,maker.id)
            local subCrafts=math.ceil(missing/subYield)
            for sub,m in pairs(subMats) do
              local n=m*subCrafts;takeStock(self,pool,sub,n);need(sub,n)
            end
            out.intermediates[#out.intermediates+1]={item=mat,count=missing,key=maker.key,id=maker.id,for_=s.item}
          else
            need(mat,total)
          end
        end
      end
    end
    out.steps[#out.steps+1]=st
  end
  for _,st in ipairs(out.steps) do if not st.done then out.next=st;break end end
  out.done=out.next==nil and #out.steps>0
  return out
end

function CP:ProjectStatus(project)
  local pool=projectPool(self)
  for _,p in ipairs(self:Projects()) do
    local status=projectStatus(self,p,pool)
    if p==project then return status end
  end
  return projectStatus(self,project,projectPool(self))
end

-- Requirements for the shared reservation (Planning.lua, owner "project"): all projects together.
function CP:ProjectRequirements()
  local req,pool={},projectPool(self)
  for _,p in ipairs(self:Projects()) do
    for id,n in pairs(projectStatus(self,p,pool).required) do req[id]=(req[id] or 0)+n end
  end
  return req
end

-- "Projekt Bomben: erst 10× Bronzebarren, dann 20× Große Eisenbombe (3/20)"
function CP:ProjectNextText()
  local p=self:ActiveProject()
  if not p then return nil end
  local status=self:ProjectStatus(p)
  if status.done then return string.format(L("Projekt „%s“ abgeschlossen"),p.name) end
  local st=status.next
  if not st then return nil end
  local first
  if st.step.type=="item" then
    for _,im in ipairs(status.intermediates) do
      if im.for_==st.step.item then first=string.format(L("erst %d× %s, dann "),im.count,self:ItemName(im.item));break end
    end
  end
  return string.format(L("Projekt „%s“: "),p.name)..(first or "")..st.text
end

-- Cards for Plan & Einkauf > Projekte
function CP:ProjectCards(key)
  local cards={}
  local list=self:Projects()
  local active=self:ActiveProject()
  cards[#cards+1]={title=L("Neues Projekt"),detail=L("Ein gemeinsamer Ablauf aus Skillzielen und Gegenständen. Gegenstände fügst du unter Gegenstände › Hergestellt durch hinzu („Zum Projekt“)."),
    color="green",grid=true,action=function() CP:CreateProject();CP:Render() end,footer=L("Klick: anlegen")}
  local p=self.db.professions[key]
  if active and p and p.cap and (p.skill or 0)<p.cap then
    local target=math.min(p.cap,(p.skill or 0)+25)
    cards[#cards+1]={title=string.format(L("%s auf %d"),profName(key),target),detail=string.format(L("Als Skillziel zu „%s“ hinzufügen"),active.name),
      color="blue",grid=true,footer=L("Klick: hinzufügen"),action=function() CP:AddProjectSkill(active,key,target);CP:Render() end}
  end
  if #list>0 then
    cards[#cards+1]={title=L("Einkaufsliste der Projekte"),detail=L("Alles, was deine Projekte noch kaufen müssen, als Auctionator-Liste. Vorrat und andere Pläne sind schon verrechnet."),
      color="blue",grid=true,footer=L("Klick: an Auctionator"),action=function() CP:ExportToAuctionator("project");CP:Render() end}
  end
  for _,proj in ipairs(list) do
    local id=proj.id
    local status=self:ProjectStatus(proj)
    local isActive=active and active.id==id
    cards[#cards+1]={sectionHeader=true,title=(isActive and "> " or "")..string.upper(proj.name)}
    cards[#cards+1]={title=status.done and L("Abgeschlossen") or (status.next and status.next.text or L("Noch keine Schritte")),
      detail=isActive and L("Aktives Projekt · der nächste Schritt steht auch auf „Jetzt“") or L("Klick: als aktives Projekt wählen"),
      color=status.done and "green" or (isActive and "gold" or "blue"),
      action=not isActive and function() CP.db.activeProject=id;CP:Render() end or nil,
      buttons={{label=L("Projekt löschen"),action=function() CP:DeleteProject(id);CP:Render() end}}}
    for i,st in ipairs(status.steps) do
      local index=i
      local buttons={{label=L("Entfernen"),action=function() CP:RemoveProjectStep(proj,index);CP:Render() end}}
      if st.step.type=="item" then
        buttons[#buttons+1]={label="+5",action=function() st.step.count=st.step.count+5;CP:InvalidateReservations();CP:Render() end}
        buttons[#buttons+1]={label="-5",action=function() st.step.count=math.max(1,st.step.count-5);CP:InvalidateReservations();CP:Render() end}
      end
      cards[#cards+1]={title=(st.done and "|cff8fd6a6[x]|r " or (i..". "))..st.text,color=st.done and "green" or "blue",buttons=buttons,
        tooltipItem=st.step.type=="item" and st.step.item or nil}
    end
    for _,im in ipairs(status.intermediates) do
      cards[#cards+1]={title=string.format(L("Zwischenprodukt: %d× %s (%s)"),im.count,self:ItemName(im.item),profName(im.key)),
        detail=string.format(L("für %s · wird selbst hergestellt statt gekauft"),self:ItemName(im.for_)),color="blue",tooltipItem=im.item}
    end
  end
  return cards
end
