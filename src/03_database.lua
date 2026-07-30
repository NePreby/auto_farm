-- PHẦN 3: DATABASE — QUEST, ĐẢO, BOSS (3 SEA)
------------------------------------------------------------

-- ==================== VŨ KHÍ ====================
local MeleeNames = {
    "Combat", "Black Leg", "Electro", "Fishman Karate", "Dragon Claw",
    "Superhuman", "Death Step", "Sharkman Karate", "Electric Claw",
    "Dragon Talon", "Godhuman", "Sanguine Art"
}
local SwordNames = {
    "Katana", "Cutlass", "Dual Katana", "Iron Mace", "Pipe",
    "Shark Saw", "Bisento", "Trident", "Soul Cane", "Saddi",
    "Shisui", "Yama", "Tushita", "Dark Blade", "Buddy Sword",
    "Saber", "Gravity Cane", "Pole (1st form)", "Pole (2nd form)",
    "Midnight Blade", "Rengoku", "True Triple Katana", "Cursed Dual Katana",
    "Dragon Trident", "Hallow Scythe", "Dark Dagger", "Canvander",
    "Twin Hooks", "Koko", "Wando"
}
local GunNames = {
    "Slingshot", "Musket", "Flintlock", "Refined Flintlock",
    "Cannon", "Kabucha", "Bizarre Rifle", "Acidum Rifle",
    "Soul Guitar", "Serpent Bow"
}

-- ==================== ĐẢO - SEA 1 ====================
local IslandsSea1 = {
    ["Starter Island"]    = Vector3.new(1059, 15, 1549),
    ["Jungle"]            = Vector3.new(-1598, 36, 153),
    ["Pirate Village"]    = Vector3.new(-1182, 4, 3851),
    ["Desert"]            = Vector3.new(944, 6, 4373),
    ["Frozen Village"]    = Vector3.new(1255, 6, -4246),
    ["Marine Fortress"]   = Vector3.new(-5036, 24, 4317),
    ["Skylands"]          = Vector3.new(-4839, 717, -2620),
    ["Prison"]            = Vector3.new(4875, 5, 735),
    ["Colosseum"]         = Vector3.new(-1516, 7, -2994),
    ["Magma Village"]     = Vector3.new(-5241, 8, 8504),
    ["Underwater City"]   = Vector3.new(61163, 11, 1819),
    ["Fountain City"]     = Vector3.new(5121, 5, 4110),
    ["Upper Skylands"]    = Vector3.new(-7900, 5600, -1800),
    ["Mirage Island"]     = Vector3.new(15367, 262, 3252),
}

-- ==================== ĐẢO - SEA 2 ====================
local IslandsSea2 = {
    ["Kingdom of Rose"]    = Vector3.new(-360, 8, 390),
    ["Green Zone"]         = Vector3.new(-2410, 73, -3222),
    ["Graveyard"]          = Vector3.new(-5465, 87, -782),
    ["Snow Mountain"]      = Vector3.new(609, 400, -5765),
    ["Hot and Cold"]       = Vector3.new(-5700, 15, -3050),
    ["Cursed Ship"]        = Vector3.new(916, 88, 33022),
    ["Ice Castle"]         = Vector3.new(6125, 252, -4902),
    ["Forgotten Island"]   = Vector3.new(-3053, 236, -10197),
    ["Dark Arena"]         = Vector3.new(-465, 10, -1867),
    ["Mansion"]            = Vector3.new(-4545, 82, -691),
    ["Usoap's Island"]     = Vector3.new(4820, 10, 2620),
    ["Café"]               = Vector3.new(-379, 40, 254),
    ["Cake Island"]        = Vector3.new(-856, 8, -11221),
}

-- ==================== ĐẢO - SEA 3 ====================
local IslandsSea3 = {
    ["Port Town"]          = Vector3.new(-290, 42, 5358),
    ["Hydra Island"]       = Vector3.new(5229, 15, 353),
    ["Great Tree"]         = Vector3.new(2575, 1190, -680),
    ["Floating Turtle"]    = Vector3.new(-12142, 332, -3820),
    ["Haunted Castle"]     = Vector3.new(-9516, 167, 5765),
    ["Sea of Treats"]      = Vector3.new(-2364, 73, -10925),
    ["Tiki Outpost"]       = Vector3.new(-12104, 54, -5765),
    ["Castle on the Sea"]  = Vector3.new(-5044, 314, -2812),
    ["Mirage Island"]      = Vector3.new(15367, 262, 3252),
}

-- Hàm lấy đảo theo Sea hiện tại
local function getSeaIslands()
    if WorldSea == 1 then return IslandsSea1
    elseif WorldSea == 2 then return IslandsSea2
    elseif WorldSea == 3 then return IslandsSea3
    end
    return IslandsSea1
end

