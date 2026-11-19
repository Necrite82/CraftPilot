-- 0.26: what to keep for later steps, the price up to which a material is worth buying, item tooltips,
-- buying the plan's vendor materials, what to do with crafted leftovers and a budget mode.
-- Buying at a vendor happens only on the player's click on "Kaufen"; nothing is sold or crafted.
local _,CP=...
local L=CP.L

local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c,d,e,f,g,h,i,j,k=pcall(fn,...)
  if ok then return a,b,c,d,e,f,g,h,i,j,k end
end
local function clock() return type(GetTime)=="function" and GetTime() or 0 end

-- Keep for later -----------------------------------------------------------------------------------------------
-- The crafts of a plan in order: {id, name, first, crafts, output, yield, mats}. A saved route wins; otherwise
-- the cheapest path to the training cap.
local function planCrafts(self,key)
  local out={}
  local route=self.AutoRouteShopping and self:AutoRouteShopping(key)
  if route then
    for _,s in ipairs(route.steps or {}) do
      out[#out+1]={id=s.id,name=s.name,first=s.first,crafts=s.crafts,output=s.output,yield=s.yield or 1,mats=s.mats or {}}
    end
    for _,s in ipairs(route.intermediates or {}) do
      out[#out+1]={id=s.id,name=s.name,first=s.skill or 0,crafts=s.count,output=s.output,yield=s.yield or 1,mats=s.mats or {},intermediate=true}
    end
  else
    local path=self.CheapestPath and self:CheapestPath(key)
    local catalog=self:RecipeVendorCatalog(key)
    for _,s in ipairs(path and path.segments or {}) do
      local recipe=catalog and catalog.recipes[s.id]
      local native=(self.db.recipes[key] or {})[s.id]
      out[#out+1]={id=s.id,name=s.name,first=s.first,crafts=s.crafts,output=(recipe and recipe.makes) or (native and native.outputItemID),
        yield=recipe and (recipe.count or recipe.yield) or 1,mats=recipe and recipe.mats or {}}
    end
  end
  -- Intermediates are made just before the step that uses them.
  table.sort(out,function(a,b)
    if a.first~=b.first then return a.first<b.first end
    if (a.intermediate==true)~=(b.intermediate==true) then return a.intermediate==true end
    return a.id<b.id
  end)
  return out
end

-- Items a plan makes and needs again later: {item, keep, need, have, made, uses={{name,at}}, maker}.
function CP:KeepList(key)
  local cache=self.keepCache
  if cache and cache.key==key and clock()-cache.at<2 then return cache.list end
  local crafts=planCrafts(self,key)
  local byItem,list={},{}
  for i,c in ipairs(crafts) do
    local item=c.output
    if type(item)=="number" and (c.crafts or 0)>0 then
      local made=c.crafts*math.max(1,c.yield or 1)
      local need,uses=0,{}
      for j=i+1,#crafts do
        local later=crafts[j]
        local n=type(later.mats)=="table" and later.mats[item]
        if type(n)=="number" and n>0 and later.id~=c.id then
          need=need+n*(later.crafts or 0)
          uses[#uses+1]={name=later.name,at=later.first,id=later.id}
        end
      end
      if need>0 then
        local entry=byItem[item]
        if not entry then
          entry={item=item,keep=0,need=0,made=0,uses={},maker=c.name,makerID=c.id,at=c.first}
          byItem[item]=entry;list[#list+1]=entry
        end
        entry.made=entry.made+made
        entry.need=math.max(entry.need,need)
        for _,u in ipairs(uses) do entry.uses[#entry.uses+1]=u end
      end
    end
  end
  for _,e in ipairs(list) do
    e.keep=math.min(e.made,e.need)
    e.have=self:ItemAvailability(e.item)
    e.enough=e.have>=e.need
    table.sort(e.uses,function(a,b) return a.at<b.at end)
  end
  table.sort(list,function(a,b) return a.at<b.at end)
  self.keepCache={key=key,at=clock(),list=list}
  return list
end

function CP:KeepEntry(key,item)
  for _,e in ipairs(self:KeepList(key)) do if e.item==item then return e end end
end

function CP:KeepText(e)
  local first=e.uses[1]
  local use=first and string.format(L("für %s ab Skill %d"),first.name,first.at) or ""
  if e.enough then
    return string.format(L("Schon vorhanden: %d von %d %s · nicht erneut herstellen"),e.have,e.need,use)
  end
  return string.format(L("Behalten: %d× %s %s · nicht verkaufen"),e.need,self:ItemName(e.item),use)
end

-- Cards on the plan's crafts page.
function CP:KeepCards(key)
  local list=self:KeepList(key)
  if #list==0 then return {} end
  local cards={{sectionHeader=true,title=L("AUFHEBEN FÜR SPÄTERE SCHRITTE")}}
  for _,e in ipairs(list) do
    local uses={}
    for i,u in ipairs(e.uses) do if i<=3 then uses[#uses+1]=u.name..L(" (ab ")..u.at..")" end end
    cards[#cards+1]={title=e.need.."× "..self:ItemName(e.item)..(e.enough and (" · "..L("schon vorhanden")) or ""),
      detail=(e.enough and string.format(L("Du hast %d · nicht erneut herstellen."),e.have) or string.format(L("Hergestellt mit %s · nicht verkaufen."),e.maker))
        .."\n"..L("Gebraucht für: ")..table.concat(uses,", "),
      color=e.enough and "green" or "gold",tooltipItem=e.item}
  end
  return cards
end

-- Price limits ---------------------------------------------------------------------------------------------------
-- From the cheapest path (path.priceLimits): above this price per item, another recipe is cheaper per point.
function CP:PriceLimit(key,item)
  local path=self.CheapestPath and self:CheapestPath(key)
  return path and path.priceLimits and path.priceLimits[item]
end

function CP:PriceLimitCards(key,items)
  local path=self.CheapestPath and self:CheapestPath(key)
  if not path or not path.priceLimits then return {} end
  local rows={}
  for _,id in ipairs(items) do
    local limit=path.priceLimits[id]
    if limit then rows[#rows+1]={id=id,limit=limit} end
  end
  if #rows==0 then return {} end
  table.sort(rows,function(a,b) return self:ItemName(a.id)<self:ItemName(b.id) end)
  local cards={{sectionHeader=true,title=L("PREISGRENZEN")}}
  for _,r in ipairs(rows) do
    local price=self:PriceDetails(r.id).price
    local over=price and price>r.limit.price
    cards[#cards+1]={title=self:ItemName(r.id)..": "..L("lohnt sich bis ")..self:FormatCostMoney(r.limit.price),
      detail=(price and (L("AH jetzt: ")..self:FormatCostMoney(price).." · ") or "")
        ..(r.limit.alt and string.format(L("darüber ist %s günstiger"),r.limit.alt) or ""),
      color=over and "red" or "green",tooltipItem=r.id}
  end
  return cards
end

-- Budget mode --------------------------------------------------------------------------------------------------
-- How far the cheapest path goes with a given amount of gold (copper), and its most expensive stretches.
function CP:BudgetReach(path,budget)
  if not path or not budget or budget<=0 then return nil end
  local spent,reached=0,path.from
  for _,s in ipairs(path.segments) do
    local points=math.max(1,s.last-s.first)
    local per=s.cost/points
    local fee=s.learned and 0 or (s.fee or 0)
    if spent+fee>budget then break end
    spent=spent+fee
    local stop=false
    for k=s.first,s.last-1 do
      if spent+per>budget then stop=true;break end
      spent=spent+per;reached=k+1
    end
    if stop then break end
  end
  local dear={}
  for _,s in ipairs(path.segments) do dear[#dear+1]={name=s.name,first=s.first,last=s.last,per=s.cost/math.max(1,s.last-s.first)} end
  table.sort(dear,function(a,b) return a.per>b.per end)
  return {reached=reached,spent=spent,target=path.reached,dear={dear[1],dear[2],dear[3]}}
end

function CP:BudgetCards(key)
  local ui=self.db.ui
  local gold=tonumber(ui.budgetGold) or 0
  local cards={{sectionHeader=true,title=L("BUDGET")},
    {title=L("Budget: ")..(gold>0 and (gold..L(" Gold")) or L("aus")),footer=L("Regler ziehen: 0 = aus"),color="blue",
      slider={label=L("Budget: "),value=gold,min=0,max=500,step=5,unit=L(" Gold"),apply=function(value) ui.budgetGold=value;CP:Render() end}}}
  if gold<=0 then return cards end
  local reach=self:BudgetReach(self.CheapestPath and self:CheapestPath(key),gold*10000)
  if not reach then
    cards[#cards+1]={title=L("Kein Weg berechenbar"),detail=L("Für den Budget-Modus fehlen Preise · AH scannen."),color="gold"}
    return cards
  end
  local dear={}
  for _,d in ipairs(reach.dear) do dear[#dear+1]=string.format("%s %d–%d (%s/%s)",d.name,d.first,d.last,self:FormatCostMoney(d.per),L("Punkt")) end
  cards[#cards+1]={title=reach.reached>=reach.target and string.format(L("Reicht bis Skill %d · ca. %s"),reach.reached,self:FormatCostMoney(reach.spent))
      or string.format(L("Mit %d Gold bis Skill %d (von %d)"),gold,reach.reached,reach.target),
    detail=L("Teuerste Abschnitte: ")..table.concat(dear,", "),color=reach.reached>=reach.target and "green" or "gold"}
  return cards
end

-- 1.1.0: one line for "Jetzt" and the companion. Without a budget it offers one and names the whole way's cost.
function CP:BudgetLine(key,rec)
  local gold=tonumber(self.db.ui.budgetGold) or 0
  local path=self.CheapestPath and self:CheapestPath(key)
  if gold<=0 then
    if path and path.total and path.reached and path.reached>(path.from or 0) then
      return {text=string.format(L("Ganzer Weg bis %d: ca. %s · Wie weit reicht dein Gold?"),path.reached,self:FormatCostMoney(path.total)),
        short=string.format(L("Bis %d: ca. %s"),path.reached,self:FormatCostMoney(path.total)),action=L("Budget festlegen"),off=true}
    end
    return {text=L("Budget festlegen: CraftPilot zeigt, bis zu welchem Skill dein Gold reicht."),action=L("Budget festlegen"),off=true}
  end
  local reach=self:BudgetReach(path,gold*10000)
  local text,short
  if not reach then
    text=string.format(L("Budget %d Gold · für die Reichweite fehlen Preise (AH scannen)"),gold);short=text
  elseif reach.reached>=reach.target then
    text=string.format(L("Budget %d Gold · reicht für den ganzen Weg bis %d (ca. %s)"),gold,reach.target,self:FormatCostMoney(reach.spent))
    short=string.format(L("Budget %d Gold reicht bis %d"),gold,reach.target)
  else
    text=string.format(L("Budget %d Gold · reicht bis Skill %d von %d"),gold,reach.reached,reach.target)
    short=string.format(L("Budget %d Gold reicht bis %d"),gold,reach.reached)
  end
  local over=rec and rec.buy and rec.buyComplete and rec.buy>gold*10000
  if over then
    local warn=string.format(L("Nächster Schritt kostet %s – mehr als dein Budget"),self:FormatCostMoney(rec.buy))
    text=text.."  ·  |cffff7f66"..warn.."|r";short=short.."\n|cffff7f66"..warn.."|r"
  end
  return {text=text,short=short,action=L("Budget ändern"),over=over,reach=reach}
end

function CP:SetBudget(gold)
  gold=math.max(0,math.min(100000,math.floor(tonumber(gold) or 0)))
  self.db.ui.budgetGold=gold
  if self.Render then self:Render() end
  return gold
end

function CP:OpenBudgetWindow()
  local f=self.budgetWindow
  if not f then
    -- CraftPilot look: rounded dark panel, flat buttons, gold primary action.
    f=CreateFrame("Frame","CraftPilotProBudgetWindow",UIParent,"BackdropTemplate")
    f:SetSize(380,132);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    self:Round(f)
    if type(f.SetBackdropColor)=="function" then f:SetBackdropColor(.078,.090,.110,1);f:SetBackdropBorderColor(.88,.69,.31,.9) end
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",14,-12);f.title:SetText(L("Budget"))
    f.hint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall");f.hint:SetPoint("TOPLEFT",f,"TOPLEFT",14,-32);f.hint:SetWidth(352);f.hint:SetJustifyH("LEFT")
    f.hint:SetText(L("Wie viel Gold willst du fürs Skillen ausgeben? 0 schaltet das Budget aus."))
    local function flat(w,caption,fn,primary)
      local b=CreateFrame("Button",nil,f,"BackdropTemplate")
      b:SetSize(w,24)
      if primary then CP:StylePrimaryButton(b) else CP:StyleActionButton(b) end
      b:SetText(caption);b:SetScript("OnClick",fn)
      return b
    end
    f.box=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.box:SetSize(64,22);f.box:SetPoint("TOPLEFT",f,"TOPLEFT",120,-60);f.box:SetAutoFocus(false)
    if type(f.box.SetNumeric)=="function" then f.box:SetNumeric(true) end
    if type(f.box.SetMaxLetters)=="function" then f.box:SetMaxLetters(6) end
    f.unit=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.unit:SetPoint("LEFT",f.box,"RIGHT",6,0);f.unit:SetText(L("Gold"))
    local function step(d,x)
      local b=flat(38,(d>0 and "+" or "-")..math.abs(d),function() f.box:SetText(tostring(math.max(0,(tonumber(f.box:GetText()) or 0)+d))) end)
      b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-59)
    end
    step(-5,14);step(-1,58);step(1,232);step(5,276)
    local function apply() CP:SetBudget(f.box:GetText());f:Hide() end
    f.box:SetScript("OnEnterPressed",apply);f.box:SetScript("OnEscapePressed",function() f:Hide() end)
    f.apply=flat(130,L("Übernehmen"),apply,true);f.apply:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",14,12)
    f.off=flat(90,L("Aus"),function() CP:SetBudget(0);f:Hide() end);f.off:SetPoint("LEFT",f.apply,"RIGHT",8,0)
    f.close=flat(100,L("Schließen"),function() f:Hide() end);f.close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-14,12)
    self.budgetWindow=f
  end
  -- Right below the budget line on "Jetzt", else centred.
  f:ClearAllPoints()
  local strip=self.budgetStrip
  if strip and type(strip.IsShown)=="function" and strip:IsShown() then f:SetPoint("TOPRIGHT",strip,"BOTTOMRIGHT",0,-4)
  else f:SetPoint("CENTER") end
  f.box:SetText(tostring(tonumber(self.db.ui.budgetGold) or 0))
  f:Show()
  if type(f.box.SetFocus)=="function" then f.box:SetFocus() end
  if type(f.box.HighlightText)=="function" then f.box:HighlightText() end
  return true
end

-- Leftovers -------------------------------------------------------------------------------------------------------
-- Crafted items in the bags that no plan keeps: sell at the AH, sell to a vendor or let an enchanter disenchant.
local function vendorSell(item)
  local sell
  if C_Item and type(C_Item.GetItemInfo)=="function" then sell=select(11,safe(C_Item.GetItemInfo,item))
  elseif type(GetItemInfo)=="function" then sell=select(11,safe(GetItemInfo,item)) end
  return type(sell)=="number" and sell or 0
end
local function gear(item)
  local class
  if C_Item and type(C_Item.GetItemInfoInstant)=="function" then class=select(6,safe(C_Item.GetItemInfoInstant,item))
  elseif type(GetItemInfoInstant)=="function" then class=select(6,safe(GetItemInfoInstant,item)) end
  return class==2 or class==4
end

function CP:Leftovers(key)
  local catalog=self:RecipeVendorCatalog(key)
  local products={}
  for id,r in pairs(catalog and catalog.recipes or {}) do if type(r.makes)=="number" then products[r.makes]=true end end
  for _,native in pairs(self.db.recipes[key] or {}) do if native.learned and type(native.outputItemID)=="number" then products[native.outputItemID]=true end end
  local keep={}
  for owner in pairs(self.db.plans) do
    for item,n in pairs((self:PlanRequirements(owner))) do keep[item]=(keep[item] or 0)+n end
    for _,e in ipairs(self:KeepList(owner)) do keep[e.item]=math.max(keep[e.item] or 0,e.need) end
  end
  local enchanter
  for _,c in ipairs(self:AltProfessions("enchanting")) do enchanter=enchanter or c.name end
  if self:OwnsProfession("enchanting") then enchanter=L("du") end
  local cut=1-math.max(0,math.min(30,tonumber(self.db.ui.economyCut) or 5))/100
  local out={}
  for item in pairs(products) do
    local have=self:RawItemCount(item,false)
    local spare=have-(keep[item] or 0)
    if spare>0 then
      local d=self:PriceDetails(item)
      local ah=d.auction and math.floor(d.auction*cut) or 0
      local vendor=vendorSell(item)
      local best,how
      if ah>vendor then best,how=ah,"ah" else best,how=vendor,"vendor" end
      if gear(item) and enchanter and ah<vendor*3 then how="disenchant" end
      out[#out+1]={id=item,count=spare,ah=ah,vendor=vendor,how=how,value=best*spare,enchanter=enchanter,stale=d.freshness=="stale" or d.freshness=="aging"}
    end
  end
  table.sort(out,function(a,b) return a.value>b.value end)
  return out
end

function CP:LeftoverCards(key)
  local rows=self:Leftovers(key)
  if #rows==0 then
    return {{title=L("Nichts zu verwerten"),detail=L("In deinen Taschen liegen keine hergestellten Gegenstände, die kein Plan mehr braucht. Was später gebraucht wird, steht nie hier."),color="green"}}
  end
  local cards={{title=L("Hergestelltes verwerten"),detail=L("Nur Gegenstände, die kein Plan mehr braucht. Vergleich: AH (abzüglich AH-Abzug), Händler, Entzaubern."),color="blue"}}
  for i,r in ipairs(rows) do
    if i>12 then break end
    local advice
    if r.how=="ah" then advice=L("Im AH verkaufen")
    elseif r.how=="disenchant" then advice=string.format(L("Entzaubern lassen (%s)"),r.enchanter)
    else advice=L("Beim Händler verkaufen") end
    cards[#cards+1]={title=r.count.."× "..self:ItemName(r.id).." · "..advice,
      detail=L("AH netto: ")..(r.ah>0 and self:FormatCostMoney(r.ah) or "—")..(r.stale and (" ("..L("alt")..")") or "").."  ·  "..L("Händler: ")..self:FormatCostMoney(r.vendor)..L(" je Stück"),
      footer=r.how=="ah" and L("Klick am Auktionshaus: Angebote ansehen") or "",tooltipItem=r.id,
      color=r.how=="ah" and "green" or (r.how=="disenchant" and "gold" or "blue"),
      action=r.how=="ah" and function() CP:SearchItems({{id=r.id,quantity=r.count}},L("Verwerten"),L("Auctionator sucht die Angebote.")) end or nil}
  end
  return cards
end

-- Vendor helper ---------------------------------------------------------------------------------------------------
-- What the plans and the recommendation still miss: item -> count (after bags, bank and twinks).
function CP:MissingForPlans()
  local need={}
  for owner in pairs(self.db.plans) do
    for id,n in pairs((self:PlanRequirements(owner))) do need[id]=(need[id] or 0)+n end
  end
  local rec=self.currentRecommendation
  -- 1.3.0: the recommendation's whole need (not what is still missing): stock is subtracted exactly once below.
  for _,m in ipairs(rec and rec.materials or {}) do need[m.id]=math.max(need[m.id] or 0,m.required or m.quantity) end
  local out={}
  for id,n in pairs(need) do
    local missing=n-self:ItemAvailability(id)
    if missing>0 then out[id]=missing end
  end
  return out
end

function CP:MerchantOffers()
  local missing=self:MissingForPlans()
  local out={}
  local n=safe(GetMerchantNumItems) or 0
  for i=1,n do
    local item=safe(GetMerchantItemID,i)
    if not item and type(GetMerchantItemLink)=="function" then
      local link=safe(GetMerchantItemLink,i)
      item=type(link)=="string" and tonumber(link:match("item:(%d+)"))
    end
    if item and missing[item] then
      local name,_,price,stack,available=safe(GetMerchantItemInfo,i)
      stack=math.max(1,tonumber(stack) or 1)
      local count=missing[item]
      if type(available)=="number" and available>=0 then count=math.min(count,available*stack) end
      if count>0 and type(price)=="number" then
        local purchases=math.ceil(count/stack)
        out[#out+1]={index=i,id=item,name=name or self:ItemName(item),count=purchases*stack,stack=stack,purchases=purchases,cost=purchases*price}
      end
    end
  end
  table.sort(out,function(a,b) return a.name<b.name end)
  return out
end

-- Buy exactly the missing amount of one offer: presold stacks one purchase each, the rest in max-stack chunks.
function CP:BuyMerchantOffer(o)
  if type(BuyMerchantItem)~="function" then return false end
  local money=safe(GetMoney) or math.huge
  if o.cost>money then self:Say(L("Nicht genug Gold."));return false end
  if o.stack>1 then
    for _=1,o.purchases do safe(BuyMerchantItem,o.index,1) end
  else
    local left=o.count
    local max=math.max(1,tonumber(safe(GetMerchantItemMaxStack,o.index)) or 20)
    while left>0 do local n=math.min(left,max);safe(BuyMerchantItem,o.index,n);left=left-n end
  end
  self:Say(string.format(L("Gekauft: %d× %s für %s"),o.count,o.name,self:FormatCostMoney(o.cost)))
  return true
end

function CP:ShowMerchantHelper()
  if not self.db then return end
  local offers=self:MerchantOffers()
  local f=self.MerchantHelper
  if #offers==0 then if f then f:Hide() end;return end
  if not f then
    f=CreateFrame("Frame","CraftPilotProMerchantHelper",UIParent,"BackdropTemplate")
    f:SetSize(280,80);f:SetFrameStrata("HIGH");f:SetClampedToScreen(true)
    if type(f.SetBackdrop)=="function" then
      f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f:SetBackdropColor(.07,.08,.10,.96);f:SetBackdropBorderColor(.88,.69,.31,.8)
    end
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-8)
    f.title:SetText(L("CraftPilot · fehlt für deinen Plan"))
    f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton");f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
    f.buttons={}
    f.all=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.all:SetSize(258,24)
    self.MerchantHelper=f
  end
  f:ClearAllPoints()
  local host=_G.MerchantFrame
  if type(host)=="table" and type(host.IsShown)=="function" and host:IsShown() then f:SetPoint("TOPLEFT",host,"TOPRIGHT",8,0)
  else f:SetPoint("CENTER",UIParent,"CENTER",300,100) end
  local y=32
  local total=0
  for i,o in ipairs(offers) do
    local b=f.buttons[i]
    if not b then b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetSize(258,22);f.buttons[i]=b end
    b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",10,-y)
    b:SetText(string.format(L("Kaufen: %d× %s"),o.count,o.name).." ("..self:FormatCostMoney(o.cost)..")")
    b:SetScript("OnClick",function() CP:BuyMerchantOffer(o);if C_Timer and C_Timer.After then C_Timer.After(.5,function() CP:ShowMerchantHelper() end) end end)
    b:Show();y=y+26;total=total+o.cost
  end
  for i=#offers+1,#f.buttons do f.buttons[i]:Hide() end
  f.all:ClearAllPoints();f.all:SetPoint("TOPLEFT",f,"TOPLEFT",10,-(y+4))
  f.all:SetText(L("Alles kaufen: ")..self:FormatCostMoney(total))
  f.all:SetScript("OnClick",function()
    for _,o in ipairs(CP:MerchantOffers()) do CP:BuyMerchantOffer(o) end
    if C_Timer and C_Timer.After then C_Timer.After(.5,function() CP:ShowMerchantHelper() end) end
  end)
  f.all:SetShown(#offers>1)
  f:SetHeight(y+(#offers>1 and 36 or 8))
  f:Show()
end

-- Item tooltips -----------------------------------------------------------------------------------------------------
-- Plan need, keep-for-later, twink stock and the price limit, on every item tooltip. Cached briefly because
-- tooltips refresh many times per second.
function CP:TooltipLines(item)
  if not self.db or self.db.ui.tooltips==false or type(item)~="number" then return nil end
  local cache=self.tooltipCache
  if not cache or clock()-cache.at>3 then cache={at=clock(),lines={}};self.tooltipCache=cache end
  if cache.lines[item]~=nil then return cache.lines[item] or nil end
  local lines={}
  local key=self.db.view
  local need=0
  for owner in pairs(self.db.plans) do need=need+((self:PlanRequirements(owner))[item] or 0) end
  local keep=self:KeepEntry(key,item)
  if keep and not keep.enough then lines[#lines+1]={"|cffffd200"..L("Nicht verkaufen")..":|r "..string.format(L("%d für deinen Plan (ab Skill %d)"),keep.need,keep.uses[1] and keep.uses[1].at or 0),1,1,1} end
  if need>0 then
    local have=self:ItemAvailability(item)
    lines[#lines+1]={string.format(L("Für deinen Plan: %d nötig, %d fehlen"),need,math.max(0,need-have)),.8,.85,.95}
  end
  if need>0 or keep then
    for i,a in ipairs(self:AltStock(item)) do
      if i<=2 and a.reachable then
        local where=a.bank>0 and L("Bank") or ((a.mail or 0)>0 and L("Post") or L("Taschen"))
        lines[#lines+1]={string.format("%s: %d (%s)",a.name,a.count,where),.6,.8,.6}
      end
    end
  end
  if self.IsWatched and self:IsWatched(item) then lines[#lines+1]={"|cffffd200"..L("Auf deiner Merkliste").."|r",1,1,1} end
  local verdict,vc
  if self.ItemVerdict then verdict,vc=self:ItemVerdict(item) end
  if verdict and not keep then lines[#lines+1]={verdict,vc and vc[1] or .8,vc and vc[2] or .8,vc and vc[3] or .8} end
  local wish=self.WishedRecipeItems and self:WishedRecipeItems()[item]
  if wish then lines[#lines+1]={(CP.WISH_MARK or "").."|cffffd200"..L("Auf deiner Rezept-Wunschliste").."|r",1,1,1} end
  local limit=self:PriceLimit(key,item)
  if limit then lines[#lines+1]={L("Lohnt sich bis ")..self:FormatCostMoney(limit.price)..L(" je Stück"),.8,.8,.8} end
  if #lines==0 then cache.lines[item]=false;return nil end
  cache.lines[item]=lines
  return lines
end

function CP:AddTooltipLines(tooltip,item)
  local lines=self:TooltipLines(item)
  if not lines or not tooltip or type(tooltip.AddLine)~="function" then return end
  tooltip:AddLine("CraftPilot",.88,.69,.31)
  for _,l in ipairs(lines) do tooltip:AddLine(l[1],l[2],l[3],l[4]) end
end

local function itemFromTooltip(tooltip)
  if type(tooltip.GetItem)~="function" then return nil end
  local _,link=tooltip:GetItem()
  return type(link)=="string" and tonumber(link:match("item:(%d+)")) or nil
end
local hooked=false
function CP:HookTooltips()
  if hooked then return end
  hooked=true
  if _G.TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall)=="function" and _G.Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,function(tooltip,data)
      local item=data and data.id or itemFromTooltip(tooltip)
      CP:AddTooltipLines(tooltip,item)
    end)
    return
  end
  for _,tip in ipairs({_G.GameTooltip,_G.ItemRefTooltip}) do
    if type(tip)=="table" and type(tip.HookScript)=="function" then
      pcall(tip.HookScript,tip,"OnTooltipSetItem",function(tooltip) CP:AddTooltipLines(tooltip,itemFromTooltip(tooltip)) end)
    end
  end
end

-- Events ------------------------------------------------------------------------------------------------------------
local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","MERCHANT_SHOW","MERCHANT_CLOSED","MERCHANT_UPDATE","UNIT_SPELLCAST_SUCCEEDED"}) do
  pcall(frame.RegisterEvent,frame,event)
end
frame:SetScript("OnEvent",function(_,event,unit,_,spell)
  if event=="PLAYER_LOGIN" then CP:HookTooltips();if CP.HookItemDB then CP:HookItemDB() end;return end
  if not CP.db then return end
  if event=="MERCHANT_SHOW" then
    if C_Timer and C_Timer.After then C_Timer.After(.2,function() CP:ShowMerchantHelper() end) else CP:ShowMerchantHelper() end
  elseif event=="MERCHANT_UPDATE" then
    if CP.MerchantHelper and CP.MerchantHelper:IsShown() then CP:ShowMerchantHelper() end
  elseif event=="MERCHANT_CLOSED" then
    if CP.MerchantHelper then CP.MerchantHelper:Hide() end
  elseif event=="UNIT_SPELLCAST_SUCCEEDED" and unit=="player" and type(spell)=="number" then
    -- Right after crafting something a later step needs: say so before it ends up at the AH.
    local key=CP.db.lastCapture and CP.db.lastCapture.key
    if not key then return end
    for _,e in ipairs(CP:KeepList(key)) do
      if e.makerID==spell and not e.enough and CP.CompanionNotice then
        CP:CompanionNotice(CP:KeepText(e))
        break
      end
    end
  end
end)
