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
  cooking = {id=185, name=L("Kochen"), short=L("Kochen"), secondary=true, ranksUnverified=true},
  firstaid = {id=129, name=L("Erste Hilfe"), short=L("Erste Hilfe"), secondary=true, ranksUnverified=true},
  fishing = {id=356, name=L("Angeln"), short=L("Angeln"), secondary=true, gathering=true, crafting=true, ranksUnverified=true},
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

-- Verified public NPC travel references. Each destination is a point of interest,
-- not a guarantee of server-side trainer stock or an indoor NPC position.
-- Coordinates are normalized in the helper; all zone IDs are UiMapIDs.
local function T(prof, name, zone, map, x, y, side, cap, indoor)
  return {profession=prof, name=name, zone=zone, map=map,
    x=x/100, y=y/100, faction=side, cap=cap, indoor=indoor}
end
D.trainers = {
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
}