-- ==================== QUEST DATA — SEA 1 (Lv 1–700) ====================
local QuestsSea1 = {
    {MinLevel=1, MaxLevel=9, QuestName="BanditQuest1", QuestNumber=1, MobName="Bandit", QuestNpc=Vector3.new(1059.372,15.450,1550.423), MobPosition=Vector3.new(1045.963,27.003,1560.820)},
    {MinLevel=10, MaxLevel=14, QuestName="JungleQuest", QuestNumber=1, MobName="Monkey", QuestNpc=Vector3.new(-1598.089,35.550,153.378), MobPosition=Vector3.new(-1448.518,67.853,11.466)},
    {MinLevel=15, MaxLevel=29, QuestName="JungleQuest", QuestNumber=2, MobName="Gorilla", QuestNpc=Vector3.new(-1598.089,35.550,153.378), MobPosition=Vector3.new(-1129.884,40.464,-525.424)},
    {MinLevel=30, MaxLevel=39, QuestName="BuggyQuest1", QuestNumber=1, MobName="Pirate", QuestNpc=Vector3.new(-1141.075,4.100,3831.550), MobPosition=Vector3.new(-1201.084,40.629,3857.598)},
    {MinLevel=40, MaxLevel=59, QuestName="BuggyQuest1", QuestNumber=2, MobName="Brute", QuestNpc=Vector3.new(-1141.075,4.100,3831.550), MobPosition=Vector3.new(-1146.497,96.094,4312.138)},
    {MinLevel=60, MaxLevel=74, QuestName="DesertQuest", QuestNumber=1, MobName="Desert Bandit", QuestNpc=Vector3.new(894.489,5.140,4392.434), MobPosition=Vector3.new(924.800,6.449,4481.586)},
    {MinLevel=75, MaxLevel=89, QuestName="DesertQuest", QuestNumber=2, MobName="Desert Officer", QuestNpc=Vector3.new(894.489,5.140,4392.434), MobPosition=Vector3.new(1547.151,14.452,4381.800)},
    {MinLevel=90, MaxLevel=99, QuestName="SnowQuest", QuestNumber=1, MobName="Snow Bandit", QuestNpc=Vector3.new(1389.745,88.152,-1298.908), MobPosition=Vector3.new(1354.348,87.273,-1393.947)},
    {MinLevel=100, MaxLevel=119, QuestName="SnowQuest", QuestNumber=2, MobName="Snowman", QuestNpc=Vector3.new(1389.745,88.152,-1298.908), MobPosition=Vector3.new(1201.641,144.580,-1550.067)},
    {MinLevel=120, MaxLevel=149, QuestName="MarineQuest2", QuestNumber=1, MobName="Chief Petty Officer", QuestNpc=Vector3.new(-5039.586,27.350,4324.680), MobPosition=Vector3.new(-4881.231,22.652,4273.752)},
    {MinLevel=150, MaxLevel=174, QuestName="SkyQuest", QuestNumber=1, MobName="Sky Bandit", QuestNpc=Vector3.new(-4839.530,716.369,-2619.442), MobPosition=Vector3.new(-4953.207,295.744,-2899.229)},
    {MinLevel=175, MaxLevel=189, QuestName="SkyQuest", QuestNumber=2, MobName="Dark Master", QuestNpc=Vector3.new(-4839.530,716.369,-2619.442), MobPosition=Vector3.new(-5259.845,391.398,-2229.035)},
    {MinLevel=190, MaxLevel=209, QuestName="PrisonerQuest", QuestNumber=1, MobName="Prisoner", QuestNpc=Vector3.new(5308.931,1.655,475.121), MobPosition=Vector3.new(5098.974,-0.320,474.237)},
    {MinLevel=210, MaxLevel=249, QuestName="PrisonerQuest", QuestNumber=2, MobName="Dangerous Prisoner", QuestNpc=Vector3.new(5308.931,1.655,475.121), MobPosition=Vector3.new(5654.563,15.633,866.299)},
    {MinLevel=250, MaxLevel=274, QuestName="ColosseumQuest", QuestNumber=1, MobName="Toga Warrior", QuestNpc=Vector3.new(-1580.047,6.350,-2986.475), MobPosition=Vector3.new(-1820.215,51.684,-2740.665)},
    {MinLevel=275, MaxLevel=299, QuestName="ColosseumQuest", QuestNumber=2, MobName="Gladiator", QuestNpc=Vector3.new(-1580.047,6.350,-2986.475), MobPosition=Vector3.new(-1292.838,56.381,-3339.031)},
    {MinLevel=300, MaxLevel=324, QuestName="MagmaQuest", QuestNumber=1, MobName="Military Soldier", QuestNpc=Vector3.new(-5313.370,10.950,8515.294), MobPosition=Vector3.new(-5411.165,11.082,8454.293)},
    {MinLevel=325, MaxLevel=374, QuestName="MagmaQuest", QuestNumber=2, MobName="Military Spy", QuestNpc=Vector3.new(-5313.370,10.950,8515.294), MobPosition=Vector3.new(-5802.868,86.262,8828.859)},
    {MinLevel=375, MaxLevel=399, QuestName="FishmanQuest", QuestNumber=1, MobName="Fishman Warrior", QuestNpc=Vector3.new(61122.652,18.497,1569.400), MobPosition=Vector3.new(60878.301,18.483,1543.757), Entrance=Vector3.new(61163.852,11.680,1819.785)},
    {MinLevel=400, MaxLevel=449, QuestName="FishmanQuest", QuestNumber=2, MobName="Fishman Commando", QuestNpc=Vector3.new(61122.652,18.497,1569.400), MobPosition=Vector3.new(61922.633,18.483,1493.934), Entrance=Vector3.new(61163.852,11.680,1819.785)},
    {MinLevel=450, MaxLevel=474, QuestName="SkyExp1Quest", QuestNumber=1, MobName="God's Guard", QuestNpc=Vector3.new(-4721.889,843.875,-1949.966), MobPosition=Vector3.new(-4710.043,845.277,-1927.308), Entrance=Vector3.new(-4607.823,872.542,-1667.557)},
    {MinLevel=475, MaxLevel=524, QuestName="SkyExp1Quest", QuestNumber=2, MobName="Shanda", QuestNpc=Vector3.new(-7859.098,5544.190,-381.476), MobPosition=Vector3.new(-7678.490,5566.404,-497.216), Entrance=Vector3.new(-7894.618,5547.142,-380.291)},
    {MinLevel=525, MaxLevel=549, QuestName="SkyExp2Quest", QuestNumber=1, MobName="Royal Squad", QuestNpc=Vector3.new(-7906.816,5634.663,-1411.992), MobPosition=Vector3.new(-7624.252,5658.133,-1467.354), Entrance=Vector3.new(-7894.618,5547.142,-380.291)},
    {MinLevel=550, MaxLevel=624, QuestName="SkyExp2Quest", QuestNumber=2, MobName="Royal Soldier", QuestNpc=Vector3.new(-7906.816,5634.663,-1411.992), MobPosition=Vector3.new(-7836.753,5645.664,-1790.623), Entrance=Vector3.new(-7894.618,5547.142,-380.291)},
    {MinLevel=625, MaxLevel=649, QuestName="FountainQuest", QuestNumber=1, MobName="Galley Pirate", QuestNpc=Vector3.new(5259.820,37.350,4050.029), MobPosition=Vector3.new(5551.022,78.901,3930.413)},
    {MinLevel=650, MaxLevel=math.huge, QuestName="FountainQuest", QuestNumber=2, MobName="Galley Captain", QuestNpc=Vector3.new(5259.820,37.350,4050.029), MobPosition=Vector3.new(5441.952,42.502,4950.094)},
}

