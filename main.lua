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
_G.BringMob          = false
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
    {MinLevel=1,   MaxLevel=9,   QuestName="BanditQuest1",  QuestNumber=1, MobName="Bandit",             QuestNpc=Vector3.new(1059,15,1549),    MobPosition=Vector3.new(1038,16,1621)},
    {MinLevel=10,  MaxLevel=14,  QuestName="MonkeyQuest",   QuestNumber=1, MobName="Monkey",             QuestNpc=Vector3.new(-1598,36,153),    MobPosition=Vector3.new(-1610,36,142)},
    {MinLevel=15,  MaxLevel=29,  QuestName="MonkeyQuest",   QuestNumber=2, MobName="Gorilla",            QuestNpc=Vector3.new(-1598,36,153),    MobPosition=Vector3.new(-1243,6,-493)},
    {MinLevel=30,  MaxLevel=39,  QuestName="PirateQuest",   QuestNumber=1, MobName="Pirate",             QuestNpc=Vector3.new(-1141,4,3896),    MobPosition=Vector3.new(-1203,4,3915)},
    {MinLevel=40,  MaxLevel=59,  QuestName="PirateQuest",   QuestNumber=2, MobName="Brute",              QuestNpc=Vector3.new(-1141,4,3896),    MobPosition=Vector3.new(-1145,14,4300)},
    {MinLevel=60,  MaxLevel=89,  QuestName="DesertQuest",   QuestNumber=1, MobName="Desert Bandit",      QuestNpc=Vector3.new(894,6,4390),      MobPosition=Vector3.new(996,6,4363)},
    {MinLevel=90,  MaxLevel=99,  QuestName="DesertQuest",   QuestNumber=2, MobName="Desert Officer",     QuestNpc=Vector3.new(894,6,4390),      MobPosition=Vector3.new(1582,10,4370)},
    {MinLevel=100, MaxLevel=119, QuestName="SnowQuest",     QuestNumber=1, MobName="Snow Bandit",        QuestNpc=Vector3.new(1385,15,-4740),   MobPosition=Vector3.new(1313,26,-4641)},
    {MinLevel=120, MaxLevel=149, QuestName="SnowQuest",     QuestNumber=2, MobName="Snowman",            QuestNpc=Vector3.new(1385,15,-4740),   MobPosition=Vector3.new(1250,26,-4580)},
    {MinLevel=150, MaxLevel=174, QuestName="MarineQuest2",  QuestNumber=1, MobName="Marine Commodore",   QuestNpc=Vector3.new(-5036,24,4317),   MobPosition=Vector3.new(-4940,72,4260)},
    {MinLevel=175, MaxLevel=189, QuestName="SkyQuest",      QuestNumber=1, MobName="Sky Bandit",         QuestNpc=Vector3.new(-4839,717,-2620), MobPosition=Vector3.new(-4950,717,-2620)},
    {MinLevel=190, MaxLevel=209, QuestName="SkyQuest",      QuestNumber=2, MobName="Dark Master",        QuestNpc=Vector3.new(-4839,717,-2620), MobPosition=Vector3.new(-5250,390,-2250)},
    {MinLevel=210, MaxLevel=249, QuestName="PrisonerQuest", QuestNumber=1, MobName="Prisoner",           QuestNpc=Vector3.new(4875,5,735),      MobPosition=Vector3.new(4940,5,800)},
    {MinLevel=250, MaxLevel=274, QuestName="PrisonerQuest", QuestNumber=2, MobName="Dangerous Prisoner", QuestNpc=Vector3.new(4875,5,735),      MobPosition=Vector3.new(5060,5,890)},
    {MinLevel=275, MaxLevel=299, QuestName="ColosseumQuest",QuestNumber=1, MobName="Toga Warrior",       QuestNpc=Vector3.new(-1516,7,-2994),   MobPosition=Vector3.new(-1800,7,-3000)},
    {MinLevel=300, MaxLevel=329, QuestName="MagmaQuest",    QuestNumber=1, MobName="Military Soldier",   QuestNpc=Vector3.new(-5241,8,8504),    MobPosition=Vector3.new(-5400,8,8500)},
    {MinLevel=330, MaxLevel=374, QuestName="MagmaQuest",    QuestNumber=2, MobName="Military Spy",       QuestNpc=Vector3.new(-5241,8,8504),    MobPosition=Vector3.new(-5800,8,8800)},
    {MinLevel=375, MaxLevel=399, QuestName="FishmanQuest",  QuestNumber=1, MobName="Fishman Warrior",    QuestNpc=Vector3.new(61163,11,1819),   MobPosition=Vector3.new(60800,18,1500)},
    {MinLevel=400, MaxLevel=449, QuestName="FishmanQuest",  QuestNumber=2, MobName="Fishman Commando",   QuestNpc=Vector3.new(61163,11,1819),   MobPosition=Vector3.new(61800,18,1500)},
    {MinLevel=450, MaxLevel=474, QuestName="SkyExp1Quest",  QuestNumber=1, MobName="God's Guard",        QuestNpc=Vector3.new(-4720,845,-1950), MobPosition=Vector3.new(-4700,845,-1900)},
    {MinLevel=475, MaxLevel=524, QuestName="SkyExp1Quest",  QuestNumber=2, MobName="Shanda",             QuestNpc=Vector3.new(-4720,845,-1950), MobPosition=Vector3.new(-7700,5600,-1800)},
    {MinLevel=525, MaxLevel=549, QuestName="SkyExp2Quest",  QuestNumber=1, MobName="Royal Squad",        QuestNpc=Vector3.new(-7900,5600,-1800),MobPosition=Vector3.new(-7600,5600,-1400)},
    {MinLevel=550, MaxLevel=624, QuestName="SkyExp2Quest",  QuestNumber=2, MobName="Royal Soldier",      QuestNpc=Vector3.new(-7900,5600,-1800),MobPosition=Vector3.new(-7800,5600,-1600)},
    {MinLevel=625, MaxLevel=649, QuestName="FountainQuest", QuestNumber=1, MobName="Galley Pirate",      QuestNpc=Vector3.new(5121,5,4110),     MobPosition=Vector3.new(5500,5,4000)},
    {MinLevel=650, MaxLevel=700, QuestName="FountainQuest", QuestNumber=2, MobName="Galley Captain",     QuestNpc=Vector3.new(5121,5,4110),     MobPosition=Vector3.new(5600,5,4400)},
}

