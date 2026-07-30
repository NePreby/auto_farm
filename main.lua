local HAOTOOL_SOURCE = [========[
local RuntimeEnv = getgenv and getgenv() or _G
local RequestedScriptVersion = "2.1.4"
if RuntimeEnv.HAOTOOL_RUNNING then
    -- Khi người dùng bấm EXECUTE lại trong Delta X: Xóa giao diện cũ và dựng lại giao diện mới 100%
    if type(RuntimeEnv.HAOTOOL_DESTROY_UI) == "function" then
        pcall(RuntimeEnv.HAOTOOL_DESTROY_UI)
    end
    RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
    RuntimeEnv.HAOTOOL_RUNNING = nil
    RuntimeEnv.HAOTOOL_TOGGLE_MENU = nil
    RuntimeEnv.HAOTOOL_DESTROY_UI = nil
    RuntimeEnv.HAOTOOL_TELEPORT_QUEUED = nil
    task.wait(0.1)
end
RuntimeEnv.HAOTOOL_RUNNING = true
local CurrentRunToken = {}
RuntimeEnv.HAOTOOL_RUN_TOKEN = CurrentRunToken
RuntimeEnv.HAOTOOL_SCRIPT_VERSION = RequestedScriptVersion
RuntimeEnv.HAOTOOL_UI_READY = false
RuntimeEnv.HAOTOOL_TAB_COUNT = 0

--[[
    ================================================================================
    ⚡ HAOTOOL | BLOX FRUITS V2.1.4 — STABLE EDITION
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
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser         = game:GetService("VirtualUser")
local TeleportService     = game:GetService("TeleportService")
local HttpService         = game:GetService("HttpService")
local CoreGui             = game:GetService("CoreGui")
local Lighting            = game:GetService("Lighting")
local Workspace           = game:GetService("Workspace")

local featureErrors = {}
local function runFeature(featureName, callback)
    local ok, result = pcall(callback)
    if ok then
        featureErrors[featureName] = nil
        return true, result
    end

    local old = featureErrors[featureName]
    local now = os.clock()
    featureErrors[featureName] = {Message = tostring(result), Time = now}
    if not old or now - old.Time >= 8 then
        warn("[HAOTOOL/" .. featureName .. "] " .. tostring(result))
    end
    return false, result
end

-- Character tracking
local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(char)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
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

-- Nạp thư viện Fluent với URL tương thích Delta X Mobile / PC
local ok1, err1 = pcall(function()
    Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
end)
if not ok1 or not Fluent then
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)
end

if not Fluent then
    warn("[HAOTOOL] Không nạp được Fluent UI: " .. tostring(err1))
    return
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

local function setDefault(key, value)
    if _G[key] == nil then
        _G[key] = value
    end
end

-- Farm & chiến đấu
setDefault("AutoFarmLevel", false)
setDefault("AutoFarmMastery", false)
setDefault("MasteryWeapon", "Melee")
setDefault("AutoFarmBoss", false)
setDefault("SelectedBoss", "")
setDefault("AutoFarmSeaBeast", false)
setDefault("AutoFarmObs", false)
setDefault("AutoFarmBone", false)
setDefault("AutoFarmFragment", false)
setDefault("AutoFarmChest", false)
setDefault("SelectWeapon", "Melee")
setDefault("FarmMethod", "Quest")
setDefault("SelectedMob", "")
setDefault("BringMob", true)
setDefault("BringRadius", 300)
setDefault("FarmHeight", 12)
setDefault("FarmDistance", 0)
setDefault("HoldFarmPosition", true)
setDefault("FreezeTarget", true)
setDefault("AttackDelay", 0.05)
setDefault("BackgroundAttack", true)
setDefault("HitboxSize", 12)
setDefault("SafetyMode", true)
setDefault("AutoSkill", false)
setDefault("SkillCooldown", 1.5)

-- Raid
setDefault("AutoRaid", false)
setDefault("AutoRaidFarm", false)
setDefault("AutoAwakening", false)
setDefault("RaidChip", "Flame")

-- Fruit
setDefault("AutoFruitFinder", false)
setDefault("AutoCollectFruit", false)
setDefault("FruitESP", false)
setDefault("AutoGachaFruit", false)

-- ESP
setDefault("ESPPlayer", false)
setDefault("ESPMob", false)
setDefault("ESPBoss", false)
setDefault("ESPChest", false)
setDefault("ESPFlower", false)
setDefault("ESPIsland", false)
setDefault("ESPDistance", 2000)
setDefault("ESPPlayerColor", Color3.fromRGB(0, 170, 255))
setDefault("ESPMobColor", Color3.fromRGB(255, 85, 85))
setDefault("ESPBossColor", Color3.fromRGB(255, 170, 0))
setDefault("ESPFruitColor", Color3.fromRGB(170, 0, 255))
setDefault("ESPChestColor", Color3.fromRGB(255, 255, 0))
setDefault("ESPFlowerColor", Color3.fromRGB(255, 100, 200))
setDefault("ESPTeamCheck", true)

-- Combat
setDefault("AutoHaki", true)
setDefault("AutoKen", false)
setDefault("AutoObsV2", false)
setDefault("AutoDodge", false)

-- Misc
setDefault("WalkSpeedHack", false)
setDefault("WalkSpeedVal", 50)
setDefault("JumpPowerHack", false)
setDefault("JumpPowerVal", 100)
setDefault("InfiniteJump", false)
setDefault("InfiniteEnergy", false)
setDefault("AntiAFK", true)
setDefault("AutoStats", false)
setDefault("StatToUpgrade", "Melee")
setDefault("ServerHopNoFruit", false)

-- Teleport
setDefault("SelectedIsland", "")
setDefault("SelectedNPC", "")
setDefault("SelectedBossTP", "")
-- ====== GIỮ TRẠNG THÁI KHI CHUYỂN SERVER ======
local teleportState = RuntimeEnv.HAOTOOL_TELEPORT_STATE
RuntimeEnv.HAOTOOL_TELEPORT_STATE = nil

if type(teleportState) == "table" then
    for key, value in pairs(teleportState) do
        _G[key] = value
    end
end

local TELEPORT_STATE_KEYS = {
    "AutoFarmLevel", "AutoFarmMastery", "MasteryWeapon",
    "AutoFarmBoss", "SelectedBoss", "AutoFarmSeaBeast",
    "AutoFarmObs", "AutoFarmBone", "AutoFarmFragment", "AutoFarmChest",
    "SelectWeapon", "FarmMethod", "SelectedMob",
    "BringMob", "BringRadius", "FarmHeight", "FarmDistance",
    "HoldFarmPosition", "FreezeTarget", "AttackDelay", "BackgroundAttack", "HitboxSize",
    "SafetyMode", "AutoSkill", "SkillCooldown",
    "AutoRaid", "AutoRaidFarm", "AutoAwakening", "RaidChip",
    "AutoHaki", "AutoKen", "AutoObsV2", "AutoDodge",
    "AutoFruitFinder", "AutoCollectFruit", "FruitESP", "AutoGachaFruit",
    "ESPPlayer", "ESPMob", "ESPBoss", "ESPChest", "ESPFlower",
    "ESPIsland", "ESPDistance", "ESPTeamCheck",
    "WalkSpeedHack", "WalkSpeedVal", "JumpPowerHack", "JumpPowerVal",
    "InfiniteJump", "InfiniteEnergy", "AntiAFK",
    "AutoStats", "StatToUpgrade", "ServerHopNoFruit",
    "SelectedIsland", "SelectedNPC", "SelectedBossTP",
}

local TELEPORT_FOLDER = "HaoToolHub"
local TELEPORT_STATE_FILE = TELEPORT_FOLDER .. "/session.json"
local TELEPORT_SCRIPT_FILE = TELEPORT_FOLDER .. "/autoload.lua"
local lastTeleportStateJson = ""

local function collectTeleportState()
    local state = {}
    for _, key in ipairs(TELEPORT_STATE_KEYS) do
        local value = _G[key]
        local valueType = type(value)
        if valueType == "boolean" or valueType == "number" or valueType == "string" then
            state[key] = value
        end
    end
    return state
end

local function ensureTeleportFolder()
    pcall(function()
        if makefolder and (not isfolder or not isfolder(TELEPORT_FOLDER)) then
            makefolder(TELEPORT_FOLDER)
        end
    end)
end

local function saveTeleportState()
    if type(writefile) ~= "function" then return false end
    ensureTeleportFolder()

    local ok, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(collectTeleportState())
    end)
    if not ok or encoded == lastTeleportStateJson then return ok end

    local saved = pcall(function()
        writefile(TELEPORT_STATE_FILE, encoded)
    end)
    if saved then lastTeleportStateJson = encoded end
    return saved
end

local function setupTeleportReload()
    local queueTeleport = queue_on_teleport or queueonteleport
        or (syn and syn.queue_on_teleport)
    if type(queueTeleport) ~= "function" or type(readfile) ~= "function"
        or RuntimeEnv.HAOTOOL_SOURCE_SAVED ~= true then
        return false
    end
    if RuntimeEnv.HAOTOOL_TELEPORT_QUEUED then return true end

    local queuedLoader = [==[
local env = getgenv and getgenv() or _G
env.HAOTOOL_RUNNING = nil
env.HAOTOOL_TOGGLE_MENU = nil
env.HAOTOOL_TELEPORT_QUEUED = nil
env.HAOTOOL_SOURCE_SAVED = true
pcall(function()
    env.HAOTOOL_TELEPORT_STATE = game:GetService("HttpService"):JSONDecode(
        readfile("HaoToolHub/session.json")
    )
end)
local source = readfile("HaoToolHub/autoload.lua")
local runner, compileError = loadstring(source)
if runner then
    local ok, runError = pcall(runner)
    if not ok then
        env.HAOTOOL_RUNNING = nil
        warn("[HAOTOOL] Auto reload lỗi: " .. tostring(runError))
    end
else
    warn("[HAOTOOL] Không biên dịch được auto reload: " .. tostring(compileError))
end
    ]==]

    local queued = pcall(queueTeleport, queuedLoader)
    RuntimeEnv.HAOTOOL_TELEPORT_QUEUED = queued
    return queued
end

local teleportReloadReady = setupTeleportReload()
saveTeleportState()
pcall(function()
    Player.OnTeleport:Connect(function()
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
        saveTeleportState()
    end)
end)

task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.25)
        saveTeleportState()
    end
end)


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
-- PHẦN 4: HÀM CỐT LÕI (CORE FUNCTIONS)
------------------------------------------------------------

-- ====== Noclip ======
local noclipConn = nil
local noclipOriginal = setmetatable({}, {__mode = "k"})
local function restoreCharacterCollision()
    for part, canCollide in pairs(noclipOriginal) do
        pcall(function()
            if part and part.Parent then part.CanCollide = canCollide end
        end)
        noclipOriginal[part] = nil
    end
end

