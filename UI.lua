local _, CP = ...
local D=CP.Data
local function label(parent,template,x,y,width,text)
  local f=parent:CreateFontString(nil,"OVERLAY",template)
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  f:SetWidth(width)
  f:SetJustifyH("LEFT")
  f:SetText(text or "")
  return f
end
local function button(parent,width,x,y,caption,callback)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(width,24)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(caption)
  b:SetScript("OnClick",callback)
  return b
end
local function gold(value)
  if type(value)~="number" then return "Preis fehlt" end
  local v=math.floor(value+0.5)
  return string.format("%dg %ds %dc",math.floor(v/10000),
    math.floor((v%10000)/100),v%100)
end

local frame=CreateFrame("Frame","CraftPilotMainFrame",UIParent,"BackdropTemplate")
frame:SetSize(640,610)
frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=15,
  insets={left=5,right=5,top=5,bottom=5}})
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart",frame.StartMoving)
frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
frame:Hide()
CP.frame=frame
if type(UISpecialFrames)=="table" then
  table.insert(UISpecialFrames,"CraftPilotMainFrame")
end
local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4)

label(frame,"GameFontNormalLarge",18,-17,460,"CraftPilot  |  WoW Forever  |  0.4 alpha")
label(frame,"GameFontDisableSmall",18,-44,605,
  "Beruf wählen, Berufsfenster öffnen, Empfehlungen und Lehrer direkt im Spiel anzeigen")

for index,key in ipairs(D.order) do
  local x=18+((index-1)%4)*151
  local y=-74-math.floor((index-1)/4)*30
  button(frame,144,x,y,D.professions[key].name,function()
    CP:ChangeView(key)
  end)
end

local view="now"
button(frame,112,18,-147,"Jetzt skillen",function() view="now";CP:Render() end)
button(frame,112,137,-147,"1–300 Etappen",function() view="stages";CP:Render() end)
button(frame,112,256,-147,"Materialien",function() view="mats";CP:Render() end)
button(frame,122,376,-147,"Lehrer: Wegpunkt",function()
  CP:TrainerWaypoint()
end)
button(frame,114,505,-147,"Aktualisieren",function()
  CP:Refresh(true)
end)

