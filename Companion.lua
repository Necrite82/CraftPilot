-- Companion panel beside the game's profession window: the recommendation, crafts left until the
-- next color change, and notices when a recipe changes color or the training cap is reached.
local _,CP=...
local L=CP.L
local flat={bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}
local COLOR_NAMES={[0]=L("Orange"),[1]=L("Gelb"),[2]=L("Grün"),[3]=L("Grau")}
local INKS={[0]="|cffffa040",[1]="|cffffff50",[2]="|cff60df70",[3]="|cffaaaaaa"}
local HOSTS={"ProfessionsFrame","TradeSkillFrame"}

local function hostFrame()
  for _,name in ipairs(HOSTS) do
    local f=_G[name]
    if type(f)=="table" and type(f.IsShown)=="function" and f:IsShown() then return f end
  end
end

local function label(parent,font,width)
  local t=parent:CreateFontString(nil,"OVERLAY",font)
  t:SetJustifyH("LEFT");t:SetJustifyV("TOP");t:SetWidth(width);t:SetWordWrap(true)
  return t
end

local function smallButton(parent,width,caption,fn)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  CP:StyleActionButton(b);b:SetSize(width,24);b:SetText(caption);b:SetScript("OnClick",fn)
  return b
end

function CP:CompanionFrame()
  if self.companion then return self.companion end
  local f=CreateFrame("Frame","CraftPilotCompanion",UIParent,"BackdropTemplate")
  f:SetSize(250,180);f:SetBackdrop(flat)
  f:SetBackdropColor(.078,.090,.110,.97);f:SetBackdropBorderColor(.17,.196,.227,1)
  if type(f.SetFrameStrata)=="function" then f:SetFrameStrata("HIGH") end
  if type(f.SetClampedToScreen)=="function" then f:SetClampedToScreen(true) end
  f:EnableMouse(true)
  -- Drag at the header; the position is remembered relative to the screen.
  if type(f.SetMovable)=="function" then f:SetMovable(true) end
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function() if type(f.StartMoving)=="function" then f:StartMoving() end end)
  f:SetScript("OnDragStop",function()
    if type(f.StopMovingOrSizing)=="function" then f:StopMovingOrSizing() end
    local point,_,relPoint,x,y=f:GetPoint(1)
    if type(point)=="string" and type(x)=="number" and type(y)=="number" then
      CP.db.ui.companionPos={point=point,relPoint=relPoint or point,x=x,y=y}
    end
  end)
  f.stripe=f:CreateTexture(nil,"OVERLAY");f.stripe:SetWidth(3)
  f.stripe:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);f.stripe:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
  f.stripe:SetColorTexture(.88,.69,.31,1)
  f.logo=f:CreateTexture(nil,"ARTWORK");f.logo:SetSize(18,18);f.logo:SetPoint("TOPLEFT",f,"TOPLEFT",10,-8)
  f.logo:SetTexture("Interface\\AddOns\\CraftPilot\\Media\\CraftPilot")
  f.header=label(f,"GameFontNormal",150);f.header:SetPoint("TOPLEFT",f,"TOPLEFT",32,-10);f.header:SetText("CraftPilot")
  f.skill=label(f,"GameFontHighlightSmall",70);f.skill:SetJustifyH("RIGHT");f.skill:SetPoint("TOPRIGHT",f,"TOPRIGHT",-52,-11)
  -- Minimize to the header row and close until the profession window opens again.
  f.minimize=CreateFrame("Button",nil,f)
  f.minimize:SetSize(16,16);f.minimize:SetPoint("TOPRIGHT",f,"TOPRIGHT",-28,-8)
  f.minimize:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  f.minimize:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
  f.minimize:SetScript("OnClick",function() CP.db.ui.companionCollapsed=not CP.db.ui.companionCollapsed;CP:UpdateCompanion() end)
  f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
  f.close:SetSize(22,22);f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-3,-4)
  f.close:SetScript("OnClick",function() CP.companionClosed=true;f:Hide() end)
  f.title=label(f,"GameFontHighlight",226)
  f.detail=label(f,"GameFontHighlightSmall",226)
  f.progress=label(f,"GameFontNormalSmall",226)
  f.notice=label(f,"GameFontHighlightSmall",226)
  f.extra=label(f,"GameFontDisableSmall",226)
  f.select=smallButton(f,112,L("Rezept wählen"),function()
    local r=CP.currentCompanionRecommendation;if r then CP:OpenLearnedRecipe(r.key,r.id) end
  end)
  f.search=smallButton(f,112,L("Im AH suchen"),function()
    CP.currentRecommendation=CP.currentCompanionRecommendation;CP:SearchRecommendation()
  end)
  f.open=smallButton(f,112,L("CraftPilot öffnen"),function() CP:OpenTab("now") end)
  f.trainer=smallButton(f,112,L("Lehrer markieren"),function() CP:TrainerWaypoint() end)
  if self.StylePrimaryButton then self:StylePrimaryButton(f.select) end
  f:Hide()
  self.companion=f
  return f