local function setNoclip(state)
    if state then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
                runFeature("Noclip", function()
                    local char = Player.Character
                    if not char then return end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if noclipOriginal[part] == nil then
                                noclipOriginal[part] = part.CanCollide
                            end
                            part.CanCollide = false
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
        restoreCharacterCollision()
    end
end

-- ====== Trạng thái farm: tách di chuyển và chiến đấu ======
local currentTween = nil
local movementSerial = 0
local activeFarmTarget = nil
local farmState = "idle"
local lastAttackTime = 0
local lastCombatMaintenance = 0
local lastEquipCheck = 0
local lastPreparedTarget = nil
local restoreFrozenMobs = function() end
local userPointerActive = false
local sendingVirtualAttack = false
local manualPointerPauseUntil = 0

-- Chỉ một chế độ được quyền di chuyển nhân vật tại một thời điểm.
local function getActiveMovementMode()
    if _G.AutoFarmLevel then return "level" end
    if _G.AutoFarmBoss then return "boss" end
    if _G.AutoFarmMastery then return "mastery" end
    if _G.AutoFarmSeaBeast then return "sea_beast" end
    if _G.AutoFarmBone then return "bone" end
    if _G.AutoFarmFragment then return "fragment" end
    if _G.AutoRaid and _G.AutoRaidFarm then return "raid" end
    if _G.AutoFarmChest then return "chest" end
    if _G.AutoCollectFruit then return "fruit" end
    return nil
end

local function modeCanMove(mode)
    return getActiveMovementMode() == mode
end

local function isPointerInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

UserInputService.InputBegan:Connect(function(input)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if sendingVirtualAttack or not isPointerInput(input) then return end
    userPointerActive = true
end)

UserInputService.InputEnded:Connect(function(input)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if sendingVirtualAttack or not isPointerInput(input) then return end
    userPointerActive = false
    manualPointerPauseUntil = os.clock() + 0.18
end)

local function clearFarmTarget()
    local wasAttacking = farmState == "attacking"
    activeFarmTarget = nil
    if wasAttacking then
        farmState = "idle"
        setNoclip(false)
    end

    local char = Player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function stopFarmMovement()
    movementSerial = movementSerial + 1
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

    movementSerial = movementSerial + 1
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
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
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
    movementSerial = movementSerial + 1
    local requestId = movementSerial
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
        setNoclip(false)
        return true
    end

    local speed = 300
    setNoclip(true)
    local tween = TweenService:Create(
        rootPart,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    currentTween = tween
    tween:Play()
    tween.Completed:Wait()

    if requestId ~= movementSerial then return false end
    if currentTween == tween then currentTween = nil end
    if farmState == "moving" then farmState = "idle" end
    setNoclip(false)

    return (rootPart.Position - targetCFrame.Position).Magnitude <= 25
end

-- ====== Haki (Buso & Observation) ======
local lastBusoAttempt = 0
local lastObservationAttempt = 0

local function activateObservation(force)
    local now = os.clock()
    if not force and now - lastObservationAttempt < 2 then return false end
    if userPointerActive or UserInputService:GetFocusedTextBox() then return false end
    lastObservationAttempt = now

    return runFeature("Observation", function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local ken = remotes and remotes:FindFirstChild("Ken")
        if ken and ken:IsA("RemoteEvent") then
            ken:FireServer(true)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

local function checkHaki()
    local char = Player.Character
    if not char then return end
    local now = os.clock()

    if _G.AutoHaki and not char:FindFirstChild("HasBuso") and now - lastBusoAttempt >= 1 then
        lastBusoAttempt = now
        runFeature("Buso Haki", function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end)
    end

    if _G.AutoKen or _G.AutoObsV2 then
        activateObservation(false)
    end
end

-- Hệ thống đánh tự động ngầm 100% (Không click màn hình, trúng 100% sát thương)
local function attack()
    local now = os.clock()
    local delay = math.clamp(tonumber(_G.AttackDelay) or 0.05, 0.01, 0.50)
    if _G.SafetyMode then
        delay = math.max(delay, 0.05)
    end
    if now - lastAttackTime < delay then return end
    lastAttackTime = now

    checkHaki()

    local char = Player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- 1. Kích hoạt Tool ngầm
    pcall(function() tool:Activate() end)

    -- 2. Gửi click ảo VirtualUser kết hợp Camera CFrame (không di chuyển chuột)
    pcall(function()
        if VirtualUser then
            local cam = workspace.CurrentCamera
            local cf = cam and cam.CFrame or CFrame.new()
            VirtualUser:ClickButton1(Vector2.new(500, 500), cf)
            VirtualUser:Button1Down(Vector2.zero, cf)
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.zero, cf)
        end
    end)

    -- 3. Gửi Remote đánh ngầm Blox Fruits
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if net then
            local regAttack = net:FindFirstChild("RegisterAttack") or net:FindFirstChild("RE/RegisterAttack")
            if regAttack and regAttack:IsA("RemoteEvent") then regAttack:FireServer() end
        end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commE = remotes and remotes:FindFirstChild("CommE")
        if commE and commE:IsA("RemoteEvent") then commE:FireServer("weaponAttack") end
        local rigController = ReplicatedStorage:FindFirstChild("RigControllerEvent")
        if rigController and rigController:IsA("RemoteEvent") then rigController:FireServer("weaponAttack") end
    end)
end
-- ====== Auto Skill (dùng Z, X, C, V) ======
local lastSkillTime = 0
local skillSequenceBusy = false
local function useSkills(force)
    if not force and not _G.AutoSkill then return end
    if skillSequenceBusy or userPointerActive or os.clock() < manualPointerPauseUntil
        or UserInputService:GetFocusedTextBox() then return end

    local cooldown = math.max(0.5, tonumber(_G.SkillCooldown) or 1.5)
    if os.clock() - lastSkillTime < cooldown then return end
    lastSkillTime = os.clock()
    skillSequenceBusy = true

    task.spawn(function()
        runFeature("Auto Skill", function()
            local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
            for _, key in ipairs(keys) do
                if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then break end
                if userPointerActive or UserInputService:GetFocusedTextBox() then break end
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
                task.wait(0.12)
            end
        end)
        skillSequenceBusy = false
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

-- Chuẩn hóa tên model như "Monkey [Lv. 14]" hoặc "The Gorilla King [Boss]".
local function normalizeMobName(name)
    local normalized = string.lower(tostring(name or ""))
    normalized = normalized:gsub("%s*%[lv%.?%s*%d+%]%s*", "")
    normalized = normalized:gsub("%s*%[raid boss%]%s*", "")
    normalized = normalized:gsub("%s*%[boss%]%s*", "")
    normalized = normalized:gsub("^the%s+", "")
    normalized = normalized:gsub("^%s+", ""):gsub("%s+$", "")
    normalized = normalized:gsub("%s+", " ")
    return normalized
end

local function mobNameMatches(actualName, wantedName)
    if not actualName or not wantedName or wantedName == "" then return false end
    return normalizeMobName(actualName) == normalizeMobName(wantedName)
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
            PlatformStand = humanoid.PlatformStand,
            Anchored = rootPart.Anchored,
            CanCollide = rootPart.CanCollide,
            Size = rootPart.Size,
        }
    end

    rootPart.CanCollide = false
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    -- Nối dài Hitbox chiều cao lên phía trên để nhân vật ở độ cao 12+ vẫn chạm Hitbox và đánh trúng 100%
    local farmHeight = math.abs(tonumber(_G.FarmHeight) or 12)
    local hitboxLimit = _G.SafetyMode and 30 or 60
    local hitboxSize = math.clamp(tonumber(_G.HitboxSize) or 14, 4, hitboxLimit)
    local verticalSize = math.clamp(farmHeight * 2.5 + 20, hitboxSize, 90)

    rootPart.Size = Vector3.new(hitboxSize, verticalSize, hitboxSize)

    if _G.FreezeTarget then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
        rootPart.Anchored = true
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
                    humanoid.PlatformStand = state.PlatformStand
                end
                if rootPart then
                    rootPart.CanCollide = state.CanCollide
                    rootPart.Anchored = state.Anchored
                    rootPart.Size = state.Size
                end
            end
        end)
        frozenMobStates[mob] = nil
    end
end

local function bringMobsNear(targetName, centerCFrame)
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return end
        grantSimulationRadius()

        local radiusLimit = _G.SafetyMode and 350 or 1000
        local radius = math.clamp(tonumber(_G.BringRadius) or 300, 50, radiusLimit)
        for _, mob in pairs(enemies:GetChildren()) do
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            local rootPart = mob:FindFirstChild("HumanoidRootPart")

            if mobNameMatches(mob.Name, targetName)
                and humanoid and humanoid.Health > 0 and rootPart then
                local distance = (rootPart.Position - centerCFrame.Position).Magnitude
                if distance <= radius or mob == lastPreparedTarget then
                    freezeMob(mob)
                    -- Giữ quái đứng im 100% tại đúng 1 vị trí cố định trên mặt đất (không bị trôi hay di chuyển)
                    rootPart.CFrame = centerCFrame
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function engageTarget(target, targetName, weaponType, forceSkills)
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

    local now = os.clock()
    if target ~= lastPreparedTarget or now - lastCombatMaintenance >= 0.15 then
        grantSimulationRadius()
        freezeMob(target)
        -- Sử dụng vị trí mặt đất cố định của quái chính làm tâm gom quái
        local groundCFrame = CFrame.new(targetRoot.Position)
        bringMobsNear(targetName or target.Name, groundCFrame)
        lastPreparedTarget = target
        lastCombatMaintenance = now
    end

    if now - lastEquipCheck >= 0.35 then
        equipWeapon(weaponType or _G.SelectWeapon)
        lastEquipCheck = now
    end

    attack()
    useSkills(forceSkills)
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
local function getQuestGui()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("Main")
    return mainGui and mainGui:FindFirstChild("Quest")
end

local function hasActiveQuest()
    local questGui = getQuestGui()
    return questGui ~= nil and questGui.Visible == true
end

local function getActiveQuestText()
    local questGui = getQuestGui()
    if not questGui or not questGui.Visible then return "" end

    local parts = {}
    for _, item in ipairs(questGui:GetDescendants()) do
        if (item:IsA("TextLabel") or item:IsA("TextButton")) and item.Text ~= "" then
            table.insert(parts, string.lower(item.Text))
        end
    end
    return table.concat(parts, " ")
end

local acceptedQuestSignature = nil
local function questSignature(quest)
    if not quest then return "" end
    return tostring(quest.QuestName) .. ":" .. tostring(quest.QuestNumber)
end

local function abandonQuest()
    runFeature("Bỏ nhiệm vụ cũ", function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
    end)
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
        if hasActiveQuest() then
            acceptedQuestSignature = questSignature(quest)
            return true
        end

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

    local active = hasActiveQuest()
    if active then acceptedQuestSignature = questSignature(quest) end
    return active
end

-- ====== Tìm quái theo tên (gần nhất) ======
local function isFruitObject(obj)
    if not obj then return false end
    local lowerName = string.lower(obj.Name)
    local hasFruitName = string.find(lowerName, "fruit", 1, true) ~= nil or string.find(lowerName, "trái", 1, true) ~= nil
    if not hasFruitName then return false end

    if obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart") then
        local handle = obj:FindFirstChild("Handle") or (obj:IsA("BasePart") and obj)
        if handle and handle:IsA("BasePart") then
            return true
        end
    end
    return false
end

local function getSpawnedFruits()
    local fruits = {}
    local seen = {}
    local containers = {
        workspace,
        workspace:FindFirstChild("Fruit"),
        workspace:FindFirstChild("Fruits"),
        workspace:FindFirstChild("SpawnedFruits"),
    }
    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if isFruitObject(obj) and not seen[obj] then
                    seen[obj] = true
                    table.insert(fruits, obj)
                end
            end
        end
    end
    return fruits
end

local function findNearestFruit()
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local closest, closestDistance = nil, math.huge
    for _, fruit in ipairs(getSpawnedFruits()) do
        local handle = fruit:FindFirstChild("Handle")
        local distance = rootPart and (handle.Position - rootPart.Position).Magnitude or 0
        if distance < closestDistance then
            closest, closestDistance = fruit, distance
        end
    end
    return closest, closestDistance
end

