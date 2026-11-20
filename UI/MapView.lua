-- Map window (taken over from GearPilot and shown in CraftPilot's look): a zoomable section of the zone map with
-- trainers, rank books and quests, recipe vendors and tour stops, plus your own position. The map art comes from the
-- game (C_Map art layers), the detail pieces from Data/Maps/MapOverlays.lua; zones it cannot draw fall back to the
-- world map. Clicking a point sets the waypoint (TomTom or the game's own).
--
-- CP:ShowMap(title, points): points = { { map, x, y (0..1), kind = "trainer"|"vendor"|"book"|"quest"|"drop",
--   title, sub, location } }  location = the destination CP:SetWaypoint takes.
local _,CP=...
local L=CP.L

local W,H,HEAD=600,500,78
local MAX_ZOOM=6
local ICONS={
  trainer="Interface\\GossipFrame\\TrainerGossipIcon", vendor="Interface\\GossipFrame\\VendorGossipIcon",
  book="Interface\\Icons\\INV_Misc_Book_09", quest="Interface\\GossipFrame\\AvailableQuestIcon",
  drop="Interface\\Icons\\INV_Misc_Head_Dragon_01", ah="Interface\\Icons\\INV_Misc_Coin_01",
}
local KIND_NAMES={trainer=L("Lehrer"),vendor=L("Händler"),book=L("Buch beim Händler"),quest=L("Quest"),drop=L("Boss / Beute")}
local FILTERS={{key="all",label=L("Alle")},{key="trainer",label=L("Lehrer")},{key="vendor",label=L("Händler")}}

local state={points={},maps={},map=nil,zoom=1,offsetX=0,offsetY=0,filter="all"}
local frame,view,canvas,message,title,zoneLabel,prevZone,nextZone,revealButton,worldButton
local filterButtons={}
local tiles,overlayTiles,pins={},{},{}
local playerPin

local function safe(fn,...) if type(fn)~="function" then return nil end local ok,a,b=pcall(fn,...) if ok then return a,b end end
local function mapName(uiMap)
  local info=C_Map and safe(C_Map.GetMapInfo,uiMap)
  return type(info)=="table" and info.name or nil
end

local function art(uiMap)
  if not (C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayerTextures) then return nil end
  local layers=safe(C_Map.GetMapArtLayers,uiMap)
  local layer=type(layers)=="table" and layers[1]
  if not (layer and layer.layerWidth and layer.layerWidth>0 and layer.tileWidth and layer.tileWidth>0) then return nil end
  local textures=safe(C_Map.GetMapArtLayerTextures,uiMap,1)
  if not (type(textures)=="table" and #textures>0) then return nil end
  return {width=layer.layerWidth,height=layer.layerHeight,tileWidth=layer.tileWidth,tileHeight=layer.tileHeight,textures=textures}
end
-- Detail pieces on top of the base map (towns, roads, forests): all of them, or only what you have explored.
local function overlays(uiMap)
  local reveal=not (CP.db and CP.db.ui.mapReveal==false)
  local data=CP.MapOverlays and CP.MapOverlays.maps and CP.MapOverlays.maps[uiMap]
  if reveal and data then return data end
  local list={}
  if C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures then
    local explored=safe(C_MapExplorationInfo.GetExploredMapTextures,uiMap)
    for _,info in ipairs(type(explored)=="table" and explored or {}) do
      if not info.isShownByMouseOver and info.fileDataIDs then
        list[#list+1]={info.offsetX or 0,info.offsetY or 0,info.textureWidth or 0,info.textureHeight or 0,info.fileDataIDs}
      end
    end
  end
  return list
end
local function pow2(value) local size=16;while size<value do size=size*2 end;return size end
local function fit(info)
  local vw,vh=view:GetWidth() or 400,view:GetHeight() or 300
  return math.min(vw/info.width,vh/info.height)
end
local function clampOffset(info,scale)
  local vw,vh=view:GetWidth() or 400,view:GetHeight() or 300
  local mw,mh=info.width*scale,info.height*scale
  if mw<=vw then state.offsetX=(vw-mw)/2 else state.offsetX=math.min(0,math.max(vw-mw,state.offsetX)) end
  if mh<=vh then state.offsetY=(vh-mh)/2 else state.offsetY=math.min(0,math.max(vh-mh,state.offsetY)) end
end
local function visible(point)
  if state.filter=="all" then return true end
  if state.filter=="trainer" then return point.kind=="trainer" or point.kind=="quest" end
  return point.kind=="vendor" or point.kind=="book"
end

local function pin(i)
  local p=pins[i]
  if p then return p end
  p=CreateFrame("Button",nil,canvas)
  p:SetSize(22,22)
  p.icon=p:CreateTexture(nil,"ARTWORK");p.icon:SetAllPoints()
  p.label=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");p.label:SetPoint("TOPLEFT",p,"BOTTOMRIGHT",-8,8)
  p:SetScript("OnEnter",function(self)
    local point=self.point;if not point or not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(point.title or "")
    GameTooltip:AddLine(KIND_NAMES[point.kind] or "",.88,.69,.31)
    if point.sub then GameTooltip:AddLine(point.sub,.85,.85,.85,true) end
    GameTooltip:AddLine(L("Klick: Wegpunkt"),.6,.64,.68)
    GameTooltip:Show()
  end)
  p:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  p:SetScript("OnClick",function(self) local point=self.point;if point and point.location then CP:SetWaypoint(point.location) end end)
  pins[i]=p
  return p
end

local Map={}
CP.Map=Map

function Map.Layout()
  if not (frame and frame:IsShown()) then return end
  for _,t in ipairs(tiles) do t:Hide() end
  for _,t in ipairs(overlayTiles) do t:Hide() end
  for _,p in ipairs(pins) do p:Hide() end
  if playerPin then playerPin:Hide() end
  local reveal=not (CP.db and CP.db.ui.mapReveal==false)
  revealButton:SetText(reveal and L("Ganze Karte") or L("Nur erkundet"))
  for _,b in ipairs(filterButtons) do CP:StyleSegment(b,b.filterKey==state.filter) end
  local uiMap=state.map
  local info=uiMap and art(uiMap)
  worldButton:SetEnabled(uiMap~=nil)
  if not info then
    message:SetWidth((view:GetWidth() or 300)-40)
    message:SetText(uiMap and L("Diese Karte kann CraftPilot nicht zeichnen. Öffne sie auf der Weltkarte.") or L("Für diese Auswahl ist kein Ort bekannt."))
    message:Show()
    return
  end
  message:Hide()
  local scale=fit(info)*state.zoom
  clampOffset(info,scale)
  canvas:ClearAllPoints()
  canvas:SetPoint("TOPLEFT",view,"TOPLEFT",state.offsetX,-state.offsetY)
  canvas:SetSize(info.width*scale,info.height*scale)
  local cols=math.ceil(info.width/info.tileWidth)
  for index,fileID in ipairs(info.textures) do
    local t=tiles[index]
    if not t then t=canvas:CreateTexture(nil,"BACKGROUND");tiles[index]=t end
    local col,row=(index-1)%cols,math.floor((index-1)/cols)
    t:SetTexture(fileID)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT",canvas,"TOPLEFT",col*info.tileWidth*scale,-row*info.tileHeight*scale)
    t:SetSize(info.tileWidth*scale,info.tileHeight*scale)
    t:Show()
  end
  -- Detail pieces, cut like the world map does: 256 px tiles, the last row and column smaller.
  local used=0
  for _,piece in ipairs(overlays(uiMap)) do
    local ox,oy,pw,ph,files=piece[1],piece[2],piece[3],piece[4],piece[5]
    local columns,rowsCount=math.ceil(pw/256),math.ceil(ph/256)
    for row=1,rowsCount do
      local pixelH=(row==rowsCount and ph%256~=0) and ph%256 or 256
      for col=1,columns do
        local fileID=files[(row-1)*columns+col]
        if fileID and fileID~=0 then
          local pixelW=(col==columns and pw%256~=0) and pw%256 or 256
          used=used+1
          local t=overlayTiles[used]
          if not t then t=canvas:CreateTexture(nil,"BORDER");overlayTiles[used]=t end
          t:SetTexture(fileID)
          t:SetTexCoord(0,pixelW/pow2(pixelW),0,pixelH/pow2(pixelH))
          t:ClearAllPoints()
          t:SetPoint("TOPLEFT",canvas,"TOPLEFT",(ox+(col-1)*256)*scale,-(oy+(row-1)*256)*scale)
          t:SetSize(pixelW*scale,pixelH*scale)
          t:Show()
        end
      end
    end
  end
  local n=0
  for _,point in ipairs(state.points) do
    if point.map==uiMap and visible(point) then
      n=n+1
      local p=pin(n)
      p.point=point
      p.icon:SetTexture(ICONS[point.kind] or ICONS.vendor)
      p.label:SetText(point.label or "")
      p:ClearAllPoints()
      p:SetPoint("CENTER",canvas,"TOPLEFT",point.x*info.width*scale,-point.y*info.height*scale)
      p:SetFrameLevel(canvas:GetFrameLevel()+2)
      p:Show()
    end
  end
  Map.UpdatePlayer()
end

function Map.UpdatePlayer()
  if not (frame and frame:IsShown() and state.map and C_Map and C_Map.GetPlayerMapPosition) then return end
  local info=art(state.map)
  if not info then return end
  local pos=safe(C_Map.GetPlayerMapPosition,state.map,"player")
  if not playerPin then
    playerPin=canvas:CreateTexture(nil,"OVERLAY");playerPin:SetSize(18,18);playerPin:SetTexture("Interface\\Minimap\\MinimapArrow")
  end
  local x,y
  if type(pos)=="table" then
    if type(pos.GetXY)=="function" then x,y=pos:GetXY() else x,y=pos.x,pos.y end
  end
  if not (x and y and x>0 and y>0) then playerPin:Hide();return end
  local scale=fit(info)*state.zoom
  playerPin:ClearAllPoints()
  playerPin:SetPoint("CENTER",canvas,"TOPLEFT",x*info.width*scale,-y*info.height*scale)
  if GetPlayerFacing and playerPin.SetRotation then playerPin:SetRotation(GetPlayerFacing() or 0) end
  playerPin:Show()
end

-- Zoom around a point of the view (cursor or centre): the map spot under it stays in place.
function Map.Zoom(factor,vx,vy)
  local info=state.map and art(state.map)
  if not info then return end
  local old=state.zoom
  local new=math.max(1,math.min(MAX_ZOOM,old*factor))
  if new==old then return end
  vx=vx or (view:GetWidth() or 400)/2
  vy=vy or (view:GetHeight() or 300)/2
  local base=fit(info)
  local mx,my=(vx-state.offsetX)/(base*old),(vy-state.offsetY)/(base*old)
  state.zoom=new
  state.offsetX,state.offsetY=vx-mx*base*new,vy-my*base*new
  Map.Layout()
end

-- Zones with points (after the filter): your zone first, then the zone with most points.
local function zones()
  local counts,order={},{}
  for _,point in ipairs(state.points) do
    if point.map and visible(point) then
      if not counts[point.map] then order[#order+1]=point.map end
      counts[point.map]=(counts[point.map] or 0)+1
    end
  end
  local list={}
  for _,m in ipairs(order) do list[#list+1]={map=m,count=counts[m],name=mapName(m) or ("#"..m)} end
  local here=C_Map and safe(C_Map.GetBestMapForUnit,"player")
  table.sort(list,function(a,b)
    if (a.map==here)~=(b.map==here) then return a.map==here end
    if a.count~=b.count then return a.count>b.count end
    return a.name<b.name
  end)
  return list
end
local function zoneIndex()
  for i,z in ipairs(state.maps) do if z.map==state.map then return i end end
  return nil
end
function Map.Refresh(keepMap)
  state.maps=zones()
  if not (keepMap and zoneIndex()) then state.map=state.maps[1] and state.maps[1].map or nil;state.zoom,state.offsetX,state.offsetY=1,0,0 end
  local i=zoneIndex()
  local z=i and state.maps[i]
  zoneLabel:SetText(z and string.format("%s (%d) · %d/%d",z.name,z.count,i,#state.maps) or L("Kein Ort"))
  prevZone:SetEnabled(#state.maps>1);nextZone:SetEnabled(#state.maps>1)
  Map.Layout()
end
local function stepZone(d)
  if #state.maps<2 then return end
  local i=zoneIndex() or 1
  i=(i-1+d)%#state.maps+1
  state.map=state.maps[i].map;state.zoom,state.offsetX,state.offsetY=1,0,0
  Map.Refresh(true)
end

local function build()
  frame=CreateFrame("Frame","CraftPilotProMap",UIParent,"BackdropTemplate")
  CP:Round(frame)
  if type(frame.SetBackdropColor)=="function" then frame:SetBackdropColor(.078,.090,.110,1);frame:SetBackdropBorderColor(.88,.69,.31,.9) end
  frame:SetSize(W,H);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG");frame:SetToplevel(true)
  frame:SetClampedToScreen(true);frame:SetMovable(true);frame:SetResizable(true);frame:EnableMouse(true)
  if frame.SetResizeBounds then frame:SetResizeBounds(420,340,1400,1000) end
  frame:Hide()
  if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"CraftPilotProMap") end
  local function save()
    if not CP.db then return end
    local point,_,relative,x,y=frame:GetPoint()
    CP.db.ui.mapWindow={point=point,relative=relative,x=x,y=y,w=frame:GetWidth(),h=frame:GetHeight()}
  end
  local header=CreateFrame("Frame",nil,frame)
  header:SetPoint("TOPLEFT",frame,"TOPLEFT",1,-1);header:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-1,-1);header:SetHeight(40)
  header:EnableMouse(true);header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart",function() frame:StartMoving() end)
  header:SetScript("OnDragStop",function() frame:StopMovingOrSizing();save() end)
  title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal");title:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-14);title:SetJustifyH("LEFT");title:SetWordWrap(false)
  local function flat(w,caption,fn)
    local b=CreateFrame("Button",nil,frame,"BackdropTemplate");b:SetSize(w,24);CP:StyleActionButton(b);b:SetText(caption);b:SetScript("OnClick",fn);return b
  end
  local close=flat(26,"x",function() frame:Hide() end);close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-10,-10)
  worldButton=flat(110,L("Weltkarte"),function()
    if not state.map then return end
    if WorldMapFrame and WorldMapFrame.SetMapID then
      if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
      WorldMapFrame:SetMapID(state.map)
    elseif OpenWorldMap then OpenWorldMap(state.map) end
  end)
  worldButton:SetPoint("RIGHT",close,"LEFT",-8,0)
  local zoomIn=flat(26,"+",function() Map.Zoom(1.25) end);zoomIn:SetPoint("RIGHT",worldButton,"LEFT",-8,0)
  local zoomOut=flat(26,"-",function() Map.Zoom(.8) end);zoomOut:SetPoint("RIGHT",zoomIn,"LEFT",-4,0)
  revealButton=flat(110,"",function() if CP.db then CP.db.ui.mapReveal=CP.db.ui.mapReveal==false;Map.Layout() end end)
  revealButton:SetPoint("RIGHT",zoomOut,"LEFT",-8,0)
  title:SetPoint("RIGHT",revealButton,"LEFT",-10,0)
  -- Second row: filter and zone switch.
  local x=14
  for _,f in ipairs(FILTERS) do
    local b=flat(74,f.label,function(self) state.filter=self.filterKey;Map.Refresh(true) end)
    b.filterKey=f.key;b:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-44);x=x+78
    filterButtons[#filterButtons+1]=b
  end
  nextZone=flat(26,">",function() stepZone(1) end);nextZone:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-12,-44)
  prevZone=flat(26,"<",function() stepZone(-1) end)
  zoneLabel=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight");zoneLabel:SetJustifyH("CENTER");zoneLabel:SetWordWrap(false)
  zoneLabel:SetPoint("RIGHT",nextZone,"LEFT",-6,0);zoneLabel:SetWidth(220)
  prevZone:SetPoint("RIGHT",zoneLabel,"LEFT",-6,0)
  view=CreateFrame("Frame",nil,frame,"BackdropTemplate")
  CP:Round(view)
  if type(view.SetBackdropColor)=="function" then view:SetBackdropColor(.098,.114,.137,1) end
  view:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-HEAD);view:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-12,12)
  if view.SetClipsChildren then view:SetClipsChildren(true) end
  view:EnableMouse(true);view:EnableMouseWheel(true)
  canvas=CreateFrame("Frame",nil,view);canvas:SetPoint("TOPLEFT",view,"TOPLEFT",0,0)
  message=view:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");message:SetPoint("TOPLEFT",view,"TOPLEFT",20,-20);message:SetJustifyH("LEFT");message:Hide()
  view:SetScript("OnMouseWheel",function(self,delta)
    local cx,cy=GetCursorPosition();local s=self:GetEffectiveScale()
    Map.Zoom(delta>0 and 1.25 or .8,cx/s-self:GetLeft(),self:GetTop()-cy/s)
  end)
  view:SetScript("OnMouseDown",function(self,button)
    if button~="LeftButton" then return end
    local cx,cy=GetCursorPosition()
    self.drag={x=cx,y=cy,ox=state.offsetX,oy=state.offsetY,scale=self:GetEffectiveScale()}
  end)
  view:SetScript("OnMouseUp",function(self) self.drag=nil end)
  local elapsed=0
  view:SetScript("OnUpdate",function(self,delta)
    if self.drag then
      local cx,cy=GetCursorPosition()
      state.offsetX=self.drag.ox+(cx-self.drag.x)/self.drag.scale
      state.offsetY=self.drag.oy-(cy-self.drag.y)/self.drag.scale
      Map.Layout();return
    end
    elapsed=elapsed+(delta or 0)
    if elapsed>.5 then elapsed=0;Map.UpdatePlayer() end
  end)
  local grip=CreateFrame("Button",nil,frame);grip:SetSize(16,16);grip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetScript("OnMouseDown",function() frame:StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp",function() frame:StopMovingOrSizing();save();Map.Layout() end)
  grip:SetFrameLevel((frame:GetFrameLevel() or 1)+20)
  frame:SetScript("OnSizeChanged",function() Map.Layout() end)
end

-- Opens the map with these points. Points without a usable position are left out.
function CP:ShowMap(heading,points)
  local list={}
  for _,p in ipairs(points or {}) do
    if type(p.map)=="number" and type(p.x)=="number" and type(p.y)=="number" and p.x>0 and p.y>0 then list[#list+1]=p end
  end
  if #list==0 then self:Say(L("Für diese Auswahl ist kein Ort bekannt."));return false end
  if not frame then build() end
  state.points=list;state.filter="all"
  title:SetText(heading or L("Karte"))
  local saved=self.db and self.db.ui.mapWindow
  if saved and saved.point and not frame.placed then
    frame:ClearAllPoints()
    frame:SetPoint(saved.point,UIParent,saved.relative or saved.point,saved.x or 0,saved.y or 0)
    if saved.w and saved.h then frame:SetSize(saved.w,saved.h) end
    frame.placed=true
  end
  frame:Show();if frame.Raise then frame:Raise() end
  Map.Refresh()
  return true,#list
end
function CP:MapPointsShown() return state.points,state.maps end
