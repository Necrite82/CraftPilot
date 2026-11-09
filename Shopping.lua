-- Explicit planned craft dependencies and Auctionator's public shopping-list API.
local _,CP=...
local L=CP.L
function CP:RecipeStockText(key,id,compact)
  local native,reference=self:CostRecipeData(key,id)
  local mats={}
  if native then for _,mat in ipairs(native.mats or {}) do mats[mat[1]]=(mats[mat[1]] or 0)+mat[2] end
  else for item,n in pairs(reference and reference.mats or {}) do mats[item]=n end end
  local ids={};for item in pairs(mats) do ids[#ids+1]=item end;table.sort(ids)
  local parts={}
  for _,item in ipairs(ids) do
    local available,bag,bank,live,known,reserved=self:AvailableForPlan(item,key)
    local name=self:ItemName(item)
    if compact then
      local icon
      if _G.C_Item and type(C_Item.GetItemIconByID)=="function" then local ok,value=pcall(C_Item.GetItemIconByID,item);if ok then icon=value end end
      parts[#parts+1]=mats[item].."x "..(icon and ("|T"..icon..":14|t ") or (name.." "))..bag.."/"..(known and bank or "?")
        ..(reserved>0 and (L(" · reserviert ")..reserved) or "")
    else
      parts[#parts+1]=mats[item].."x "..name..": "..L("Tasche ")..bag..L(" · Bank ")..(known and bank or L("unbekannt"))
        ..(self.db.includeBank and "" or L(" (aus)"))..L(" · reserviert ")..reserved..L(" · fehlt ")..math.max(0,mats[item]-available)
    end
  end
  if compact and #parts>0 then return L("Zutaten [Tasche/Bank]: ")..table.concat(parts," · ")..(self.db.includeBank and "" or L(" (Bank aus)")) end
  return #parts>0 and table.concat(parts,"\n") or L("Materialbestand: keine eindeutigen Zutaten erfasst")
end
function CP:ResolveManualPlan(key)
  local plan=self:PlanFor(key)
  local records=self.db.recipes[key] or {}
  local producers,ids={},{}
  for id,n in pairs(plan.crafts) do
    if type(n)=="number" and n>0 then
      local recipe=records[id]
      if not recipe or not recipe.learned or recipe.disabled or type(recipe.mats)~="table" or #recipe.mats==0 then return nil,"materials" end
      ids[#ids+1]=id
      if recipe.outputItemID then producers[recipe.outputItemID]=producers[recipe.outputItemID] or {};table.insert(producers[recipe.outputItemID],id) end
    end
  end
  table.sort(ids)
  local states,ordered={},{}
  local function visit(id)
    if states[id]==1 then return false,"cycle" end
    if states[id]==2 then return true end
    states[id]=1
    for _,mat in ipairs(records[id].mats) do
      for _,producer in ipairs(producers[mat[1]] or {}) do
        if type(records[producer].outputMin)~="number" or records[producer].outputMin<=0 then return false,"yield" end
        local ok,reason=visit(producer);if not ok then return false,reason end
      end
    end
    states[id]=2;ordered[#ordered+1]=id;return true
  end
  for _,id in ipairs(ids) do local ok,reason=visit(id);if not ok then return nil,reason end end
  local pool,remaining,used,bought={},{},{},{}
  local function initialize(item)
    if pool[item]==nil then local amount=self:AvailableForPlan(item,key);pool[item]=amount;remaining[item]=amount end
  end
  for _,id in ipairs(ordered) do
    local recipe,n=records[id],plan.crafts[id]
    for _,mat in ipairs(recipe.mats) do
      local item,quantity=mat[1],mat[2]*n
      initialize(item)
      local take=math.min(pool[item],quantity)
      local own=math.min(take,remaining[item]);remaining[item]=remaining[item]-own
      used[item]=(used[item] or 0)+own;pool[item]=pool[item]-take
      if quantity>take then bought[item]=(bought[item] or 0)+quantity-take end
    end
    if recipe.outputItemID and recipe.outputMin and recipe.outputMin>0 then
      initialize(recipe.outputItemID);pool[recipe.outputItemID]=pool[recipe.outputItemID]+recipe.outputMin*n
    end
  end
  local required={}
  for id,n in pairs(used) do if n>0 then required[id]=n end end
  for id,n in pairs(bought) do required[id]=(required[id] or 0)+n end
  return {requirements=required,bought=bought,owned=used,order=ordered}
end
function CP:AuctionatorExportCard(key,owner)
  owner=owner or key
  return {title=L("Auctionator-Einkaufsliste erstellen"),
    detail=owner=="camping" and L("Nur fehlende Camping-Zutaten; Bestände werden abgezogen.")
      or L("Fehlmengen für den gewählten Skillbereich; Zwischenprodukte werden verrechnet."),
    footer=L("Manuelle Schritte oder Auto-Route exportieren. Ohne Schritte wird die Auto-Route erstellt."),color="gold",
    action=function() CP:ExportToAuctionator(owner);CP:Render() end}
end
function CP:ExportToAuctionator(owner)
  local api=_G.Auctionator and Auctionator.API and Auctionator.API.v1
  if not api or type(api.CreateShoppingList)~="function" or type(api.ConvertToSearchString)~="function" then
    self:Say(L("Auctionator-Einkaufslisten-API fehlt. Bitte eine kompatible Auctionator-Version aktivieren."));return false,"api"
  end
  self:InvalidateReservations()
  local missing={};local name="CraftPilot - "
  if owner=="camping" then
    local plan=self:CampingShopping()
    if plan.unknown>0 then self:Say(L("Export gestoppt: Materialdaten fehlen."));return false,"materials" end
    for _,mat in ipairs(plan.materials) do if mat.missing>0 then missing[mat.id]=mat.missing end end
    name=name..L("Camping")
  else
    local plan=self:PlanFor(owner)
    if not plan then return false,"plan" end
    if not plan.autoMode and not next(plan.crafts) then
      local ok,reason=self:BuildRouteForCurrentPlan(owner)
      if not ok then self:Say(reason or L("Auto-Route nicht verfügbar."));return false,"route" end
    elseif self:PlanNeedsReview(owner) and not self:ReevaluatePlan(owner) then return false,"review" end
    if plan.autoMode then
      -- Always rebuild from the selected range so changed inventory and intermediates are reflected.
      local ok,route=self:BuildRouteForCurrentPlan(owner)
      if not ok or route.blocked or route.reached<plan.target then
        self:Say(L("Export gestoppt: Auto-Route erreicht den Zielskill nicht. Bereich oder Rezeptdaten prüfen."));return false,"incomplete"
      end
      for _,mat in ipairs(route.materials) do if mat.missing>0 then missing[mat.id]=mat.missing end end
    else
      local resolved,reason=self:ResolveManualPlan(owner)
      if not resolved then
        self:Say(L("Export gestoppt: Materialien, Ausbeute oder Herstellungskette ungeklärt. Berufsfenster aktualisieren."));return false,reason
      end
      missing=resolved.bought
    end
    name=name..self.Data.professions[owner].name.." "..plan.start.."-"..plan.target
  end
  local ids={};for id,n in pairs(missing) do if n>0 then ids[#ids+1]=id end end;table.sort(ids)
  local terms,names={},{}
  for _,id in ipairs(ids) do
    local itemName=self:ItemName(id)
    if itemName=="Item #"..id or (names[itemName] and names[itemName]~=id) then
      self:MarketItemData(id);self:Say(L("Export gestoppt: Gegenstandsname fehlt oder ist nicht eindeutig. Nach dem Laden erneut versuchen."));return false,"name"
    end
    names[itemName]=id
    local ok,term=pcall(api.ConvertToSearchString,"CraftPilot",{searchString=itemName,isExact=true,quantity=math.ceil(missing[id])})
    if not ok or type(term)~="string" or term=="" then self:Say(L("Auctionator konnte einen Suchbegriff nicht erstellen."));return false,"convert" end
    terms[#terms+1]=term
  end
  local ok,result=pcall(api.CreateShoppingList,"CraftPilot",name,terms)
  if not ok or result==false then self:Say(L("Auctionator-Liste konnte nicht erstellt werden."));return false,"create" end
  self:StampPlan(owner)
  if #terms==0 then
    self:Say(L("Keine Fehlmengen: die gleichnamige CraftPilot-Liste in Auctionator ist jetzt leer."))
    return true,name,terms
  end
  self:Say(L("An Auctionator übergeben: ")..name..L(" · Positionen: ")..#terms..L(". Gleiche CraftPilot-Liste wird ersetzt; Kauf bleibt manuell."))
  return true,name,terms
end
