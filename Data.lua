local _, CP = ...
CP.Data = {}
local D = CP.Data

D.version = "Forever 1.60.x / 2026-11-08"
D.order = {"engineering", "mining", "blacksmithing", "enchanting", "tailoring", "leatherworking"}
D.professions = {
  engineering = {id=202, name="Ingenieurskunst", short="Ingi"},
  mining = {id=186, name="Bergbau", short="Bergbau", gathering=true},
  blacksmithing = {id=164, name="Schmiedekunst", short="Schmied"},
  enchanting = {id=333, name="Verzauberkunst", short="Verzaub."},
  tailoring = {id=197, name="Schneiderei", short="Schneider"},
  leatherworking = {id=165, name="Lederverarbeitung", short="Leder"},
}
D.ranks = {
  {cap=75, min=0, level=1, name="Lehrling"},
  {cap=150, min=50, level=10, name="Geselle"},
  {cap=225, min=125, level=20, name="Experte"},
  {cap=300, min=200, level=35, name="Fachmann"},
}
-- The following original milestone summaries are a general 1-300 roadmap, not
-- a copied leveling guide or a source of exact reagent/skill-up calculations.
-- The client recipe book always determines actual available and learned crafts.
D.stages = {
  engineering = {
    {1,75,"Steine, Kupfer, Sprengpulver und Kupferbolzen"},
    {75,125,"Grober Stein, Bronze und einfache Bauteile"},
    {125,175,"Bronzegeräte, schwere Sprengpulver und Eisen"},
    {175,225,"Robuster Stein, Mithril und Auslöser"},
    {225,250,"Mithrilbauteile und Sprengstoffe"},
    {250,300,"Thorium, dichtes Sprengpulver und geeignete Baupläne"},
  },
  mining = {
    {1,65,"Kupfer: Startgebiete und frühe Questgebiete"},
    {65,125,"Zinn und Silber: Brachland, Sumpfland, Rotkammgebirge"},
    {125,175,"Eisen und Gold: Arathihochland, Tausend Nadeln"},
    {175,245,"Mithril und Echtsilber: Ödland, Tanaris"},
    {245,275,"Kleine Thoriumvorkommen: Un'Goro, Azshara"},
    {275,300,"Reiche Thoriumvorkommen: Winterquell, Östliche Pestländer"},
  },
  blacksmithing = {
    {1,50,"Schleif- und Wetzsteine aus grobem Anfangsstein"},
    {50,100,"Kupfer- und Bronzegegenstände, Schleifsteine"},
    {100,150,"Bronzegegenstände und schwere Schleifsteine"},
    {150,200,"Eisen, Stahl und passende Schmiederezepte"},
    {200,250,"Mithrilbauteile und verfügbares Ausbildungsangebot"},
    {250,300,"Thoriumrezepte, ggf. Händler- und Spezialbaupläne"},
  },
  enchanting = {
    {1,50,"Frühe Armschienen-Verzauberungen und einfache Runenrute"},
    {50,100,"Leichte Verzauberungen mit seltsamem Staub"},
    {100,150,"Zauberstäbe, geringe Essenzen und neue Ruten"},
    {150,200,"Seelenstaub, Astralessenzen und höhere Verzauberungen"},
    {200,250,"Visionsstaub und Traumstaub; Uldaman-Lehrer beachten"},
    {250,300,"Illusionsstaub, ewige Essenzen und seltenere Formeln"},
  },
  tailoring = {
    {1,75,"Leinenballen, frühe Stoffkleidung und Taschen"},
    {75,125,"Wollballen und einfache Wollrezepte"},
    {125,175,"Seidenballen und passende Seidenrezepte"},
    {175,225,"Magiestoffballen und höherwertige Stoffausrüstung"},
    {225,250,"Magiestoff und frühe Runenstoffrezepte"},
    {250,300,"Runenstoffballen, Taschen und passende Muster"},
  },
  leatherworking = {
    {1,75,"Leichtes Leder, Rüstungssets und frühe Handschuhe"},
    {75,125,"Mittleres Leder und einfache Ledergegenstände"},
    {125,175,"Schweres Leder und robuste Rüstungsteile"},
    {175,225,"Dickes Leder, Rüstungssets und neue Schnittmuster"},
    {225,250,"Unverwüstliches Leder und höhere Schnitte"},
    {250,300,"Unverwüstliches Leder, Rüstungssets und Spezialmuster"},
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
  -- Engineering / Mining
  T("engineering","Jemma Quikswitch","Eisenschmiede",1455,67.8,43.8,"Alliance",75),
  T("engineering","Trixie Quikswitch","Eisenschmiede",1455,67.8,43.2,"Alliance",150),
  T("engineering","Sprite Jumpsprocket","Sturmwind",1453,61.8,30.8,"Alliance",75),
  T("engineering","Lilliam Sparkspindle","Sturmwind",1453,62.2,30.4,"Alliance",150),
  T("engineering","Thund","Orgrimmar",1454,75.8,24.6,"Horde",75),
  T("engineering","Nogg","Orgrimmar",1454,75.8,25.2,"Horde",150),
  T("engineering","Springspindle Fizzlegear","Eisenschmiede",1455,68.4,44.0,"Alliance",225),
  T("engineering","Roxxik","Orgrimmar",1454,76.0,25.0,"Horde",225),
  T("engineering","Buzzek Bracketswing","Gadgetzan",1446,52.2,27.6,"B",300),
  T("mining","Geofram Bouldertoe","Eisenschmiede",1455,50.2,26.0,"Alliance",300),
  T("mining","Gelman Stonehand","Sturmwind",1453,59.0,37.6,"Alliance",300),
  T("mining","Makaru","Orgrimmar",1454,73.0,26.4,"Horde",300),
  T("mining","Brek Stonehoof","Donnerfels",1456,34.6,57.6,"Horde",300),

  -- Blacksmithing
  T("blacksmithing","Dane Lindgren","Sturmwind",1453,64.0,37.2,"Alliance",75),
  T("blacksmithing","Groum Stonebeard","Eisenschmiede",1455,52.2,41.4,"Alliance",75),
  T("blacksmithing","Therum Deepforge","Sturmwind",1453,63.8,37.2,"Alliance",150),
  T("blacksmithing","Rotgath Stonebeard","Eisenschmiede",1455,52.0,42.6,"Alliance",150),
  T("blacksmithing","Bengus Deepforge","Eisenschmiede",1455,52.6,40.8,"Alliance",225),
  T("blacksmithing","Ug'thok","Orgrimmar",1454,80.6,23.6,"Horde",75),
  T("blacksmithing","Snarl","Orgrimmar",1454,79.8,23.4,"Horde",150),
  T("blacksmithing","Saru Steelfury","Orgrimmar",1454,82.4,23.6,"Horde",225),
  T("blacksmithing","Brikk Keencraft","Beutebucht",1434,29.0,75.6,"B",300),

  -- Enchanting: Annora is inside Uldaman; pin is near the rear dungeon entrance.
  T("enchanting","Betty Quin","Sturmwind",1453,43.2,63.8,"Alliance",75),
  T("enchanting","Lucan Cordell","Sturmwind",1453,43.0,64.4,"Alliance",150),
  T("enchanting","Kitta Firewind","Wald von Elwynn",1429,64.8,70.6,"Alliance",225),
  T("enchanting","Jhag","Orgrimmar",1454,53.6,38.2,"Horde",75),
  T("enchanting","Godan","Orgrimmar",1454,53.8,38.4,"Horde",150),
  T("enchanting","Hgarth","Steinkrallengebirge",1442,49.2,57.2,"Horde",225),
  T("enchanting","Annora (Uldaman-Eingang)","Ödland / Uldaman",1418,66.0,43.0,"B",300,true),

  -- Tailoring
  T("tailoring","Lawrence Schneider","Sturmwind",1453,43.6,73.8,"Alliance",75),
  T("tailoring","Sellandus","Sturmwind",1453,42.0,76.2,"Alliance",150),
  T("tailoring","Georgio Bolero","Sturmwind",1453,43.2,73.6,"Alliance",225),
  T("tailoring","Timothy Worthington","Theramore",1445,66.2,51.6,"Alliance",300),
  T("tailoring","Snang","Orgrimmar",1454,63.0,49.6,"Horde",75),
  T("tailoring","Magar","Orgrimmar",1454,63.6,50.0,"Horde",150),
  T("tailoring","Josef Gregorian","Unterstadt",1458,70.6,30.6,"Horde",225),
  T("tailoring","Daryl Stack","Vorgebirge des Hügellands",1424,63.6,20.8,"Horde",300),

  -- Leatherworking
  T("leatherworking","Randal Worth","Sturmwind",1453,67.4,49.4,"Alliance",75),
  T("leatherworking","Simon Tanner","Sturmwind",1453,67.2,49.4,"Alliance",150),
  T("leatherworking","Telonis","Darnassus",1457,64.4,21.4,"Alliance",225),
  T("leatherworking","Drakk Stonehand","Hinterland",1425,13.4,43.4,"Alliance",300),
  T("leatherworking","Kamari","Orgrimmar",1454,63.0,45.0,"Horde",75),
  T("leatherworking","Karolek","Orgrimmar",1454,62.8,44.4,"Horde",150),
  T("leatherworking","Una","Donnerfels",1456,41.4,42.6,"Horde",225),
  T("leatherworking","Hahrana Ironhide","Feralas",1444,74.4,43.0,"Horde",300),
}