-- ==================== QUEST DATA — SEA 2 (Lv 700–1500) ====================
-- Lưu ý: Tọa độ có thể lệch vài đơn vị, script sẽ tự tween tới
local QuestsSea2 = {
    {MinLevel=700,  MaxLevel=724,  QuestName="Area1Quest",       QuestNumber=1, MobName="Swan Pirate",         QuestNpc=Vector3.new(-432,73,299),       MobPosition=Vector3.new(-545,72,302)},
    {MinLevel=725,  MaxLevel=774,  QuestName="Area1Quest",       QuestNumber=2, MobName="Factory Staff",       QuestNpc=Vector3.new(-432,73,299),       MobPosition=Vector3.new(-410,72,280)},
    {MinLevel=775,  MaxLevel=799,  QuestName="Area2Quest",       QuestNumber=1, MobName="Marine Lieutenant",   QuestNpc=Vector3.new(-1189,6,371),       MobPosition=Vector3.new(-1250,6,430)},
    {MinLevel=800,  MaxLevel=849,  QuestName="Area2Quest",       QuestNumber=2, MobName="Marine Captain",      QuestNpc=Vector3.new(-1189,6,371),       MobPosition=Vector3.new(-1300,6,350)},
    {MinLevel=850,  MaxLevel=899,  QuestName="GreenZoneQuest",   QuestNumber=1, MobName="Zombie",              QuestNpc=Vector3.new(-2410,73,-3222),    MobPosition=Vector3.new(-2356,73,-3187)},
    {MinLevel=900,  MaxLevel=949,  QuestName="GreenZoneQuest",   QuestNumber=2, MobName="Vampire",             QuestNpc=Vector3.new(-2410,73,-3222),    MobPosition=Vector3.new(-2520,73,-3130)},
    {MinLevel=950,  MaxLevel=999,  QuestName="GraveyardQuest",   QuestNumber=1, MobName="Zombie",              QuestNpc=Vector3.new(-5465,87,-782),     MobPosition=Vector3.new(-5530,87,-890)},
    {MinLevel=1000, MaxLevel=1049, QuestName="SnowMountainQuest",QuestNumber=1, MobName="Snow Trooper",        QuestNpc=Vector3.new(609,400,-5765),     MobPosition=Vector3.new(550,400,-5800)},
    {MinLevel=1050, MaxLevel=1099, QuestName="SnowMountainQuest",QuestNumber=2, MobName="Winter Warrior",      QuestNpc=Vector3.new(609,400,-5765),     MobPosition=Vector3.new(480,400,-5860)},
    {MinLevel=1100, MaxLevel=1124, QuestName="IceSideQuest",     QuestNumber=1, MobName="Ice Castle Warrior",  QuestNpc=Vector3.new(6125,252,-4902),    MobPosition=Vector3.new(6200,252,-4950)},
    {MinLevel=1125, MaxLevel=1174, QuestName="IceSideQuest",     QuestNumber=2, MobName="Ice Castle King",     QuestNpc=Vector3.new(6125,252,-4902),    MobPosition=Vector3.new(6050,252,-4980)},
    {MinLevel=1175, MaxLevel=1249, QuestName="ForgottenQuest",   QuestNumber=1, MobName="Forgotten Island NPC",QuestNpc=Vector3.new(-3053,236,-10197),  MobPosition=Vector3.new(-3100,236,-10250)},
    {MinLevel=1250, MaxLevel=1299, QuestName="MansionQuest",     QuestNumber=1, MobName="Reborn Skeleton",     QuestNpc=Vector3.new(-4545,82,-691),     MobPosition=Vector3.new(-4600,82,-750)},
    {MinLevel=1300, MaxLevel=1324, QuestName="MansionQuest",     QuestNumber=2, MobName="Living Zombie",       QuestNpc=Vector3.new(-4545,82,-691),     MobPosition=Vector3.new(-4480,82,-640)},
    {MinLevel=1325, MaxLevel=1349, QuestName="CakeQuest",        QuestNumber=1, MobName="Cookie Crafter",      QuestNpc=Vector3.new(-856,8,-11221),     MobPosition=Vector3.new(-900,8,-11280)},
    {MinLevel=1350, MaxLevel=1374, QuestName="CakeQuest",        QuestNumber=2, MobName="Cake Guard",          QuestNpc=Vector3.new(-856,8,-11221),     MobPosition=Vector3.new(-780,8,-11150)},
    {MinLevel=1375, MaxLevel=1424, QuestName="CakeQuest",        QuestNumber=3, MobName="Biscuit Soldier",     QuestNpc=Vector3.new(-856,8,-11221),     MobPosition=Vector3.new(-950,8,-11350)},
    {MinLevel=1425, MaxLevel=1474, QuestName="CakeQuest",        QuestNumber=4, MobName="Chocolate Milk",      QuestNpc=Vector3.new(-856,8,-11221),     MobPosition=Vector3.new(-820,8,-11400)},
    {MinLevel=1475, MaxLevel=1500, QuestName="CakeQuest",        QuestNumber=5, MobName="Candy Rebel",         QuestNpc=Vector3.new(-856,8,-11221),     MobPosition=Vector3.new(-750,8,-11100)},
}

