--[[
    ================================================================================
    ⚡ HAOTOOL | BLOX FRUITS V2.0 — ULTIMATE EDITION
    --------------------------------------------------------------------------------
    Developer   : HAOTOOL Team
    UI Library  : Fluent (Dark Theme)
    Tương thích : Delta, Solara, Wave, Fluxus, Codex
    Ẩn/Hiện GUI : Phím RightControl
    ================================================================================
    LƯU Ý:
    • Không dùng VirtualUser:CaptureController() (gây đơ GUI)
    • Tất cả remote đều bọc pcall để an toàn
    • Mỗi chức năng chạy trong task.spawn riêng, crash 1 cái không ảnh hưởng cái khác
    ================================================================================
--]]

------------------------------------------------------------
-- PHẦN 1: KHỞI TẠO & SERVICES
------------------------------------------------------------

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

-- Services chính
local Players             = game:GetService("Players")
local Player              = Players.LocalPlayer
local TweenService        = game:GetService("TweenService")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local VirtualUser         = game:GetService("VirtualUser")
local Lighting            = game:GetService("Lighting")
local Workspace           = game:GetService("Workspace")

-- Character tracking
local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(char)
    Character = char
    task.wait(0.5) -- Đợi character load xong
end)

-- Nhận diện Sea hiện tại dựa trên PlaceId
local PlaceId = game.PlaceId
local WorldSea = 1
if PlaceId == 2753915549 then WorldSea = 1
elseif PlaceId == 4442272183 then WorldSea = 2
elseif PlaceId == 7449423635 then WorldSea = 3
end

------------------------------------------------------------
-- PHẦN 1.5: LOAD FLUENT UI LIBRARY
------------------------------------------------------------

local Fluent, SaveManager, InterfaceManager

local ok1, err1 = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not ok1 then
    warn("[HAOTOOL] Không load được Fluent: " .. tostring(err1))
    -- Fallback: thử Rayfield nếu Fluent lỗi
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if not Fluent then return end
end

pcall(function()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)
pcall(function()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

------------------------------------------------------------
-- PHẦN 2: BIẾN CẤU HÌNH TOÀN CỤC
------------------------------------------------------------

-- Farm
_G.AutoFarmLevel     = false
_G.AutoFarmMastery   = false
_G.MasteryWeapon     = "Melee"
_G.AutoFarmBoss      = false
_G.SelectedBoss      = ""
_G.AutoFarmSeaBeast  = false
_G.AutoFarmObs       = false
_G.AutoFarmBone      = false
_G.AutoFarmFragment  = false
_G.SelectWeapon      = "Melee"
_G.FarmMethod        = "Quest"
_G.SelectedMob       = ""
_G.BringMob          = true
_G.BringRadius       = 300
_G.FarmHeight        = 8
_G.FarmDistance      = 0
_G.HoldFarmPosition  = true
_G.FreezeTarget      = true
_G.AttackDelay       = 0.08
_G.HitboxSize        = 12
_G.AutoSkill         = false
_G.SkillCooldown     = 1.5

-- Raid
_G.AutoRaid          = false
_G.AutoRaidFarm      = false
_G.AutoAwakening     = false
_G.RaidChip          = "Flame"

-- Fruit
_G.AutoFruitFinder   = false
_G.AutoCollectFruit  = false
_G.FruitESP          = false
_G.AutoGachaFruit    = false

-- ESP
_G.ESPPlayer         = false
_G.ESPMob            = false
_G.ESPBoss           = false
_G.ESPChest          = false
_G.ESPFlower         = false
_G.ESPIsland         = false
_G.ESPDistance        = 2000
_G.ESPPlayerColor    = Color3.fromRGB(0, 170, 255)
_G.ESPMobColor       = Color3.fromRGB(255, 85, 85)
_G.ESPBossColor      = Color3.fromRGB(255, 170, 0)
_G.ESPFruitColor     = Color3.fromRGB(170, 0, 255)
_G.ESPChestColor     = Color3.fromRGB(255, 255, 0)
_G.ESPFlowerColor    = Color3.fromRGB(255, 100, 200)
_G.ESPTeamCheck      = true

-- Combat
_G.AutoHaki          = true
_G.AutoKen           = false
_G.AutoObsV2         = false
_G.AutoDodge         = false

-- Misc
_G.WalkSpeedHack     = false
_G.WalkSpeedVal      = 50
_G.JumpPowerHack     = false
_G.JumpPowerVal      = 100
_G.InfiniteJump      = false
_G.InfiniteEnergy    = false
_G.AntiAFK           = true
_G.AutoStats         = false
_G.StatToUpgrade     = "Melee"
_G.FPSBoost          = false
_G.ServerHop         = false
_G.ServerHopNoFruit  = false

-- Teleport
_G.SelectedIsland    = ""

------------------------------------------------------------
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
    {Name="Tide Keeper",      Level=1475, Position=Vector3.new(-3053,236,-10197)},
    {Name="Cake Queen",       Level=1500, Position=Vector3.new(-856,8,-11221)},
}
local BossesSea3 = {
    {Name="Stone",            Level=1550, Position=Vector3.new(-290,42,5358)},
    {Name="Island Empress",   Level=1675, Position=Vector3.new(5229,15,353)},
    {Name="Kilo Admiral",     Level=1750, Position=Vector3.new(2575,1190,-680)},
    {Name="Captain Elephant", Level=1875, Position=Vector3.new(-12142,332,-3820)},
    {Name="Beautiful Pirate", Level=2000, Position=Vector3.new(-12104,54,-5765)},
    {Name="Cake Queen",       Level=2175, Position=Vector3.new(-5044,314,-2812)},
}

-- ==================== RAID CHIPS ====================
local RaidChips = {
    "Flame", "Ice", "Quake", "Light", "Dark", "String",
    "Magma", "Rumble", "Buddha", "Sand", "Phoenix",
    "Dough", "Sound", "Venom", "Control", "Spirit",
    "Dragon", "Leopard", "T-Rex", "Mammoth"
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
-- PHẦN 4: HÀM CỐT LÕI (CORE FUNCTIONS)
------------------------------------------------------------

-- ====== Noclip ======
local noclipConn = nil
local function setNoclip(state)
    if state then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                pcall(function()
                    local char = Player.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end)
        end
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
    end
end

-- ====== Trạng thái farm: tách di chuyển và chiến đấu ======
local currentTween = nil
local activeFarmTarget = nil
local farmState = "idle"
local lastAttackTime = 0
local restoreFrozenMobs = function() end

local function clearFarmTarget()
    activeFarmTarget = nil
    if farmState == "attacking" then farmState = "idle" end

    local char = Player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function stopFarmMovement()
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    clearFarmTarget()
    restoreFrozenMobs()
    farmState = "idle"
    setNoclip(false)
end

local function getFarmCFrame(targetRoot)
    local height = tonumber(_G.FarmHeight) or 8
    local distance = tonumber(_G.FarmDistance) or 0
    return targetRoot.CFrame * CFrame.new(0, height, distance)
end

local function holdFarmTarget(target)
    if not target or not target.Parent then
        clearFarmTarget()
        return
    end

    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end

    activeFarmTarget = target
    farmState = "attacking"
    setNoclip(true)
end

-- Giữ nhân vật đứng yên tương đối với quái; không chạy/chase trong lúc đánh.
RunService.Heartbeat:Connect(function()
    pcall(function()
        if farmState ~= "attacking" or not activeFarmTarget then return end
        if not _G.HoldFarmPosition then return end
        if not activeFarmTarget.Parent then
            clearFarmTarget()
            return
        end

        local targetHumanoid = activeFarmTarget:FindFirstChildOfClass("Humanoid")
        local targetRoot = activeFarmTarget:FindFirstChild("HumanoidRootPart")
        local char = Player.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot
            or not rootPart or not humanoid then
            clearFarmTarget()
            return
        end

        rootPart.CFrame = getFarmCFrame(targetRoot)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        humanoid.AutoRotate = false
        humanoid:Move(Vector3.zero, false)
    end)
end)

-- ====== Bay tới mục tiêu (Tween), tự hủy khi chuyển sang đánh ======
local function toTarget(targetCFrame)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    clearFarmTarget()
    farmState = "moving"

    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end

    local rootPart = char.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude

    if distance < 15 then
        rootPart.CFrame = targetCFrame
        rootPart.AssemblyLinearVelocity = Vector3.zero
        farmState = "idle"
        return true
    end

    local speed = 300
    setNoclip(true)
    currentTween = TweenService:Create(
        rootPart,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    currentTween:Play()
    currentTween.Completed:Wait()
    currentTween = nil

    if farmState == "moving" then farmState = "idle" end
    setNoclip(false)

    return (rootPart.Position - targetCFrame.Position).Magnitude <= 25
end

-- ====== Haki (Buso & Ken) ======
local function checkHaki()
    pcall(function()
        local char = Player.Character
        if not char then return end

        if _G.AutoHaki and not char:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end

        if _G.AutoKen and not char:FindFirstChild("HasKen") then
            local ken = ReplicatedStorage.Remotes:FindFirstChild("Ken")
            if ken then ken:FireServer(true) end
        end

        if _G.AutoObsV2 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Observation")
        end
    end)
end

-- Tool:Activate kết hợp click ảo để tương thích nhiều executor hơn.
local function attack()
    local now = tick()
    local delay = math.max(0.03, tonumber(_G.AttackDelay) or 0.08)
    if now - lastAttackTime < delay then return end
    lastAttackTime = now

    checkHaki()

    local char = Player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end

    pcall(function() tool:Activate() end)
    pcall(function()
        local input = game:GetService("VirtualInputManager")
        input:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.02)
        input:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end
-- ====== Auto Skill (dùng Z, X, C, V) ======
local lastSkillTime = 0
local function useSkills()
    if not _G.AutoSkill then return end
    if tick() - lastSkillTime < _G.SkillCooldown then return end

    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
        for _, key in ipairs(keys) do
            VIM:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, key, false, game)
            task.wait(0.15)
        end
        lastSkillTime = tick()
    end)
