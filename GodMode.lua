-- CraftPilot opportunity-cost comparison of current learned recipes.
local _,CP=...
local L=CP.L
local function settings(self)
  local ui=self.db.ui
  local cut=tonumber(ui.godCut)
  if not cut or cut~=cut then cut=5 end
  return math.max(0,math.min(30,cut))/100
end

function CP:GodModeComparison(key)
  local rows={}
  local cut=settings(self)
  local profession=self.db.professions[key]
  if profession and profession.cap and profession.skill>=profession.cap then return {rows=rows,cut=cut} end
  for _,option in ipairs(self:Options(key)) do
    local crafts=math.max(1,math.ceil(1/option.chance))
    local row={id=option.id,name=self:RecipeName(key,option.id,option.name),crafts=crafts,
      points=crafts*option.chance,chance=option.chance,buy=0,ownedValue=0,
      unknown=0,uncertain=0,materials={},used={}}
    local aggregate={}
    for _,mat in ipairs(option.mats) do aggregate[mat[1]]=(aggregate[mat[1]] or 0)+mat[2]*crafts end
    for id,quantity in pairs(aggregate) do
      local stock=self:ItemAvailability(id)
      local used=math.min(stock,quantity)
      local missing=quantity-used
      local p=self:PriceDetails(id)
      local net=p.auction and math.floor(p.auction*(1-cut)) or nil
      local value=net and used*net or nil
      if missing>0 then
        if p.price then row.buy=row.buy+missing*p.price else row.unknown=row.unknown+1 end
        if p.source=="Auctionator" and (p.ageDays==nil or p.ageDays>3) then row.uncertain=row.uncertain+1 end
      end
      if used>0 then
        if value then row.ownedValue=row.ownedValue+value else row.unknown=row.unknown+1 end
        if net and (p.ageDays==nil or p.ageDays>3) then row.uncertain=row.uncertain+1 end
      end
      row.used[id]=used
      row.materials[#row.materials+1]={id=id,quantity=quantity,used=used,missing=missing,
        price=p.price,net=net,age=p.ageDays}
    end
    row.value=(row.buy+row.ownedValue)/row.points
    row.cash=row.buy/row.points
    table.sort(row.materials,function(a,b) return a.id<b.id end)
    rows[#rows+1]=row
  end
  -- Baseline is the cash-cheapest usable batch; unknown purchase prices cannot win.
  local baseline
  for _,row in ipairs(rows) do
    local unpriced=false
    for _,mat in ipairs(row.materials) do if mat.missing>0 and not mat.price then unpriced=true end end
    if not unpriced and (not baseline or row.cash<baseline.cash or (row.cash==baseline.cash and row.id<baseline.id)) then baseline=row end
  end
  table.sort(rows,function(a,b)
    if a.unknown~=b.unknown then return a.unknown<b.unknown end
    if a.uncertain~=b.uncertain then return a.uncertain<b.uncertain end
    if a.value~=b.value then return a.value<b.value end
    return a.id<b.id
  end)
  for _,row in ipairs(rows) do
    row.preserve={}
    if baseline then
      row.advantage=baseline.value-row.value
      row.reliable=row.unknown==0 and row.uncertain==0 and baseline.unknown==0 and baseline.uncertain==0
      for _,mat in ipairs(baseline.materials) do
        local released=math.max(0,mat.used-(row.used[mat.id] or 0))
        if released>0 and mat.net then row.preserve[#row.preserve+1]={id=mat.id,quantity=released,net=mat.net*released} end
      end
    end
  end
  return {rows=rows,baseline=baseline,cut=cut}
end

function CP:ChooseGodRecipe(key,id)
  for _,row in ipairs(self:GodModeComparison(key).rows) do
    if row.id==id then
      self.db.ui.selectedRecipes[key]=id
      self.db.ui.godRecipe=id
      -- Only replace the proposal after an explicit choice; existing manual plans remain intact.
      return true
    end
  end
  return false
end

function CP:ApplyGodPlan(key,id)
  local chosen
  for _,row in ipairs(self:GodModeComparison(key).rows) do if row.id==id then chosen=row;break end end
  if not chosen then return false end
  local plan=self:PlanFor(key)
  if not plan then return false end
  local previous={crafts=plan.crafts,start=plan.start,target=plan.target,autoMode=plan.autoMode,autoRoute=plan.autoRoute}
  plan.crafts={}
  if not self:AddPlanCraft(key,id,chosen.crafts) then plan.crafts=previous.crafts;return false end
  plan.godPrevious=previous
  plan.autoRoute=nil
  plan.start=(self.db.professions[key] or {}).skill or plan.start
  plan.target=math.min(300,plan.start+math.ceil(chosen.points))
  return true
end

function CP:UndoGodPlan(key)
  local plan=self:PlanFor(key)
  local previous=plan and plan.godPrevious
  if not previous then return false end
  for _,field in ipairs({"crafts","start","target","autoMode","autoRoute"}) do plan[field]=previous[field] end
  plan.godPrevious=nil
  return true
end

function CP:GodModeCards(key)
  local comparison=self:GodModeComparison(key)
  local cards={{title="God-Mode",detail=L("Eigene Vorräte sind nicht kostenlos: Verkauf oder andere Skillrezepte vergleichen."),
    footer=L("Nur erlernte Rezepte und aktuelle Skillfarben; keine automatischen Käufe oder Verkäufe."),color="gold"}}
  cards[#cards+1]={title=L("Vergleich für den nächsten Skillschritt"),
    detail=L("Bestehende Pläne reservieren hier keine Materialien. Keine Gesamtoptimierung bis Skill 300."),color="blue"}
  local plan=self:PlanFor(key)
  if plan and plan.godPrevious then cards[#cards+1]={title=L("Vorherigen Einkaufsplan wiederherstellen"),
    detail=L("Letzte Übernahme aus God-Mode rückgängig machen."),color="gold",
    action=function() CP:UndoGodPlan(key);CP:OpenTab("plan") end} end
  local baseline=comparison.baseline
  if not baseline then
    cards[#cards+1]={title=L("Noch kein vollständiger Vergleich"),detail=L("Eigenes Berufsfenster öffnen und AH-Preise aktualisieren."),color="gold"}
    return cards
  end
  cards[#cards+1]={title=L("Günstigster Zukauf: ")..baseline.name,
    detail=L("Zukauf je erwartetem Skillpunkt: ")..self:FormatMoney(baseline.cash),
    footer=L("Vorratswert wird beim God-Mode zusätzlich berücksichtigt."),color="blue"}
  cards[#cards+1]={title=L("AH-Abzug: ")..math.floor(comparison.cut*100+.5).."%",
    detail=L("Auktionserlös geschätzt; Verkauf, Nachfrage und Verkaufbarkeit im Spiel prüfen."),
    footer=L("Abzug in Einstellungen ändern; mögliche erfolglose Einstellgebühren sind nicht berechnet."),color="gold"}
  for _,row in ipairs(comparison.rows) do
    local id=row.id
    local selected=self.db.ui.selectedRecipes[key]==id
    local advantage=row.reliable and row.advantage>0
    cards[#cards+1]={title=(selected and L("GEWÄHLT: ") or "")..row.name,
      detail=L("Zukauf: ")..self:FormatMoney(row.buy)..L(" · Vorratswert: ")..self:FormatMoney(row.ownedValue),
      footer=advantage and (L("Vorteil je erwartetem Skillpunkt: ")..self:FormatMoney(row.advantage))
        or (row.reliable and L("Kein wirtschaftlicher Vorteil zum günstigsten Zukauf") or L("Vergleich unvollständig oder Preise nicht aktuell")),
      icon=self:RecipeIcon(key,id),color=advantage and "green" or "blue",
      action=function() CP:ChooseGodRecipe(key,id);CP:Render() end}
    if self.db.ui.godRecipe==id then
      cards[#cards+1]={title=row.crafts..L(" Herstellungen · Skillchance ")..math.floor(row.chance*100).."%",
        detail=string.format(L("Ø %.2f Skillpunkte; wirtschaftlicher Aufwand je Punkt: "),row.points)..self:FormatMoney(row.value),
        footer=L("Chancen sind Schätzwerte. Endprodukte werden nicht als Verkaufserlös angerechnet."),color="gold"}
      for _,mat in ipairs(row.preserve) do cards[#cards+1]={title=L("Statt verbrauchen: ")..mat.quantity.."x "..self:ItemName(mat.id),
        detail=L("Möglicher Nettoverkauf: ")..self:FormatMoney(mat.net),
        footer=L("Nur gegenüber der Zukauf-Variante freigewordene Mengen; Bestände werden nicht verändert."),tooltipItem=mat.id,color="green"} end
      for _,mat in ipairs(row.materials) do cards[#cards+1]={title=mat.quantity.."x "..self:ItemName(mat.id),
        detail=L("Aus Vorrat: ")..mat.used..L(" · Kaufen: ")..mat.missing,
        footer=mat.missing>0 and (mat.price and self:FormatMoney(mat.price*mat.missing) or L("Preis fehlt")) or L("Kein Zukauf"),
        tooltipItem=mat.id,color="blue"} end
      cards[#cards+1]={title=L("Diese Variante als Einkaufsplan übernehmen"),detail=row.crafts.."x "..row.name,
        footer=L("Ersetzt den aktuellen Plan; im God-Mode einmal rückgängig machbar."),color="gold",
        action=function() if CP:ApplyGodPlan(key,id) then CP:OpenTab("plan") end end}
    end
  end
  return cards
end
