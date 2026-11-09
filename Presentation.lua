-- Shared original layout primitives. Display only; no crafting or market actions.
local _,CP=...
local L=CP.L
local bg={bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}
function CP:StyleActionButton(b)
  b:SetBackdrop(bg);b:SetBackdropColor(.075,.115,.15,1);b:SetBackdropBorderColor(.28,.4,.5,1)
  local label=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");label:SetAllPoints(b);label:SetJustifyH("CENTER");label:SetWordWrap(false);b:SetFontString(label);b:SetNormalFontObject("GameFontNormalSmall");b:SetHighlightFontObject("GameFontHighlightSmall");b:SetDisabledFontObject("GameFontDisableSmall")
  b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local h=b:GetHighlightTexture();if h then h:SetVertexColor(.35,.55,.75,.16) end
end
function CP:RenderCheckbox(b,spec,width)
  if not rawget(b,"settingCheck") then
    local check=CreateFrame("CheckButton",nil,b,"BackdropTemplate")
    check:SetSize(20,20);check:SetPoint("TOPRIGHT",b,"TOPRIGHT",-12,-9);check:SetBackdrop(bg)
    check:SetBackdropColor(.03,.06,.08,1);check:SetBackdropBorderColor(.4,.55,.65,1)
    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetScript("OnClick",function(c) local current=c.craftCheckSpec;current.apply(not current.checked) end)
    b.settingCheck=check
  end
  b.settingCheck.craftCheckSpec=spec;b.settingCheck:SetChecked(spec.checked);b.settingCheck:Show()
  b.titleLabel:SetWidth(width-100)
end
function CP:CreateFlatAction(parent,width,height,action)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  b:SetSize(width,height);b:SetBackdrop(bg);b:SetBackdropColor(.045,.07,.095,.98);b:SetBackdropBorderColor(.18,.25,.32,1)
  b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local highlight=b:GetHighlightTexture();if highlight then highlight:SetVertexColor(.3,.45,.6,.12) end
  b:SetScript("OnClick",action);return b
end
function CP:DisplayLabel(parent,font,x,y,w,value,align)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);t:SetWidth(w);t:SetJustifyH(align or "LEFT");t:SetText(value or "")
  return t
end
local function height(text,fallback)
  local n=text:GetStringHeight();return type(n)=="number" and n>0 and n or fallback
end
function CP:DisplayMoney(n) return n~=nil and self:FormatCostMoney(n) or "—" end
function CP:MetricStrip(parent,values,x,y,width)
  parent.metricPanels=rawget(parent,"metricPanels") or {}
  local w=(width-16)/3
  for i=1,3 do
    local p=parent.metricPanels[i]
    if not p then
      p=CreateFrame("Frame",nil,parent,"BackdropTemplate");p:SetBackdrop(bg);p:SetBackdropColor(.055,.085,.11,.95);p:SetBackdropBorderColor(.16,.22,.28,1)
      p.label=self:DisplayLabel(p,"GameFontDisableSmall",10,7,w-20,"")
      p.value=self:DisplayLabel(p,"GameFontNormal",10,24,w-20,"")
      parent.metricPanels[i]=p
    end
    p:ClearAllPoints();p:SetPoint("TOPLEFT",parent,"TOPLEFT",x+(i-1)*(w+8),-y);p:SetSize(w,48)
    p.label:SetWidth(w-20);p.value:SetWidth(w-20)
    p.label:SetText(values[i].label);p.value:SetText(values[i].value)
    p.value:SetFontObject(values[i].emphasis and "GameFontNormalLarge" or "GameFontNormal")
    p.value:SetTextColor((unpack or table.unpack)(values[i].color or {1,.84,.46}));p:Show()
  end