local status=label(frame,"GameFontHighlight",600,20,-186,"")
local rankText=label(frame,"GameFontHighlightSmall",600,18,-211,"")
local priceText=label(frame,"GameFontDisableSmall",600,20,-233,"")
local section=label(frame,"GameFontNormal",600,20,-259,"")
local scroll=CreateFrame("ScrollFrame","CraftPilotScroll",frame,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-286)
scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-40,60)
local content=CreateFrame("Frame",nil,scroll)
content:SetWidth(565)
content:SetHeight(400)
scroll:SetScrollChild(content)
local rows={}
local function setRows(lines)
  for i=1,#lines do
    local row=rows[i]
    if not row then
      row=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
      row:SetPoint("TOPLEFT",content,"TOPLEFT",0,-(i-1)*37)
      row:SetWidth(550)
      row:SetHeight(37)
      row:SetJustifyH("LEFT")
      row:SetJustifyV("TOP")
      row:SetWordWrap(true)
      rows[i]=row
    end
    row:SetText(lines[i])
    row:Show()
  end
  for i=#lines+1,#rows do rows[i]:Hide() end
  content:SetHeight(math.max(300,#lines*37+12))
  scroll:SetVerticalScroll(0)
end
local footer=label(frame,"GameFontDisableSmall",18,-577,600,
  "Alpha: Kosten sind Schätzungen aus dem letzten Auctionator-Scan.")

function CP:Render()
  if not self.db then return end
  local key=self.db.view
  local meta=D.professions[key]
  local p=self.db.professions[key]
  local skill=p and p.skill or 0
  local cap=p and p.cap or 0
  status:SetText(meta.name.."   "..(p and (skill.." / "..cap) or "noch nicht eingelesen")
    .."   |   Ziel: 300")
  local rank=self:NextRank(key)
  local npc=self:FindTrainer(key)
  if rank then
    local character=type(UnitLevel)=="function" and UnitLevel("player") or 0
    local requirement=(skill<rank.min and " | Skill "..rank.min.." erforderlich" or "")
    local requiredLevel=self:RankCharacterLevel(key,rank)
    if character<requiredLevel then
      requirement=requirement.." | Charakterstufe "..requiredLevel.." erforderlich"
    end
    rankText:SetText("Nächster Rang: "..rank.name.." (bis "..rank.cap..")"
      ..requirement.." | "..(npc and npc.name or "Lehrer unbekannt"))
  else
    rankText:SetText(p and "Maximaler Ausbildungsrang erreicht."
      or "Berufsfenster öffnen, um Skill und bekannte Rezepte einzulesen.")
  end
  priceText:SetText("Preise: gespeicherter Auctionator-Scan, keine Live-Auktionen | "
    ..(self.db.mode=="cash" and "Zukaufkosten" or "Materialwert")
    ..(self.db.includeBank and " | Bank an" or " | Taschen"))
  local lines={}
  if view=="stages" then
    section:SetText("Orientierung 1–300 (keine garantierte feste Rezeptliste)")
    for _,stage in ipairs(D.stages[key]) do
      local marker=skill>=stage[2] and "|cff8e9a9e[erledigt]|r"
        or (skill>=stage[1] and "|cff85dbad[AKTUELL]|r" or "[später]")
      lines[#lines+1]=string.format("%s  %d–%d: %s",marker,stage[1],stage[2],stage[3])
    end
    lines[#lines+1]="Die konkreten Rezepte und Kosten werden im Tab 'Jetzt skillen' "
      .."aus dem geöffneten Berufsfenster übernommen."
  elseif meta.gathering then
    section:SetText(meta.name..": passende Sammelstufen")
    for _,stage in ipairs(D.stages[key]) do
      if skill>=stage[1] and skill<stage[2] then
        lines[#lines+1]="Aktuell: "..stage[3]
        break
      end
    end
    if key=="herbalism" then
      lines[#lines+1]="Kräuter wachsen an wechselnden Fundstellen. Kräuter aufspüren aktivieren."
      lines[#lines+1]="Zum Lehrer führt der Button oben; Sammelstellen sind nicht garantiert."
    else
      lines[#lines+1]="Erzvorkommen erscheinen nicht an dauerhaft garantierten Positionen."
      lines[#lines+1]="Zum Lehrer führt der Button oben; eine Spitzhacke wird weiterhin benötigt."
    end
    lines[#lines+1]="Für Herstellungsberufe berechnet CraftPilot Kosten aus bekannten Rezepten."
  else
    local opts=self:Options(key)
    local capture=self.db.lastCapture
    local current=capture and capture.key==key and capture.skill==skill
    if view=="mats" then
      section:SetText("Einkaufsliste für die nächste Herstellung")
      if #opts==0 then
        lines[#lines+1]="Kein aktuelles auswertbares Rezept. Berufsfenster einmal öffnen."
      else
        lines[#lines+1]="Empfehlung: "..opts[1].name.." (1 Herstellung)"
        local any=false
        for _,mat in ipairs(opts[1].mats) do
          local required,owned=mat[2],self:ItemCount(mat[1])
          local deficit=math.max(0,required-owned)
          if deficit>0 then
            any=true
            local price=self:Price(mat[1])
            lines[#lines+1]=string.format("%d × %s  |  Lager %d  |  %s",
              deficit,self:ItemName(mat[1]),owned,price and gold(price*deficit) or "AH-Preis fehlt")
          end
        end
        if not any then lines[#lines+1]="Alle erforderlichen Materialien vorhanden." end
      end
    else
      section:SetText("Bekannte Rezepte: nach geschätzten Kosten je Skillpunkt")
      if not current then
        lines[#lines+1]="Berufsfenster öffnen. Erst dann können aktuelle Schwierigkeitsfarben"
          .." und Reagenzien korrekt ausgewertet werden."
      elseif #opts==0 then
        lines[#lines+1]="Kein geeignetes bekanntes Rezept mit eindeutig erfassten Reagenzien."
        lines[#lines+1]="Möglicherweise fehlen Ausbildungsrang, Rezepte oder Rezeptdaten."
      else
        for i=1,math.min(18,#opts) do
          local o=opts[i]
          lines[#lines+1]=string.format("%d. %s | ca. %d%% Skillchance | %s | %s",
            i,o.name,math.floor(o.chance*100),
            o.unknown and "Preis unvollständig" or gold(o.cost),
            o.missing==0 and "Material vorhanden" or (o.missing.." Teile fehlen"))
        end
        if #opts>18 then lines[#lines+1]="Weitere "..(#opts-18).." Rezepte nicht angezeigt." end
      end
    end
    if not p then
      lines[#lines+1]="Dieser Beruf wurde noch nicht auf dem Charakter erfasst."
    end
  end
  setRows(lines)
  footer:SetText("Alpha: Keine Kauf- oder Herstellungsautomatik. Materialwerte/Skillchancen sind Schätzungen.")
end

function CP:ToggleWindow()
  if frame:IsShown() then frame:Hide();return end
  self:Refresh(true)
  frame:Show()
end
