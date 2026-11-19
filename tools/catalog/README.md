# Eigener Rezeptkatalog / Own recipe catalog

CraftPilot baut seinen Rezeptkatalog und die Camp-Daten (`Data/Catalog/*.lua`) selbst aus öffentlichen Quellen.

| Schritt | Werkzeug | Ergebnis |
|---|---|---|
| 1. Eingaben holen | `fetch_inputs.py` (Workflow `catalog-inputs.yml`, täglich) | Zweig `catalog-inputs`: Client-Tabellen (DB2 von wago.tools), QuestieDB-Releasepaket, AllTheThings-Quellen, `manifest.json` mit SHA-256 |
| 2. Katalog bauen | `build_catalog.py`, `build_camp.py`, `spec_guides.py` (Workflow `catalog-build.yml`) | `Data/Catalog/<Beruf>.lua`, `Camp.lua`, `SOURCES.json` |
| 3. Vergleichen | `compare_catalog.py` | Änderungsbericht im Pull Request (neu vs. bisher) |

Lokal (Eingaben aus dem Zweig `catalog-inputs` entpackt, CMaNGOS-Datei aus `ThirdParty/Trainers/SOURCES.json`):

```
git archive origin/catalog-inputs | tar -x -C /tmp/inputs
python3 tools/catalog/build_catalog.py --inputs /tmp/inputs --classicdb ClassicDB_1_12_1_z2815.sql.gz
python3 tools/catalog/build_camp.py --inputs /tmp/inputs
python3 tools/catalog/compare_catalog.py --theirs ALTER_KATALOG_ORDNER --out bericht.md
```

Woher was stammt:

- **Forever-Client (wago.tools):** welche Zauber Rezepte sind, Skillfarben, Materialien, Ergebnis und Menge, Werkzeuge, Abklingzeiten, Rezeptgegenstände samt geforderter Stufe, Ruf und Spezialisierung, Händlerpreise, Namen.
- **CMaNGOS classic-db (GPL-3.0):** Lehrerkosten und Lernstufe, wo Forever ein Classic-Rezept beim Lehrer lässt. Die Stufe wird verschoben, wenn Forever die Farben verschoben hat. Dazu Quests, die ein Rezept beibringen.
- **QuestieDB (GPL-3.0, gebackene Forever-Daten aus dem Releasepaket):** Händler, Drops und Questbelohnungen von Rezeptgegenständen, NPC-Namen und -Orte.
- **AllTheThings (MIT):** welche Rezepte Forevers Lehrer lehren, was (noch) nicht veröffentlicht ist, Merchant's-Favor-Preise und Rufstufen, Lernstufen neuer Forever-Rezepte.

Lehrerkosten neuer Forever-Rezepte kennt keine dieser Quellen. Sie werden aus Rezepten ähnlicher Stufe geschätzt (`costGuess`), bis CraftPilot sie im Spiel selbst erfasst.

## Skilldaten aus der Community (seit 1.1.0)

CraftPilot schreibt bei jedem Herstellen mit, bei welchem Skill ein Punkt kam (abschaltbar). Unter **Hilfe › Skilldaten teilen** kopieren Spieler einen Code der Form

```
CPSKILL1;<Client-Build>;<beruf>:<zauber-ID>:<skill>:<herstellungen>:<punkte>,...
```

und posten ihn im Discord-Kanal für Skilldaten. **Der CraftPilot-Bot legt für jeden solchen Post ein GitHub-Issue mit dem Label `skilldaten` an** (Text des Posts als Issue-Text genügt; der Code wird darin gesucht, gleiche Codes zählen einmal). Enthalten sind nur Beruf, Rezept, Skill und Anzahl.

`.github/workflows/skill-data.yml` sammelt montags alle Issues mit diesem Label, rechnet sie mit `skill_data.py` zusammen und schlägt `Data/Catalog/Observed.lua` und `docs/SKILL_DATA.md` als Pull Request nach `dev` vor. Im Addon steht dann bei den Farbgrenzen „Grenzen bestätigt“ oder „Spieler bekamen noch bei N einen Punkt“.

Lokal: `gh issue list --label skilldaten --state all --json number,body > issues.json && python3 tools/catalog/skill_data.py --issues issues.json`