end
function CP:ShowCraftTooltip(owner,key,id,item)
  local tip=GameTooltip;if not tip then return end
  tip:SetOwner(owner,"ANCHOR_RIGHT");tip:ClearLines()
  local shown=false
  if id and C_TradeSkillUI and type(C_TradeSkillUI.GetRecipeOutputItemData)=="function" and type(tip.SetHyperlink)=="function" then
    local ok,data=pcall(C_TradeSkillUI.GetRecipeOutputItemData,id)
    if ok and type(data)=="table" and type(data.hyperlink)=="string" then shown=pcall(tip.SetHyperlink,tip,data.hyperlink) end
  end
  if not shown and id and type(tip.SetSpellByID)=="function" then shown=pcall(tip.SetSpellByID,tip,id) end
  item=item or (id and self:RecipeMarketOutput(key,id))
  if not shown and item and type(tip.SetItemByID)=="function" then shown=pcall(tip.SetItemByID,tip,item) end
  if not shown then tip:AddLine(id and self:RecipeName(key,id) or self:ItemName(item)) end
  tip:AddLine(" ");tip:AddLine("CraftPilot",1,.8,.35)
  if id then
    local c=self:CostCalculation("recipe",key,id,self:RequestedRecipeQuantity(key,id))
    tip:AddDoubleLine(L("Zukauf / Herstellung"),self:DisplayMoney(c.buy),.8,.85,.9,1,.8,.35)
    if c.fee>0 or c.feeUnknown then tip:AddDoubleLine(L("Lernen · einmalig"),c.feeUnknown and L("unbekannt") or self:DisplayMoney(c.fee)) end
    tip:AddLine(" ");tip:AddDoubleLine(L("Material"),L("Bedarf · Tasche · Bank · Kaufen"),1,.8,.35,1,.8,.35)
    for _,mat in ipairs(c.materials) do
      tip:AddDoubleLine(self:ItemName(mat.id),string.format("%d · %d · %s · %d",mat.quantity,mat.bag,mat.bankKnown and tostring(mat.bank) or "?",mat.missing),.8,.85,.9,.8,.85,.9)
    end
  end
  if item then
    local m=self:ItemMarket(item)
    tip:AddLine(" ");tip:AddDoubleLine(L("AH / Stück"),self:DisplayMoney(m.auction))
    tip:AddDoubleLine(L("AH netto / Stück"),self:DisplayMoney(not m.bound and m.net or nil))
    tip:AddDoubleLine(L("Händler / Stück"),self:DisplayMoney(m.vendor));tip:AddLine(m.advice,.65,.85,.75,true)
    tip:AddLine(self:PriceFreshness(item),.65,.7,.75,true)
  end
  tip:Show()