local QuestsSea2 = {
    {MinLevel=700, MaxLevel=724, QuestName="Area1Quest", QuestNumber=1, MobName="Raider", QuestNpc=Vector3.new(-429.544,71.770,1836.182), MobPosition=Vector3.new(-728.327,52.779,2345.771)},
    {MinLevel=725, MaxLevel=774, QuestName="Area1Quest", QuestNumber=2, MobName="Mercenary", QuestNpc=Vector3.new(-429.544,71.770,1836.182), MobPosition=Vector3.new(-1004.324,80.159,1424.619)},
    {MinLevel=775, MaxLevel=799, QuestName="Area2Quest", QuestNumber=1, MobName="Swan Pirate", QuestNpc=Vector3.new(638.438,71.770,918.283), MobPosition=Vector3.new(1065.367,137.640,1324.380)},
    {MinLevel=800, MaxLevel=874, QuestName="Area2Quest", QuestNumber=2, MobName="Factory Staff", QuestNpc=Vector3.new(638.438,71.770,918.283), MobPosition=Vector3.new(296.793,72.995,-57.149)},
    {MinLevel=875, MaxLevel=899, QuestName="MarineQuest3", QuestNumber=1, MobName="Marine Lieutenant", QuestNpc=Vector3.new(-2440.796,71.714,-3216.068), MobPosition=Vector3.new(-2821.372,75.897,-3070.089)},
    {MinLevel=900, MaxLevel=949, QuestName="MarineQuest3", QuestNumber=2, MobName="Marine Captain", QuestNpc=Vector3.new(-2440.796,71.714,-3216.068), MobPosition=Vector3.new(-1861.235,80.172,-3254.669)},
    {MinLevel=950, MaxLevel=974, QuestName="ZombieQuest", QuestNumber=1, MobName="Zombie", QuestNpc=Vector3.new(-5497.062,47.592,-795.237), MobPosition=Vector3.new(-5657.777,78.970,-928.687)},
    {MinLevel=975, MaxLevel=999, QuestName="ZombieQuest", QuestNumber=2, MobName="Vampire", QuestNpc=Vector3.new(-5497.062,47.592,-795.237), MobPosition=Vector3.new(-6037.668,32.185,-1340.660)},
    {MinLevel=1000, MaxLevel=1049, QuestName="SnowMountainQuest", QuestNumber=1, MobName="Snow Trooper", QuestNpc=Vector3.new(609.859,400.120,-5372.259), MobPosition=Vector3.new(549.147,427.387,-5563.699)},
    {MinLevel=1050, MaxLevel=1099, QuestName="SnowMountainQuest", QuestNumber=2, MobName="Winter Warrior", QuestNpc=Vector3.new(609.859,400.120,-5372.259), MobPosition=Vector3.new(1142.745,475.665,-5199.417)},
    {MinLevel=1100, MaxLevel=1124, QuestName="IceSideQuest", QuestNumber=1, MobName="Lab Subordinate", QuestNpc=Vector3.new(-6064.069,15.242,-4902.979), MobPosition=Vector3.new(-5707.472,56.656,-4517.424)},
    {MinLevel=1125, MaxLevel=1174, QuestName="IceSideQuest", QuestNumber=2, MobName="Horned Warrior", QuestNpc=Vector3.new(-6064.069,15.242,-4902.979), MobPosition=Vector3.new(-6298.242,83.999,-5575.932)},
    {MinLevel=1175, MaxLevel=1199, QuestName="FireSideQuest", QuestNumber=1, MobName="Magma Ninja", QuestNpc=Vector3.new(-5428.032,15.062,-5299.435), MobPosition=Vector3.new(-5466.911,75.151,-5856.288)},
    {MinLevel=1200, MaxLevel=1249, QuestName="FireSideQuest", QuestNumber=2, MobName="Lava Pirate", QuestNpc=Vector3.new(-5428.032,15.062,-5299.435), MobPosition=Vector3.new(-5251.189,51.284,-4774.408)},
    {MinLevel=1250, MaxLevel=1274, QuestName="ShipQuest1", QuestNumber=1, MobName="Ship Deckhand", QuestNpc=Vector3.new(1037.801,125.092,32911.602), MobPosition=Vector3.new(1212.011,150.792,33059.246), Entrance=Vector3.new(923.213,126.976,32852.832)},
    {MinLevel=1275, MaxLevel=1299, QuestName="ShipQuest1", QuestNumber=2, MobName="Ship Engineer", QuestNpc=Vector3.new(1037.801,125.092,32911.602), MobPosition=Vector3.new(919.479,43.544,32779.969), Entrance=Vector3.new(923.213,126.976,32852.832)},
    {MinLevel=1300, MaxLevel=1324, QuestName="ShipQuest2", QuestNumber=1, MobName="Ship Steward", QuestNpc=Vector3.new(968.810,125.092,33244.125), MobPosition=Vector3.new(919.439,129.556,33436.035), Entrance=Vector3.new(923.213,126.976,32852.832)},
    {MinLevel=1325, MaxLevel=1349, QuestName="ShipQuest2", QuestNumber=2, MobName="Ship Officer", QuestNpc=Vector3.new(968.810,125.092,33244.125), MobPosition=Vector3.new(1036.018,181.439,33315.727), Entrance=Vector3.new(923.213,126.976,32852.832)},
    {MinLevel=1350, MaxLevel=1374, QuestName="FrostQuest", QuestNumber=1, MobName="Arctic Warrior", QuestNpc=Vector3.new(5667.658,26.800,-6486.090), MobPosition=Vector3.new(5966.246,62.970,-6179.383)},
    {MinLevel=1375, MaxLevel=1424, QuestName="FrostQuest", QuestNumber=2, MobName="Snow Lurker", QuestNpc=Vector3.new(5667.658,26.800,-6486.090), MobPosition=Vector3.new(5407.074,69.194,-6880.880)},
    {MinLevel=1425, MaxLevel=1449, QuestName="ForgottenQuest", QuestNumber=1, MobName="Sea Soldier", QuestNpc=Vector3.new(-3054.445,235.544,-10142.819), MobPosition=Vector3.new(-3185.510,58.789,-9663.635)},
    {MinLevel=1450, MaxLevel=math.huge, QuestName="ForgottenQuest", QuestNumber=2, MobName="Water Fighter", QuestNpc=Vector3.new(-3054.445,235.544,-10142.819), MobPosition=Vector3.new(-3262.930,298.690,-10551.584)},
}

