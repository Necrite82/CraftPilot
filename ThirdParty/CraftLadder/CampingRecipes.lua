-- Filtered camping recipe records from Craft Ladder; GPL-3.0, original notices in CREDITS.txt.
-- Modified: only recipes referenced by Camp.lua. No gathering or unrelated recipes included.
local _,CP=...
CP.CampingRecipeData={
  ["cooking"]={
    [1229737] = { name = "Basic Campfire", learn = 1, colors = { 1, 1, 3, 5 }, makes = 279981, mats = { [4470] = 1 }, get = { { kind = "start" } }, forever = true },
    [1283400] = { name = "Journeyman Campfire", item = 273087, learn = 90, colors = { 90, 95, 100, 105 }, makes = 279961, mats = { [11291] = 1 }, get = { { kind = "drop", npcs = 1 } }, forever = true },
    [1262978] = { name = "Cookie's Feast", item = 273102, learn = 140, colors = { 140, 145, 147, 150 }, makes = 279957, mats = { [12037] = 2, [12204] = 1, [3713] = 1 }, get = {  }, forever = true },
    [1291341] = { name = "Expert Campfire", item = 273101, learn = 200, colors = { 200, 205, 212, 220 }, makes = 279974, mats = { [272941] = 1 }, get = {  }, forever = true },
    [1263067] = { name = "Iron Oven", item = 273115, learn = 300, colors = { 300, 300, 300, 300 }, makes = 279982, mats = { [10284] = 10, [159] = 5, [3713] = 4 }, get = {  }, forever = true },
  },
  ["firstaid"]={
    [1230117] = { name = "First Aid Kit", learn = 1, colors = { 1, 20, 22, 25 }, makes = 279968, mats = { [1251] = 3, [159] = 1 }, get = { { kind = "quest", quest = 96047, questName = "Camping 101: First Aid", faction = "A", reqLevel = 4 }, { kind = "quest", quest = 97903, questName = "Camping 101: First Aid", faction = "H", reqLevel = 4 }, { kind = "quest", quest = 97919, questName = "Camping 101: First Aid", faction = "A", reqLevel = 4 }, { kind = "quest", quest = 97931, questName = "Camping 101: First Aid", faction = "H", reqLevel = 4 }, { kind = "quest", quest = 97942, questName = "Camping 101: First Aid", faction = "A", reqLevel = 4 }, { kind = "quest", quest = 97955, questName = "Camping 101: First Aid", faction = "H", reqLevel = 4 }, { kind = "quest", quest = 97965, questName = "Camping 101: First Aid", faction = "AH", reqLevel = 4 } }, forever = true },
    [1262996] = { name = "Toxin Study", item = 273105, learn = 140, colors = { 140, 140, 142, 145 }, makes = 279940, mats = { [6452] = 1, [8544] = 2, [4470] = 2 }, get = { { kind = "drop", npcs = 1 } }, forever = true },
    [1263001] = { name = "Plague Doctor's Laboratory", item = 273118, learn = 300, colors = { 300, 300, 300, 300 }, makes = 279951, mats = { [4470] = 2, [6453] = 2, [14530] = 5 }, get = {  }, forever = true },
  },
  ["fishing"]={
  },
}