local function touchFruit(fruit)
    local handle = fruit and fruit:FindFirstChild("Handle")
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not handle or not rootPart then return false end

    if type(firetouchinterest) == "function" then
        return runFeature("Nhặt trái", function()
            firetouchinterest(rootPart, handle, 0)
            task.wait(0.08)
            firetouchinterest(rootPart, handle, 1)
        end)
    end

    -- Fallback chuẩn: đặt nhân vật chạm Handle để Touched được gửi lên máy chủ.
    rootPart.CFrame = handle.CFrame
    rootPart.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.25)
    return fruit.Parent ~= workspace
end

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
findBoss = function(bossName)
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
    local bosses, known = {}, {}
    local bossTable = WorldSea == 1 and BossesSea1
        or WorldSea == 2 and BossesSea2 or BossesSea3

    local function addBoss(name)
        local clean = normalizeMobName(name)
        if clean ~= "" and not known[clean] then
            known[clean] = true
            table.insert(bosses, clean:gsub("(%a)([%w']*)", function(a, b)
                return string.upper(a) .. b
            end))
        end
    end

    for _, boss in ipairs(bossTable) do addBoss(boss.Name) end
    local containers = {workspace:FindFirstChild("Enemies"), ReplicatedStorage:FindFirstChild("Enemies"), ReplicatedStorage}
    for _, container in ipairs(containers) do
        if container then
            for _, mob in ipairs(container:GetChildren()) do
                local lowerName = string.lower(mob.Name)
                if string.find(lowerName, "[boss]", 1, true)
                    or string.find(lowerName, "[raid boss]", 1, true) then
                    addBoss(mob.Name)
                end
            end
        end
    end
    table.sort(bosses)
    return bosses
end

-- ====== Tìm boss data theo tên ======
local function getBossData(bossName)
    local tables = {BossesSea1, BossesSea2, BossesSea3}
    local idx = math.clamp(WorldSea, 1, 3)
    for _, b in ipairs(tables[idx]) do
        if mobNameMatches(b.Name, bossName) then return b end
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

-- ====== Raid helpers: mua chip rồi bấm nút raid thật trên bản đồ ======
local lastRaidStartAttempt = 0
local lastRaidCapabilityWarning = 0

local function isInRaid()
    local mainGui = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("Main")
    local raidTimer = mainGui and mainGui:FindFirstChild("RaidTimer", true)
    if raidTimer and raidTimer.Visible then return true end

    local origin = workspace:FindFirstChild("_WorldOrigin")
    local locations = origin and origin:FindFirstChild("Locations")
    if locations then
        for index = 1, 5 do
            if locations:FindFirstChild("Island " .. index) then return true end
        end
    end
    return false
end

local function hasRaidChip()
    local function containsChip(container)
        if not container then return false end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and string.find(string.lower(item.Name), "microchip", 1, true) then
                return true
            end
        end
        return false
    end
    return containsChip(Player:FindFirstChild("Backpack")) or containsChip(Player.Character)
end

local function findRaidStartDetector()
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("ClickDetector") then
            local fullName = string.lower(item:GetFullName())
            if string.find(fullName, "raidsummon", 1, true) then
                return item
            end
        end
    end
    return nil
end

local function purchaseRaidChip()
    if hasRaidChip() then return true end
    local ok = runFeature("Mua chip raid", function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Check")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.RaidChip)
    end)
    if ok then task.wait(1) end
    return hasRaidChip()
end

local function startSelectedRaid()
    local now = os.clock()
    if isInRaid() then return false end
    local level = getPlayerLevel()
    if WorldSea == 1 or level < 1100 then
        if now - lastRaidCapabilityWarning >= 15 then
            lastRaidCapabilityWarning = now
            notify("Raid chưa mở khóa", "Cần đạt cấp 1100 và ở Sea 2 hoặc Sea 3 để tự mua chip raid.", 6)
        end
        return false
    end
    if now - lastRaidStartAttempt < 8 then return false end
    lastRaidStartAttempt = now

    if not purchaseRaidChip() then return false end
    local detector = findRaidStartDetector()
    if detector and type(fireclickdetector) == "function" then
        local ok = runFeature("Bắt đầu raid", function()
            fireclickdetector(detector)
        end)
        if ok then task.wait(2) end
        return ok
    end

    if now - lastRaidCapabilityWarning >= 15 then
        lastRaidCapabilityWarning = now
        notify("Raid cần thao tác", "Đã mua chip nhưng executor không bấm được nút raid; hãy đứng tại phòng raid và bấm nút một lần.", 6)
    end
    return false
end

------------------------------------------------------------
-- PHẦN 5: HỆ THỐNG ESP
------------------------------------------------------------

local playerGui = Player:WaitForChild("PlayerGui")
local oldESPFolder = playerGui:FindFirstChild("HAOTOOL_ESP") or CoreGui:FindFirstChild("HAOTOOL_ESP")
if oldESPFolder then oldESPFolder:Destroy() end
for _, obj in ipairs(workspace:GetChildren()) do
    if string.sub(obj.Name, 1, 15) == "HAOTOOL_ISLAND_" then obj:Destroy() end
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "HAOTOOL_ESP"
ESPFolder.Parent = playerGui

local espRegistry = setmetatable({}, {__mode = "k"})
local espSerial = 0
local islandParts = {}

local function destroyESPEntry(target)
    local entry = espRegistry[target]
    if not entry then return end
    if entry.Billboard then entry.Billboard:Destroy() end
    if entry.Highlight then entry.Highlight:Destroy() end
    espRegistry[target] = nil
end

local function createESP(target, kind, color, baseText)
    if not target or not target.Parent then return nil end
    local adornee = target:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("Handle")
        or (target:IsA("BasePart") and target)
    if not adornee or not adornee:IsA("BasePart") then return nil end

    local entry = espRegistry[target]
    if not entry then
        espSerial = espSerial + 1
        local highlight = Instance.new("Highlight")
        highlight.Name = "HAOTOOL_HL_" .. espSerial
        highlight.FillTransparency = 0.50
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.10
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = target
        highlight.Parent = ESPFolder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HAOTOOL_BB_" .. espSerial
        billboard.Size = UDim2.new(0, 230, 0, 52)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = adornee
        billboard.Parent = ESPFolder

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Parent = billboard

        entry = {
            Billboard = billboard,
            Highlight = highlight,
            Adornee = adornee,
            Kind = kind,
        }
        espRegistry[target] = entry
    end

    entry.Kind = kind
    entry.Adornee = adornee
    entry.Billboard.Adornee = adornee
    entry.Highlight.Adornee = target
    entry.Highlight.FillColor = color
    local label = entry.Billboard:FindFirstChild("Label")
    if label then
        local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local distance = rootPart and math.floor((rootPart.Position - adornee.Position).Magnitude) or 0
        label.TextColor3 = color
        label.Text = tostring(baseText) .. "  [" .. distance .. "m]"
    end
    return entry
end

local function clearESPKind(kind)
    local targets = {}
    for target, entry in pairs(espRegistry) do
        if entry.Kind == kind then table.insert(targets, target) end
    end
    for _, target in ipairs(targets) do destroyESPEntry(target) end
end

local function clearIslandESP()
    for _, part in ipairs(islandParts) do
        if part and part.Parent then part:Destroy() end
    end
    islandParts = {}
    for _, child in ipairs(ESPFolder:GetChildren()) do
        if child:GetAttribute("HAOTOOL_KIND") == "island" then child:Destroy() end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if string.sub(obj.Name, 1, 15) == "HAOTOOL_ISLAND_" then obj:Destroy() end
    end
end

local function setIslandESP(enabled)
    clearIslandESP()
    if not enabled then return end

    for name, position in pairs(getSeaIslands()) do
        local part = Instance.new("Part")
        part.Name = "HAOTOOL_ISLAND_" .. name
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Transparency = 1
        part.Position = position
        part.Size = Vector3.new(1, 1, 1)
        part.Parent = workspace
        table.insert(islandParts, part)

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HAOTOOL_ISLAND_BB"
        billboard:SetAttribute("HAOTOOL_KIND", "island")
        billboard.Size = UDim2.new(0, 220, 0, 36)
        billboard.StudsOffset = Vector3.new(0, 50, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = part
        billboard.Parent = ESPFolder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "🏝️ " .. name
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.Parent = billboard
    end
end

local function clearAllESP()
    local targets = {}
    for target in pairs(espRegistry) do table.insert(targets, target) end
    for _, target in ipairs(targets) do destroyESPEntry(target) end
    clearIslandESP()
end

local function pruneESP(seen)
    local targets = {}
    for target, entry in pairs(espRegistry) do
        if not target.Parent or not entry.Adornee or not entry.Adornee.Parent
            or not seen[target] then
            table.insert(targets, target)
        end
    end
    for _, target in ipairs(targets) do destroyESPEntry(target) end
end
------------------------------------------------------------
-- PHẦN 6: VÒNG LẶP NỀN (BACKGROUND LOOPS)
------------------------------------------------------------

-- ====== LOOP 1: Auto Farm Level (Tự động nhận Quest Boss khi có Boss) ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.03)

        if _G.AutoFarmLevel and modeCanMove("level") then
            runFeature("Auto Farm Level", function()
                local level = getPlayerLevel()
                local normalQuest = getQuestData(level)
                if not normalQuest then return end

                local questToUse = normalQuest
                local targetMob = nil
                local isBossTarget = false

                -- Tự động phát hiện Boss cùng tầm level đang có mặt trên server
                local bossQuest, bossMob = getAvailableBossQuest(level)
                if bossQuest and bossMob then
                    questToUse = bossQuest
                    targetMob = bossMob
                    isBossTarget = true
                end

                if _G.FarmMethod == "Quest" and hasActiveQuest() then
                    if acceptedQuestSignature ~= nil and acceptedQuestSignature ~= questSignature(questToUse) then
                        abandonQuest()
                        acceptedQuestSignature = nil
                        task.wait(0.35)
                        return
                    end
                end

                if not hasActiveQuest() then
                    startQuest(questToUse)
                    return
                end

                if not isBossTarget then
                    if _G.FarmMethod == "Quest" then
                        targetMob = findMob(questToUse.MobName, false)
                    elseif _G.FarmMethod == "Nearest" then
                        targetMob = findMob("", true)
                    elseif _G.FarmMethod == "Selected Mob" then
                        targetMob = findMob(_G.SelectedMob, false)
                    else
                        targetMob = findMob(questToUse.MobName, false)
                    end
                end

                if not targetMob then
                    clearFarmTarget()
                    if ensureQuestArea(questToUse) then
                        toTarget(CFrame.new(questToUse.MobPosition))
                    end
                    return
                end

                local bringName = questToUse.MobName
                if not isBossTarget then
                    if _G.FarmMethod == "Nearest" then
                        bringName = targetMob.Name
                    elseif _G.FarmMethod == "Selected Mob" then
                        bringName = _G.SelectedMob
                    end
                end

                engageTarget(targetMob, bringName, _G.SelectWeapon)
            end)
        end
    end
end)
-- ====== LOOP 2: Auto Farm Mastery ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.03)

        if _G.AutoFarmMastery and modeCanMove("mastery") then
            runFeature("Auto Farm Mastery", function()
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
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.03)

        if _G.AutoFarmBoss and modeCanMove("boss") then
            runFeature("Auto Farm Boss", function()
                local boss = findBoss(_G.SelectedBoss)
                if boss then
                    engageTarget(boss, boss.Name, _G.SelectWeapon)
                    return
                end

                local bossData = getBossData(_G.SelectedBoss)
                clearFarmTarget()
                if bossData then
                    toTarget(CFrame.new(bossData.Position))
                    task.wait(0.5)
                end
            end)
        end
    end