local QuestsSea3 = {
    {MinLevel=1500, MaxLevel=1524, QuestName="PiratePortQuest", QuestNumber=1, MobName="Pirate Millionaire", QuestNpc=Vector3.new(-290.075,42.903,5581.590), MobPosition=Vector3.new(81.165,43.756,5724.702)},
    {MinLevel=1525, MaxLevel=1574, QuestName="PiratePortQuest", QuestNumber=2, MobName="Pistol Billionaire", QuestNpc=Vector3.new(-290.075,42.903,5581.590), MobPosition=Vector3.new(81.165,43.756,5724.702)},
    {MinLevel=1575, MaxLevel=1599, QuestName="AmazonQuest", QuestNumber=1, MobName="Dragon Crew Warrior", QuestNpc=Vector3.new(5832.836,51.681,-1101.516), MobPosition=Vector3.new(6301.998,104.772,-1082.608)},
    {MinLevel=1600, MaxLevel=1624, QuestName="AmazonQuest", QuestNumber=2, MobName="Dragon Crew Archer", QuestNpc=Vector3.new(5832.836,51.681,-1101.516), MobPosition=Vector3.new(6831.117,483.070,514.792)},
    {MinLevel=1625, MaxLevel=1649, QuestName="AmazonQuest2", QuestNumber=1, MobName="Female Islander", QuestNpc=Vector3.new(5448.861,601.532,751.114), MobPosition=Vector3.new(5792.517,848.144,1084.182)},
    {MinLevel=1650, MaxLevel=1699, QuestName="AmazonQuest2", QuestNumber=2, MobName="Giant Islander", QuestNpc=Vector3.new(5448.861,601.532,751.114), MobPosition=Vector3.new(5034.813,664.653,-123.631)},
    {MinLevel=1700, MaxLevel=1724, QuestName="MarineTreeIsland", QuestNumber=1, MobName="Marine Commodore", QuestNpc=Vector3.new(2180.541,27.816,-6741.550), MobPosition=Vector3.new(2490.084,190.423,-7160.050)},
    {MinLevel=1725, MaxLevel=1774, QuestName="MarineTreeIsland", QuestNumber=2, MobName="Marine Rear Admiral", QuestNpc=Vector3.new(2180.541,27.816,-6741.550), MobPosition=Vector3.new(3951.393,227.110,-6912.053)},
    {MinLevel=1775, MaxLevel=1799, QuestName="DeepForestIsland3", QuestNumber=1, MobName="Fishman Raider", QuestNpc=Vector3.new(-10581.656,330.873,-8761.187), MobPosition=Vector3.new(-10407.526,331.763,-8368.604)},
    {MinLevel=1800, MaxLevel=1824, QuestName="DeepForestIsland3", QuestNumber=2, MobName="Fishman Captain", QuestNpc=Vector3.new(-10581.656,330.873,-8761.187), MobPosition=Vector3.new(-10994.701,352.381,-9002.110)},
    {MinLevel=1825, MaxLevel=1849, QuestName="DeepForestIsland", QuestNumber=1, MobName="Forest Pirate", QuestNpc=Vector3.new(-13234.040,331.488,-7625.401), MobPosition=Vector3.new(-13225.021,428.194,-7753.467)},
    {MinLevel=1850, MaxLevel=1899, QuestName="DeepForestIsland", QuestNumber=2, MobName="Mythological Pirate", QuestNpc=Vector3.new(-13234.040,331.488,-7625.401), MobPosition=Vector3.new(-13869.173,564.813,-7086.048)},
    {MinLevel=1900, MaxLevel=1924, QuestName="DeepForestIsland2", QuestNumber=1, MobName="Jungle Pirate", QuestNpc=Vector3.new(-12680.382,389.971,-9902.020), MobPosition=Vector3.new(-12262.889,430.273,-10393.493)},
    {MinLevel=1925, MaxLevel=1974, QuestName="DeepForestIsland2", QuestNumber=2, MobName="Musketeer Pirate", QuestNpc=Vector3.new(-12680.382,389.971,-9902.020), MobPosition=Vector3.new(-13283.894,524.385,-9975.609)},
    {MinLevel=1975, MaxLevel=1999, QuestName="HauntedQuest1", QuestNumber=1, MobName="Reborn Skeleton", QuestNpc=Vector3.new(-9479.217,141.215,5566.093), MobPosition=Vector3.new(-8761.315,164.858,6161.160)},
    {MinLevel=2000, MaxLevel=2024, QuestName="HauntedQuest1", QuestNumber=2, MobName="Living Zombie", QuestNpc=Vector3.new(-9479.217,141.215,5566.093), MobPosition=Vector3.new(-10144.132,138.627,6243.350)},
    {MinLevel=2025, MaxLevel=2049, QuestName="HauntedQuest2", QuestNumber=1, MobName="Demonic Soul", QuestNpc=Vector3.new(-9515.750,174.852,6079.406), MobPosition=Vector3.new(-9506.401,176.094,6172.262)},
    {MinLevel=2050, MaxLevel=2074, QuestName="HauntedQuest2", QuestNumber=2, MobName="Posessed Mummy", QuestNpc=Vector3.new(-9515.750,174.852,6079.406), MobPosition=Vector3.new(-9582.151,6.179,6188.422)},
    {MinLevel=2075, MaxLevel=2099, QuestName="NutsIslandQuest", QuestNumber=1, MobName="Peanut Scout", QuestNpc=Vector3.new(-2104.172,38.130,-10194.418), MobPosition=Vector3.new(-2150.406,120.125,-10353.003)},
    {MinLevel=2100, MaxLevel=2124, QuestName="NutsIslandQuest", QuestNumber=2, MobName="Peanut President", QuestNpc=Vector3.new(-2104.172,38.130,-10194.418), MobPosition=Vector3.new(-2150.406,120.125,-10353.003)},
    {MinLevel=2125, MaxLevel=2149, QuestName="IceCreamIslandQuest", QuestNumber=1, MobName="Ice Cream Chef", QuestNpc=Vector3.new(-820.648,65.820,-10965.796), MobPosition=Vector3.new(-857.365,117.309,-11037.851)},
    {MinLevel=2150, MaxLevel=2199, QuestName="IceCreamIslandQuest", QuestNumber=2, MobName="Ice Cream Commander", QuestNpc=Vector3.new(-820.648,65.820,-10965.796), MobPosition=Vector3.new(-857.365,117.309,-11037.851)},
    {MinLevel=2200, MaxLevel=2224, QuestName="CakeQuest1", QuestNumber=1, MobName="Cookie Crafter", QuestNpc=Vector3.new(-2021.320,37.798,-12028.730), MobPosition=Vector3.new(-2322.064,37.798,-12150.913)},
    {MinLevel=2225, MaxLevel=2249, QuestName="CakeQuest1", QuestNumber=2, MobName="Cake Guard", QuestNpc=Vector3.new(-2021.320,37.798,-12028.730), MobPosition=Vector3.new(-1418.110,37.798,-12255.732)},
    {MinLevel=2250, MaxLevel=2274, QuestName="CakeQuest2", QuestNumber=1, MobName="Baking Staff", QuestNpc=Vector3.new(-1927.916,37.798,-12842.539), MobPosition=Vector3.new(-1837.280,77.606,-12896.552)},
    {MinLevel=2275, MaxLevel=2299, QuestName="CakeQuest2", QuestNumber=2, MobName="Head Baker", QuestNpc=Vector3.new(-1927.916,37.798,-12842.539), MobPosition=Vector3.new(-2203.302,70.915,-12903.390)},
    {MinLevel=2300, MaxLevel=2324, QuestName="ChocQuest1", QuestNumber=1, MobName="Cocoa Warrior", QuestNpc=Vector3.new(233.228,29.876,-12201.233), MobPosition=Vector3.new(137.829,82.420,-12396.800)},
    {MinLevel=2325, MaxLevel=2349, QuestName="ChocQuest1", QuestNumber=2, MobName="Chocolate Bar Battler", QuestNpc=Vector3.new(233.228,29.876,-12201.233), MobPosition=Vector3.new(721.716,82.420,-12596.176)},
    {MinLevel=2350, MaxLevel=2374, QuestName="ChocQuest2", QuestNumber=1, MobName="Sweet Thief", QuestNpc=Vector3.new(150.507,30.694,-12774.503), MobPosition=Vector3.new(128.246,82.420,-12860.881)},
    {MinLevel=2375, MaxLevel=2399, QuestName="ChocQuest2", QuestNumber=2, MobName="Candy Rebel", QuestNpc=Vector3.new(150.507,30.694,-12774.503), MobPosition=Vector3.new(128.246,82.420,-12860.881)},
    {MinLevel=2400, MaxLevel=2424, QuestName="CandyQuest", QuestNumber=1, MobName="Candy Pirate", QuestNpc=Vector3.new(-1150.040,20.379,-14446.335), MobPosition=Vector3.new(-1310.500,26.017,-14562.404)},
    {MinLevel=2425, MaxLevel=2449, QuestName="CandyQuest", QuestNumber=2, MobName="Snow Demon", QuestNpc=Vector3.new(-1150.040,20.379,-14446.335), MobPosition=Vector3.new(-887.181,82.420,-14525.981)},
    {MinLevel=2450, MaxLevel=2474, QuestName="TikiQuest1", QuestNumber=1, MobName="Isle Outlaw", QuestNpc=Vector3.new(-16547.746,61.135,-173.414), MobPosition=Vector3.new(-16448.922,116.139,-277.707)},
    {MinLevel=2475, MaxLevel=2499, QuestName="TikiQuest1", QuestNumber=2, MobName="Island Boy", QuestNpc=Vector3.new(-16547.746,61.135,-173.414), MobPosition=Vector3.new(-16901.262,84.068,-192.889)},
    {MinLevel=2500, MaxLevel=2524, QuestName="TikiQuest2", QuestNumber=1, MobName="Sun-kissed Warrior", QuestNpc=Vector3.new(-16539.078,55.686,1051.574), MobPosition=Vector3.new(-16321.292,92.102,1111.195)},
    {MinLevel=2525, MaxLevel=2549, QuestName="TikiQuest2", QuestNumber=2, MobName="Isle Champion", QuestNpc=Vector3.new(-16539.078,55.686,1051.574), MobPosition=Vector3.new(-16641.688,125.975,1065.094)},
    {MinLevel=2550, MaxLevel=2574, QuestName="TikiQuest3", QuestNumber=1, MobName="Serpent Hunter", QuestNpc=Vector3.new(-16667.146,105.340,1573.600), MobPosition=Vector3.new(-16551.104,116.325,1538.730)},
    {MinLevel=2575, MaxLevel=2599, QuestName="TikiQuest3", QuestNumber=2, MobName="Skull Slayer", QuestNpc=Vector3.new(-16667.146,105.340,1573.600), MobPosition=Vector3.new(-16808.527,120.855,1479.563)},
    {MinLevel=2600, MaxLevel=2624, QuestName="SubmergedQuest1", QuestNumber=1, MobName="Reef Bandit", QuestNpc=Vector3.new(10778.875,-2087.724,9265.184), MobPosition=Vector3.new(11019.132,-2146.068,9342.392), Travel="Submerged"},
    {MinLevel=2625, MaxLevel=2649, QuestName="SubmergedQuest1", QuestNumber=2, MobName="Coral Pirate", QuestNpc=Vector3.new(10778.875,-2087.724,9265.184), MobPosition=Vector3.new(10808.601,-2030.361,9364.233), Travel="Submerged"},
    {MinLevel=2650, MaxLevel=2674, QuestName="SubmergedQuest2", QuestNumber=1, MobName="Sea Chanter", QuestNpc=Vector3.new(10880.686,-2086.200,10032.624), MobPosition=Vector3.new(10671.272,-2057.592,10047.259), Travel="Submerged"},
    {MinLevel=2675, MaxLevel=2699, QuestName="SubmergedQuest2", QuestNumber=2, MobName="Ocean Prophet", QuestNpc=Vector3.new(10880.686,-2086.200,10032.624), MobPosition=Vector3.new(11008.520,-2007.728,10223.079), Travel="Submerged"},
    {MinLevel=2700, MaxLevel=2724, QuestName="SubmergedQuest3", QuestNumber=1, MobName="High Disciple", QuestNpc=Vector3.new(9640.088,-1992.445,9613.652), MobPosition=Vector3.new(9750.416,-1966.939,9753.360), Travel="Submerged"},
    {MinLevel=2725, MaxLevel=math.huge, QuestName="SubmergedQuest3", QuestNumber=2, MobName="Grand Devotee", QuestNpc=Vector3.new(9640.088,-1992.445,9613.652), MobPosition=Vector3.new(9611.705,-1993.471,9882.688), Travel="Submerged"},
}

