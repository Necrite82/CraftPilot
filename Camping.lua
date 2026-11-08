-- Own display integration; raw reference data retains its original notices.
local _,CP=...
local L=CP.L
CP.campingSource="https://news.blizzard.com/en-us/article/24301516/gather-around-the-campfire-in-world-of-warcraft-forever"
local function factionFits(row)
  local side=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
  return not row.faction or row.faction=="AH" or row.faction=="B" or row.faction==(side=="Horde" and "H" or "A")
end
function CP:CampingRecipes(key)
  local rows,seen={},{}
  local function add(object,base,tier)
    if seen[object.item] or not factionFits(object) or (key and object.prof~=key) then return end
    seen[object.item]=true
    local catalog=self:Catalog(object.prof)
    local recipe=(catalog and catalog.recipes[object.maker]) or (self.CampingRecipeData[object.prof] or {})[object.maker]
    local native=(self.db.recipes[object.prof] or {})[object.maker]
    local mats=recipe and recipe.mats or object.mats
    if native then
      mats=nil
      if native.mats then mats={};for _,mat in ipairs(native.mats) do mats[mat[1]]=mat[2] end end
    end
    local ways,unique={},{}
    for _,source in ipairs(recipe and recipe.get or {}) do
      local text
      if source.kind=="trainer" then text=L("Lehrer; aktuelles Angebot prüfen")
      elseif source.kind=="quest" then text=L("Quest ")..tostring(source.quest or "?")
      elseif source.kind=="drop" then text=L("Drop im alten Katalog; Boss nicht belegt")
      elseif source.kind=="vendor" then text=L("Händler ")..tostring(source.npc or "?")
      elseif source.kind=="start" then text=L("Startrezept") end
      if text and factionFits(source) and not unique[text] then ways[#ways+1]=text;unique[text]=true end
    end
    rows[#rows+1]={id=object.maker,object=object,base=base,recipe=recipe,prof=object.prof,tier=tier,
      mats=mats,materialsLive=native and native.mats~=nil,
      learned=native and native.learned==true and native.disabled~=true,
      name=self:RecipeName(object.prof,object.maker,object.name),
      source=#ways>0 and table.concat(ways," / ") or L("Bezugsquelle unbekannt")}
  end
  for _,fire in ipairs(self.CAMP.fires) do add(fire,nil,L("Campfire")) end
  for _,base in ipairs(self.CAMP.features) do
    if factionFits(base) then
      add(base,base,L("Grundobjekt"))
      for _,upgrade in ipairs(base.upgrades or {}) do add(upgrade,base,L("Blueprint-Ausbau")) end
    end
  end
  for _,other in ipairs(self.CAMP.others) do add(other,nil,L("Blueprint-Ausbau")) end
  table.sort(rows,function(a,b)
    if a.prof~=b.prof then return a.prof<b.prof end
    local aa=a.recipe and a.recipe.learn or 999
    local bb=b.recipe and b.recipe.learn or 999
    if aa~=bb then return aa<bb end
    return a.name<b.name
  end)
  return rows
end
local effectsDE={
  ["Usable for recipes that require it"]="Handwerksstation für entsprechende Rezepte",
  ["Purchase reagents"]="Reagenzien einkaufen",
  ["Allows you and others nearby to buy reagents and repair gear"]="Reagenzienhandel und Reparaturen",
  ["Allows the creation of certain reagents"]="Herstellung bestimmter Reagenzien",
  ["Spawns a common mining node over time"]="Erzeugt mit der Zeit ein gewöhnliches Erzvorkommen",
  ["Allows seeds to be multiplied or combined into rarer tiers"]="Samen vermehren oder zu selteneren Stufen kombinieren",
  ["Will grow herbs over time from seeds planted"]="Kräuter aus eingepflanzten Samen ziehen",
  ["Grants the ability to catch uncommon fish for 1 hour, provides Fishing Skill lures"]="Eine Stunde ungewöhnliche Fische und Angelköder",
  ["Grants the ability to catch rare fish for 1 hour, provides Fishing Skill lures"]="Eine Stunde seltene Fische und Angelköder",
  ["Contains healing potions and anti-venom"]="Heiltränke und Gegengifte",
  ["Contains healing potions and poultices"]="Heiltränke und Umschläge",
  ["Enables more efficient disenchanting"]="Effizienteres Entzaubern",
  ["Rested experience up to 5% of a level"]="Erholungsbonus bis zu 5% einer Stufe",
  ["Allows players to read it and gain Track Beasts"]="Ermöglicht Wildtiere aufspüren",
  ["Contains Stamina-boosting food"]="Nahrung mit Ausdauerbonus",
  ["Required for the most advanced cooking recipes"]="Station für fortgeschrittene Kochrezepte",
  ["Strength of Earth Totem"]="Totem der Erdstärke",["Blessing of Wisdom"]="Segen der Weisheit",
  ["Blessing of Might"]="Segen der Macht",["Arcane Intellect"]="Arkane Intelligenz",
  ["Blessing of Kings"]="Segen der Könige",["Power Word: Fortitude"]="Machtwort: Seelenstärke",
  ["Divine Spirit"]="Göttlicher Wille",["Mark of the Wild"]="Mal der Wildnis",["Moonkin Aura"]="Aura des Mondkin",
}
function CP:CampingText(text)
  text=text or ""
  if self.locale~="deDE" then return text end
  if effectsDE[text] then return effectsDE[text] end
  for _,pair in ipairs({{"critical strike chance with all spells and attacks","kritische Trefferchance für Zauber und Angriffe"},
    {"all resistances","alle Widerstände"},{"all stats","alle Attribute"},{"melee Attack Power","Nahkampfangriffskraft"},
    {"Mana every 5 sec","Mana alle 5 Sek."},{"Strength","Stärke"},{"Stamina","Ausdauer"},{"Intellect","Intelligenz"},
    {"Spirit","Willenskraft"},{"Armor","Rüstung"},{"stats","Attribute"},{" and "," und "}}) do text=text:gsub(pair[1],pair[2]) end
  return text
end
function CP:CampingCards(key)
  local page=self.db.ui.campingPage or "fires"
  local filter=self.db.ui.campingAll==false and key or nil
  local cards={{title=L("Camping: Grundobjekte und Ausbauten"),
    detail=L("Eine Minute sitzen oder herstellen; Camp-Objekte teilen eine Stunde Abklingzeit."),
    footer=L("Aktuelle Tooltips haben Vorrang vor dem Referenzbuild 1.60.1.70425."),color="gold"}}
  if page=="buffs" then
    local seen={}
    for _,base in ipairs(self.CAMP.features) do
      if factionFits(base) and not seen[base.prof] and (not filter or base.prof==filter) then
        seen[base.prof]=true
        local effect,live
        if C_Spell and type(C_Spell.GetSpellDescription)=="function" then
          local ok,text=pcall(C_Spell.GetSpellDescription,base.spell)
          if ok and type(text)=="string" and text~="" then effect=text;live=true end
        end
        if not effect then
          local level=type(UnitLevel)=="function" and UnitLevel("player") or 60
          for _,step in ipairs(base.gives or {}) do effect=step[2];if level<=step[1] then break end end
          effect=self:CampingText(effect)
        end
        local item=base.item
        cards[#cards+1]={title=self.Data.professions[base.prof].name.." | "..self:RecipeName(base.prof,base.maker,base.name),
          detail=effect,footer=live and L("Aktueller Zaubertext aus dem Client") or L("Buffstaffel aus älterem Referenzbuild"),
          icon=self.Data.professionIcons[base.prof],tooltipItem=item,tooltipSpell=base.spell,color="blue",
          action=function() CP.db.ui.campingBuff=CP.db.ui.campingBuff~=item and item or nil;CP:Render() end}
        if base.exclusive then cards[#cards+1]={title=L("Nicht kombinierbar mit: ")..self:CampingText(base.exclusive),
          detail=L("Kein zusätzlicher Stapelbonus mit diesem Klassenbuff."),footer=L("Referenzangabe; aktuellen Tooltip prüfen."),color="gold"} end
        if self.db.ui.campingBuff==item then
          for _,step in ipairs(base.gives or {}) do cards[#cards+1]={title=string.format(L("Bis Charakterstufe %d"),step[1]),
            detail=self:CampingText(step[2]),footer=L("Ältere Buffstaffel, keine Live-Bestätigung."),color="gold"} end
        end
      end
    end
    if not filter or filter=="cooking" then cards[#cards+1]={title=self.Data.professions.cooking.name,
      detail=L("Campfires schaffen Plätze; weitere Kochobjekte bieten Nahrung und Kochstationen."),
      footer=L("Kein zusätzlicher allgemeiner Attributbuff wird behauptet."),color="blue"} end
  else
    for _,row in ipairs(self:CampingRecipes(filter)) do
      if (page=="fires")== (row.object.slots~=nil) then
        local item=row.object.item
        cards[#cards+1]={title=self.Data.professions[row.prof].name.." | "..row.name.." | "..(row.learned and L("Erlernt") or L("Nicht als erlernt erfasst")),
          detail=row.object.slots and (row.object.slots..L(" Camp-Plätze")) or (self:CampingText(row.object.adds)~="" and self:CampingText(row.object.adds) or row.tier),
          footer=row.source,tooltipItem=item,tooltipSpell=row.object.spell,icon=self:RecipeIcon(row.prof,row.id),color=row.learned and "green" or "blue",
          action=function() CP.db.ui.campingRecipe=CP.db.ui.campingRecipe~=item and item or nil;CP:Render() end}
        if self.db.ui.campingRecipe==item then
          cards[#cards+1]={title=L("Lernskill im Katalog: ")..tostring(row.recipe and row.recipe.learn or L("unbekannt")),
            detail=L("Herstellung, Lernen und Benutzung können unterschiedliche Voraussetzungen haben."),
            footer=L("Benutzungsanforderung im Gegenstands-Tooltip prüfen."),color="gold"}
          if row.recipe and row.recipe.item then cards[#cards+1]={title=L("Blueprint-Gegenstand: ")..self:ItemName(row.recipe.item),
            detail=L("Dropchance und konkreter Boss sind hier nicht bestätigt."),footer=row.source,tooltipItem=row.recipe.item,color="gold"} end
          local mats={}
          for id,n in pairs(row.mats or {}) do mats[#mats+1]={id=id,n=n} end
          table.sort(mats,function(a,b) return a.id<b.id end)
          for _,mat in ipairs(mats) do
            local missing=math.max(0,mat.n-self:ItemCount(mat.id))
            local price=self:Price(mat.id)
            cards[#cards+1]={title=mat.n.."x "..self:ItemName(mat.id),detail=L("Fehlt: ")..missing,
              footer=(row.materialsLive and L("Aus dem aktuellen Berufsfenster") or L("Früherer Katalogstand; im Spiel prüfen")).." | "..(price and self:FormatMoney(price*missing) or L("Preis fehlt")),
              tooltipItem=mat.id,color=missing==0 and "green" or "blue"}
          end
          if #mats==0 then cards[#cards+1]={title=L("Materialdaten unvollständig"),detail=L("Berufsfenster öffnen und aktualisieren."),color="gold"} end
        end
      end
    end
    if page=="objects" and (not filter or filter=="skinning") then cards[#cards+1]={title="Trapper's Workbench",
      detail=L("Zusätzlicher Guide-Hinweis; nicht im eingebundenen Camping-Build enthalten."),
      footer=L("Keine bestätigten Material-, Buff- oder Rezeptdaten hinterlegt."),color="gold"} end
  end
  cards[#cards+1]={title=L("Herkunft und Grenzen"),detail=L("Blizzard-Übersicht und gekennzeichneter Craft-Ladder-Referenzstand."),
    footer=L("Keine vollständige aktuelle Boss-Dropdatenbank; fehlende Werte werden nicht geraten."),color="gold"}
  return cards
end
