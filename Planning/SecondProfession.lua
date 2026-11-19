-- 1.1.0: two professions together. Materials the cheapest path of one profession needs that this character can
-- make with another of its professions (bars from ore with Mining, bolts with Tailoring, ...): what making them
-- yourself saves against buying, and how many skill points it gives in the second profession on the way.
local _,CP=...
local L=CP.L
local D=CP.Data

-- Options for profession `key`: {item, need, via={key,id,recipe}, unitBuy, unitMake, saving, points, prof, skill}.
function CP:SecondProfessionOptions(key)
  local path=self.CheapestPath and self:CheapestPath(key)
  if not path or not path.quantities then return {} end
  local out={}
  for item,q in pairs(path.quantities) do
    local need=math.ceil(q)-(self:ItemAvailability(item) or 0)
    if need>0 then
      for _,p in ipairs(self.ItemProducers and self:ItemProducers(item) or {}) do
        local mine=p.key~=key and self.db.professions[p.key]
        local learn=p.recipe.learn or 1
        if mine and (mine.skill or 0)>=learn then
          local yield=math.max(1,p.recipe.yield or 1)
          local matCost,complete=0,true
          for mat,n in pairs(p.recipe.mats) do
            local price=self:PriceDetails(mat).price
            if price then matCost=matCost+price*n else complete=false end
          end
          local unitBuy=self:PriceDetails(item).price
          local unitMake=complete and matCost/yield or nil
          local crafts=math.ceil(need/yield)
          -- Expected points: chance at the current skill, held while the colour lasts (an estimate, never more than crafts).
          local chance=self.RecipeChanceAt and self:RecipeChanceAt(p.key,p.id,p.recipe,mine.skill) or 0
          local room=math.max(0,((p.recipe.colors or {})[4] or 0)-(mine.skill or 0))
          local points=math.min(room,math.floor(crafts*chance+.5))
          local saving=unitBuy and unitMake and math.floor((unitBuy-unitMake)*need) or nil
          if (saving and saving>0) or points>0 then
            out[#out+1]={item=item,need=need,via=p,unitBuy=unitBuy,unitMake=unitMake,saving=saving,points=points,crafts=crafts,
              prof=p.key,skill=mine.skill}
          end
          break
        end
      end
    end
  end
  table.sort(out,function(a,b)
    local sa,sb=(a.saving or 0)+a.points*1000,(b.saving or 0)+b.points*1000
    if sa~=sb then return sa>sb end
    return a.item<b.item
  end)
  return out
end

local function profName(key) return (D.professions[key] or {}).name or key end

function CP:SecondProfessionText(o)
  local parts={string.format(L("%d %s selbst herstellen (%s %d)"),o.need,self:ItemName(o.item),profName(o.prof),o.skill)}
  if o.saving and o.saving>0 then parts[#parts+1]=string.format(L("spart ca. %s"),self:FormatCostMoney(o.saving)) end
  if o.points>0 then parts[#parts+1]=string.format(L("bringt ca. %d %s-Punkte"),o.points,profName(o.prof)) end
  return table.concat(parts," · ")
end

function CP:SecondProfessionCards(key)
  local options=self:SecondProfessionOptions(key)
  if #options==0 then return {} end
  local cards={{sectionHeader=true,title=L("ZWEITER BERUF")}}
  for i,o in ipairs(options) do
    if i>4 then break end
    local mats={}
    for mat,n in pairs(o.via.recipe.mats) do mats[#mats+1]=(n*o.crafts).."× "..self:ItemName(mat) end
    table.sort(mats)
    cards[#cards+1]={title=self:SecondProfessionText(o),
      detail=string.format(L("%d× %s · braucht %s"),o.crafts,self.RecipeName and self:RecipeName(o.prof,o.via.id) or o.via.recipe.name or self:ItemName(o.item),table.concat(mats,", ")),
      footer=o.unitMake and o.unitBuy and string.format(L("Je Stück: selbst ca. %s · AH %s"),self:FormatCostMoney(math.floor(o.unitMake)),self:FormatCostMoney(o.unitBuy)) or L("Preise unvollständig"),
      color=(o.saving or 0)>0 and "green" or "blue",tooltipItem=o.item}
  end
  return cards
end
