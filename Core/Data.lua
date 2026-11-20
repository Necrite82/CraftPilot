local _, CP = ...
local L=CP.L
CP.Data = {}
local D = CP.Data

D.version = "Forever 1.60.x / 2026-11-08"
D.order = {"engineering", "mining", "blacksmithing", "enchanting", "tailoring", "leatherworking", "herbalism", "alchemy", "skinning", "cooking", "firstaid", "fishing"}
D.professions = {
  engineering = {id=202, name=L("Ingenieurskunst"), short=L("Ingi")},
  mining = {id=186, name=L("Bergbau"), short=L("Bergbau"), gathering=true},
  blacksmithing = {id=164, name=L("Schmiedekunst"), short=L("Schmied")},
  enchanting = {id=333, name=L("Verzauberkunst"), short=L("Verzaub.")},
  tailoring = {id=197, name=L("Schneiderei"), short=L("Schneider")},
  leatherworking = {id=165, name=L("Lederverarbeitung"), short=L("Leder")},
  herbalism = {id=182, name=L("Kräuterkunde"), short=L("Kräuter"), gathering=true},
  alchemy = {id=171, name=L("Alchemie"), short=L("Alchemie")},
  skinning = {id=393, name=L("Kürschnerei"), short=L("Kürschner"), gathering=true, crafting=true, ranksUnverified=true},
  cooking = {id=185, name=L("Kochen"), short=L("Kochen"), secondary=true},
  firstaid = {id=129, name=L("Erste Hilfe"), short=L("Erste Hilfe"), secondary=true},
  fishing = {id=356, name=L("Angeln"), short=L("Angeln"), secondary=true, gathering=true, crafting=true},
}
D.professionIcons = {
  engineering="Interface\\Icons\\Trade_Engineering",
  mining="Interface\\Icons\\Trade_Mining",
  blacksmithing="Interface\\Icons\\Trade_BlackSmithing",
  enchanting="Interface\\Icons\\Trade_Engraving",
  tailoring="Interface\\Icons\\Trade_Tailoring",
  leatherworking="Interface\\Icons\\Trade_LeatherWorking",
  herbalism="Interface\\Icons\\Trade_Herbalism",
  alchemy="Interface\\Icons\\Trade_Alchemy",
  skinning="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
  cooking="Interface\\Icons\\INV_Misc_Food_15",
  firstaid="Interface\\Icons\\Spell_Holy_SealOfSacrifice",
  fishing="Interface\\Icons\\Trade_Fishing",
}
D.rankLevelExceptions = {herbalism = { [75]=0, [150]=0, [225]=0, [300]=0 }}
D.ranks = {
  {cap=75, min=0, level=1, name=L("Lehrling")},
  {cap=150, min=50, level=10, name=L("Geselle")},
  {cap=225, min=125, level=20, name=L("Experte")},
  {cap=300, min=200, level=35, name=L("Fachmann")},
}
-- The following original milestone summaries are a general 1-300 roadmap, not
-- a copied leveling guide or a source of exact reagent/skill-up calculations.
-- The client recipe book always determines actual available and learned crafts.
D.stages = {
  -- Milestones are deliberately split at material and profession-rank changes.
  -- They are ORIENTATION, not a recipe shopping list or guaranteed skill-ups.
  engineering = {
    {1,30,L("Rauer Stein: erstes Sprengpulver und einfache Kupferbauteile")},
    {30,50,L("Kupferbolzen, Röhren und frühe Werkzeuge")},
    {50,75,L("Kupferbauteile bis zum nächsten Ausbildungsrang")},
    {75,100,L("Grober Stein und erste Bronze-Bauteile")},
    {100,125,L("Bronze, leichte Sprengstoffe und Vorprodukte")},
    {125,150,L("Schwere Sprengstoffe und verbesserte Mechanik")},
    {150,175,L("Eisen und Bronze; bekannte Alternativen prüfen")},
    {175,200,L("Robuster Stein, Mithril und Zubehör")},
    {200,225,L("Mithrilgeräte und mechanische Teile")},
    {225,250,L("Mithrilbauteile und spezialisierte Vorprodukte")},
    {250,275,L("Thorium und dichtes Sprengpulver")},
    {275,300,L("Hochstufige Thorium-Baupläne und Händlerformeln")},
  },
  mining = {
    {1,50,L("Kupfer: Startgebiete")},
    {50,65,L("Kupfer weiter abbauen, höhere Erzgebiete erkunden")},
    {65,100,L("Zinn und Silber: Brachland, Sumpfland, Rotkammgebirge")},
    {100,125,L("Zinn und Silber: Übergang zu Eisen")},
    {125,150,L("Eisen und Gold: Arathihochland, Tausend Nadeln")},
    {150,175,L("Eisen und Gold: weitere Eisenadern")},
    {175,200,L("Mithril und Echtsilber: Ödland, Tanaris")},
    {200,225,L("Mithril: Ödland und Hinterland")},
    {225,245,L("Mithril und Echtsilber: weiter sammeln")},
    {245,275,L("Kleine Thoriumvorkommen: Un'Goro und Azshara")},
    {275,300,L("Reiche Thoriumvorkommen: Winterquell, Östliche Pestländer")},
  },
  blacksmithing = {
    {1,30,L("Rauer Stein für Wetz- und Schleifsteine")},
    {30,50,L("Kupferteile und Anfangswaffen")},
    {50,75,L("Kupfergegenstände und grobe Schleifsteine")},
    {75,100,L("Bronze und grober Stein: neue Rezepte vergleichen")},
    {100,125,L("Bronzegegenstände und schwere Steine")},
    {125,150,L("Schwere Schleifsteine und Übergang zu Eisen")},
    {150,175,L("Eisengegenstände und Stahl: Materialbedarf prüfen")},
    {175,200,L("Eisen- und Stahlrezepte nach Skillfarbe sortieren")},
    {200,225,L("Mithril: geeignete Waffen und Rüstungsteile")},
    {225,250,L("Mithril-Bauteile und verfügbare Spezialrezepte")},
    {250,275,L("Thorium sowie Händlerrezepte")},
    {275,300,L("Thorium, schwere Rüstungsrezepte und Spezialbaupläne")},
  },
  enchanting = {
    {1,30,L("Frühe Armschienen-Verzauberungen und einfache Runenrute")},
    {30,50,L("Seltsamer Staub und erste kleine Essenzen")},
    {50,75,L("Günstige Staubverzauberungen vergleichen")},
    {75,100,L("Neue Rute, grüne Gegenstände und schwache Essenzen")},
    {100,125,L("Seelenstaub und Astralessenzen")},
    {125,150,L("Zauberstäbe und mittlere Verzauberungen")},
    {150,175,L("Seelenstaub und verbesserte Essenzen")},
    {175,200,L("Visionenstaub und hochstufigere Verzauberungen")},
    {200,225,L("Visionenstaub und Traumstaub: Expertenrezepte")},
    {225,250,L("Traumstaub, höhere Essenzen; Uldaman-Lehrer beachten")},
    {250,275,L("Illusionsstaub und ewige Essenzen")},
    {275,300,L("Hochstufige Formeln und passende Runenrute")},
  },
  tailoring = {
    {1,30,L("Leinenballen und einfache Stoffkleidung")},
    {30,50,L("Leinenkleidung und erste Taschen")},
    {50,75,L("Leinen- zu Wollrezepten übergehen")},
    {75,100,L("Wollballen und Wollausrüstung")},
    {100,125,L("Wollgegenstände und frühe Seidenrezepte")},
    {125,150,L("Seidenballen und erste Seidenkleidung")},
    {150,175,L("Seidenkleidung und günstigere Alternativen")},
    {175,200,L("Magiestoffballen und einfache Stoffrüstung")},
    {200,225,L("Magiestoff-Taschen und Magiestoff-Ausrüstung")},
    {225,250,L("Magiestoff und Übergang zu Runenstoff")},
    {250,275,L("Runenstoffballen und Stoffkleidung")},
    {275,300,L("Runenstofftaschen und weitere Muster")},
  },
  leatherworking = {
    {1,30,L("Leichtes Leder und einfache Rüstungsteile")},
    {30,50,L("Leichtes Leder, kleine Rüstungssets")},
    {50,75,L("Leichtes bis mittleres Leder: Übergangsrezepte")},
    {75,100,L("Mittleres Leder und Rüstungssets")},
    {100,125,L("Mittleres Leder, einfache Ausrüstung")},
    {125,150,L("Schweres Leder und verbesserte Rüstungsteile")},
    {150,175,L("Schweres Leder und robuste Verarbeitung")},
    {175,200,L("Dickes Leder und neue Rüstungssets")},
    {200,225,L("Dickes Leder, Handschuhe und Ausrüstung")},
    {225,250,L("Dickes und unverwüstliches Leder: Spezialisierung prüfen")},
    {250,275,L("Unverwüstliches Leder und große Rüstungssets")},
    {275,300,L("Hochstufige Lederrezepte und Spezialmuster")},
  },
  herbalism = {
    {1,50,L("Friedensblume, Silberblatt und Erdwurzel: Startgebiete")},
    {50,75,L("Maguskönigskraut: niedrige Questgebiete")},
    {75,100,L("Wilddornrose: Brachland, Dunkelküste und Loch Modan")},
    {100,125,L("Beulengras und Wildstahlblume: Eschental, Sumpfland")},
    {125,150,L("Königsblut und Wildstahlblume: Vorgebirge")},
    {150,175,L("Lebenswurz: Gewässer und Feuchtgebiete")},
    {175,200,L("Golddorn und Blassblatt: Arathi, Sümpfe des Elends")},
    {200,230,L("Feuerblüte und Lila Lotus: Tanaris, Hinterland")},
    {230,250,L("Sonnengras und Blindkraut: Feralas")},
    {250,270,L("Gromsblut und Hochstufenkräuter")},
    {270,285,L("Traumblatt, Bergsilbersalbei und Pestblüte")},
    {285,300,L("Eiskappe und andere Hochstufenkräuter")},
  },
  alchemy = {
    {1,30,L("Einfache Tränke und kleine Elixiere")},
    {30,50,L("Erste Kräuterkombinationen und günstige Phiolen")},
    {50,75,L("Einfache Elixiere mit wenigen Kräutern")},
    {75,100,L("Frühe Mana- und Unterstützungsrezepte")},
    {100,125,L("Verbesserte Elixiere und Zwischenprodukte")},
    {125,150,L("Neue Trankrezepte, günstige Kräuter prüfen")},
    {150,175,L("Mittlere Elixiere und neue Phiolen")},
    {175,200,L("Weitere Unterstützungsrezepte und Alchemie-Öle")},
    {200,225,L("Höhere Elixiere und Handwerkszutaten")},
    {225,250,L("Fortgeschrittene Alchemie, ggf. Händlerformeln")},
    {250,275,L("Hochstufige Tränke und Elixiere")},
    {275,300,L("Hochstufige Formeln und mögliche Transmutationen")},
  },
}