end)
-- ====== LOOP 4: Auto Farm Sea Beast ======
local lastSeaBeastWarning = 0
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.05)

        if _G.AutoFarmSeaBeast and modeCanMove("sea_beast") then
            runFeature("Auto Sea Beast", function()
                if WorldSea == 1 then
                    if os.clock() - lastSeaBeastWarning >= 15 then
                        lastSeaBeastWarning = os.clock()
                        notify("Sea Beast", "Sea Beast chỉ xuất hiện tại vùng biển Sea 2 và Sea 3.", 5)
                    end
                    return
                end
                local candidates = {}
                for _, obj in ipairs(workspace:GetChildren()) do
                    table.insert(candidates, obj)
                    if obj:IsA("Folder") and string.find(string.lower(obj.Name), "sea", 1, true) then
                        for _, child in ipairs(obj:GetChildren()) do table.insert(candidates, child) end
                    end
                end

                for _, obj in ipairs(candidates) do
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local rootPart = obj:FindFirstChild("HumanoidRootPart")
                    local lowerName = string.lower(obj.Name)
                    if humanoid and humanoid.Health > 0 and rootPart
                        and (string.find(lowerName, "sea beast", 1, true)
                            or string.find(lowerName, "seabeast", 1, true)) then
                        engageTarget(obj, obj.Name, _G.SelectWeapon, true)
                        return
                    end
                end
                clearFarmTarget()
            end)
        end
    end
end)

-- Hoàn nguyên mục tiêu cũ khi đổi chế độ, tránh hai chế độ dùng chung tween/noclip.
local supervisedMovementMode = nil
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.15)
        local mode = getActiveMovementMode()
        if mode ~= supervisedMovementMode then
            if farmState ~= "idle" or activeFarmTarget or currentTween then
                stopFarmMovement()
            end
            supervisedMovementMode = mode
        elseif mode == nil and (farmState ~= "idle" or activeFarmTarget or currentTween) then
            stopFarmMovement()
        end
    end
end)
-- ====== LOOP 5: Duy trì Haki / Observation ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.75)
        if _G.AutoHaki or _G.AutoKen or _G.AutoObsV2 then
            checkHaki()
        end
        if _G.AutoFarmObs then activateObservation(false) end
    end
end)

-- ====== LOOP 6: Auto Farm Bone ======
local BoneMobNames = {
    ["reborn skeleton"] = true,
    ["living zombie"] = true,
    ["demonic soul"] = true,
    ["posessed mummy"] = true,
    ["evil wraith"] = true,
}
local lastBoneWarning = 0

task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.08)
        if _G.AutoFarmBone and modeCanMove("bone") then
            runFeature("Auto Farm Bone", function()
                if WorldSea ~= 3 then
                    if os.clock() - lastBoneWarning >= 12 then
                        lastBoneWarning = os.clock()
                        notify("Farm Bone", "Bone chỉ farm ổn định tại Haunted Castle ở Sea 3.", 5)
                    end
                    return
                end

                local target = nil
                local nearest = math.huge
                local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local humanoid = mob:FindFirstChildOfClass("Humanoid")
                        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                        if BoneMobNames[normalizeMobName(mob.Name)] and humanoid
                            and humanoid.Health > 0 and mobRoot then
                            local distance = rootPart and (mobRoot.Position - rootPart.Position).Magnitude or 0
                            if distance < nearest then
                                nearest = distance
                                target = mob
                            end
                        end
                    end
                end

                if target then
                    engageTarget(target, target.Name, _G.SelectWeapon)
                else
                    clearFarmTarget()
                    toTarget(CFrame.new(IslandsSea3["Haunted Castle"]))
                end
            end)
        end
    end
end)

-- ====== LOOP 7: Auto Fruit Finder & Collector ======
local announcedFruits = setmetatable({}, {__mode = "k"})
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(1)
        if _G.AutoFruitFinder or _G.AutoCollectFruit then
            runFeature("Theo dõi trái", function()
                local fruits = getSpawnedFruits()
                local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

                if _G.AutoFruitFinder then
                    for _, fruit in ipairs(fruits) do
                        if not announcedFruits[fruit] then
                            announcedFruits[fruit] = true
                            local distance = rootPart
                                and math.floor((fruit.Handle.Position - rootPart.Position).Magnitude) or 0
                            notify("🍎 Phát hiện trái", fruit.Name .. " [" .. distance .. "m]", 6)
                        end
                    end
                end

                if _G.AutoCollectFruit and modeCanMove("fruit") then
                    local fruit = findNearestFruit()
                    if fruit and fruit:FindFirstChild("Handle") then
                        toTarget(fruit.Handle.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.15)
                        touchFruit(fruit)
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 8: Auto Raid / Farm Fragment ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        local movementMode = getActiveMovementMode()
        local wantsRaid = (_G.AutoFarmFragment and movementMode == "fragment")
            or (_G.AutoRaid and (movementMode == nil or movementMode == "raid"))
        local wantsCombat = (_G.AutoRaidFarm and movementMode == "raid")
            or (_G.AutoFarmFragment and movementMode == "fragment")
        task.wait((wantsRaid and wantsCombat) and 0.05 or 0.8)

        if wantsRaid then
            runFeature("Auto Raid", function()
                if not isInRaid() then
                    startSelectedRaid()
                    return
                end

                if wantsCombat then
                    local targetMob = findMob("", true)
                    if targetMob then
                        engageTarget(targetMob, targetMob.Name, _G.SelectWeapon)
                    else
                        clearFarmTarget()
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 9: Auto Awakening ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(5)
        if _G.AutoAwakening then
            runFeature("Auto Awakening", function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakener", "Check")
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakener", "Awaken")
            end)
        end
    end
end)

-- ====== LOOP 10: Auto Stats ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.3)
        if _G.AutoStats then
            runFeature("Auto Stats", function()
                local data = getPlayerData()
                local pointsObj = data and data:FindFirstChild("Points")
                if pointsObj and pointsObj.Value > 0 then
                    local statName = _G.StatToUpgrade == "Blox Fruit"
                        and "Demon Fruit" or _G.StatToUpgrade
                    ReplicatedStorage.Remotes.CommF_:InvokeServer(
                        "AddPoint", statName, math.min(pointsObj.Value, 3)
                    )
                end
            end)
        end
    end
end)

-- ====== LOOP 11: Auto Farm Chest ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.5)
        if _G.AutoFarmChest and modeCanMove("chest") then
            runFeature("Auto Farm Chest", function()
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
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(30)
        if _G.AutoGachaFruit then
            runFeature("Auto Gacha", function()
                local res = nil
                pcall(function()
                    res = ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
                end)
                local msg = tostring(res or "Đã gửi yêu cầu mua trái ngẫu nhiên.")
                notify("🎰 Gacha Fruit", msg, 6)
            end)
        end
    end
end)

-- ====== LOOP 13: Speed / Jump / Energy ======
local humanoidDefaults = setmetatable({}, {__mode = "k"})
local function rememberHumanoidDefaults(humanoid)
    if humanoid and not humanoidDefaults[humanoid] then
        humanoidDefaults[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
        }
    end
end

local function restoreMovementStats(statName)
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local defaults = humanoid and humanoidDefaults[humanoid]
    if not humanoid or not defaults then return end
    if statName == nil or statName == "WalkSpeed" then humanoid.WalkSpeed = defaults.WalkSpeed end
    if statName == nil or statName == "JumpPower" then humanoid.JumpPower = defaults.JumpPower end
end

task.spawn(function()
    RunService.RenderStepped:Connect(function()
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
        runFeature("Di chuyển", function()
            local char = Player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            rememberHumanoidDefaults(humanoid)

            if _G.WalkSpeedHack then humanoid.WalkSpeed = tonumber(_G.WalkSpeedVal) or 50 end
            if _G.JumpPowerHack then humanoid.JumpPower = tonumber(_G.JumpPowerVal) or 100 end

            if _G.InfiniteEnergy then
                local energy = char:FindFirstChild("Energy")
                    or Player:FindFirstChild("Energy")
                if energy and (energy:IsA("NumberValue") or energy:IsA("IntValue")) then
                    energy.Value = math.max(energy.Value, 5000)
                end
            end
        end)
    end)
end)

-- ====== LOOP 14: Infinite Jump ======
UserInputService.JumpRequest:Connect(function()
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if _G.InfiniteJump then
        pcall(function()
            local char = Player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- ====== LOOP 15: Anti-AFK ======
Player.Idled:Connect(function()
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if _G.AntiAFK then
        runFeature("Anti AFK", function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end)
    end
end)

-- ====== LOOP 16: ESP Update Loop ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(1.5)
        runFeature("ESP", function()
            local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            local seen = {}
            local maxDistance = math.max(100, tonumber(_G.ESPDistance) or 2000)

            if _G.ESPPlayer then
                for _, plr in ipairs(Players:GetPlayers()) do
                    local char = plr.Character
                    local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    local sameTeam = _G.ESPTeamCheck and plr.Team ~= nil and plr.Team == Player.Team
                    if plr ~= Player and targetRoot and humanoid and humanoid.Health > 0 and not sameTeam
                        and (targetRoot.Position - rootPart.Position).Magnitude <= maxDistance then
                        seen[char] = true
                        createESP(char, "player", _G.ESPPlayerColor,
                            plr.DisplayName .. "  HP " .. math.floor(humanoid.Health))
                    end
                end
            end

            local enemies = workspace:FindFirstChild("Enemies")
            if (_G.ESPMob or _G.ESPBoss) and enemies then
                for _, mob in ipairs(enemies:GetChildren()) do
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    local targetRoot = mob:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and targetRoot
                        and (targetRoot.Position - rootPart.Position).Magnitude <= maxDistance then
                        local lowerName = string.lower(mob.Name)
                        local isBoss = string.find(lowerName, "[boss]", 1, true) ~= nil
                            or string.find(lowerName, "[raid boss]", 1, true) ~= nil
                            or getBossData(mob.Name) ~= nil
                        if isBoss and _G.ESPBoss then
                            seen[mob] = true
                            createESP(mob, "boss", _G.ESPBossColor,
                                "⭐ " .. normalizeMobName(mob.Name) .. "  HP " .. math.floor(humanoid.Health))
                        elseif not isBoss and _G.ESPMob then
                            seen[mob] = true
                            createESP(mob, "mob", _G.ESPMobColor, normalizeMobName(mob.Name))
                        end
                    end
                end
            end

            if _G.FruitESP then
                for _, fruit in ipairs(getSpawnedFruits()) do
                    local handle = fruit:FindFirstChild("Handle") or (fruit:IsA("BasePart") and fruit) or fruit:FindFirstChildOfClass("BasePart")
                    if handle and (handle.Position - rootPart.Position).Magnitude <= maxDistance then
                        seen[fruit] = true
                        createESP(fruit, "fruit", _G.ESPFruitColor, "🍎 " .. fruit.Name)
                    end
                end
            end

            if _G.ESPChest or _G.ESPFlower then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Position - rootPart.Position).Magnitude <= maxDistance then
                        local lowerName = string.lower(obj.Name)
                        if _G.ESPChest and string.find(lowerName, "chest", 1, true) then
                            seen[obj] = true
                            createESP(obj, "chest", _G.ESPChestColor, "📦 Chest")
                        elseif _G.ESPFlower and (string.find(lowerName, "flower", 1, true)
                            or string.find(lowerName, "flora", 1, true)) then
                            seen[obj] = true
                            createESP(obj, "flower", _G.ESPFlowerColor, "🌸 " .. obj.Name)
                        end
                    end
                end
            end

            pruneESP(seen)
            if _G.ESPIsland and #islandParts == 0 then setIslandESP(true) end
            if not _G.ESPIsland and #islandParts > 0 then clearIslandESP() end
        end)
    end
end)
-- ====== LOOP 17: Auto Dodge ======
local lastDodgeTime = 0
local HazardWords = {"projectile", "bullet", "missile", "blast", "attack", "slash", "beam"}
local function looksLikeHazard(part)
    if not part:IsA("BasePart") or part.Anchored then return false end
    local lowerName = string.lower(part.Name)
    for _, word in ipairs(HazardWords) do
        if string.find(lowerName, word, 1, true) then return true end
    end
    return false
