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
setDefault("NoAttackAnimation", true)
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
setDefault("AutoStoreFruit", true)
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
setDefault("SelectedFightingStyleShop", "Dark Step")

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
setDefault("LowServerMaxPlayers", 5)
setDefault("AutoRedeemExpCodes", true)
setDefault("AutoRedeemResetCodes", false)
setDefault("AutoChooseTeam", true)
setDefault("PreferredTeam", "Pirates")

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

-- Level và Mastery dùng chung quyền di chuyển; không cho hai vòng farm tranh nhau.
if _G.AutoFarmLevel and _G.AutoFarmMastery then
    _G.AutoFarmMastery = false
end

local TELEPORT_STATE_KEYS = {
    "AutoFarmLevel", "AutoFarmMastery", "MasteryWeapon",
    "AutoFarmBoss", "SelectedBoss", "AutoFarmSeaBeast",
    "AutoFarmObs", "AutoFarmBone", "AutoFarmFragment", "AutoFarmChest",
    "SelectWeapon", "FarmMethod", "SelectedMob",
    "BringMob", "BringRadius", "FarmHeight", "FarmDistance",
    "HoldFarmPosition", "FreezeTarget", "AttackDelay", "BackgroundAttack", "NoAttackAnimation", "HitboxSize",
    "SafetyMode", "AutoSkill", "SkillCooldown",
    "AutoRaid", "AutoRaidFarm", "AutoAwakening", "RaidChip",
    "AutoHaki", "AutoKen", "AutoObsV2", "AutoDodge", "SelectedFightingStyleShop",
    "AutoFruitFinder", "AutoCollectFruit", "AutoStoreFruit", "FruitESP", "AutoGachaFruit",
    "ESPPlayer", "ESPMob", "ESPBoss", "ESPChest", "ESPFlower",
    "ESPIsland", "ESPDistance", "ESPTeamCheck",
    "WalkSpeedHack", "WalkSpeedVal", "JumpPowerHack", "JumpPowerVal",
    "InfiniteJump", "InfiniteEnergy", "AntiAFK",
    "AutoStats", "StatToUpgrade", "ServerHopNoFruit", "LowServerMaxPlayers",
    "AutoRedeemExpCodes", "AutoRedeemResetCodes",
    "AutoChooseTeam", "PreferredTeam",
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
        env.HAOTOOL_RUN_TOKEN = {}
        env.HAOTOOL_RUNNING = nil
        env.HAOTOOL_LAST_FATAL_ERROR = tostring(runError)
        warn("[HAOTOOL] Auto reload lỗi: " .. tostring(runError))
    else
        env.HAOTOOL_LAST_FATAL_ERROR = nil
    end
else
    env.HAOTOOL_RUN_TOKEN = {}
    env.HAOTOOL_RUNNING = nil
    env.HAOTOOL_LAST_FATAL_ERROR = tostring(compileError)
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