end
function CP:DrawMaterialTable(parent,rows,width,outputs)
  local ordered={};for _,row in ipairs(rows) do ordered[#ordered+1]=row end
  table.sort(ordered,function(a,b)
    if not outputs and ((a.missing or 0)>0)~=((b.missing or 0)>0) then return (a.missing or 0)>0 end
    local an,bn=a.name or CP:ItemName(a.id),b.name or CP:ItemName(b.id)
    if an~=bn then return an<bn end;return a.id<b.id
  end)
  rows=ordered;parent.displayRows=ordered
  parent.tableHeaders=rawget(parent,"tableHeaders") or {};parent.tableRows=rawget(parent,"tableRows") or {}
  local columns=outputs and {{L("Ergebnis"),.43},{L("AH / Stück"),.19},{L("AH netto / Stück"),.19},{L("Händler / Stück"),.19}}
    or {{L("Material"),.37},{L("Bedarf"),.09},{L("Tasche"),.09},{L("Bank"),.09},{L("Kaufen"),.09},{L("AH/St."),.135},{L("Zukauf"),.135}}
  for _,h in ipairs(parent.tableHeaders) do h:Hide() end
  local x=8
  for i,c in ipairs(columns) do
    local h=parent.tableHeaders[i] or self:DisplayLabel(parent,"GameFontNormalSmall",0,0,50,"");parent.tableHeaders[i]=h
    h:ClearAllPoints();h:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-4);h:SetWidth(width*c[2]-8);h:SetJustifyH(i==1 and "LEFT" or "RIGHT");h:SetText(c[1]);h:Show();x=x+width*c[2]
  end
  for _,r in ipairs(parent.tableRows) do r:Hide() end
  local y=28
  for i,mat in ipairs(rows) do
    local r=parent.tableRows[i]
    if not r then
      r=CreateFrame("Button",nil,parent,"BackdropTemplate");r:SetBackdrop(bg);r:SetBackdropBorderColor(.12,.18,.23,1)
      r.cells={};r.note=self:DisplayLabel(r,"GameFontDisableSmall",8,32,width-16,"")
      r:SetScript("OnEnter",function() CP:ShowCraftTooltip(r,r.recipeKey,r.recipeID,r.itemID) end)
      r:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
      parent.tableRows[i]=r
    end
    r.itemID=mat.id;r.recipeKey=mat.key;r.recipeID=mat.recipeID
    local m=self:ItemMarket(mat.id)
    local values=outputs and {mat.name or self:ItemName(mat.id),self:DisplayMoney(m.auction),self:DisplayMoney(not m.bound and m.net or nil),self:DisplayMoney(m.vendor)}
      or {mat.name or self:ItemName(mat.id),mat.quantity or mat.required or 0,mat.bag or 0,mat.bankKnown and mat.bank or "?",mat.missing or 0,self:DisplayMoney(m.auction),mat.missing==0 and self:DisplayMoney(0) or self:DisplayMoney(mat.buy or mat.cost)}
    if C_Item and type(C_Item.GetItemIconByID)=="function" then
      local ok,icon=pcall(C_Item.GetItemIconByID,mat.id)
      if ok and icon then values[1]="|T"..icon..":18|t "..values[1] end
    end
    x=8
    for j,c in ipairs(columns) do
      local t=r.cells[j] or self:DisplayLabel(r,"GameFontHighlightSmall",0,0,50,"");r.cells[j]=t
      t:ClearAllPoints();t:SetPoint("TOPLEFT",r,"TOPLEFT",x,-9);t:SetWidth(width*c[2]-8);t:SetJustifyH(j==1 and "LEFT" or "RIGHT");t:SetText(tostring(values[j]))
      t:SetTextColor(1,1,1);if not outputs and j==5 then t:SetTextColor(mat.missing>0 and 1 or .4,mat.missing>0 and .55 or .9,.5) end
      if ((not outputs and j==6) or (outputs and j==2)) and m.auction and not m.fresh then t:SetTextColor(1,.65,.3) end
      t:Show();x=x+width*c[2]
    end
    for j=#columns+1,#r.cells do r.cells[j]:Hide() end
    local titleHeight=height(r.cells[1],16)
    local noteY=math.max(32,14+titleHeight)
    r.note:ClearAllPoints();r.note:SetPoint("TOPLEFT",r,"TOPLEFT",8,-noteY);r.note:SetWidth(width-16)
    local reserved=(mat.reserved or 0)>0 and (L("Reserviert für andere Pläne: ")..mat.reserved.." · ") or ""
    r.note:SetText(reserved..m.advice)
    local h=noteY+height(r.note,16)+10
    r:ClearAllPoints();r:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-y);r:SetSize(width,h);r:SetBackdropColor(i%2==0 and .065 or .045,.085,.11,.9);r:Show();y=y+h+4
  end
  parent:SetSize(width,math.max(30,y));return y
end
function CP:RecipeDisplayData(key,id)
  local c=self:CostCalculation("recipe",key,id,self:RequestedRecipeQuantity(key,id))
  local output=self:RecipeMarketOutput(key,id)
  local m=output and self:ItemMarket(output) or nil
  local bag,bank,buy=0,0,0
  local unknown=false
  for _,mat in ipairs(c.materials) do
    local fromBag=math.min(mat.used,mat.bag);bag=bag+fromBag;bank=bank+mat.used-fromBag;buy=buy+mat.missing
    unknown=unknown or not mat.bankKnown
  end
  return {cost=c,market=m,bag=bag,bank=bank,buy=buy,bankUnknown=unknown}