-- ==================== QUEST DATA — SEA 3 (Lv 1500–2550+) ====================
local QuestsSea3 = {
    {MinLevel=1500, MaxLevel=1524, QuestName="PortQuest",        QuestNumber=1, MobName="Pirate Millionaire",  QuestNpc=Vector3.new(-290,42,5358),     MobPosition=Vector3.new(-350,42,5420)},
    {MinLevel=1525, MaxLevel=1574, QuestName="PortQuest",        QuestNumber=2, MobName="Pistol Billionaire",  QuestNpc=Vector3.new(-290,42,5358),     MobPosition=Vector3.new(-220,42,5300)},
    {MinLevel=1575, MaxLevel=1599, QuestName="HydraQuest",       QuestNumber=1, MobName="Dragon Crew Warrior", QuestNpc=Vector3.new(5229,15,353),      MobPosition=Vector3.new(5300,15,400)},
    {MinLevel=1600, MaxLevel=1624, QuestName="HydraQuest",       QuestNumber=2, MobName="Dragon Crew Archer",  QuestNpc=Vector3.new(5229,15,353),      MobPosition=Vector3.new(5180,15,300)},
    {MinLevel=1625, MaxLevel=1649, QuestName="TreeQuest",        QuestNumber=1, MobName="Forest Pirate",       QuestNpc=Vector3.new(2575,1190,-680),   MobPosition=Vector3.new(2630,1190,-720)},
    {MinLevel=1650, MaxLevel=1699, QuestName="TreeQuest",        QuestNumber=2, MobName="Mythological Pirate", QuestNpc=Vector3.new(2575,1190,-680),   MobPosition=Vector3.new(2520,1190,-640)},
    {MinLevel=1700, MaxLevel=1724, QuestName="TurtleQuest",      QuestNumber=1, MobName="Musketeer Pirate",    QuestNpc=Vector3.new(-12142,332,-3820), MobPosition=Vector3.new(-12200,332,-3880)},
    {MinLevel=1725, MaxLevel=1774, QuestName="TurtleQuest",      QuestNumber=2, MobName="Mercenary",           QuestNpc=Vector3.new(-12142,332,-3820), MobPosition=Vector3.new(-12080,332,-3760)},
    {MinLevel=1775, MaxLevel=1799, QuestName="HauntedQuest",     QuestNumber=1, MobName="Vampire",             QuestNpc=Vector3.new(-9516,167,5765),   MobPosition=Vector3.new(-9580,167,5820)},
    {MinLevel=1800, MaxLevel=1849, QuestName="HauntedQuest",     QuestNumber=2, MobName="Vampire",             QuestNpc=Vector3.new(-9516,167,5765),   MobPosition=Vector3.new(-9450,167,5710)},
    {MinLevel=1850, MaxLevel=1899, QuestName="TreatsQuest",      QuestNumber=1, MobName="Candy Pirate",        QuestNpc=Vector3.new(-2364,73,-10925),  MobPosition=Vector3.new(-2420,73,-10980)},
    {MinLevel=1900, MaxLevel=1974, QuestName="TreatsQuest",      QuestNumber=2, MobName="Sweet Thief",         QuestNpc=Vector3.new(-2364,73,-10925),  MobPosition=Vector3.new(-2300,73,-10870)},
    {MinLevel=1975, MaxLevel=2024, QuestName="TikiQuest",        QuestNumber=1, MobName="Tiki Warrior",        QuestNpc=Vector3.new(-12104,54,-5765),  MobPosition=Vector3.new(-12160,54,-5820)},
    {MinLevel=2025, MaxLevel=2074, QuestName="TikiQuest",        QuestNumber=2, MobName="Tiki Warrior",        QuestNpc=Vector3.new(-12104,54,-5765),  MobPosition=Vector3.new(-12050,54,-5710)},
    {MinLevel=2075, MaxLevel=2174, QuestName="CastleQuest",      QuestNumber=1, MobName="Castle Mage",         QuestNpc=Vector3.new(-5044,314,-2812),  MobPosition=Vector3.new(-5100,314,-2870)},
    {MinLevel=2175, MaxLevel=2274, QuestName="CastleQuest",      QuestNumber=2, MobName="Royal Warrior",       QuestNpc=Vector3.new(-5044,314,-2812),  MobPosition=Vector3.new(-4980,314,-2750)},
    {MinLevel=2275, MaxLevel=2399, QuestName="CastleQuest",      QuestNumber=3, MobName="Royal Squad",         QuestNpc=Vector3.new(-5044,314,-2812),  MobPosition=Vector3.new(-5060,314,-2900)},
    {MinLevel=2400, MaxLevel=2550, QuestName="CastleQuest",      QuestNumber=4, MobName="Elite Pirate",        QuestNpc=Vector3.new(-5044,314,-2812),  MobPosition=Vector3.new(-5000,314,-2800)},
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

-- ====== Bay tới mục tiêu (Tween) ======
local function toTarget(targetCFrame)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude

    -- Nếu gần rồi thì teleport thẳng
    if distance < 15 then
        rootPart.CFrame = targetCFrame
        return
    end

    local speed = 300
    setNoclip(true)
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    setNoclip(false)
end

-- ====== Haki (Buso & Ken) ======
local function checkHaki()
    pcall(function()
        local char = Player.Character
        if not char then return end

        -- Auto Buso Haki
        if _G.AutoHaki and not char:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end

        -- Auto Ken Haki
        if _G.AutoKen and not char:FindFirstChild("HasKen") then
            local ken = ReplicatedStorage.Remotes:FindFirstChild("Ken")
            if ken then ken:FireServer(true) end
        end

        -- Auto Observation V2
        if _G.AutoObsV2 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Observation")
        end
    end)
end

-- ====== Tấn công (chỉ dùng tool:Activate — an toàn cho GUI) ======
local function attack()
    checkHaki()
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
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

-- ====== Gom quái lại 1 chỗ ======
local function bringMobsNear(targetName, centerCFrame)
    if not _G.BringMob then return end
    pcall(function()
        if not workspace:FindFirstChild("Enemies") then return end
        for _, mob in pairs(workspace.Enemies:GetChildren()) do
            if mob.Name == targetName
                and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
                and mob:FindFirstChild("HumanoidRootPart") then
                local dist = (mob.HumanoidRootPart.Position - centerCFrame.Position).Magnitude
                if dist <= 350 then
                    mob.HumanoidRootPart.CFrame = centerCFrame
                    mob.HumanoidRootPart.CanCollide = false
                    mob.Humanoid.WalkSpeed = 0
                end
            end
        end
    end)
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
    local questGui = Player.PlayerGui:FindFirstChild("Main")
        and Player.PlayerGui.Main:FindFirstChild("Quest")
    return questGui and questGui.Visible
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

            local nameMatch = (mobName == "" or mobName == nil or mob.Name == mobName)
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
        if mob.Name == bossName
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
        task.wait(0.15)
        if _G.AutoFarmLevel then
            pcall(function()
                local level = Player.Data.Level.Value
                local quest = getQuestData(level)
                if not quest then return end

                if not hasActiveQuest() then
                    -- Bay tới NPC nhận quest
                    toTarget(CFrame.new(quest.QuestNpc))
                    task.wait(0.5)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer(
                        "StartQuest", quest.QuestName, quest.QuestNumber
                    )
                    task.wait(0.3)
                else
                    -- Tìm quái theo phương thức farm
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
                        -- Không có quái → bay tới vị trí mob
                        toTarget(CFrame.new(quest.MobPosition))
                    else
                        equipWeapon(_G.SelectWeapon)
                        local char = Player.Character
                        if char and char:FindFirstChild("HumanoidRootPart")
                            and targetMob:FindFirstChild("HumanoidRootPart") then
                            setNoclip(true)
                            -- Đứng phía trên quái để đánh
                            char.HumanoidRootPart.CFrame =
                                targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                            -- Gom quái nếu bật
                            bringMobsNear(quest.MobName, targetMob.HumanoidRootPart.CFrame)
                            -- Đánh
                            attack()
                            -- Auto Skill
                            useSkills()
                        end
                    end
                end
            end)
        else
            setNoclip(false)
        end
    end
end)

