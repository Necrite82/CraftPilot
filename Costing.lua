-- A single read-only cost model and flat cost-calculation window.
local _,CP=...
local L=CP.L
function CP:InitializeCostingState()
  for _,plan in pairs(self.db.plans) do
    if type(plan)=="table" and plan.autoRoute and (type(plan.autoRoute)~="table" or type(plan.autoRoute.ownedMaterials)~="table") then
      plan.autoRoute=nil;plan.autoMode=nil
    end
  end
end
local function add(out,id,n)
  if type(id)=="number" and type(n)=="number" and n>0 then out[id]=(out[id] or 0)+n end
end
function CP:CalculateMaterialCosts(requirements,fee,feeUnknown,owner)
  local cut=math.max(0,math.min(30,tonumber(self.db.ui.economyCut) or 5))/100
  local result={buy=0,fee=fee or 0,stockValue=0,missingBuy=0,missingStock=0,feeUnknown=feeUnknown==true,
    stale=0,unknownAge=0,unknownBank=0,materials={},cut=cut}
  for id,quantity in pairs(requirements or {}) do
    local available,bag,bank,live,known,reserved
    if owner then available,bag,bank,live,known,reserved=self:AvailableForPlan(id,owner)
    else available,bag,bank,live,known=self:ItemAvailability(id) end
    local used=math.min(quantity,available)
    local missing=quantity-used
    local price=self:PriceDetails(id)
    local net=price.auction and math.floor(price.auction*(1-cut))
    if missing>0 then
      if price.price then result.buy=result.buy+missing*price.price else result.missingBuy=result.missingBuy+1 end
    end
    if used>0 then
      if net then result.stockValue=result.stockValue+used*net else result.missingStock=result.missingStock+1 end
    end
    local ahRelevant=(missing>0 and price.source=="Auctionator") or (used>0 and net~=nil)
    if ahRelevant then
      if price.ageDays==nil then result.unknownAge=result.unknownAge+1
      elseif price.ageDays>3 then result.stale=result.stale+1 end
    end
    if self.db.includeBank and not known then result.unknownBank=result.unknownBank+1 end
    result.materials[#result.materials+1]={id=id,quantity=quantity,used=used,missing=missing,bag=bag,bank=bank,
      reserved=reserved or 0,bankKnown=known,buy=price.price and missing*price.price,stock=net and used*net}
  end
  table.sort(result.materials,function(a,b) return a.id<b.id end)
  result.cash=result.buy+result.fee
  result.economic=result.cash+result.stockValue
  result.cashComplete=result.missingBuy==0 and not result.feeUnknown
  result.economicComplete=result.cashComplete and result.missingStock==0
  return result
end
local function recipeData(self,key,id)
  local native=(self.db.recipes[key] or {})[id]
  local catalog=self:RecipeVendorCatalog(key)
  local reference=catalog and catalog.recipes[id]
  local displayName
  if not reference then
    for _,row in ipairs(self:CampingRecipes(key)) do
      if row.id==id then reference=row.recipe or {mats=row.mats};displayName=row.name;break end
    end
  end
  return native,reference,displayName
end
function CP:CostRecipeData(key,id) return recipeData(self,key,id) end
function CP:RecipeAcquisitionCost(key,id,owner)
  local native,reference=recipeData(self,key,id)
  if native and native.learned then return 0,false end
  if not reference then return 0,true end
  local bookStock=reference.item and (owner and self:AvailableForPlan(reference.item,owner) or self:ItemAvailability(reference.item)) or 0
  if reference.item and bookStock>0 then return 0,false,nil,false,reference.item end
  local trainerFee,guessed,eligible=self:TrainerRecipeFee(key,id)
  local cheapest=eligible and not guessed and trainerFee or nil
  for _,vendor in ipairs(self:RecipeVendors(key,id)) do
    if vendor.cost and (not cheapest or vendor.cost<cheapest) then cheapest=vendor.cost end
  end
  if reference.item then
    local market=self:PriceDetails(reference.item)
    if market.auction and (not cheapest or market.auction<cheapest) then
      return market.auction,false,market.ageDays,true
    end
  end
  for _,source in ipairs(reference.get or {}) do
    if source.kind=="start" then cheapest=0 end
  end
  return cheapest or 0,cheapest==nil