end
function CP:LayoutRecipeCard(b,key,entry,width)
  local d=self:RecipeDisplayData(key,entry.id)
  if not entry.vendorRecipe and not entry.referenceOnly then
    b.infoLabel:SetText(CP:RecipeColorLabel(key,entry.id).." · "..string.format(L("Skillchance ca. %.0f%%"),(entry.chance or 0)*100))
  end
  b.stockLabel:Hide();b.marketLabel:Hide()
  b.nameLabel:SetWidth(width-182);b.infoLabel:SetWidth(width-60)
  local infoY=math.max(30,13+height(b.nameLabel,16))
  b.infoLabel:ClearAllPoints();b.infoLabel:SetPoint("TOPLEFT",b,"TOPLEFT",48,-infoY)
  local metricY=math.max(57,infoY+height(b.infoLabel,16)+10)
  b.rangeLabel:ClearAllPoints();b.rangeLabel:SetPoint("TOPLEFT",b,"TOPLEFT",48,-(metricY+81));b.rangeLabel:SetWidth(width-60)
  b.stockSummary=rawget(b,"stockSummary") or self:DisplayLabel(b,"GameFontHighlightSmall",48,116,width-60,"")
  b.stockSummary:SetWidth(width-60)
  b.stockSummary:ClearAllPoints();b.stockSummary:SetPoint("TOPLEFT",b,"TOPLEFT",48,-(metricY+58))
  b.stockSummary:SetText(string.format(L("Vorrat genutzt (Einheiten)   Tasche %d    Bank %s    Zukauf %d"),d.bag,not self.db.includeBank and L("aus") or (d.bankUnknown and "?" or tostring(d.bank)),d.buy))
  local learning=entry.vendorRecipe and not entry.referenceOnly
  self:MetricStrip(b,{{label=string.format(L("Zukauf für %dx"),self:RequestedRecipeQuantity(key,entry.id))..(learning and L(" + Lernen") or ""),
      value=(learning and d.cost.cashComplete or (not learning and d.cost.missingBuy==0 and d.cost.unknownRecipes==0))
        and self:DisplayMoney(learning and d.cost.cash or d.cost.buy) or L("unvollständig")},
    {label=L("AH netto / Ergebnisstück"),value=self:DisplayMoney(d.market and not d.market.bound and d.market.net or nil),color={.55,.9,.7}},
    {label=L("Händler / Ergebnisstück"),value=self:DisplayMoney(d.market and d.market.vendor)}},48,metricY,width-60)
  b:SetScript("OnEnter",function() CP:ShowCraftTooltip(b,key,entry.id) end)
  local rh=height(b.rangeLabel,16);local h=math.max(164,metricY+86+rh)
  if not entry.referenceOnly then h=self:QuantityControl(b,key,entry.id,entry.active,h,width)
  elseif rawget(b,"quantityLabel") then b.quantityLabel:Hide();b.quantityInput:Hide();b.quantityReset:Hide();b.quantityCaption:Hide();b.followupNote:Hide() end
  b:SetHeight(h);if b.craftStripe then b.craftStripe:SetHeight(h-12) end
  return h