end

task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.15)
        if _G.AutoDodge and getActiveMovementMode() == nil
            and os.clock() - lastDodgeTime >= 0.8 then
            runFeature("Auto Dodge", function()
                local char = Player.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                if not humanoid or humanoid.Health <= 0 or not rootPart then return end

                local containers = {workspace:FindFirstChild("_WorldOrigin"), workspace:FindFirstChild("Effects")}
                for _, container in ipairs(containers) do
                    if container then
                        for _, obj in ipairs(container:GetDescendants()) do
                            if looksLikeHazard(obj) and (obj.Position - rootPart.Position).Magnitude < 28 then
                                local side = math.random(0, 1) == 0 and -10 or 10
                                rootPart.CFrame = rootPart.CFrame * CFrame.new(side, 0, 0)
                                rootPart.AssemblyLinearVelocity = Vector3.zero
                                lastDodgeTime = os.clock()
                                return
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
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(30)
        if _G.ServerHopNoFruit then
            runFeature("Server Hop Fruit", function()
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
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    task.wait(1)
    if _G.AutoFarmLevel or _G.AutoFarmMastery or _G.AutoFarmBoss then
        notify("💀 Đã Hồi Sinh", "Tiếp tục farm...", 3)
    end
end)

local function buildSystemDiagnostic()
    local passed, failed, notes = 0, {}, {}
    local function check(name, condition)
        if condition then
            passed = passed + 1
        else
            table.insert(failed, name)
        end
    end

    local char = Player.Character
    check("Nhân vật", char and char:FindFirstChildOfClass("Humanoid")
        and char:FindFirstChild("HumanoidRootPart"))
    check("Player.Data.Level", Player:FindFirstChild("Data")
        and Player.Data:FindFirstChild("Level"))
    check("Remote CommF_", ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("CommF_"))
    check("Folder Enemies", workspace:FindFirstChild("Enemies"))
    check("Dữ liệu quest Sea hiện tại", getQuestData(
        getPlayerLevel()
    ) ~= nil)
    check("VirtualInputManager", VirtualInputManager ~= nil)

    if type(firetouchinterest) ~= "function" then
        table.insert(notes, "Nhặt trái: dùng fallback chạm trực tiếp")
    end
    if type(fireclickdetector) ~= "function" then
        table.insert(notes, "Raid: cần tự bấm nút khởi động")
    end
    if not teleportReloadReady then
        table.insert(notes, "Đổi server: executor không hỗ trợ tự nạp")
    end

    local runtimeErrors = {}
    for featureName, info in pairs(featureErrors) do
        table.insert(runtimeErrors, featureName .. ": " .. tostring(info.Message))
    end
    table.sort(runtimeErrors)

    local status = "Kiểm tra lõi: " .. passed .. "/" .. (passed + #failed)
    if #failed > 0 then status = status .. "\nThiếu: " .. table.concat(failed, ", ") end
    if #notes > 0 then status = status .. "\nLưu ý: " .. table.concat(notes, "; ") end
    if #runtimeErrors > 0 then
        status = status .. "\nLỗi gần nhất: " .. table.concat(runtimeErrors, " | ")
    else
        status = status .. "\nKhông ghi nhận lỗi vòng chạy."
    end
    status = status .. "\nChế độ di chuyển: " .. tostring(getActiveMovementMode() or "không")
    return status
end
------------------------------------------------------------
-- PHẦN 7: GIAO DIỆN FLUENT — BỐ CỤC MODERN DASHBOARD
------------------------------------------------------------

local Window = Fluent:CreateWindow({
    Title    = "HAOTOOL  •  BLOX FRUITS",
    SubTitle = "V" .. RequestedScriptVersion .. "  •  Sea " .. WorldSea .. "  |  Control Center",
    TabWidth = 170,
    Size     = UDim2.fromOffset(720, 540),
    Acrylic  = true,
    Theme    = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl, -- Phím ẩn/hiện GUI
})

-- ====== LOGO NỔI: LUÔN CÓ THỂ MỞ LẠI MENU ======
local function setMainWindowVisible(visible)
    if Fluent and Fluent.GUI then
        pcall(function() Fluent.GUI.Enabled = true end)
    end
    if not Window then return false end

    local changed = false
    if Window.Root then
        local okVisible = pcall(function()
            Window.Root.Visible = visible
        end)
        local okEnabled = pcall(function()
            if Window.Root:IsA("ScreenGui") then
                Window.Root.Enabled = visible
            end
        end)
        changed = okVisible or okEnabled
    end
    Window.Minimized = not visible
    return changed
end

local function rebuildMainInterface()
    if RuntimeEnv.HAOTOOL_RELOADING then return end
    if type(readfile) ~= "function" then return end

    RuntimeEnv.HAOTOOL_RELOADING = true
    pcall(stopFarmMovement)
    pcall(clearAllESP)
    saveTeleportState()
    pcall(function()
        RuntimeEnv.HAOTOOL_TELEPORT_STATE = HttpService:JSONDecode(
            readfile(TELEPORT_STATE_FILE)
        )
    end)
    RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
    RuntimeEnv.HAOTOOL_RUNNING = nil
    RuntimeEnv.HAOTOOL_TOGGLE_MENU = nil

    task.spawn(function()
        task.wait()
        local readOk, source = pcall(function()
            return readfile(TELEPORT_SCRIPT_FILE)
        end)
        if not readOk then
            RuntimeEnv.HAOTOOL_RELOADING = nil
            warn("[HAOTOOL] Không đọc được file phục hồi giao diện.")
            return
        end

        local runner, compileError = loadstring(source)
        if not runner then
            RuntimeEnv.HAOTOOL_RELOADING = nil
            warn("[HAOTOOL] Không dựng lại được giao diện: " .. tostring(compileError))
            return
        end

        local runOk, runError = pcall(runner)
        RuntimeEnv.HAOTOOL_RELOADING = nil
        if not runOk then
            RuntimeEnv.HAOTOOL_RUNNING = nil
            warn("[HAOTOOL] Phục hồi giao diện lỗi: " .. tostring(runError))
        end
    end)
end

local function toggleMainWindow()
    if Window and Window.Root and Window.Root.Parent then
        local isCurrentlyVisible = false
        pcall(function() isCurrentlyVisible = Window.Root.Visible == true end)
        if Window.Minimized == true then isCurrentlyVisible = false end
        setMainWindowVisible(not isCurrentlyVisible)
    else
        rebuildMainInterface()
    end
end

RuntimeEnv.HAOTOOL_TOGGLE_MENU = toggleMainWindow

local function createLauncherButton()
    local coreGui = game:GetService("CoreGui")
    local playerGui = Player:FindFirstChild("PlayerGui")

    local function destroyOld(container)
        if container then
            local old = container:FindFirstChild("HAOTOOL_Launcher")
            if old then pcall(function() old:Destroy() end) end
        end
    end
    destroyOld(coreGui)
    destroyOld(playerGui)

    local launcherGui = Instance.new("ScreenGui")
    launcherGui.Name = "HAOTOOL_Launcher"
    launcherGui.ResetOnSpawn = false
    launcherGui.IgnoreGuiInset = true
    launcherGui.DisplayOrder = 1000000
    launcherGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local okParent = pcall(function() launcherGui.Parent = coreGui end)
    if not okParent or not launcherGui.Parent then
        pcall(function() launcherGui.Parent = playerGui or Player:WaitForChild("PlayerGui") end)
    end

    pcall(function()
        local protect = protectgui or (syn and syn.protect_gui)
        if protect then protect(launcherGui) end
    end)

    local button = Instance.new("TextButton")
    button.Name = "LogoButton"
    button.Size = UDim2.fromOffset(58, 58)
    button.Position = UDim2.new(1, -78, 0.5, -29)
    button.BackgroundColor3 = Color3.fromRGB(112, 72, 232)
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = "H"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 26
    button.Font = Enum.Font.GothamBold
    button.Active = true
    button.ZIndex = 100000
    button.Parent = launcherGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(205, 188, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.15
    stroke.Parent = button

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(66, 45, 140)),
    })
    gradient.Rotation = 45
    gradient.Parent = button

    -- Kéo thả nút mượt mà + Nhấp vào để Bật/Tắt Menu 100%
    local dragging = false
    local dragStart, startPos = nil, nil

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                local dist = 0
                if dragStart and input.Position then
                    dist = (input.Position - dragStart).Magnitude
                end
                if dist < 10 then
                    toggleMainWindow()
                end
            end
        end
    end)

    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local lastLauncherToggle = 0
    button.Activated:Connect(function()
        local now = os.clock()
        if now - lastLauncherToggle < 0.25 then return end
        lastLauncherToggle = now
        toggleMainWindow()
    end)
    return launcherGui
end

local LauncherGui = createLauncherButton()

pcall(function()
    if Window and Window.Root then
        Window.Root.Name = "HAOTOOL_MainWindow"
    end
end)

RuntimeEnv.HAOTOOL_DESTROY_UI = function()
    pcall(function()
        if LauncherGui and LauncherGui.Parent then LauncherGui:Destroy() end
    end)
    pcall(function()
        if Fluent and Fluent.GUI and typeof(Fluent.GUI) == "Instance" then
            Fluent.GUI:Destroy()
        elseif Window and Window.Root and Window.Root.Parent then
            Window.Root:Destroy()
        end
    end)
end

-- Nút X an toàn phủ lên nút hủy mặc định của Fluent.
pcall(function()
    local originalClose = Window.TitleBar and Window.TitleBar.CloseButton
        and Window.TitleBar.CloseButton.Frame
    if originalClose then
        if type(getconnections) == "function" then
            for _, connection in ipairs(getconnections(originalClose.MouseButton1Click)) do
                pcall(function()
                    if connection.Disable then
                        connection:Disable()
                    elseif connection.Disconnect then
                        connection:Disconnect()
                    end
                end)
            end
        end
        originalClose.Active = false
        originalClose.Visible = false
    end


    local safeClose = Instance.new("TextButton")
    safeClose.Name = "SafeMinimizeButton"
    safeClose.Size = UDim2.fromOffset(34, 34)
    safeClose.AnchorPoint = Vector2.new(1, 0)
    safeClose.Position = UDim2.new(1, -4, 0, 4)
    safeClose.BackgroundTransparency = 1
    safeClose.BorderSizePixel = 0
    safeClose.Text = "×"
    safeClose.TextColor3 = Color3.fromRGB(230, 224, 255)
    safeClose.TextSize = 24
    safeClose.Font = Enum.Font.Gotham
    safeClose.Active = true
    safeClose.ZIndex = 10000
    safeClose.Parent = Window.Root
    safeClose.Activated:Connect(function()
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
        setMainWindowVisible(false)
    end)
end)

-- ==================== TAB 1: MAIN ====================
-- Tên tab ngắn, đồng nhất và ưu tiên tiếng Việt để dễ quét nhanh.
local createdTabCount = 0
local function addTabSafe(name, title)
    -- Không dùng icon mạng ở đây: một icon tải lỗi không được phép chặn các tab sau.
    local ok, tabOrError = pcall(function()
        return Window:AddTab({Title = title})
    end)
    if ok and tabOrError then
        createdTabCount = createdTabCount + 1
        return tabOrError
    end

    featureErrors["Tab " .. name] = tostring(tabOrError)
    return nil