end
function CP:CostCalculation(kind,key,id,quantity)
  local owner=kind=="camping" and "camping" or key
  local required,unknown={},0
  local fee,feeUnknown=0,false
  local title=self.Data.professions[key] and self.Data.professions[key].name or "CraftPilot"
  local sale,points,saleBlocked=0,nil,false
  local feeStale,feeUndated=0,0
  local fees={}
  local function includeFee(profession,recipeID)
    local marker=profession..":"..recipeID
    if fees[marker] then return end
    fees[marker]=true
    local amount,missing,age,auction,book=self:RecipeAcquisitionCost(profession,recipeID,owner)
    fee=fee+amount;feeUnknown=feeUnknown or missing
    if book then add(required,book,1) end
    if auction then
      if age==nil then feeUndated=feeUndated+1 elseif age>3 then feeStale=feeStale+1 end
    end
  end
  if kind=="recipe" or kind=="economy" then
    quantity=math.max(1,math.min(999,math.floor(tonumber(quantity) or 1)))
    local native,reference,displayName=recipeData(self,key,id)
    if native and (native.learned or native.mats) then
      if native.mats then for _,mat in ipairs(native.mats) do add(required,mat[1],mat[2]*quantity) end else unknown=unknown+1 end
    elseif reference and reference.mats then for item,n in pairs(reference.mats) do add(required,item,n*quantity) end
    else unknown=unknown+1 end
    title=quantity.."x "..self:RecipeName(key,id,displayName or (reference and reference.name))
    includeFee(key,id)
    if kind=="economy" then
      for _,row in ipairs(self:EconomyComparison(key).rows) do
        if row.id==id then
          points=row.chance*quantity
          -- Preserve only the exactly compared integer batch; never scale sale stock beyond ownership.
          if quantity==row.crafts and row.reliable then for _,item in ipairs(row.preserve) do sale=sale+item.net end
          elseif not row.reliable then saleBlocked=true end
          break
        end
      end
    end
  elseif kind=="camping" then
    local plan=self:CampingShopping()
    title=L("Camping-Einkauf · alle Berufe")
    unknown=plan.unknown
    for _,mat in ipairs(plan.materials) do add(required,mat.id,mat.quantity) end
    for _,step in ipairs(plan.steps) do
      includeFee(step.row.prof,step.row.id)
    end
  elseif kind=="plan" then
    local route=self:AutoRouteShopping(key)
    if route then
      title=L("Gespeicherte Auto-Route")
      if type(route.ownedMaterials)=="table" then
        for _,mat in ipairs(route.materials) do add(required,mat.id,mat.missing) end
        for item,n in pairs(route.ownedMaterials) do add(required,item,n) end
      else unknown=unknown+1 end
      local recipes={}
      for _,step in ipairs(route.steps) do
        if not recipes[step.id] then
          recipes[step.id]=true
          includeFee(key,step.id)
        end
      end
    else
      local plan=self:PlanFor(key)
      local resolved=self:ResolveManualPlan(key)
      if resolved then for item,n in pairs(resolved.requirements) do add(required,item,n) end end
      for recipe,n in pairs(plan and plan.crafts or {}) do
        local native=(self.db.recipes[key] or {})[recipe]
        if native and native.mats then
          if not resolved then for _,mat in ipairs(native.mats) do add(required,mat[1],mat[2]*n) end;unknown=unknown+1 end
        else unknown=unknown+1 end
        includeFee(key,recipe)
      end
    end
  end
  local result=self:CalculateMaterialCosts(required,fee,feeUnknown,owner)
  result.title=title;result.kind=kind;result.quantity=quantity;result.sale=sale;result.points=points;result.saleBlocked=saleBlocked
  result.unknownRecipes=unknown
  if unknown>0 then result.cashComplete=false;result.economicComplete=false end
  result.stale=result.stale+feeStale;result.unknownAge=result.unknownAge+feeUndated
  result.balance=result.cash-sale
  return result
