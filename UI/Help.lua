-- Help view (header "?" and /cp hilfe) and the first start. Matches the 0.28 interface: five tabs, the
-- companion at the profession window and the helpers at bank, vendor, mailbox and auction house.
local _,CP=...
local L=CP.L
local ICON="Interface\\AddOns\\CraftPilot\\Media\\CraftPilot"

local function card(title,detail,action,footer,color,icon)
  return {title=title,detail=detail,action=action,footer=footer or (action and L("Klick: öffnen") or ""),color=color or "blue",icon=icon or ICON}
end
local function header(title) return {sectionHeader=true,title=title} end

function CP:AuctionatorStatus()
  local api=_G.Auctionator and Auctionator.API and Auctionator.API.v1
  return api~=nil
end

function CP:HelpCards()
  local cards={}
  if self.db.ui.firstRunDone~=true then
    cards[#cards+1]=card(L("Willkommen bei CraftPilot"),
      L("CraftPilot zeigt dir den günstigsten Weg, deine Berufe zu skillen, und hilft beim Einkaufen, Lernen und Herstellen. Es kauft, lernt und stellt nur her, wenn du klickst."),
      function() CP.db.ui.firstRunDone=true;CP:OpenTab("now") end,L("Klick: Los geht's"),"gold")
  end
  cards[#cards+1]=header(L("ERSTE SCHRITTE"))
  cards[#cards+1]=card(L("1. Beruf wählen"),L("Oben links im Berufsmenü. Erlernte Berufe stehen zuerst; ein Klick auf einen erlernten Beruf öffnet auch sein Berufsfenster (abschaltbar)."))
  cards[#cards+1]=card(L("2. Berufsfenster einmal öffnen"),L("Dabei liest CraftPilot deine Rezepte, Skillfarben und Materialien ein. Danach stimmt die Empfehlung."))
  cards[#cards+1]=card(L("3. Der Empfehlung folgen"),L("Oben in „Jetzt“ steht der nächste Schritt des günstigsten Weges. „Im AH suchen“, „Herstellen“ im Begleitfenster oder „Weg zum Lehrer“ – je nachdem, was als Nächstes ansteht."),
    function() CP:OpenTab("now") end)
  if self:AuctionatorStatus() then
    cards[#cards+1]=card(L("Auctionator gefunden"),L("Preise kommen aus deinen Auctionator-Scans. Ein voller Scan am Auktionshaus bringt die besten Ergebnisse; „Preise alt“ scannt gezielt nach."),nil,nil,"green")
  else
    cards[#cards+1]=card(L("Auctionator fehlt"),L("Ohne Auctionator kennt CraftPilot nur Händlerpreise. Für den günstigsten Weg, Preisgrenzen und das Einkaufen am AH bitte Auctionator installieren und einmal am Auktionshaus scannen."),nil,nil,"red")
  end

  if not self:QuestieProvider() then
    cards[#cards+1]=card(L("QuestieDB fehlt"),L("CraftPilot braucht das Addon QuestieDB (Version für WoW Forever) für Lehrer, Händlerstandorte und Sammelgebiete. Über die CurseForge-App wird es automatisch mitinstalliert, sonst bitte von Hand installieren."),nil,nil,"red")
  end
  cards[#cards+1]=header(L("DIE REITER"))
  cards[#cards+1]=card(L("Jetzt"),L("Empfehlung oben, Rezeptliste links (Filter, Sortierung über die Spaltenköpfe), Details rechts mit Menge, Materialien, Kosten und „Behalten“-Hinweisen. Nicht erlernte Rezepte haben ein Kartensymbol für den Weg zum Lehrer oder Händler."),
    function() CP:OpenTab("now") end)
  cards[#cards+1]=card(L("Plan & Einkauf"),L("Bereich wählen und „Plan erstellen“ – der Plan folgt dem Skillweg aus den Einstellungen. Einkaufen: fehlende Materialien, Preisgrenzen, Selbst farmen. Herstellen: Schritte und was du aufheben musst. Verwerten: übrige Herstellungen. Details: Preise prüfen, Budget, Plan teilen."),
    function() CP:OpenTab("plan") end)
  cards[#cards+1]=card(L("Lehrer & Händler"),L("Lehrer mit Wegpunkt, alle Händlerrezepte, die Lerntour entlang des günstigsten Weges und die Spezialisierungen (Schmied, Ingenieur, Lederer) mit Questgeber."),
    function() CP:OpenTab("trainers") end)
  cards[#cards+1]=card(L("Camping"),L("Lagerfeuer, Buffs und Objekte der Camping-Berufe mit gemeinsamem Einkauf."),function() CP:OpenTab("camping") end)
  cards[#cards+1]=card(L("Twinks"),L("Cooldowns aller Charaktere, was Twinks für deinen Plan haben, was sie günstiger herstellen können, und alle Charaktere mit Berufen. Dafür jeden Twink einmal einloggen, Berufsfenster und Bank öffnen."),
    function() CP:OpenTab("twinks") end)
  cards[#cards+1]=card(L("Endgame"),L("Was dein Beruf nach dem Skillen bringt: Gewinn je Herstellung, Merchant's-Favor-Rezepte, deine Rezept-Wunschliste mit Bossen und Händlern, der Raid-Vorrat und der AH-Alarm."),
    function() CP:OpenTab("endgame") end)

  cards[#cards+1]=header(L("AM BERUFSFENSTER"))
  cards[#cards+1]=card(L("Begleitfenster"),L("Neben dem Berufsfenster: Empfehlung, „noch N× bis zur nächsten Farbe“, Herstellen-Knopf, Aufheben-Hinweise, bereite Cooldowns und die Sitzungsbilanz. Verschieben an der Kopfzeile, Minus minimiert, X schließt bis zum nächsten Öffnen."))
  cards[#cards+1]=card(L("Herstellen"),L("„Herstellen: N×“ stellt die empfohlene Menge her, „1×“ genau eine. Fehlt Material, steht das am Knopf. Hergestelltes, das ein späterer Schritt braucht, wird sofort als „Behalten“ gemeldet."))

  cards[#cards+1]=header(L("UNTERWEGS"))
  cards[#cards+1]=card(L("Auktionshaus"),L("Beim Öffnen bietet CraftPilot eine Einkaufsrunde an: Posten für Posten mit Preisgrenze, Gekauftes wird abgezählt. Reservierte Gegenstände lösen beim Einstellen eine Warnung aus, ebenso beim Zerstören, Entzaubern oder Verschicken an fremde Charaktere."))
  cards[#cards+1]=card(L("Händler"),L("Ein kleines Fenster zeigt, was dein Plan braucht und dieser Händler verkauft; „Kaufen“ kauft genau die fehlende Menge. Verkaufst du etwas Reserviertes, bietet CraftPilot „Zurückkaufen“ an."))
  cards[#cards+1]=card(L("Bank und Briefkasten"),L("An der Bank: was du für den Plan mitnehmen solltest. Am Briefkasten: was deine Twinks brauchen, mit „Brief vorbereiten“."))
  cards[#cards+1]=card(L("Taschen, Bank und Tooltips"),L("Goldener Punkt: für einen späteren Schritt aufheben. Blauer Punkt: dein Plan braucht es. Funktioniert mit den üblichen Taschen-Addons. Im Tooltip stehen Bedarf, Twink-Bestände und die Preisgrenze."))

  cards[#cards+1]=header(L("GUT ZU WISSEN"))
  cards[#cards+1]=card(L("Skillweg"),L("Günstigster Weg: rein nach AH-Preisen je Skillpunkt. Sichere Farben bevorzugen: Grün nur, wenn es über 25 % billiger ist. Nur Orange und Gelb: nie Grün. Schnellster Weg: so wenige Herstellungen wie möglich. Einstellbar unter Einstellungen."),
    function() CP:OpenTab("settings") end)
  cards[#cards+1]=card(L("Farben und Chancen"),L("Orange gibt immer einen Punkt, Gelb meist (ca. 70 %), Grün selten (ca. 35 %), Grau nie. CraftPilot rechnet mit diesen Chancen; einzelne Ergebnisse können abweichen."))
  cards[#cards+1]=card(L("Preise sind Schätzungen"),L("Grundlage ist dein letzter Auctionator-Scan. Fehlende oder alte Preise werden genannt, nicht geraten. Rezeptdaten stammen aus Craft Ladder, Lehrer und Sammelgebiete aus QuestieDB und CMaNGOS."))
  cards[#cards+1]=card(L("Befehle"),L("/cp öffnet und schließt · /cp hilfe · /cp <Beruf> (z. B. /cp schmied) · /cp plan · /cp lehrer · /cp trainer (Wegpunkt) · /cp naechster · /cp refresh · /cp resetpos · /cp skin auto|dark|classic"))
  cards[#cards+1]=card(L("Fehler melden"),L("Erstellt einen Bericht mit Version und Lua-Fehlern zum Kopieren für GitHub."),function() CP:OpenDiagnosticReport() end,L("Klick: Bericht öffnen"),"gold")
  return cards
end