end

-- ====== Trang bị vũ khí theo loại ======
local function equipWeapon(weaponType)
    pcall(function()
        local backpack = Player.Backpack
        local char = Player.Character
        if not char or not char:FindFirstChild("Humanoid") then return end

        -- Kiểm tra đã trang bị đúng loại chưa
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped then
            if weaponType == "Melee" and (table.find(MeleeNames, equipped.Name) or equipped.ToolTip == "Melee") then return end
            if weaponType == "Sword" and (table.find(SwordNames, equipped.Name) or equipped.ToolTip == "Sword") then return end
            if weaponType == "Gun" and (table.find(GunNames, equipped.Name) or equipped.ToolTip == "Gun") then return end
            if weaponType == "Blox Fruit" and (equipped.ToolTip == "Blox Fruit" or equipped.Name:find("Fruit")) then return end
        end

        -- Tìm và trang bị vũ khí phù hợp
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local match = false
                if weaponType == "Melee" and (table.find(MeleeNames, tool.Name) or tool.ToolTip == "Melee") then match = true end
                if weaponType == "Sword" and (table.find(SwordNames, tool.Name) or tool.ToolTip == "Sword") then match = true end
                if weaponType == "Gun" and (table.find(GunNames, tool.Name) or tool.ToolTip == "Gun") then match = true end
                if weaponType == "Blox Fruit" and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit")) then match = true end
                if match then
                    char.Humanoid:EquipTool(tool)
                    return
                end
            end
        end

        -- Nếu không tìm thấy, trang bị tool đầu tiên
        local fallback = backpack:FindFirstChildOfClass("Tool")
        if fallback then char.Humanoid:EquipTool(fallback) end
    end)
end

-- Tên model có thể là "Monkey" hoặc "Monkey [Lv. 14]".
local function mobNameMatches(actualName, wantedName)
    if not actualName or not wantedName or wantedName == "" then return false end

    local actual = string.lower(tostring(actualName))
    local wanted = string.lower(tostring(wantedName))

    if actual == wanted then return true end
    if string.find(actual, wanted, 1, true) then return true end

    actual = actual:gsub("%s*%[lv%.?%s*%d+%]%s*", "")
    actual = actual:gsub("%s*%[boss%]%s*", "")
    actual = actual:gsub("^the%s+", "")
    actual = actual:gsub("%s+$", "")

    wanted = wanted:gsub("%s*%[lv%.?%s*%d+%]%s*", "")
    wanted = wanted:gsub("%s*%[boss%]%s*", "")
    wanted = wanted:gsub("^the%s+", "")
    wanted = wanted:gsub("%s+$", "")

    return actual == wanted or string.find(actual, wanted, 1, true) ~= nil
end


-- ====== Khóa và gom quái có thể hoàn nguyên ======
local frozenMobStates = setmetatable({}, {__mode = "k"})

local function grantSimulationRadius()
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Player, "SimulationRadius", math.huge)
        elseif setsimulationradius then
            setsimulationradius(math.huge, math.huge)
        end
    end)
end

local function freezeMob(mob)
    if not mob or not mob.Parent then return end

    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    local rootPart = mob:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end

    if not frozenMobStates[mob] then
        frozenMobStates[mob] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            AutoRotate = humanoid.AutoRotate,
            CanCollide = rootPart.CanCollide,
            Size = rootPart.Size,
        }
    end

    rootPart.CanCollide = false
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    local hitboxSize = math.clamp(tonumber(_G.HitboxSize) or 12, 2, 40)
    rootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)

    if _G.FreezeTarget then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    end
end

restoreFrozenMobs = function()
    for mob, state in pairs(frozenMobStates) do
        pcall(function()
            if mob and mob.Parent then
                local humanoid = mob:FindFirstChildOfClass("Humanoid")
                local rootPart = mob:FindFirstChild("HumanoidRootPart")
                if humanoid then
                    humanoid.WalkSpeed = state.WalkSpeed
                    humanoid.JumpPower = state.JumpPower
                    humanoid.AutoRotate = state.AutoRotate
                end
                if rootPart then
                    rootPart.CanCollide = state.CanCollide
                    rootPart.Size = state.Size
                end
            end
        end)
        frozenMobStates[mob] = nil
    end
end

local function bringMobsNear(targetName, centerCFrame)
    if not _G.BringMob then return end

    pcall(function()
        if not workspace:FindFirstChild("Enemies") then return end
        grantSimulationRadius()

        local radius = math.clamp(tonumber(_G.BringRadius) or 300, 50, 1000)
        for _, mob in pairs(workspace.Enemies:GetChildren()) do
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            local rootPart = mob:FindFirstChild("HumanoidRootPart")

            if mobNameMatches(mob.Name, targetName)
                and humanoid and humanoid.Health > 0 and rootPart then
                local distance = (rootPart.Position - centerCFrame.Position).Magnitude
                if distance <= radius then
                    freezeMob(mob)
                    rootPart.CFrame = centerCFrame
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function engageTarget(target, targetName, weaponType)
    if not target or not target.Parent then
        clearFarmTarget()
        return false
    end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not targetRoot then
        clearFarmTarget()
        return false
    end

    holdFarmTarget(target)
    grantSimulationRadius()
    freezeMob(target)
    bringMobsNear(targetName or target.Name, targetRoot.CFrame)

    equipWeapon(weaponType or _G.SelectWeapon)
    attack()
    useSkills()
    return true
end
-- ====== Lấy quest phù hợp level ======
local function getQuestData(level)
    local questTable
    if WorldSea == 1 then questTable = QuestsSea1
    elseif WorldSea == 2 then questTable = QuestsSea2
    elseif WorldSea == 3 then questTable = QuestsSea3
    else questTable = QuestsSea1
    end

    for _, data in ipairs(questTable) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    -- Fallback: trả về quest cuối cùng nếu quá level
    return questTable[#questTable]
end

-- ====== Kiểm tra quest đang hoạt động ======
local function hasActiveQuest()
    local mainGui = Player.PlayerGui:FindFirstChild("Main")
    local questGui = mainGui and mainGui:FindFirstChild("Quest")
    return questGui ~= nil and questGui.Visible == true
end

local lastSubmergedTravel = 0
local lastQuestWarning = 0

local function ensureQuestArea(quest)
    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    if quest.Travel == "Submerged" and rootPart.Position.Y > -1000 then
        if tick() - lastSubmergedTravel < 8 then return false end
        lastSubmergedTravel = tick()

        toTarget(CFrame.new(-16269.704, 25.229, 1373.660))
        task.wait(1)

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local submarineRemote = remotes and remotes:FindFirstChild("RF/SubmarineWorkerSpeak")
        if submarineRemote then
            pcall(function()
                submarineRemote:InvokeServer("TravelToSubmergedIsland")
            end)
            task.wait(5)
        else
            warn("[HAOTOOL] Không tìm thấy remote đi Submerged Island.")
            return false
        end
    elseif quest.Entrance
        and (rootPart.Position - quest.QuestNpc).Magnitude > 3000 then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", quest.Entrance)
        end)
        task.wait(1)
    end

    return true
end

local function startQuest(quest)
    clearFarmTarget()
    if not ensureQuestArea(quest) then return false end

    if not toTarget(CFrame.new(quest.QuestNpc)) then return false end
    if not _G.AutoFarmLevel then return false end

    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart or (rootPart.Position - quest.QuestNpc).Magnitude > 30 then
        return false
    end

    for _ = 1, 3 do
        if not _G.AutoFarmLevel then return false end
        if hasActiveQuest() then return true end

        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer(
                "StartQuest", quest.QuestName, quest.QuestNumber
            )
        end)

        task.wait(0.7)
    end

    if not hasActiveQuest() and tick() - lastQuestWarning > 8 then
        lastQuestWarning = tick()
        warn(string.format(
            "[HAOTOOL] Nhận quest thất bại: %s #%s",
            tostring(quest.QuestName),
            tostring(quest.QuestNumber)
        ))
    end

    return hasActiveQuest()