end

-- Difficulty index (0 orange … 3 grey) of a learned recipe as last read from the client.
local function difficulty(self,key,id)
  local native=(self.db.recipes[key] or {})[id]
  local skill=(self.db.professions[key] or {}).skill
  if native and native.snapshotSkill==skill and type(native.difficulty)=="number" then return native.difficulty end
end

-- Crafts left until the recipe changes to its next color, from the stored color thresholds.
function CP:CraftsToNextColor(key,id)
  local colors=self:RecipeRangeData(key,id)
  local skill=(self.db.professions[key] or {}).skill
  if not colors or type(skill)~="number" then return nil end
  local nextIndex
  for i=2,4 do if skill<colors[i] then nextIndex=i;break end end
  if not nextIndex then return nil end
  local count=self.ExpectedCrafts and select(1,self:ExpectedCrafts(key,id,{colors=colors},skill,colors[nextIndex]))
  return count,colors[nextIndex],nextIndex-1
end

function CP:CompanionNotice(message)
  self.companionNotice={text=message,at=type(GetTime)=="function" and GetTime() or 0}
  if UIErrorsFrame and type(UIErrorsFrame.AddMessage)=="function" then pcall(UIErrorsFrame.AddMessage,UIErrorsFrame,"CraftPilot: "..message,1,.82,.3) end
end

local function watchChanges(self,key,rec)
  local record=self.db.professions[key]
  local state=self.companionState
  local diff=rec and difficulty(self,key,rec.id)
  if state and state.key==key and record then
    if rec and state.id==rec.id and diff and state.diff and diff>state.diff then
      self:CompanionNotice(string.format(L("%s ist jetzt %s."),rec.name,INKS[diff]..COLOR_NAMES[diff].."|r"))
    end
    if record.cap and record.cap<300 and record.skill>=record.cap and (state.skill or 0)<record.cap then
      self:CompanionNotice(string.format(L("Ausbildungsgrenze %d erreicht · nächsten Rang beim Lehrer lernen."),record.cap))
    end
  end
  self.companionState={key=key,id=rec and rec.id,diff=diff,skill=record and record.skill}
end

