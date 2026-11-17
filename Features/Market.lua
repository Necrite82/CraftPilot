-- Snapshot prices and conservative keep/sell advice; never performs a sale.
local _,CP=...
local L=CP.L
local function finite(n) return type(n)=="number" and n==n and n>=0 and n<math.huge end
function CP:MarketItemData(id)
  local fn=(_G.C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
  if type(fn)=="function" then
    local ok,name,link,quality,level,minLevel,itemType,subType,stack,equip,texture,sellPrice,class,subclass,bind=pcall(fn,id)
    if ok and name then return {vendor=finite(sellPrice) and sellPrice or nil,bind=bind} end
  end
  if _G.C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
    self.marketRequested=self.marketRequested or {}
    if not self.marketRequested[id] then
      self.marketRequested[id]=true;pcall(C_Item.RequestLoadItemDataByID,id)
    end
  end
  return {}
end
function CP:FutureMaterialUses()
  if self.marketUseCache then return self.marketUseCache end
  local uses={}
  local function add(id,key,recipe,skill,name,reference)
    uses[id]=uses[id] or {};uses[id][#uses[id]+1]={key=key,id=recipe,skill=skill,name=name,reference=reference}
  end
  for _,key in ipairs(self.Data.order) do
    if self:OwnsProfession(key) then
      local current=(self.db.professions[key] or {}).skill or 0
      local target=math.min(300,current+25)
      local plan=self.db.plans[key]
      if type(plan)=="table" and (plan.autoMode or next(plan.crafts or {})) then target=math.max(current,plan.target or target) end
      local seen={}
      for id,recipe in pairs(self.db.recipes[key] or {}) do
        if recipe.learned and not recipe.disabled and recipe.canSkillUp~=false and recipe.snapshotSkill==current
          and type(recipe.difficulty)=="number" and recipe.difficulty>=0 and recipe.difficulty<3 then
          seen[id]=true
          for _,mat in ipairs(recipe.mats or {}) do add(mat[1],key,id,current,recipe.name) end
        end
      end
      local catalog=self:RecipeVendorCatalog(key)
      for id,recipe in pairs(catalog and catalog.recipes or {}) do
        local learn=recipe.learn
        if not seen[id] and not (self.db.recipes[key] or {})[id] and type(learn)=="number" and learn>current and learn<=target
          and not recipe.unavailable and not recipe.rep and not recipe.spec and not recipe.cooldown then
          for item in pairs(recipe.mats or {}) do add(item,key,id,learn,recipe.name,true) end
        end
      end
    end
  end
  for _,rows in pairs(uses) do table.sort(rows,function(a,b)
    if a.skill~=b.skill then return a.skill<b.skill end
    if a.key~=b.key then return a.key<b.key end
    return a.id<b.id
  end) end
  self.marketUseCache=uses
  return uses
end
function CP:ItemMarket(id)
  local p=self:PriceDetails(id)
  local data=self:MarketItemData(id)
  local cut=math.max(0,math.min(30,tonumber(self.db.ui.economyCut) or 5))/100
  local net=p.auction and math.floor(p.auction*(1-cut))
  local fresh=p.auction~=nil and p.ageDays~=nil and p.ageDays<=3
  local bound=data.bind==1 or data.bind==4
  local channel,reason="unknown",L("Verkauf prüfen · Daten unvollständig")
  if bound then
    channel,reason="bound",L("Nicht fürs AH · Bindung beachten")
    if data.vendor and data.vendor>0 then channel,reason="vendor",L("Händler möglich · nicht fürs AH") end
  elseif fresh and data.vendor~=nil then
    if net>data.vendor then channel,reason="auction",L("AH bevorzugen · Bindung und Nachfrage prüfen")
    elseif data.vendor>0 then channel,reason="vendor",L("Händler sinnvoll · mindestens AH-Netto")
    else channel,reason="unknown",L("Kein verlässlicher Verkaufserlös") end
  elseif p.auction and not fresh then reason=L("Vor Verkauf neu scannen · Preisalter ungeklärt/alt")
  elseif data.vendor and data.vendor>0 then reason=L("AH-Preis fehlt · Händlerwert bekannt, Vergleich offen") end
  local stock=self:ItemAvailability(id)
  local required=0
  for _,items in pairs(self:ReservationLedger().owners) do required=required+(items[id] or 0) end
  local uses=self:FutureMaterialUses()[id] or {}
  local advice=reason
  if required>0 then
    advice=L("Für Pläne benötigt: ")..required
    if stock>required then advice=advice..L(" · Überschuss: ")..(stock-required).." · "..(#uses>0 and L("Weitere Rezeptverwendung möglich") or reason) end
  elseif #uses>0 then
    local use=uses[1]
    advice=(use.reference and L("Mögliches Folgerezept (Referenz): ") or L("Für erlerntes Rezept nutzbar: "))..self:RecipeName(use.key,use.id,use.name).." ("..self.Data.professions[use.key].name..", "..L("Skill ")..use.skill..")"
      ..L(" · Bedarf nicht mengenmäßig geplant")
  end
  return {id=id,auction=p.auction,age=p.ageDays,net=net,vendor=data.vendor,bound=bound,fresh=fresh,
    channel=channel,advice=advice,required=required,keep=math.min(stock,required),surplus=math.max(0,stock-required),uses=uses}
end
function CP:ItemMarketText(id)
  local m=self:ItemMarket(id)
  local money=function(n) return n~=nil and self:FormatCostMoney(n) or L("unbekannt") end
  local age=m.auction and m.age~=nil and (tostring(m.age)..L(" T.")) or L("Alter unbekannt")
  return L("AH/St.: ")..money(m.auction).." ("..age..") · "..L("Netto/St.: ")..money(not m.bound and m.net or nil)
    ..L(" · Händler/St.: ")..money(m.vendor).."\n"..m.advice
end
function CP:RecipeMarketOutput(key,id)
  local native=(self.db.recipes[key] or {})[id]
  if native and native.outputKnown then return native.outputItemID end
  if native and type(native.outputItemID)=="number" and native.outputItemID>0 then return native.outputItemID end
  local catalog=self:RecipeVendorCatalog(key)
  local recipe=catalog and catalog.recipes[id]
  if recipe and type(recipe.makes)=="number" and recipe.makes>0 then return recipe.makes end
  for _,row in ipairs(self:CampingRecipes(key)) do if row.id==id then return row.object.item end end
end
function CP:RecipeMarketText(key,id)
  local output=self:RecipeMarketOutput(key,id)
  if not output then return L("Ergebnis: kein zugeordnetes handelbares Item · AH-Preis unbekannt") end
  return self:ItemMarketText(output)
end
function CP:MarketCostLines(context)
  local lines={};local seen={}
  local function add(key,id)
    local marker=key..":"..id
    if seen[marker] then return end;seen[marker]=true
    lines[#lines+1]=L("Ergebnis: ")..self:RecipeName(key,id).."\n"..self:RecipeMarketText(key,id)
  end
  if context.kind=="plan" then
    local plan=self:PlanFor(context.key)
    if plan.autoMode and plan.autoRoute then
      for _,step in ipairs(plan.autoRoute.intermediates or {}) do add(context.key,step.id) end
    else for id in pairs(plan.crafts) do add(context.key,id) end end
  elseif context.kind=="camping" then
    for _,step in ipairs(self:CampingShopping().steps) do add(step.row.prof,step.row.id) end
  else add(context.key,context.id) end
  return lines
end