end

-- ====== Tìm quái theo tên (gần nhất) ======
local function findMob(mobName, useNearest)
    if not workspace:FindFirstChild("Enemies") then return nil end
    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")

    local closest = nil
    local closestDist = math.huge

    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
            and mob:FindFirstChild("HumanoidRootPart") then

            local nameMatch = (mobName == "" or mobName == nil or mobNameMatches(mob.Name, mobName))
            if useNearest then nameMatch = true end

            if nameMatch then
                if rootPart then
                    local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = mob
                    end
                else
                    closest = mob
                    break
                end
            end
        end
    end
    return closest
end

-- ====== Tìm boss ======
local function findBoss(bossName)
    if not workspace:FindFirstChild("Enemies") then return nil end
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mobNameMatches(mob.Name, bossName)
            and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
            and mob:FindFirstChild("HumanoidRootPart") then
            return mob
        end
    end
    return nil
end

-- ====== Lấy danh sách quái hiện có ======
local function getEnemyList()
    local enemies = {}
    pcall(function()
        if workspace:FindFirstChild("Enemies") then
            for _, mob in pairs(workspace.Enemies:GetChildren()) do
                if mob:FindFirstChild("Humanoid") and not table.find(enemies, mob.Name) then
                    table.insert(enemies, mob.Name)
                end
            end
        end
    end)
    if #enemies == 0 then
        return {"(Không có quái)"}
    end
    table.sort(enemies)
    return enemies
end

-- ====== Lấy danh sách boss theo Sea ======
local function getBossList()
    local bosses = {}
    local bossTable
    if WorldSea == 1 then bossTable = BossesSea1
    elseif WorldSea == 2 then bossTable = BossesSea2
    elseif WorldSea == 3 then bossTable = BossesSea3
    else bossTable = BossesSea1
    end
    for _, b in ipairs(bossTable) do
        table.insert(bosses, b.Name)
    end
    return bosses
end

-- ====== Tìm boss data theo tên ======
local function getBossData(bossName)
    local tables = {BossesSea1, BossesSea2, BossesSea3}
    local idx = math.clamp(WorldSea, 1, 3)
    for _, b in ipairs(tables[idx]) do
        if b.Name == bossName then return b end
    end
    return nil
end

-- ====== Server Hop ======
local function serverHop()
    pcall(function()
        local servers = {}
        local req = game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        )
        local data = game:GetService("HttpService"):JSONDecode(req)
        if data and data.data then
            for _, sv in ipairs(data.data) do
                if sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                    table.insert(servers, sv.id)
                end
            end
        end
        if #servers > 0 then
            local chosen = servers[math.random(1, #servers)]
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, chosen, Player)
        end
    end)
end

-- ====== Notify helper ======
local function notify(title, content, duration)
    pcall(function()
        Fluent:Notify({
            Title = title or "HAOTOOL",
            Content = content or "",
            Duration = duration or 4,
        })
    end)
end

------------------------------------------------------------
-- PHẦN 5: HỆ THỐNG ESP
------------------------------------------------------------

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "HAOTOOL_ESP"
ESPFolder.Parent = game:GetService("CoreGui")

-- Tạo ESP cho 1 đối tượng
local function createESP(target, color, text, parent)
    if not target then return end
    local adornee = target:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("Handle")
        or (target:IsA("BasePart") and target)
    if not adornee then return end

    -- Kiểm tra đã có ESP chưa
    local existingTag = "HAOTOOL_" .. target:GetFullName()
    if ESPFolder:FindFirstChild(existingTag) then return end

    -- Highlight
    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = existingTag .. "_HL"
        highlight.FillColor = color
        highlight.FillTransparency = 0.6
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.3
        highlight.Adornee = target
        highlight.Parent = ESPFolder
    end)

    -- BillboardGui
    pcall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Name = existingTag
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = adornee
        billboard.Parent = ESPFolder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = false
        label.TextSize = 14
        label.Parent = billboard
    end)
end

-- Xóa tất cả ESP
local function clearAllESP()
    pcall(function()
        for _, child in pairs(ESPFolder:GetChildren()) do
            child:Destroy()
        end
    end)
end

-- Xóa ESP theo loại (prefix)
local function clearESPByPrefix(prefix)
    pcall(function()
        for _, child in pairs(ESPFolder:GetChildren()) do
            if child.Name:find(prefix) then
                child:Destroy()
            end
        end
    end)
end

-- Cập nhật khoảng cách trên ESP
local function updateESPDistance(billboard, adornee)
    pcall(function()
        local char = Player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        if not adornee or not adornee.Parent then
            billboard:Destroy()
            return
        end
        local dist = math.floor((char.HumanoidRootPart.Position - adornee.Position).Magnitude)
        local label = billboard:FindFirstChildOfClass("TextLabel")
        if label and label.Text then
            -- Cập nhật khoảng cách trong text
            local baseName = label.Text:match("^(.-)%s*%[") or label.Text
            label.Text = baseName .. " [" .. dist .. "m]"
        end
    end)
end

------------------------------------------------------------
-- PHẦN 6: VÒNG LẶP NỀN (BACKGROUND LOOPS)
------------------------------------------------------------

-- ====== LOOP 1: Auto Farm Level ======
task.spawn(function()
    while true do
        task.wait(0.10)

        if _G.AutoFarmLevel then
            pcall(function()
                local level = Player.Data.Level.Value
                local quest = getQuestData(level)
                if not quest then return end

                if not hasActiveQuest() then
                    startQuest(quest)
                    return
                end

                local targetMob = nil
                if _G.FarmMethod == "Quest" then
                    targetMob = findMob(quest.MobName, false)
                elseif _G.FarmMethod == "Nearest" then
                    targetMob = findMob("", true)
                elseif _G.FarmMethod == "Selected Mob" then
                    targetMob = findMob(_G.SelectedMob, false)
                else
                    targetMob = findMob(quest.MobName, false)
                end

                if not targetMob then
                    clearFarmTarget()
                    if ensureQuestArea(quest) then
                        toTarget(CFrame.new(quest.MobPosition))
                    end
                    return
                end

                local bringName = quest.MobName
                if _G.FarmMethod == "Nearest" then
                    bringName = targetMob.Name
                elseif _G.FarmMethod == "Selected Mob" then
                    bringName = _G.SelectedMob
                end

                engageTarget(targetMob, bringName, _G.SelectWeapon)
            end)
        end
    end
end)
-- ====== LOOP 2: Auto Farm Mastery ======
task.spawn(function()
    while true do
        task.wait(0.10)

        if _G.AutoFarmMastery and not _G.AutoFarmLevel and not _G.AutoFarmBoss then
            pcall(function()
                local targetMob = findMob("", true)
                if targetMob then
                    engageTarget(targetMob, targetMob.Name, _G.MasteryWeapon)
                else
                    clearFarmTarget()
                end
            end)
        end
    end
end)
-- ====== LOOP 3: Auto Farm Boss ======
task.spawn(function()
    while true do
        task.wait(0.10)

        if _G.AutoFarmBoss and not _G.AutoFarmLevel then
            pcall(function()
                local bossData = getBossData(_G.SelectedBoss)
                if not bossData then return end

                local boss = findBoss(_G.SelectedBoss)
                if boss then
                    engageTarget(boss, boss.Name, _G.SelectWeapon)
                else
                    clearFarmTarget()
                    toTarget(CFrame.new(bossData.Position))
                    task.wait(0.5)
                end
            end)
        end
    end
end)
-- ====== LOOP 4: Auto Farm Sea Beast ======
task.spawn(function()
    while true do
        task.wait(0.15)

        if _G.AutoFarmSeaBeast and not _G.AutoFarmLevel and not _G.AutoFarmBoss and not _G.AutoFarmMastery then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local rootPart = obj:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and rootPart
                        and (obj.Name:find("Sea Beast") or obj.Name:find("SeaBeast")) then
                        engageTarget(obj, obj.Name, _G.SelectWeapon)
                        return
                    end
                end
                clearFarmTarget()
            end)
        end
    end
