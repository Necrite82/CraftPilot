-- 1.1.0: when to buy. CraftPilot notes the auction price of the items it looks at once a day (per realm) and
-- compares today's price with the days before. A material the cheapest path still needs that is clearly below its
-- usual price is named with what buying now saves. Display only; nothing is bought.
local _,CP=...
local L=CP.L
local DAY=86400
local KEEP=14
local function today() return math.floor((type(time)=="function" and time() or 0)/DAY) end

local function store(self)
  local root=self.account or self.db
  if not root then return nil end
  root.priceTrend=root.priceTrend or {}
  local me=self.CurrentCharacter and self:CurrentCharacter()
  local realm=(me and me.realm) or "?"
  root.priceTrend[realm]=root.priceTrend[realm] or {}
  return root.priceTrend[realm]
end

-- Today's lowest seen price; days older than two weeks are dropped.
function CP:RecordPrice(item,price)
  if type(item)~="number" or type(price)~="number" or price<=0 then return end
  local s=store(self);if not s then return end
  local d=today()
  local days=s[item] or {}
  s[item]=days
  if not days[d] or price<days[d] then days[d]=price end
  for day in pairs(days) do if day<=d-KEEP then days[day]=nil end end
end

-- Average of the days before today, and how many there are.
function CP:UsualPrice(item)
  local s=store(self);local days=s and s[item]
  if not days then return nil,0 end
  local d,sum,n=today(),0,0
  for day,p in pairs(days) do if day<d then sum=sum+p;n=n+1 end end
  if n==0 then return nil,0 end
  return sum/n,n
end

-- Materials the path still has to buy that are at least 20 % below their usual price, biggest saving first.
function CP:BuyTimingDeals(key,limit)
  local path=self.CheapestPath and self:CheapestPath(key)
  if not path or not path.quantities then return {} end
  local out={}
  for item,q in pairs(path.quantities) do
    local p=self:PriceDetails(item)
    local now=p.auction
    if now then
      self:RecordPrice(item,now)
      local usual,days=self:UsualPrice(item)
      local need=math.ceil(q)-(self:ItemAvailability(item) or 0)
      if usual and days>=3 and need>0 and now<=usual*.8 and p.source~=L("Haendler") then
        local saving=math.floor((usual-now)*need)
        if saving>=5000 then
          out[#out+1]={id=item,name=self:ItemName(item),now=now,usual=usual,need=need,saving=saving,
            percent=math.floor((1-now/usual)*100+.5)}
        end
      end
    end
  end
  table.sort(out,function(a,b) return a.saving>b.saving end)
  if limit then for i=#out,limit+1,-1 do out[i]=nil end end
  return out
end

function CP:BuyTimingText(deal)
  return string.format(L("%s heute %d %% unter dem Schnitt – %d kaufen spart ca. %s"),
    deal.name,deal.percent,deal.need,self:FormatCostMoney(deal.saving))
end

function CP:BuyTimingCards(key)
  local deals=self:BuyTimingDeals(key,5)
  if #deals==0 then return {} end
  local cards={{sectionHeader=true,title=L("JETZT GÜNSTIG")}}
  for _,d in ipairs(deals) do
    local id,need=d.id,d.need
    cards[#cards+1]={title=string.format(L("%s · %d %% unter Schnitt"),d.name,d.percent),
      detail=string.format(L("Heute %s statt sonst %s je Stück. Dein Weg braucht noch %d."),self:FormatCostMoney(d.now),self:FormatCostMoney(math.floor(d.usual)),d.need),
      footer=string.format(L("Spart ca. %s · Klick am AH: suchen"),self:FormatCostMoney(d.saving)),color="green",
      action=function() CP:SearchItems({{id=id,quantity=need}},L("Jetzt günstig"),L("Auctionator sucht das günstige Material.")) end}
  end
  return cards
end