function CP:UpdateCompanion()
  if not self.db then return end
  local host=hostFrame()
  local f=self.companion
  if self.db.ui.companion==false or not host then if f then f:Hide() end;return end
  local capture=self.db.lastCapture
  local key=capture and capture.key
  local prof=key and self.Data.professions[key]
  if not prof or (prof.gathering and not prof.crafting) then if f then f:Hide() end;return end
  if self.companionClosed then if f then f:Hide() end;return end
  f=self:CompanionFrame()
  f:ClearAllPoints()
  local pos=self.db.ui.companionPos
  if type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number" then
    f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
  else
    -- Leave room for the profession tab icons along the window's right edge.
    f:SetPoint("TOPLEFT",host,"TOPRIGHT",60,0)
  end
  local collapsed=self.db.ui.companionCollapsed==true
  f.minimize:SetNormalTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
  local record=self.db.professions[key] or {}
  local rec=self:Recommendation(key)
  self.currentCompanionRecommendation=rec
  watchChanges(self,key,rec)
  f.skill:SetText((record.skill or 0).." / "..(record.cap or 0))
  local y=36
  local function put(node,gap)
    node:ClearAllPoints();node:SetPoint("TOPLEFT",f,"TOPLEFT",12,-y);node:Show()
    local h=node:GetStringHeight();y=y+(type(h)=="number" and h>0 and h or 14)+(gap or 6)
  end
  for _,node in ipairs({f.title,f.detail,f.progress,f.notice,f.extra,f.select,f.search,f.open,f.trainer}) do node:Hide() end
  if collapsed then
    f:SetHeight(34)
    f:Show()
    return
  end
  if rec then
    f.title:SetText(rec.title);put(f.title,4)
    f.detail:SetText(rec.detail);put(f.detail,8)
    local count,at,index=self:CraftsToNextColor(key,rec.id)
    if count then
      f.progress:SetText(string.format(L("Noch ca. %d× bis %s (Skill %d)"),count,INKS[index]..COLOR_NAMES[index].."|r",at))
      put(f.progress,8)
    end
  else
    f.title:SetText(L("Keine Empfehlung"))
    put(f.title,4)
    f.detail:SetText(L("Berufsfenster einmal komplett laden oder in CraftPilot einen Filter wählen."))
    put(f.detail,8)
  end
  local notice=self.companionNotice
  local fresh=notice and (type(GetTime)~="function" or GetTime()-notice.at<120)
  if fresh then
    f.notice:SetText("|cffffd878"..notice.text.."|r");put(f.notice,8)
  end
  -- Small status lines: rank or specialization due, learning tour stop, ready cooldowns, session balance.
  local extra={}
  local gate=self.RankGate and self:RankGate(key)
  if gate and (record.skill or 0)>=(record.cap or 0)-10 and (record.cap or 0)<300 then extra[#extra+1]=gate.text end
  local spec=self.SpecHint and self:SpecHint(key)
  if spec then extra[#extra+1]=spec end
  local tour=self.tour and self.tour.key==key and self.tour.stops[self.tour.index]
  if tour then extra[#extra+1]=string.format(L("Lerntour: nächster Halt %s"),tour.name) end
  if rec and self.KeepEntry then
    local output=self:RecipeMarketOutput(key,rec.id)
    local keep=output and self:KeepEntry(key,output)
    if keep then extra[#extra+1]="|cffffd200"..self:KeepText(keep).."|r" end
  end
  local cd=self.ReadyCooldownText and self:ReadyCooldownText()
  if cd then extra[#extra+1]=cd end
  local session=self.SessionText and self:SessionText(key)
  if session then extra[#extra+1]=session end
  if #extra>0 then f.extra:SetText(table.concat(extra,"\n"));put(f.extra,8) end
  local atCap=record.cap and record.cap<300 and (record.skill or 0)>=record.cap
  local row={}
  if rec and not rec.learn then row[#row+1]=f.select end
  if rec and not rec.learn and rec.missing>0 then row[#row+1]=f.search end
  if rec and rec.learn then row[#row+1]=f.trainer end
  if atCap and not (rec and rec.learn) then row[#row+1]=f.trainer end
  row[#row+1]=f.open
  for i,b in ipairs(row) do
    local col=(i-1)%2
    if col==0 and i>1 then y=y+28 end
    b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",12+col*116,-y);b:Show()
  end
  y=y+34
  f:SetHeight(y)
  f:Show()
end

local events=CreateFrame("Frame")
for _,event in ipairs({"TRADE_SKILL_SHOW","TRADE_SKILL_CLOSE","TRADE_SKILL_LIST_UPDATE"}) do pcall(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event)
  if event=="TRADE_SKILL_CLOSE" then
    if CP.companion then CP.companion:Hide() end
    CP.companionClosed=nil
    return
  end
  -- The game positions its window after the event; place the panel on the next frame.
  if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(.1,function() CP:UpdateCompanion() end)
  else CP:UpdateCompanion() end
end)