end)

-- Chỉ hoàn nguyên vị trí/noclip khi không còn chế độ farm chiến đấu nào bật.
task.spawn(function()
    while true do
        task.wait(0.25)
        if not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmBoss and not _G.AutoFarmSeaBeast and not _G.AutoRaidFarm then
            if farmState ~= "idle" or activeFarmTarget or currentTween then
                stopFarmMovement()
            end
        end
    end
end)
-- ====== LOOP 5: Auto Farm Observation ======
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoFarmObs then
            pcall(function()
                -- Kích hoạt Observation liên tục để luyện
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Observation")
            end)
        end
    end
end)

-- ====== LOOP 6: Auto Farm Bone / Fragment ======
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoFarmBone or _G.AutoFarmFragment then
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local name = obj.Name:lower()
                        if (_G.AutoFarmBone and name:find("bone"))
                            or (_G.AutoFarmFragment and name:find("frag")) then
                            toTarget(obj.CFrame)
                            task.wait(0.3)
                            -- Thu thập
                            pcall(function()
                                obj:Destroy()
                            end)
                        end
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 7: Auto Fruit Finder & Collector ======
task.spawn(function()
    while true do
        task.wait(2)
        if _G.AutoFruitFinder or _G.AutoCollectFruit then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    local isFruit = false
                    if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                        isFruit = true
                    end
                    -- Kiểm tra thêm trong folder
                    if not isFruit and obj:IsA("Model") and obj.Name:find("Fruit") then
                        isFruit = true
                    end

                    if isFruit then
                        -- Tính khoảng cách
                        local fruitPos = obj:FindFirstChild("Handle") and obj.Handle.Position
                            or obj:GetModelCFrame() and obj:GetModelCFrame().Position
                            or Vector3.new(0,0,0)
                        local char = Player.Character
                        local dist = 0
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            dist = math.floor((char.HumanoidRootPart.Position - fruitPos).Magnitude)
                        end

                        -- Thông báo
                        if _G.AutoFruitFinder then
                            notify(
                                "🍎 Trái Ác Quỷ!",
                                "Phát hiện: " .. obj.Name .. " [" .. dist .. "m]",
                                6
                            )
                        end

                        -- Tự động nhặt
                        if _G.AutoCollectFruit and obj:FindFirstChild("Handle") then
                            toTarget(obj.Handle.CFrame)
                            task.wait(0.5)
                            -- Thử nhặt
                            pcall(function()
                                local char2 = Player.Character
                                if char2 and char2:FindFirstChild("Humanoid") then
                                    obj.Parent = char2
                                end
                            end)
                            task.wait(0.3)
                        end
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 8: Auto Raid ======
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoRaid then
            pcall(function()
                -- Kiểm tra đang trong raid chưa
                local inRaid = false
                pcall(function()
                    inRaid = Player.PlayerGui:FindFirstChild("Main")
                        and Player.PlayerGui.Main:FindFirstChild("RaidTimer")
                        and Player.PlayerGui.Main.RaidTimer.Visible
                end)

                if not inRaid then
                    -- Bắt đầu raid
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidStart", _G.RaidChip)
                    task.wait(3)
                else
                    -- Đang trong raid → farm quái raid
                    if _G.AutoRaidFarm and not _G.AutoFarmLevel
                        and not _G.AutoFarmBoss and not _G.AutoFarmMastery and not _G.AutoFarmSeaBeast then
                        local targetMob = findMob("", true)
                        if targetMob then
                            engageTarget(targetMob, targetMob.Name, _G.SelectWeapon)
                        else
                            clearFarmTarget()
                        end
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 9: Auto Awakening ======
task.spawn(function()
    while true do
        task.wait(5)
        if _G.AutoAwakening then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Awaken")
            end)
        end
    end
end)

-- ====== LOOP 10: Auto Stats ======
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoStats then
            pcall(function()
                local points = Player.Data.Points.Value
                if points > 0 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer(
                        "AddPoint", _G.StatToUpgrade, 3
                    )
                end
            end)
        end
    end
end)

-- ====== LOOP 11: Auto Farm Chest ======
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoFarmChest then
            pcall(function()
                local targetChest = nil
                local char = Player.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                local closestDist = math.huge

                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():find("chest") then
                        if rootPart then
                            local d = (obj.Position - rootPart.Position).Magnitude
                            if d < closestDist then
                                closestDist = d
                                targetChest = obj
                            end
                        else
                            targetChest = obj
                            break
                        end
                    end
                end

                if targetChest then
                    toTarget(targetChest.CFrame)
                    task.wait(0.3)
                end
            end)
        end
    end
end)

-- ====== LOOP 12: Auto Gacha Fruit ======
task.spawn(function()
    while true do
        task.wait(8)
        if _G.AutoGachaFruit then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
                notify("🎰 Gacha", "Đã mua Random Fruit!", 3)
            end)
        end
    end
end)

-- ====== LOOP 13: Speed / Jump / Energy ======
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local char = Player.Character
            if not char or not char:FindFirstChild("Humanoid") then return end
            local hum = char.Humanoid

            if _G.WalkSpeedHack then hum.WalkSpeed = _G.WalkSpeedVal end
            if _G.JumpPowerHack then hum.JumpPower = _G.JumpPowerVal end

            -- Infinite Energy
            if _G.InfiniteEnergy then
                pcall(function()
                    if Player.Character:FindFirstChild("Energy") then
                        Player.Character.Energy.Value = 5000
                    end
                end)
            end
        end)
    end)
end)

-- ====== LOOP 14: Infinite Jump ======
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        pcall(function()
            local char = Player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end
        end)
    end
end)

-- ====== LOOP 15: Anti-AFK ======
Player.Idled:Connect(function()
    if _G.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

-- ====== LOOP 16: ESP Update Loop ======
task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            local char = Player.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            -- ESP Player
            if _G.ESPPlayer then
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= Player and plr.Character
                        and plr.Character:FindFirstChild("HumanoidRootPart")
                        and plr.Character:FindFirstChild("Humanoid") then
                        -- Team check
                        if _G.ESPTeamCheck and plr.Team == Player.Team then
                            -- Cùng team, bỏ qua
                        else
                            local dist = (plr.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                            if dist <= _G.ESPDistance then
                                local hp = math.floor(plr.Character.Humanoid.Health)
                                createESP(plr.Character, _G.ESPPlayerColor,
                                    plr.Name .. " [HP:" .. hp .. "]", ESPFolder)
                            end
                        end
                    end
                end
            else
                clearESPByPrefix("HAOTOOL_Workspace.") -- Xóa ESP player cũ nếu tắt
            end

            -- ESP Mob & Boss
            if _G.ESPMob or _G.ESPBoss then
                if workspace:FindFirstChild("Enemies") then
                    for _, mob in pairs(workspace.Enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
                            and mob:FindFirstChild("HumanoidRootPart") then
                            local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude
                            if dist <= _G.ESPDistance then
                                -- Phân biệt Boss và Mob thường
                                local isBoss = mob.Humanoid.MaxHealth >= 10000
                                if isBoss and _G.ESPBoss then
                                    local hp = math.floor(mob.Humanoid.Health)
                                    createESP(mob, _G.ESPBossColor,
                                        "⭐ " .. mob.Name .. " [" .. hp .. "HP]", ESPFolder)
                                elseif not isBoss and _G.ESPMob then
                                    createESP(mob, _G.ESPMobColor, mob.Name, ESPFolder)
                                end
                            end
                        end
                    end
                end
            end

            -- ESP Fruit
            if _G.FruitESP then
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                        local handle = obj:FindFirstChild("Handle")
                        if handle then
                            local dist = (handle.Position - rootPart.Position).Magnitude
                            if dist <= _G.ESPDistance then
                                createESP(obj, _G.ESPFruitColor,
                                    "🍎 " .. obj.Name .. " [" .. math.floor(dist) .. "m]", ESPFolder)
                            end
                        end
                    end
                end
            end

            -- ESP Chest
            if _G.ESPChest then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():find("chest") then
                        local dist = (obj.Position - rootPart.Position).Magnitude
                        if dist <= _G.ESPDistance then
                            createESP(obj, _G.ESPChestColor,
                                "📦 Chest [" .. math.floor(dist) .. "m]", ESPFolder)
                        end
                    end
                end
            end

            -- ESP Flower
            if _G.ESPFlower then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("flower") or obj.Name:lower():find("flora")) then
                        local dist = (obj.Position - rootPart.Position).Magnitude
                        if dist <= _G.ESPDistance then
                            createESP(obj, _G.ESPFlowerColor,
                                "🌸 " .. obj.Name .. " [" .. math.floor(dist) .. "m]", ESPFolder)
                        end
                    end
                end
            end

            -- Xóa ESP cũ nếu tất cả đều tắt
            if not _G.ESPPlayer and not _G.ESPMob and not _G.ESPBoss
                and not _G.FruitESP and not _G.ESPChest and not _G.ESPFlower then
                clearAllESP()
            end

            -- Cập nhật khoảng cách
            for _, child in pairs(ESPFolder:GetChildren()) do
                if child:IsA("BillboardGui") and child.Adornee then
                    updateESPDistance(child, child.Adornee)
                end
            end
        end)
    end
end)