-- ==================== BOSS QUEST DATA (3 SEA) ====================
local BossQuestsSea1 = {
    {MinLevel=25, MaxLevel=29, QuestName="JungleQuest", QuestNumber=3, MobName="The Gorilla King", QuestNpc=Vector3.new(-1598.089,35.550,153.378), MobPosition=Vector3.new(-1243.000,6.000,-493.000)},
    {MinLevel=55, MaxLevel=59, QuestName="BuggyQuest1", QuestNumber=3, MobName="Bobby", QuestNpc=Vector3.new(-1141.075,4.100,3831.550), MobPosition=Vector3.new(-1145.000,14.000,4300.000)},
    {MinLevel=110, MaxLevel=119, QuestName="SnowQuest", QuestNumber=3, MobName="Yeti", QuestNpc=Vector3.new(1389.745,88.152,-1298.908), MobPosition=Vector3.new(1313.000,26.000,-4641.000)},
    {MinLevel=130, MaxLevel=149, QuestName="MarineQuest2", QuestNumber=2, MobName="Vice Admiral", QuestNpc=Vector3.new(-5039.586,27.350,4324.680), MobPosition=Vector3.new(-5036.000,24.000,4317.000)},
    {MinLevel=175, MaxLevel=199, QuestName="PrisonerQuest", QuestNumber=3, MobName="Warden", QuestNpc=Vector3.new(5308.931,1.655,475.121), MobPosition=Vector3.new(4875.000,5.000,735.000)},
    {MinLevel=200, MaxLevel=224, QuestName="ImpelQuest", QuestNumber=1, MobName="Chief Warden", QuestNpc=Vector3.new(5308.931,1.655,475.121), MobPosition=Vector3.new(5060.000,5.000,890.000)},
    {MinLevel=225, MaxLevel=249, QuestName="ImpelQuest", QuestNumber=2, MobName="Swan", QuestNpc=Vector3.new(5308.931,1.655,475.121), MobPosition=Vector3.new(-1516.000,7.000,-2994.000)},
    {MinLevel=350, MaxLevel=374, QuestName="MagmaQuest", QuestNumber=3, MobName="Magma Admiral", QuestNpc=Vector3.new(-5313.370,10.950,8515.294), MobPosition=Vector3.new(-5400.000,8.000,8500.000)},
    {MinLevel=425, MaxLevel=449, QuestName="FishmanQuest", QuestNumber=3, MobName="Fishman Lord", QuestNpc=Vector3.new(61122.652,18.497,1569.400), MobPosition=Vector3.new(61163.000,11.000,1819.000), Entrance=Vector3.new(61163.852,11.680,1819.785)},
    {MinLevel=500, MaxLevel=524, QuestName="SkyExp1Quest", QuestNumber=3, MobName="Wysper", QuestNpc=Vector3.new(-7859.098,5544.190,-381.476), MobPosition=Vector3.new(-4720.000,845.000,-1950.000), Entrance=Vector3.new(-7894.618,5547.142,-380.291)},
    {MinLevel=575, MaxLevel=624, QuestName="SkyExp2Quest", QuestNumber=3, MobName="Thunder God", QuestNpc=Vector3.new(-7906.816,5634.663,-1411.992), MobPosition=Vector3.new(-7800.000,5600.000,-1600.000), Entrance=Vector3.new(-7894.618,5547.142,-380.291)},
    {MinLevel=675, MaxLevel=699, QuestName="FountainQuest", QuestNumber=3, MobName="Cyborg", QuestNpc=Vector3.new(5259.820,37.350,4050.029), MobPosition=Vector3.new(5600.000,5.000,4400.000)},
}

