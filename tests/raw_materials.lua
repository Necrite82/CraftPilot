-- 1.0.0: raw materials one step back (ore in stock for missing bars).
local CP=...
local saved={avail=CP.ItemAvailability,mining=CP.db.professions.mining,current=CP.CurrentCharacter,alts=CP.AltProfessions}
local stock={[3858]=21}
CP.ItemAvailability=function(_,id) return stock[id] or 0 end
CP.CurrentCharacter=function() return {mail={[3858]=2}} end
CP.AltProfessions=function() return {} end
CP:ResetRawMaterialIndex()
CP.db.professions.mining={skill=200,cap=225}
local options=CP:RawMaterialOptions(3860)
assert(#options>=1 and options[1].id==10097 and options[1].count==23,"21 ore in stock + 2 in the mailbox make 23 Mithril bars")
assert(options[1].who=="me")
local text=CP:RawMaterialText(3860)
assert(text and text:find("23",1,true),"Hint names the count")
local hints=CP:RawMaterialHints({{id=3860,missing=5},{id=3859,missing=0}},3)
assert(#hints==1,"Only missing materials with stock get a hint")
-- No mining here, a twink smelts it.
CP.db.professions.mining=nil
CP.AltProfessions=function(_,key) return key=="mining" and {{name="Schmelzi",skill=230}} or {} end
assert(CP:RawMaterialOptions(3860)[1].who=="Schmelzi")
assert(CP:RawMaterialText(3860):find("Schmelzi",1,true))
-- Nothing in stock: no hint.
stock={};CP.CurrentCharacter=function() return {} end
assert(CP:RawMaterialText(3860)==nil)
CP.ItemAvailability,CP.db.professions.mining,CP.CurrentCharacter,CP.AltProfessions=saved.avail,saved.mining,saved.current,saved.alts
print("PASS: raw materials one step back: ore and mailbox for missing bars, twink who can smelt, no hint without stock")