-- ====== LOOP 17: Auto Dodge ======
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoDodge then
            pcall(function()
                -- Dodge bằng cách nhấn đúp hướng di chuyển
                local char = Player.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    -- Kiểm tra nếu có đạn/đòn đánh đang bay tới
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("BasePart") and obj.Name:lower():find("projectile") then
                            local rootPart = char:FindFirstChild("HumanoidRootPart")
                            if rootPart then
                                local dist = (obj.Position - rootPart.Position).Magnitude
                                if dist < 30 then
                                    -- Dodge sang bên
                                    rootPart.CFrame = rootPart.CFrame * CFrame.new(10, 0, 0)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 18: Server Hop khi hết mob/trái ======
task.spawn(function()
    while true do
        task.wait(30)
        if _G.ServerHopNoFruit then
            pcall(function()
                -- Kiểm tra có trái trên map không
                local hasFruit = false
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and obj.Name:find("Fruit") then
                        hasFruit = true
                        break
                    end
                end
                if not hasFruit then
                    notify("🔄 Server Hop", "Không có trái, đang chuyển server...", 3)
                    task.wait(2)
                    serverHop()
                end
            end)
        end
    end
end)

-- ====== Sự kiện khi chết → thông báo + tiếp tục farm ======
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if _G.AutoFarmLevel or _G.AutoFarmMastery or _G.AutoFarmBoss then
        notify("💀 Đã Hồi Sinh", "Tiếp tục farm...", 3)
    end
end)

------------------------------------------------------------
-- PHẦN 7: GIAO DIỆN FLUENT — BỐ CỤC MODERN DASHBOARD
------------------------------------------------------------

local Window = Fluent:CreateWindow({
    Title    = "HAOTOOL  •  BLOX FRUITS",
    SubTitle = "Sea " .. WorldSea .. "  |  Control Center",
    TabWidth = 170,
    Size     = UDim2.fromOffset(720, 540),
    Acrylic  = true,
    Theme    = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl, -- Phím ẩn/hiện GUI
})

-- ==================== TAB 1: MAIN ====================
-- Tên tab ngắn, đồng nhất và ưu tiên tiếng Việt để dễ quét nhanh.
local MainTab = Window:AddTab({Title = "Tổng quan", Icon = "layout-dashboard"})

MainTab:AddParagraph({
    Title = "⚡  Xin chào, " .. Player.DisplayName,
    Content = "SEA  " .. WorldSea
        .. "    •    LEVEL  " .. tostring(pcall(function() return Player.Data.Level.Value end) and Player.Data.Level.Value or "?")
        .. "    •    BELI  " .. tostring(pcall(function() return Player.Data.Beli.Value end) and Player.Data.Beli.Value or "?")
        .. "\nServer  " .. game.JobId:sub(1, 8) .. "..."
        .. "\n\nRightControl  •  Ẩn / hiện bảng điều khiển"
})

local ServerSection = MainTab:AddSection("Kết nối máy chủ")

ServerSection:AddButton({
    Title = "Vào lại máy chủ",
    Description = "Kết nối lại đúng máy chủ hiện tại.",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
        end)
    end
})

ServerSection:AddButton({
    Title = "Tìm máy chủ mới",
    Description = "Chuyển sang một máy chủ khác.",
    Callback = function()
        notify("🔄 Server Hop", "Đang tìm server...", 3)
        serverHop()
    end
})

-- ==================== TAB 2: FARM ====================
local FarmTab = Window:AddTab({Title = "Tự động farm", Icon = "swords"})

local FarmCoreSection = FarmTab:AddSection("Nâng cấp & Mastery")