end
function CP:FormatCostMoney(value)
  local amount=math.floor(math.abs(value)+.5)
  local parts={}
  local gold,silver,copper=math.floor(amount/10000),math.floor(amount%10000/100),amount%100
  for _,entry in ipairs({{gold,"Gold"},{silver,"Silver"},{copper,"Copper"}}) do
    if entry[1]>0 or (entry[2]=="Copper" and #parts==0) then
      parts[#parts+1]=entry[1].."|TInterface\\MoneyFrame\\UI-"..entry[2].."Icon:14:14:0:0|t"
    end
  end
  return (value<0 and "-" or "")..table.concat(parts," ")
end
local function money(self,value)
  return self:FormatCostMoney(value)
end
function CP:RefreshCostWindow()
  self:InvalidateReservations();self.marketUseCache=nil
  local frame=self.costWindow
  if not frame or not frame:IsShown() or not self.costContext then return end
  local context=self.costContext
  local result=self:CostCalculation(context.kind,context.key,context.id,context.quantity)
  self.costSnapshot=result
  self:RenderCostDashboard(result,context)
end
function CP:CostSummaryCard(kind,key,id,quantity)
  local result=self:CostCalculation(kind,key,id,quantity)
  return {title=(result.cashComplete and "" or L("Bekannter Teil: "))..self:FormatCostMoney(result.cash),
    detail=L("Zusätzlich bezahlen · Rezept einmalig enthalten · Schätzung"),
    footer=L("Wirtschaftlicher Aufwand: ")..self:FormatCostMoney(result.economic)..(result.economicComplete and "" or L(" + unbekannter Anteil"))..L(" · Kalkulation öffnen"),color="gold",emphasis=true,
    action=function() CP:OpenCostCalculation(kind,key,id,quantity) end}
end
function CP:OpenCurrentCostCalculation()
  local key=self.db.view
  local tab=self.db.ui.tab
  if tab=="plan" then return self:OpenCostCalculation("plan",key) end
  if tab=="camping" then
    local selected=self.db.ui.campingRecipe
    if self.db.ui.campingPage=="buffs" then selected=self.db.ui.campingBuff end
    if self.db.ui.campingPage~="shopping" and selected then
      for _,row in ipairs(self:CampingRecipes()) do
        if row.object.item==selected then return self:OpenCostCalculation("recipe",row.prof,row.id,1) end
      end
    end
    return self:OpenCostCalculation("camping",key)
  end
  if tab=="economy" then
    for _,row in ipairs(self:EconomyComparison(key).rows) do
      if row.id==(self.db.ui.economyRecipe or self.db.ui.selectedRecipes[key]) then return self:OpenCostCalculation("economy",key,row.id,row.crafts) end
    end
  end
  if self.db.ui.selectedVendorKey==key and self.db.ui.selectedVendorRecipe then
    return self:OpenCostCalculation("recipe",key,self.db.ui.selectedVendorRecipe,1)
  end
  local chosen=self:SelectedOption(key)
  if chosen then return self:OpenCostCalculation("recipe",key,chosen.id,1) end
  self:Say(L("Rezept auswählen oder Einkaufsplan öffnen."))
end
function CP:OpenCostCalculation(kind,key,id,quantity)
  if not self.costWindow then self.costWindow=self:CreateCostDashboard() end
  self.costContext={kind=kind,key=key,id=id,quantity=quantity or 1}
  self.costWindow:Show();self:RefreshCostWindow()
end