end
function CP:LayoutVisualCard(b,entry,width)
  b:SetScript("OnEnter",nil)
  b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  if rawget(b,"dataTable") then b.dataTable:Hide() end
  if entry.materialTable or entry.productionRows then
    for _,name in ipairs({"titleLabel","detailLabel","footLabel","marketLabel","craftIcon","craftStripe","craftDot"}) do if rawget(b,name) then b[name]:Hide() end end
    for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
    b.dataTable=rawget(b,"dataTable") or CreateFrame("Frame",nil,b)
    b.dataTable:ClearAllPoints();b.dataTable:SetPoint("TOPLEFT",b,"TOPLEFT",0,-2);b.dataTable:Show()
    for _,name in ipairs({"tableHeaders","tableRows","productionHeaders","productionRows"}) do for _,part in ipairs(rawget(b.dataTable,name) or {}) do part:Hide() end end
    if entry.productionRows then return self:DrawProductionTable(b.dataTable,entry.productionRows,entry.recipeKey,width),true end
    return self:DrawMaterialTable(b.dataTable,entry.materialTable,width),true
  end
  for _,name in ipairs({"titleLabel","detailLabel","footLabel","craftIcon","craftStripe","craftDot"}) do if rawget(b,name) then b[name]:Show() end end
  b.marketLabel:Hide()
  local y=math.max(30,10+height(b.titleLabel,16))
  b.detailLabel:ClearAllPoints();b.detailLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-y);b.detailLabel:SetWidth(width-70)
  y=y+height(b.detailLabel,16)+10
  if entry.recipeID or entry.tooltipItem then
    local item=entry.tooltipItem or self:RecipeMarketOutput(entry.recipeKey or self.db.view,entry.recipeID)
    local m=item and self:ItemMarket(item)
    self:MetricStrip(b,{{label=L("AH / Stück"),value=self:DisplayMoney(m and m.auction)},
      {label=L("AH netto / Stück"),value=self:DisplayMoney(m and not m.bound and m.net or nil),color={.55,.9,.7}},
      {label=L("Händler / Stück"),value=self:DisplayMoney(m and m.vendor)}},55,y,width-70)
    y=y+58
    b.marketLabel:ClearAllPoints();b.marketLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-y);b.marketLabel:SetWidth(width-70)
    b.marketLabel:SetText(m and m.advice or L("Kein handelbares Ergebnis zugeordnet"));b.marketLabel:Show();y=y+height(b.marketLabel,16)+8
    b:SetScript("OnEnter",function() CP:ShowCraftTooltip(b,entry.recipeKey or CP.db.view,entry.recipeID,item) end)
  else
    for _,p in ipairs(rawget(b,"metricPanels") or {}) do p:Hide() end
    if entry.tooltipSpell then b:SetScript("OnEnter",function()
      if not GameTooltip then return end
      GameTooltip:SetOwner(b,"ANCHOR_RIGHT");if type(GameTooltip.SetSpellByID)=="function" then pcall(GameTooltip.SetSpellByID,GameTooltip,entry.tooltipSpell) end;GameTooltip:Show()
    end) end
  end
  b.footLabel:ClearAllPoints();b.footLabel:SetPoint("TOPLEFT",b,"TOPLEFT",55,-y);b.footLabel:SetWidth(width-70)
  return y+height(b.footLabel,14)+12