FarmCoreSection:AddToggle("AutoFarmLevel", {
    Title = "Auto Farm Level",
    Description = "Tự động nhận quest → farm quái → lên level",
    Default = false,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if not v and not _G.AutoFarmMastery and not _G.AutoFarmBoss
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmCoreSection:AddToggle("AutoFarmMastery", {
    Title = "Auto Farm Mastery",
    Description = "Farm mastery cho vũ khí được chọn",
    Default = false,
    Callback = function(v)
        _G.AutoFarmMastery = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmBoss
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmCoreSection:AddDropdown("MasteryWeaponDrop", {
    Title = "Vũ Khí Farm Mastery",
    Values = {"Melee", "Sword", "Gun", "Blox Fruit"},
    Default = "Melee",
    Callback = function(v) _G.MasteryWeapon = v end,
})

FarmCoreSection:AddDropdown("SelectWeaponDrop", {
    Title = "Chọn Vũ Khí Farm",
    Values = {"Melee", "Sword", "Gun", "Blox Fruit"},
    Default = "Melee",
    Callback = function(v) _G.SelectWeapon = v end,
})

FarmCoreSection:AddDropdown("FarmMethodDrop", {
    Title = "Phương Thức Farm",
    Values = {"Quest", "Nearest", "Selected Mob"},
    Default = "Quest",
    Callback = function(v) _G.FarmMethod = v end,
})

FarmCoreSection:AddDropdown("SelectedMobDrop", {
    Title = "Chọn Quái (nếu dùng Selected Mob)",
    Values = getEnemyList(),
    Default = 1,
    Callback = function(v) _G.SelectedMob = v end,
})

local FarmPositionSection = FarmTab:AddSection("Vị trí & chiến đấu")

FarmPositionSection:AddSlider("FarmHeightSlider", {
    Title = "Độ cao so với quái",
    Description = "Số âm đứng thấp hơn, số dương đứng cao hơn.",
    Min = -20,
    Max = 30,
    Default = 8,
    Rounding = 0,
    Callback = function(v) _G.FarmHeight = v end,
})

FarmPositionSection:AddSlider("FarmDistanceSlider", {
    Title = "Khoảng cách trước / sau",
    Description = "0 là ngay trên quái; tăng để lùi ra sau.",
    Min = 0,
    Max = 25,
    Default = 0,
    Rounding = 0,
    Callback = function(v) _G.FarmDistance = v end,
})

FarmPositionSection:AddToggle("HoldFarmPositionToggle", {
    Title = "Giữ vị trí khi đánh",
    Description = "Ngăn nhân vật vừa đánh vừa chạy hoặc giật quanh quái.",
    Default = true,
    Callback = function(v) _G.HoldFarmPosition = v end,
})

FarmPositionSection:AddToggle("FreezeTargetToggle", {
    Title = "Khóa di chuyển của quái",
    Description = "Giữ mục tiêu đứng yên trong lúc đánh.",
    Default = true,
    Callback = function(v)
        _G.FreezeTarget = v
        if not v then restoreFrozenMobs() end
    end,
})

FarmPositionSection:AddSlider("AttackDelaySlider", {
    Title = "Độ trễ đánh thường",
    Description = "Thấp hơn sẽ đánh nhanh hơn; 0.08 là mức ổn định.",
    Min = 0.03,
    Max = 0.50,
    Default = 0.08,
    Rounding = 2,
    Callback = function(v) _G.AttackDelay = v end,
})

FarmPositionSection:AddSlider("HitboxSizeSlider", {
    Title = "Kích thước vùng đánh",
    Min = 2,
    Max = 30,
    Default = 12,
    Rounding = 0,
    Callback = function(v) _G.HitboxSize = v end,
})

FarmPositionSection:AddToggle("BringMobToggle", {
    Title = "Gom quái cùng loại",
    Description = "Kéo các quái cùng tên về mục tiêu đang đánh.",
    Default = true,
    Callback = function(v)
        _G.BringMob = v
        if not v then restoreFrozenMobs() end
    end,
})

FarmPositionSection:AddSlider("BringRadiusSlider", {
    Title = "Bán kính gom quái",
    Min = 50,
    Max = 1000,
    Default = 300,
    Rounding = 0,
    Callback = function(v) _G.BringRadius = v end,
})

FarmPositionSection:AddToggle("AutoSkillToggle", {
    Title = "Tự dùng kỹ năng Z, X, C, V",
    Description = "Dùng lần lượt các kỹ năng khi đang giữ vị trí.",
    Default = false,
    Callback = function(v) _G.AutoSkill = v end,
})

FarmPositionSection:AddSlider("SkillCDSlider", {
    Title = "Hồi chiêu kỹ năng",
    Min = 0.5,
    Max = 5,
    Default = 1.5,
    Rounding = 1,
    Callback = function(v) _G.SkillCooldown = v end,
})

local FarmBossSection = FarmTab:AddSection("Boss & tài nguyên")

FarmBossSection:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Boss",
    Description = "Tự động farm boss được chọn",
    Default = false,
    Callback = function(v)
        _G.AutoFarmBoss = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmBossSection:AddDropdown("SelectedBossDrop", {
    Title = "Chọn Boss",
    Values = getBossList(),
    Default = 1,
    Callback = function(v) _G.SelectedBoss = v end,
})

FarmBossSection:AddToggle("AutoFarmSeaBeast", {
    Title = "Auto Farm Sea Beast",
    Default = false,
    Callback = function(v)
        _G.AutoFarmSeaBeast = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmBoss then
            stopFarmMovement()
        end
    end,
})

FarmBossSection:AddToggle("AutoFarmObs", {
    Title = "Auto Farm Observation",
    Description = "Luyện Observation liên tục",
    Default = false,
    Callback = function(v) _G.AutoFarmObs = v end,
})

FarmBossSection:AddToggle("AutoFarmBone", {
    Title = "Auto Farm Bone",
    Default = false,
    Callback = function(v) _G.AutoFarmBone = v end,
})

FarmBossSection:AddToggle("AutoFarmFragment", {
    Title = "Auto Farm Fragment",
    Default = false,
    Callback = function(v) _G.AutoFarmFragment = v end,
})

FarmBossSection:AddToggle("AutoFarmChest", {
    Title = "Auto Farm Rương",
    Description = "Tự động tìm và mở rương",
    Default = false,
    Callback = function(v) _G.AutoFarmChest = v end,
})

-- ==================== TAB 3: RAID ====================
local RaidTab = Window:AddTab({Title = "Đột kích", Icon = "shield"})

local RaidMainSection = RaidTab:AddSection("Đột kích & thức tỉnh")

RaidMainSection:AddToggle("AutoRaidToggle", {
    Title = "Auto Raid",
    Description = "Tự động bắt đầu raid với chip được chọn",
    Default = false,
    Callback = function(v) _G.AutoRaid = v end,
})

RaidMainSection:AddToggle("AutoRaidFarmToggle", {
    Title = "Auto Farm trong Raid",
    Description = "Farm quái bên trong raid",
    Default = false,
    Callback = function(v)
        _G.AutoRaidFarm = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmBoss and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

RaidMainSection:AddDropdown("RaidChipDrop", {
    Title = "Chọn Chip Raid",
    Values = RaidChips,
    Default = "Flame",
    Callback = function(v) _G.RaidChip = v end,
})

RaidMainSection:AddToggle("AutoAwakeningToggle", {
    Title = "Auto Awakening",
    Description = "Tự động thức tỉnh trái ác quỷ",
    Default = false,
    Callback = function(v) _G.AutoAwakening = v end,
})

RaidMainSection:AddButton({
    Title = "🔄 Bắt Đầu Raid Ngay",
    Description = "Bắt đầu raid với chip đã chọn",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidStart", _G.RaidChip)
            notify("⚡ Raid", "Đang bắt đầu raid " .. _G.RaidChip .. "...", 3)
        end)
    end
})

-- ==================== TAB 4: FRUIT ====================
local FruitTab = Window:AddTab({Title = "Trái ác quỷ", Icon = "cherry"})

local FruitAutoSection = FruitTab:AddSection("Theo dõi & tự động nhặt")

FruitAutoSection:AddToggle("AutoFindFruitToggle", {
    Title = "Báo Trái Spawn",
    Description = "Thông báo khi có trái ác quỷ spawn trên map",
    Default = false,
    Callback = function(v) _G.AutoFruitFinder = v end,
})

FruitAutoSection:AddToggle("AutoCollectFruitToggle", {
    Title = "Auto Nhặt Trái",
    Description = "Tự động bay tới và nhặt trái",
    Default = false,
    Callback = function(v) _G.AutoCollectFruit = v end,
})

FruitAutoSection:AddToggle("FruitESPToggle", {
    Title = "ESP Fruit",
    Description = "Hiển thị vị trí trái ác quỷ trên map",
    Default = false,
    Callback = function(v) _G.FruitESP = v end,
})

FruitAutoSection:AddToggle("AutoGachaToggle", {
    Title = "Auto Gacha / Random Fruit",
    Description = "Tự động mua trái random mỗi 8 giây",
    Default = false,
    Callback = function(v) _G.AutoGachaFruit = v end,
})

local FruitActionSection = FruitTab:AddSection("Thao tác nhanh")

FruitActionSection:AddButton({
    Title = "Mua trái ngẫu nhiên",
    Description = "Mua 1 trái random từ Blox Fruit Dealer Cousin",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            notify("🎰 Gacha", "Đã mua Random Fruit!", 3)
        end)
    end
})

FruitActionSection:AddButton({
    Title = "Quét trái trên toàn bản đồ",
    Description = "Quét tất cả workspace tìm trái",
    Callback = function()
        local found = 0
        pcall(function()
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                    found = found + 1
                    local handle = obj:FindFirstChild("Handle")
                    local pos = handle and handle.Position or Vector3.new(0,0,0)
                    notify("🍎 Trái #" .. found, obj.Name .. " tại " .. tostring(pos), 5)
                end
            end
        end)
        if found == 0 then
            notify("🔍 Quét xong", "Không tìm thấy trái nào trên map", 3)
        else
            notify("🔍 Quét xong", "Tìm thấy " .. found .. " trái!", 3)
        end
    end
})

FruitActionSection:AddButton({
    Title = "Mở cửa hàng trái",
    Description = "Mở cửa hàng trái ác quỷ",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Place")
        end)
    end
})

-- ==================== TAB 5: ESP ====================
local ESPTab = Window:AddTab({Title = "Hiển thị ESP", Icon = "eye"})

local ESPTargetSection = ESPTab:AddSection("Đối tượng hiển thị")

ESPTargetSection:AddToggle("ESPPlayerToggle", {
    Title = "ESP Player",
    Description = "Hiển thị người chơi khác (có Team Check)",
    Default = false,
    Callback = function(v) _G.ESPPlayer = v; if not v then clearESPByPrefix("HAOTOOL_") end end,
})

ESPTargetSection:AddToggle("ESPTeamCheckToggle", {
    Title = "Team Check",
    Description = "Bỏ qua đồng đội",
    Default = true,
    Callback = function(v) _G.ESPTeamCheck = v end,
})

ESPTargetSection:AddToggle("ESPMobToggle", {
    Title = "ESP Mob",
    Description = "Hiển thị quái thường",
    Default = false,
    Callback = function(v) _G.ESPMob = v end,
})

ESPTargetSection:AddToggle("ESPBossToggle", {
    Title = "ESP Boss",
    Description = "Hiển thị boss (HP > 10000)",
    Default = false,
    Callback = function(v) _G.ESPBoss = v end,
})

ESPTargetSection:AddToggle("ESPChestToggle", {
    Title = "ESP Chest",
    Description = "Hiển thị rương",
    Default = false,
    Callback = function(v) _G.ESPChest = v end,
})

ESPTargetSection:AddToggle("ESPFlowerToggle", {
    Title = "ESP Flower",
    Description = "Hiển thị hoa",
    Default = false,
    Callback = function(v) _G.ESPFlower = v end,
})

ESPTargetSection:AddToggle("ESPIslandToggle", {
    Title = "ESP Island (Waypoint)",
    Description = "Hiển thị tên đảo",
    Default = false,
    Callback = function(v)
        _G.ESPIsland = v
        if v then
            pcall(function()
                local islands = getSeaIslands()
                for name, pos in pairs(islands) do
                    local part = Instance.new("Part")
                    part.Name = "HAOTOOL_ISLAND_" .. name
                    part.Anchored = true
                    part.CanCollide = false
                    part.Transparency = 1
                    part.Position = pos
                    part.Size = Vector3.new(1,1,1)
                    part.Parent = workspace

                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 200, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 50, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = part
                    bb.Parent = ESPFolder

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = "🏝️ " .. name
                    lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
                    lbl.TextStrokeTransparency = 0
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 16
                    lbl.Parent = bb
                end
            end)
        else
            -- Xóa waypoint đảo
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj.Name:find("HAOTOOL_ISLAND_") then obj:Destroy() end
                end
                clearESPByPrefix("HAOTOOL_ISLAND_")
            end)
        end
    end,
})

local ESPStyleSection = ESPTab:AddSection("Khoảng cách & màu sắc")

ESPStyleSection:AddSlider("ESPDistSlider", {
    Title = "Khoảng Cách ESP (studs)",
    Min = 100,
    Max = 10000,
    Default = 2000,
    Rounding = 0,
    Callback = function(v) _G.ESPDistance = v end,
})

ESPStyleSection:AddColorpicker("ESPPlayerColor", {
    Title = "Màu Player",
    Default = Color3.fromRGB(0, 170, 255),
    Callback = function(v) _G.ESPPlayerColor = v end,
})

ESPStyleSection:AddColorpicker("ESPMobColorPick", {
    Title = "Màu Mob",
    Default = Color3.fromRGB(255, 85, 85),
    Callback = function(v) _G.ESPMobColor = v end,
})

ESPStyleSection:AddColorpicker("ESPBossColorPick", {
    Title = "Màu Boss",
    Default = Color3.fromRGB(255, 170, 0),
    Callback = function(v) _G.ESPBossColor = v end,
})

ESPStyleSection:AddColorpicker("ESPFruitColorPick", {
    Title = "Màu Fruit",
    Default = Color3.fromRGB(170, 0, 255),
    Callback = function(v) _G.ESPFruitColor = v end,
})

ESPStyleSection:AddButton({
    Title = "Xóa toàn bộ ESP",
    Callback = function()
        clearAllESP()
        notify("ESP", "Đã xóa tất cả ESP", 2)
    end
})

-- ==================== TAB 6: TELEPORT ====================
local TeleportTab = Window:AddTab({Title = "Di chuyển", Icon = "map-pin"})

local IslandSection = TeleportTab:AddSection("Đảo tại Sea " .. WorldSea)

-- Lấy danh sách đảo theo Sea hiện tại
local currentIslands = getSeaIslands()
local islandNames = {}
for name, _ in pairs(currentIslands) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

IslandSection:AddDropdown("IslandDrop", {
    Title = "Chọn Đảo (Sea " .. WorldSea .. ")",
    Values = islandNames,
    Default = 1,
    Callback = function(v) _G.SelectedIsland = v end,
})

IslandSection:AddButton({
    Title = "✈️ Bay Tới Đảo",
    Description = "Bay tới đảo đã chọn",
    Callback = function()
        local targetPos = currentIslands[_G.SelectedIsland]
        if targetPos then
            notify("✈️ Teleport", "Đang bay tới " .. _G.SelectedIsland .. "...", 3)
            toTarget(CFrame.new(targetPos))
            notify("✅ Đã Đến", _G.SelectedIsland, 2)
        else
            notify("❌ Lỗi", "Không tìm thấy đảo", 2)
        end
    end
})

-- Teleport NPC quan trọng
if #ImportantNPCs > 0 then
    local NPCSection = TeleportTab:AddSection("NPC quan trọng")

    local npcNames = {}
    for _, npc in ipairs(ImportantNPCs) do
        table.insert(npcNames, npc.Name)
    end

    NPCSection:AddDropdown("NPCDrop", {
        Title = "Chọn NPC",
        Values = npcNames,
        Default = 1,
        Callback = function(v) _G.SelectedNPC = v end,
    })

    NPCSection:AddButton({
        Title = "👤 Bay Tới NPC",
        Callback = function()
            for _, npc in ipairs(ImportantNPCs) do
                if npc.Name == _G.SelectedNPC then
                    notify("✈️ Teleport", "Đang bay tới " .. npc.Name, 3)
                    toTarget(CFrame.new(npc.Position))
                    break
                end
            end
        end
    })
end

-- Teleport Boss
local BossTeleportSection = TeleportTab:AddSection("Boss")

BossTeleportSection:AddDropdown("BossTPDrop", {
    Title = "Chọn Boss",
    Values = getBossList(),
    Default = 1,
    Callback = function(v) _G.SelectedBossTP = v end,
})

BossTeleportSection:AddButton({
    Title = "💀 Bay Tới Boss",
    Callback = function()
        local bossData = getBossData(_G.SelectedBossTP)
        if bossData then
            notify("✈️ Teleport", "Đang bay tới " .. bossData.Name, 3)
            toTarget(CFrame.new(bossData.Position))
        end
    end
})

-- Teleport tới Fruit
local FruitTeleportSection = TeleportTab:AddSection("Trái ác quỷ")

FruitTeleportSection:AddButton({
    Title = "🍎 Bay Tới Trái Gần Nhất",
    Description = "Tìm và bay tới trái ác quỷ gần nhất",
    Callback = function()
        local closestFruit = nil
        local closestDist = math.huge
        pcall(function()
            local char = Player.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and obj.Name:find("Fruit") and obj:FindFirstChild("Handle") then
                    if rootPart then
                        local d = (obj.Handle.Position - rootPart.Position).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closestFruit = obj
                        end
                    else
                        closestFruit = obj
                        break
                    end
                end
            end
        end)
        if closestFruit and closestFruit:FindFirstChild("Handle") then
            notify("🍎 Fruit TP", "Bay tới " .. closestFruit.Name, 3)
            toTarget(closestFruit.Handle.CFrame)
        else
            notify("❌", "Không tìm thấy trái trên map", 2)
        end
    end
})

-- Quick Teleport đến các Sea khác
local SeaSection = TeleportTab:AddSection("Chuyển vùng biển")

SeaSection:AddButton({
    Title = "🌊 Đi Sea 1",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(2753915549, Player)
        end)
    end
})

SeaSection:AddButton({
    Title = "🌊 Đi Sea 2",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(4442272183, Player)
        end)
    end
})