local BossQuestsSea2 = {
    {MinLevel=750, MaxLevel=774, QuestName="Area1Quest", QuestNumber=3, MobName="Diamond", QuestNpc=Vector3.new(-429.544,71.770,1836.182), MobPosition=Vector3.new(-432.000,73.000,299.000)},
    {MinLevel=850, MaxLevel=874, QuestName="Area2Quest", QuestNumber=3, MobName="Jeremy", QuestNpc=Vector3.new(638.438,71.770,918.283), MobPosition=Vector3.new(-5465.000,87.000,-782.000)},
    {MinLevel=925, MaxLevel=949, QuestName="MarineQuest3", QuestNumber=3, MobName="Fajita", QuestNpc=Vector3.new(-2440.796,71.714,-3216.068), MobPosition=Vector3.new(-5700.000,15.000,-3050.000)},
    {MinLevel=1000, MaxLevel=1049, QuestName="SnowMountainQuest", QuestNumber=3, MobName="Don Swan", QuestNpc=Vector3.new(609.859,400.120,-5372.259), MobPosition=Vector3.new(-456.000,10.000,-1867.000)},
    {MinLevel=1150, MaxLevel=1174, QuestName="IceSideQuest", QuestNumber=3, MobName="Smoke Admiral", QuestNpc=Vector3.new(-6064.069,15.242,-4902.979), MobPosition=Vector3.new(-5700.000,15.000,-3050.000)},
    {MinLevel=1250, MaxLevel=1274, QuestName="FireSideQuest", QuestNumber=3, MobName="Magma Admiral", QuestNpc=Vector3.new(-5428.032,15.062,-5299.435), MobPosition=Vector3.new(-5700.000,15.000,-3050.000)},
    {MinLevel=1400, MaxLevel=1424, QuestName="FrostQuest", QuestNumber=3, MobName="Awakened Ice Admiral", QuestNpc=Vector3.new(5667.658,26.800,-6486.090), MobPosition=Vector3.new(6400.000,340.000,-6890.000)},
    {MinLevel=1475, MaxLevel=1499, QuestName="ForgottenQuest", QuestNumber=3, MobName="Tide Keeper", QuestNpc=Vector3.new(-3054.445,235.544,-10142.819), MobPosition=Vector3.new(-3570.000,123.000,-11556.000)},
}

