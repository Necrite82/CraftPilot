-- CraftPilot smelting subset, derived from Craft Ladder's Mining.lua (GPL-3.0).
-- Original copyright, credits and upstream revision: see ThirdParty/CraftLadder/CREDITS.txt
-- and ThirdParty/CraftLadder/SOURCE.md. Other mining data (nodes, coordinates, etc.) omitted.
local _, ns = ...
ns.MINING = {
  recipes = {
    [2657] = { name = "Smelt Copper", learn = 1, colors = { 1, 25, 47, 70 }, mats = { [2770] = 1 }, makes = 2840, count = 1, get = { { kind = "start" } } },
    [2658] = { name = "Smelt Silver", learn = 75, colors = { 75, 100, 112, 125 }, mats = { [2775] = 1 }, makes = 2842, count = 1, get = { { kind = "trainer", cost = 180 } } },
    [2659] = { name = "Smelt Bronze", learn = 65, colors = { 65, 65, 90, 115 }, mats = { [2840] = 1, [3576] = 1 }, makes = 2841, count = 2, get = { { kind = "trainer", cost = 200 } } },
    [3304] = { name = "Smelt Tin", learn = 65, colors = { 65, 50, 62, 75 }, mats = { [2771] = 1 }, makes = 3576, count = 1, get = { { kind = "trainer", cost = 50 } } },
    [3307] = { name = "Smelt Iron", learn = 125, colors = { 125, 130, 135, 140 }, mats = { [2772] = 1 }, makes = 3575, count = 1, get = { { kind = "trainer", cost = 450 } } },
    [3308] = { name = "Smelt Gold", learn = 155, colors = { 155, 170, 177, 185 }, mats = { [2776] = 1 }, makes = 3577, count = 1, get = { { kind = "trainer", cost = 2250 } } },
    [3569] = { name = "Smelt Steel", learn = 165, colors = { 165, 165, 165, 165 }, mats = { [3575] = 1, [3857] = 1 }, makes = 3859, count = 1, get = { { kind = "trainer", cost = 2250 } } },
    [10097] = { name = "Smelt Mithril", learn = 175, colors = { 175, 175, 202, 230 }, mats = { [3858] = 1 }, makes = 3860, count = 1, get = { { kind = "trainer", cost = 4500 } }, data = "classic" },
    [10098] = { name = "Smelt Truesilver", learn = 230, colors = { 230, 230, 235, 240 }, mats = { [7911] = 1 }, makes = 6037, count = 1, get = { { kind = "trainer", cost = 9000 } }, data = "classic" },
    [16153] = { name = "Smelt Thorium", learn = 250, colors = { 250, 250, 270, 290 }, mats = { [10620] = 1 }, makes = 12359, count = 1, get = { { kind = "trainer", cost = 18000 } }, data = "classic" },
  },
}