SeaSection:AddButton({
    Title = "🌊 Đi Sea 3",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(7449423635, Player)
        end)
    end
})

-- ==================== TAB 7: COMBAT ====================
local CombatTab = Window:AddTab({Title = "Chiến đấu", Icon = "crosshair"})

local CombatAutoSection = CombatTab:AddSection("Haki & phòng thủ tự động")

CombatAutoSection:AddToggle("AutoBusoToggle", {
    Title = "Auto Buso Haki",
    Description = "Tự động bật Buso Haki (Haki Vũ Trang)",
    Default = true,
    Callback = function(v) _G.AutoHaki = v end,
})

CombatAutoSection:AddToggle("AutoKenToggle", {
    Title = "Auto Ken Haki",
    Description = "Tự động bật Ken Haki (Haki Quan Sát)",
    Default = false,
    Callback = function(v) _G.AutoKen = v end,
})

CombatAutoSection:AddToggle("AutoObsV2Toggle", {
    Title = "Auto Observation V2",
    Description = "Tự động kích hoạt Observation V2",
    Default = false,
    Callback = function(v) _G.AutoObsV2 = v end,
})

CombatAutoSection:AddToggle("AutoDodgeToggle", {
    Title = "Auto Dodge",
    Description = "Tự động né tránh đạn/đòn đánh",
    Default = false,
    Callback = function(v) _G.AutoDodge = v end,
})

local CombatActionSection = CombatTab:AddSection("Kích hoạt nhanh")

CombatActionSection:AddButton({
    Title = "Bật Buso Haki",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
            notify("🥋", "Đã bật Buso Haki", 2)
        end)
    end
})

