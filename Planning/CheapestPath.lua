-- Cheapest skill path from the current skill to the training cap, point by point.
-- For every skill point the expected cost of each usable recipe is (cost of one craft at AH or vendor
-- prices) / (chance of a point at that skill: orange 100 %, yellow ~70 %, green ~35 %). Own stock is
-- valued at its price, so it never makes a recipe look free; the shopping list subtracts it later.
-- A recipe still to learn adds its fee once, and is only taken when it saves more than it costs.
local _,CP=...
local L=CP.L
local CACHE_SECONDS=30

local function now() return type(GetTime)=="function" and GetTime() or 0 end

-- Who on the account can make an item: this character (recipe learned) or a twink on the same realm and
-- faction whose profession skill reaches the recipe. Twinks' learned recipes are known from their last
-- visit to the profession window; without that, the skill is the best available hint.
function CP:ItemMakers(item)
  local out={}
  local index=self.BuildOutputIndex and self:BuildOutputIndex()[item]
  if not index then return out end
  local me=self.CurrentCharacter and self:CurrentCharacter()
  for _,entry in ipairs(index) do
    local recipe=entry.recipe
    local need=recipe.learn or (recipe.colors and recipe.colors[1]) or 1
    local native=(self.db.recipes[entry.key] or {})[entry.id]
    if native and native.learned and not native.disabled then
      out[#out+1]={key=entry.key,id=entry.id,recipe=recipe}
    elseif me and self.db.ui.includeAlts~=false then
      for charKey,c in pairs(self.account and self.account.characters or {}) do
        local p=c.professions and c.professions[entry.key]
        local learned=c.learned and c.learned[entry.key]
        if charKey~=self.characterKey and p and c.realm==me.realm and c.faction==me.faction and (p.skill or 0)>=need
          and (not learned or learned[entry.id]) then
          out[#out+1]={key=entry.key,id=entry.id,recipe=recipe,alt=c.name or charKey,altSure=learned~=nil}
          break
        end
      end
    end
  end
  return out
end

-- Price of one item: AH or vendor, or making it (two levels deep) when that is cheaper by at least 5 %.
-- Making it on a twink is noted in memo.notes, so the UI can say who should craft what.
-- 1.3.0: results are cached per depth (memo.byDepth[depth][item]); a price found near the depth limit (where
-- making it is not looked at any more) no longer replaces the full price of a later, shallower lookup.
-- memo[item] keeps the price at depth 0 for the price limits below. Cycles are cut with memo.visiting.
local function unitPrice(self,memo,item,depth)
  memo.byDepth=memo.byDepth or {}
  local cache=memo.byDepth[depth] or {};memo.byDepth[depth]=cache
  if cache[item]~=nil then return cache[item] or nil end
  memo.visiting=memo.visiting or {}
  if memo.visiting[item] then return nil end
  memo.visiting[item]=true
  local price=self:PriceDetails(item).price
  memo.items[item]=true
  if depth<2 then
    for _,maker in ipairs(self:ItemMakers(item)) do
      -- Only makers that are sure (own recipe, or a twink whose recipe list confirms it) count for the price.
      if not maker.alt or maker.altSure then
        local sum,known=0,true
        for mat,n in pairs(maker.recipe.mats or {}) do
          local p=type(n)=="number" and unitPrice(self,memo,mat,depth+1)
          if not p then known=false;break end
          sum=sum+p*n
        end
        local made=maker.recipe.count or maker.recipe.yield or 1
        if known and sum>0 and (not price or sum/made<price*0.95) then
          if maker.alt and price then memo.notes[item]={alt=maker.alt,sure=true,id=maker.id,key=maker.key,saving=price-sum/made} end
          price=sum/made
        end
      end
      if maker.alt and not maker.altSure and price then
        -- Unconfirmed twink recipe: only a hint ("open the profession once on X"), never in the price.
        memo.maybe=memo.maybe or {}
        memo.maybe[item]=memo.maybe[item] or {alt=maker.alt,id=maker.id,key=maker.key}
      end
    end
  end
  memo.visiting[item]=nil
  cache[item]=price or false
  if depth==0 then memo[item]=price or false end
  return price
end
CP.UnitPriceForTest=unitPrice

-- What a vendor always pays for an item (0 when unknown). The only sale the skill path may count on:
-- whether the auction house buys 18 blunderbusses is anyone's guess.
function CP:ItemVendorValue(item)
  if type(item)~="number" then return 0 end
  local vendor=0
  if C_Item and type(C_Item.GetItemInfo)=="function" then
    local ok,sell=pcall(function() return select(11,C_Item.GetItemInfo(item)) end)
    if ok and type(sell)=="number" then vendor=sell end
  elseif type(GetItemInfo)=="function" then
    local ok,sell=pcall(function() return select(11,GetItemInfo(item)) end)
    if ok and type(sell)=="number" then vendor=sell end
  end
  return vendor
end

-- What one craft brings back when sold: AH minus the cut, or the vendor price, whichever is higher.
function CP:ItemSaleValue(item)
  if type(item)~="number" then return 0 end
  local d=self:PriceDetails(item)
  local cut=1-math.max(0,math.min(30,tonumber(self.db.ui.economyCut) or 5))/100
  local ah=d.auction and d.freshness~="stale" and d.auction*cut or 0
  return math.max(ah,self:ItemVendorValue(item))
end

local function materials(self,key,id,recipe)
  local native=(self.db.recipes[key] or {})[id]
  local out={}
  if native and type(native.mats)=="table" and #native.mats>0 then
    for _,mat in ipairs(native.mats) do if type(mat[1])=="number" then out[mat[1]]=(out[mat[1]] or 0)+mat[2] end end
  else
    for item,n in pairs(recipe and recipe.mats or {}) do if type(n)=="number" then out[item]=n end end
  end
  return out
end

-- How the recipe is obtained: learned already, or a trainer/vendor with fee and the skill to learn it at.
local function acquisition(self,key,id,recipe,target)
  local native=(self.db.recipes[key] or {})[id]
  if native and native.learned and not native.disabled then return {learned=true,fee=0,at=0} end
  if not recipe or recipe.unavailable or recipe.twin or recipe.spec or recipe.rep or recipe.cooldown then return nil end
  local fee,_,eligible=self:TrainerRecipeFee(key,id,target)
  if eligible then
    local at=recipe.learn or 1
    for _,source in ipairs(recipe.get or {}) do
      if source.kind=="trainer" then at=math.max(at,source.skill or source.classicSkill or at) end
    end
    return {learned=false,fee=fee,feeUnknown=fee==nil,at=at,source="trainer"}
  end
  local cheapest
  for _,vendor in ipairs(self:RecipeVendors(key,id)) do
    if not vendor.restricted and vendor.cost and (not cheapest or vendor.cost<cheapest.cost) then cheapest=vendor end
  end
  -- A world-drop recipe that is on the auction house right now (Auctionator price) is a buyable option too.
  local ah
  if recipe.item then
    local drop=false
    for _,source in ipairs(recipe.get or {}) do if source.kind=="drop" then drop=true end end
    local d=drop and self:PriceDetails(recipe.item)
    if d and d.auction and d.freshness~="stale" then ah=d.auction end
  end
  if cheapest and (not ah or cheapest.cost<=ah) then return {learned=false,fee=cheapest.cost,at=recipe.learn or 1,source="vendor",vendor=cheapest} end
  if ah then return {learned=false,fee=ah,at=recipe.learn or 1,source="ah",item=recipe.item} end
  return nil
end

-- from/to default to the current skill and the training cap; "Plan erstellen" passes its own range.
function CP:CheapestPath(key,from,to)
  local record=self.db and self.db.professions[key]
  local prof=self.Data.professions[key]
  if not record or not prof or (prof.gathering and not prof.crafting) then return nil end
  local skill,target=from or record.skill or 0,to or record.cap or 0
  if target<=skill then return nil end
  local ui=self.db.ui
  local token=table.concat({key,skill,target,tostring(self.SkillPolicyToken and self:SkillPolicyToken()),tostring(ui.knownRecipesOnly),
    tostring(ui.preferReliableSkill),tostring(ui.countSales),tostring(ui.economyCut),tostring(ui.includeAlts),
    tostring(self.pathModeOverride or ""),tostring(ui.fewestTrips),
    tostring(ui.fastestSkill),tostring(ui.favorRate)},":")
  self.pathCaches=self.pathCaches or {}
  local cache=self.pathCaches[token]
  if self.pathCache==nil then self.pathCaches={} ;cache=nil end
  if cache and now()-cache.at<CACHE_SECONDS then return cache.path end
  -- 1.3.0: three ways to compare – "cheap", "crafts" (fewest crafts), "trips" (learn only what is needed to go on).
  -- pathModeOverride is set by CompareRoutes for one calculation; otherwise the settings decide.
  local mode=self.pathModeOverride
  local reliable=ui.preferReliableSkill==true and mode==nil
  local fastest=(mode=="crafts") or (mode==nil and ui.fastestSkill==true)
  local fewTrips=(mode=="trips") or (mode==nil and ui.fewestTrips==true)

  local catalog=self:RecipeVendorCatalog(key)
  local recipes={}
  for id,r in pairs(catalog and catalog.recipes or {}) do recipes[id]=r end
  local ranges=self.SecondarySkillRanges and self.SecondarySkillRanges[key] or {}
  for id,native in pairs(self.db.recipes[key] or {}) do
    if not recipes[id] and native.learned and ranges[id] then recipes[id]={colors=ranges[id],name=native.name} end
  end

  local memo,candidates,unpriced={items={},notes={}},{},0
  for id,recipe in pairs(recipes) do
    local how=acquisition(self,key,id,recipe,target)
    if how and (how.learned or not self.db.ui.knownRecipesOnly) then
      local cost,known=0,true
      for item,n in pairs(materials(self,key,id,recipe)) do
        local p=unitPrice(self,memo,item,0)
        if not p then known=false;break end
        cost=cost+p*n
      end
      local sale=0
      if known and cost>0 and ui.countSales then
        local native=(self.db.recipes[key] or {})[id]
        local out=recipe.makes or (native and native.outputItemID)
        sale=math.min(cost,self:ItemVendorValue(out)*(recipe.count or recipe.yield or 1))
      end
      if not known or cost<=0 then unpriced=unpriced+1
      else
        -- Never free: a craft that sells for more than it costs still counts one copper per point.
        local net=math.max(1,cost-sale)
        local perPoint,chances,rank={},{},{}
        for k=math.max(skill,how.at or 0),target-1 do
          local chance=self:RecipeChanceAt(key,id,recipe,k)
          if chance>0 and self:SkillPolicyAllows(key,id,recipe,k,chance) then
            perPoint[k]=net/chance;chances[k]=chance
            -- "Sichere Farben bevorzugen": green has to be over 25 % cheaper per point to win.
            rank[k]=(reliable and chance<.5) and perPoint[k]*1.25 or perPoint[k]
            -- "Schnellster Weg": fewer crafts first; a lower chance only wins when it is many times cheaper
            -- (orange 1×, yellow ~0.7 → ~8×, green ~0.35 → ~540×).
            if fastest then rank[k]=perPoint[k]*(1/chance)^6 end
          end
        end
        if next(perPoint) then
          candidates[#candidates+1]={id=id,name=self:RecipeName(key,id,recipe.name),cost=net,sale=sale,perPoint=perPoint,chances=chances,rank=rank,
            learned=how.learned,fee=how.fee or 0,feeUnknown=how.feeUnknown,source=how.source,vendor=how.vendor,item=how.item,at=how.at}
        end
      end
    end
  end

  -- Best recipe per point among an allowed set; ties go to the higher chance (fewer crafts).
  local function solve(allowed)
    local pick,total={},0
    for k=skill,target-1 do
      local best,bestCost
      for _,c in ipairs(allowed) do
        local v=c.rank[k]
        if v and (not bestCost or v<bestCost*0.995 or (v<=bestCost*1.005 and c.chances[k]>best.chances[k])) then best,bestCost=c,v end
      end
      if not best then return pick,total,k end
      pick[k]=best;total=total+best.perPoint[k]
    end
    return pick,total,target
  end
  local allowed={}
  local pending={}
  for _,c in ipairs(candidates) do if c.learned then allowed[#allowed+1]=c elseif not c.feeUnknown then pending[#pending+1]=c end end
  local pick,total,reached=solve(allowed)
  local fees=0
  -- Add recipes to learn one at a time while one pays for its fee or extends the reachable range.
  -- Adding one recipe can only lower the per-point minimum, so its gain is a single pass over the points.
  for _=1,6 do
    local bestGain,bestIndex
    for i,c in ipairs(pending) do
      local gain,used=0,false
      for k=skill,reached-1 do
        local v=c.rank[k]
        local current=pick[k] and pick[k].rank[k]
        if v and current and v<current*0.995 then gain=gain+(current-v);used=true end
      end
      if c.perPoint[reached] then gain,used=math.huge,true
      elseif fewTrips then used=false end      -- fewest trips: learn only what is needed to go on
      gain=gain-c.fee
      if used and gain>0 and (not bestGain or gain>bestGain) then bestGain,bestIndex=gain,i end
    end
    if not bestIndex then break end
    local c=table.remove(pending,bestIndex)
    allowed[#allowed+1]=c;fees=fees+c.fee
    pick,total,reached=solve(allowed)
  end

  local segments={}
  for k=skill,reached-1 do
    local c=pick[k]
    local last=segments[#segments]
    if last and last.id==c.id then
      last.last=k+1;last.expected=last.expected+1/c.chances[k];last.cost=last.cost+c.perPoint[k]
    else
      segments[#segments+1]={id=c.id,name=c.name,first=k,last=k+1,expected=1/c.chances[k],cost=c.perPoint[k],
        learned=c.learned,fee=c.learned and 0 or c.fee,source=c.source,vendor=c.vendor,item=c.item,at=c.at,sale=c.sale,color=self:ReferenceDifficulty(
          (self:RecipeRangeData(key,c.id)),k)}
    end
  end
  -- Count each learned-on-the-way fee once, only for recipes the final path really uses.
  fees=0
  local charged={}
  for _,s in ipairs(segments) do
    s.crafts=math.max(1,math.ceil(s.expected-1e-9))
    if not s.learned and not charged[s.id] then charged[s.id]=true;fees=fees+(s.fee or 0) end
  end
  local perPointNow,optionsNow={},{}
  for _,c in ipairs(candidates) do
    perPointNow[c.id]=c.perPoint[skill]
    if c.perPoint[skill] then
      -- a fee to learn it, spread over the points the recipe can give from here
      local span=0;for _ in pairs(c.perPoint) do span=span+1 end
      optionsNow[#optionsNow+1]={id=c.id,name=c.name,perPoint=c.perPoint[skill]+(c.learned and 0 or (c.fee or 0)/math.max(1,span)),
        chance=c.chances[skill],learned=c.learned,fee=c.fee,source=c.source}
    end
  end
  table.sort(optionsNow,function(a,b) return a.perPoint<b.perPoint end)
  -- Materials the chosen path really uses, for the price age check and a targeted AH scan.
  local used={}
  local function addItem(item,depth)
    if used[item] or depth>2 then return end
    used[item]=true
    local note=memo.notes[item]
    for _,maker in ipairs(note and self:ItemMakers(item) or {}) do
      if maker.id==note.id then for mat in pairs(maker.recipe.mats or {}) do addItem(mat,depth+1) end end
    end
  end
  local altCrafts={}
  local quantities={}
  for _,s in ipairs(segments) do
    local recipe=recipes[s.id]
    for item,q in pairs(materials(self,key,s.id,recipe)) do
      addItem(item,0)
      if type(q)=="number" then quantities[item]=(quantities[item] or 0)+q*(s.expected or 0) end
    end
  end
  for item in pairs(used) do
    local note=memo.notes[item]
    if note then altCrafts[#altCrafts+1]={item=item,alt=note.alt,sure=note.sure,id=note.id,key=note.key,saving=note.saving} end
  end
  table.sort(altCrafts,function(a,b) return a.saving>b.saving end)
  local priceItems={}
  for item in pairs(used) do priceItems[#priceItems+1]=item end
  table.sort(priceItems)
  -- Price limits: how much more a material may cost before the next best recipe wins at some point.
  -- perPoint = (cost - sale) / chance, so one copper more per item adds quantity / chance per point.
  local priceLimits={}
  for k=skill,reached-1 do
    local c=pick[k]
    local alt,altC
    for _,o in ipairs(allowed) do
      local v=o.rank[k]
      if o~=c and v and (not alt or v<alt) then alt,altC=v,o end
    end
    if alt then
      local gap=math.max(0,alt-c.rank[k])
      local factor=(reliable and c.chances[k]<.5) and 1.25 or 1
      for item,q in pairs(materials(self,key,c.id,recipes[c.id])) do
        local p=memo[item]
        if type(p)=="number" and type(q)=="number" and q>0 then
          local limit=p+gap*c.chances[k]/(q*factor)
          local current=priceLimits[item]
          if not current or limit<current.price then priceLimits[item]={price=limit,alt=altC.name,recipe=c.name,at=k} end
        end
      end
    end
  end
  local path={key=key,from=skill,target=target,reached=reached,segments=segments,total=total+fees,fees=fees,
    unpriced=unpriced,perPointNow=perPointNow,optionsNow=optionsNow,priceItems=priceItems,altCrafts=altCrafts,priceLimits=priceLimits,quantities=quantities,maybeAlts=memo.maybe}
  self.pathCache=true
  self.pathCaches[token]={at=now(),path=path}
  self.lastPathByKey=self.lastPathByKey or {};self.lastPathByKey[key]=path
  return path
end

-- Market cost per expected point at the current skill, as used by the path (nil when not priced).
function CP:PathPointCost(key,id)
  local path=self:CheapestPath(key)
  return path and path.perPointNow[id]
end

function CP:PathSummaryLines(path)
  local lines={}
  for _,s in ipairs(path.segments) do
    lines[#lines+1]=string.format(L("Skill %d–%d: ca. %d× %s"),s.first,s.last,s.crafts,s.name)
      ..(s.learned and "" or (" · "..L("lernen")..(s.fee>0 and (" "..self:FormatCostMoney(s.fee)) or "")))
      ..(s.source=="ah" and (" · "..L("Rezept im AH")) or "")
      .."  ·  "..self:FormatCostMoney(s.cost+(s.fee or 0))
  end
  lines[#lines+1]=string.format(L("Gesamt bis %d: ca. %s"),path.reached,self:FormatCostMoney(path.total))
  for i,c in ipairs(path.altCrafts or {}) do
    if i<=3 then lines[#lines+1]=string.format(L("%s: %s kann es herstellen · spart ca. %s je Stück"),self:ItemName(c.item),c.alt,self:FormatCostMoney(c.saving)) end
  end
  if self.db.ui.countSales then lines[#lines+1]=L("Händlererlös der hergestellten Dinge ist abgezogen.") end
  local p=path.priceItems and self:PriceSummary(path.priceItems)
  if p and p.stale>0 then lines[#lines+1]=string.format(L("%d Preise älter als 3 Tage · am AH neu scannen."),p.stale) end
  if path.reached<path.target then lines[#lines+1]=string.format(L("Ab %d fehlen Preise oder Rezepte für einen sicheren Weg."),path.reached) end
  if path.unpriced>0 then lines[#lines+1]=string.format(L("%d Rezepte ohne vollständige Preise nicht verglichen · AH scannen."),path.unpriced) end
  return lines
end

-- The path as a readable tooltip: one row per stretch (skill range and recipe left, cost right), learning
-- on its own indented row, the total, then notes. Rows: {left, right, color} or {left, color, wrap=true}.
local SOURCE_TEXT={trainer=L("beim Lehrer lernen"),vendor=L("beim Händler kaufen"),ah=L("im AH kaufen")}
function CP:PathTooltip(path)
  local rows={}
  local white,grey,gold,learn={1,1,1},{.65,.68,.72},{1,.82,.30},{.55,.80,1}
  local nextLearn=self:NextLearnStep(path)
  if nextLearn then
    rows[#rows+1]={left=string.format(L("Als Nächstes lernen: %s ab Skill %d"),nextLearn.name,nextLearn.first),color=learn,wrap=true}
    rows[#rows+1]={left=" "}
  end
  for _,s in ipairs(path.segments) do
    rows[#rows+1]={left=string.format("%d–%d   %d× %s",s.first,s.last,s.crafts,s.name),right=self:FormatCostMoney(s.cost),color=white}
    if not s.learned then
      rows[#rows+1]={left="      "..(SOURCE_TEXT[s.source] or L("lernen")),right=(s.fee or 0)>0 and self:FormatCostMoney(s.fee) or "",color=learn}
    end
  end
  rows[#rows+1]={left=" "}
  rows[#rows+1]={left=string.format(L("Gesamt bis Skill %d"),path.reached),right=self:FormatCostMoney(path.total),color=gold}
  local notes={}
  if path.reached<path.target then notes[#notes+1]=string.format(L("Ab %d fehlen Preise oder Rezepte für einen sicheren Weg."),path.reached) end
  for i,c in ipairs(path.altCrafts or {}) do
    if i<=3 then notes[#notes+1]=string.format(L("%s: %s kann es herstellen · spart ca. %s je Stück"),self:ItemName(c.item),c.alt,self:FormatCostMoney(c.saving)) end
  end
  if self.db.ui.countSales then notes[#notes+1]=L("Händlererlös der hergestellten Dinge ist abgezogen.") end
  local p=path.priceItems and self:PriceSummary(path.priceItems)
  if p and p.stale>0 then notes[#notes+1]=string.format(L("%d Preise älter als 3 Tage · am AH neu scannen."),p.stale) end
  if path.unpriced>0 then notes[#notes+1]=string.format(L("%d Rezepte ohne vollständige Preise nicht verglichen · AH scannen."),path.unpriced) end
  if #notes>0 then rows[#rows+1]={left=" "} end
  for _,n in ipairs(notes) do rows[#rows+1]={left=n,color=grey,wrap=true} end
  return rows
end

-- The next recipe the path learns: shown ahead, so the trainer or vendor visit can be planned in time.
function CP:NextLearnStep(path)
  for _,s in ipairs(path and path.segments or {}) do
    if not s.learned then return s end
  end
end

-- 1.3.0: "Why this recipe?" – the chosen one next to the two best alternatives at the current skill:
-- cost per point (learning fee spread in), skill chance, learning fee, and whether the result is used later.
function CP:WhyRecipe(key,id)
  local path=self:CheapestPath(key)
  if not path or not path.optionsNow then return nil end
  local list={}
  for _,o in ipairs(path.optionsNow) do list[#list+1]=o end
  table.sort(list,function(a,b) return a.perPoint<b.perPoint end)
  local chosen,others=nil,{}
  for _,o in ipairs(list) do
    if o.id==id then chosen=o elseif #others<2 then others[#others+1]=o end
  end
  if not chosen then return nil end
  local function row(o)
    local recipe=(self:Catalog(key) or {recipes={}}).recipes[o.id]
    local makes=recipe and recipe.makes
    return {id=o.id,name=o.name,perPoint=o.perPoint,chance=o.chance or 0,fee=(not o.learned) and (o.fee or 0) or 0,
      learned=o.learned,usedLater=makes and path.quantities and (path.quantities[makes] or 0)>0 or false}
  end
  local out={chosen=row(chosen),others={}}
  for _,o in ipairs(others) do out.others[#out.others+1]=row(o) end
  return out
end

function CP:WhyRecipeLines(key,id)
  local why=self:WhyRecipe(key,id)
  if not why then return nil end
  local function line(r,mark)
    local parts={string.format(L("%s je Punkt"),self:FormatCostMoney(math.floor(r.perPoint))),string.format(L("Chance %d%%"),math.floor(r.chance*100+.5))}
    if r.fee>0 then parts[#parts+1]=L("lernen ")..self:FormatCostMoney(r.fee) end
    if r.usedLater then parts[#parts+1]=L("Ergebnis später gebraucht") end
    return {left=mark..r.name,right=table.concat(parts," · ")}
  end
  local rows={{left=L("Warum dieses Rezept?"),color={1,.82,.30}},line(why.chosen,"> ")}
  for _,r in ipairs(why.others) do rows[#rows+1]=line(r,"   ") end
  rows[#rows+1]={left=" "}
  return rows
end

-- 1.3.0: budget with a reserve. Yellow and green recipes need a varying number of crafts: per point the crafts
-- follow a geometric distribution (variance (1-p)/p²). The reserve covers about 9 of 10 runs (1.28 σ).
function CP:PathReserve(path)
  if not path or not path.segments then return 0 end
  local variance=0
  for _,s in ipairs(path.segments) do
    local points=math.max(0,(s.last or 0)-(s.first or 0))
    local expected=s.expected or s.crafts or 0
    if points>0 and expected>0 and (s.cost or 0)>0 then
      local p=math.min(1,points/expected)
      local perCraft=s.cost/expected
      variance=variance+perCraft*perCraft*points*(1-p)/(p*p)
    end
  end
  return math.floor(1.28*math.sqrt(variance)+.5)
end

-- 1.3.0: what a scan changed. Before the new prices are used, the current path is remembered; afterwards the new
-- one is compared: cost difference, recipes swapped, extra or fewer trainer/vendor visits.
local function snapshot(path)
  if not path then return nil end
  local ids,visits={},0
  for _,s in ipairs(path.segments or {}) do ids[s.id]=s.name;if not s.learned then visits=visits+1 end end
  return {total=path.total,reached=path.reached,ids=ids,visits=visits}
end
function CP:PathChange(before,after)
  if not before or not after then return nil end
  local added,removed={},{}
  for id,name in pairs(after.ids) do if not before.ids[id] then added[#added+1]=name end end
  for id,name in pairs(before.ids) do if not after.ids[id] then removed[#removed+1]=name end end
  table.sort(added);table.sort(removed)
  local diff=(after.total or 0)-(before.total or 0)
  if #added==0 and #removed==0 and math.abs(diff)<100 then return nil end
  return {diff=diff,added=added,removed=removed,visits=after.visits-before.visits}
end
function CP:PathChangeText(change)
  if not change then return nil end
  local parts={}
  if change.diff<=-100 then parts[#parts+1]=string.format(L("spart ca. %s"),self:FormatCostMoney(-change.diff))
  elseif change.diff>=100 then parts[#parts+1]=string.format(L("kostet ca. %s mehr"),self:FormatCostMoney(change.diff)) end
  if #change.added>0 then parts[#parts+1]=L("neu: ")..table.concat(change.added,", ") end
  if #change.removed>0 then parts[#parts+1]=L("entfällt: ")..table.concat(change.removed,", ") end
  if change.visits>0 then parts[#parts+1]=string.format(L("%d Lehrer-/Händlerbesuch(e) mehr"),change.visits)
  elseif change.visits<0 then parts[#parts+1]=string.format(L("%d Lehrer-/Händlerbesuch(e) weniger"),-change.visits) end
  return L("Nach dem Scan: neue Route ")..table.concat(parts," · ")
end
-- Called when the auction data changed (Auctionator scan): remember, recompute, compare, tell.
function CP:ComparePathAfterScan()
  local key=self.db and self.db.view
  if not key or not self.CheapestPath then return nil end
  -- The last path computed with the old prices (even if its cache has expired meanwhile).
  local before=snapshot((self.lastPathByKey or {})[key] or self:CheapestPath(key))
  self.pathCache=nil
  local after=snapshot(self:CheapestPath(key))
  local change=self:PathChange(before,after)
  local text=self:PathChangeText(change)
  self.lastPathChange=text and {key=key,text=text,at=type(time)=="function" and time() or 0} or nil
  if text then self:Say(text) end
  return change
end

-- 1.3.0: compare three ways side by side. Each: what you buy, learning fees, number of crafts and visits
-- (the trainer counts once, each vendor once, the AH once).
local MODES={{key="cheap",label="Wenig Gold"},{key="crafts",label="Wenig Herstellungen"},{key="trips",label="Wenig Wege"}}
function CP:RouteSummary(key,path)
  if not path then return nil end
  local crafts,stops,places=0,0,{}
  for _,s in ipairs(path.segments or {}) do
    crafts=crafts+(s.crafts or 0)
    if not s.learned then
      local t=self.LearnTarget and self:LearnTarget(key,s.id)
      local place=t and (t.kind=="trainer" and "trainer" or (t.kind=="ah" and "ah" or (t.name or "?"))) or ("?"..s.id)
      if not places[place] then places[place]=true;stops=stops+1 end
    end
  end
  return {total=path.total or 0,fees=path.fees or 0,buy=(path.total or 0)-(path.fees or 0),crafts=crafts,stops=stops,reached=path.reached,first=path.segments and path.segments[1]}
end
function CP:CompareRoutes(key,first,last)
  local out={}
  for _,m in ipairs(MODES) do
    self.pathModeOverride=m.key
    local ok,path=pcall(self.CheapestPath,self,key,first,last)
    self.pathModeOverride=nil
    local summary=ok and self:RouteSummary(key,path)
    if summary then summary.mode=m.key;summary.label=L(m.label);out[#out+1]=summary end
  end
  return out
end
function CP:CurrentRouteMode()
  local ui=self.db.ui
  if ui.fewestTrips then return "trips" elseif ui.fastestSkill then return "crafts" end
  return "cheap"
end
function CP:UseRouteMode(mode)
  local ui=self.db.ui
  ui.fastestSkill=mode=="crafts"
  ui.fewestTrips=mode=="trips"
  self.pathCache=nil
  if self.Render then self:Render() end
end
function CP:RouteCompareCards(key,first,last)
  local record=self.db.professions[key] or {}
  first,last=first or record.skill or 0,last or record.cap or 0
  local routes=self:CompareRoutes(key,first,last)
  if #routes<2 then return {} end
  local current=self:CurrentRouteMode()
  local baseline
  for _,r in ipairs(routes) do if r.mode==current and r.reached==last then baseline=r;break end end
  local cards={{sectionHeader=true,title=string.format(L("WEGE VERGLEICHEN · SKILL %d–%d"),first,last)}}
  for _,r in ipairs(routes) do
    local mode=r.mode
    local detail=string.format(L("Materialwert %s · Lernen %s · %d Herstellungen · %d Lernwege"),
      self:FormatCostMoney(math.max(0,r.buy)),self:FormatCostMoney(r.fees),r.crafts,r.stops)
    if (r.reached or 0)<last then
      detail=detail.."\n"..string.format(L("reicht bis %d"),r.reached or first)
    elseif baseline and baseline~=r then
      local cost=r.total-baseline.total
      detail=detail.."\n"..string.format(L("Gegenüber aktiv: %s · %+d Herstellungen · %+d Lernwege"),
        (cost<0 and "−" or "+")..self:FormatCostMoney(math.abs(cost)),r.crafts-baseline.crafts,r.stops-baseline.stops)
    end
    cards[#cards+1]={title=r.label..": "..self:FormatCostMoney(r.total),detail=detail,
      footer=mode==current and L("Aktiv") or L("Klick: diesen Weg nutzen"),color=mode==current and "gold" or "blue",grid=true,
      action=function() CP:UseRouteMode(mode) end}
  end
  return cards
end