end
function CP:CostOutputRows(context)
  local rows,seen={},{}
  local function add(key,id)
    local output=self:RecipeMarketOutput(key,id)
    if output and not seen[output] then rows[#rows+1]={id=output,key=key,recipeID=id,name=self:RecipeName(key,id)};seen[output]=true end
  end
  if context.kind=="plan" then
    local p=self:PlanFor(context.key)
    if p.autoMode and p.autoRoute then for _,s in ipairs(p.autoRoute.intermediates or {}) do add(s.key or context.key,s.id) end
    else for id in pairs(p.crafts) do add(context.key,id) end end
  elseif context.kind=="camping" then for _,s in ipairs(self:CampingShopping().steps) do add(s.row.prof,s.row.id) end
  else add(context.key,context.id) end
  table.sort(rows,function(a,b) return a.name<b.name end);return rows
end
function CP:RenderCostDashboard(result,context)
  local f=self.costWindow
  f.caption:SetText(result.title)
  self:CostQuantityControls(f,context)
  local metricY=math.max(72,49+height(f.caption,16)+10)
  self:MetricStrip(f,{{label=L("Material-Zukauf"),value=self:DisplayMoney(result.buy)},
    {label=L("Lernen · einmalig"),value=self:DisplayMoney(result.fee)..(result.feeUnknown and " + ?" or "")},
    {label=L("JETZT BEZAHLEN"),value=(result.cashComplete and "" or L("Ab "))..self:DisplayMoney(result.cash),emphasis=true}},22,metricY,756)
  f.total=f.metricPanels[3].value
  f.notice:ClearAllPoints();f.notice:SetPoint("TOPLEFT",f,"TOPLEFT",22,-(metricY+58))
  f.notice:SetText(result.cashComplete and L("Zukauf und Lernkosten · Erlöse sind keine verfügbaren Einkaufsmittel") or L("Unvollständige Kalkulation · unbekannte Angaben sind keine Nullkosten"))
  if result.stale>0 or result.unknownAge>0 then
    f.notice:SetText((result.cashComplete and L("Zukauf und Lernkosten") or L("Unvollständige Kalkulation"))..L(" · AH-Preisstand prüfen"))
  end
  if result.unknownBank>0 then f.notice:SetText(L("Bankdaten unvollständig · nur erfasste Vorräte eingerechnet. AH-Werte sind Scanpreise.")) end
  f.scroll:ClearAllPoints();f.scroll:SetPoint("TOPLEFT",f,"TOPLEFT",22,-(metricY+68+height(f.notice,16)));f.scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-44,74)
  local list=f.list;list.sections=rawget(list,"sections") or {};list.summary=rawget(list,"summary") or {}
  local y=0
  local function section(index,label)
    local t=list.sections[index] or CP:DisplayLabel(list,"GameFontNormal",0,0,730,"");list.sections[index]=t
    t:ClearAllPoints();t:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y);t:SetText(label);y=y+30
  end
  section(1,L("Kosten einordnen"))
  local summaries={{L("Verbrauchte Vorräte · Netto-AH-Wert"),self:DisplayMoney(result.stockValue)..(result.missingStock>0 and " + ?" or "")},
    {L("Wirtschaftlicher Aufwand · kein zusätzlicher Zukauf"),self:DisplayMoney(result.economic)..(result.economicComplete and "" or " + ?")}}
  if result.sale>0 then
    summaries[#summaries+1]={L("Freigesetzte Vorräte · möglicher Nettoverkauf"),self:DisplayMoney(result.sale)}
    summaries[#summaries+1]={L("Saldo nach möglichem Verkauf"),self:DisplayMoney(result.balance)}
  end
  if result.points and result.points>0 then summaries[#summaries+1]={L("Aufwand / erwarteter Skillpunkt"),self:DisplayMoney(result.economic/result.points)..(result.economicComplete and "" or " + ?")} end
  for _,r in ipairs(list.summary) do r.label:Hide();r.value:Hide() end
  for i,entry in ipairs(summaries) do
    local r=list.summary[i] or {label=self:DisplayLabel(list,nil,0,0,490,""),value=self:DisplayLabel(list,"GameFontHighlight",510,0,220,"","RIGHT")};list.summary[i]=r
    r.label:ClearAllPoints();r.label:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y);r.label:SetText(entry[1]);r.label:Show()
    r.value:ClearAllPoints();r.value:SetPoint("TOPLEFT",list,"TOPLEFT",510,-y);r.value:SetText(entry[2]);r.value:Show();y=y+math.max(24,height(r.label,16)+6)
  end
  y=y+16;section(2,L("Ergebnisse · Verkaufswerte pro Stück"))
  f.outputs=rawget(f,"outputs") or CreateFrame("Frame",nil,list);f.outputs:ClearAllPoints();f.outputs:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y)
  local outputs=self:CostOutputRows(context)
  y=y+self:DrawMaterialTable(f.outputs,outputs,730,true)+16
  f.noOutput=rawget(f,"noOutput") or self:DisplayLabel(list,"GameFontDisableSmall",0,0,730,"")
  f.noOutput:SetShown(#outputs==0)
  if #outputs==0 then f.noOutput:ClearAllPoints();f.noOutput:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y);f.noOutput:SetText(L("Kein handelbares Ergebnis zugeordnet"));y=y+30 end
  section(3,L("Materialien · Bedarf und Fehlmengen"))
  f.materialTable=rawget(f,"materialTable") or CreateFrame("Frame",nil,list);f.materialTable:ClearAllPoints();f.materialTable:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y)
  local rows={};for _,m in ipairs(result.materials) do rows[#rows+1]=m end
  table.sort(rows,function(a,b) if (a.missing>0)~=(b.missing>0) then return a.missing>0 end;return CP:ItemName(a.id)<CP:ItemName(b.id) end)
  y=y+self:DrawMaterialTable(f.materialTable,rows,730)+18
  f.warnings=rawget(f,"warnings") or self:DisplayLabel(list,"GameFontDisableSmall",0,0,730,"")
  f.warnings:ClearAllPoints();f.warnings:SetPoint("TOPLEFT",list,"TOPLEFT",0,-y)
  f.warnings:SetText(string.format(L("Fehlende Preise: %d · alte Preise: %d · ohne Alter: %d"),result.missingBuy+result.missingStock,result.stale,result.unknownAge)
    .."\n"..L("Ungeklärte Rezept-/Materialangaben: ")..result.unknownRecipes.."\n"..self:BankStatus()
    ..(result.saleBlocked and ("\n"..L("Verkauf nicht angerechnet: Vergleich oder Preisstand unvollständig.")) or ""))
  list:SetHeight(y+height(f.warnings,48)+18)
end
function CP:CreateCostDashboard()
  local f=CreateFrame("Frame","CraftPilotCostWindow",UIParent,"BackdropTemplate")
  f:SetSize(800,690);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
  f:SetBackdrop(bg);f:SetBackdropColor(.035,.055,.075,.99);f:SetBackdropBorderColor(.4,.5,.57,1)
  self:DisplayLabel(f,"GameFontNormalLarge",22,18,440,L("Kostenkalkulation"))
  f.caption=self:DisplayLabel(f,"GameFontHighlight",22,46,735,"")
  f.notice=self:DisplayLabel(f,"GameFontDisableSmall",22,130,735,"")
  f.scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  f.list=CreateFrame("Frame",nil,f.scroll);f.list:SetSize(730,100);f.scroll:SetScrollChild(f.list)
  local hint=self:DisplayLabel(f,"GameFontDisableSmall",22,0,735,L("AH: letzter Scan · Bank: letzter Stand · Stückerlöse sind kein garantierter Gewinn. Bindung, Nachfrage und Reise prüfen."))
  hint:ClearAllPoints();hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,46)
  local refresh=CreateFrame("Button",nil,f,"BackdropTemplate");CP:StyleActionButton(refresh);refresh:SetSize(180,25);refresh:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,14);refresh:SetText(L("Neu berechnen"));refresh:SetScript("OnClick",function() CP:RefreshCostWindow() end)
  local add=CreateFrame("Button",nil,f,"BackdropTemplate");CP:StyleActionButton(add);add:SetSize(230,25);add:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",214,14);add:SetText(L("+ Fehlmengen zur Einkaufsliste"));add:SetScript("OnClick",function() CP:AddCostDeficits(CP.costContext) end)
  local shopping=CreateFrame("Button",nil,f,"BackdropTemplate");CP:StyleActionButton(shopping);shopping:SetSize(220,25);shopping:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",456,14);shopping:SetText(L("Manuelle Einkaufsliste"));shopping:SetScript("OnClick",function() CP:OpenPersonalShopping() end)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-5,-5);close:SetScript("OnClick",function() f:Hide() end)
  UISpecialFrames[#UISpecialFrames+1]="CraftPilotCostWindow";return f
end