CombatActionSection:AddButton({
    Title = "Bật Ken Haki",
    Callback = function()
        pcall(function()
            local ken = ReplicatedStorage.Remotes:FindFirstChild("Ken")
            if ken then ken:FireServer(true) end
            notify("👁️", "Đã bật Ken Haki", 2)
        end)
    end
})

CombatActionSection:AddButton({
    Title = "Bật Observation V2",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Observation")
            notify("🔮", "Đã bật Observation V2", 2)
        end)
    end
})

-- ==================== TAB 8: MISC ====================
local MiscTab = Window:AddTab({Title = "Tiện ích", Icon = "wrench"})

local MovementSection = MiscTab:AddSection("Di chuyển nhân vật")

-- Speed & Jump
MovementSection:AddToggle("WalkSpeedToggle", {
    Title = "WalkSpeed Hack",
    Default = false,
    Callback = function(v) _G.WalkSpeedHack = v end,
})

MovementSection:AddSlider("WalkSpeedSlider", {
    Title = "Tốc Độ Chạy",
    Min = 16,
    Max = 300,
    Default = 50,
    Rounding = 0,
    Callback = function(v) _G.WalkSpeedVal = v end,
})

MovementSection:AddToggle("JumpPowerToggle", {
    Title = "JumpPower Hack",
    Default = false,
    Callback = function(v) _G.JumpPowerHack = v end,
})

MovementSection:AddSlider("JumpPowerSlider", {
    Title = "Sức Nhảy",
    Min = 50,
    Max = 500,
    Default = 100,
    Rounding = 0,
    Callback = function(v) _G.JumpPowerVal = v end,
})

MovementSection:AddToggle("InfiniteJumpToggle", {
    Title = "Infinite Jump",
    Description = "Nhảy không giới hạn trên không",
    Default = false,
    Callback = function(v) _G.InfiniteJump = v end,
})

MovementSection:AddToggle("InfiniteEnergyToggle", {
    Title = "Infinite Energy",
    Description = "Năng lượng không giới hạn",
    Default = false,
    Callback = function(v) _G.InfiniteEnergy = v end,
})

-- Stats
local StatsSection = MiscTab:AddSection("Chỉ số tự động")

StatsSection:AddToggle("AutoStatsToggle", {
    Title = "Auto Cộng Điểm Stats",
    Default = false,
    Callback = function(v) _G.AutoStats = v end,
})

StatsSection:AddDropdown("StatDropdown", {
    Title = "Chọn Chỉ Số",
    Values = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"},
    Default = "Melee",
    Callback = function(v) _G.StatToUpgrade = v end,
})

-- Anti-AFK
local ProtectionSection = MiscTab:AddSection("Bảo vệ phiên chơi")

ProtectionSection:AddToggle("AntiAFKToggle", {
    Title = "Anti AFK",
    Description = "Chống bị kick do AFK",
    Default = true,
    Callback = function(v) _G.AntiAFK = v end,
})

-- FPS Boost
local PerformanceSection = MiscTab:AddSection("Hiệu năng & hiển thị")

PerformanceSection:AddButton({
    Title = "Tối ưu FPS",
    Description = "Xóa texture, particle, giảm lag",
    Callback = function()
        pcall(function()
            local removed = 0
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                    removed = removed + 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj:Destroy()
                    removed = removed + 1
                end
            end
            -- Đơn giản hóa material
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
            -- Giảm chất lượng ánh sáng
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            notify("⚡ FPS Boost", "Đã xóa " .. removed .. " hiệu ứng + đơn giản hóa vật liệu", 3)
        end)
    end
})

PerformanceSection:AddButton({
    Title = "Chế độ nền trắng",
    Description = "Xóa Skybox, đổi nền trắng",
    Callback = function()
        pcall(function()
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            for _, obj in pairs(Lighting:GetChildren()) do
                if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds")
                    or obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
                    or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
                    obj:Destroy()
                end
            end
            notify("⬜", "White Screen đã bật", 2)
        end)
    end
})

PerformanceSection:AddButton({
    Title = "Chế độ nền đen",
    Description = "Xóa Skybox, đổi nền đen",
    Callback = function()
        pcall(function()
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.Brightness = 0
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            for _, obj in pairs(Lighting:GetChildren()) do
                if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds")
                    or obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
                    or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
                    obj:Destroy()
                end
            end
            notify("⬛", "Black Screen đã bật", 2)
        end)
    end
})

-- Server Hop
local MiscServerSection = MiscTab:AddSection("Tự động đổi máy chủ")

MiscServerSection:AddButton({
    Title = "Đổi máy chủ ngay",
    Description = "Nhảy sang server khác",
    Callback = function()
        notify("🌐", "Đang tìm server...", 2)
        serverHop()
    end
})

MiscServerSection:AddToggle("ServerHopNoFruitToggle", {
    Title = "Auto Server Hop (Không có Fruit)",
    Description = "Tự động nhảy server nếu không có trái",
    Default = false,
    Callback = function(v) _G.ServerHopNoFruit = v end,
})

-- ==================== TAB 9: SETTINGS ====================
local SettingsTab = Window:AddTab({Title = "Cài đặt", Icon = "settings"})

SettingsTab:AddParagraph({
    Title = "Cá nhân hóa HAOTOOL",
    Content = "Đổi giao diện, phím tắt và lưu cấu hình của bạn."
})

local UtilitySection = SettingsTab:AddSection("Thông tin & dữ liệu")

UtilitySection:AddButton({
    Title = "Xem thông tin nhân vật",
    Description = "Xem thông tin nhân vật hiện tại",
    Callback = function()
        pcall(function()
            local lvl = Player.Data.Level.Value or "?"
            local beli = Player.Data.Beli.Value or "?"
            local frag = "?"
            pcall(function() frag = Player.Data.Fragments.Value end)

            notify("📋 Thông Tin", string.format(
                "Level: %s\nBeli: %s\nFragment: %s\nSea: %d\nServer: %s",
                tostring(lvl), tostring(beli), tostring(frag), WorldSea, game.JobId:sub(1,12)
            ), 6)
        end)
    end
})

UtilitySection:AddButton({
    Title = "Làm mới danh sách quái",
    Description = "Cập nhật danh sách quái hiện có",
    Callback = function()
        local enemies = getEnemyList()
        pcall(function()
            if Fluent.Options and Fluent.Options.SelectedMobDrop then
                Fluent.Options.SelectedMobDrop:SetValues(enemies)
            end
        end)
        notify("🔄", "Đã cập nhật danh sách quái: " .. #enemies .. " loại", 2)
    end
})

-- Lưu/Tải cấu hình (nếu SaveManager tồn tại)
if SaveManager and InterfaceManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)

        -- Đồng bộ mặc định của trình quản lý với giao diện mới.
        -- Cấu hình người dùng đã lưu (nếu có) vẫn được ưu tiên khi tải.
        if InterfaceManager.Settings then
            InterfaceManager.Settings.Theme = "Amethyst"
            InterfaceManager.Settings.MenuKeybind = "RightControl"
        end

        SaveManager:IgnoreThemeSettings()
        InterfaceManager:SetFolder("HaoToolHub")
        SaveManager:SetFolder("HaoToolHub/BloxFruits")
        InterfaceManager:BuildInterfaceSection(SettingsTab)
        -- InterfaceManager cung cấp sẵn chọn theme, acrylic, độ trong suốt
        -- và phím ẩn/hiện; không cần tạo thêm điều khiển trùng lặp.
        SaveManager:BuildConfigSection(SettingsTab)
    end)
end

------------------------------------------------------------
-- PHẦN 8: HOÀN TẤT
------------------------------------------------------------

-- Chọn tab đầu tiên
pcall(function() Window:SelectTab(1) end)

-- Tải config tự động (nếu có)
pcall(function()
    if SaveManager then
        SaveManager:LoadAutoloadConfig()
    end
end)

-- Thông báo load thành công
notify(
    "HAOTOOL • Sẵn sàng",
    "Sea " .. WorldSea
        .. "  •  " .. #(WorldSea == 1 and QuestsSea1 or WorldSea == 2 and QuestsSea2 or QuestsSea3) .. " quest"
        .. "  •  " .. #islandNames .. " đảo"
        .. "\nRightControl để ẩn / hiện giao diện",
    6
)

print("=====================================")
print("⚡ HAOTOOL v2.0 — LOADED SUCCESSFULLY")
print("🌊 Sea: " .. WorldSea)
print("📌 RightControl to toggle GUI")
print("=====================================")