-- ====== LOOP 2: Auto Farm Mastery ======
task.spawn(function()
    while true do
        task.wait(0.15)
        if _G.AutoFarmMastery and not _G.AutoFarmLevel then
            pcall(function()
                equipWeapon(_G.MasteryWeapon)
                -- Tìm quái gần nhất để farm mastery
                local targetMob = findMob("", true)
                if targetMob and targetMob:FindFirstChild("HumanoidRootPart") then
                    local char = Player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        setNoclip(true)
                        char.HumanoidRootPart.CFrame =
                            targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                        attack()
                        useSkills()
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 3: Auto Farm Boss ======
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.AutoFarmBoss and not _G.AutoFarmLevel then
            pcall(function()
                local bossData = getBossData(_G.SelectedBoss)
                if not bossData then return end

                local boss = findBoss(_G.SelectedBoss)
                if not boss then
                    -- Boss chưa spawn, bay tới vị trí chờ
                    toTarget(CFrame.new(bossData.Position))
                    task.wait(1)
                else
                    equipWeapon(_G.SelectWeapon)
                    local char = Player.Character
                    if char and char:FindFirstChild("HumanoidRootPart")
                        and boss:FindFirstChild("HumanoidRootPart") then
                        setNoclip(true)
                        char.HumanoidRootPart.CFrame =
                            boss.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                        attack()
                        useSkills()
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 4: Auto Farm Sea Beast ======
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoFarmSeaBeast then
            pcall(function()
                -- Tìm Sea Beast trong workspace
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0
                        and obj:FindFirstChild("HumanoidRootPart")
                        and (obj.Name:find("Sea Beast") or obj.Name:find("SeaBeast")) then
                        equipWeapon(_G.SelectWeapon)
                        local char = Player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            setNoclip(true)
                            char.HumanoidRootPart.CFrame =
                                obj.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)
                            attack()
                            useSkills()
                        end
                        break
                    end
                end
            end)
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
                    if _G.AutoRaidFarm then
                        local targetMob = findMob("", true)
                        if targetMob and targetMob:FindFirstChild("HumanoidRootPart") then
                            equipWeapon(_G.SelectWeapon)
                            local char = Player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                setNoclip(true)
                                char.HumanoidRootPart.CFrame =
                                    targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                                attack()
                                useSkills()
                            end
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
    Callback = function(v) _G.AutoFarmLevel = v end,
})

FarmCoreSection:AddToggle("AutoFarmMastery", {
    Title = "Auto Farm Mastery",
    Description = "Farm mastery cho vũ khí được chọn",
    Default = false,
    Callback = function(v) _G.AutoFarmMastery = v end,
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

FarmCoreSection:AddToggle("BringMobToggle", {
    Title = "Gom Quái (Bring Mob)",
    Description = "Kéo quái cùng tên lại 1 chỗ",
    Default = false,
    Callback = function(v) _G.BringMob = v end,
})

FarmCoreSection:AddToggle("AutoSkillToggle", {
    Title = "Auto Skill (Z, X, C, V)",
    Description = "Tự động dùng skill khi farm",
    Default = false,
    Callback = function(v) _G.AutoSkill = v end,
})

FarmCoreSection:AddSlider("SkillCDSlider", {
    Title = "Cooldown Skill (giây)",
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
    Callback = function(v) _G.AutoFarmBoss = v end,
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
    Callback = function(v) _G.AutoFarmSeaBeast = v end,
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
    Callback = function(v) _G.AutoRaidFarm = v end,
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