end

-- Tạo tuần tự toàn bộ tab trước khi thêm điều khiển.
local UITabs = {}
UITabs.Main = addTabSafe("Tổng quan", "Tổng quan")
UITabs.Farm = addTabSafe("Farm", "Tự động farm")
UITabs.Raid = addTabSafe("Raid", "Đột kích")
UITabs.Fruit = addTabSafe("Fruit", "Trái ác quỷ")
UITabs.ESP = addTabSafe("ESP", "Hiển thị ESP")
UITabs.Teleport = addTabSafe("Di chuyển", "Di chuyển")
UITabs.Combat = addTabSafe("Chiến đấu", "Chiến đấu")
UITabs.Misc = addTabSafe("Tiện ích", "Tiện ích")
UITabs.Settings = addTabSafe("Cài đặt", "Cài đặt")
RuntimeEnv.HAOTOOL_TAB_COUNT = createdTabCount
local currentBossNames

local MainTab = UITabs.Main
runFeature("Giao diện Tổng quan", function()

local tabStatus = "Đã tạo " .. createdTabCount .. "/9 tab"
if createdTabCount < 9 then
    for featureName, message in pairs(featureErrors) do
        if string.sub(featureName, 1, 4) == "Tab " then
            tabStatus = tabStatus .. "\n" .. featureName .. ": " .. string.sub(tostring(message), 1, 220)
            break
        end
    end
end
MainTab:AddParagraph({
    Title = "Trạng thái giao diện • V" .. RequestedScriptVersion,
    Content = tabStatus,
})
MainTab:AddParagraph({
    Title = "⚡  Xin chào, " .. Player.DisplayName,
    Content = "SEA  " .. WorldSea
        .. "    •    LEVEL  " .. tostring(pcall(function() return Player.Data.Level.Value end) and Player.Data.Level.Value or "?")
        .. "    •    BELI  " .. tostring(pcall(function() return Player.Data.Beli.Value end) and Player.Data.Beli.Value or "?")
        .. "\nServer  " .. game.JobId:sub(1, 8) .. "..."
        .. "\n\nRightControl hoặc nút H  •  Ẩn / hiện bảng điều khiển"
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
ServerSection:AddButton({
    Title = "Buộc dựng lại toàn bộ menu",
    Description = "Xóa cửa sổ hiện tại và nạp lại đủ 9 tab từ bản đã lưu.",
    Callback = function()
        RuntimeEnv.HAOTOOL_UI_READY = false
        rebuildMainInterface()
    end
})

end)

-- ==================== TAB 2: FARM ====================
local FarmTab = UITabs.Farm
runFeature("Giao diện Farm", function()

local FarmCoreSection = FarmTab:AddSection("Nâng cấp & Mastery")

FarmCoreSection:AddToggle("AutoFarmLevel", {
    Title = "Auto Farm Level",
    Description = "Tự động nhận quest → farm quái → lên level",
    Default = _G.AutoFarmLevel,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if v and hasActiveQuest() then
            abandonQuest()
            acceptedQuestSignature = nil
        end
        if not v and not _G.AutoFarmMastery and not _G.AutoFarmBoss
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmCoreSection:AddToggle("AutoFarmMastery", {
    Title = "Auto Farm Mastery",
    Description = "Farm mastery cho vũ khí được chọn",
    Default = _G.AutoFarmMastery,
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
    Default = _G.MasteryWeapon,
    Callback = function(v) _G.MasteryWeapon = v end,
})

FarmCoreSection:AddDropdown("SelectWeaponDrop", {
    Title = "Chọn Vũ Khí Farm",
    Values = {"Melee", "Sword", "Gun", "Blox Fruit"},
    Default = _G.SelectWeapon,
    Callback = function(v) _G.SelectWeapon = v end,
})

FarmCoreSection:AddDropdown("FarmMethodDrop", {
    Title = "Phương Thức Farm",
    Values = {"Quest", "Nearest", "Selected Mob"},
    Default = _G.FarmMethod,
    Callback = function(v) _G.FarmMethod = v end,
})

local currentEnemyNames = getEnemyList()
if _G.SelectedMob == "" and currentEnemyNames[1] ~= "(Không có quái)" then
    _G.SelectedMob = currentEnemyNames[1]
end
FarmCoreSection:AddDropdown("SelectedMobDrop", {
    Title = "Chọn Quái (nếu dùng Selected Mob)",
    Values = currentEnemyNames,
    Default = (_G.SelectedMob ~= "" and _G.SelectedMob or 1),
    Callback = function(v) _G.SelectedMob = v end,
})

local FarmPositionSection = FarmTab:AddSection("Vị trí & chiến đấu")

FarmPositionSection:AddSlider("FarmHeightSlider", {
    Title = "Độ cao so với quái",
    Description = "Số âm đứng thấp hơn, số dương đứng cao hơn.",
    Min = -20,
    Max = 30,
    Default = _G.FarmHeight,
    Rounding = 0,
    Callback = function(v) _G.FarmHeight = v end,
})

FarmPositionSection:AddSlider("FarmDistanceSlider", {
    Title = "Khoảng cách trước / sau",
    Description = "0 là ngay trên quái; tăng để lùi ra sau.",
    Min = 0,
    Max = 25,
    Default = _G.FarmDistance,
    Rounding = 0,
    Callback = function(v) _G.FarmDistance = v end,
})

FarmPositionSection:AddToggle("HoldFarmPositionToggle", {
    Title = "Giữ vị trí khi đánh",
    Description = "Ngăn nhân vật vừa đánh vừa chạy hoặc giật quanh quái.",
    Default = _G.HoldFarmPosition,
    Callback = function(v) _G.HoldFarmPosition = v end,
})

FarmPositionSection:AddToggle("FreezeTargetToggle", {
    Title = "Khóa di chuyển của quái",
    Description = "Giữ mục tiêu đứng yên trong lúc đánh.",
    Default = _G.FreezeTarget,
    Callback = function(v)
        _G.FreezeTarget = v
        if not v then restoreFrozenMobs() end
    end,
})

FarmPositionSection:AddToggle("SafetyModeToggle", {
    Title = "Giới hạn an toàn",
    Description = "Giới hạn tốc độ, hitbox và gom quái để giảm spam; không thể bảo đảm chống ban.",
    Default = _G.SafetyMode,
    Callback = function(v)
        _G.SafetyMode = v
        notify(
            v and "Đã bật giới hạn an toàn" or "Đã tắt giới hạn an toàn",
            v and "Tốc độ tối thiểu 0.05, hitbox tối đa 18, gom quái tối đa 350."
                or "Tốc độ và phạm vi cao hơn có thể làm tăng rủi ro.",
            5
        )
    end,
})

FarmPositionSection:AddToggle("BackgroundAttackToggle", {
    Title = "Đánh nền (không chiếm chuột)",
    Description = "Chỉ dùng Tool:Activate nên vẫn bấm menu bình thường. Nếu vũ khí không gây sát thương, hãy tắt để dùng chế độ tương thích.",
    Default = _G.BackgroundAttack,
    Callback = function(v) _G.BackgroundAttack = v end,
})

FarmPositionSection:AddSlider("AttackDelaySlider", {
    Title = "Độ trễ đánh thường",
    Description = "Thấp hơn sẽ nhanh hơn; khi giới hạn an toàn bật, mức thực tế không thấp hơn 0.05.",
    Min = 0.01,
    Max = 0.50,
    Default = _G.AttackDelay,
    Rounding = 2,
    Callback = function(v) _G.AttackDelay = v end,
})

FarmPositionSection:AddSlider("HitboxSizeSlider", {
    Title = "Kích thước vùng đánh",
    Min = 2,
    Max = 30,
    Default = _G.HitboxSize,
    Rounding = 0,
    Callback = function(v) _G.HitboxSize = v end,
})

FarmPositionSection:AddToggle("BringMobToggle", {
    Title = "Gom quái cùng loại",
    Description = "Kéo các quái cùng tên về mục tiêu đang đánh.",
    Default = _G.BringMob,
    Callback = function(v)
        _G.BringMob = v
        if not v then restoreFrozenMobs() end
    end,
})

FarmPositionSection:AddSlider("BringRadiusSlider", {
    Title = "Bán kính gom quái",
    Min = 50,
    Max = 1000,
    Default = _G.BringRadius,
    Rounding = 0,
    Callback = function(v) _G.BringRadius = v end,
})

FarmPositionSection:AddToggle("AutoSkillToggle", {
    Title = "Tự dùng kỹ năng Z, X, C, V",
    Description = "Dùng lần lượt các kỹ năng khi đang giữ vị trí.",
    Default = _G.AutoSkill,
    Callback = function(v) _G.AutoSkill = v end,
})

FarmPositionSection:AddSlider("SkillCDSlider", {
    Title = "Hồi chiêu kỹ năng",
    Min = 0.5,
    Max = 5,
    Default = _G.SkillCooldown,
    Rounding = 1,
    Callback = function(v) _G.SkillCooldown = v end,
})

local FarmBossSection = FarmTab:AddSection("Boss & tài nguyên")

currentBossNames = getBossList()
if #currentBossNames > 0 and (_G.SelectedBoss == "" or not table.find(currentBossNames, _G.SelectedBoss)) then
    _G.SelectedBoss = currentBossNames[1]
end

FarmBossSection:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Boss",
    Description = "Tự động farm boss được chọn",
    Default = _G.AutoFarmBoss,
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
    Values = currentBossNames,
    Default = (_G.SelectedBoss ~= "" and _G.SelectedBoss or 1),
    Callback = function(v) _G.SelectedBoss = v end,
})

FarmBossSection:AddButton({
    Title = "Làm mới danh sách Boss",
    Description = "Thêm các boss/raid boss vừa xuất hiện trong server.",
    Callback = function()
        currentBossNames = getBossList()
        if #currentBossNames > 0 and not table.find(currentBossNames, _G.SelectedBoss) then
            _G.SelectedBoss = currentBossNames[1]
        end
        for _, optionId in ipairs({"SelectedBossDrop", "BossTPDrop"}) do
            local option = Fluent.Options and Fluent.Options[optionId]
            if option then
                option:SetValues(currentBossNames)
                if option.SetValue and _G.SelectedBoss ~= "" then
                    option:SetValue(_G.SelectedBoss)
                end
            end
        end
        notify("Boss", "Đã cập nhật " .. #currentBossNames .. " boss.", 3)
    end
})
FarmBossSection:AddToggle("AutoFarmSeaBeast", {
    Title = "Auto Farm Sea Beast",
    Default = _G.AutoFarmSeaBeast,
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
    Description = "Duy trì Observation; điểm kinh nghiệm chỉ tăng khi né đòn trong game",
    Default = _G.AutoFarmObs,
    Callback = function(v) _G.AutoFarmObs = v end,
})

FarmBossSection:AddToggle("AutoFarmBone", {
    Title = "Auto Farm Bone",
    Default = _G.AutoFarmBone,
    Callback = function(v) _G.AutoFarmBone = v end,
})

FarmBossSection:AddToggle("AutoFarmFragment", {
    Title = "Auto Farm Fragment (Raid)",
    Description = "Mua chip, bắt đầu raid và đánh quái raid để nhận Fragment.",
    Default = _G.AutoFarmFragment,
    Callback = function(v) _G.AutoFarmFragment = v end,
})

FarmBossSection:AddToggle("AutoFarmChest", {
    Title = "Auto Farm Rương",
    Description = "Tự động tìm và mở rương",
    Default = _G.AutoFarmChest,
    Callback = function(v) _G.AutoFarmChest = v end,
})

end)

-- ==================== TAB 3: RAID ====================
local RaidTab = UITabs.Raid
runFeature("Giao diện Raid", function()

local RaidMainSection = RaidTab:AddSection("Đột kích & thức tỉnh")

RaidMainSection:AddToggle("AutoRaidToggle", {
    Title = "Auto Raid",
    Description = "Tự động bắt đầu raid với chip được chọn",
    Default = _G.AutoRaid,
    Callback = function(v) _G.AutoRaid = v end,
})

RaidMainSection:AddToggle("AutoRaidFarmToggle", {
    Title = "Auto Farm trong Raid",
    Description = "Farm quái bên trong raid",
    Default = _G.AutoRaidFarm,
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
    Default = _G.RaidChip,
    Callback = function(v) _G.RaidChip = v end,
})

RaidMainSection:AddToggle("AutoAwakeningToggle", {
    Title = "Auto Awakening",
    Description = "Tự kiểm tra và thức tỉnh kỹ năng khi đang ở phòng Awakener",
    Default = _G.AutoAwakening,
    Callback = function(v) _G.AutoAwakening = v end,
})

RaidMainSection:AddButton({
    Title = "🔄 Bắt Đầu Raid Ngay",
    Description = "Bắt đầu raid với chip đã chọn",
    Callback = function()
        if WorldSea == 1 then
            notify("Raid", "Raid chỉ mở tại Sea 2 hoặc Sea 3.", 4)
        elseif startSelectedRaid() then
            notify("⚡ Raid", "Đã gửi thao tác bắt đầu raid " .. _G.RaidChip .. ".", 3)
        end
    end
})

end)

-- ==================== TAB 4: FRUIT ====================
local FruitTab = UITabs.Fruit
runFeature("Giao diện Trái", function()

local FruitAutoSection = FruitTab:AddSection("Theo dõi & tự động nhặt")

FruitAutoSection:AddToggle("AutoFindFruitToggle", {
    Title = "Báo Trái Spawn",
    Description = "Thông báo khi có trái ác quỷ spawn trên map",
    Default = _G.AutoFruitFinder,
    Callback = function(v) _G.AutoFruitFinder = v end,
})

FruitAutoSection:AddToggle("AutoCollectFruitToggle", {
    Title = "Auto Nhặt Trái",
    Description = "Tự động bay tới và nhặt trái",
    Default = _G.AutoCollectFruit,
    Callback = function(v) _G.AutoCollectFruit = v end,
})

FruitAutoSection:AddToggle("FruitESPToggle", {
    Title = "ESP Fruit",
    Description = "Hiển thị vị trí trái ác quỷ trên map",
    Default = _G.FruitESP,
    Callback = function(v) _G.FruitESP = v end,
})

FruitAutoSection:AddToggle("AutoGachaToggle", {
    Title = "Auto Gacha / Random Fruit",
    Description = "Gửi yêu cầu mua trái mỗi 30 giây; game vẫn áp dụng tiền và thời gian chờ",
    Default = _G.AutoGachaFruit,
    Callback = function(v) _G.AutoGachaFruit = v end,
})

local FruitActionSection = FruitTab:AddSection("Thao tác nhanh")

FruitActionSection:AddButton({
    Title = "Mua trái ngẫu nhiên",
    Description = "Mua 1 trái random từ Blox Fruit Dealer Cousin",
    Callback = function()
        pcall(function()
            local res = ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            notify("🎰 Gacha Fruit", tostring(res or "Đã gửi yêu cầu Mua trái"), 6)
        end)
    end
})

FruitActionSection:AddButton({
    Title = "Quét trái trên toàn bản đồ",
    Description = "Quét các Tool trái thật đang nằm trong workspace",
    Callback = function()
        local fruits = getSpawnedFruits()
        if #fruits == 0 then
            notify("🔍 Quét xong", "Không tìm thấy trái nào trên map", 3)
            return
        end
        for index, fruit in ipairs(fruits) do
            local handle = fruit:FindFirstChild("Handle")
            notify("🍎 Trái #" .. index, fruit.Name .. " tại " .. tostring(handle and handle.Position), 5)
        end
        notify("🔍 Quét xong", "Tìm thấy " .. #fruits .. " trái!", 3)
    end
})


FruitActionSection:AddButton({
    Title = "Mở cửa hàng trái",
    Description = "Nạp dữ liệu cửa hàng và mở bảng Fruit Shop nếu game đã tạo giao diện.",
    Callback = function()
        local opened = false
        runFeature("Mở cửa hàng trái", function()
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits") end)
            local pGui = Player:FindFirstChild("PlayerGui")
            local mainGui = pGui and pGui:FindFirstChild("Main")
            if mainGui then
                for _, name in ipairs({"FruitShop", "FruitStore", "FruitDealer", "Shop", "FruitInventory", "ShopFrame"}) do
                    local shop = mainGui:FindFirstChild(name, true)
                    if shop and shop:IsA("GuiObject") then
                        shop.Visible = true
                        opened = true
                    end
                end
            end
        end)
        if opened then
            notify("🍎 Cửa hàng trái", "Đã mở giao diện cửa hàng trái quỷ.", 4)
        else
            notify("🍎 Cửa hàng trái", "Đã nạp dữ liệu cửa hàng từ máy chủ.", 5)
        end
    end
})

end)

-- ==================== TAB 5: ESP ====================
local ESPTab = UITabs.ESP
runFeature("Giao diện ESP", function()

local ESPTargetSection = ESPTab:AddSection("Đối tượng hiển thị")

ESPTargetSection:AddToggle("ESPPlayerToggle", {
    Title = "ESP Player",
    Description = "Hiển thị người chơi khác (có Team Check)",
    Default = _G.ESPPlayer,
    Callback = function(v) _G.ESPPlayer = v; if not v then clearESPKind("player") end end,
})

ESPTargetSection:AddToggle("ESPTeamCheckToggle", {
    Title = "Team Check",
    Description = "Bỏ qua đồng đội",
    Default = _G.ESPTeamCheck,
    Callback = function(v) _G.ESPTeamCheck = v end,
})

ESPTargetSection:AddToggle("ESPMobToggle", {
    Title = "ESP Mob",
    Description = "Hiển thị quái thường",
    Default = _G.ESPMob,
    Callback = function(v) _G.ESPMob = v; if not v then clearESPKind("mob") end end,
})

ESPTargetSection:AddToggle("ESPBossToggle", {
    Title = "ESP Boss",
    Description = "Hiển thị model có nhãn Boss/Raid Boss hoặc nằm trong dữ liệu boss",
    Default = _G.ESPBoss,
    Callback = function(v) _G.ESPBoss = v; if not v then clearESPKind("boss") end end,
})

ESPTargetSection:AddToggle("ESPChestToggle", {
    Title = "ESP Chest",
    Description = "Hiển thị rương",
    Default = _G.ESPChest,
    Callback = function(v) _G.ESPChest = v; if not v then clearESPKind("chest") end end,
})

ESPTargetSection:AddToggle("ESPFlowerToggle", {
    Title = "ESP Flower",
    Description = "Hiển thị hoa",
    Default = _G.ESPFlower,
    Callback = function(v) _G.ESPFlower = v; if not v then clearESPKind("flower") end end,
})

ESPTargetSection:AddToggle("ESPIslandToggle", {
    Title = "ESP Island (Waypoint)",
    Description = "Hiển thị tên đảo",
    Default = _G.ESPIsland,
    Callback = function(v)
        _G.ESPIsland = v
        setIslandESP(v)
    end,
})

local ESPStyleSection = ESPTab:AddSection("Khoảng cách & màu sắc")

ESPStyleSection:AddSlider("ESPDistSlider", {
    Title = "Khoảng Cách ESP (studs)",
    Min = 100,
    Max = 10000,
    Default = _G.ESPDistance,
    Rounding = 0,
    Callback = function(v) _G.ESPDistance = v end,
})

ESPStyleSection:AddColorpicker("ESPPlayerColor", {
    Title = "Màu Player",
    Default = _G.ESPPlayerColor,
    Callback = function(v) _G.ESPPlayerColor = v end,
})

ESPStyleSection:AddColorpicker("ESPMobColorPick", {
    Title = "Màu Mob",
    Default = _G.ESPMobColor,
    Callback = function(v) _G.ESPMobColor = v end,
})

ESPStyleSection:AddColorpicker("ESPBossColorPick", {
    Title = "Màu Boss",
    Default = _G.ESPBossColor,
    Callback = function(v) _G.ESPBossColor = v end,
})

ESPStyleSection:AddColorpicker("ESPFruitColorPick", {
    Title = "Màu Fruit",
    Default = _G.ESPFruitColor,
    Callback = function(v) _G.ESPFruitColor = v end,
})

ESPStyleSection:AddButton({
    Title = "Tắt và xóa toàn bộ ESP",
    Callback = function()
        _G.ESPPlayer = false
        _G.ESPMob = false
        _G.ESPBoss = false
        _G.ESPChest = false
        _G.ESPFlower = false
        _G.ESPIsland = false
        _G.FruitESP = false
        for _, optionId in ipairs({
            "ESPPlayerToggle", "ESPMobToggle", "ESPBossToggle",
            "ESPChestToggle", "ESPFlowerToggle", "ESPIslandToggle", "FruitESPToggle",
        }) do
            local option = Fluent.Options and Fluent.Options[optionId]
            if option and option.SetValue then pcall(function() option:SetValue(false) end) end
        end
        clearAllESP()
        notify("ESP", "Đã tắt và xóa tất cả ESP", 2)
    end
})

end)

-- ==================== TAB 6: TELEPORT ====================
local TeleportTab = UITabs.Teleport
runFeature("Giao diện Di chuyển", function()

local IslandSection = TeleportTab:AddSection("Đảo tại Sea " .. WorldSea)

-- Lấy danh sách đảo theo Sea hiện tại
local currentIslands = getSeaIslands()
local islandNames = {}
for name, _ in pairs(currentIslands) do
    table.insert(islandNames, name)
end
table.sort(islandNames)
if #islandNames > 0 and (_G.SelectedIsland == "" or not currentIslands[_G.SelectedIsland]) then
    _G.SelectedIsland = islandNames[1]
end

IslandSection:AddDropdown("IslandDrop", {
    Title = "Chọn Đảo (Sea " .. WorldSea .. ")",
    Values = islandNames,
    Default = (_G.SelectedIsland ~= "" and _G.SelectedIsland or 1),
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
    if _G.SelectedNPC == "" or not table.find(npcNames, _G.SelectedNPC) then
        _G.SelectedNPC = npcNames[1]
    end

    NPCSection:AddDropdown("NPCDrop", {
        Title = "Chọn NPC",
        Values = npcNames,
        Default = (_G.SelectedNPC ~= "" and _G.SelectedNPC or 1),
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

if _G.SelectedBossTP == "" or not table.find(currentBossNames, _G.SelectedBossTP) then
    _G.SelectedBossTP = currentBossNames[1] or ""
end

BossTeleportSection:AddDropdown("BossTPDrop", {
    Title = "Chọn Boss",
    Values = currentBossNames,
    Default = (_G.SelectedBossTP ~= "" and _G.SelectedBossTP or 1),
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
        local closestFruit = findNearestFruit()
        if closestFruit and closestFruit:FindFirstChild("Handle") then
            notify("🍎 Fruit TP", "Bay tới " .. closestFruit.Name, 3)
            toTarget(closestFruit.Handle.CFrame * CFrame.new(0, 2, 0))
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

end)

-- ==================== TAB 7: COMBAT ====================
local CombatTab = UITabs.Combat
runFeature("Giao diện Chiến đấu", function()

local CombatAutoSection = CombatTab:AddSection("Haki & phòng thủ tự động")

CombatAutoSection:AddToggle("AutoBusoToggle", {
    Title = "Auto Buso Haki",
    Description = "Tự động bật Buso Haki (Haki Vũ Trang)",
    Default = _G.AutoHaki,
    Callback = function(v) _G.AutoHaki = v end,
})

CombatAutoSection:AddToggle("AutoKenToggle", {
    Title = "Auto Ken Haki",
    Description = "Tự động bật Ken Haki (Haki Quan Sát)",
    Default = _G.AutoKen,
    Callback = function(v) _G.AutoKen = v; if v then activateObservation(true) end end,
})

CombatAutoSection:AddToggle("AutoObsV2Toggle", {
    Title = "Duy trì Observation",
    Description = "Duy trì Observation sau khi hồi sinh; không tự mở khóa V2",
    Default = _G.AutoObsV2,
    Callback = function(v) _G.AutoObsV2 = v; if v then activateObservation(true) end end,
})

CombatAutoSection:AddToggle("AutoDodgeToggle", {
    Title = "Auto Dodge",
    Description = "Tự động né tránh đạn/đòn đánh",
    Default = _G.AutoDodge,
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
        if activateObservation(true) then
            notify("👁️", "Đã gửi thao tác bật Observation", 2)
        end
    end
})

CombatActionSection:AddButton({
    Title = "Duy trì Observation",
    Description = "Chỉ bật/duy trì Observation hiện có; không tự mở khóa V2.",
    Callback = function()
        if activateObservation(true) then
            notify("🔮", "Đã gửi thao tác duy trì Observation", 2)
        end
    end
})

end)

-- ==================== TAB 8: MISC ====================
local MiscTab = UITabs.Misc
runFeature("Giao diện Tiện ích", function()

local MovementSection = MiscTab:AddSection("Di chuyển nhân vật")

-- Speed & Jump
MovementSection:AddToggle("WalkSpeedToggle", {
    Title = "WalkSpeed Hack",
    Default = _G.WalkSpeedHack,
    Callback = function(v) _G.WalkSpeedHack = v; if not v then restoreMovementStats("WalkSpeed") end end,
})

MovementSection:AddSlider("WalkSpeedSlider", {
    Title = "Tốc Độ Chạy",
    Min = 16,
    Max = 300,
    Default = _G.WalkSpeedVal,
    Rounding = 0,
    Callback = function(v) _G.WalkSpeedVal = v end,
})

MovementSection:AddToggle("JumpPowerToggle", {
    Title = "JumpPower Hack",
    Default = _G.JumpPowerHack,
    Callback = function(v) _G.JumpPowerHack = v; if not v then restoreMovementStats("JumpPower") end end,
})

MovementSection:AddSlider("JumpPowerSlider", {
    Title = "Sức Nhảy",
    Min = 50,
    Max = 500,
    Default = _G.JumpPowerVal,
    Rounding = 0,
    Callback = function(v) _G.JumpPowerVal = v end,
})

MovementSection:AddToggle("InfiniteJumpToggle", {
    Title = "Infinite Jump",
    Description = "Nhảy không giới hạn trên không",
    Default = _G.InfiniteJump,
    Callback = function(v) _G.InfiniteJump = v end,
})

MovementSection:AddToggle("InfiniteEnergyToggle", {
    Title = "Infinite Energy",
    Description = "Năng lượng không giới hạn",
    Default = _G.InfiniteEnergy,
    Callback = function(v) _G.InfiniteEnergy = v end,
})

-- Stats
local StatsSection = MiscTab:AddSection("Chỉ số tự động")

StatsSection:AddToggle("AutoStatsToggle", {
    Title = "Auto Cộng Điểm Stats",
    Default = _G.AutoStats,
    Callback = function(v) _G.AutoStats = v end,
})

StatsSection:AddDropdown("StatDropdown", {
    Title = "Chọn Chỉ Số",
    Values = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"},
    Default = _G.StatToUpgrade,
    Callback = function(v) _G.StatToUpgrade = v end,
})

-- Anti-AFK
local ProtectionSection = MiscTab:AddSection("Bảo vệ phiên chơi")

ProtectionSection:AddToggle("AntiAFKToggle", {
    Title = "Anti AFK",
    Description = "Chống bị kick do AFK",
    Default = _G.AntiAFK,
    Callback = function(v) _G.AntiAFK = v end,
})

-- FPS Boost
local PerformanceSection = MiscTab:AddSection("Hiệu năng & hiển thị")

PerformanceSection:AddButton({
    Title = "Tối ưu FPS",
    Description = "Tắt texture/particle để giảm lag; muốn hoàn tác hãy vào lại server.",
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
    Default = _G.ServerHopNoFruit,
    Callback = function(v) _G.ServerHopNoFruit = v end,
})

end)

-- ==================== TAB 9: SETTINGS ====================
local SettingsTab = UITabs.Settings
runFeature("Giao diện Cài đặt", function()

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
            local lvl = getPlayerLevel()
            local beli = getPlayerBeli()
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
    Title = "Kiểm tra hệ thống",
    Description = "Kiểm tra dịch vụ lõi, khả năng executor và lỗi gần nhất của từng vòng chạy.",
    Callback = function()
        local report = buildSystemDiagnostic()
        print("[HAOTOOL DIAGNOSTIC]\n" .. report)
        notify("🩺 Kiểm tra hệ thống", report, 10)
    end
})
UtilitySection:AddButton({
    Title = "Làm mới danh sách quái",
    Description = "Cập nhật danh sách quái hiện có",
    Callback = function()
        local enemies = getEnemyList()
        pcall(function()
            local option = Fluent.Options and Fluent.Options.SelectedMobDrop
            if option then
                option:SetValues(enemies)
                if not table.find(enemies, _G.SelectedMob) and enemies[1] ~= "(Không có quái)" then
                    _G.SelectedMob = enemies[1]
                    if option.SetValue then option:SetValue(enemies[1]) end
                end
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

end)

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

-- Đồng bộ lại giao diện theo đúng trạng thái trước khi chuyển server.
if type(teleportState) == "table" and Fluent and Fluent.Options then
    local teleportOptionMap = {
        AutoFarmLevel = "AutoFarmLevel",
        AutoFarmMastery = "AutoFarmMastery",
        MasteryWeaponDrop = "MasteryWeapon",
        SelectWeaponDrop = "SelectWeapon",
        FarmMethodDrop = "FarmMethod",
        SelectedMobDrop = "SelectedMob",
        FarmHeightSlider = "FarmHeight",
        FarmDistanceSlider = "FarmDistance",
        HoldFarmPositionToggle = "HoldFarmPosition",
        FreezeTargetToggle = "FreezeTarget",
        SafetyModeToggle = "SafetyMode",
        BackgroundAttackToggle = "BackgroundAttack",
        AttackDelaySlider = "AttackDelay",
        HitboxSizeSlider = "HitboxSize",
        BringMobToggle = "BringMob",
        BringRadiusSlider = "BringRadius",
        AutoSkillToggle = "AutoSkill",
        SkillCDSlider = "SkillCooldown",
        AutoFarmBoss = "AutoFarmBoss",
        SelectedBossDrop = "SelectedBoss",
        AutoFarmSeaBeast = "AutoFarmSeaBeast",
        AutoFarmObs = "AutoFarmObs",
        AutoFarmBone = "AutoFarmBone",
        AutoFarmFragment = "AutoFarmFragment",
        AutoFarmChest = "AutoFarmChest",
        AutoRaidToggle = "AutoRaid",
        AutoRaidFarmToggle = "AutoRaidFarm",
        RaidChipDrop = "RaidChip",
        AutoAwakeningToggle = "AutoAwakening",
        AutoFindFruitToggle = "AutoFruitFinder",
        AutoCollectFruitToggle = "AutoCollectFruit",
        FruitESPToggle = "FruitESP",
        AutoGachaToggle = "AutoGachaFruit",
        ESPPlayerToggle = "ESPPlayer",
        ESPTeamCheckToggle = "ESPTeamCheck",
        ESPMobToggle = "ESPMob",
        ESPBossToggle = "ESPBoss",
        ESPChestToggle = "ESPChest",
        ESPFlowerToggle = "ESPFlower",
        ESPIslandToggle = "ESPIsland",
        ESPDistSlider = "ESPDistance",
        IslandDrop = "SelectedIsland",
        NPCDrop = "SelectedNPC",
        BossTPDrop = "SelectedBossTP",
        AutoBusoToggle = "AutoHaki",
        AutoKenToggle = "AutoKen",
        AutoObsV2Toggle = "AutoObsV2",
        AutoDodgeToggle = "AutoDodge",
        WalkSpeedToggle = "WalkSpeedHack",
        WalkSpeedSlider = "WalkSpeedVal",
        JumpPowerToggle = "JumpPowerHack",
        JumpPowerSlider = "JumpPowerVal",
        InfiniteJumpToggle = "InfiniteJump",
        InfiniteEnergyToggle = "InfiniteEnergy",
        AutoStatsToggle = "AutoStats",
        StatDropdown = "StatToUpgrade",
        AntiAFKToggle = "AntiAFK",
        ServerHopNoFruitToggle = "ServerHopNoFruit",
        ESPPlayerColor = "ESPPlayerColor",
        ESPMobColorPick = "ESPMobColor",
        ESPBossColorPick = "ESPBossColor",
        ESPFruitColorPick = "ESPFruitColor",
    }

    for optionId, stateKey in pairs(teleportOptionMap) do
        local option = Fluent.Options[optionId]
        local value = teleportState[stateKey]
        if option and value ~= nil and option.SetValue then
            pcall(function() option:SetValue(value) end)
        end
    end
end


RuntimeEnv.HAOTOOL_UI_READY = createdTabCount == 9

-- Thông báo load thành công
notify(
    "HAOTOOL • Sẵn sàng",
    "Sea " .. WorldSea
        .. "  •  " .. #(WorldSea == 1 and QuestsSea1 or WorldSea == 2 and QuestsSea2 or QuestsSea3) .. " quest"
        .. "  •  " .. #islandNames .. " đảo"
        .. "\nGiao diện: " .. createdTabCount .. "/9 tab"
        .. "\nRightControl hoặc nút H để ẩn / hiện giao diện"
        .. (teleportReloadReady and "  •  Tự nạp server: ON" or "  •  Executor không hỗ trợ tự nạp"),
    6
)

print("=====================================")
print("⚡ HAOTOOL v2.1.4 — LOADED SUCCESSFULLY")
print("🌊 Sea: " .. WorldSea)
print("📌 RightControl to toggle GUI")
print("=====================================")
]========]

local RuntimeEnv = getgenv and getgenv() or _G
local storageFolder = "HaoToolHub"
local storageFile = storageFolder .. "/autoload.lua"
local sourceSaved = false

if makefolder then
    pcall(function()
        if not isfolder or not isfolder(storageFolder) then
            makefolder(storageFolder)
        end
    end)
end

if writefile then
    sourceSaved = pcall(function()
        writefile(storageFile, HAOTOOL_SOURCE)
    end)
end
RuntimeEnv.HAOTOOL_SOURCE_SAVED = sourceSaved

local runner, compileError = loadstring(HAOTOOL_SOURCE)
if not runner then
    RuntimeEnv.HAOTOOL_RUNNING = nil
    warn("[HAOTOOL] Không biên dịch được tool: " .. tostring(compileError))
else
    local ok, runError = pcall(runner)
    if not ok then
        RuntimeEnv.HAOTOOL_RUNNING = nil
        warn("[HAOTOOL] Tool gặp lỗi: " .. tostring(runError))
    end
end
