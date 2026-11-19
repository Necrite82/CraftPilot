-- 1.3.0: vendor recipes with a visit status: offered, limited, sold out, not offered; learn target avoids sold out.
local CP=...
local saved={seen=(CP.account or CP.db).vendorSeen,vendors=CP.RecipeVendors,fee=CP.TrainerRecipeFee,price=CP.PriceDetails,rec=CP.db.recipes.engineering}
;(CP.account or CP.db).vendorSeen=nil
CP:ResetVendorStatusIndex()
-- Fizzlefuse (248200) sells some engineering recipe; find one of its items from the catalog
local item,recipeId
for id,r in pairs(CP.CatalogData.engineering.recipes) do
  for _,src in ipairs(r.get or {}) do if src.npc==248200 and r.item then item,recipeId=r.item,id end end
end
assert(item,"catalog has a Fizzlefuse recipe")
CP:RecordMerchantRecipes(248200,{{item=item,available=0}})
local st=CP:VendorRecipeStatus(248200,item)
assert(st and st.state=="soldout" and CP:VendorStatusText(st):find("ausverkauft",1,true))
CP:RecordMerchantRecipes(248200,{{item=item,available=2}})
assert(CP:VendorRecipeStatus(248200,item).left==2)
CP:RecordMerchantRecipes(248200,{})
assert(CP:VendorRecipeStatus(248200,item).state=="missing","Not in the window at all")
-- Learn target: sold-out vendor comes after another vendor
CP.db.recipes.engineering={}
CP.TrainerRecipeFee=function() return 0,nil,false end
CP.RecipeVendors=function() return {{id=248200,name="Fizzlefuse",location={name="F",zone="Z",map=1,x=.1,y=.1}},{id=777,name="Other",location={name="O",zone="Z",map=1,x=.2,y=.2}}} end
CP:RecordMerchantRecipes(248200,{{item=item,available=0}})
local t=CP:LearnTarget("engineering",recipeId)
assert(t and t.kind=="vendor" and t.name=="Other","Sold-out vendor skipped")
CP.RecipeVendors=function() return {{id=248200,name="Fizzlefuse",location={name="F",zone="Z",map=1,x=.1,y=.1}}} end
CP.PriceDetails=function() return {} end
t=CP:LearnTarget("engineering",recipeId)
assert(t and t.name=="Fizzlefuse" and t.status.state=="soldout","Only vendor: still named, with its status")
;(CP.account or CP.db).vendorSeen=saved.seen
CP.RecipeVendors,CP.TrainerRecipeFee,CP.PriceDetails,CP.db.recipes.engineering=saved.vendors,saved.fee,saved.price,saved.rec
print("PASS: 1.3.0 vendor visit status: offered, limited, sold out, not offered; learn target skips sold-out vendors")
