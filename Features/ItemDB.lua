-- 1.2.0: item database. Any item from the catalog: where it is used (every recipe of every profession), what
-- makes it, its chain from raw material to end product, price, own stock and where it drops. Plus "what can I
-- build now", a keep-or-sell line in item tooltips and a watchlist with AH alarm and drop hints.
local _,CP=...
local L=CP.L
local D=CP.Data

-- Indexes ----------------------------------------------------------------------------------------------------------
local usedIn,allItems
local function buildIndex()
  if usedIn then return end
  usedIn,allItems={},{}
  local seen={}
  local function note(item) if type(item)=="number" and not seen[item] then seen[item]=true;allItems[#allItems+1]=item end end
  for key,data in pairs(CP.CatalogData or {}) do
    if type(data)=="table" and type(data.recipes)=="table" then
      for id,recipe in pairs(data.recipes) do
        if type(recipe)=="table" and not recipe.unavailable then
          note(recipe.makes)
          for mat,n in pairs(recipe.mats or {}) do
            if type(mat)=="number" and type(n)=="number" then
              note(mat)
              usedIn[mat]=usedIn[mat] or {}
              usedIn[mat][#usedIn[mat]+1]={key=key,id=id,recipe=recipe,count=n}
            end
          end
        end
      end
    end
  end
  table.sort(allItems)
end
function CP:ResetItemIndex() usedIn,allItems=nil,nil end
function CP:ItemUses(item) buildIndex();return usedIn[item] or {} end
function CP:CatalogItems() buildIndex();return allItems end

local function profName(key) return (D.professions[key] or {}).name or key end
local function ownSkill(self,key) local p=self.db.professions[key];return p and p.skill end
local function known(self,key,id)
  local native=(self.db.recipes[key] or {})[id]
  return native~=nil and native.learned~=false
end
local function altWith(self,key,need)
  for _,a in ipairs(self.AltProfessions and self:AltProfessions(key) or {}) do
    if (a.skill or 0)>=(need or 1) then return a.name end
  end
  return nil
end
local function itemIcon(id)
  local fn=(_G.C_Item and C_Item.GetItemIconByID) or _G.GetItemIcon
  if type(fn)~="function" then return nil end
  local ok,icon=pcall(fn,id)
  return ok and icon or nil
end

-- Search -----------------------------------------------------------------------------------------------------------
-- Names come from the client's item cache; uncached items are requested so a second look finds them.
local requested=false
function CP:RequestItemNames()
  if requested then return end
  requested=true
  local load=_G.C_Item and C_Item.RequestLoadItemDataByID
  if type(load)~="function" then return end
  for _,id in ipairs(self:CatalogItems()) do pcall(load,id) end
end

function CP:SearchItems_DB(query,limit)
  query=type(query)=="string" and query:lower():gsub("^%s+",""):gsub("%s+$","") or ""
  if #query<2 then return {} end
  local exact,out={},{}
  for _,id in ipairs(self:CatalogItems()) do
    local name=self:ItemName(id)
    local lower=name:lower()
    if lower==query then exact[#exact+1]={id=id,name=name}
    elseif lower:find(query,1,true) then out[#out+1]={id=id,name=name} end
  end
  table.sort(out,function(a,b) if a.name~=b.name then return a.name<b.name end return a.id<b.id end)
  for i=#exact,1,-1 do table.insert(out,1,exact[i]) end
  limit=limit or 40
  for i=#out,limit+1,-1 do out[i]=nil end
  return out
end

-- Chain: raw material -> ... -> item -> ... (first producer down, first use of an own profession up) -------------
function CP:ItemChain(item)
  local down,cur,guard={},item,0
  while guard<5 do
    guard=guard+1
    local p=(self.ItemProducers and self:ItemProducers(cur) or {})[1]
    if not p then break end
    local mat,best=nil,-1
    for m,n in pairs(p.recipe.mats or {}) do if n>best then mat,best=m,n end end
    if not mat or mat==item then break end
    table.insert(down,1,mat);cur=mat
  end
  local up,seen={},{[item]=true}
  cur=item;guard=0
  while guard<4 do
    guard=guard+1
    local uses=self:ItemUses(cur)
    local pick
    for _,u in ipairs(uses) do if self.db.professions[u.key] and u.recipe.makes and not seen[u.recipe.makes] then pick=u;break end end
    if not pick then for _,u in ipairs(uses) do if u.recipe.makes and not seen[u.recipe.makes] then pick=u;break end end end
    if not pick then break end
    seen[pick.recipe.makes]=true
    up[#up+1]=pick.recipe.makes;cur=pick.recipe.makes
  end
  return down,up
end

function CP:ItemChainText(item)
  local down,up=self:ItemChain(item)
  if #down==0 and #up==0 then return nil end
  local parts={}
  for _,id in ipairs(down) do parts[#parts+1]=self:ItemName(id) end
  parts[#parts+1]="|cffffd200"..self:ItemName(item).."|r"
  for _,id in ipairs(up) do parts[#parts+1]=self:ItemName(id) end
  return table.concat(parts," > ")
end

-- Watchlist ----------------------------------------------------------------------------------------------------------
function CP:ItemWatch()
  self.db.itemWatch=type(self.db.itemWatch)=="table" and self.db.itemWatch or {}
  return self.db.itemWatch
end
function CP:IsWatched(item) return self:ItemWatch()[item]==true end
function CP:ToggleWatch(item)
  local w=self:ItemWatch()
  w[item]=not w[item] or nil
  self.watchDropIndex=nil
  if self.tooltipCache then self.tooltipCache=nil end
  return w[item]==true
end
function CP:WatchDropIndex()
  if self.watchDropIndex then return self.watchDropIndex end
  local index={}
  for item in pairs(self:ItemWatch()) do
    for _,d in ipairs(self.QuestieItemDrops and self:QuestieItemDrops(item) or {}) do
      index[d.id]=index[d.id] or {}
      index[d.id][#index[d.id]+1]=item
    end
  end
  self.watchDropIndex=index
  return index
end
function CP:WatchUnitLines(npc)
  local items=type(npc)=="number" and self:WatchDropIndex()[npc]
  if not items then return nil end
  local lines={}
  for _,item in ipairs(items) do lines[#lines+1]=L("Droppt von deiner Merkliste: ")..self:ItemName(item) end
  return lines
end
-- Watched items with a fresh AH price, for the AH alarm.
function CP:WatchAlarms()
  local out={}
  for item in pairs(self:ItemWatch()) do
    local p=self:PriceDetails(item)
    if p.auction and p.ageDays~=nil and p.ageDays<=1 then
      local usual=self.UsualPrice and self:UsualPrice(item)
      local cheap=usual and p.auction<=usual*.85
      out[#out+1]={item=item,kind="watch",price=p.auction,text=string.format(cheap and L("Merkliste günstig im AH: %s für %s") or L("Merkliste im AH: %s für %s"),
        self:ItemName(item),self:FormatCostMoney(p.auction))}
    end
  end
  return out
end

-- Keep or sell: one line for the item tooltip ----------------------------------------------------------------------
function CP:ItemVerdict(item)
  if not self.db or self.db.ui.itemVerdict==false then return nil end
  local uses=self:ItemUses(item)
  if #uses==0 then
    local vendor=self.CatalogVendorPrice and self:CatalogVendorPrice(item)
    local sell=self.ItemVendorValue and self:ItemVendorValue(item)
    if (self.ItemProducers and #self:ItemProducers(item)>0) then return nil end
    return sell and sell>0 and string.format(L("Wird in keinem Rezept gebraucht · Händler %s"),self:FormatCostMoney(sell)) or nil,{.7,.7,.7}
  end
  local mine,alts,profs,seenProf=0,0,{},{}
  for _,u in ipairs(uses) do
    if not seenProf[u.key] then seenProf[u.key]=true;profs[#profs+1]=profName(u.key) end
    if self.db.professions[u.key] then mine=mine+1 elseif altWith(self,u.key,1) then alts=alts+1 end
  end
  local path=self.CheapestPath and self:CheapestPath(self.db.view)
  if path and path.quantities and path.quantities[item] then
    return string.format(L("Behalten: Zutat auf deinem Weg (%s)"),profName(self.db.view)),{.55,.85,.55}
  end
  if mine>0 then return string.format(L("Behalten: Zutat in %d Rezepten deiner Berufe"),mine),{.55,.85,.55} end
  if alts>0 then return string.format(L("Für deine Twinks: Zutat in %d Rezepten"),alts),{.6,.8,.9} end
  local p=self:PriceDetails(item)
  table.sort(profs)
  local where=table.concat(profs,", ")
  if p.auction then return string.format(L("Nur für andere Berufe (%s) · AH ca. %s"),where,self:FormatCostMoney(p.auction)),{.8,.8,.8} end
  return string.format(L("Nur für andere Berufe (%s)"),where),{.8,.8,.8}
end

-- What can I build now: learned recipes of this character, every material on hand (bags, bank, mail, twinks).
function CP:BuildableNow(limit)
  local out={}
  for key,record in pairs(self.db.professions or {}) do
    local data=CP.CatalogData and CP.CatalogData[key]
    for id,recipe in pairs(data and data.recipes or {}) do
      if type(recipe)=="table" and recipe.mats and next(recipe.mats) and known(self,key,id) then
        local runs=math.huge
        for mat,n in pairs(recipe.mats) do
          local have=(self.RawStock and self:RawStock(mat)) or self:ItemAvailability(mat) or 0
          runs=math.min(runs,math.floor(have/math.max(1,n)))
        end
        if runs~=math.huge and runs>0 then
          local chance=self.RecipeChanceAt and self:RecipeChanceAt(key,id,recipe,record.skill) or 0
          local profit=self.RecipeProfit and self:RecipeProfit(key,id)
          out[#out+1]={key=key,id=id,recipe=recipe,runs=runs,chance=chance,
            profit=type(profit)=="table" and profit.missing==0 and profit.profitOwn or nil}
        end
      end
    end
  end
  table.sort(out,function(a,b)
    if (a.chance>0)~=(b.chance>0) then return a.chance>0 end
    local pa,pb=a.profit or -math.huge,b.profit or -math.huge
    if pa~=pb then return pa>pb end
    return a.id<b.id
  end)
  if limit then for i=#out,limit+1,-1 do out[i]=nil end end
  return out
end

-- Cards ---------------------------------------------------------------------------------------------------------------
local function header(title) return {sectionHeader=true,title=title} end

function CP:ItemOverviewCard(item)
  local p=self:PriceDetails(item)
  local parts={}
  if p.auction then parts[#parts+1]=L("AH ")..self:FormatCostMoney(p.auction) end
  local sell=self.ItemVendorValue and self:ItemVendorValue(item)
  if sell and sell>0 then parts[#parts+1]=L("Händler zahlt ")..self:FormatCostMoney(sell) end
  local have=(self.RawStock and self:RawStock(item)) or self:ItemAvailability(item) or 0
  parts[#parts+1]=string.format(L("Vorrat %d"),have)
  local gather=self.GatherHint and self:GatherHint(item)
  local detail=table.concat(parts," · ")..(gather and ("\n"..gather) or "")
  local verdict=self:ItemVerdict(item)
  local watched=self:IsWatched(item)
  return {title=self:ItemName(item),detail=detail,footer=(verdict and (verdict.."  ·  ") or "")..(watched and L("Klick: von der Merkliste") or L("Klick: auf die Merkliste")),
    icon=itemIcon(item),tooltipItem=item,color=watched and "gold" or "blue",emphasis=true,
    action=function() CP:ToggleWatch(item);CP:Render() end}
end

function CP:ItemDetailCards(item)
  local cards={self:ItemOverviewCard(item)}
  local chain=self:ItemChainText(item)
  if chain then cards[#cards+1]={title=L("Rezeptkette"),detail=chain,color="blue"} end
  -- Made by
  local producers=self.ItemProducers and self:ItemProducers(item) or {}
  if #producers>0 then
    cards[#cards+1]=header(L("HERGESTELLT DURCH"))
    for _,pr in ipairs(producers) do
      local mats={}
      for mat,n in pairs(pr.recipe.mats) do mats[#mats+1]=n.."× "..self:ItemName(mat) end
      table.sort(mats)
      local who=known(self,pr.key,pr.id) and L("Du kannst es") or (altWith(self,pr.key,pr.recipe.learn) and string.format(L("%s kann es"),altWith(self,pr.key,pr.recipe.learn)) or nil)
      local id,key=pr.id,pr.key
      cards[#cards+1]={title=self:RecipeName(key,id).." · "..profName(key),detail=table.concat(mats,", "),
        footer=(who and (who.."  ·  ") or "")..L("Klick: als Vorrat planen (Endgame › Raid-Vorrat)"),color=who and "green" or "blue",tooltipSpell=id,
        action=function() CP:PlanItemFromDB(item,key,id) end}
    end
  end
  -- Used in
  local uses=self:ItemUses(item)
  if #uses>0 then
    cards[#cards+1]=header(string.format(L("ZUTAT IN %d REZEPTEN"),#uses))
    local rows={}
    for _,u in ipairs(uses) do
      local own=self.db.professions[u.key]~=nil
      rows[#rows+1]={u=u,own=own,learned=own and known(self,u.key,u.id)}
    end
    table.sort(rows,function(a,b)
      if a.own~=b.own then return a.own end
      if a.u.key~=b.u.key then return a.u.key<b.u.key end
      return (a.u.recipe.learn or 0)<(b.u.recipe.learn or 0)
    end)
    for i,r in ipairs(rows) do
      if i>40 then cards[#cards+1]={title=string.format(L("und %d weitere"),#rows-40),color="blue"};break end
      local u=r.u
      local key,id=u.key,u.id
      local colors=u.recipe.colors
      local range=colors and string.format("%d/%d/%d/%d",colors[1] or 0,colors[2] or 0,colors[3] or 0,colors[4] or 0) or ""
      local title=string.format("%s · %s (%s)",self:RecipeName(key,id),profName(key),range)
      local footer,action,color
      if r.learned then
        footer=string.format(L("%d× %s je Herstellung · erlernt"),u.count,self:ItemName(item));color="green"
        action=function() CP:ChangeView(key,false);CP.db.ui.selectedRecipes=CP.db.ui.selectedRecipes or {};CP.db.ui.selectedRecipes[key]=id;CP:OpenTab("now") end
      elseif r.own then
        local go=self.RecipeGoTo and self:RecipeGoTo(key,id)
        footer=L("Noch nicht gelernt: ")..(self.RecipeSourceText and self:RecipeSourceText(key,id) or "")
          ..(go and ("  ·  "..string.format(L("Klick: Wegpunkt zu %s"),go.label)) or "")
        color="gold"
        action=function() CP:GoToRecipe(key,id) end
      else
        local alt=altWith(self,key,u.recipe.learn)
        footer=alt and string.format(L("Nicht dein Beruf · %s hat %s"),alt,profName(key)) or L("Nicht dein Beruf")
        color="blue"
      end
      cards[#cards+1]={title=title,detail=string.format(L("%d× pro Herstellung"),u.count),footer=footer,color=color,action=action,tooltipSpell=id}
    end
  end
  for _,d in ipairs(self.QuestieItemDrops and self:QuestieItemDrops(item) or {}) do
    if not cards.dropHeader then cards[#cards+1]=header(L("DROPPT BEI"));cards.dropHeader=true end
    cards[#cards+1]={title=d.name,detail=d.zone or "",color="blue"}
    if #cards>80 then break end
  end
  cards.dropHeader=nil
  return cards
end

function CP:PlanItemFromDB(item,key,id)
  if not self.SetRaidStock then return false end
  local stock=self:RaidStock()
  local current=stock[item] and stock[item].count or 0
  self:SetRaidStock(item,key,id,math.max(current,5))
  self.db.ui.endgamePage="stock"
  self:Say(string.format(L("%s als Vorrat geplant (Endgame › Raid-Vorrat) – Menge dort anpassen."),self:ItemName(item)))
  self:OpenTab("endgame")
  return true
end

function CP:ItemSearchCards(query)
  local results=self:SearchItems_DB(query)
  if #results==0 then
    return {{title=#(query or "")<2 and L("Gegenstand suchen") or L("Nichts gefunden"),
      detail=L("Namen eintippen (mind. 2 Buchstaben), einen Gegenstand mit Shift-Klick ins Suchfeld legen oder in der Tasche Alt-Klick. Noch nie gesehene Gegenstände kennt das Spiel erst nach einem Moment – dann einfach erneut suchen."),color="blue"}}
  end
  local cards={}
  for _,r in ipairs(results) do
    local uses=#self:ItemUses(r.id)
    local makes=self.ItemProducers and #self:ItemProducers(r.id) or 0
    local id=r.id
    cards[#cards+1]={title=r.name,detail=string.format(L("Zutat in %d Rezepten · %d Herstellungswege"),uses,makes),
      footer=L("Klick: Details"),icon=itemIcon(id),tooltipItem=id,color="blue",grid=true,
      action=function() CP.db.ui.itemSelected=id;CP:Render() end}
  end
  return cards
end

function CP:BuildableCards()
  local list=self:BuildableNow(30)
  if #list==0 then
    return {{title=L("Gerade nichts herstellbar"),detail=L("Mit deinem Vorrat (Taschen, Bank, Post, Twinks) lässt sich kein erlerntes Rezept vollständig herstellen. Berufsfenster einmal öffnen, damit CraftPilot deine Rezepte kennt."),color="blue"}}
  end
  local cards={header(L("MIT DEINEM VORRAT HERSTELLBAR"))}
  for _,b in ipairs(list) do
    local key,id=b.key,b.id
    local parts={string.format(L("bis %d×"),b.runs)}
    if b.chance>0 then parts[#parts+1]=string.format(L("Skillchance ca. %d%%"),math.floor(b.chance*100+.5)) end
    if b.profit then parts[#parts+1]=(b.profit>=0 and L("Gewinn ca. ") or L("Verlust ca. "))..self:FormatCostMoney(math.abs(b.profit)) end
    cards[#cards+1]={title=self:RecipeName(key,id).." · "..profName(key),detail=table.concat(parts," · "),footer=L("Klick: Rezept öffnen"),
      color=b.chance>0 and "gold" or "green",tooltipSpell=id,grid=true,
      action=function() CP:ChangeView(key,false);CP.db.ui.selectedRecipes=CP.db.ui.selectedRecipes or {};CP.db.ui.selectedRecipes[key]=id;CP:OpenTab("now") end}
  end
  return cards
end

function CP:WatchCards()
  local w=self:ItemWatch()
  local ids={};for item in pairs(w) do ids[#ids+1]=item end
  table.sort(ids)
  if #ids==0 then
    return {{title=L("Merkliste ist leer"),detail=L("In den Details eines Gegenstands auf die obere Karte klicken. Gemerkte Gegenstände meldet der AH-Alarm nach dem Scan, und Gegner, die sie droppen, zeigen es im Tooltip."),color="blue"}}
  end
  local cards={}
  for _,item in ipairs(ids) do
    local p=self:PriceDetails(item)
    local drops=self.QuestieItemDrops and #self:QuestieItemDrops(item) or 0
    cards[#cards+1]={title=self:ItemName(item),detail=(p.auction and (L("AH ")..self:FormatCostMoney(p.auction)) or L("Kein AH-Preis"))..(drops>0 and (" · "..string.format(L("droppt bei %d Gegnern"),drops)) or ""),
      footer=L("Klick: Details · Rechtsklick: entfernen"),icon=itemIcon(item),tooltipItem=item,color="gold",grid=true,
      action=function() CP.db.ui.itemPage="search";CP.db.ui.itemSelected=item;CP:Render() end,
      rightAction=function() CP:ToggleWatch(item);CP:Render() end}
  end
  return cards
end

function CP:ItemDBCards()
  local ui=self.db.ui
  local page=ui.itemPage or "search"
  if page=="build" then return self:BuildableCards() end
  if page=="watch" then return self:WatchCards() end
  if ui.itemSelected then return self:ItemDetailCards(ui.itemSelected) end
  return self:ItemSearchCards(ui.itemQuery)
end

-- Open an item from anywhere (Alt-click in bags, /cpp item, links).
function CP:OpenItemInDB(item)
  if type(item)~="number" then return false end
  self.db.ui.itemPage="search";self.db.ui.itemSelected=item
  self:OpenTab("items")
  return true
end

local hooked=false
function CP:HookItemDB()
  if hooked then return end
  hooked=true
  -- Alt-click on an item in bags or links opens it here (setting "Alt-Klick öffnet Gegenstand").
  if type(hooksecurefunc)=="function" and type(_G.HandleModifiedItemClick)=="function" then
    hooksecurefunc("HandleModifiedItemClick",function(link)
      if not CP.db or CP.db.ui.itemAltClick==false then return end
      if type(IsAltKeyDown)=="function" and IsAltKeyDown() and not (IsShiftKeyDown and IsShiftKeyDown()) and not (IsControlKeyDown and IsControlKeyDown()) then
        local id=type(link)=="string" and tonumber(link:match("item:(%d+)"))
        if id then CP:OpenItemInDB(id) end
      end
    end)
  end
  -- Shift-click while the search field has focus puts the item's name there.
  if type(hooksecurefunc)=="function" and type(_G.ChatEdit_InsertLink)=="function" then
    hooksecurefunc("ChatEdit_InsertLink",function(link)
      local box=CP.itemSearchBox
      if box and type(box.HasFocus)=="function" and box:HasFocus() and type(link)=="string" then
        local id=tonumber(link:match("item:(%d+)"))
        if id then box:SetText(CP:ItemName(id));CP.db.ui.itemQuery=CP:ItemName(id);CP.db.ui.itemSelected=id;CP:Render() end
      end
    end)
  end
end