local BossQuestsSea3 = {
    {MinLevel=1550, MaxLevel=1574, QuestName="PiratePortQuest", QuestNumber=3, MobName="Stone", QuestNpc=Vector3.new(-290.075,42.903,5581.590), MobPosition=Vector3.new(-1085.000,40.000,6779.000)},
    {MinLevel=1675, MaxLevel=1699, QuestName="AmazonQuest2", QuestNumber=3, MobName="Island Empress", QuestNpc=Vector3.new(5448.861,601.532,751.114), MobPosition=Vector3.new(5659.000,602.000,244.000)},
    {MinLevel=1750, MaxLevel=1774, QuestName="MarineTreeIsland", QuestNumber=3, MobName="Kilo Admiral", QuestNpc=Vector3.new(2180.541,27.816,-6741.550), MobPosition=Vector3.new(2846.000,433.000,-7100.000)},
    {MinLevel=1875, MaxLevel=1899, QuestName="DeepForestIsland", QuestNumber=3, MobName="Captain Elephant", QuestNpc=Vector3.new(-13234.040,331.488,-7625.401), MobPosition=Vector3.new(-13221.000,325.000,-8405.000)},
    {MinLevel=1950, MaxLevel=1974, QuestName="DeepForestIsland2", QuestNumber=3, MobName="Beautiful Pirate", QuestNpc=Vector3.new(-12680.382,389.971,-9902.020), MobPosition=Vector3.new(5182.000,23.000,-20.000)},
    {MinLevel=2175, MaxLevel=2199, QuestName="IceCreamIslandQuest", QuestNumber=3, MobName="Cake Queen", QuestNpc=Vector3.new(-820.648,65.820,-10965.796), MobPosition=Vector3.new(-821.000,66.000,-10965.000)},
}