-- Trainers. The generated list (ThirdParty/Trainers/Trainers.lua: QuestieDB Forever positions,
-- CMaNGOS ranks) is the base. The hand-kept list below only adds trainers the generated data
-- lacks (Forever-only NPCs, indoor pins); an entry with the same profession and name is
-- replaced by the generated one. Each destination is a point of interest, not a guarantee of
-- server-side trainer stock. Coordinates are normalized in the helper; zone IDs are UiMapIDs.
local function mapName(map,fallback)
  local info
  if C_Map and type(C_Map.GetMapInfo)=="function" then
    local ok,value=pcall(C_Map.GetMapInfo,map)
    if ok then info=value end
  end
  return type(info)=="table" and type(info.name)=="string" and info.name~="" and info.name or fallback
end
local function T(prof, name, zone, map, x, y, side, cap, indoor)
  return {profession=prof, name=name, zone=mapName(map,zone), map=map,
    x=x/100, y=y/100, faction=side, cap=cap, indoor=indoor}
end
local manualTrainers = {
  -- Herbalism: starter NPCs teach Apprentice; major-city trainers up to 300.
  T("herbalism","Nancy Songflower",L("Wald von Elwynn"),1429,52.42,43.83,"Alliance",75),
  T("herbalism","Emrys Flintbeard","Dun Morogh",1426,28.84,66.63,"Alliance",75),
  T("herbalism","Eleyna Duskbreeze","Teldrassil",1438,59.84,41.63,"Alliance",75),
  T("herbalism","Zor'la","Durotar",1411,42.84,67.63,"Horde",75),
  T("herbalism","Garan Sunstrider","Mulgore",1412,44.24,77.83,"Horde",75),
  T("herbalism","Florence Nightshade","Tirisfal",1420,32.43,65.24,"Horde",75),
  T("herbalism","Tannysa",L("Sturmwind"),1453,54.43,84.04,"Alliance",300),
  T("herbalism","Reyna Stonebranch",L("Eisenschmiede"),1455,55.6,58.4,"Alliance",300),
  T("herbalism","Firodren Mooncaller","Darnassus",1457,48.0,68.4,"Alliance",300),
  T("herbalism","Jandi","Orgrimmar",1454,55.6,39.6,"Horde",300),
  T("herbalism","Komin Winterhoof",L("Donnerfels"),1456,49.8,39.8,"Horde",300),
  T("herbalism","Martha Alliestar",L("Unterstadt"),1458,54.6,50.4,"Horde",300),

  -- Alchemy: specific Expert and Artisan trainers.
  T("alchemy","Tel'Athir",L("Sturmwind"),1453,55.6,85.6,"Alliance",75),
  T("alchemy","Vosur Brakthel",L("Eisenschmiede"),1455,67.0,54.2,"Alliance",75),
  T("alchemy","Lilyssia Nightbreeze",L("Sturmwind"),1453,55.6,85.8,"Alliance",150),
  T("alchemy","Tally Berryfizz",L("Eisenschmiede"),1455,67.2,54.2,"Alliance",150),
  T("alchemy","Ainethil","Darnassus",1457,55.0,24.0,"Alliance",225),
  T("alchemy","Kylanna Windwhisper","Feralas",1444,32.6,43.8,"Alliance",300),
  T("alchemy","Whuut","Orgrimmar",1454,56.0,33.8,"Horde",75),
  T("alchemy","Kray",L("Donnerfels"),1456,47.0,34.6,"Horde",75),
  T("alchemy","Yelmak","Orgrimmar",1454,56.6,33.2,"Horde",150),
  T("alchemy","Bena Winterhoof",L("Donnerfels"),1456,47.0,33.0,"Horde",150),
  T("alchemy","Doctor Herbert Halsey",L("Unterstadt"),1458,48.2,72.2,"Horde",225),
  T("alchemy","Rogvar",L("Sümpfe des Elends"),1435,48.4,55.6,"Horde",300),

  -- Engineering / Mining
  T("engineering","Jemma Quikswitch",L("Eisenschmiede"),1455,67.8,43.8,"Alliance",75),
  T("engineering","Trixie Quikswitch",L("Eisenschmiede"),1455,67.8,43.2,"Alliance",150),
  T("engineering","Sprite Jumpsprocket",L("Sturmwind"),1453,61.8,30.8,"Alliance",75),
  T("engineering","Lilliam Sparkspindle",L("Sturmwind"),1453,62.2,30.4,"Alliance",150),
  T("engineering","Thund","Orgrimmar",1454,75.8,24.6,"Horde",75),
  T("engineering","Nogg","Orgrimmar",1454,75.8,25.2,"Horde",150),
  T("engineering","Springspindle Fizzlegear",L("Eisenschmiede"),1455,68.4,44.0,"Alliance",225),
  T("engineering","Roxxik","Orgrimmar",1454,76.0,25.0,"Horde",225),
  T("engineering","Buzzek Bracketswing","Gadgetzan",1446,52.2,27.6,"B",300),
  T("mining","Geofram Bouldertoe",L("Eisenschmiede"),1455,50.2,26.0,"Alliance",300),
  T("mining","Gelman Stonehand",L("Sturmwind"),1453,59.0,37.6,"Alliance",300),
  T("mining","Makaru","Orgrimmar",1454,73.0,26.4,"Horde",300),
  T("mining","Brek Stonehoof",L("Donnerfels"),1456,34.6,57.6,"Horde",300),

  -- Blacksmithing
  T("blacksmithing","Dane Lindgren",L("Sturmwind"),1453,64.0,37.2,"Alliance",75),
  T("blacksmithing","Groum Stonebeard",L("Eisenschmiede"),1455,52.2,41.4,"Alliance",75),
  T("blacksmithing","Therum Deepforge",L("Sturmwind"),1453,63.8,37.2,"Alliance",150),
  T("blacksmithing","Rotgath Stonebeard",L("Eisenschmiede"),1455,52.0,42.6,"Alliance",150),
  T("blacksmithing","Bengus Deepforge",L("Eisenschmiede"),1455,52.6,40.8,"Alliance",225),
  T("blacksmithing","Ug'thok","Orgrimmar",1454,80.6,23.6,"Horde",75),
  T("blacksmithing","Snarl","Orgrimmar",1454,79.8,23.4,"Horde",150),
  T("blacksmithing","Saru Steelfury","Orgrimmar",1454,82.4,23.6,"Horde",225),
  T("blacksmithing","Brikk Keencraft",L("Beutebucht"),1434,29.0,75.6,"B",300),

  -- Enchanting: Annora is inside Uldaman; pin is near the rear dungeon entrance.
  T("enchanting","Betty Quin",L("Sturmwind"),1453,43.2,63.8,"Alliance",75),
  T("enchanting","Lucan Cordell",L("Sturmwind"),1453,43.0,64.4,"Alliance",150),
  T("enchanting","Kitta Firewind",L("Wald von Elwynn"),1429,64.8,70.6,"Alliance",225),
  T("enchanting","Jhag","Orgrimmar",1454,53.6,38.2,"Horde",75),
  T("enchanting","Godan","Orgrimmar",1454,53.8,38.4,"Horde",150),
  T("enchanting","Hgarth",L("Steinkrallengebirge"),1442,49.2,57.2,"Horde",225),
  T("enchanting",L("Annora (Uldaman-Eingang)"),L("Ödland / Uldaman"),1418,66.0,43.0,"B",300,true),

  -- Tailoring
  T("tailoring","Lawrence Schneider",L("Sturmwind"),1453,43.6,73.8,"Alliance",75),
  T("tailoring","Sellandus",L("Sturmwind"),1453,42.0,76.2,"Alliance",150),
  T("tailoring","Georgio Bolero",L("Sturmwind"),1453,43.2,73.6,"Alliance",225),
  T("tailoring","Timothy Worthington","Theramore",1445,66.2,51.6,"Alliance",300),
  T("tailoring","Snang","Orgrimmar",1454,63.0,49.6,"Horde",75),
  T("tailoring","Magar","Orgrimmar",1454,63.6,50.0,"Horde",150),
  T("tailoring","Josef Gregorian",L("Unterstadt"),1458,70.6,30.6,"Horde",225),
  T("tailoring","Daryl Stack",L("Vorgebirge des Hügellands"),1424,63.6,20.8,"Horde",300),

  -- Leatherworking
  T("leatherworking","Randal Worth",L("Sturmwind"),1453,67.4,49.4,"Alliance",75),
  T("leatherworking","Simon Tanner",L("Sturmwind"),1453,67.2,49.4,"Alliance",150),
  T("leatherworking","Telonis","Darnassus",1457,64.4,21.4,"Alliance",225),
  T("leatherworking","Drakk Stonehand",L("Hinterland"),1425,13.4,43.4,"Alliance",300),
  T("leatherworking","Kamari","Orgrimmar",1454,63.0,45.0,"Horde",75),
  T("leatherworking","Karolek","Orgrimmar",1454,62.8,44.4,"Horde",150),
  T("leatherworking","Una",L("Donnerfels"),1456,41.4,42.6,"Horde",225),
  T("leatherworking","Hahrana Ironhide","Feralas",1444,74.4,43.0,"Horde",300),

  -- Cooking, first aid, fishing: Apprentice/Journeyman trainers (QuestieDB Forever positions, CMaNGOS ranks), so
  -- these professions have trainers without QuestieDB too. Expert and Artisan come from D.rankSources below.
  T("cooking","Alegorn","",1457,49.03,21.24,"Alliance",150),
  T("cooking","Cook Ghilm","",1426,68.38,54.49,"Alliance",150),
  T("cooking","Crystal Boughman","",1433,17.69,43.47,"Alliance",150),
  T("cooking","Daryl Riknussun","",1455,60.08,36.43,"Alliance",150),
  T("cooking","Gremlock Pilsnor","",1426,47.67,52.31,"Alliance",150),
  T("cooking","Stephen Ryback","",1453,78.17,53.10,"Alliance",150),
  T("cooking","Tomas","",1429,44.37,65.99,"Alliance",150),
  T("cooking","Zarrin","",1438,57.12,61.30,"Alliance",150),
  T("cooking","Aska Mistrunner","",1456,50.72,53.11,"Horde",150),
  T("cooking","Duhng","",1413,55.29,31.78,"Horde",150),
  T("cooking","Eunice Burch","",1458,62.14,44.91,"Horde",150),
  T("cooking","Mudduk","",1434,31.34,27.97,"Horde",150),
  T("cooking","Pyall Silentstride","",1412,44.92,61.67,"Horde",150),
  T("cooking","Zamja","",1454,57.40,53.96,"Horde",150),
  T("firstaid","Byancie","",1438,55.29,56.82,"Alliance",150),
  T("firstaid","Dannelor","",1457,51.71,12.22,"Alliance",150),
  T("firstaid","Fremal Doohickey","",1437,10.83,61.40,"Alliance",150),
  T("firstaid","Michelle Belle","",1429,43.39,65.55,"Alliance",150),
  T("firstaid","Nissa Firestone","",1455,55.09,58.26,"Alliance",150),
  T("firstaid","Shaina Fuller","",1453,53.00,44.68,"Alliance",150),
  T("firstaid","Thamner Pol","",1426,47.18,52.61,"Alliance",150),
  T("firstaid","Arnok","",1454,34.18,84.58,"Horde",150),
  T("firstaid","Mary Edras","",1458,73.16,55.15,"Horde",150),
  T("firstaid","Nurse Neela","",1420,61.82,52.83,"Horde",150),
  T("firstaid","Pand Stonebinder","",1456,29.69,21.18,"Horde",150),
  T("firstaid","Rawrk","",1411,54.17,41.93,"Horde",150),
  T("firstaid","Vira Younghoof","",1412,46.08,63.96,"Horde",150),
  T("fishing","Androl Oakhand","",1438,55.88,93.51,"Alliance",150),
  T("fishing","Arnold Leland","",1453,54.99,69.65,"Alliance",150),
  T("fishing","Astaia","",1457,47.89,56.65,"Alliance",150),
  T("fishing","Brannock","",1444,32.25,41.61,"Alliance",150),
  T("fishing","Donald Rabonne","",1424,50.78,61.03,"Alliance",150),
  T("fishing","Grimnur Stonebrand","",1455,48.07,6.91,"Alliance",150),
  T("fishing","Harold Riggs","",1437,8.08,58.59,"Alliance",150),
  T("fishing","Lee Brown","",1429,47.61,62.32,"Alliance",150),
  T("fishing","Matthew Hooper","",1433,21.90,51.13,"Alliance",150),
  T("fishing","Paxton Ganter","",1426,35.48,40.22,"Alliance",150),
  T("fishing","Warg Deepwater","",1432,40.55,39.70,"Alliance",150),
  T("fishing","Myizz Luckycatch","",1434,27.46,77.11,"B",150),
  T("fishing","Katoom the Angler","",1425,80.33,81.54,"Horde",300),
  T("fishing","Armand Cromwell","",1458,80.70,31.26,"Horde",150),
  T("fishing","Clyde Kellen","",1420,67.17,50.99,"Horde",150),
  T("fishing","Kah Mistrunner","",1456,56.13,46.38,"Horde",150),
  T("fishing","Kil'Hiwana","",1440,10.83,33.66,"Horde",150),
  T("fishing","Lau'Tiki","",1411,53.25,81.59,"Horde",150),
  T("fishing","Lui'Mala","",1443,22.70,72.42,"Horde",150),
  T("fishing","Lumak","",1454,69.80,29.21,"Horde",150),
  T("fishing","Uthan Stillwater","",1412,44.16,63.80,"Horde",150),
}

