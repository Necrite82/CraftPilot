-- Personal purchase quantities, independent from profession plans.
local _,CP=...
local L=CP.L
function CP:PersonalShopping()
  if type(self.db.manualShopping)~="table" then self.db.manualShopping={} end
  return self.db.manualShopping
end
function CP:ChangePersonalShopping(id,delta)
  if type(id)~="number" or id<1 or id%1~=0 or type(delta)~="number" or delta%1~=0 then return false end
  local list=self:PersonalShopping();local n=math.max(0,math.min(99999,(tonumber(list[id]) or 0)+delta))
  list[id]=n>0 and n or nil;return true
end
function CP:AddCostDeficits(context)
  local cost=self:CostCalculation(context.kind,context.key,context.id,context.quantity or 1)
  if cost.unknownRecipes>0 then self:Say(L("Zutaten unvollständig · zuerst Berufsfenster aktualisieren."));return false end
  local count=0
  for _,m in ipairs(cost.materials) do if m.missing>0 then self:ChangePersonalShopping(m.id,m.missing);count=count+1 end end
  self:Say(count>0 and L("Aktuelle Fehlmengen zur manuellen Einkaufsliste hinzugefügt.") or L("Keine fehlenden Zutaten."))
  self:RefreshPersonalShopping();return count>0
end
function CP:RecipeShoppingButton(b,key,entry,active)
  if not rawget(b,"shoppingButton") then
    local add=CreateFrame("Button",nil,b,"BackdropTemplate");CP:StyleActionButton(add);add:SetSize(112,22);add:SetPoint("TOPRIGHT",b,"TOPRIGHT",-8,-6)
    add:SetText(L("+ Einkaufsliste"));b.shoppingButton=add
  end
  b.shoppingButton:SetShown(active and not entry.referenceOnly)
  b.shoppingButton:SetScript("OnClick",function() CP:AddCostDeficits({kind="recipe",key=key,id=entry.id,quantity=CP:RequestedRecipeQuantity(key,entry.id)}) end)
  if active then b.nameLabel:SetWidth((b:GetWidth() or 650)-182) end
end
function CP:ManualShoppingCard()
  local n=0;for _ in pairs(self:PersonalShopping()) do n=n+1 end
  return {title=L("Manuelle Einkaufsliste").." · "..n,
    detail=L("Eigene Kaufmengen verwalten und an Auctionator übergeben."),
    footer=L("Unabhängig vom Skillplan · Rezept-Fehlmengen per + Einkaufsliste übernehmen."),color="blue",
    action=function() CP:OpenPersonalShopping() end}