local findBoss
local function getAvailableBossQuest(level)
    local bossTable
    if WorldSea == 1 then bossTable = BossQuestsSea1
    elseif WorldSea == 2 then bossTable = BossQuestsSea2
    elseif WorldSea == 3 then bossTable = BossQuestsSea3
    else bossTable = BossQuestsSea1
    end

    for _, bossQuest in ipairs(bossTable) do
        if level >= bossQuest.MinLevel and level <= bossQuest.MaxLevel then
            local bossMob = findBoss(bossQuest.MobName)
            if bossMob then
                return bossQuest, bossMob
            end
        end
    end
    return nil, nil
end
-- ==================== BOSS DATA ====================
local BossesSea1 = {
    {Name="Gorilla King",     Level=25,   Position=Vector3.new(-1243,6,-493)},
    {Name="Bobby",            Level=55,   Position=Vector3.new(-1145,14,4300)},
    {Name="Yeti",             Level=110,  Position=Vector3.new(1313,26,-4641)},
    {Name="Vice Admiral",     Level=130,  Position=Vector3.new(-5036,24,4317)},
    {Name="Warden",           Level=175,  Position=Vector3.new(4875,5,735)},
    {Name="Chief Warden",     Level=200,  Position=Vector3.new(5060,5,890)},
    {Name="Swan",             Level=225,  Position=Vector3.new(-1516,7,-2994)},
    {Name="Magma Admiral",    Level=350,  Position=Vector3.new(-5400,8,8500)},
    {Name="Fishman Lord",     Level=425,  Position=Vector3.new(61163,11,1819)},
    {Name="Wysper",           Level=500,  Position=Vector3.new(-4720,845,-1950)},
    {Name="Thunder God",      Level=575,  Position=Vector3.new(-7800,5600,-1600)},
    {Name="Cyborg",           Level=675,  Position=Vector3.new(5600,5,4400)},
}
local BossesSea2 = {
    {Name="Diamond",          Level=750,  Position=Vector3.new(-432,73,299)},
    {Name="Jeremy",           Level=850,  Position=Vector3.new(-5465,87,-782)},
    {Name="Fajita",           Level=925,  Position=Vector3.new(-5700,15,-3050)},
    {Name="Don Swan",         Level=1000, Position=Vector3.new(-456,10,-1867)},
    {Name="Smoke Admiral",    Level=1150, Position=Vector3.new(-5700,15,-3050)},
    {Name="Tide Keeper",      Level=1475, Position=Vector3.new(-3570,123,-11556)},
    {Name="Darkbeard",        Level=1000, Position=Vector3.new(3876,25,-3820)},
    {Name="Order",            Level=1250, Position=Vector3.new(-6221,16,-5045)},
    {Name="Cursed Captain",   Level=1325, Position=Vector3.new(917,181,33422)},
    {Name="Awakened Ice Admiral", Level=1400, Position=Vector3.new(6400,340,-6890)},
}
local BossesSea3 = {
    {Name="Stone",            Level=1550, Position=Vector3.new(-1085,40,6779)},
    {Name="Island Empress",   Level=1675, Position=Vector3.new(5659,602,244)},
    {Name="Kilo Admiral",     Level=1750, Position=Vector3.new(2846,433,-7100)},
    {Name="Captain Elephant", Level=1875, Position=Vector3.new(-13221,325,-8405)},
    {Name="Beautiful Pirate", Level=1950, Position=Vector3.new(5182,23,-20)},
    {Name="Longma",           Level=2000, Position=Vector3.new(-10248,354,-9306)},
    {Name="Soul Reaper",      Level=2100, Position=Vector3.new(-9516,316,6691)},
    {Name="Cake Queen",       Level=2175, Position=Vector3.new(-821,66,-10965)},
    {Name="rip_indra True Form", Level=5000, Position=Vector3.new(-5359,424,-2735)},
}

-- ==================== RAID CHIPS ====================
local RaidChips = {
    "Flame", "Ice", "Sand", "Dark", "Light", "Magma",
    "Quake", "Buddha", "Spider", "Rumble", "Phoenix", "Dough"
}

-- ==================== NPC QUAN TRỌNG ====================
local ImportantNPCs = {}
if WorldSea == 1 then
    ImportantNPCs = {
        {Name="Blox Fruit Dealer",      Position=Vector3.new(-70,15,30)},
        {Name="Sword Dealer",           Position=Vector3.new(-259,16,324)},
        {Name="Ability Teacher",        Position=Vector3.new(-1578,18,-42)},
        {Name="Boat Dealer",            Position=Vector3.new(1071,15,1518)},
        {Name="Luxury Boat Dealer",     Position=Vector3.new(-1542,29,144)},
        {Name="Advanced Weapon Dealer", Position=Vector3.new(-6880,14,-516)},
    }
elseif WorldSea == 2 then
    ImportantNPCs = {
        {Name="Blox Fruit Dealer",      Position=Vector3.new(-438,73,286)},
        {Name="Sword Dealer",           Position=Vector3.new(-400,73,300)},
        {Name="Ability Teacher",        Position=Vector3.new(-380,73,310)},
        {Name="Mysterious Man",         Position=Vector3.new(-1413,14,-11)},
        {Name="Awakening Expert",       Position=Vector3.new(-465,10,-1867)},
    }
elseif WorldSea == 3 then
    ImportantNPCs = {
        {Name="Blox Fruit Dealer",      Position=Vector3.new(-290,42,5370)},
        {Name="Advanced Weapon Dealer", Position=Vector3.new(-310,42,5380)},
    }
end

------------------------------------------------------------