-- 1.4.0: Expert and Artisan of the secondary professions are not taught by the usual trainers: Expert is a book
-- bought from a vendor, Artisan a trainer in the world or a quest. NPCs and books: CMaNGOS classic-db (npc_vendor,
-- quest_template), positions: QuestieDB Forever. Each source is shown like a trainer, with how it teaches the rank.
local function S(prof,name,map,x,y,side,cap,how,extra)
  local entry=T(prof,name,"",map,x,y,side,cap)
  entry.how=how
  for k,v in pairs(extra or {}) do entry[k]=v end
  return entry
end
D.rankSources = {
  cooking = {
    [225] = {S("cooking","Shandrina",1440,49.48,67.09,"Alliance",225,"book",{book=16072,npcID=3955}),
             S("cooking","Wulan",1443,26.17,69.65,"Horde",225,"book",{book=16072,npcID=12033})},
    [300] = {S("cooking","Dirge Quikcleave",1446,52.63,28.11,"B",300,"trainer",{npcID=8125})},
  },
  firstaid = {
    [225] = {S("firstaid","Deneb Walker",1417,26.97,58.83,"Alliance",225,"book",{book=16084,npcID=2805}),
             S("firstaid","Balai Lok'Wein",1445,36.49,30.36,"Horde",225,"book",{book=16084,npcID=13476})},
    [300] = {S("firstaid","Doctor Gustaf VanHowzen",1445,67.76,48.97,"Alliance",300,"quest",{quest=6624,questName="Triage",npcID=12939}),
             S("firstaid","Doctor Gregory Victor",1417,73.41,36.89,"Horde",300,"quest",{quest=6622,questName="Triage",npcID=12920})},
  },
  fishing = {
    [225] = {S("fishing","Old Man Heming",1434,27.42,77.16,"B",225,"book",{book=16083,npcID=2626})},
    [300] = {S("fishing","Nat Pagle",1445,58.61,60.06,"B",300,"quest",{quest=6607,questName="Nat Pagle, Angler Extreme",npcID=12919})},
  },
}
-- Artisan of a secondary profession needs the full Expert skill (225), not 200 as the main professions.
D.rankMinOverrides = {cooking={[300]=225}, firstaid={[300]=225}, fishing={[300]=225}}

