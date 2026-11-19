-- 1.3.0: recipe collection. Which recipes of a profession are still missing, how far the collection is, filters by
-- source (trainer, vendor, reputation, quest, drop) and a tour through the missing recipes of the current zone.
-- The wishlist is part of it: wished recipes come first and keep their star.
local _,CP=...
local L=CP.L

local KINDS={{key="all",label="Alle"},{key="trainer",label="Lehrer"},{key="vendor",label="Händler"},{key="rep",label="Ruf"},{key="quest",label="Quest"},{key="drop",label="Drop"}}
CP.CollectionKinds=KINDS

-- Source kinds of one recipe (a recipe can have several).
function CP:RecipeSourceKinds(recipe)
  local kinds={}
  for _,s in ipairs(recipe and recipe.get or {}) do
    if s.kind=="vendor" and (s.rep or s.favor or s.favorStanding) then kinds.rep=true
    elseif s.kind=="vendor" then kinds.vendor=true
    elseif s.kind=="trainer" or s.kind=="quest" or s.kind=="drop" then kinds[s.kind]=true end
  end
  if recipe and recipe.rep then kinds.rep=true end
  return kinds
end

-- Collection state of a profession: total available, learned, missing rows (wished first, then by skill).
function CP:RecipeCollection(key)
  local catalog=self:RecipeVendorCatalog(key)
  local total,learned,missing=0,0,{}
  for id,recipe in pairs(catalog and catalog.recipes or {}) do
    if type(recipe)=="table" and not recipe.unavailable then
      local kinds=self:RecipeSourceKinds(recipe)
      local start=false
      for _,s in ipairs(recipe.get or {}) do if s.kind=="start" then start=true end end
      total=total+1
      local native=(self.db.recipes[key] or {})[id]
      if (native and native.learned) or start then learned=learned+1
      else missing[#missing+1]={id=id,recipe=recipe,kinds=kinds,learn=recipe.learn or 0,wished=self:IsWished(key,id)} end
    end
  end
  table.sort(missing,function(a,b)
    if a.wished~=b.wished then return a.wished end
    if a.learn~=b.learn then return a.learn<b.learn end
    return a.id<b.id
  end)
  return {total=total,learned=learned,missing=missing}
end

-- Where a missing recipe is, if known: vendor or boss location (RecipeGoTo).
local function zoneOf(self,key,row)
  local go=self.RecipeGoTo and self:RecipeGoTo(key,row.id)
  return go and go.location and go.location.zone,go
end

function CP:CurrentZoneName()
  if type(GetRealZoneText)=="function" then local z=GetRealZoneText();if type(z)=="string" and z~="" then return z end end
  if type(GetZoneText)=="function" then local z=GetZoneText();if type(z)=="string" and z~="" then return z end end
  return nil
end

-- Missing recipes in the current zone, as tour stops (one stop per place).
function CP:CollectionZoneStops(key)
  local zone=self:CurrentZoneName()
  if not zone then return {},nil end
  local stops,byPlace={},{}
  for _,row in ipairs(self:RecipeCollection(key).missing) do
    local z,go=zoneOf(self,key,row)
    if z==zone and go then
      local place=go.label..":"..tostring(go.location.x)
      local stop=byPlace[place]
      if not stop then
        stop={kind=go.kind=="vendor" and "vendor" or "drop",name=go.label,location=go.location,recipes={},seen={},cost=0}
        byPlace[place]=stop;stops[#stops+1]=stop
      end
      stop.recipes[#stop.recipes+1]={id=row.id,name=self:RecipeName(key,row.id,row.recipe.name),at=row.learn}
    end
  end
  return stops,zone
end

function CP:StartCollectionTour(key)
  local stops,zone=self:CollectionZoneStops(key)
  if #stops==0 then self:Say(L("In diesem Gebiet fehlt dir kein Rezept mit bekanntem Ort."));return false end
  self.tour={key=key,stops=stops,index=1,collection=true}
  if self.GoTourStop then self:GoTourStop() end
  self:Say(string.format(L("Sammeltour %s: %d Halte · Wegpunkt zum ersten gesetzt."),zone,#stops))
  return true
end

function CP:CollectionCards(key)
  local ui=self.db.ui
  local filter=ui.collectFilter or "all"
  local onlyZone=ui.collectZone==true
  local c=self:RecipeCollection(key)
  local pct=c.total>0 and math.floor(c.learned/c.total*100+.5) or 0
  local cards={{title=string.format(L("Sammlung: %d von %d Rezepten (%d %%)"),c.learned,c.total,pct),
    detail=L("Alle Rezepte dieses Berufs, die es in WoW Forever gibt. Fehlende mit Quelle; Wunschrezepte stehen oben. Berufsfenster einmal öffnen, damit CraftPilot weiß, was du schon kannst."),
    color="gold"}}
  -- Filters
  for _,k in ipairs(KINDS) do
    local key2=k.key
    local n=0
    for _,row in ipairs(c.missing) do if key2=="all" or row.kinds[key2] then n=n+1 end end
    cards[#cards+1]={title=L(k.label).." ("..n..")",footer=filter==key2 and L("Aktiv") or L("Klick: filtern"),color=filter==key2 and "gold" or "blue",grid=true,
      action=function() ui.collectFilter=key2;CP:Render() end}
  end
  local zone=self:CurrentZoneName()
  local stops=self:CollectionZoneStops(key)
  cards[#cards+1]={title=onlyZone and string.format(L("Nur %s"),zone or "?") or L("Alle Gebiete"),
    detail=string.format(L("%d Halte mit fehlenden Rezepten in %s"),#stops,zone or "?"),
    footer=L("Klick: Gebiet umschalten"),color=onlyZone and "gold" or "blue",grid=true,
    action=function() ui.collectZone=not onlyZone;CP:Render() end}
  cards[#cards+1]={title=L("Sammeltour in diesem Gebiet"),detail=#stops>0 and string.format(L("%d Halte · Wegpunkt zum ersten, danach weiter wie bei der Lerntour"),#stops) or L("Hier fehlt dir kein Rezept mit bekanntem Ort."),
    footer=#stops>0 and L("Klick: Tour starten") or "",color=#stops>0 and "green" or "blue",grid=true,
    action=#stops>0 and function() CP:StartCollectionTour(key) end or nil}
  cards[#cards+1]={sectionHeader=true,title=L("FEHLENDE REZEPTE")}
  local shown=0
  for _,row in ipairs(c.missing) do
    local fits=filter=="all" or row.kinds[filter]
    if fits and onlyZone then fits=(zoneOf(self,key,row))==zone end
    if fits then
      shown=shown+1
      if shown>60 then cards[#cards+1]={title=L("Weitere mit Filter eingrenzen"),color="blue"};break end
      local id=row.id
      local action,right=self.RecipeCardActions(self,key,id)
      cards[#cards+1]={title=(row.wished and "|cffffd200* |r" or "")..self:RecipeName(key,id,row.recipe.name),
        detail=self:RecipeSourceText(key,id),footer=row.learn>0 and (L("ab Skill ")..row.learn) or "",
        buttons=self:RecipeButtons(key,id),color=row.wished and "gold" or "blue",icon=self.RecipeIcon and self:RecipeIcon(key,id),
        tooltipItem=row.recipe.item,recipeKey=key,recipeID=id,showMarket=false,action=action,rightAction=right}
    end
  end
  if shown==0 then cards[#cards+1]={title=L("Nichts offen"),detail=L("Mit diesem Filter fehlt dir kein Rezept."),color="green"} end
  return cards
end