end
function CP:ExportPersonalShopping()
  local api=_G.Auctionator and Auctionator.API and Auctionator.API.v1
  if not api or type(api.ConvertToSearchString)~="function" or type(api.CreateShoppingList)~="function" then self:Say(L("Auctionator-Einkaufslisten-API fehlt."));return false end
  local terms,ids={},{};for id in pairs(self:PersonalShopping()) do ids[#ids+1]=id end;table.sort(ids)
  local names={}
  for _,id in ipairs(ids) do
    local name=self:ItemName(id)
    if name=="Item #"..id or names[name] then self:MarketItemData(id);self:Say(L("Gegenstandsname fehlt oder ist nicht eindeutig."));return false end
    names[name]=true
    local ok,term=pcall(api.ConvertToSearchString,"CraftPilot",{searchString=name,isExact=true,quantity=self.db.manualShopping[id]})
    if not ok or type(term)~="string" then return false end;terms[#terms+1]=term
  end
  local ok,result=pcall(api.CreateShoppingList,"CraftPilot","CraftPilot - "..L("Manueller Einkauf"),terms)
  if not ok or result==false then self:Say(L("Auctionator-Liste konnte nicht erstellt werden."));return false end
  self:Say(L("Manuelle Kaufmengen an Auctionator übergeben."));return true
end
function CP:RefreshPersonalShopping()
  local f=self.personalShoppingWindow;if not f or not f:IsShown() then return end
  local rows={};local total,unknown=0,0
  for id,n in pairs(self:PersonalShopping()) do
    local _,bag,bank,live,known=self:ItemAvailability(id);local p=self:PriceDetails(id)
    local cost=p.price and p.price*n
    rows[#rows+1]={id=id,quantity=n,bag=bag,bank=bank,bankKnown=known,missing=n,buy=cost}
    if cost then total=total+cost else unknown=unknown+1 end
  end
  table.sort(rows,function(a,b) return CP:ItemName(a.id)<CP:ItemName(b.id) end)
  f.total:SetText(self:DisplayMoney(total)..(unknown>0 and " + ?" or ""))
  self:DrawMaterialTable(f.list,rows,700)
  f.removeButtons=rawget(f,"removeButtons") or {}
  for _,b in ipairs(f.removeButtons) do b:Hide() end
  for i,row in ipairs(rows) do
    local b=f.removeButtons[i]
    if not b then b=CreateFrame("Button",nil,f.list,"UIPanelCloseButton");f.removeButtons[i]=b end
    b:ClearAllPoints();b:SetPoint("TOPRIGHT",f.list.tableRows[i],"TOPRIGHT",27,0);b:SetSize(25,25);b:Show()
    local id=row.id;b:SetScript("OnClick",function() CP:PersonalShopping()[id]=nil;CP:RefreshPersonalShopping() end)
    local line=f.list.tableRows[i]
    line:SetScript("OnClick",function() f.item:SetText(tostring(id));f.quantity:SetText(tostring(CP:PersonalShopping()[id]));f.quantity:SetFocus() end)
  end
  f.empty:SetShown(#rows==0)
end
function CP:OpenPersonalShopping()
  if not self.personalShoppingWindow then
    local f=CreateFrame("Frame","CraftPilotPersonalShopping",UIParent,"BackdropTemplate")
    f:SetSize(800,620);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});f:SetBackdropColor(.035,.055,.075,.99);f:SetBackdropBorderColor(.4,.5,.57,1)
    self:DisplayLabel(f,"GameFontNormalLarge",22,20,480,L("Manuelle Einkaufsliste"))
    f.total=self:DisplayLabel(f,"GameFontNormalLarge",510,20,265,"","RIGHT")
    self:DisplayLabel(f,"GameFontDisableSmall",22,53,750,L("Explizite Kaufmengen · keine erneute Bestandsabziehung · Position anklicken zum Ändern"))
    self:DisplayLabel(f,"GameFontNormalSmall",22,86,450,L("Gegenstand · Name, Itemlink oder ID"))
    self:DisplayLabel(f,"GameFontNormalSmall",495,86,90,L("Kaufmenge"))
    f.item=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.item:SetSize(450,26);f.item:SetPoint("TOPLEFT",f,"TOPLEFT",26,-107);f.item:SetAutoFocus(false)
    f.quantity=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.quantity:SetSize(85,26);f.quantity:SetPoint("TOPLEFT",f,"TOPLEFT",500,-107);f.quantity:SetAutoFocus(false);f.quantity:SetNumeric(true);f.quantity:SetText("1")
    local save=CreateFrame("Button",nil,f,"BackdropTemplate");CP:StyleActionButton(save);save:SetSize(170,26);save:SetPoint("TOPLEFT",f,"TOPLEFT",607,-107);save:SetText(L("Hinzufügen / Setzen"))
    save:SetScript("OnClick",function()
      local text=f.item:GetText() or "";local id=tonumber(text) or tonumber(text:match("item:(%d+)"))
      if not id then local fn=(_G.C_Item and C_Item.GetItemInfo) or _G.GetItemInfo;if type(fn)=="function" then local ok,name,link=pcall(fn,text);if ok and type(link)=="string" then id=tonumber(link:match("item:(%d+)")) end end end
      local n=tonumber(f.quantity:GetText())
      if not id or id<1 or id%1~=0 or not n or n<0 or n>99999 or n%1~=0 then CP:Say(L("Gültigen Gegenstand und eine ganze Kaufmenge eingeben."));return end
      CP:PersonalShopping()[id]=n>0 and n or nil;CP:RefreshPersonalShopping()
    end)
    for _,box in ipairs({f.item,f.quantity}) do box:SetScript("OnEscapePressed",function() box:ClearFocus() end) end
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",f,"TOPLEFT",22,-155);scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-45,92)
    f.list=CreateFrame("Frame",nil,scroll);f.list:SetSize(700,100);scroll:SetScrollChild(f.list)
    f.empty=self:DisplayLabel(f,"GameFontHighlight",22,205,730,L("Noch keine Positionen · am Rezept + Einkaufsliste wählen oder oben einen Gegenstand eingeben."))
    local export=CreateFrame("Button",nil,f,"BackdropTemplate");CP:StyleActionButton(export);export:SetSize(260,28);export:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,20);export:SetText(L("An Auctionator übergeben"));export:SetScript("OnClick",function() CP:ExportPersonalShopping() end)
    self:DisplayLabel(f,"GameFontDisableSmall",22,0,750,"")
    local hint=self:DisplayLabel(f,"GameFontDisableSmall",22,0,750,L("Rezept-Zugänge addieren aktuelle Fehlmengen. Kaufmengen bleiben bis zur manuellen Änderung erhalten."));hint:ClearAllPoints();hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,63)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-5,-5);close:SetScript("OnClick",function() f:Hide() end)
    UISpecialFrames[#UISpecialFrames+1]="CraftPilotPersonalShopping";self.personalShoppingWindow=f
  end
  self.personalShoppingWindow:Show();self:RefreshPersonalShopping()
end