-- Trainer list: CP.TrainerRanks (NPC id, profession, highest rank; CMaNGOS) completed at runtime with name,
-- position, faction and title from the QuestieDB addon. The hand-kept list fills in trainers that are
-- missing there; until QuestieDB is read, it is the whole list.
D.manualTrainers = manualTrainers
D.trainers = {}
for _,entry in ipairs(manualTrainers) do D.trainers[#D.trainers+1]=entry end
function CP:BuildTrainers()
  local built,keys={},{}
  for _,row in ipairs(self.TrainerRanks or {}) do
    local prof,npc,cap=row[1],row[2],row[3]
    local record=self.QuestieNpcRecord and self:QuestieNpcRecord(npc)
    if record then
      local p=record.point
      local entry=T(prof,record.name,mapName(p.map,L("Karte ")..p.map),p.map,p.x*100,p.y*100,record.faction,cap)
      entry.npcID,entry.title,entry.generated=npc,record.title,true
      built[#built+1]=entry
      keys[prof..":"..record.name]=true
    end
  end
  if #built==0 then return false end
  for _,entry in ipairs(manualTrainers) do
    if not keys[entry.profession..":"..entry.name] then built[#built+1]=entry end
  end
  -- Replace the contents in place: other modules keep a reference to D.trainers.
  for i=#D.trainers,1,-1 do D.trainers[i]=nil end
  for i,entry in ipairs(built) do D.trainers[i]=entry end
  self.trainersFromQuestie=true
  return true
end
