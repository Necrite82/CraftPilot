-- 1.4.4: /cpp speicher wraps the main functions for a while and reports what they allocate; results and nils pass through.
local CP=...
local said={};local oldSay=CP.Say;CP.Say=function(_,m) said[#said+1]=m end
local oldAfter=C_Timer.After;local finish
C_Timer.After=function(_,fn) finish=fn end
local realRender=CP.Render
assert(CP:StartMemoryWatch(60))
assert(CP.Render~=realRender,"wrapped while measuring")
local ok,a,b=pcall(CP.RankSources,CP,"cooking")
CP:Render();CP:Render()
local x,y=CP:PlanRequirements("tailoring")
assert(type(x)=="table","results pass through")
finish()
assert(CP.Render==realRender and not CP.memoryWatch,"restored after the measurement")
local report=table.concat(said,"\n")
assert(report:find("Render",1,true) and report:find("2 Aufrufe",1,true) and report:find("Speichermessung",1,true),report)
C_Timer.After=oldAfter;CP.Say=oldSay
print("PASS: 1.4.4 /cpp speicher measures and restores the functions")
-- 1.4.4: a closed window is not redrawn on Refresh; it is marked and redrawn when shown.
do
  local renders=0;local realRender=CP.Render;CP.Render=function() renders=renders+1 end
  local wasShown=CP.frame:IsShown()
  CP.frame:Hide();CP.renderStale=false
  CP:Refresh(false)
  assert(renders==0 and CP.renderStale==true,"closed window: no redraw, marked stale")
  CP.frame:Show();CP:Refresh(false)
  assert(renders==1,"open window: redraw")
  CP.Render=realRender;CP.renderStale=false
  if not wasShown then CP.frame:Hide() end
end
-- 1.4.4: the frame scan makes no garbage per frame (no closures)
do
  local meta={__index={GetName=function(self) return self.name end,GetParent=function(self) return self.parent end,
    IsObjectType=function(self,t) return self.kind==t end}}
  local all={}
  for i=1,3000 do
    local p=setmetatable({kind="Frame"},meta);p.parent=setmetatable({kind="Frame"},meta)
    local f=setmetatable({kind=i%2==0 and "Button" or "Frame",parent=p},meta)
    if i%30==0 then f.GetBagID=function() return 0 end end
    all[i]=f
  end
  local index={};for i,f in ipairs(all) do index[f]=i end
  local saved=EnumerateFrames
  EnumerateFrames=function(prev) if not prev then return all[1] end;return all[index[prev]+1] end
  collectgarbage("collect");collectgarbage("stop")
  local before=collectgarbage("count")
  CP:FindItemButtons(true)
  local used=collectgarbage("count")-before
  collectgarbage("restart")
  EnumerateFrames=saved
  assert(used<50,"frame scan allocates "..used.." KB")
end
-- 1.4.4: stock counts are kept within one frame and passed through unchanged, nils included.
do
local t=100;GetTime=function() return t end
local calls=0;local real=CP.ItemAvailabilityUncached
CP.ItemAvailabilityUncached=function(self,id) calls=calls+1;return 5,3,2,true,true,0 end
local a,b,c,d,e,f=CP:ItemAvailability(2589);local a2=CP:ItemAvailability(2589)
assert(a==5 and b==3 and c==2 and d==true and f==0 and a2==5 and calls==1,"cached within a frame")
t=101;CP:ItemAvailability(2589);assert(calls==2,"new frame, new count")
CP:InvalidateReservations();CP:ItemAvailability(2589);assert(calls==3,"invalidated")
CP.ItemAvailabilityUncached=function() return 1,nil,nil,false end
t=102;local x,y,z,w=CP:ItemAvailability(1);assert(x==1 and y==nil and w==false,"nil values pass through")
CP.ItemAvailabilityUncached=real;GetTime=nil;CP.availabilityCache=nil
end

print("PASS: 1.4.4 no redraw while closed, frame scan without garbage, stock cache per frame")
