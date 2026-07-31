local HAOTOOL_SOURCE = [========[
local RuntimeEnv = getgenv and getgenv() or _G
local RequestedScriptVersion = "2.3.4"
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
    ⚡ HAOTOOL | BLOX FRUITS V2.3.4 — STABLE EDITION
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

-- Chọn phe phải chạy trước khi chờ Character: Blox Fruits chỉ tạo nhân vật sau khi chọn phe.
RuntimeEnv.HAOTOOL_TEAM_CONTROLLER_READY = false
RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Đang chờ màn hình chọn phe"

do
    local teleportPreference = RuntimeEnv.HAOTOOL_TELEPORT_STATE
    local autoFromTeleport = type(teleportPreference) == "table"
        and teleportPreference.AutoChooseTeam or nil
    local preferredFromTeleport = type(teleportPreference) == "table"
        and teleportPreference.PreferredTeam or nil
    local startupAutoEnabled = autoFromTeleport ~= false and _G.AutoChooseTeam ~= false
    local startupTeamName = (preferredFromTeleport or _G.PreferredTeam) == "Marines"
        and "Marines" or "Pirates"

    local function teamAlreadySelected()
        return Player.Team ~= nil and Player.Neutral == false
    end

    local function findStartupTeamButton(teamName)
        local playerGui = Player:FindFirstChildOfClass("PlayerGui")
        local chooseGui = playerGui and playerGui:FindFirstChild("ChooseTeam", true)
        if not chooseGui then return nil end

        local direct = chooseGui:FindFirstChild(teamName, true)
        if direct then
            if direct:IsA("GuiButton") then return direct end
            local directButton = direct:FindFirstChildWhichIsA("GuiButton", true)
            if directButton then return directButton end
        end

        local keyword = teamName == "Marines" and "marine" or "pirate"
        for _, object in ipairs(chooseGui:GetDescendants()) do
            if object:IsA("GuiButton") then
                local parts = {object.Name}
                if object:IsA("TextButton") then table.insert(parts, object.Text) end
                local ancestor = object.Parent
                for _ = 1, 4 do
                    if not ancestor then break end
                    table.insert(parts, ancestor.Name)
                    ancestor = ancestor.Parent
                end
                if string.find(string.lower(table.concat(parts, " ")), keyword, 1, true) then
                    return object
                end
            end
        end
        return nil
    end

    local function clickStartupTeamButton(button)
        if not button then return false end
        local fired = false

        if type(firesignal) == "function" then
            local ok = pcall(function()
                firesignal(button.Activated)
                if button:IsA("TextButton") or button:IsA("ImageButton") then
                    firesignal(button.MouseButton1Click)
                end
            end)
            fired = ok
        end

        if not fired and type(getconnections) == "function" then
            pcall(function()
                for _, connection in ipairs(getconnections(button.Activated)) do
                    if connection.Fire then
                        connection:Fire()
                        fired = true
                    elseif connection.Function then
                        task.spawn(connection.Function)
                        fired = true
                    end
                end
            end)
        end

        if not fired and button.Visible and button.AbsoluteSize.X > 0 and button.AbsoluteSize.Y > 0 then
            local center = button.AbsolutePosition + button.AbsoluteSize / 2
            local ok = pcall(function()
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                task.wait(0.06)
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
            end)
            fired = ok
        end
        return fired
    end

    local function tryStartupTeam(teamName)
        if teamAlreadySelected() then
            RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Đã có phe"
            return true, "Nhân vật đã có phe."
        end

        local remoteSent = false
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local commF = remotes and remotes:FindFirstChild("CommF_")
            if commF and commF:IsA("RemoteFunction") then
                commF:InvokeServer("SetTeam", teamName)
                remoteSent = true
            end
        end)

        task.wait(0.4)
        if teamAlreadySelected() then
            RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Đã chọn " .. teamName .. " bằng máy chủ"
            return true, "Đã chọn phe."
        end

        local button = findStartupTeamButton(teamName)
        local clicked = clickStartupTeamButton(button)
        if clicked then task.wait(0.65) end

        if teamAlreadySelected() then
            RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Đã chọn " .. teamName .. " trên giao diện"
            return true, "Đã chọn phe."
        end

        if remoteSent or clicked then
            RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Đã gửi yêu cầu, đang chờ game xác nhận"
            return false, "Đã gửi yêu cầu; đang chờ game xác nhận."
        end
        RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Chưa tìm thấy Remote hoặc nút chọn phe"
        return false, "Chưa tìm thấy màn hình chọn phe."
    end

    RuntimeEnv.HAOTOOL_STARTUP_TEAM_PICKER = tryStartupTeam

    task.spawn(function()
        if not startupAutoEnabled then
            RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS = "Tự chọn phe đang tắt"
            return
        end

        local deadline = os.clock() + 120
        while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken
            and RuntimeEnv.HAOTOOL_TEAM_CONTROLLER_READY ~= true
            and not teamAlreadySelected() and os.clock() < deadline do
            tryStartupTeam(startupTeamName)
            task.wait(0.8)
        end
    end)
end

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
local Character = Player.Character
Player.CharacterAdded:Connect(function(char)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    Character = char
    task.wait(0.5) -- Đợi character load xong
end)

-- Nhận diện Sea hiện tại dựa trên PlaceId (kèm Fallback theo Workspace nếu ở Server riêng/Subplace)
local PlaceId = game.PlaceId
local WorldSea = 1
if PlaceId == 2753915549 then 
    WorldSea = 1
elseif PlaceId == 4442272183 then 
    WorldSea = 2
elseif PlaceId == 7449423635 then 
    WorldSea = 3
else
    local map = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("WorldOrigin")
    local npcs = Workspace:FindFirstChild("NPCs")
    if (map and (map:FindFirstChild("Cafe") or map:FindFirstChild("Kingdom of Rose") or map:FindFirstChild("Green Zone") or map:FindFirstChild("Ice Side")))
        or (npcs and (npcs:FindFirstChild("Manager") or npcs:FindFirstChild("Bartilo"))) then
        WorldSea = 2
    elseif (map and (map:FindFirstChild("Tiki Outpost") or map:FindFirstChild("Turtle") or map:FindFirstChild("Port Town") or map:FindFirstChild("Haunted Castle")))
        or (npcs and npcs:FindFirstChild("Horned Man")) then
        WorldSea = 3
    else
        WorldSea = 1
    end
end
-- Truy cập dữ liệu người chơi theo một đường duy nhất, chịu được lúc Data tải chậm.
local function getPlayerData()
    return Player:FindFirstChild("Data")
end

local function getPlayerValue(name, fallback)
    local data = getPlayerData()
    local valueObject = data and data:FindFirstChild(name)
    if not valueObject then return fallback end
    local ok, value = pcall(function() return valueObject.Value end)
    if ok and value ~= nil then return value end
    return fallback
end

local function getPlayerLevel()
    return tonumber(getPlayerValue("Level", 1)) or 1
end

local function getPlayerBeli()
    return tonumber(getPlayerValue("Beli", 0)) or 0
end

------------------------------------------------------------
-- PHẦN 1.5: LOAD FLUENT UI LIBRARY
------------------------------------------------------------

local Fluent, SaveManager, InterfaceManager

-- Màn hình lỗi độc lập với Fluent: lỗi sớm vẫn được hiển thị trong game.
local function showStartupError(message)
    RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = tostring(message)
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        local playerGui = Player:FindFirstChild("PlayerGui") or Player:WaitForChild("PlayerGui")
        local old = coreGui:FindFirstChild("HAOTOOL_StartupError")
            or playerGui:FindFirstChild("HAOTOOL_StartupError")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "HAOTOOL_StartupError"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 2000000

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(470, 150)
        frame.Position = UDim2.new(0.5, -235, 0.12, 0)
        frame.BackgroundColor3 = Color3.fromRGB(32, 22, 52)
        frame.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -28, 1, -28)
        label.Position = UDim2.fromOffset(14, 14)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(245, 238, 255)
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.Text = "HAOTOOL không thể khởi động\n\n" .. tostring(message)
        label.Parent = frame

        local parentOk = pcall(function() gui.Parent = coreGui end)
        if not parentOk or not gui.Parent then gui.Parent = playerGui end
    end)
end
RuntimeEnv.HAOTOOL_SHOW_STARTUP_ERROR = showStartupError

local function executeLibrarySource(source, label)
    if type(source) ~= "string" or source == "" then
        return nil, label .. ": không có mã nguồn"
    end
    local runner, compileError = loadstring(source)
    if not runner then return nil, label .. ": " .. tostring(compileError) end
    local ok, result = pcall(runner)
    if not ok then return nil, label .. ": " .. tostring(result) end
    return result
end

local fluentErrors = {}
local remoteOk, remoteSource = pcall(function()
    return game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/download/1.1.0/main.lua", true)
end)
if remoteOk then
    local remoteError
    Fluent, remoteError = executeLibrarySource(remoteSource, "Fluent mạng")
    if remoteError then table.insert(fluentErrors, remoteError) end
else
    table.insert(fluentErrors, "Mạng: " .. tostring(remoteSource))
end

if not Fluent then
    local embeddedSource = RuntimeEnv.HAOTOOL_EMBEDDED_FLUENT_SOURCE
    if not embeddedSource and type(readfile) == "function" then
        pcall(function() embeddedSource = readfile("HaoToolHub/fluent.lua") end)
    end
    local embeddedError
    Fluent, embeddedError = executeLibrarySource(embeddedSource, "Fluent nhúng")
    if embeddedError then table.insert(fluentErrors, embeddedError) end
end

if not Fluent then
    RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
    RuntimeEnv.HAOTOOL_RUNNING = nil
    local message = "Không nạp được Fluent UI. " .. table.concat(fluentErrors, " | ")
    showStartupError(message)
    warn("[HAOTOOL] " .. message)
    error(message)
end

pcall(function()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local oldError = CoreGui:FindFirstChild("HAOTOOL_StartupError")
        or (playerGui and playerGui:FindFirstChild("HAOTOOL_StartupError"))
    if oldError then oldError:Destroy() end
end)
RuntimeEnv.HAOTOOL_EMBEDDED_FLUENT_SOURCE = nil

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
setDefault("AutoSaberQuest", false)
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
    "AutoHaki", "AutoKen", "AutoObsV2", "AutoDodge", "AutoSaberQuest", "SelectedFightingStyleShop",
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
local activeFruitTarget = nil
local farmState = "idle"
local lastAttackTime = 0
local lastAttackMethod = "Chưa đánh"
local lastCombatMaintenance = 0
local lastEquipCheck = 0
local lastPreparedTarget = nil
local restoreFrozenMobs = function() end
local userPointerActive = false
local sendingVirtualAttack = false
local manualPointerPauseUntil = 0
local equipWeapon
local damageWatchTarget = nil
local damageWatchHealth = nil
local damageWatchStartedAt = 0
local lastConfirmedDamageAt = 0
local lastNetAttackTime = 0
local manualMovementActive = false
local manualMovementPauseUntil = 0
local manualTravelSerial = 0
local skillSequenceBusy = false
local silentAnimator = nil
local silentAnimationConnection = nil
local suppressAttackAnimationUntil = 0

local ACTION_ANIMATION_PRIORITIES = {
    [Enum.AnimationPriority.Action] = true,
    [Enum.AnimationPriority.Action2] = true,
    [Enum.AnimationPriority.Action3] = true,
    [Enum.AnimationPriority.Action4] = true,
}

-- Chỉ một chế độ được quyền di chuyển nhân vật tại một thời điểm.
local function getActiveMovementMode()
    if manualMovementActive or os.clock() < manualMovementPauseUntil then return "manual" end
    -- Trái đang tồn tại được nhặt trước, sau đó tự trả quyền di chuyển cho farm.
    if _G.AutoCollectFruit and activeFruitTarget and activeFruitTarget.Parent then return "fruit" end
    if _G.AutoSaberQuest then return "saber" end
    if _G.AutoFarmLevel then return "level" end
    if _G.AutoFarmBoss then return "boss" end
    if _G.AutoFarmMastery then return "mastery" end
    if _G.AutoFarmSeaBeast then return "sea_beast" end
    if _G.AutoFarmBone then return "bone" end
    if _G.AutoFarmFragment then return "fragment" end
    if _G.AutoRaid and _G.AutoRaidFarm then return "raid" end
    if _G.AutoFarmChest then return "chest" end
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
    local hadTarget = activeFarmTarget ~= nil
    activeFarmTarget = nil
    if wasAttacking then
        farmState = "idle"
        setNoclip(false)
    end
    if wasAttacking or hadTarget then
        restoreFrozenMobs()
        lastPreparedTarget = nil
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
-- Hành trình xa đi theo 3 chặng: nâng độ cao, bay ngang, rồi hạ xuống.
-- Cách này giữ nhân vật cách xa mặt biển khi chuyển giữa các đảo/map.
local LONG_TRAVEL_DISTANCE = 500
local MIN_SAFE_CRUISE_Y = 350
local SAFE_CRUISE_CLEARANCE = 120

local function toTarget(targetCFrame)
    if typeof(targetCFrame) == "Vector3" then targetCFrame = CFrame.new(targetCFrame) end
    if typeof(targetCFrame) ~= "CFrame" then return false end
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
    local function tweenSegment(segmentCFrame)
        if requestId ~= movementSerial or not rootPart.Parent then return false end

        local segmentDistance = (rootPart.Position - segmentCFrame.Position).Magnitude
        if segmentDistance < 15 then
            rootPart.CFrame = segmentCFrame
            rootPart.AssemblyLinearVelocity = Vector3.zero
            return true
        end

        local tween = TweenService:Create(
            rootPart,
            TweenInfo.new(segmentDistance / speed, Enum.EasingStyle.Linear),
            {CFrame = segmentCFrame}
        )
        currentTween = tween
        tween:Play()
        local playbackState = tween.Completed:Wait()

        if currentTween == tween then currentTween = nil end
        if requestId ~= movementSerial or playbackState == Enum.PlaybackState.Cancelled then return false end
        return (rootPart.Position - segmentCFrame.Position).Magnitude <= 25
    end

    setNoclip(true)

    local startPosition = rootPart.Position
    local targetPosition = targetCFrame.Position
    local horizontalOffset = Vector3.new(
        targetPosition.X - startPosition.X,
        0,
        targetPosition.Z - startPosition.Z
    )

    if horizontalOffset.Magnitude >= LONG_TRAVEL_DISTANCE then
        local cruiseY = math.max(
            MIN_SAFE_CRUISE_Y,
            startPosition.Y + SAFE_CRUISE_CLEARANCE,
            targetPosition.Y + SAFE_CRUISE_CLEARANCE
        )
        local liftCFrame = CFrame.new(startPosition.X, cruiseY, startPosition.Z)
        local cruiseCFrame = CFrame.new(targetPosition.X, cruiseY, targetPosition.Z)

        if not tweenSegment(liftCFrame) or not tweenSegment(cruiseCFrame) then
            if requestId == movementSerial then
                farmState = "idle"
                setNoclip(false)
            end
            return false
        end
    end

    local arrived = tweenSegment(targetCFrame)
    if requestId ~= movementSerial then return false end
    if farmState == "moving" then farmState = "idle" end
    setNoclip(false)

    return arrived and (rootPart.Position - targetCFrame.Position).Magnitude <= 25
end

-- Dịch chuyển thủ công có quyền ưu tiên, tránh vòng farm hủy tween ngay sau khi bấm nút.
local function manualTeleportTo(targetCFrame)
    if typeof(targetCFrame) == "Vector3" then targetCFrame = CFrame.new(targetCFrame) end
    if typeof(targetCFrame) ~= "CFrame" then return false end

    manualTravelSerial = manualTravelSerial + 1
    local travelId = manualTravelSerial
    manualMovementActive = true
    manualMovementPauseUntil = os.clock() + 3
    stopFarmMovement()

    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart and (rootPart.Position - targetCFrame.Position).Magnitude > 3500 then
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local commF = remotes and remotes:FindFirstChild("CommF_")
            if commF then commF:InvokeServer("requestEntrance", targetCFrame.Position) end
        end)
        task.wait(0.8)
    end

    local arrived = toTarget(targetCFrame)
    if travelId == manualTravelSerial then
        manualMovementActive = false
        manualMovementPauseUntil = os.clock() + 3
    end
    return arrived
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
local combatControllerCache = nil
local lastCombatControllerResolve = 0

local function findAttackController(value, depth, visited)
    if type(value) ~= "table" then return nil end
    visited = visited or {}
    if visited[value] then return nil end
    visited[value] = true

    local direct = rawget(value, "activeController")
    if type(direct) == "table"
        and (type(rawget(direct, "attack")) == "function"
            or type(rawget(direct, "Attack")) == "function") then
        return direct
    end
    if type(rawget(value, "attack")) == "function"
        or type(rawget(value, "Attack")) == "function" then
        return value
    end
    if depth <= 0 then return nil end

    local found = nil
    pcall(function()
        for _, nested in pairs(value) do
            found = findAttackController(nested, depth - 1, visited)
            if found then break end
        end
    end)
    return found
end

local function findControllerInFunction(fn)
    if type(fn) ~= "function" then return nil end
    local found = nil
    local bulkGetter = getupvalues or (debug and debug.getupvalues)
    if type(bulkGetter) == "function" then
        pcall(function()
            found = findAttackController(bulkGetter(fn), 3, {})
        end)
        if found then return found end
    end

    local singleGetter = getupvalue or (debug and debug.getupvalue)
    if type(singleGetter) == "function" then
        for index = 1, 30 do
            local ok, first, second = pcall(singleGetter, fn, index)
            if not ok then break end
            local value = second ~= nil and second or first
            if value == nil then break end
            found = findAttackController(value, 3, {})
            if found then return found end
        end
    end
    return nil
end

local function findControllerFromGC()
    if type(getgc) ~= "function" then return nil end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end

    for _, value in ipairs(objects) do
        if type(value) == "table" then
            local direct = rawget(value, "activeController")
            if type(direct) == "table"
                and (type(rawget(direct, "attack")) == "function"
                    or type(rawget(direct, "Attack")) == "function") then
                return direct
            end

            local attackFn = rawget(value, "attack") or rawget(value, "Attack")
            if type(attackFn) == "function"
                and (rawget(value, "timeToNextAttack") ~= nil
                    or rawget(value, "hitboxMagnitude") ~= nil
                    or rawget(value, "attacking") ~= nil) then
                return value
            end
        end
    end
    return nil
end

local function resolveCombatController(force)
    if combatControllerCache
        and (type(combatControllerCache.attack) == "function"
            or type(combatControllerCache.Attack) == "function") then
        return combatControllerCache
    end

    local now = os.clock()
    if not force and now - lastCombatControllerResolve < 2 then return nil end
    lastCombatControllerResolve = now

    local controller = nil
    local playerScripts = Player:FindFirstChild("PlayerScripts")
    local combatModule = playerScripts and playerScripts:FindFirstChild("CombatFramework", true)
    if combatModule and combatModule:IsA("ModuleScript") then
        local ok, framework = pcall(require, combatModule)
        if ok then
            controller = findAttackController(framework, 4, {})
                or findControllerInFunction(framework)
        end
    end
    controller = controller or findControllerFromGC()
    if controller then combatControllerCache = controller end
    return controller
end

-- Chỉ làm trong suốt animation đánh thường, không Stop track để marker damage vẫn được xử lý.
local function bindSilentAnimationWatcher(humanoid)
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end
    if animator == silentAnimator and silentAnimationConnection then return true end

    if silentAnimationConnection then
        pcall(function() silentAnimationConnection:Disconnect() end)
        silentAnimationConnection = nil
    end

    silentAnimator = animator
    silentAnimationConnection = animator.AnimationPlayed:Connect(function(track)
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
        task.defer(function()
            if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
            if not _G.NoAttackAnimation or skillSequenceBusy then return end
            if os.clock() > suppressAttackAnimationUntil then return end
            if not ACTION_ANIMATION_PRIORITIES[track.Priority] then return end
            pcall(function() track:AdjustWeight(0, 0) end)
        end)
    end)
    return true
end

local function armSilentAttack(humanoid)
    if not _G.NoAttackAnimation or skillSequenceBusy then return end
    if bindSilentAnimationWatcher(humanoid) then
        suppressAttackAnimationUntil = os.clock() + 0.18
    end
end

local function restoreAttackAnimationWeights()
    suppressAttackAnimationUntil = 0
    local animator = silentAnimator
    if not animator or not animator.Parent then return end
    pcall(function()
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if ACTION_ANIMATION_PRIORITIES[track.Priority] then
                track:AdjustWeight(1, 0.05)
            end
        end
    end)
end

-- Ưu tiên bộ điều khiển chiến đấu thật để đánh nền mà không chiếm chuột.
local function attack()
    local now = os.clock()
    local delay = math.clamp(tonumber(_G.AttackDelay) or 0.05, 0.01, 0.50)
    if _G.SafetyMode then delay = math.max(delay, 0.05) end
    if now - lastAttackTime < delay then return false end
    lastAttackTime = now
    checkHaki()

    local target = activeFarmTarget
    local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    if target ~= damageWatchTarget then
        damageWatchTarget = target
        damageWatchHealth = targetHumanoid and targetHumanoid.Health or nil
        damageWatchStartedAt = now
        lastConfirmedDamageAt = 0
    elseif targetHumanoid and damageWatchHealth and targetHumanoid.Health < damageWatchHealth then
        lastConfirmedDamageAt = now
    end
    if targetHumanoid then damageWatchHealth = targetHumanoid.Health end
    local noDamageFor = lastConfirmedDamageAt > 0
        and (now - lastConfirmedDamageAt) or (now - damageWatchStartedAt)

    local char = Player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    armSilentAttack(humanoid)
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool and equipWeapon then
        equipWeapon(_G.SelectWeapon or "Melee")
        tool = char:FindFirstChildOfClass("Tool")
    end
    if not tool then
        lastAttackMethod = "Không tìm thấy vũ khí trong Balo"
        return false
    end

    local methods = {}

    -- Bộ điều khiển thật: không thoát sớm chỉ vì pcall thành công.
    local controller = resolveCombatController(false)
    if controller then
        local controllerOk = pcall(function()
            controller.attacking = false
            controller.blocking = false
            controller.timeToNextAttack = 0
            controller.timeToNextBlock = 0
            controller.hitboxMagnitude = math.max(tonumber(controller.hitboxMagnitude) or 0, 60)
            local controllerAttack = controller.attack or controller.Attack
            if type(controllerAttack) == "function" then controllerAttack(controller) end
        end)
        if controllerOk then
            table.insert(methods, "Controller")
        else
            combatControllerCache = nil
        end
    end

    local toolOk = pcall(function() tool:Activate() end)
    if toolOk then table.insert(methods, "Tool") end

    -- Một số Tool mới có remote click riêng.
    local leftClickRemote = tool:FindFirstChild("LeftClickRemote")
    if leftClickRemote and leftClickRemote:IsA("RemoteEvent") and targetRoot then
        local leftClickOk = pcall(function()
            local direction = targetRoot.Position - char:GetPivot().Position
            if direction.Magnitude > 0 then direction = direction.Unit end
            leftClickRemote:FireServer(direction, 1)
        end)
        if leftClickOk then table.insert(methods, "ToolRemote") end
    end

    -- VirtualUser gửi đòn đánh vào bộ điều khiển game, không click lên nút menu.
    if RuntimeEnv.HAOTOOL_MENU_VISIBLE ~= true
        and not userPointerActive and now >= manualPointerPauseUntil
        and not UserInputService:GetFocusedTextBox() then
        sendingVirtualAttack = true
        local virtualOk = pcall(function()
            local camera = workspace.CurrentCamera
            local cameraCFrame = camera and camera.CFrame or CFrame.new()
            VirtualUser:Button1Down(Vector2.new(0, 0), cameraCFrame)
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0, 0), cameraCFrame)
        end)
        sendingVirtualAttack = false
        if virtualOk then table.insert(methods, "VirtualUser") end

        -- Nếu chưa có damage, gửi click vào giữa màn hình nhưng chỉ khi menu đã đóng.
        if noDamageFor >= 0.75 then
            sendingVirtualAttack = true
            local inputOk = pcall(function()
                local camera = workspace.CurrentCamera
                local size = camera and camera.ViewportSize or Vector2.new(800, 600)
                local x, y = math.floor(size.X * 0.5), math.floor(size.Y * 0.5)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.012)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
            sendingVirtualAttack = false
            if inputOk then table.insert(methods, "VIM") end
        end
    end

    -- Đường Net dùng BasePart thật trong danh sách hit; chỉ báo thành công khi remote thực sự được gửi.
    if target and targetRoot and now - lastNetAttackTime >= math.max(delay, 0.10) then
        lastNetAttackTime = now
        local netFired = false
        local netOk = pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local net = modules and modules:FindFirstChild("Net")
            local registerAttack = net and net:FindFirstChild("RE/RegisterAttack")
            local registerHit = net and net:FindFirstChild("RE/RegisterHit")
            if not registerAttack or not registerHit then return end
            if not registerAttack:IsA("RemoteEvent") or not registerHit:IsA("RemoteEvent") then return end
            local hitList = {targetRoot}
            registerAttack:FireServer(0)
            registerHit:FireServer(targetRoot, hitList)
            netFired = true
        end)
        if netOk and netFired then table.insert(methods, "NetHit") end
    end

    local damageState = lastConfirmedDamageAt > 0 and now - lastConfirmedDamageAt < 1
        and "Damage OK" or string.format("chờ damage %.1fs", noDamageFor)
    lastAttackMethod = damageState .. " • " .. (#methods > 0 and table.concat(methods, "+") or "không có đường đánh")
    return #methods > 0
end-- ====== Auto Skill (dùng Z, X, C, V) ======
local lastSkillTime = 0
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
equipWeapon = function(weaponType)
    pcall(function()
        local char = Player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local backpack = Player:FindFirstChild("Backpack")
        if not char or not humanoid then return end

        weaponType = weaponType or _G.SelectWeapon or "Melee"

        -- Nếu nhân vật đã cầm đúng loại vũ khí trên tay
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped then
            local eqName = equipped.Name
            local eqTip = equipped.ToolTip or ""
            local isMatch = false
            if weaponType == "Melee" and (table.find(MeleeNames, eqName) or eqTip == "Melee" or eqName == "Combat" or eqTip:find("Melee") or eqName:lower():find("combat") or eqName:lower():find("style")) then isMatch = true end
            if weaponType == "Sword" and (table.find(SwordNames, eqName) or eqTip == "Sword" or eqTip:find("Sword") or eqName:lower():find("sword")) then isMatch = true end
            if weaponType == "Gun" and (table.find(GunNames, eqName) or eqTip == "Gun" or eqTip:find("Gun") or eqName:lower():find("gun")) then isMatch = true end
            if weaponType == "Blox Fruit" and (eqTip == "Blox Fruit" or eqName:find("Fruit") or eqTip:find("Fruit") or eqName:lower():find("fruit")) then isMatch = true end
            if isMatch then return end
        end

        -- Tìm trong Backpack vũ khí khớp với loại được chọn
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local tName = tool.Name
                    local tTip = tool.ToolTip or ""
                    local match = false
                    if weaponType == "Melee" and (table.find(MeleeNames, tName) or tTip == "Melee" or tName == "Combat" or tTip:find("Melee") or tName:lower():find("combat") or tName:lower():find("style")) then match = true end
                    if weaponType == "Sword" and (table.find(SwordNames, tName) or tTip == "Sword" or tTip:find("Sword") or tName:lower():find("sword")) then match = true end
                    if weaponType == "Gun" and (table.find(GunNames, tName) or tTip == "Gun" or tTip:find("Gun") or tName:lower():find("gun")) then match = true end
                    if weaponType == "Blox Fruit" and (tTip == "Blox Fruit" or tName:find("Fruit") or tTip:find("Fruit") or tName:lower():find("fruit")) then match = true end

                    if match then
                        tool.Parent = char
                        humanoid:EquipTool(tool)
                        return
                    end
                end
            end

            -- Fallback: Cầm Tool đầu tiên có trong Backpack
            local fallback = backpack:FindFirstChildOfClass("Tool")
            if fallback then
                fallback.Parent = char
                humanoid:EquipTool(fallback)
            end
        end
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
    local hitboxLimit = _G.SafetyMode and 18 or 60
    local hitboxSize = math.clamp(tonumber(_G.HitboxSize) or 14, 4, hitboxLimit)
    local verticalSize = math.clamp(farmHeight * 2.5 + 20, hitboxSize, 90)

    rootPart.Size = Vector3.new(hitboxSize, verticalSize, hitboxSize)

    if _G.FreezeTarget then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        -- Không neo/PlatformStand mục tiêu: hai trạng thái này có thể làm bộ đánh của game bỏ qua sát thương.
        humanoid.PlatformStand = false
        rootPart.Anchored = false
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
    if not _G.BringMob then return end
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
local function getFruitHandle(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end

    local handle = obj:FindFirstChild("Handle", true)
    if handle and handle:IsA("BasePart") then return handle end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end

    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return part
end

local function isFruitObject(obj)
    if not obj or not (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart")) then
        return false
    end
    local lowerName = string.lower(obj.Name)
    local hasFruitName = string.find(lowerName, "fruit", 1, true) ~= nil
        or string.find(lowerName, "trái", 1, true) ~= nil
    return hasFruitName and getFruitHandle(obj) ~= nil
end

local function getSpawnedFruits()
    local fruits, seen = {}, {}
    local function addFrom(container, recursive)
        if not container then return end
        local objects = recursive and container:GetDescendants() or container:GetChildren()
        for _, obj in ipairs(objects) do
            if isFruitObject(obj) and not seen[obj] then
                seen[obj] = true
                table.insert(fruits, obj)
            end
        end
    end

    addFrom(workspace, false)
    for _, folderName in ipairs({"Fruit", "Fruits", "SpawnedFruits"}) do
        addFrom(workspace:FindFirstChild(folderName), true)
    end
    return fruits
end

local function findNearestFruit()
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local closest, closestDistance = nil, math.huge
    for _, fruit in ipairs(getSpawnedFruits()) do
        local handle = getFruitHandle(fruit)
        if handle then
            local distance = rootPart and (handle.Position - rootPart.Position).Magnitude or 0
            if distance < closestDistance then
                closest, closestDistance = fruit, distance
            end
        end
    end
    return closest, closestDistance
end

local function touchFruit(fruit)
    local handle = getFruitHandle(fruit)
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not handle or not rootPart then return false end

    if type(firetouchinterest) == "function" then
        local ok = runFeature("Nhặt trái", function()
            firetouchinterest(rootPart, handle, 0)
            task.wait(0.08)
            firetouchinterest(rootPart, handle, 1)
        end)
        return ok
    end

    -- Fallback: chạm vật lý vào Handle khi executor không có firetouchinterest.
    rootPart.CFrame = handle.CFrame
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.35)
    return not fruit.Parent or getFruitHandle(fruit) == nil
end

-- Khi đang ở dưới biển, nổi thẳng lên rồi ghé bờ trước khi bay tới trái trên đất.
local moveToFruitSafely
do
local WATER_SAMPLE_OFFSETS = {
    Vector2.new(0, 0),
    Vector2.new(12, 0), Vector2.new(-12, 0),
    Vector2.new(0, 12), Vector2.new(0, -12),
    Vector2.new(28, 0), Vector2.new(-28, 0),
    Vector2.new(0, 28), Vector2.new(0, -28),
}
local SHORE_SEARCH_RADII = {24, 50, 90, 150, 240, 360, 520, 750, 1050, 1400}

local function rayResultIsWater(result)
    if not result then return false end
    if result.Material == Enum.Material.Water then return true end
    local instanceName = result.Instance and string.lower(result.Instance.Name) or ""
    return instanceName == "sea"
        or string.find(instanceName, "water", 1, true) ~= nil
        or string.find(instanceName, "ocean", 1, true) ~= nil
end

local function detectWaterSurfaceY(position, fruit)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character, fruit}
    params.IgnoreWater = false
    local originY = math.max(position.Y + 500, 4000)

    for _, offset in ipairs(WATER_SAMPLE_OFFSETS) do
        local origin = Vector3.new(position.X + offset.X, originY, position.Z + offset.Y)
        local result = Workspace:Raycast(origin, Vector3.new(0, -8000, 0), params)
        if rayResultIsWater(result) then
            return result.Position.Y
        end
    end
    return nil
end

local function characterIsUnderwater(rootPart, humanoid, fruit)
    if not rootPart or not humanoid then return false, nil end
    local swimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
    local surfaceY = detectWaterSurfaceY(rootPart.Position, fruit)
    if surfaceY then
        return swimming or rootPart.Position.Y < surfaceY - 2, surfaceY
    end
    if swimming then
        -- Blox Fruits thường đặt mặt biển gần Y=0; cộng thêm độ cao để hỗ trợ hồ ở vị trí cao.
        return true, math.max(0, rootPart.Position.Y + 35)
    end
    return false, nil
end

local function validShoreHit(result, surfaceY)
    if not result or rayResultIsWater(result) then return false end
    if result.Position.Y < surfaceY + 1 or result.Normal.Y < 0.35 then return false end
    local instance = result.Instance
    return instance and (instance:IsA("Terrain") or instance.CanCollide == true)
end

local function findNearestShoreCFrame(position, surfaceY)
    local params = RaycastParams.new()
    local map = Workspace:FindFirstChild("Map")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    local include = {}
    if map then table.insert(include, map) end
    if terrain then table.insert(include, terrain) end
    if #include == 0 then return nil end
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = include
    params.IgnoreWater = true

    local bestPosition, bestScore = nil, math.huge
    local originY = surfaceY + 2500
    for ringIndex, radius in ipairs(SHORE_SEARCH_RADII) do
        local angleOffset = ringIndex % 2 == 0 and math.pi / 16 or 0
        for step = 0, 15 do
            local angle = angleOffset + step * math.pi / 8
            local x = position.X + math.cos(angle) * radius
            local z = position.Z + math.sin(angle) * radius
            local origin = Vector3.new(x, originY, z)
            local result = Workspace:Raycast(origin, Vector3.new(0, -5000, 0), params)
            if validShoreHit(result, surfaceY) then
                local score = radius + math.abs(result.Position.Y - surfaceY) * 0.05
                if score < bestScore then
                    bestScore = score
                    bestPosition = result.Position + Vector3.new(0, 6, 0)
                end
            end
        end
        if bestPosition then break end
    end
    return bestPosition and CFrame.new(bestPosition) or nil
end

local function fruitTravelIsActive(fruit, manual)
    if not fruit or not fruit.Parent or not getFruitHandle(fruit) then return false end
    if manual then return true end
    return _G.AutoCollectFruit and activeFruitTarget == fruit and modeCanMove("fruit")
end

moveToFruitSafely = function(fruit, manual, statusCallback)
    local handle = getFruitHandle(fruit)
    local character = Player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not handle or not rootPart or not humanoid then return false end

    local function report(message)
        if type(statusCallback) == "function" then
            pcall(statusCallback, message)
        end
    end
    local function travel(targetCFrame)
        if not fruitTravelIsActive(fruit, manual) then return false end
        if manual then return manualTeleportTo(targetCFrame) end
        return toTarget(targetCFrame)
    end

    local underwater, surfaceY = characterIsUnderwater(rootPart, humanoid, fruit)
    local fruitIsAboveWater = surfaceY and handle.Position.Y > surfaceY + 2
    if underwater and fruitIsAboveWater then
        report("Đang nổi thẳng lên mặt nước trước khi tới " .. fruit.Name)
        local surfacePoint = CFrame.new(rootPart.Position.X, surfaceY + 12, rootPart.Position.Z)
        if not travel(surfacePoint) then return false end
        task.wait(0.15)
        if not fruitTravelIsActive(fruit, manual) then return false end

        rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end
        local shorePoint = findNearestShoreCFrame(rootPart.Position, surfaceY)
        if shorePoint then
            report("Đang lên bờ trước khi tới " .. fruit.Name)
            if not travel(shorePoint) then return false end
            task.wait(0.12)
        else
            report("Đã lên mặt nước; không tìm thấy bờ gần nên tiếp tục trên mặt nước")
        end
    end

    if not fruitTravelIsActive(fruit, manual) then return false end
    handle = getFruitHandle(fruit)
    if not handle then return false end
    report("Đang di chuyển tới " .. fruit.Name)
    return travel(handle.CFrame * CFrame.new(0, 2, 0))
end
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
            -- gsub trả về 2 giá trị; ngoặc ép còn 1 giá trị cho table.insert.
            table.insert(bosses, (clean:gsub("(%a)([%w']*)", function(a, b)
                return string.upper(a) .. b
            end)))
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

local function getBossStatusList(bossNames)
    local labels, labelToName, nameToLabel = {}, {}, {}
    local aliveNames = {}

    for _, bossName in ipairs(bossNames or getBossList()) do
        local boss = findBoss(bossName)
        local label
        if boss then
            label = "🟢 " .. bossName .. " — Đang xuất hiện"
            table.insert(aliveNames, bossName)
        else
            label = "⚫ " .. bossName .. " — Chưa xuất hiện"
        end
        table.insert(labels, label)
        labelToName[label] = bossName
        nameToLabel[bossName] = label
    end

    local summary = "Đang xuất hiện: " .. #aliveNames .. "/" .. #labels
    if #aliveNames > 0 then
        summary = summary .. "\n🟢 " .. table.concat(aliveNames, ", ")
    else
        summary = summary .. "\nHiện chưa có Trùm nào trong máy chủ."
    end
    return labels, labelToName, nameToLabel, summary, table.concat(labels, "\n")
end

-- ====== Chuyển máy chủ, ưu tiên máy chủ ít người ======
local serverHopBusy = false
local function serverHop(preferLowPopulation, wantedMaximum)
    if serverHopBusy then return false, "Hệ thống đang tìm máy chủ." end
    serverHopBusy = true

    local ok, result = pcall(function()
        local available, visitedFallback = {}, {}
        local visited = RuntimeEnv.HAOTOOL_VISITED_SERVERS or {}
        RuntimeEnv.HAOTOOL_VISITED_SERVERS = visited
        local cursor = nil

        -- Đọc tối đa 300 máy chủ công khai rồi sắp theo số người và độ trễ.
        for _ = 1, 3 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor and cursor ~= "" then
                url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
            end

            local data = HttpService:JSONDecode(game:HttpGet(url, true))
            for _, server in ipairs(data.data or {}) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(visited[server.id] and visitedFallback or available, server)
                end
            end
            cursor = data.nextPageCursor
            if not cursor or cursor == "" then break end
        end

        local candidates = #available > 0 and available or visitedFallback
        table.sort(candidates, function(a, b)
            if a.playing == b.playing then
                return (tonumber(a.ping) or math.huge) < (tonumber(b.ping) or math.huge)
            end
            return a.playing < b.playing
        end)
        if #candidates == 0 then error("Không tìm thấy máy chủ còn chỗ trống.") end

        local chosen = nil
        if preferLowPopulation then
            local maximum = math.clamp(tonumber(wantedMaximum) or 5, 1, 12)
            for _, server in ipairs(candidates) do
                if server.playing <= maximum then
                    chosen = server
                    break
                end
            end
            chosen = chosen or candidates[1]
        else
            chosen = candidates[math.random(1, math.min(#candidates, 20))]
        end

        visited[chosen.id] = true
        saveTeleportState()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, Player)
        return chosen
    end)

    serverHopBusy = false
    if not ok then return false, tostring(result) end
    return true, result
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

-- ====== Cửa hàng cận chiến & kỹ năng ======
local CombatShop = {}
do
local styleEntries = {
    {
        Id = "Dark Step",
        Label = "Dark Step — 150.000 Beli",
        Price = "150.000 Beli",
        Requirement = "Không yêu cầu.",
        Command = "BuyBlackLeg",
    },
    {
        Id = "Electric",
        Label = "Electric — 500.000 Beli",
        Price = "500.000 Beli",
        Requirement = "Không yêu cầu.",
        Command = "BuyElectro",
    },
    {
        Id = "Water Kung Fu",
        Label = "Water Kung Fu — 750.000 Beli",
        Price = "750.000 Beli",
        Requirement = "Không yêu cầu.",
        Command = "BuyFishmanKarate",
    },
    {
        Id = "Dragon Breath",
        Label = "Dragon Breath — 1.500 Mảnh",
        Price = "1.500 Mảnh",
        Requirement = "Từ Biển 2.",
        Special = "DragonBreath",
    },
    {
        Id = "Superhuman",
        Label = "Superhuman — 3.000.000 Beli",
        Price = "3.000.000 Beli",
        Requirement = "300 thông thạo Dark Step, Electric, Water Kung Fu và Dragon Breath.",
        Command = "BuySuperhuman",
    },
    {
        Id = "Death Step",
        Label = "Death Step — 2.500.000 Beli + 5.000 Mảnh",
        Price = "2.500.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Dark Step và đã mở phòng bằng Library Key.",
        Command = "BuyDeathStep",
    },
    {
        Id = "Sharkman Karate",
        Label = "Sharkman Karate — 2.500.000 Beli + 5.000 Mảnh",
        Price = "2.500.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Water Kung Fu và Water Key.",
        Command = "BuySharkmanKarate",
    },
    {
        Id = "Electric Claw",
        Label = "Electric Claw — 3.000.000 Beli + 5.000 Mảnh",
        Price = "3.000.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Electric và hoàn thành nhiệm vụ Previous Hero.",
        Command = "BuyElectricClaw",
    },
    {
        Id = "Dragon Talon",
        Label = "Dragon Talon — 3.000.000 Beli + 5.000 Mảnh",
        Price = "3.000.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Dragon Breath và Fire Essence.",
        Command = "BuyDragonTalon",
    },
    {
        Id = "Godhuman",
        Label = "Godhuman — 5.000.000 Beli + 5.000 Mảnh",
        Price = "5.000.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo 5 phong cách nâng cao; 20 Fish Tail, 20 Magma Ore, 10 Dragon Scale, 10 Mystic Droplet.",
        Command = "BuyGodhuman",
    },
    {
        Id = "Sanguine Art",
        Label = "Sanguine Art — 5.000.000 Beli + 5.000 Mảnh",
        Price = "5.000.000 Beli + 5.000 Mảnh",
        Requirement = "Leviathan Heart; 2 Dark Fragment, 20 Vampire Fang và 20 Demonic Wisp.",
        Command = "BuySanguineArt",
    },
}

local abilityEntries = {
    {
        Id = "AirJump",
        Name = "Nhảy trên không",
        Price = "10.000 Beli",
        Requirement = "Không yêu cầu.",
        Args = {"BuyHaki", "Geppo"},
    },
    {
        Id = "Aura",
        Name = "Haki Vũ Trang / Aura",
        Price = "25.000 Beli",
        Requirement = "Không yêu cầu.",
        Args = {"BuyHaki", "Buso"},
    },
    {
        Id = "FlashStep",
        Name = "Bước nhanh / Flash Step",
        Price = "100.000 Beli",
        Requirement = "Không yêu cầu.",
        Args = {"BuyHaki", "Soru"},
    },
    {
        Id = "Instinct",
        Name = "Haki Quan Sát / Instinct",
        Price = "750.000 Beli",
        Requirement = "Cấp 300 trở lên và đã hoàn thành Saber Puzzle.",
        Args = {"KenTalk", "Buy"},
    },
}

local styleById, styleIdByLabel, abilityById = {}, {}, {}
CombatShop.StyleLabels = {}
for _, entry in ipairs(styleEntries) do
    styleById[entry.Id] = entry
    styleIdByLabel[entry.Label] = entry.Id
    table.insert(CombatShop.StyleLabels, entry.Label)
end
for _, entry in ipairs(abilityEntries) do
    abilityById[entry.Id] = entry
end

local function invokeCombatShop(...)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF or not commF:IsA("RemoteFunction") then
        return false, "Không tìm thấy hệ thống cửa hàng của game."
    end

    local args = table.pack(...)
    local ok, result = pcall(function()
        return commF:InvokeServer(table.unpack(args, 1, args.n))
    end)
    return ok, result
end

local styleToolNames = {
    ["Dark Step"] = "Black Leg",
    ["Electric"] = "Electro",
    ["Water Kung Fu"] = "Fishman Karate",
    ["Dragon Breath"] = "Dragon Claw",
    ["Superhuman"] = "Superhuman",
    ["Death Step"] = "Death Step",
    ["Sharkman Karate"] = "Sharkman Karate",
    ["Electric Claw"] = "Electric Claw",
    ["Dragon Talon"] = "Dragon Talon",
    ["Godhuman"] = "Godhuman",
    ["Sanguine Art"] = "Sanguine Art",
}

local shopCosts = {
    ["Dark Step"] = {Beli = 150000},
    ["Electric"] = {Beli = 500000},
    ["Water Kung Fu"] = {Beli = 750000},
    ["Dragon Breath"] = {Fragments = 1500},
    ["Superhuman"] = {Beli = 3000000},
    ["Death Step"] = {Beli = 2500000, Fragments = 5000},
    ["Sharkman Karate"] = {Beli = 2500000, Fragments = 5000},
    ["Electric Claw"] = {Beli = 3000000, Fragments = 5000},
    ["Dragon Talon"] = {Beli = 3000000, Fragments = 5000},
    ["Godhuman"] = {Beli = 5000000, Fragments = 5000},
    ["Sanguine Art"] = {Beli = 5000000, Fragments = 5000},
    ["AirJump"] = {Beli = 10000},
    ["Aura"] = {Beli = 25000},
    ["FlashStep"] = {Beli = 100000},
    ["Instinct"] = {Beli = 750000},
}

local function formatShopAmount(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    local replacements
    repeat
        text, replacements = text:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
    until replacements == 0
    return text
end

local function findStyleTool(entry)
    if not entry then return nil end
    local mainToolName = styleToolNames[entry.Id] or entry.Id
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    local tool = (character and (character:FindFirstChild(mainToolName) or character:FindFirstChild(entry.Id)))
        or (backpack and (backpack:FindFirstChild(mainToolName) or backpack:FindFirstChild(entry.Id)))
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

local function waitForStyleTool(entry, timeout)
    local deadline = os.clock() + (timeout or 2.5)
    repeat
        local tool = findStyleTool(entry)
        if tool then return tool end
        task.wait(0.1)
    until os.clock() >= deadline
    return findStyleTool(entry)
end

local function missingCurrencyText(entry)
    local cost = entry and shopCosts[entry.Id]
    if not cost then return nil end
    local missing = {}
    local beli = getPlayerBeli()
    local fragments = tonumber(getPlayerValue("Fragments", 0)) or 0
    if cost.Beli and beli < cost.Beli then
        table.insert(missing, string.format(
            "Beli: có %s, cần %s (thiếu %s)",
            formatShopAmount(beli),
            formatShopAmount(cost.Beli),
            formatShopAmount(cost.Beli - beli)
        ))
    end
    if cost.Fragments and fragments < cost.Fragments then
        table.insert(missing, string.format(
            "Mảnh: có %s, cần %s (thiếu %s)",
            formatShopAmount(fragments),
            formatShopAmount(cost.Fragments),
            formatShopAmount(cost.Fragments - fragments)
        ))
    end
    return #missing > 0 and ("Không đủ tiền:\n" .. table.concat(missing, "\n")) or nil
end

local function resultText(ok, result, entry, verifiedTool)
    if not ok then return "Lỗi kết nối cửa hàng: " .. tostring(result) end
    if verifiedTool then
        return "Thành công: đã mua / trang bị " .. entry.Id .. "."
    end
    local missingCurrency = missingCurrencyText(entry)
    if result == 0 or tostring(result) == "0" then
        return missingCurrency
            or "Game từ chối giao dịch. Hãy kiểm tra điều kiện, nhiệm vụ và nguyên liệu."
    end
    if result == nil or tostring(result) == "" then return "Game đã nhận yêu cầu mua." end
    return "Phản hồi game: " .. tostring(result)
end

CombatShop.GetStyleId = function(label)
    return styleIdByLabel[label] or label
end

CombatShop.GetStyleLabel = function(styleId)
    local realId = CombatShop.GetStyleId(styleId)
    local entry = styleById[realId] or styleById[styleId]
    return entry and entry.Label or CombatShop.StyleLabels[1]
end

CombatShop.GetStyleInfo = function(styleId)
    local realId = CombatShop.GetStyleId(styleId)
    return styleById[realId] or styleById[styleId]
end

CombatShop.BuyStyle = function(styleId)
    local realId = CombatShop.GetStyleId(styleId)
    local entry = styleById[realId] or styleById[styleId]
    if not entry then
        notify("Cửa hàng cận chiến", "Chưa chọn phong cách hợp lệ.", 4)
        return false
    end

    local ok, result
    if entry.Special == "DragonBreath" then
        invokeCombatShop("BlackbeardReward", "DragonClaw", "1")
        ok, result = invokeCombatShop("BlackbeardReward", "DragonClaw", "2")
    else
        -- Trong Blox Fruits, gửi true để xác nhận mua/trang bị võ
        ok, result = invokeCombatShop(entry.Command, true)
        if not ok or result == 0 or tostring(result) == "0" or result == nil then
            -- Fallback thử chuỗi "1"/"2" hoặc tham số mặc định
            invokeCombatShop(entry.Command, "1")
            local ok2, result2 = invokeCombatShop(entry.Command, "2")
            if ok2 and result2 ~= nil and result2 ~= 0 then
                ok, result = ok2, result2
            else
                local ok3, result3 = invokeCombatShop(entry.Command)
                if ok3 and result3 ~= nil then
                    ok, result = ok3, result3
                end
            end
        end
    end

    local verifiedTool = ok and waitForStyleTool(entry, 2.5) or nil

    notify(
        "Mua " .. entry.Id,
        "Giá: " .. entry.Price .. "\nĐiều kiện: " .. entry.Requirement
            .. "\n" .. resultText(ok, result, entry, verifiedTool),
        7
    )
    return ok, result
end

CombatShop.ShowStyleInfo = function(styleId)
    local realId = CombatShop.GetStyleId(styleId)
    local entry = styleById[realId] or styleById[styleId]
    if not entry then return end
    notify(
        entry.Id,
        "Giá: " .. entry.Price .. "\nĐiều kiện: " .. entry.Requirement,
        8
    )
end

CombatShop.BuyAbility = function(abilityId)
    local entry = abilityById[abilityId]
    if not entry then return false end
    local ok, result = invokeCombatShop(table.unpack(entry.Args))
    notify(
        "Mua " .. entry.Name,
        "Giá: " .. entry.Price .. "\nĐiều kiện: " .. entry.Requirement
            .. "\n" .. resultText(ok, result, entry),
        6
    )
    return ok, result
end

CombatShop.BuyAllAbilities = function()
    local summary = {}
    for _, entry in ipairs(abilityEntries) do
        local ok, result = invokeCombatShop(table.unpack(entry.Args))
        table.insert(summary, entry.Name .. ": " .. resultText(ok, result, entry))
        task.wait(0.2)
    end
    notify(
        "Mua toàn bộ kỹ năng cơ bản",
        "Tổng giá khi chưa sở hữu: 885.000 Beli\n" .. table.concat(summary, "\n"),
        10
    )
end
end

-- ====== Tự động mở Sea 2 khi Auto Farm Level đạt cấp 700 ======
local Sea2Quest = {}
do
local lastSea2QuestStatus = "Chờ đạt cấp 700 tại Biển 1"
local lastDetectiveAttempt = -math.huge
local lastTravelAttempt = -math.huge
local lastProgressCheck = -math.huge
local cachedProgressOk = false
local cachedProgress = nil
local iceAdmiralEngaged = false

local SEA2_POINTS = {
    Detective = CFrame.new(4849.299, 5.651, 719.612),
    IceDoor = CFrame.new(1347.712, 37.375, -1325.649),
}

local function setSea2QuestStatus(message)
    lastSea2QuestStatus = tostring(message or "Đang kiểm tra nhiệm vụ mở Biển 2")
end

local function getSea2CommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then return commF end
    return nil
end

local function invokeSea2Remote(...)
    local commF = getSea2CommF()
    if not commF then return false, "Không tìm thấy RemoteFunction CommF_." end
    local args = table.pack(...)
    return pcall(function()
        return commF:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function getDressrosaProgress()
    if os.clock() - lastProgressCheck < 1 then
        return cachedProgressOk, cachedProgress
    end
    lastProgressCheck = os.clock()
    cachedProgressOk, cachedProgress = invokeSea2Remote("DressrosaQuestProgress", "Dressrosa")
    return cachedProgressOk, cachedProgress
end

local function findSea2Tool(toolName)
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    local tool = character and character:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then return tool end
    tool = backpack and backpack:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

local function equipSea2Tool(toolName)
    local tool = findSea2Tool(toolName)
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not tool or not humanoid then return nil end
    if tool.Parent ~= character then
        pcall(function() humanoid:EquipTool(tool) end)
        task.wait(0.2)
    end
    return (character and character:FindFirstChild(toolName)) or tool
end

local function getIceDoor()
    local map = Workspace:FindFirstChild("Map")
    local ice = map and map:FindFirstChild("Ice")
    local door = ice and ice:FindFirstChild("Door", true)
    if door and door:IsA("BasePart") then return door end
    return nil
end

local function iceDoorIsOpen(door)
    return door and door.CanCollide == false and door.Transparency >= 0.9
end

local function progressIsComplete(progress)
    return tonumber(progress) == 0
end

local function sea2QuestCanContinue()
    return _G.AutoFarmLevel
        and WorldSea == 1
        and getPlayerLevel() >= 700
        and modeCanMove("level")
end

local function travelSea2Quest(label, targetCFrame)
    if not sea2QuestCanContinue() then return false end
    clearFarmTarget()
    setSea2QuestStatus("Mở Biển 2: đang đến " .. label)
    return toTarget(targetCFrame)
end

local function touchKeyToDoor(key, door)
    if not key or not door then return end
    local handle = key:FindFirstChild("Handle")
    if handle and type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(handle, door, 0)
            task.wait(0.1)
            firetouchinterest(handle, door, 1)
        end)
    end
end

local function tryTravelDressrosa()
    if os.clock() - lastTravelAttempt < 4 then return end
    lastTravelAttempt = os.clock()
    clearFarmTarget()
    setSea2QuestStatus("Mở Biển 2: đã hạ Ice Admiral, đang chuyển sang Biển 2")
    invokeSea2Remote("TravelDressrosa")
    task.wait(4)
end

Sea2Quest.ShouldRun = function(level)
    return WorldSea == 1 and (tonumber(level) or getPlayerLevel()) >= 700
end

Sea2Quest.Step = function()
    if not sea2QuestCanContinue() then return false end

    if hasActiveQuest() then
        setSea2QuestStatus("Mở Biển 2: đang bỏ nhiệm vụ luyện cấp cũ")
        abandonQuest()
        acceptedQuestSignature = nil
        task.wait(0.5)
        return true
    end

    local progressOk, progress = getDressrosaProgress()
    if progressOk and progressIsComplete(progress) then
        tryTravelDressrosa()
        return true
    end

    local door = getIceDoor()
    if not door then
        setSea2QuestStatus("Mở Biển 2: đang chờ khu Frozen Village tải xong")
        task.wait(0.8)
        return true
    end

    if not iceDoorIsOpen(door) then
        local key = findSea2Tool("Key")
        if not key then
            if travelSea2Quest("Military Detective", SEA2_POINTS.Detective)
                and os.clock() - lastDetectiveAttempt >= 1 then
                lastDetectiveAttempt = os.clock()
                setSea2QuestStatus("Mở Biển 2: đang nhận Key từ Military Detective")
                invokeSea2Remote("DressrosaQuestProgress", "Detective")
                lastProgressCheck = -math.huge
                task.wait(0.8)
            end
            return true
        end

        key = equipSea2Tool("Key")
        setSea2QuestStatus("Mở Biển 2: đang mang Key đến cửa Ice Admiral")
        if travelSea2Quest("cửa Ice Admiral", SEA2_POINTS.IceDoor) then
            key = equipSea2Tool("Key") or key
            touchKeyToDoor(key, door)
            task.wait(1)
        end
        return true
    end

    local iceAdmiral = findBoss("Ice Admiral")
    if iceAdmiral then
        iceAdmiralEngaged = true
        setSea2QuestStatus("Mở Biển 2: đang đánh Ice Admiral")
        equipWeapon(_G.SelectWeapon)
        engageTarget(iceAdmiral, iceAdmiral.Name, _G.SelectWeapon)
        return true
    end

    if iceAdmiralEngaged then
        tryTravelDressrosa()
        return true
    end

    clearFarmTarget()
    travelSea2Quest("phòng Ice Admiral", SEA2_POINTS.IceDoor)
    setSea2QuestStatus("Mở Biển 2: đang chờ Ice Admiral xuất hiện")
    task.wait(0.8)
    return true
end

Sea2Quest.GetStatus = function()
    return lastSea2QuestStatus
end
end
-- ====== Tự động làm Saber Puzzle để mở khóa điều kiện Haki Quan Sát ======
local SaberQuest = {}
do
local lastSaberQuestStatus = "Chờ bật Tự động làm Saber Puzzle"
local saberCompletionNotified = false
local lastSaberInventoryCheck = -math.huge
local cachedSaberOwned = false

local SABER_POINTS = {
    JungleStart = CFrame.new(-1612.559, 36.977, 148.720),
    Torch = CFrame.new(-1610.008, 11.505, 164.002),
    BurnWall = CFrame.new(1114.615, 5.047, 4350.228),
    Water = CFrame.new(1397.229, 37.348, -1320.852),
    SickMan = CFrame.new(1458.543, 88.252, -1390.349),
    RichMan = CFrame.new(-910.980, 13.752, 4078.146),
    MobLeader = CFrame.new(-2852.902, 7.562, 5367.724),
    RelicSlot = CFrame.new(-1405.420, 29.852, 5.624),
    SaberExpert = CFrame.new(-1458.895, 29.887, -50.634),
}

local function setSaberQuestStatus(message)
    lastSaberQuestStatus = tostring(message or "Đang kiểm tra tiến độ Saber Puzzle")
end

local function getSaberCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then return commF end
    return nil
end

local function invokeSaberProgress(action, ...)
    local commF = getSaberCommF()
    if not commF then return false, "Không tìm thấy RemoteFunction CommF_." end
    local args = table.pack(...)
    return pcall(function()
        return commF:InvokeServer("ProQuestProgress", action, table.unpack(args, 1, args.n))
    end)
end

local function findQuestTool(toolName)
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    local tool = character and character:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then return tool end
    tool = backpack and backpack:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

local function equipQuestTool(toolName)
    local tool = findQuestTool(toolName)
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not tool or not humanoid then return nil end
    if tool.Parent ~= character then
        pcall(function() humanoid:EquipTool(tool) end)
        task.wait(0.15)
    end
    return (character and character:FindFirstChild(toolName)) or tool
end

local function inventoryContainsSaber(inventory)
    if type(inventory) ~= "table" then return false end
    for _, entry in pairs(inventory) do
        if type(entry) == "table" then
            local name = entry.Name or entry.name
            if name == "Saber" then return true end
        elseif tostring(entry) == "Saber" then
            return true
        end
    end
    return false
end

local function playerOwnsSaber()
    if findQuestTool("Saber") then
        cachedSaberOwned = true
        return true
    end
    if cachedSaberOwned then return true end
    if os.clock() - lastSaberInventoryCheck < 5 then return false end
    lastSaberInventoryCheck = os.clock()
    local commF = getSaberCommF()
    if not commF then return false end
    local ok, inventory = pcall(function()
        return commF:InvokeServer("getInventoryWeapons")
    end)
    cachedSaberOwned = ok and inventoryContainsSaber(inventory) or false
    return cachedSaberOwned
end

local function resolveQuestPart(object)
    if not object then return nil end
    if object:IsA("BasePart") then return object end
    if object:IsA("Model") and object.PrimaryPart then return object.PrimaryPart end
    return object:FindFirstChildWhichIsA("BasePart", true)
end

local function questPartIsOpen(part)
    return part and (part.CanCollide == false or part.Transparency >= 0.95)
end

local function touchQuestPart(part, tool)
    if not part then return false end
    local character = Player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local toolHandle = tool and (tool:FindFirstChild("Handle") or resolveQuestPart(tool))
    local toucher = toolHandle or rootPart
    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(toucher, part, 0)
            task.wait(0.1)
            firetouchinterest(toucher, part, 1)
        end)
    end
    pcall(function()
        rootPart.CFrame = part.CFrame * CFrame.new(0, 2, 0)
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end)
    return true
end

local function travelSaberQuest(label, targetCFrame)
    if not _G.AutoSaberQuest or not modeCanMove("saber") then return false end
    setSaberQuestStatus("Đang đến " .. label)
    return toTarget(targetCFrame)
end

local function finishSaberQuest()
    _G.AutoSaberQuest = false
    stopFarmMovement()
    setSaberQuestStatus("Hoàn thành: đã sở hữu Saber; có thể mua Haki Quan Sát khi đủ cấp 300 và 750.000 Beli.")
    if not saberCompletionNotified then
        saberCompletionNotified = true
        notify(
            "Saber Puzzle hoàn thành",
            "Đã nhận Saber. Khi đạt cấp 300 và có 750.000 Beli, hãy bấm Mua Haki Quan Sát.",
            8
        )
    end
end

local function pressJunglePlates(jungle)
    local plates = jungle and jungle:FindFirstChild("QuestPlates")
    if not plates then
        setSaberQuestStatus("Không tìm thấy QuestPlates tại Jungle.")
        return false
    end
    setSaberQuestStatus("Đang kích hoạt 5 nút Jungle")
    for index = 1, 5 do
        if not _G.AutoSaberQuest or not modeCanMove("saber") then return false end
        local plate = plates:FindFirstChild("Plate" .. index)
        local button = plate and resolveQuestPart(plate:FindFirstChild("Button") or plate)
        if button then
            if not toTarget(button.CFrame * CFrame.new(0, 2, 0)) then return false end
            touchQuestPart(button)
            task.wait(0.35)
        end
    end
    setSaberQuestStatus("Đã bấm 5 nút; đang chờ cửa bí mật mở")
    task.wait(0.8)
    return true
end

local function handleTorchStage(jungle, desert, burnPart)
    local torch = findQuestTool("Torch")
    if not torch then
        local torchObject = jungle and jungle:FindFirstChild("Torch", true)
        local torchPart = resolveQuestPart(torchObject)
        local target = torchPart and (torchPart.CFrame * CFrame.new(0, 2, 0)) or SABER_POINTS.Torch
        if travelSaberQuest("phòng Torch ở Jungle", target) then
            touchQuestPart(torchPart)
            setSaberQuestStatus("Đang nhặt Torch")
            task.wait(0.6)
        end
        return
    end

    torch = equipQuestTool("Torch")
    local target = burnPart and (burnPart.CFrame * CFrame.new(0, 2, 0)) or SABER_POINTS.BurnWall
    if travelSaberQuest("bức tường cháy tại Desert", target) then
        touchQuestPart(burnPart, torch)
        setSaberQuestStatus("Đang dùng Torch mở phòng Cup")
        task.wait(0.8)
    end
end

local function handleSickManStage(desert)
    local cup = findQuestTool("Cup")
    if not cup then
        invokeSaberProgress("GetCup")
        task.wait(0.5)
        cup = findQuestTool("Cup")
        if not cup then
            local cupObject = desert and desert:FindFirstChild("Cup", true)
            local cupPart = resolveQuestPart(cupObject)
            local target = cupPart and (cupPart.CFrame * CFrame.new(0, 2, 0)) or SABER_POINTS.BurnWall
            if travelSaberQuest("Cup trong căn nhà Desert", target) then
                touchQuestPart(cupPart)
                setSaberQuestStatus("Đang nhặt Cup")
                task.wait(0.6)
            end
            return
        end
    end

    cup = equipQuestTool("Cup")
    local isFull = cup and (cup:FindFirstChild("Water", true) or cup:FindFirstChild("Liquid", true) or cup:FindFirstChild("Full", true)) ~= nil

    if not isFull then
        if travelSaberQuest("nguồn nước tại Frozen Village", SABER_POINTS.Water) then
            local equippedCup = equipQuestTool("Cup") or cup
            
            -- Chạm vào giọt nước đọng trong hang nếu có
            local map = workspace:FindFirstChild("Map")
            local frozen = map and map:FindFirstChild("Frozen Village")
            local waterDrop = frozen and frozen:FindFirstChild("Water", true)
            if waterDrop then
                touchQuestPart(resolveQuestPart(waterDrop), equippedCup)
            end

            invokeSaberProgress("FillCup", equippedCup)
            setSaberQuestStatus("Đang hứng nước tại Frozen Village...")
            task.wait(0.8)
        end
        return
    end

    if travelSaberQuest("Sick Man tại Frozen Village", SABER_POINTS.SickMan) then
        local equippedCup = equipQuestTool("Cup") or cup
        invokeSaberProgress("SickMan", equippedCup)
        setSaberQuestStatus("Đã đưa Cup đầy nước cho Sick Man")
        task.wait(0.7)
    end
end

local function handleRichSonStage(richStatus)
    if richStatus == 0 or tostring(richStatus) == "0" then
        local mobLeader = findBoss("Mob Leader")
        if mobLeader then
            setSaberQuestStatus("Đang đánh Mob Leader")
            engageTarget(mobLeader, mobLeader.Name, _G.SelectWeapon)
        else
            clearFarmTarget()
            travelSaberQuest("điểm xuất hiện Mob Leader", SABER_POINTS.MobLeader)
            setSaberQuestStatus("Đang chờ Mob Leader xuất hiện")
            task.wait(0.5)
        end
        return
    end

    if travelSaberQuest("Rich Man tại Pirate Village", SABER_POINTS.RichMan) then
        invokeSaberProgress("RichSon")
        if richStatus == 1 or tostring(richStatus) == "1" then
            setSaberQuestStatus("Đã nhận Relic từ Rich Man")
        else
            setSaberQuestStatus("Đã nói chuyện với Rich Man")
        end
        task.wait(0.7)
    end
end

SaberQuest.Step = function()
    if not _G.AutoSaberQuest then return end
    if WorldSea ~= 1 then
        setSaberQuestStatus("Saber Puzzle chỉ thực hiện tại Biển 1.")
        clearFarmTarget()
        return
    end
    local level = getPlayerLevel()
    if level < 200 then
        setSaberQuestStatus("Cần đạt cấp 200 để làm Saber Puzzle; hiện tại cấp " .. level .. ".")
        clearFarmTarget()
        return
    end
    if playerOwnsSaber() then
        finishSaberQuest()
        return
    end

    local map = workspace:FindFirstChild("Map")
    local jungle = map and map:FindFirstChild("Jungle")
    local desert = map and map:FindFirstChild("Desert")
    if not jungle or not desert then
        setSaberQuestStatus("Đang chờ bản đồ Jungle và Desert tải xong.")
        return
    end

    local finalFolder = jungle:FindFirstChild("Final")
    local finalPart = finalFolder and resolveQuestPart(finalFolder:FindFirstChild("Part") or finalFolder)
    if questPartIsOpen(finalPart) then
        local saberExpert = findBoss("Saber Expert")
        if saberExpert then
            setSaberQuestStatus("Đang đánh Saber Expert")
            engageTarget(saberExpert, saberExpert.Name, _G.SelectWeapon)
        else
            clearFarmTarget()
            travelSaberQuest("phòng Saber Expert", SABER_POINTS.SaberExpert)
            setSaberQuestStatus("Đang chờ Saber Expert xuất hiện")
            task.wait(0.5)
        end
        return
    end

    local relic = findQuestTool("Relic")
    if relic then
        relic = equipQuestTool("Relic")
        if travelSaberQuest("khe đặt Relic tại Jungle", SABER_POINTS.RelicSlot) then
            touchQuestPart(finalPart, relic)
            invokeSaberProgress("PlaceRelic")
            setSaberQuestStatus("Đã đặt Relic; đang chờ phòng Saber Expert mở")
            task.wait(0.8)
        end
        return
    end

    local plates = jungle:FindFirstChild("QuestPlates")
    local plateDoor = plates and resolveQuestPart(plates:FindFirstChild("Door"))
    if not questPartIsOpen(plateDoor) then
        if not travelSaberQuest("khu nút Jungle", SABER_POINTS.JungleStart) then return end
        pressJunglePlates(jungle)
        return
    end

    local burnFolder = desert:FindFirstChild("Burn")
    local burnPart = burnFolder and resolveQuestPart(burnFolder:FindFirstChild("Part") or burnFolder)
    if not questPartIsOpen(burnPart) then
        handleTorchStage(jungle, desert, burnPart)
        return
    end

    local sickOk, sickStatus = invokeSaberProgress("SickMan")
    if not sickOk then
        setSaberQuestStatus("Không đọc được tiến độ Sick Man: " .. tostring(sickStatus))
        task.wait(1)
        return
    end
    if sickStatus ~= 0 and tostring(sickStatus) ~= "0" then
        handleSickManStage(desert)
        return
    end

    local richOk, richStatus = invokeSaberProgress("RichSon")
    if not richOk then
        setSaberQuestStatus("Không đọc được tiến độ Rich Man: " .. tostring(richStatus))
        task.wait(1)
        return
    end
    handleRichSonStage(richStatus)
end

SaberQuest.GetStatus = function()
    return lastSaberQuestStatus
end

SaberQuest.PrepareStart = function()
    saberCompletionNotified = false
    cachedSaberOwned = false
    lastSaberInventoryCheck = -math.huge
    setSaberQuestStatus("Đang kiểm tra tiến độ Saber Puzzle")
end
end

-- ====== Tự cất trái: bỏ qua trái trùng và giữ trái trùng trên tay ======
local FruitStorage = {}
do
local fruitStoreState = setmetatable({}, {__mode = "k"})
local lastFruitStoreStatus = "Chưa kiểm tra trái đang giữ"

local FruitIdentityAliases = {
    kilo = "rocket", rocket = "rocket",
    chop = "blade", blade = "blade",
    falcon = "eagle", eagle = "eagle",
    barrier = "creation", creation = "creation",
    door = "portal", portal = "portal",
    paw = "pain", pain = "pain",
    soul = "spirit", spirit = "spirit",
    revive = "ghost", ghost = "ghost",
    string = "spider", spider = "spider",
}

local LegacyFruitInternalNames = {
    buddha = "Human-Human: Buddha",
    phoenix = "Bird-Bird: Phoenix",
    falcon = "Bird-Bird: Falcon",
}

local function fruitBaseName(value)
    if type(value) ~= "string" then return "" end
    local text = string.lower(value)
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    text = text:gsub("%s+fruit%s*$", "")

    local afterColon = text:match(":%s*(.+)$")
    if afterColon and afterColon ~= "" then
        text = afterColon
    elseif string.find(text, "-", 1, true) then
        text = text:match("^([^%-]+)") or text
    end

    text = text:gsub("[^%w]", "")
    return FruitIdentityAliases[text] or text
end

local function fruitToolIdentityValues(tool)
    local values, seen = {}, {}
    local function add(value)
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(values, value)
        end
    end

    add(tool and tool.Name)
    if tool then
        for _, attributeName in ipairs({"FruitName", "OriginalName", "InternalName", "ItemName"}) do
            local ok, value = pcall(function() return tool:GetAttribute(attributeName) end)
            if ok then add(value) end
        end
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("StringValue") then
                local lowerName = string.lower(child.Name)
                if string.find(lowerName, "fruit", 1, true)
                    or string.find(lowerName, "original", 1, true)
                    or string.find(lowerName, "item", 1, true) then
                    add(child.Value)
                end
            end
        end
    end
    return values
end

local function getFruitRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    return commF and commF:IsA("RemoteFunction") and commF or nil
end

local function buildFruitNameSet(data)
    local names = {}
    if type(data) ~= "table" then return names end

    for key, entry in pairs(data) do
        local rawName = nil
        if type(entry) == "string" then
            rawName = entry
        elseif type(entry) == "table" then
            rawName = entry.Name or entry.name or entry.FruitName or entry.ItemName
        elseif type(key) == "string" then
            rawName = key
        end

        local base = fruitBaseName(rawName)
        if base ~= "" then names[base] = rawName end
    end
    return names
end

local function fetchStoredFruitNames()
    local commF = getFruitRemote()
    if not commF then return nil, "Không tìm thấy kho trái của game." end

    local ok, inventory = pcall(function()
        return commF:InvokeServer("getInventoryFruits")
    end)
    if not ok or type(inventory) ~= "table" then
        return nil, "Chưa đọc được danh sách trái trong kho."
    end
    return buildFruitNameSet(inventory), inventory
end

local function resolveFruitInternalName(tool)
    local identityValues = fruitToolIdentityValues(tool)
    local wantedBases = {}
    local directInternalName = nil
    for _, value in ipairs(identityValues) do
        local base = fruitBaseName(value)
        if base ~= "" then wantedBases[base] = true end
        local lowerValue = string.lower(value)
        if string.find(value, "-", 1, true)
            and not string.find(lowerValue, " fruit", 1, true) then
            directInternalName = directInternalName or value
        end
    end

    local commF = getFruitRemote()
    if commF then
        local ok, catalog = pcall(function() return commF:InvokeServer("GetFruits") end)
        if ok and type(catalog) == "table" then
            for _, entry in pairs(catalog) do
                local name = type(entry) == "table" and (entry.Name or entry.name) or nil
                if name and wantedBases[fruitBaseName(name)] then
                    return name
                end
            end
        end
    end

    if directInternalName then return directInternalName end

    for base in pairs(wantedBases) do
        if LegacyFruitInternalNames[base] then
            return LegacyFruitInternalNames[base]
        end
    end

    local displayName = tool and tool.Name or ""
    displayName = displayName:gsub("%s+[Ff][Rr][Uu][Ii][Tt]%s*$", "")
    displayName = displayName:gsub("^%s+", ""):gsub("%s+$", "")
    if displayName == "" then return nil end
    if string.find(displayName, "-", 1, true) then return displayName end
    return displayName .. "-" .. displayName
end

local function getOwnedFruitTools()
    local tools, seen = {}, {}
    local function scan(container)
        if not container then return end
        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool") and isFruitObject(object) and not seen[object] then
                seen[object] = true
                table.insert(tools, object)
            end
        end
    end
    scan(Player.Character)
    scan(Player:FindFirstChildOfClass("Backpack"))
    return tools
end

local function holdDuplicateFruit(tool)
    if not tool or not tool.Parent then return end
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if humanoid and backpack and tool.Parent == backpack then
        pcall(function() humanoid:EquipTool(tool) end)
    end
end

local function storeOwnedFruitTool(tool, force)
    if not tool or not tool.Parent or not isFruitObject(tool) then return "ignored" end
    local state = fruitStoreState[tool]
    if not state then
        state = {nextAttempt = 0, duplicateNotified = false}
        fruitStoreState[tool] = state
    end
    if not force and os.clock() < state.nextAttempt then return "waiting" end
    state.nextAttempt = os.clock() + 5

    local storedNames, inventoryError = fetchStoredFruitNames()
    if not storedNames then
        lastFruitStoreStatus = inventoryError
        return "failed"
    end

    local toolBase = ""
    for _, value in ipairs(fruitToolIdentityValues(tool)) do
        toolBase = fruitBaseName(value)
        if toolBase ~= "" then break end
    end
    if toolBase == "" then
        lastFruitStoreStatus = "Không nhận diện được " .. tostring(tool.Name)
        return "failed"
    end

    if storedNames[toolBase] then
        holdDuplicateFruit(tool)
        lastFruitStoreStatus = tool.Name .. " đã có trong kho — giữ ngoài tay"
        if not state.duplicateNotified then
            state.duplicateNotified = true
            notify("Trái đã có trong kho", tool.Name .. " được giữ ngoài tay, không cất lại.", 5)
        end
        return "duplicate"
    end

    local internalName = resolveFruitInternalName(tool)
    local commF = getFruitRemote()
    if not internalName or not commF then
        lastFruitStoreStatus = "Chưa xác định được tên kho của " .. tool.Name
        return "failed"
    end

    local ok, result = pcall(function()
        return commF:InvokeServer("StoreFruit", internalName, tool)
    end)
    if not ok then
        lastFruitStoreStatus = "Cất " .. tool.Name .. " thất bại"
        return "failed"
    end

    task.wait(0.35)
    local afterNames = fetchStoredFruitNames()
    local stored = not tool.Parent or (afterNames and afterNames[toolBase] ~= nil)
    if stored then
        lastFruitStoreStatus = "Đã cất " .. tool.Name .. " vào kho"
        notify("Đã cất trái", tool.Name .. " → kho trái", 4)
        return "stored"
    end

    local resultText = string.lower(tostring(result or ""))
    if string.find(resultText, "already", 1, true)
        or string.find(resultText, "đã có", 1, true) then
        holdDuplicateFruit(tool)
        lastFruitStoreStatus = tool.Name .. " đã có trong kho — giữ ngoài tay"
        return "duplicate"
    end

    lastFruitStoreStatus = "Game chưa xác nhận cất " .. tool.Name
    return "failed"
end

local function storeOwnedFruitsNow(force)
    local stored, duplicates, failed = 0, 0, 0
    for _, tool in ipairs(getOwnedFruitTools()) do
        local result = storeOwnedFruitTool(tool, force)
        if result == "stored" then
            stored = stored + 1
        elseif result == "duplicate" then
            duplicates = duplicates + 1
        elseif result == "failed" then
            failed = failed + 1
        end
        task.wait(0.15)
    end
    return stored, duplicates, failed
end

task.spawn(function()
    task.wait(2)
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        if _G.AutoStoreFruit then
            runFeature("Tự cất trái", function() storeOwnedFruitsNow(false) end)
            task.wait(0.8)
        else
            task.wait(1.5)
        end
    end
end)

FruitStorage.StoreNow = storeOwnedFruitsNow
FruitStorage.GetStatus = function() return lastFruitStoreStatus end
end

-- ====== Tự nhập mã x2 EXP / đặt lại chỉ số ======
local RewardCodes = {}
do
-- Danh sách đối chiếu ngày 31/07/2026; game tự bỏ qua mã đã dùng hoặc hết hạn.
local ActiveExpCodes = {
    "EASTEREXP", "LIGHTNINGABUSE", "KITTGAMING", "SUB2FER999",
    "ENYU_IS_PRO", "MAGICBUS", "JCWK", "STARCODEHEO", "BLUXXY",
    "SUB2GAMERROBOT_EXP1", "SUB2NOOBMASTER123", "SUB2DAIGROCK",
    "AXIORE", "TANTAIGAMING", "STRAWHATMAINE", "SUB2OFFICIALNOOBIE",
    "THEGREATACE", "SUB2CAPTAINMAUi",
}
local ActiveResetCodes = {
    "KITT_RESET", "SUB2GAMERROBOT_RESET1", "SUB2UNCLEKIZARU",
}

local redeemAttemptedByCode = {}
local codeCategoryAttempted = {exp = false, reset = false}
local redeemBatchBusy = false
local lastCodeStatus = "Chưa nhập mã"

local function redeemRewardCode(code)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local redeem = remotes and remotes:FindFirstChild("Redeem")
    if not redeem then return false, "Không tìm thấy hệ thống nhập mã." end

    if redeem:IsA("RemoteFunction") then
        local ok, result = pcall(function() return redeem:InvokeServer(code) end)
        return ok, result
    end
    if redeem:IsA("RemoteEvent") then
        local ok, result = pcall(function()
            redeem:FireServer(code)
            return "Đã gửi"
        end)
        return ok, result
    end
    return false, "Remote nhập mã không hợp lệ."
end

local function redeemCodeBatch(codes, label, force)
    if redeemBatchBusy then return false, "Hệ thống đang nhập nhóm mã khác." end
    redeemBatchBusy = true

    local submitted, accepted, rejected, failed = 0, 0, 0, 0
    for _, code in ipairs(codes) do
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then break end
        if force or not redeemAttemptedByCode[code] then
            redeemAttemptedByCode[code] = true
            submitted = submitted + 1
            local ok, result = redeemRewardCode(code)
            if ok then
                local resultText = string.lower(tostring(result or ""))
                if string.find(resultText, "already", 1, true)
                    or string.find(resultText, "invalid", 1, true)
                    or string.find(resultText, "expired", 1, true) then
                    rejected = rejected + 1
                else
                    accepted = accepted + 1
                end
            else
                failed = failed + 1
            end
            task.wait(0.18)
        end
    end

    redeemBatchBusy = false
    lastCodeStatus = string.format(
        "%s: gửi %d • nhận %d • đã dùng/hết hạn %d • lỗi %d",
        label, submitted, accepted, rejected, failed
    )
    notify("Nhập mã " .. label, lastCodeStatus, 6)
    return true, lastCodeStatus
end

task.spawn(function()
    local teamWaitStarted = os.clock()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken
        and Player.Team == nil and os.clock() - teamWaitStarted < 20 do
        task.wait(0.5)
    end
    task.wait(1)

    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        if _G.AutoRedeemExpCodes and not codeCategoryAttempted.exp then
            codeCategoryAttempted.exp = true
            redeemCodeBatch(ActiveExpCodes, "x2 EXP", false)
        elseif _G.AutoRedeemResetCodes and not codeCategoryAttempted.reset then
            codeCategoryAttempted.reset = true
            redeemCodeBatch(ActiveResetCodes, "đặt lại chỉ số", false)
        end
        task.wait(1)
    end
end)

RewardCodes.SetPending = function(category)
    if category == "exp" or category == "reset" then
        codeCategoryAttempted[category] = false
    end
end
RewardCodes.RedeemExp = function(force)
    return redeemCodeBatch(ActiveExpCodes, "x2 EXP", force == true)
end
RewardCodes.RedeemReset = function(force)
    return redeemCodeBatch(ActiveResetCodes, "đặt lại chỉ số", force == true)
end
end

-- ====== Tự chọn phe khi vào game / đổi máy chủ ======
local lastTeamAttempt = 0

local function normalizedPreferredTeam()
    return _G.PreferredTeam == "Marines" and "Marines" or "Pirates"
end

local function teamIsSelected()
    return Player.Team ~= nil and Player.Neutral == false
end

local function choosePreferredTeam(force)
    if not force and not _G.AutoChooseTeam then
        return false, "Tự chọn phe đang tắt."
    end
    if teamIsSelected() and not force then
        return true, "Nhân vật đã có phe."
    end

    local now = os.clock()
    if not force and now - lastTeamAttempt < 1 then
        return false, "Đang chờ lần thử kế tiếp."
    end
    lastTeamAttempt = now

    local picker = RuntimeEnv.HAOTOOL_STARTUP_TEAM_PICKER
    if type(picker) == "function" then
        local ok, selected, message = pcall(picker, normalizedPreferredTeam())
        if ok then return selected == true, tostring(message or "") end
    end

    local sent = false
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")
        if commF and commF:IsA("RemoteFunction") then
            commF:InvokeServer("SetTeam", normalizedPreferredTeam())
            sent = true
        end
    end)
    task.wait(0.5)
    if teamIsSelected() then return true, "Đã chọn phe." end
    return false, sent and "Đã gửi yêu cầu; đang chờ game xác nhận."
        or "Không tìm thấy hệ thống chọn phe."
end

RuntimeEnv.HAOTOOL_TEAM_CONTROLLER_READY = true
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        if _G.AutoChooseTeam and not teamIsSelected() then
            choosePreferredTeam(false)
            task.wait(0.7)
        else
            task.wait(2)
        end
    end
end)
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
            notify("Đột kích chưa mở khóa", "Cần đạt cấp 1100 và ở Biển 2 hoặc Biển 3 để tự mua chip.", 6)
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
        notify("Đột kích cần thao tác", "Đã mua chip nhưng trình thực thi không bấm được nút; hãy đứng tại phòng đột kích và bấm nút một lần.", 6)
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

-- ====== LOOP 0: Tự động làm Saber Puzzle ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.2)
        if _G.AutoSaberQuest and modeCanMove("saber") then
            runFeature("Saber Puzzle", SaberQuest.Step)
        end
    end
end)

-- ====== LOOP 1: Auto Farm Level ======
local lastFarmStatus = "Chờ bật Auto Farm Level"
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.05)

        if _G.AutoFarmLevel and modeCanMove("level") then
            runFeature("Auto Farm Level", function()
                local level = getPlayerLevel()
                if Sea2Quest.ShouldRun(level) then
                    Sea2Quest.Step()
                    lastFarmStatus = Sea2Quest.GetStatus()
                    return
                end

                local quest = getQuestData(level)
                local method = _G.FarmMethod or "Quest"
                if not quest then
                    lastFarmStatus = "Không có dữ liệu quest cho cấp " .. level
                    return
                end

                if method == "Quest" then
                    local expectedSignature = questSignature(quest)
                    if hasActiveQuest() and acceptedQuestSignature ~= expectedSignature then
                        lastFarmStatus = "Đang đổi sang quest đúng cấp: "
                            .. tostring(quest.MobName) .. " (" .. expectedSignature .. ")"
                        abandonQuest()
                        acceptedQuestSignature = nil
                        task.wait(0.35)
                        return
                    end

                    if not hasActiveQuest() then
                        lastFarmStatus = "Đang nhận quest " .. tostring(quest.MobName)
                        startQuest(quest)
                        return
                    end
                end

                local targetMob
                if method == "Nearest" then
                    targetMob = findMob("", true)
                elseif method == "Selected Mob" then
                    targetMob = findMob(_G.SelectedMob, false)
                else
                    targetMob = findMob(quest.MobName, false)
                end

                if not targetMob then
                    clearFarmTarget()
                    if method == "Quest" then
                        lastFarmStatus = "Đang chờ quái " .. tostring(quest.MobName)
                        if ensureQuestArea(quest) then
                            toTarget(CFrame.new(quest.MobPosition))
                        end
                    elseif method == "Selected Mob" then
                        lastFarmStatus = "Chưa thấy quái " .. tostring(_G.SelectedMob)
                    else
                        lastFarmStatus = "Chưa thấy quái gần nhân vật"
                    end
                    return
                end

                local bringName = method == "Quest" and quest.MobName
                    or method == "Selected Mob" and _G.SelectedMob
                    or targetMob.Name
                lastFarmStatus = "Đang đánh " .. tostring(targetMob.Name)
                    .. " • " .. tostring(lastAttackMethod)
                engageTarget(targetMob, bringName, _G.SelectWeapon)
            end)
        else
            if not _G.AutoFarmLevel then
                lastFarmStatus = "Chờ bật Auto Farm Level"
            end
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
                        notify("Quái biển", "Quái biển chỉ xuất hiện tại Biển 2 và Biển 3.", 5)
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
                        notify("Kiếm Xương", "Chỉ kiếm Xương ổn định tại Lâu đài ma ở Biển 3.", 5)
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
local lastFruitStatus = "Chờ bật Auto Nhặt Trái"
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.5)

        if not _G.AutoCollectFruit then activeFruitTarget = nil end
        if _G.AutoFruitFinder or _G.AutoCollectFruit then
            runFeature("Theo dõi trái", function()
                local fruits = getSpawnedFruits()
                local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                lastFruitStatus = #fruits > 0 and ("Tìm thấy " .. #fruits .. " trái") or "Không có trái trên bản đồ"

                if _G.AutoFruitFinder then
                    for _, fruit in ipairs(fruits) do
                        if not announcedFruits[fruit] then
                            announcedFruits[fruit] = true
                            local handle = getFruitHandle(fruit)
                            local distance = rootPart and handle
                                and math.floor((handle.Position - rootPart.Position).Magnitude) or 0
                            notify("🍎 Phát hiện trái", fruit.Name .. " [" .. distance .. "m]", 6)
                        end
                    end
                end

                if _G.AutoCollectFruit then
                    local fruit = findNearestFruit()
                    activeFruitTarget = fruit
                    local handle = getFruitHandle(fruit)
                    if fruit and handle and modeCanMove("fruit") then
                        lastFruitStatus = "Đang nhặt " .. fruit.Name
                        local arrived = moveToFruitSafely(fruit, false, function(status)
                            lastFruitStatus = status
                        end)
                        if arrived then
                            task.wait(0.12)
                            touchFruit(fruit)
                        end
                        if not fruit.Parent or not getFruitHandle(fruit) then
                            activeFruitTarget = nil
                            lastFruitStatus = "Đã nhặt " .. fruit.Name
                        elseif not arrived then
                            lastFruitStatus = "Di chuyển tới " .. fruit.Name .. " bị gián đoạn"
                        end
                    elseif not fruit then
                        activeFruitTarget = nil
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
                notify("🎰 Mua Trái ngẫu nhiên", msg, 6)
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
                    local handle = getFruitHandle(fruit)
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
                local hasFruit = #getSpawnedFruits() > 0
                if not hasFruit then
                    notify("Đổi máy chủ", "Không có Trái, đang chuyển máy chủ ít người...", 3)
                    task.wait(2)
                    serverHop(true, _G.LowServerMaxPlayers)
                end
            end)
        end
    end
end)

-- ====== Sự kiện khi chết → thông báo + tiếp tục farm ======
Player.CharacterAdded:Connect(function(char)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    task.wait(1)
    if _G.AutoChooseTeam and not teamIsSelected() then
        choosePreferredTeam(false)
    end
    if _G.AutoFarmLevel or _G.AutoFarmMastery or _G.AutoFarmBoss then
        notify("💀 Đã hồi sinh", "Tiếp tục hoạt động tự động...", 3)
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

    if RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR then
        table.insert(notes, "Lỗi khởi động: " .. tostring(RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR))
    end

    local status = "Kiểm tra lõi: " .. passed .. "/" .. (passed + #failed)
    if #failed > 0 then status = status .. "\nThiếu: " .. table.concat(failed, ", ") end
    if #notes > 0 then status = status .. "\nLưu ý: " .. table.concat(notes, "; ") end
    if #runtimeErrors > 0 then
        status = status .. "\nLỗi gần nhất: " .. table.concat(runtimeErrors, " | ")
    else
        status = status .. "\nKhông ghi nhận lỗi vòng chạy."
    end
    status = status .. "\nChế độ di chuyển: " .. tostring(getActiveMovementMode() or "không")
    status = status .. "\nFarm: " .. tostring(lastFarmStatus)
    status = status .. "\nTrái: " .. tostring(lastFruitStatus)
    status = status .. "\nĐánh: " .. tostring(lastAttackMethod)
    return status
end
------------------------------------------------------------
-- PHẦN 7: GIAO DIỆN FLUENT — BỐ CỤC MODERN DASHBOARD
------------------------------------------------------------

-- Tách toàn bộ UI khỏi chunk chính để tránh chạm giới hạn local/register của Luau.
local function buildMainInterface()
RuntimeEnv.HAOTOOL_MENU_VISIBLE = true
local Window = Fluent:CreateWindow({
    Title    = "HAOTOOL  •  BLOX FRUITS",
    SubTitle = "V" .. RequestedScriptVersion .. "  •  Biển " .. WorldSea .. "  |  Trung tâm điều khiển",
    TabWidth = 170,
    Size     = UDim2.fromOffset(720, 540),
    Acrylic  = true,
    Theme    = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl, -- Phím ẩn/hiện GUI
})

-- ====== LOGO NỔI: LUÔN CÓ THỂ MỞ LẠI MENU ======
local function setMainWindowVisible(visible)
    RuntimeEnv.HAOTOOL_MENU_VISIBLE = visible == true
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
    if RuntimeEnv.HAOTOOL_RELOADING then return false end
    if type(readfile) ~= "function" then
        RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = "Executor không hỗ trợ readfile để dựng lại menu."
        return false
    end

    RuntimeEnv.HAOTOOL_RELOADING = true
    task.spawn(function()
        local readOk, source = pcall(function()
            return readfile(TELEPORT_SCRIPT_FILE)
        end)
        if not readOk or type(source) ~= "string" or source == "" then
            RuntimeEnv.HAOTOOL_RELOADING = nil
            RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = "Không đọc được file phục hồi giao diện: " .. tostring(source)
            warn("[HAOTOOL] " .. RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR)
            return
        end

        local runner, compileError = loadstring(source)
        if not runner then
            RuntimeEnv.HAOTOOL_RELOADING = nil
            RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = "Không biên dịch được file phục hồi: " .. tostring(compileError)
            warn("[HAOTOOL] " .. RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR)
            return
        end

        pcall(stopFarmMovement)
        pcall(clearAllESP)
        saveTeleportState()
        pcall(function()
            RuntimeEnv.HAOTOOL_TELEPORT_STATE = HttpService:JSONDecode(
                readfile(TELEPORT_STATE_FILE)
            )
        end)

        local destroyOldUI = RuntimeEnv.HAOTOOL_DESTROY_UI
        RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
        RuntimeEnv.HAOTOOL_RUNNING = nil
        RuntimeEnv.HAOTOOL_TOGGLE_MENU = nil
        RuntimeEnv.HAOTOOL_DESTROY_UI = nil
        if type(destroyOldUI) == "function" then pcall(destroyOldUI) end
        task.wait()

        local runOk, runError = pcall(runner)
        RuntimeEnv.HAOTOOL_RELOADING = nil
        if not runOk then
            RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
            RuntimeEnv.HAOTOOL_RUNNING = nil
            RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = tostring(runError)
            warn("[HAOTOOL] Phục hồi giao diện lỗi: " .. tostring(runError))
        else
            RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = nil
        end
    end)
    return true
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
    local dragDistance = 0
    local dragStart, startPos = nil, nil

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragDistance = 0
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    button.InputChanged:Connect(function(input)
        if dragging and dragStart
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            dragDistance = delta.Magnitude
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local lastLauncherToggle = 0
    button.Activated:Connect(function()
        if dragDistance >= 10 then
            dragDistance = 0
            return
        end
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
    RuntimeEnv.HAOTOOL_MENU_VISIBLE = nil
    restoreAttackAnimationWeights()
    if silentAnimationConnection then
        pcall(function() silentAnimationConnection:Disconnect() end)
        silentAnimationConnection = nil
    end
    silentAnimator = nil
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
UITabs.Farm = addTabSafe("Luyện cấp", "Tự động luyện cấp")
UITabs.Raid = addTabSafe("Đột kích", "Đột kích")
UITabs.Fruit = addTabSafe("Trái ác quỷ", "Trái ác quỷ")
UITabs.ESP = addTabSafe("Đánh dấu", "Đánh dấu đối tượng")
UITabs.Teleport = addTabSafe("Di chuyển", "Di chuyển")
UITabs.Combat = addTabSafe("Chiến đấu", "Chiến đấu")
UITabs.Misc = addTabSafe("Tiện ích", "Tiện ích")
UITabs.Settings = addTabSafe("Cài đặt", "Cài đặt")
RuntimeEnv.HAOTOOL_TAB_COUNT = createdTabCount
local currentBossNames = {}
local bossStatusLabels = {}
local bossStatusLabelToName = {}
local bossNameToStatusLabel = {}
local bossStatusSummary = ""
local bossStatusSignature = ""
local bossStatusParagraph = nil
local refreshBossInterface = nil
local islandNames

local weaponLabels = {"Cận chiến", "Kiếm", "Súng", "Trái ác quỷ"}
local weaponLabelToValue = {
    ["Cận chiến"] = "Melee",
    ["Kiếm"] = "Sword",
    ["Súng"] = "Gun",
    ["Trái ác quỷ"] = "Blox Fruit",
}
local weaponValueToLabel = {
    ["Melee"] = "Cận chiến",
    ["Sword"] = "Kiếm",
    ["Gun"] = "Súng",
    ["Blox Fruit"] = "Trái ác quỷ",
}
local farmMethodLabels = {"Nhiệm vụ", "Quái gần nhất", "Quái đã chọn"}
local farmMethodLabelToValue = {
    ["Nhiệm vụ"] = "Quest",
    ["Quái gần nhất"] = "Nearest",
    ["Quái đã chọn"] = "Selected Mob",
}
local farmMethodValueToLabel = {
    ["Quest"] = "Nhiệm vụ",
    ["Nearest"] = "Quái gần nhất",
    ["Selected Mob"] = "Quái đã chọn",
}
local statLabels = {"Cận chiến", "Phòng thủ", "Kiếm", "Súng", "Trái ác quỷ"}
local statLabelToValue = {
    ["Cận chiến"] = "Melee",
    ["Phòng thủ"] = "Defense",
    ["Kiếm"] = "Sword",
    ["Súng"] = "Gun",
    ["Trái ác quỷ"] = "Blox Fruit",
}
local statValueToLabel = {
    ["Melee"] = "Cận chiến",
    ["Defense"] = "Phòng thủ",
    ["Sword"] = "Kiếm",
    ["Gun"] = "Súng",
    ["Blox Fruit"] = "Trái ác quỷ",
}
local teamLabels = {"Hải Tặc", "Hải Quân"}
local teamLabelToValue = {
    ["Hải Tặc"] = "Pirates",
    ["Hải Quân"] = "Marines",
}
local teamValueToLabel = {
    ["Pirates"] = "Hải Tặc",
    ["Marines"] = "Hải Quân",
}

local function refreshBossCache()
    currentBossNames = getBossList()
    bossStatusLabels, bossStatusLabelToName, bossNameToStatusLabel,
        bossStatusSummary, bossStatusSignature = getBossStatusList(currentBossNames)
end
refreshBossCache()

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
    Content = "BIỂN  " .. WorldSea
        .. "    •    CẤP  " .. tostring(getPlayerLevel())
        .. "    •    TIỀN  " .. tostring(getPlayerBeli())
        .. "\nMáy chủ  " .. game.JobId:sub(1, 8) .. "..."
        .. "\n\nRightControl hoặc nút H  •  Ẩn / hiện bảng điều khiển"
})

local ServerSection = MainTab:AddSection("Kết nối máy chủ")

ServerSection:AddParagraph({
    Title = "Máy chủ hiện tại",
    Content = tostring(#Players:GetPlayers()) .. " người đang chơi",
})

ServerSection:AddParagraph({
    Title = "Trạng thái tự chọn phe",
    Content = tostring(RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS or "Chưa chạy"),
})

ServerSection:AddSlider("LowServerMaxPlayersSlider", {
    Title = "Số người tối đa mong muốn",
    Description = "Hệ thống ưu tiên máy chủ có số người bằng hoặc thấp hơn mức này.",
    Min = 1,
    Max = 12,
    Default = _G.LowServerMaxPlayers,
    Rounding = 0,
    Callback = function(v) _G.LowServerMaxPlayers = v end,
})

ServerSection:AddToggle("AutoChooseTeamToggle", {
    Title = "Tự chọn phe khi vào game",
    Description = "Tự chọn lại phe sau khi vào game hoặc đổi máy chủ.",
    Default = _G.AutoChooseTeam,
    Callback = function(v)
        _G.AutoChooseTeam = v
        if v and not teamIsSelected() then
            task.spawn(function() choosePreferredTeam(true) end)
        end
    end,
})

ServerSection:AddDropdown("PreferredTeamDrop", {
    Title = "Phe ưu tiên",
    Description = "Phe sẽ tự chọn ở màn hình bắt đầu.",
    Values = teamLabels,
    Default = teamValueToLabel[_G.PreferredTeam] or teamLabels[1],
    Callback = function(v)
        _G.PreferredTeam = teamLabelToValue[v] or _G.PreferredTeam
    end,
})

ServerSection:AddButton({
    Title = "Chọn phe ngay",
    Description = "Gửi lại yêu cầu nếu đang dừng ở màn hình chọn phe.",
    Callback = function()
        task.spawn(function()
            local ok, message = choosePreferredTeam(true)
            local label = teamValueToLabel[normalizedPreferredTeam()] or normalizedPreferredTeam()
            notify(ok and "Đã chọn phe" or "Chưa chọn được phe", ok and label or tostring(message), 4)
        end)
    end,
})

ServerSection:AddButton({
    Title = "Chuyển sang máy chủ ít người",
    Description = "Quét tối đa 300 máy chủ và chọn máy có ít người nhất.",
    Callback = function()
        notify("Đổi máy chủ", "Đang tìm máy chủ ít người...", 3)
        local ok, message = serverHop(true, _G.LowServerMaxPlayers)
        if not ok then notify("Không thể đổi máy chủ", tostring(message), 5) end
    end,
})

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
    Title = "Chuyển máy chủ ngẫu nhiên",
    Description = "Chuyển sang một máy chủ công khai khác.",
    Callback = function()
        notify("Đổi máy chủ", "Đang tìm máy chủ...", 3)
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

local FarmCoreSection = FarmTab:AddSection("Luyện cấp và thông thạo")
local changingCoreFarmMode = false

local function disableOtherCoreFarm(optionId, globalKey)
    _G[globalKey] = false
    local option = Fluent.Options and Fluent.Options[optionId]
    if option and option.SetValue then
        pcall(function() option:SetValue(false) end)
    end
end

FarmCoreSection:AddToggle("AutoFarmLevel", {
    Title = "Tự động luyện cấp",
    Description = "Tự động nhận nhiệm vụ → đánh quái → lên cấp; đạt cấp 700 sẽ tự mở và qua Biển 2",
    Default = _G.AutoFarmLevel,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if v and not changingCoreFarmMode then
            changingCoreFarmMode = true
            disableOtherCoreFarm("AutoFarmMastery", "AutoFarmMastery")
            changingCoreFarmMode = false
        end
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
    Title = "Tự động luyện thông thạo",
    Description = "Tự động tăng thông thạo cho vũ khí được chọn",
    Default = _G.AutoFarmMastery,
    Callback = function(v)
        _G.AutoFarmMastery = v
        if v and not changingCoreFarmMode then
            changingCoreFarmMode = true
            disableOtherCoreFarm("AutoFarmLevel", "AutoFarmLevel")
            changingCoreFarmMode = false
        end
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmBoss
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmCoreSection:AddDropdown("MasteryWeaponDrop", {
    Title = "Vũ khí luyện thông thạo",
    Values = weaponLabels,
    Default = weaponValueToLabel[_G.MasteryWeapon] or weaponLabels[1],
    Callback = function(v) _G.MasteryWeapon = weaponLabelToValue[v] or _G.MasteryWeapon end,
})

FarmCoreSection:AddDropdown("SelectWeaponDrop", {
    Title = "Chọn vũ khí để đánh",
    Values = weaponLabels,
    Default = weaponValueToLabel[_G.SelectWeapon] or weaponLabels[1],
    Callback = function(v) _G.SelectWeapon = weaponLabelToValue[v] or _G.SelectWeapon end,
})

FarmCoreSection:AddDropdown("FarmMethodDrop", {
    Title = "Phương thức luyện cấp",
    Values = farmMethodLabels,
    Default = farmMethodValueToLabel[_G.FarmMethod] or farmMethodLabels[1],
    Callback = function(v) _G.FarmMethod = farmMethodLabelToValue[v] or _G.FarmMethod end,
})

local currentEnemyNames = getEnemyList()
if _G.SelectedMob == "" and currentEnemyNames[1] ~= "(Không có quái)" then
    _G.SelectedMob = currentEnemyNames[1]
end
FarmCoreSection:AddDropdown("SelectedMobDrop", {
    Title = "Chọn quái (khi dùng Quái đã chọn)",
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
    Title = "Giới hạn hoạt động",
    Description = "Giới hạn tốc độ, vùng đánh và phạm vi gom quái để giảm thao tác quá nhanh.",
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
    Title = "Đánh nền, không chiếm chuột",
    Description = "Ưu tiên bộ điều khiển chiến đấu của game và tự dùng phương án dự phòng khi cần.",
    Default = _G.BackgroundAttack,
    Callback = function(v) _G.BackgroundAttack = v end,
})

FarmPositionSection:AddToggle("NoAttackAnimationToggle", {
    Title = "Ẩn hoạt ảnh đánh thường",
    Description = "Ẩn chuyển động đấm/chém nhưng không dừng mốc sát thương; tạm nhường khi dùng kỹ năng.",
    Default = _G.NoAttackAnimation,
    Callback = function(v)
        _G.NoAttackAnimation = v
        if not v then restoreAttackAnimationWeights() end
    end,
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
    Title = "Kích thước vùng tiếp xúc",
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

local FarmBossSection = FarmTab:AddSection("Trùm và tài nguyên")

refreshBossCache()
if #currentBossNames > 0 and (_G.SelectedBoss == "" or not table.find(currentBossNames, _G.SelectedBoss)) then
    _G.SelectedBoss = currentBossNames[1]
end

bossStatusParagraph = FarmBossSection:AddParagraph({
    Title = "Trạng thái Trùm trong máy chủ",
    Content = bossStatusSummary,
})

FarmBossSection:AddToggle("AutoFarmBoss", {
    Title = "Tự động đánh Trùm",
    Description = "Tự động tìm và đánh Trùm được chọn",
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
    Title = "Chọn Trùm",
    Values = bossStatusLabels,
    Default = bossNameToStatusLabel[_G.SelectedBoss] or bossStatusLabels[1],
    Callback = function(v)
        _G.SelectedBoss = bossStatusLabelToName[v] or _G.SelectedBoss
    end,
})

refreshBossInterface = function(showNotice)
    local previousSignature = bossStatusSignature
    refreshBossCache()
    if not showNotice and previousSignature == bossStatusSignature then return end

    if #currentBossNames > 0 and not table.find(currentBossNames, _G.SelectedBoss) then
        _G.SelectedBoss = currentBossNames[1]
    end
    if #currentBossNames > 0 and not table.find(currentBossNames, _G.SelectedBossTP) then
        _G.SelectedBossTP = currentBossNames[1]
    end

    local selectedByOption = {
        SelectedBossDrop = _G.SelectedBoss,
        BossTPDrop = _G.SelectedBossTP,
    }
    for optionId, selectedName in pairs(selectedByOption) do
        local option = Fluent.Options and Fluent.Options[optionId]
        if option then
            pcall(function() option:SetValues(bossStatusLabels) end)
            local selectedLabel = bossNameToStatusLabel[selectedName] or bossStatusLabels[1]
            if selectedLabel and option.SetValue then
                pcall(function() option:SetValue(selectedLabel) end)
            end
        end
    end

    if bossStatusParagraph and bossStatusParagraph.SetDesc then
        pcall(function() bossStatusParagraph:SetDesc(bossStatusSummary) end)
    end
    if showNotice then
        notify("Danh sách Trùm", "Đã cập nhật trạng thái " .. #currentBossNames .. " Trùm.", 3)
    end
end

FarmBossSection:AddButton({
    Title = "Làm mới danh sách Trùm",
    Description = "Cập nhật ngay trạng thái đang xuất hiện hoặc chưa xuất hiện.",
    Callback = function() refreshBossInterface(true) end,
})
FarmBossSection:AddToggle("AutoFarmSeaBeast", {
    Title = "Tự động đánh Quái biển",
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
    Title = "Tự động luyện Haki quan sát",
    Description = "Duy trì Haki quan sát; kinh nghiệm chỉ tăng khi né đòn trong game",
    Default = _G.AutoFarmObs,
    Callback = function(v) _G.AutoFarmObs = v end,
})

FarmBossSection:AddToggle("AutoFarmBone", {
    Title = "Tự động kiếm Xương",
    Default = _G.AutoFarmBone,
    Callback = function(v) _G.AutoFarmBone = v end,
})

FarmBossSection:AddToggle("AutoFarmFragment", {
    Title = "Tự động kiếm Mảnh qua đột kích",
    Description = "Mua chip, bắt đầu đột kích và đánh quái để nhận Mảnh.",
    Default = _G.AutoFarmFragment,
    Callback = function(v) _G.AutoFarmFragment = v end,
})

FarmBossSection:AddToggle("AutoFarmChest", {
    Title = "Tự động nhặt Rương",
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
    Title = "Tự động bắt đầu đột kích",
    Description = "Tự động bắt đầu đột kích với chip được chọn",
    Default = _G.AutoRaid,
    Callback = function(v) _G.AutoRaid = v end,
})

RaidMainSection:AddToggle("AutoRaidFarmToggle", {
    Title = "Tự động đánh trong đột kích",
    Description = "Tự động đánh quái bên trong khu đột kích",
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
    Title = "Chọn chip đột kích",
    Values = RaidChips,
    Default = _G.RaidChip,
    Callback = function(v) _G.RaidChip = v end,
})

RaidMainSection:AddToggle("AutoAwakeningToggle", {
    Title = "Tự động thức tỉnh",
    Description = "Tự kiểm tra và thức tỉnh kỹ năng khi đang ở phòng Thức tỉnh",
    Default = _G.AutoAwakening,
    Callback = function(v) _G.AutoAwakening = v end,
})

RaidMainSection:AddButton({
    Title = "🔄 Bắt đầu đột kích ngay",
    Description = "Bắt đầu đột kích với chip đã chọn",
    Callback = function()
        if WorldSea == 1 then
            notify("Đột kích", "Đột kích chỉ mở tại Biển 2 hoặc Biển 3.", 4)
        elseif startSelectedRaid() then
            notify("⚡ Đột kích", "Đã gửi thao tác bắt đầu đột kích " .. _G.RaidChip .. ".", 3)
        end
    end
})

end)

-- ==================== TAB 4: FRUIT ====================
local FruitTab = UITabs.Fruit
runFeature("Giao diện Trái", function()

local FruitAutoSection = FruitTab:AddSection("Theo dõi & tự động nhặt")

FruitAutoSection:AddToggle("AutoFindFruitToggle", {
    Title = "Báo khi Trái xuất hiện",
    Description = "Thông báo khi có Trái ác quỷ xuất hiện trên bản đồ",
    Default = _G.AutoFruitFinder,
    Callback = function(v) _G.AutoFruitFinder = v end,
})

FruitAutoSection:AddToggle("AutoCollectFruitToggle", {
    Title = "Tự động nhặt Trái",
    Description = "Nếu đang dưới biển: nổi lên, ghé bờ rồi mới bay tới Trái; sau đó quay lại luyện cấp",
    Default = _G.AutoCollectFruit,
    Callback = function(v)
        local wasFruitMode = getActiveMovementMode() == "fruit"
        _G.AutoCollectFruit = v
        if not v then
            activeFruitTarget = nil
            if wasFruitMode then stopFarmMovement() end
        end
    end,
})

FruitAutoSection:AddToggle("AutoStoreFruitToggle", {
    Title = "Tự động cất Trái vào kho",
    Description = "Cất trái vừa nhặt; nếu kho đã có trái đó thì giữ trái trùng ngoài tay.",
    Default = _G.AutoStoreFruit,
    Callback = function(v) _G.AutoStoreFruit = v end,
})

FruitAutoSection:AddToggle("FruitESPToggle", {
    Title = "Đánh dấu Trái ác quỷ",
    Description = "Hiển thị vị trí Trái ác quỷ trên bản đồ",
    Default = _G.FruitESP,
    Callback = function(v) _G.FruitESP = v end,
})

FruitAutoSection:AddToggle("AutoGachaToggle", {
    Title = "Tự động mua Trái ngẫu nhiên",
    Description = "Gửi yêu cầu mua trái mỗi 30 giây; game vẫn áp dụng tiền và thời gian chờ",
    Default = _G.AutoGachaFruit,
    Callback = function(v) _G.AutoGachaFruit = v end,
})

local FruitActionSection = FruitTab:AddSection("Thao tác nhanh")

FruitActionSection:AddButton({
    Title = "Kiểm tra và cất trái đang giữ",
    Description = "Cất trái chưa có trong kho; trái trùng sẽ được giữ ngoài tay.",
    Callback = function()
        task.spawn(function()
            local stored, duplicates, failed = FruitStorage.StoreNow(true)
            notify(
                "Kiểm tra kho trái",
                string.format("Đã cất %d • Trùng %d • Lỗi %d\n%s",
                    stored, duplicates, failed, FruitStorage.GetStatus()),
                6
            )
        end)
    end,
})

FruitActionSection:AddButton({
    Title = "Mua trái ngẫu nhiên",
    Description = "Mua một Trái ngẫu nhiên từ người bán Trái ác quỷ",
    Callback = function()
        pcall(function()
            local res = ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            notify("🎰 Mua Trái ngẫu nhiên", tostring(res or "Đã gửi yêu cầu Mua trái"), 6)
        end)
    end
})

FruitActionSection:AddButton({
    Title = "Quét trái trên toàn bản đồ",
    Description = "Quét các Trái thật đang nằm trên bản đồ",
    Callback = function()
        local fruits = getSpawnedFruits()
        if #fruits == 0 then
            notify("🔍 Quét xong", "Không tìm thấy trái nào trên map", 3)
            return
        end
        for index, fruit in ipairs(fruits) do
            local handle = getFruitHandle(fruit)
            notify("🍎 Trái #" .. index, fruit.Name .. " tại " .. tostring(handle and handle.Position), 5)
        end
        notify("🔍 Quét xong", "Tìm thấy " .. #fruits .. " trái!", 3)
    end
})


FruitActionSection:AddButton({
    Title = "Mở cửa hàng trái",
    Description = "Nạp dữ liệu và mở cửa hàng Trái nếu game đã tạo giao diện.",
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
    Title = "Đánh dấu người chơi",
    Description = "Hiển thị người chơi khác và có thể bỏ qua đồng đội",
    Default = _G.ESPPlayer,
    Callback = function(v) _G.ESPPlayer = v; if not v then clearESPKind("player") end end,
})

ESPTargetSection:AddToggle("ESPTeamCheckToggle", {
    Title = "Bỏ qua đồng đội",
    Description = "Bỏ qua đồng đội",
    Default = _G.ESPTeamCheck,
    Callback = function(v) _G.ESPTeamCheck = v end,
})

ESPTargetSection:AddToggle("ESPMobToggle", {
    Title = "Đánh dấu quái",
    Description = "Hiển thị quái thường",
    Default = _G.ESPMob,
    Callback = function(v) _G.ESPMob = v; if not v then clearESPKind("mob") end end,
})

ESPTargetSection:AddToggle("ESPBossToggle", {
    Title = "Đánh dấu Trùm",
    Description = "Hiển thị các Trùm thường, Trùm đột kích và Trùm trong dữ liệu",
    Default = _G.ESPBoss,
    Callback = function(v) _G.ESPBoss = v; if not v then clearESPKind("boss") end end,
})

ESPTargetSection:AddToggle("ESPChestToggle", {
    Title = "Đánh dấu Rương",
    Description = "Hiển thị rương",
    Default = _G.ESPChest,
    Callback = function(v) _G.ESPChest = v; if not v then clearESPKind("chest") end end,
})

ESPTargetSection:AddToggle("ESPFlowerToggle", {
    Title = "Đánh dấu Hoa",
    Description = "Hiển thị hoa",
    Default = _G.ESPFlower,
    Callback = function(v) _G.ESPFlower = v; if not v then clearESPKind("flower") end end,
})

ESPTargetSection:AddToggle("ESPIslandToggle", {
    Title = "Đánh dấu Đảo",
    Description = "Hiển thị tên đảo",
    Default = _G.ESPIsland,
    Callback = function(v)
        _G.ESPIsland = v
        setIslandESP(v)
    end,
})

local ESPStyleSection = ESPTab:AddSection("Khoảng cách & màu sắc")

ESPStyleSection:AddSlider("ESPDistSlider", {
    Title = "Khoảng cách hiển thị",
    Min = 100,
    Max = 10000,
    Default = _G.ESPDistance,
    Rounding = 0,
    Callback = function(v) _G.ESPDistance = v end,
})

ESPStyleSection:AddColorpicker("ESPPlayerColor", {
    Title = "Màu người chơi",
    Default = _G.ESPPlayerColor,
    Callback = function(v) _G.ESPPlayerColor = v end,
})

ESPStyleSection:AddColorpicker("ESPMobColorPick", {
    Title = "Màu quái",
    Default = _G.ESPMobColor,
    Callback = function(v) _G.ESPMobColor = v end,
})

ESPStyleSection:AddColorpicker("ESPBossColorPick", {
    Title = "Màu Trùm",
    Default = _G.ESPBossColor,
    Callback = function(v) _G.ESPBossColor = v end,
})

ESPStyleSection:AddColorpicker("ESPFruitColorPick", {
    Title = "Màu Trái",
    Default = _G.ESPFruitColor,
    Callback = function(v) _G.ESPFruitColor = v end,
})

ESPStyleSection:AddButton({
    Title = "Tắt và xóa toàn bộ đánh dấu",
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

local IslandSection = TeleportTab:AddSection("Đảo tại Biển " .. WorldSea)

-- Lấy danh sách đảo theo Sea hiện tại
local currentIslands = getSeaIslands()
islandNames = {}
for name, _ in pairs(currentIslands) do
    table.insert(islandNames, name)
end
table.sort(islandNames)
if #islandNames > 0 and (_G.SelectedIsland == "" or not currentIslands[_G.SelectedIsland]) then
    _G.SelectedIsland = islandNames[1]
end

IslandSection:AddDropdown("IslandDrop", {
    Title = "Chọn Đảo (Biển " .. WorldSea .. ")",
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
            local arrived = manualTeleportTo(CFrame.new(targetPos))
            notify(arrived and "✅ Đã Đến" or "⚠️ Di chuyển bị gián đoạn", _G.SelectedIsland, 2)
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
                    local arrived = manualTeleportTo(CFrame.new(npc.Position))
                    notify(arrived and "✅ Đã đến NPC" or "⚠️ Di chuyển bị gián đoạn", npc.Name, 2)
                    break
                end
            end
        end
    })
end

-- Teleport Boss
local BossTeleportSection = TeleportTab:AddSection("Trùm")

if _G.SelectedBossTP == "" or not table.find(currentBossNames, _G.SelectedBossTP) then
    _G.SelectedBossTP = currentBossNames[1] or ""
end

BossTeleportSection:AddDropdown("BossTPDrop", {
    Title = "Chọn Trùm",
    Values = bossStatusLabels,
    Default = bossNameToStatusLabel[_G.SelectedBossTP] or bossStatusLabels[1],
    Callback = function(v)
        _G.SelectedBossTP = bossStatusLabelToName[v] or _G.SelectedBossTP
    end,
})

BossTeleportSection:AddButton({
    Title = "💀 Bay tới Trùm",
    Callback = function()
        local bossData = getBossData(_G.SelectedBossTP)
        if bossData then
            notify("✈️ Teleport", "Đang bay tới " .. bossData.Name, 3)
            local arrived = manualTeleportTo(CFrame.new(bossData.Position))
            notify(arrived and "✅ Đã đến Trùm" or "⚠️ Di chuyển bị gián đoạn", bossData.Name, 2)
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
        local handle = getFruitHandle(closestFruit)
        if closestFruit and handle then
            notify("Dịch chuyển Trái", "Đang kiểm tra đường đi tới " .. closestFruit.Name, 3)
            local arrived = moveToFruitSafely(closestFruit, true)
            notify(arrived and "✅ Đã đến trái" or "⚠️ Di chuyển bị gián đoạn", closestFruit.Name, 2)
        else
            notify("❌", "Không tìm thấy trái trên map", 2)
        end
    end
})


-- Quick Teleport đến các Sea khác
local SeaSection = TeleportTab:AddSection("Chuyển vùng biển")

SeaSection:AddButton({
    Title = "🌊 Đi Biển 1",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(2753915549, Player)
        end)
    end
})

SeaSection:AddButton({
    Title = "🌊 Đi Biển 2",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(4442272183, Player)
        end)
    end
})

SeaSection:AddButton({
    Title = "🌊 Đi Biển 3",
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
    Title = "Tự động bật Haki vũ trang",
    Description = "Tự động bật Buso Haki (Haki Vũ Trang)",
    Default = _G.AutoHaki,
    Callback = function(v) _G.AutoHaki = v end,
})

CombatAutoSection:AddToggle("AutoKenToggle", {
    Title = "Tự động bật Haki quan sát",
    Description = "Tự động bật Ken Haki (Haki Quan Sát)",
    Default = _G.AutoKen,
    Callback = function(v) _G.AutoKen = v; if v then activateObservation(true) end end,
})

CombatAutoSection:AddToggle("AutoObsV2Toggle", {
    Title = "Duy trì Haki quan sát",
    Description = "Duy trì Observation sau khi hồi sinh; không tự mở khóa V2",
    Default = _G.AutoObsV2,
    Callback = function(v) _G.AutoObsV2 = v; if v then activateObservation(true) end end,
})

CombatAutoSection:AddToggle("AutoDodgeToggle", {
    Title = "Tự động né đòn",
    Description = "Tự động né tránh đạn/đòn đánh",
    Default = _G.AutoDodge,
    Callback = function(v) _G.AutoDodge = v end,
})

local SaberQuestSection = CombatTab:AddSection("Saber Puzzle & Haki Quan Sát")

SaberQuestSection:AddToggle("AutoSaberQuestToggle", {
    Title = "Tự động làm nhiệm vụ lấy Saber",
    Description = "Dành cho Biển 1, cấp 200 trở lên; tự làm puzzle, đánh Mob Leader và Saber Expert.",
    Default = _G.AutoSaberQuest,
    Callback = function(v)
        _G.AutoSaberQuest = v
        stopFarmMovement()
        if v then
            SaberQuest.PrepareStart()
            notify(
                "Saber Puzzle",
                "Đã bắt đầu. Tính năng Saber được ưu tiên di chuyển hơn các chế độ Auto Farm khác.",
                6
            )
        else
            notify("Saber Puzzle", "Đã dừng: " .. SaberQuest.GetStatus(), 4)
        end
    end,
})

SaberQuestSection:AddButton({
    Title = "Xem tiến độ Saber hiện tại",
    Description = "Hiển thị bước mà hệ thống đang thực hiện hoặc điều kiện còn thiếu.",
    Callback = function()
        notify("Tiến độ Saber Puzzle", SaberQuest.GetStatus(), 7)
    end,
})

local CombatShopSection = CombatTab:AddSection("Cửa hàng phong cách cận chiến")

CombatShopSection:AddDropdown("FightingStyleShopDrop", {
    Title = "Chọn phong cách muốn mua",
    Description = "Giá được hiển thị ngay cạnh tên; mua lại phong cách đã sở hữu thường sẽ trang bị lại.",
    Values = CombatShop.StyleLabels,
    Default = CombatShop.GetStyleLabel(_G.SelectedFightingStyleShop),
    Callback = function(v)
        _G.SelectedFightingStyleShop = CombatShop.GetStyleId(v)
    end,
})

CombatShopSection:AddButton({
    Title = "Mua / trang bị phong cách đã chọn",
    Description = "Game tự kiểm tra tiền, Mảnh, thông thạo, nhiệm vụ và nguyên liệu.",
    Callback = function()
        task.spawn(function() CombatShop.BuyStyle(_G.SelectedFightingStyleShop) end)
    end,
})

CombatShopSection:AddButton({
    Title = "Xem giá và điều kiện",
    Description = "Hiện đầy đủ điều kiện của phong cách đang chọn.",
    Callback = function()
        CombatShop.ShowStyleInfo(_G.SelectedFightingStyleShop)
    end,
})

local AbilityShopSection = CombatTab:AddSection("Cửa hàng Haki & kỹ năng cơ bản")

AbilityShopSection:AddButton({
    Title = "Mua Nhảy trên không — 10.000 Beli",
    Description = "Tên nội bộ: Geppo / Air Jump.",
    Callback = function() CombatShop.BuyAbility("AirJump") end,
})

AbilityShopSection:AddButton({
    Title = "Mua Haki Vũ Trang — 25.000 Beli",
    Description = "Aura/Buso giúp đánh trúng mục tiêu hệ Nguyên tố.",
    Callback = function() CombatShop.BuyAbility("Aura") end,
})

AbilityShopSection:AddButton({
    Title = "Mua Bước nhanh — 100.000 Beli",
    Description = "Flash Step/Soru.",
    Callback = function() CombatShop.BuyAbility("FlashStep") end,
})

AbilityShopSection:AddButton({
    Title = "Mua Haki Quan Sát — 750.000 Beli",
    Description = "Yêu cầu cấp 300 trở lên và hoàn thành Saber Puzzle.",
    Callback = function() CombatShop.BuyAbility("Instinct") end,
})

AbilityShopSection:AddButton({
    Title = "Mua toàn bộ kỹ năng cơ bản — 885.000 Beli",
    Description = "Mua Air Jump, Aura, Flash Step và Instinct; game tự kiểm tra kỹ năng đã sở hữu.",
    Callback = function()
        task.spawn(function() CombatShop.BuyAllAbilities() end)
    end,
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
    Title = "Duy trì Haki quan sát",
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
    Title = "Điều chỉnh tốc độ chạy",
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
    Title = "Điều chỉnh sức nhảy",
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
    Title = "Nhảy vô hạn",
    Description = "Nhảy không giới hạn trên không",
    Default = _G.InfiniteJump,
    Callback = function(v) _G.InfiniteJump = v end,
})

MovementSection:AddToggle("InfiniteEnergyToggle", {
    Title = "Năng lượng vô hạn",
    Description = "Năng lượng không giới hạn",
    Default = _G.InfiniteEnergy,
    Callback = function(v) _G.InfiniteEnergy = v end,
})

-- Stats
local StatsSection = MiscTab:AddSection("Chỉ số tự động")

StatsSection:AddToggle("AutoStatsToggle", {
    Title = "Tự động cộng điểm chỉ số",
    Default = _G.AutoStats,
    Callback = function(v) _G.AutoStats = v end,
})

StatsSection:AddDropdown("StatDropdown", {
    Title = "Chọn chỉ số",
    Values = statLabels,
    Default = statValueToLabel[_G.StatToUpgrade] or statLabels[1],
    Callback = function(v) _G.StatToUpgrade = statLabelToValue[v] or _G.StatToUpgrade end,
})

-- Mã quà tặng
local RewardCodeSection = MiscTab:AddSection("Mã x2 EXP & đặt lại chỉ số")

RewardCodeSection:AddParagraph({
    Title = "Danh sách mã đang hoạt động",
    Content = "Đã đối chiếu ngày 31/07/2026 • 18 mã x2 EXP • 3 mã đặt lại chỉ số."
})

RewardCodeSection:AddToggle("AutoRedeemExpCodesToggle", {
    Title = "Tự nhập mã x2 EXP",
    Description = "Tự nhập một lần sau khi vào game; thời gian x2 EXP hợp lệ sẽ cộng dồn.",
    Default = _G.AutoRedeemExpCodes,
    Callback = function(v)
        _G.AutoRedeemExpCodes = v
        if v then RewardCodes.SetPending("exp") end
    end,
})

RewardCodeSection:AddToggle("AutoRedeemResetCodesToggle", {
    Title = "Tự nhập mã đặt lại chỉ số",
    Description = "Cảnh báo: mã hợp lệ sẽ đặt lại toàn bộ điểm đã cộng. Mặc định tắt.",
    Default = _G.AutoRedeemResetCodes,
    Callback = function(v)
        _G.AutoRedeemResetCodes = v
        if v then RewardCodes.SetPending("reset") end
    end,
})

RewardCodeSection:AddButton({
    Title = "Nhập lại toàn bộ mã x2 EXP",
    Description = "Thử lại cả mã mới lẫn mã đã thử trong phiên hiện tại.",
    Callback = function()
        task.spawn(function() RewardCodes.RedeemExp(true) end)
    end,
})

RewardCodeSection:AddButton({
    Title = "Nhập mã đặt lại chỉ số ngay",
    Description = "Chỉ dùng khi bạn thực sự muốn xóa cách cộng điểm hiện tại.",
    Callback = function()
        task.spawn(function() RewardCodes.RedeemReset(true) end)
    end,
})

-- Anti-AFK
local ProtectionSection = MiscTab:AddSection("Bảo vệ phiên chơi")

ProtectionSection:AddToggle("AntiAFKToggle", {
    Title = "Chống mất kết nối khi đứng yên",
    Description = "Ngăn game ngắt kết nối do đứng yên quá lâu",
    Default = _G.AntiAFK,
    Callback = function(v) _G.AntiAFK = v end,
})

-- FPS Boost
local PerformanceSection = MiscTab:AddSection("Hiệu năng & hiển thị")

PerformanceSection:AddButton({
    Title = "Tối ưu FPS",
    Description = "Tắt họa tiết và hiệu ứng hạt để giảm giật; vào lại máy chủ để hoàn tác.",
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
    Description = "Xóa bầu trời và đổi nền thành màu trắng",
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
    Description = "Xóa bầu trời và đổi nền thành màu đen",
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
    Description = "Chuyển sang máy chủ công khai khác",
    Callback = function()
        notify("Đổi máy chủ", "Đang tìm máy chủ...", 2)
        serverHop()
    end
})

MiscServerSection:AddToggle("ServerHopNoFruitToggle", {
    Title = "Tự đổi máy chủ khi không có Trái",
    Description = "Tự động chuyển sang máy chủ ít người nếu không tìm thấy Trái",
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
                "Cấp: %s\nTiền: %s\nMảnh: %s\nBiển: %d\nMáy chủ: %s",
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

-- Tự cập nhật trạng thái Trùm khi Trùm xuất hiện hoặc bị hạ.
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(2)
        if refreshBossInterface then pcall(refreshBossInterface, false) end
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
        NoAttackAnimationToggle = "NoAttackAnimation",
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
        AutoStoreFruitToggle = "AutoStoreFruit",
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
        FightingStyleShopDrop = "SelectedFightingStyleShop",
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
        LowServerMaxPlayersSlider = "LowServerMaxPlayers",
        AutoRedeemExpCodesToggle = "AutoRedeemExpCodes",
        AutoRedeemResetCodesToggle = "AutoRedeemResetCodes",
        AutoChooseTeamToggle = "AutoChooseTeam",
        PreferredTeamDrop = "PreferredTeam",
        ESPPlayerColor = "ESPPlayerColor",
        ESPMobColorPick = "ESPMobColor",
        ESPBossColorPick = "ESPBossColor",
        ESPFruitColorPick = "ESPFruitColor",
    }

    for optionId, stateKey in pairs(teleportOptionMap) do
        local option = Fluent.Options[optionId]
        local value = teleportState[stateKey]
        if option and value ~= nil and option.SetValue then
            local displayValue = value
            if optionId == "MasteryWeaponDrop" or optionId == "SelectWeaponDrop" then
                displayValue = weaponValueToLabel[value] or value
            elseif optionId == "FarmMethodDrop" then
                displayValue = farmMethodValueToLabel[value] or value
            elseif optionId == "StatDropdown" then
                displayValue = statValueToLabel[value] or value
            elseif optionId == "PreferredTeamDrop" then
                displayValue = teamValueToLabel[value] or value
            elseif optionId == "FightingStyleShopDrop" then
                displayValue = CombatShop.GetStyleLabel(value)
            elseif optionId == "SelectedBossDrop" or optionId == "BossTPDrop" then
                displayValue = bossNameToStatusLabel[value] or value
            end
            pcall(function() option:SetValue(displayValue) end)
        end
    end
end


if Window and Window.SelectTab then
    pcall(function() Window:SelectTab(1) end)
end

RuntimeEnv.HAOTOOL_UI_READY = createdTabCount == 9
RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = nil

-- Thông báo load thành công
notify(
    "HAOTOOL • Sẵn sàng",
    "Biển " .. WorldSea
        .. "  •  " .. #(WorldSea == 1 and QuestsSea1 or WorldSea == 2 and QuestsSea2 or QuestsSea3) .. " nhiệm vụ"
        .. "  •  " .. #islandNames .. " đảo"
        .. "\nGiao diện: " .. createdTabCount .. "/9 tab"
        .. "\nRightControl hoặc nút H để ẩn / hiện giao diện"
        .. (teleportReloadReady and "  •  Tự nạp khi đổi máy chủ: BẬT" or "  •  Trình thực thi không hỗ trợ tự nạp"),
    6
)

print("=====================================")
print("⚡ HAOTOOL v2.3.4 — ĐÃ KHỞI ĐỘNG THÀNH CÔNG")
print("🌊 Biển: " .. WorldSea)
print("📌 RightControl để ẩn hoặc hiện giao diện")
print("=====================================")

end

buildMainInterface()
]========]

local HAOTOOL_FLUENT_SOURCE = [==========[
--[[
    Fluent Interface Suite
    This script is not intended to be modified.
    To view the source code, see the 'src' folder on GitHub!

    Author: dawid
    License: MIT
    GitHub: https://github.com/dawid-scripts/Fluent
--]]

local a,b={{1,'ModuleScript',{'MainModule'},{{18,'ModuleScript',{'Creator'}},{28,'ModuleScript',{'Icons'}},{47,'ModuleScript',{'Themes'},{{50,'ModuleScript',{'Dark'}},{52,'ModuleScript',{'Light'}},{51,'ModuleScript',{'Darker'}},{53,'ModuleScript',{'Rose'}},{49,'ModuleScript',{'Aqua'}},{48,'ModuleScript',{'Amethyst'}}}},{19,'ModuleScript',{'Elements'},{{21,'ModuleScript',{'Colorpicker'}},{27,'ModuleScript',{'Toggle'}},{23,'ModuleScript',{'Input'}},{20,'ModuleScript',{'Button'}},{25,'ModuleScript',{'Paragraph'}},{22,'ModuleScript',{'Dropdown'}},{26,'ModuleScript',{'Slider'}},{24,'ModuleScript',{'Keybind'}}}},{29,'Folder',{'Packages'},{{30,'ModuleScript',{'Flipper'},{{33,'ModuleScript',{'GroupMotor'}},{46,'ModuleScript',{'isMotor.spec'}},{39,'ModuleScript',{'Signal'}},{40,'ModuleScript',{'Signal.spec'}},{45,'ModuleScript',{'isMotor'}},{36,'ModuleScript',{'Instant.spec'}},{44,'ModuleScript',{'Spring.spec'}},{42,'ModuleScript',{'SingleMotor.spec'}},{38,'ModuleScript',{'Linear.spec'}},{31,'ModuleScript',{'BaseMotor'}},{43,'ModuleScript',{'Spring'}},{35,'ModuleScript',{'Instant'}},{37,'ModuleScript',{'Linear'}},{41,'ModuleScript',{'SingleMotor'}},{34,'ModuleScript',{'GroupMotor.spec'}},{32,'ModuleScript',{'BaseMotor.spec'}}}}}},{2,'ModuleScript',{'Acrylic'},{{3,'ModuleScript',{'AcrylicBlur'}},{5,'ModuleScript',{'CreateAcrylic'}},{6,'ModuleScript',{'Utils'}},{4,'ModuleScript',{'AcrylicPaint'}}}},{7,'Folder',{'Components'},{{9,'ModuleScript',{'Button'}},{12,'ModuleScript',{'Notification'}},{13,'ModuleScript',{'Section'}},{17,'ModuleScript',{'Window'}},{14,'ModuleScript',{'Tab'}},{10,'ModuleScript',{'Dialog'}},{8,'ModuleScript',{'Assets'}},{16,'ModuleScript',{'TitleBar'}},{15,'ModuleScript',{'Textbox'}},{11,'ModuleScript',{'Element'}}}}}}}local aa={function()local c,d,e,f,g=b(1)local h,i,j,k,l,m=game:GetService'Lighting',game:GetService'RunService',game:GetService'Players'.LocalPlayer,game:GetService'UserInputService',game:GetService'TweenService',game:GetService'Workspace'.CurrentCamera local n,o=j:GetMouse(),d local p,q,r,s=e(o.Creator),e(o.Elements),e(o.Acrylic),o.Components local t,u,v=e(s.Notification),p.New,protectgui or(syn and syn.protect_gui)or function()end local w=u('ScreenGui',{Parent=i:IsStudio()and j.PlayerGui or game:GetService'CoreGui'})v(w)t:Init(w)local x={Version='1.1.0',OpenFrames={},Options={},Themes=e(o.Themes).Names,Window=nil,WindowFrame=nil,Unloaded=false,Theme='Dark',DialogOpen=false,UseAcrylic=false,Acrylic=false,Transparency=true,MinimizeKeybind=nil,MinimizeKey=Enum.KeyCode.LeftControl,GUI=w}function x.SafeCallback(y,z,...)if not z then return end local A,B=pcall(z,...)if not A then local C,D=B:find':%d+: 'if not D then return x:Notify{Title='Interface',Content='Callback error',SubContent=B,Duration=5}end return x:Notify{Title='Interface',Content='Callback error',SubContent=B:sub(D+1),Duration=5}end end function x.Round(y,z,A)if A==0 then return math.floor(z)end z=tostring(z)return z:find'%.'and tonumber(z:sub(1,z:find'%.'+A))or z end local y=e(o.Icons).assets function x.GetIcon(z,A)if A~=nil and y['lucide-'..A]then return y['lucide-'..A]end return nil end local z={}z.__index=z z.__namecall=function(A,B,...)return z[B](...)end for A,B in ipairs(q)do z['Add'..B.__type]=function(C,D,E)B.Container=C.Container B.Type=C.Type B.ScrollFrame=C.ScrollFrame B.Library=x return B:New(D,E)end end x.Elements=z function x.CreateWindow(C,D)assert(D.Title,'Window - Missing Title')if x.Window then print'You cannot create more than one window.'return end x.MinimizeKey=D.MinimizeKey x.UseAcrylic=D.Acrylic if D.Acrylic then r.init()end local E=e(s.Window){Parent=w,Size=D.Size,Title=D.Title,SubTitle=D.SubTitle,TabWidth=D.TabWidth}x.Window=E x:SetTheme(D.Theme)return E end function x.SetTheme(C,D)if x.Window and table.find(x.Themes,D)then x.Theme=D p.UpdateTheme()end end function x.Destroy(C)if x.Window then x.Unloaded=true if x.UseAcrylic then x.Window.AcrylicPaint.Model:Destroy()end p.Disconnect()x.GUI:Destroy()end end function x.ToggleAcrylic(C,D)if x.Window then if x.UseAcrylic then x.Acrylic=D x.Window.AcrylicPaint.Model.Transparency=D and 0.98 or 1 if D then r.Enable()else r.Disable()end end end end function x.ToggleTransparency(C,D)if x.Window then x.Window.AcrylicPaint.Frame.Background.BackgroundTransparency=D and 0.35 or 0 end end function x.Notify(C,D)return t:New(D)end if getgenv then getgenv().Fluent=x end return x end,function()local c,d,e,f,g=b(2)local h={AcrylicBlur=e(d.AcrylicBlur),CreateAcrylic=e(d.CreateAcrylic),AcrylicPaint=e(d.AcrylicPaint)}function h.init()local i=Instance.new'DepthOfFieldEffect'i.FarIntensity=0 i.InFocusRadius=0.1 i.NearIntensity=1 local j={}function h.Enable()for k,l in pairs(j)do l.Enabled=false end i.Parent=game:GetService'Lighting'end function h.Disable()for k,l in pairs(j)do l.Enabled=l.enabled end i.Parent=nil end local k=function()local k=function(k)if k:IsA'DepthOfFieldEffect'then j[k]={enabled=k.Enabled}end end for l,m in pairs(game:GetService'Lighting':GetChildren())do k(m)end if game:GetService'Workspace'.CurrentCamera then for n,o in pairs(game:GetService'Workspace'.CurrentCamera:GetChildren())do k(o)end end end k()h.Enable()end return h end,function()local c,d,e,f,g=b(3)local h,i,j,k=e(d.Parent.Parent.Creator),e(d.Parent.CreateAcrylic),unpack(e(d.Parent.Utils))local l=function(l)local m={}l=l or 0.001 local n,o={topLeft=Vector2.new(),topRight=Vector2.new(),bottomRight=Vector2.new()},i()o.Parent=workspace local p,q=function(p,q)n.topLeft=q n.topRight=q+Vector2.new(p.X,0)n.bottomRight=q+p end,function()local p=game:GetService'Workspace'.CurrentCamera if p then p=p.CFrame end local q=p if not q then q=CFrame.new()end local r,s,t,u=q,n.topLeft,n.topRight,n.bottomRight local v,w,x=j(s,l),j(t,l),j(u,l)local y,z=(w-v).Magnitude,(w-x).Magnitude o.CFrame=CFrame.fromMatrix((v+x)/2,r.XVector,r.YVector,r.ZVector)o.Mesh.Scale=Vector3.new(y,z,0)end local r,s=function(r)local s=k()local t,u=r.AbsoluteSize-Vector2.new(s,s),r.AbsolutePosition+Vector2.new(s/2,s/2)p(t,u)task.spawn(q)end,function()local r=game:GetService'Workspace'.CurrentCamera if not r then return end table.insert(m,r:GetPropertyChangedSignal'CFrame':Connect(q))table.insert(m,r:GetPropertyChangedSignal'ViewportSize':Connect(q))table.insert(m,r:GetPropertyChangedSignal'FieldOfView':Connect(q))task.spawn(q)end o.Destroying:Connect(function()for t,u in m do pcall(function()u:Disconnect()end)end end)s()return r,o end return function(m)local n,o,p={},l(m)local q=h.New('Frame',{BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})h.AddSignal(q:GetPropertyChangedSignal'AbsolutePosition',function()o(q)end)h.AddSignal(q:GetPropertyChangedSignal'AbsoluteSize',function()o(q)end)n.AddParent=function(r)h.AddSignal(r:GetPropertyChangedSignal'Visible',function()n.SetVisibility(r.Visible)end)end n.SetVisibility=function(r)p.Transparency=r and 0.98 or 1 end n.Frame=q n.Model=p return n end end,function()local c,d,e,f,g=b(4)local h,i=e(d.Parent.Parent.Creator),e(d.Parent.AcrylicBlur)local j=h.New return function(k)local l={}l.Frame=j('Frame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=0.9,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0},{j('ImageLabel',{Image='rbxassetid://8992230677',ScaleType='Slice',SliceCenter=Rect.new(Vector2.new(99,99),Vector2.new(99,99)),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(1,120,1,116),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1,ImageColor3=Color3.fromRGB(0,0,0),ImageTransparency=0.7}),j('UICorner',{CornerRadius=UDim.new(0,8)}),j('Frame',{BackgroundTransparency=0.45,Size=UDim2.fromScale(1,1),Name='Background',ThemeTag={BackgroundColor3='AcrylicMain'}},{j('UICorner',{CornerRadius=UDim.new(0,8)})}),j('Frame',{BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.4,Size=UDim2.fromScale(1,1)},{j('UICorner',{CornerRadius=UDim.new(0,8)}),j('UIGradient',{Rotation=90,ThemeTag={Color='AcrylicGradient'}})}),j('ImageLabel',{Image='rbxassetid://9968344105',ImageTransparency=0.98,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.new(0,128,0,128),Size=UDim2.fromScale(1,1),BackgroundTransparency=1},{j('UICorner',{CornerRadius=UDim.new(0,8)})}),j('ImageLabel',{Image='rbxassetid://9968344227',ImageTransparency=0.9,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.new(0,128,0,128),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ThemeTag={ImageTransparency='AcrylicNoise'}},{j('UICorner',{CornerRadius=UDim.new(0,8)})}),j('Frame',{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=2},{j('UICorner',{CornerRadius=UDim.new(0,8)}),j('UIStroke',{Transparency=0.5,Thickness=1,ThemeTag={Color='AcrylicBorder'}})})})local m if e(d.Parent.Parent).UseAcrylic then m=i()m.Frame.Parent=l.Frame l.Model=m.Model l.AddParent=m.AddParent l.SetVisibility=m.SetVisibility end return l end end,function()local c,d,e,f,g=b(5)local h=d.Parent.Parent local i=e(h.Creator)local j=function()local j=i.New('Part',{Name='Body',Color=Color3.new(0,0,0),Material=Enum.Material.Glass,Size=Vector3.new(1,1,0),Anchored=true,CanCollide=false,Locked=true,CastShadow=false,Transparency=0.98},{i.New('SpecialMesh',{MeshType=Enum.MeshType.Brick,Offset=Vector3.new(0,0,-1E-6)})})return j end return j end,function()local c,d,e,f,g=b(6)local h,i=function(h,i,j,k,l)return(h-i)*(l-k)/(j-i)+k end,function(h,i)local j=game:GetService'Workspace'.CurrentCamera:ScreenPointToRay(h.X,h.Y)return j.Origin+j.Direction*i end local j=function()local j=game:GetService'Workspace'.CurrentCamera.ViewportSize.Y return h(j,0,2560,8,56)end return{i,j}end,[8]=function()local c,d,e,f,g=b(8)return{Close='rbxassetid://9886659671',Min='rbxassetid://9886659276',Max='rbxassetid://9886659406',Restore='rbxassetid://9886659001'}end,[9]=function()local c,d,e,f,g=b(9)local h=d.Parent.Parent local i,j=e(h.Packages.Flipper),e(h.Creator)local k,l=j.New,i.Spring.new return function(m,n,o)o=o or false local p={}p.Title=k('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',TextColor3=Color3.fromRGB(200,200,200),TextSize=14,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,BackgroundColor3=Color3.fromRGB(255,255,255),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ThemeTag={TextColor3='Text'}})p.HoverFrame=k('Frame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ThemeTag={BackgroundColor3='Hover'}},{k('UICorner',{CornerRadius=UDim.new(0,4)})})p.Frame=k('TextButton',{Size=UDim2.new(0,0,0,32),Parent=n,ThemeTag={BackgroundColor3='DialogButton'}},{k('UICorner',{CornerRadius=UDim.new(0,4)}),k('UIStroke',{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Transparency=0.65,ThemeTag={Color='DialogButtonBorder'}}),p.HoverFrame,p.Title})local q,r=j.SpringMotor(1,p.HoverFrame,'BackgroundTransparency',o)j.AddSignal(p.Frame.MouseEnter,function()r(0.97)end)j.AddSignal(p.Frame.MouseLeave,function()r(1)end)j.AddSignal(p.Frame.MouseButton1Down,function()r(1)end)j.AddSignal(p.Frame.MouseButton1Up,function()r(0.97)end)return p end end,[10]=function()local c,d,e,f,g=b(10)local h,i,j,k=game:GetService'UserInputService',game:GetService'Players'.LocalPlayer:GetMouse(),game:GetService'Workspace'.CurrentCamera,d.Parent.Parent local l,m=e(k.Packages.Flipper),e(k.Creator)local n,o,p,q=l.Spring.new,l.Instant.new,m.New,{Window=nil}function q.Init(r,s)q.Window=s return q end function q.Create(r)local s={Buttons=0}s.TintFrame=p('TextButton',{Text='',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=1,Parent=q.Window.Root},{p('UICorner',{CornerRadius=UDim.new(0,8)})})local t,u=m.SpringMotor(1,s.TintFrame,'BackgroundTransparency',true)s.ButtonHolder=p('Frame',{Size=UDim2.new(1,-40,1,-40),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),BackgroundTransparency=1},{p('UIListLayout',{Padding=UDim.new(0,10),FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})})s.ButtonHolderFrame=p('Frame',{Size=UDim2.new(1,0,0,70),Position=UDim2.new(0,0,1,-70),ThemeTag={BackgroundColor3='DialogHolder'}},{p('Frame',{Size=UDim2.new(1,0,0,1),ThemeTag={BackgroundColor3='DialogHolderLine'}}),s.ButtonHolder})s.Title=p('TextLabel',{FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),Text='Dialog',TextColor3=Color3.fromRGB(240,240,240),TextSize=22,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,22),Position=UDim2.fromOffset(20,25),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,ThemeTag={TextColor3='Text'}})s.Scale=p('UIScale',{Scale=1})local v,w=m.SpringMotor(1.1,s.Scale,'Scale')s.Root=p('CanvasGroup',{Size=UDim2.fromOffset(300,165),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),GroupTransparency=1,Parent=s.TintFrame,ThemeTag={BackgroundColor3='Dialog'}},{p('UICorner',{CornerRadius=UDim.new(0,8)}),p('UIStroke',{Transparency=0.5,ThemeTag={Color='DialogBorder'}}),s.Scale,s.Title,s.ButtonHolderFrame})local x,y=m.SpringMotor(1,s.Root,'GroupTransparency')function s.Open(z)e(k).DialogOpen=true s.Scale.Scale=1.1 u(0.75)y(0)w(1)end function s.Close(z)e(k).DialogOpen=false u(1)y(1)w(1.1)s.Root.UIStroke:Destroy()task.wait(0.15)s.TintFrame:Destroy()end function s.Button(z,A,B)s.Buttons=s.Buttons+1 A=A or'Button'B=B or function()end local C=e(k.Components.Button)('',s.ButtonHolder,true)C.Title.Text=A for D,E in next,s.ButtonHolder:GetChildren()do if E:IsA'TextButton'then E.Size=UDim2.new(1/s.Buttons,-(((s.Buttons-1)*10)/s.Buttons),0,32)end end m.AddSignal(C.Frame.MouseButton1Click,function()e(k):SafeCallback(B)pcall(function()s:Close()end)end)return C end return s end return q end,[11]=function()local c,d,e,f,g=b(11)local h=d.Parent.Parent local i,j=e(h.Packages.Flipper),e(h.Creator)local k,l=j.New,i.Spring.new return function(m,n,o,p)local q={}q.TitleLabel=k('TextLabel',{FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Medium,Enum.FontStyle.Normal),Text=m,TextColor3=Color3.fromRGB(240,240,240),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,14),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,ThemeTag={TextColor3='Text'}})q.DescLabel=k('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',Text=n,TextColor3=Color3.fromRGB(200,200,200),TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=Color3.fromRGB(255,255,255),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),ThemeTag={TextColor3='SubText'}})q.LabelHolder=k('Frame',{AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-28,0,0)},{k('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center}),k('UIPadding',{PaddingBottom=UDim.new(0,13),PaddingTop=UDim.new(0,13)}),q.TitleLabel,q.DescLabel})q.Border=k('UIStroke',{Transparency=0.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(0,0,0),ThemeTag={Color='ElementBorder'}})q.Frame=k('TextButton',{Size=UDim2.new(1,0,0,0),BackgroundTransparency=0.89,BackgroundColor3=Color3.fromRGB(130,130,130),Parent=o,AutomaticSize=Enum.AutomaticSize.Y,Text='',LayoutOrder=7,ThemeTag={BackgroundColor3='Element',BackgroundTransparency='ElementTransparency'}},{k('UICorner',{CornerRadius=UDim.new(0,4)}),q.Border,q.LabelHolder})function q.SetTitle(r,s)q.TitleLabel.Text=s end function q.SetDesc(r,s)if s==nil then s=''end if s==''then q.DescLabel.Visible=false else q.DescLabel.Visible=true end q.DescLabel.Text=s end function q.Destroy(r)q.Frame:Destroy()end q:SetTitle(m)q:SetDesc(n)if p then local r,s,t=h.Themes,j.SpringMotor(j.GetThemeProperty'ElementTransparency',q.Frame,'BackgroundTransparency',false,true)j.AddSignal(q.Frame.MouseEnter,function()t(j.GetThemeProperty'ElementTransparency'-j.GetThemeProperty'HoverChange')end)j.AddSignal(q.Frame.MouseLeave,function()t(j.GetThemeProperty'ElementTransparency')end)j.AddSignal(q.Frame.MouseButton1Down,function()t(j.GetThemeProperty'ElementTransparency'+j.GetThemeProperty'HoverChange')end)j.AddSignal(q.Frame.MouseButton1Up,function()t(j.GetThemeProperty'ElementTransparency'-j.GetThemeProperty'HoverChange')end)end return q end end,[12]=function()local c,d,e,f,g=b(12)local h=d.Parent.Parent local i,j,k=e(h.Packages.Flipper),e(h.Creator),e(h.Acrylic)local l,m,n,o=i.Spring.new,i.Instant.new,j.New,{}function o.Init(p,q)o.Holder=n('Frame',{Position=UDim2.new(1,-30,1,-30),Size=UDim2.new(0,310,1,-30),AnchorPoint=Vector2.new(1,1),BackgroundTransparency=1,Parent=q},{n('UIListLayout',{HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,20)})})end function o.New(p,q)q.Title=q.Title or'Title'q.Content=q.Content or'Content'q.SubContent=q.SubContent or''q.Duration=q.Duration or nil q.Buttons=q.Buttons or{}local r={Closed=false}r.AcrylicPaint=k.AcrylicPaint()r.Title=n('TextLabel',{Position=UDim2.new(0,14,0,17),Text=q.Title,RichText=true,TextColor3=Color3.fromRGB(255,255,255),TextTransparency=0,FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',TextSize=13,TextXAlignment='Left',TextYAlignment='Center',Size=UDim2.new(1,-12,0,12),TextWrapped=true,BackgroundTransparency=1,ThemeTag={TextColor3='Text'}})r.ContentLabel=n('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',Text=q.Content,TextColor3=Color3.fromRGB(240,240,240),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,0,0,14),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,TextWrapped=true,ThemeTag={TextColor3='Text'}})r.SubContentLabel=n('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',Text=q.SubContent,TextColor3=Color3.fromRGB(240,240,240),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,0,0,14),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,TextWrapped=true,ThemeTag={TextColor3='SubText'}})r.LabelHolder=n('Frame',{AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Position=UDim2.fromOffset(14,40),Size=UDim2.new(1,-28,0,0)},{n('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,3)}),r.ContentLabel,r.SubContentLabel})r.CloseButton=n('TextButton',{Text='',Position=UDim2.new(1,-14,0,13),Size=UDim2.fromOffset(20,20),AnchorPoint=Vector2.new(1,0),BackgroundTransparency=1},{n('ImageLabel',{Image=e(d.Parent.Assets).Close,Size=UDim2.fromOffset(16,16),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,ThemeTag={ImageColor3='Text'}})})r.Root=n('Frame',{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Position=UDim2.fromScale(1,0)},{r.AcrylicPaint.Frame,r.Title,r.CloseButton,r.LabelHolder})if q.Content==''then r.ContentLabel.Visible=false end if q.SubContent==''then r.SubContentLabel.Visible=false end r.Holder=n('Frame',{BackgroundTransparency=1,Size=UDim2.new(1,0,0,200),Parent=o.Holder},{r.Root})local s=i.GroupMotor.new{Scale=1,Offset=60}s:onStep(function(t)r.Root.Position=UDim2.new(t.Scale,t.Offset,0,0)end)j.AddSignal(r.CloseButton.MouseButton1Click,function()r:Close()end)function r.Open(t)local u=r.LabelHolder.AbsoluteSize.Y r.Holder.Size=UDim2.new(1,0,0,58+u)s:setGoal{Scale=l(0,{frequency=5}),Offset=l(0,{frequency=5})}end function r.Close(t)if not r.Closed then r.Closed=true task.spawn(function()s:setGoal{Scale=l(1,{frequency=5}),Offset=l(60,{frequency=5})}task.wait(0.4)if e(h).UseAcrylic then r.AcrylicPaint.Model:Destroy()end r.Holder:Destroy()end)end end r:Open()if q.Duration then task.delay(q.Duration,function()r:Close()end)end return r end return o end,[13]=function()local c,d,e,f,g=b(13)local h=d.Parent.Parent local i=e(h.Creator)local j=i.New return function(k,l)local m={}m.Layout=j('UIListLayout',{Padding=UDim.new(0,5)})m.Container=j('Frame',{Size=UDim2.new(1,0,0,26),Position=UDim2.fromOffset(0,24),BackgroundTransparency=1},{m.Layout})m.Root=j('Frame',{BackgroundTransparency=1,Size=UDim2.new(1,0,0,26),LayoutOrder=7,Parent=l},{j('TextLabel',{RichText=true,Text=k,TextTransparency=0,FontFace=Font.new('rbxassetid://12187365364',Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),TextSize=18,TextXAlignment='Left',TextYAlignment='Center',Size=UDim2.new(1,-16,0,18),Position=UDim2.fromOffset(0,2),ThemeTag={TextColor3='Text'}}),m.Container})i.AddSignal(m.Layout:GetPropertyChangedSignal'AbsoluteContentSize',function()m.Container.Size=UDim2.new(1,0,0,m.Layout.AbsoluteContentSize.Y)m.Root.Size=UDim2.new(1,0,0,m.Layout.AbsoluteContentSize.Y+25)end)return m end end,[14]=function()local c,d,e,f,g=b(14)local h=d.Parent.Parent local i,j=e(h.Packages.Flipper),e(h.Creator)local k,l,m,n,o=j.New,i.Spring.new,i.Instant.new,h.Components,{Window=nil,Tabs={},Containers={},SelectedTab=0,TabCount=0}function o.Init(p,q)o.Window=q return o end function o.GetCurrentTabPos(p)local q,r=o.Window.TabHolder.AbsolutePosition.Y,o.Tabs[o.SelectedTab].Frame.AbsolutePosition.Y return r-q end function o.New(p,q,r,s)local t,u=e(h),o.Window local v=t.Elements o.TabCount=o.TabCount+1 local w,x=o.TabCount,{Selected=false,Name=q,Type='Tab'}if t:GetIcon(r)then r=t:GetIcon(r)end if r==''or nil then r=nil end x.Frame=k('TextButton',{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,Parent=s,ThemeTag={BackgroundColor3='Tab'}},{k('UICorner',{CornerRadius=UDim.new(0,6)}),k('TextLabel',{AnchorPoint=Vector2.new(0,0.5),Position=r and UDim2.new(0,30,0.5,0)or UDim2.new(0,12,0.5,0),Text=q,RichText=true,TextColor3=Color3.fromRGB(255,255,255),TextTransparency=0,FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Regular,Enum.FontStyle.Normal),TextSize=12,TextXAlignment='Left',TextYAlignment='Center',Size=UDim2.new(1,-12,1,0),BackgroundTransparency=1,ThemeTag={TextColor3='Text'}}),k('ImageLabel',{AnchorPoint=Vector2.new(0,0.5),Size=UDim2.fromOffset(16,16),Position=UDim2.new(0,8,0.5,0),BackgroundTransparency=1,Image=r and r or nil,ThemeTag={ImageColor3='Text'}})})local y=k('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})x.ContainerFrame=k('ScrollingFrame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Parent=u.ContainerHolder,Visible=false,BottomImage='rbxassetid://6889812791',MidImage='rbxassetid://6889812721',TopImage='rbxassetid://6276641225',ScrollBarImageColor3=Color3.fromRGB(255,255,255),ScrollBarImageTransparency=0.95,ScrollBarThickness=3,BorderSizePixel=0,CanvasSize=UDim2.fromScale(0,0),ScrollingDirection=Enum.ScrollingDirection.Y},{y,k('UIPadding',{PaddingRight=UDim.new(0,10),PaddingLeft=UDim.new(0,1),PaddingTop=UDim.new(0,1),PaddingBottom=UDim.new(0,1)})})j.AddSignal(y:GetPropertyChangedSignal'AbsoluteContentSize',function()x.ContainerFrame.CanvasSize=UDim2.new(0,0,0,y.AbsoluteContentSize.Y+2)end)x.Motor,x.SetTransparency=j.SpringMotor(1,x.Frame,'BackgroundTransparency')j.AddSignal(x.Frame.MouseEnter,function()x.SetTransparency(x.Selected and 0.85 or 0.89)end)j.AddSignal(x.Frame.MouseLeave,function()x.SetTransparency(x.Selected and 0.89 or 1)end)j.AddSignal(x.Frame.MouseButton1Down,function()x.SetTransparency(0.92)end)j.AddSignal(x.Frame.MouseButton1Up,function()x.SetTransparency(x.Selected and 0.85 or 0.89)end)j.AddSignal(x.Frame.MouseButton1Click,function()o:SelectTab(w)end)o.Containers[w]=x.ContainerFrame o.Tabs[w]=x x.Container=x.ContainerFrame x.ScrollFrame=x.Container function x.AddSection(z,A)local B,C={Type='Section'},e(n.Section)(A,x.Container)B.Container=C.Container B.ScrollFrame=x.Container setmetatable(B,v)return B end setmetatable(x,v)return x end function o.SelectTab(p,q)local r=o.Window o.SelectedTab=q for s,t in next,o.Tabs do t.SetTransparency(1)t.Selected=false end o.Tabs[q].SetTransparency(0.89)o.Tabs[q].Selected=true r.TabDisplay.Text=o.Tabs[q].Name r.SelectorPosMotor:setGoal(l(o:GetCurrentTabPos(),{frequency=6}))task.spawn(function()r.ContainerPosMotor:setGoal(l(110,{frequency=10}))r.ContainerBackMotor:setGoal(l(1,{frequency=10}))task.wait(0.15)for u,v in next,o.Containers do v.Visible=false end o.Containers[q].Visible=true r.ContainerPosMotor:setGoal(l(94,{frequency=5}))r.ContainerBackMotor:setGoal(l(0,{frequency=8}))end)end return o end,[15]=function()local c,d,e,f,g=b(15)local h,i=game:GetService'TextService',d.Parent.Parent local j,k=e(i.Packages.Flipper),e(i.Creator)local l=k.New return function(m,n)n=n or false local o={}o.Input=l('TextBox',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',TextColor3=Color3.fromRGB(200,200,200),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,BackgroundColor3=Color3.fromRGB(255,255,255),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(10,0),ThemeTag={TextColor3='Text',PlaceholderColor3='SubText'}})o.Container=l('Frame',{BackgroundTransparency=1,ClipsDescendants=true,Position=UDim2.new(0,6,0,0),Size=UDim2.new(1,-12,1,0)},{o.Input})o.Indicator=l('Frame',{Size=UDim2.new(1,-4,0,1),Position=UDim2.new(0,2,1,0),AnchorPoint=Vector2.new(0,1),BackgroundTransparency=n and 0.5 or 0,ThemeTag={BackgroundColor3=n and'InputIndicator'or'DialogInputLine'}})o.Frame=l('Frame',{Size=UDim2.new(0,0,0,30),BackgroundTransparency=n and 0.9 or 0,Parent=m,ThemeTag={BackgroundColor3=n and'Input'or'DialogInput'}},{l('UICorner',{CornerRadius=UDim.new(0,4)}),l('UIStroke',{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Transparency=n and 0.5 or 0.65,ThemeTag={Color=n and'InElementBorder'or'DialogButtonBorder'}}),o.Indicator,o.Container})local p=function()local p,q=2,o.Container.AbsoluteSize.X if not o.Input:IsFocused()or o.Input.TextBounds.X<=q-2*p then o.Input.Position=UDim2.new(0,p,0,0)else local r=o.Input.CursorPosition if r~=-1 then local s=string.sub(o.Input.Text,1,r-1)local t=h:GetTextSize(s,o.Input.TextSize,o.Input.Font,Vector2.new(math.huge,math.huge)).X local u=o.Input.Position.X.Offset+t if u<p then o.Input.Position=UDim2.fromOffset(p-t,0)elseif u>q-p-1 then o.Input.Position=UDim2.fromOffset(q-t-p-1,0)end end end end task.spawn(p)k.AddSignal(o.Input:GetPropertyChangedSignal'Text',p)k.AddSignal(o.Input:GetPropertyChangedSignal'CursorPosition',p)k.AddSignal(o.Input.Focused,function()p()o.Indicator.Size=UDim2.new(1,-2,0,2)o.Indicator.Position=UDim2.new(0,1,1,0)o.Indicator.BackgroundTransparency=0 k.OverrideTag(o.Frame,{BackgroundColor3=n and'InputFocused'or'DialogHolder'})k.OverrideTag(o.Indicator,{BackgroundColor3='Accent'})end)k.AddSignal(o.Input.FocusLost,function()p()o.Indicator.Size=UDim2.new(1,-4,0,1)o.Indicator.Position=UDim2.new(0,2,1,0)o.Indicator.BackgroundTransparency=0.5 k.OverrideTag(o.Frame,{BackgroundColor3=n and'Input'or'DialogInput'})k.OverrideTag(o.Indicator,{BackgroundColor3=n and'InputIndicator'or'DialogInputLine'})end)return o end end,[16]=function()local c,d,e,f,g=b(16)local h,i=d.Parent.Parent,e(d.Parent.Assets)local j,k=e(h.Creator),e(h.Packages.Flipper)local l,m=j.New,j.AddSignal return function(n)local o,p,q={},e(h),function(o,p,q,r)local s={Callback=r or function()end}s.Frame=l('TextButton',{Size=UDim2.new(0,34,1,-8),AnchorPoint=Vector2.new(1,0),BackgroundTransparency=1,Parent=q,Position=p,Text='',ThemeTag={BackgroundColor3='Text'}},{l('UICorner',{CornerRadius=UDim.new(0,7)}),l('ImageLabel',{Image=o,Size=UDim2.fromOffset(16,16),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Name='Icon',ThemeTag={ImageColor3='Text'}})})local t,u=j.SpringMotor(1,s.Frame,'BackgroundTransparency')m(s.Frame.MouseEnter,function()u(0.94)end)m(s.Frame.MouseLeave,function()u(1,true)end)m(s.Frame.MouseButton1Down,function()u(0.96)end)m(s.Frame.MouseButton1Up,function()u(0.94)end)m(s.Frame.MouseButton1Click,s.Callback)s.SetCallback=function(v)s.Callback=v end return s end o.Frame=l('Frame',{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Parent=n.Parent},{l('Frame',{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1},{l('UIListLayout',{Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder}),l('TextLabel',{RichText=true,Text=n.Title,FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Regular,Enum.FontStyle.Normal),TextSize=12,TextXAlignment='Left',TextYAlignment='Center',Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,ThemeTag={TextColor3='Text'}}),l('TextLabel',{RichText=true,Text=n.SubTitle,TextTransparency=0.4,FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Regular,Enum.FontStyle.Normal),TextSize=12,TextXAlignment='Left',TextYAlignment='Center',Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,ThemeTag={TextColor3='Text'}})}),l('Frame',{BackgroundTransparency=0.5,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),ThemeTag={BackgroundColor3='TitleBarLine'}})})o.CloseButton=q(i.Close,UDim2.new(1,-4,0,4),o.Frame,function()p.Window:Dialog{Title='Close',Content='Are you sure you want to unload the interface?',Buttons={{Title='Yes',Callback=function()p:Destroy()end},{Title='No'}}}end)o.MaxButton=q(i.Max,UDim2.new(1,-40,0,4),o.Frame,function()n.Window.Maximize(not n.Window.Maximized)end)o.MinButton=q(i.Min,UDim2.new(1,-80,0,4),o.Frame,function()p.Window:Minimize()end)return o end end,[17]=function()local c,d,e,f,g=b(17)local h,i,j,k=game:GetService'UserInputService',game:GetService'Players'.LocalPlayer:GetMouse(),game:GetService'Workspace'.CurrentCamera,d.Parent.Parent local l,m,n,o,p=e(k.Packages.Flipper),e(k.Creator),e(k.Acrylic),e(d.Parent.Assets),d.Parent local q,r,s=l.Spring.new,l.Instant.new,m.New return function(t)local u,v,w,x,y,z=e(k),{Minimized=false,Maximized=false,Size=t.Size,CurrentPos=0,Position=UDim2.fromOffset(j.ViewportSize.X/2-t.Size.X.Offset/2,j.ViewportSize.Y/2-t.Size.Y.Offset/2)},false local A,B=false local C=false v.AcrylicPaint=n.AcrylicPaint()local D,E=s('Frame',{Size=UDim2.fromOffset(4,0),BackgroundColor3=Color3.fromRGB(76,194,255),Position=UDim2.fromOffset(0,17),AnchorPoint=Vector2.new(0,0.5),ThemeTag={BackgroundColor3='Accent'}},{s('UICorner',{CornerRadius=UDim.new(0,2)})}),s('Frame',{Size=UDim2.fromOffset(20,20),BackgroundTransparency=1,Position=UDim2.new(1,-20,1,-20)})v.TabHolder=s('ScrollingFrame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarImageTransparency=1,ScrollBarThickness=0,BorderSizePixel=0,CanvasSize=UDim2.fromScale(0,0),ScrollingDirection=Enum.ScrollingDirection.Y},{s('UIListLayout',{Padding=UDim.new(0,4)})})local F=s('Frame',{Size=UDim2.new(0,t.TabWidth,1,-66),Position=UDim2.new(0,12,0,54),BackgroundTransparency=1,ClipsDescendants=true},{v.TabHolder,D})v.TabDisplay=s('TextLabel',{RichText=true,Text='Tab',TextTransparency=0,FontFace=Font.new('rbxassetid://12187365364',Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),TextSize=28,TextXAlignment='Left',TextYAlignment='Center',Size=UDim2.new(1,-16,0,28),Position=UDim2.fromOffset(t.TabWidth+26,56),BackgroundTransparency=1,ThemeTag={TextColor3='Text'}})v.ContainerHolder=s('CanvasGroup',{Size=UDim2.new(1,-t.TabWidth-32,1,-102),Position=UDim2.fromOffset(t.TabWidth+26,90),BackgroundTransparency=1})v.Root=s('Frame',{BackgroundTransparency=1,Size=v.Size,Position=v.Position,Parent=t.Parent},{v.AcrylicPaint.Frame,v.TabDisplay,v.ContainerHolder,F,E})v.TitleBar=e(d.Parent.TitleBar){Title=t.Title,SubTitle=t.SubTitle,Parent=v.Root,Window=v}if e(k).UseAcrylic then v.AcrylicPaint.AddParent(v.Root)end local G,H=l.GroupMotor.new{X=v.Size.X.Offset,Y=v.Size.Y.Offset},l.GroupMotor.new{X=v.Position.X.Offset,Y=v.Position.Y.Offset}v.SelectorPosMotor=l.SingleMotor.new(17)v.SelectorSizeMotor=l.SingleMotor.new(0)v.ContainerBackMotor=l.SingleMotor.new(0)v.ContainerPosMotor=l.SingleMotor.new(94)G:onStep(function(I)v.Root.Size=UDim2.new(0,I.X,0,I.Y)end)H:onStep(function(I)v.Root.Position=UDim2.new(0,I.X,0,I.Y)end)local I,J=0,0 v.SelectorPosMotor:onStep(function(K)D.Position=UDim2.new(0,0,0,K+17)local L=tick()local M=L-J if I~=nil then v.SelectorSizeMotor:setGoal(q((math.abs(K-I)/(M*60))+16))I=K end J=L end)v.SelectorSizeMotor:onStep(function(K)D.Size=UDim2.new(0,4,0,K)end)v.ContainerBackMotor:onStep(function(K)v.ContainerHolder.GroupTransparency=K end)v.ContainerPosMotor:onStep(function(K)v.ContainerHolder.Position=UDim2.fromOffset(t.TabWidth+26,K)end)local K,L v.Maximize=function(M,N,O)v.Maximized=M v.TitleBar.MaxButton.Frame.Icon.Image=M and o.Restore or o.Max if M then K=v.Size.X.Offset L=v.Size.Y.Offset end local P,Q=M and j.ViewportSize.X or K,M and j.ViewportSize.Y or L G:setGoal{X=l[O and'Instant'or'Spring'].new(P,{frequency=6}),Y=l[O and'Instant'or'Spring'].new(Q,{frequency=6})}v.Size=UDim2.fromOffset(P,Q)if not N then H:setGoal{X=q(M and 0 or v.Position.X.Offset,{frequency=6}),Y=q(M and 0 or v.Position.Y.Offset,{frequency=6})}end end m.AddSignal(v.TitleBar.Frame.InputBegan,function(M)if M.UserInputType==Enum.UserInputType.MouseButton1 or M.UserInputType==Enum.UserInputType.Touch then w=true y=M.Position z=v.Root.Position if v.Maximized then z=UDim2.fromOffset(i.X-(i.X*((K-100)/v.Root.AbsoluteSize.X)),i.Y-(i.Y*(L/v.Root.AbsoluteSize.Y)))end M.Changed:Connect(function()if M.UserInputState==Enum.UserInputState.End then w=false end end)end end)m.AddSignal(v.TitleBar.Frame.InputChanged,function(M)if M.UserInputType==Enum.UserInputType.MouseMovement or M.UserInputType==Enum.UserInputType.Touch then x=M end end)m.AddSignal(E.InputBegan,function(M)if M.UserInputType==Enum.UserInputType.MouseButton1 or M.UserInputType==Enum.UserInputType.Touch then A=true B=M.Position end end)m.AddSignal(h.InputChanged,function(M)if M==x and w then local N=M.Position-y v.Position=UDim2.fromOffset(z.X.Offset+N.X,z.Y.Offset+N.Y)H:setGoal{X=r(v.Position.X.Offset),Y=r(v.Position.Y.Offset)}if v.Maximized then v.Maximize(false,true,true)end end if(M.UserInputType==Enum.UserInputType.MouseMovement or M.UserInputType==Enum.UserInputType.Touch)and A then local N,O=M.Position-B,v.Size local P=Vector3.new(O.X.Offset,O.Y.Offset,0)+Vector3.new(1,1,0)*N local Q=Vector2.new(math.clamp(P.X,470,2048),math.clamp(P.Y,380,2048))G:setGoal{X=l.Instant.new(Q.X),Y=l.Instant.new(Q.Y)}end end)m.AddSignal(h.InputEnded,function(M)if A==true or M.UserInputType==Enum.UserInputType.Touch then A=false v.Size=UDim2.fromOffset(G:getValue().X,G:getValue().Y)end end)m.AddSignal(v.TabHolder.UIListLayout:GetPropertyChangedSignal'AbsoluteContentSize',function()v.TabHolder.CanvasSize=UDim2.new(0,0,0,v.TabHolder.UIListLayout.AbsoluteContentSize.Y)end)m.AddSignal(h.InputBegan,function(M)if type(u.MinimizeKeybind)=='table'and u.MinimizeKeybind.Type=='Keybind'and not h:GetFocusedTextBox()then if M.KeyCode.Name==u.MinimizeKeybind.Value then v:Minimize()end elseif M.KeyCode==u.MinimizeKey and not h:GetFocusedTextBox()then v:Minimize()end end)function v.Minimize(M)v.Minimized=not v.Minimized v.Root.Visible=not v.Minimized if not C then C=true local N=u.MinimizeKeybind and u.MinimizeKeybind.Value or u.MinimizeKey.Name u:Notify{Title='Interface',Content='Press '..N..' to toggle the inteface.',Duration=6}end end function v.Destroy(M)if e(k).UseAcrylic then v.AcrylicPaint.Model:Destroy()end v.Root:Destroy()end local M=e(p.Dialog):Init(v)function v.Dialog(N,O)local P=M:Create()P.Title.Text=O.Title local Q=s('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',Text=O.Content,TextColor3=Color3.fromRGB(240,240,240),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Size=UDim2.new(1,-40,1,0),Position=UDim2.fromOffset(20,60),BackgroundTransparency=1,Parent=P.Root,ClipsDescendants=false,ThemeTag={TextColor3='Text'}})s('UISizeConstraint',{MinSize=Vector2.new(300,165),MaxSize=Vector2.new(620,math.huge),Parent=P.Root})P.Root.Size=UDim2.fromOffset(Q.TextBounds.X+40,165)if Q.TextBounds.X+40>v.Size.X.Offset-120 then P.Root.Size=UDim2.fromOffset(v.Size.X.Offset-120,165)Q.TextWrapped=true P.Root.Size=UDim2.fromOffset(v.Size.X.Offset-120,Q.TextBounds.Y+150)end for R,S in next,O.Buttons do P:Button(S.Title,S.Callback)end P:Open()end local N=e(p.Tab):Init(v)function v.AddTab(O,P)return N:New(P.Title,P.Icon,v.TabHolder)end function v.SelectTab(O,P)N:SelectTab(1)end m.AddSignal(v.TabHolder:GetPropertyChangedSignal'CanvasPosition',function()I=N:GetCurrentTabPos()+16 J=0 v.SelectorPosMotor:setGoal(r(N:GetCurrentTabPos()))end)return v end end,[18]=function()local c,d,e,f,g=b(18)local h=d.Parent local i,j,k=e(h.Themes),e(h.Packages.Flipper),{Registry={},Signals={},TransparencyMotors={},DefaultProperties={ScreenGui={ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},Frame={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),BorderSizePixel=0},ScrollingFrame={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),ScrollBarImageColor3=Color3.new(0,0,0)},TextLabel={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),Font=Enum.Font.SourceSans,Text='',TextColor3=Color3.new(0,0,0),BackgroundTransparency=1,TextSize=14},TextButton={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),AutoButtonColor=false,Font=Enum.Font.SourceSans,Text='',TextColor3=Color3.new(0,0,0),TextSize=14},TextBox={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),ClearTextOnFocus=false,Font=Enum.Font.SourceSans,Text='',TextColor3=Color3.new(0,0,0),TextSize=14},ImageLabel={BackgroundTransparency=1,BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),BorderSizePixel=0},ImageButton={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),AutoButtonColor=false},CanvasGroup={BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),BorderSizePixel=0}}}local l=function(l,m)if m.ThemeTag then k.AddThemeObject(l,m.ThemeTag)end end function k.AddSignal(m,n)table.insert(k.Signals,m:Connect(n))end function k.Disconnect()for m=#k.Signals,1,-1 do local n=table.remove(k.Signals,m)n:Disconnect()end end function k.GetThemeProperty(m)if i[e(h).Theme][m]then return i[e(h).Theme][m]end return i.Dark[m]end function k.UpdateTheme()for m,n in next,k.Registry do for o,p in next,n.Properties do m[o]=k.GetThemeProperty(p)end end for o,p in next,k.TransparencyMotors do p:setGoal(j.Instant.new(k.GetThemeProperty'ElementTransparency'))end end function k.AddThemeObject(m,n)local o=#k.Registry+1 local p={Object=m,Properties=n,Idx=o}k.Registry[m]=p k.UpdateTheme()return m end function k.OverrideTag(m,n)k.Registry[m].Properties=n k.UpdateTheme()end function k.New(m,n,o)local p=Instance.new(m)for q,r in next,k.DefaultProperties[m]or{}do p[q]=r end for s,t in next,n or{}do if s~='ThemeTag'then p[s]=t end end for u,v in next,o or{}do v.Parent=p end l(p,n)return p end function k.SpringMotor(m,n,o,p,s)p=p or false s=s or false local t=j.SingleMotor.new(m)t:onStep(function(u)n[o]=u end)if s then table.insert(k.TransparencyMotors,t)end local u=function(u,v)v=v or false if not p then if not v then if o=='BackgroundTransparency'and e(h).DialogOpen then return end end end t:setGoal(j.Spring.new(u,{frequency=8}))end return t,u end return k end,[19]=function()local c,d,e,f,g=b(19)local h={}for i,j in next,d:GetChildren()do table.insert(h,e(j))end return h end,[20]=function()local c,d,e,f,g=b(20)local h=d.Parent.Parent local i=e(h.Creator)local j,k,l=i.New,h.Components,{}l.__index=l l.__type='Button'function l.New(m,n)assert(n.Title,'Button - Missing Title')n.Callback=n.Callback or function()end local o=e(k.Element)(n.Title,n.Description,m.Container,true)local p=j('ImageLabel',{Image='rbxassetid://10709791437',Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),BackgroundTransparency=1,Parent=o.Frame,ThemeTag={ImageColor3='Text'}})i.AddSignal(o.Frame.MouseButton1Click,function()m.Library:SafeCallback(n.Callback)end)return o end return l end,[21]=function()local c,d,e,f,g=b(21)local h,i,j,k=game:GetService'UserInputService',game:GetService'TouchInputService',game:GetService'RunService',game:GetService'Players'local l,m=j.RenderStepped,k.LocalPlayer local n,o=m:GetMouse(),d.Parent.Parent local p=e(o.Creator)local s,t,u=p.New,o.Components,{}u.__index=u u.__type='Colorpicker'function u.New(v,w,x)local y=v.Library assert(x.Title,'Colorpicker - Missing Title')assert(x.Default,'AddColorPicker: Missing default value.')local z={Value=x.Default,Transparency=x.Transparency or 0,Type='Colorpicker',Title=type(x.Title)=='string'and x.Title or'Colorpicker',Callback=x.Callback or function(z)end}function z.SetHSVFromRGB(A,B)local C,D,E=Color3.toHSV(B)z.Hue=C z.Sat=D z.Vib=E end z:SetHSVFromRGB(z.Value)local A=e(t.Element)(x.Title,x.Description,v.Container,true)z.SetTitle=A.SetTitle z.SetDesc=A.SetDesc local B=s('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=z.Value,Parent=A.Frame},{s('UICorner',{CornerRadius=UDim.new(0,4)})})local aa,ab=s('ImageLabel',{Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,-10,0.5,0),AnchorPoint=Vector2.new(1,0.5),Parent=A.Frame,Image='http://www.roblox.com/asset/?id=14204231522',ImageTransparency=0.45,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(40,40)},{s('UICorner',{CornerRadius=UDim.new(0,4)}),B}),function()local C=e(t.Dialog):Create()C.Title.Text=z.Title C.Root.Size=UDim2.fromOffset(430,330)local D,E,F,G,H,I=z.Hue,z.Sat,z.Vib,z.Transparency,function()local D=e(t.Textbox)()D.Frame.Parent=C.Root D.Frame.Size=UDim2.new(0,90,0,32)return D end,function(D,E)return s('TextLabel',{FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Medium,Enum.FontStyle.Normal),Text=D,TextColor3=Color3.fromRGB(240,240,240),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,32),Position=E,BackgroundTransparency=1,Parent=C.Root,ThemeTag={TextColor3='Text'}})end local J,K=function()local J=Color3.fromHSV(D,E,F)return{R=math.floor(J.r*255),G=math.floor(J.g*255),B=math.floor(J.b*255)}end,s('ImageLabel',{Size=UDim2.new(0,18,0,18),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image='http://www.roblox.com/asset/?id=4805639000'})local L,M=s('ImageLabel',{Size=UDim2.fromOffset(180,160),Position=UDim2.fromOffset(20,55),Image='rbxassetid://4155801252',BackgroundColor3=z.Value,BackgroundTransparency=0,Parent=C.Root},{s('UICorner',{CornerRadius=UDim.new(0,4)}),K}),s('Frame',{BackgroundColor3=z.Value,Size=UDim2.fromScale(1,1),BackgroundTransparency=z.Transparency},{s('UICorner',{CornerRadius=UDim.new(0,4)})})local N,O=s('ImageLabel',{Image='http://www.roblox.com/asset/?id=14204231522',ImageTransparency=0.45,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(40,40),BackgroundTransparency=1,Position=UDim2.fromOffset(112,220),Size=UDim2.fromOffset(88,24),Parent=C.Root},{s('UICorner',{CornerRadius=UDim.new(0,4)}),s('UIStroke',{Thickness=2,Transparency=0.75}),M}),s('Frame',{BackgroundColor3=z.Value,Size=UDim2.fromScale(1,1),BackgroundTransparency=0},{s('UICorner',{CornerRadius=UDim.new(0,4)})})local P,Q=s('ImageLabel',{Image='http://www.roblox.com/asset/?id=14204231522',ImageTransparency=0.45,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(40,40),BackgroundTransparency=1,Position=UDim2.fromOffset(20,220),Size=UDim2.fromOffset(88,24),Parent=C.Root},{s('UICorner',{CornerRadius=UDim.new(0,4)}),s('UIStroke',{Thickness=2,Transparency=0.75}),O}),{}for R=0,1,0.1 do table.insert(Q,ColorSequenceKeypoint.new(R,Color3.fromHSV(R,1,1)))end local R,S=s('UIGradient',{Color=ColorSequence.new(Q),Rotation=90}),s('Frame',{Size=UDim2.new(1,0,1,-10),Position=UDim2.fromOffset(0,5),BackgroundTransparency=1})local T,U,V=s('ImageLabel',{Size=UDim2.fromOffset(14,14),Image='http://www.roblox.com/asset/?id=12266946128',Parent=S,ThemeTag={ImageColor3='DialogInput'}}),s('Frame',{Size=UDim2.fromOffset(12,190),Position=UDim2.fromOffset(210,55),Parent=C.Root},{s('UICorner',{CornerRadius=UDim.new(1,0)}),R,S}),H()V.Frame.Position=UDim2.fromOffset(x.Transparency and 260 or 240,55)I('Hex',UDim2.fromOffset(x.Transparency and 360 or 340,55))local W=H()W.Frame.Position=UDim2.fromOffset(x.Transparency and 260 or 240,95)I('Red',UDim2.fromOffset(x.Transparency and 360 or 340,95))local X=H()X.Frame.Position=UDim2.fromOffset(x.Transparency and 260 or 240,135)I('Green',UDim2.fromOffset(x.Transparency and 360 or 340,135))local Y=H()Y.Frame.Position=UDim2.fromOffset(x.Transparency and 260 or 240,175)I('Blue',UDim2.fromOffset(x.Transparency and 360 or 340,175))local Z if x.Transparency then Z=H()Z.Frame.Position=UDim2.fromOffset(260,215)I('Alpha',UDim2.fromOffset(360,215))end local _,aa,ab if x.Transparency then local ac=s('Frame',{Size=UDim2.new(1,0,1,-10),Position=UDim2.fromOffset(0,5),BackgroundTransparency=1})aa=s('ImageLabel',{Size=UDim2.fromOffset(14,14),Image='http://www.roblox.com/asset/?id=12266946128',Parent=ac,ThemeTag={ImageColor3='DialogInput'}})ab=s('Frame',{Size=UDim2.fromScale(1,1)},{s('UIGradient',{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)},Rotation=270}),s('UICorner',{CornerRadius=UDim.new(1,0)})})_=s('Frame',{Size=UDim2.fromOffset(12,190),Position=UDim2.fromOffset(230,55),Parent=C.Root,BackgroundTransparency=1},{s('UICorner',{CornerRadius=UDim.new(1,0)}),s('ImageLabel',{Image='http://www.roblox.com/asset/?id=14204231522',ImageTransparency=0.45,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(40,40),BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Parent=C.Root},{s('UICorner',{CornerRadius=UDim.new(1,0)})}),ab,ac})end local ac=function()L.BackgroundColor3=Color3.fromHSV(D,1,1)T.Position=UDim2.new(0,-1,D,-6)K.Position=UDim2.new(E,0,1-F,0)O.BackgroundColor3=Color3.fromHSV(D,E,F)V.Input.Text='#'..Color3.fromHSV(D,E,F):ToHex()W.Input.Text=J().R X.Input.Text=J().G Y.Input.Text=J().B if x.Transparency then ab.BackgroundColor3=Color3.fromHSV(D,E,F)O.BackgroundTransparency=G aa.Position=UDim2.new(0,-1,1-G,-6)Z.Input.Text=e(o):Round((1-G)*100,0)..'%'end end p.AddSignal(V.Input.FocusLost,function(ad)if ad then local ae,af=pcall(Color3.fromHex,V.Input.Text)if ae and typeof(af)=='Color3'then D,E,F=Color3.toHSV(af)end end ac()end)p.AddSignal(W.Input.FocusLost,function(ad)if ad then local ae=J()local af,ag=pcall(Color3.fromRGB,W.Input.Text,ae.G,ae.B)if af and typeof(ag)=='Color3'then if tonumber(W.Input.Text)<=255 then D,E,F=Color3.toHSV(ag)end end end ac()end)p.AddSignal(X.Input.FocusLost,function(ad)if ad then local ae=J()local af,ag=pcall(Color3.fromRGB,ae.R,X.Input.Text,ae.B)if af and typeof(ag)=='Color3'then if tonumber(X.Input.Text)<=255 then D,E,F=Color3.toHSV(ag)end end end ac()end)p.AddSignal(Y.Input.FocusLost,function(ad)if ad then local ae=J()local af,ag=pcall(Color3.fromRGB,ae.R,ae.G,Y.Input.Text)if af and typeof(ag)=='Color3'then if tonumber(Y.Input.Text)<=255 then D,E,F=Color3.toHSV(ag)end end end ac()end)if x.Transparency then p.AddSignal(Z.Input.FocusLost,function(ad)if ad then pcall(function()local ae=tonumber(Z.Input.Text)if ae>=0 and ae<=100 then G=1-ae*0.01 end end)end ac()end)end p.AddSignal(L.InputBegan,function(ad)if ad.UserInputType==Enum.UserInputType.MouseButton1 or ad.UserInputType==Enum.UserInputType.Touch then while h:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)do local ae=L.AbsolutePosition.X local af=ae+L.AbsoluteSize.X local ag,ah=math.clamp(n.X,ae,af),L.AbsolutePosition.Y local ai=ah+L.AbsoluteSize.Y local aj=math.clamp(n.Y,ah,ai)E=(ag-ae)/(af-ae)F=1-((aj-ah)/(ai-ah))ac()l:Wait()end end end)p.AddSignal(U.InputBegan,function(ad)if ad.UserInputType==Enum.UserInputType.MouseButton1 or ad.UserInputType==Enum.UserInputType.Touch then while h:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)do local ae=U.AbsolutePosition.Y local af=ae+U.AbsoluteSize.Y local ag=math.clamp(n.Y,ae,af)D=((ag-ae)/(af-ae))ac()l:Wait()end end end)if x.Transparency then p.AddSignal(_.InputBegan,function(ad)if ad.UserInputType==Enum.UserInputType.MouseButton1 then while h:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)do local ae=_.AbsolutePosition.Y local af=ae+_.AbsoluteSize.Y local ag=math.clamp(n.Y,ae,af)G=1-((ag-ae)/(af-ae))ac()l:Wait()end end end)end ac()C:Button('Done',function()z:SetValue({D,E,F},G)end)C:Button'Cancel'C:Open()end function z.Display(ac)z.Value=Color3.fromHSV(z.Hue,z.Sat,z.Vib)B.BackgroundColor3=z.Value B.BackgroundTransparency=z.Transparency u.Library:SafeCallback(z.Callback,z.Value)u.Library:SafeCallback(z.Changed,z.Value)end function z.SetValue(ac,ad,ae)local af=Color3.fromHSV(ad[1],ad[2],ad[3])z.Transparency=ae or 0 z:SetHSVFromRGB(af)z:Display()end function z.SetValueRGB(ac,ad,ae)z.Transparency=ae or 0 z:SetHSVFromRGB(ad)z:Display()end function z.OnChanged(ac,ad)z.Changed=ad ad(z.Value)end function z.Destroy(ac)A:Destroy()y.Options[w]=nil end p.AddSignal(A.Frame.MouseButton1Click,function()ab()end)z:Display()y.Options[w]=z return z end return u end,[22]=function()local aa,ab,ac,ad,ae=b(22)local af,ag,ah,ai,aj=game:GetService'TweenService',game:GetService'UserInputService',game:GetService'Players'.LocalPlayer:GetMouse(),game:GetService'Workspace'.CurrentCamera,ab.Parent.Parent local c,d=ac(aj.Creator),ac(aj.Packages.Flipper)local e,f,g=c.New,aj.Components,{}g.__index=g g.__type='Dropdown'function g.New(h,i,j)local k,l,m=h.Library,{Values=j.Values,Value=j.Default,Multi=j.Multi,Buttons={},Opened=false,Type='Dropdown',Callback=j.Callback or function()end},ac(f.Element)(j.Title,j.Description,h.Container,false)m.DescLabel.Size=UDim2.new(1,-170,0,14)l.SetTitle=m.SetTitle l.SetDesc=m.SetDesc local n,o=e('TextLabel',{FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text='Value',TextColor3=Color3.fromRGB(240,240,240),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-30,0,14),Position=UDim2.new(0,8,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,TextTruncate=Enum.TextTruncate.AtEnd,ThemeTag={TextColor3='Text'}}),e('ImageLabel',{Image='rbxassetid://10709790948',Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),BackgroundTransparency=1,ThemeTag={ImageColor3='SubText'}})local p,s=e('TextButton',{Size=UDim2.fromOffset(160,30),Position=UDim2.new(1,-10,0.5,0),AnchorPoint=Vector2.new(1,0.5),BackgroundTransparency=0.9,Parent=m.Frame,ThemeTag={BackgroundColor3='DropdownFrame'}},{e('UICorner',{CornerRadius=UDim.new(0,5)}),e('UIStroke',{Transparency=0.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,ThemeTag={Color='InElementBorder'}}),o,n}),e('UIListLayout',{Padding=UDim.new(0,3)})local t=e('ScrollingFrame',{Size=UDim2.new(1,-5,1,-10),Position=UDim2.fromOffset(5,5),BackgroundTransparency=1,BottomImage='rbxassetid://6889812791',MidImage='rbxassetid://6889812721',TopImage='rbxassetid://6276641225',ScrollBarImageColor3=Color3.fromRGB(255,255,255),ScrollBarImageTransparency=0.95,ScrollBarThickness=4,BorderSizePixel=0,CanvasSize=UDim2.fromScale(0,0)},{s})local u=e('Frame',{Size=UDim2.fromScale(1,0.6),ThemeTag={BackgroundColor3='DropdownHolder'}},{t,e('UICorner',{CornerRadius=UDim.new(0,7)}),e('UIStroke',{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,ThemeTag={Color='DropdownBorder'}}),e('ImageLabel',{BackgroundTransparency=1,Image='http://www.roblox.com/asset/?id=5554236805',ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(23,23,277,277),Size=UDim2.fromScale(1,1)+UDim2.fromOffset(30,30),Position=UDim2.fromOffset(-15,-15),ImageColor3=Color3.fromRGB(0,0,0),ImageTransparency=0.1})})local v=e('Frame',{BackgroundTransparency=1,Size=UDim2.fromOffset(170,300),Parent=h.Library.GUI,Visible=false},{u,e('UISizeConstraint',{MinSize=Vector2.new(170,0)})})table.insert(k.OpenFrames,v)local w,x=function()local w=0 if ai.ViewportSize.Y-p.AbsolutePosition.Y<v.AbsoluteSize.Y-5 then w=v.AbsoluteSize.Y-5-(ai.ViewportSize.Y-p.AbsolutePosition.Y)+40 end v.Position=UDim2.fromOffset(p.AbsolutePosition.X-1,p.AbsolutePosition.Y-5-w)end,0 local y,z=function()if#l.Values>10 then v.Size=UDim2.fromOffset(x,392)else v.Size=UDim2.fromOffset(x,s.AbsoluteContentSize.Y+10)end end,function()t.CanvasSize=UDim2.fromOffset(0,s.AbsoluteContentSize.Y)end w()y()c.AddSignal(p:GetPropertyChangedSignal'AbsolutePosition',w)c.AddSignal(p.MouseButton1Click,function()l:Open()end)c.AddSignal(ag.InputBegan,function(A)if A.UserInputType==Enum.UserInputType.MouseButton1 or A.UserInputType==Enum.UserInputType.Touch then local B,C=u.AbsolutePosition,u.AbsoluteSize if ah.X<B.X or ah.X>B.X+C.X or ah.Y<(B.Y-20-1)or ah.Y>B.Y+C.Y then l:Close()end end end)local A=h.ScrollFrame function l.Open(B)l.Opened=true A.ScrollingEnabled=false v.Visible=true af:Create(u,TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,1)}):Play()end function l.Close(B)l.Opened=false A.ScrollingEnabled=true u.Size=UDim2.fromScale(1,0.6)v.Visible=false end function l.Display(B)local C,D=l.Values,''if j.Multi then for E,F in next,C do if l.Value[F]then D=D..F..', 'end end D=D:sub(1,#D-2)else D=l.Value or''end n.Text=(D==''and'--'or D)end function l.GetActiveValues(B)if j.Multi then local C={}for D,E in next,l.Value do table.insert(C,D)end return C else return l.Value and 1 or 0 end end function l.BuildDropdownList(B)local C,D=l.Values,{}for E,F in next,t:GetChildren()do if not F:IsA'UIListLayout'then F:Destroy()end end local G=0 for H,I in next,C do local J={}G=G+1 local K,L=e('Frame',{Size=UDim2.fromOffset(4,14),BackgroundColor3=Color3.fromRGB(76,194,255),Position=UDim2.fromOffset(-1,16),AnchorPoint=Vector2.new(0,0.5),ThemeTag={BackgroundColor3='Accent'}},{e('UICorner',{CornerRadius=UDim.new(0,2)})}),e('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',Text=I,TextColor3=Color3.fromRGB(200,200,200),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=Color3.fromRGB(255,255,255),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(10,0),Name='ButtonLabel',ThemeTag={TextColor3='Text'}})local M,N=(e('TextButton',{Size=UDim2.new(1,-5,0,32),BackgroundTransparency=1,ZIndex=23,Text='',Parent=t,ThemeTag={BackgroundColor3='DropdownOption'}},{K,L,e('UICorner',{CornerRadius=UDim.new(0,6)})}))if j.Multi then N=l.Value[I]else N=l.Value==I end local O,P=c.SpringMotor(1,M,'BackgroundTransparency')local Q,R=c.SpringMotor(1,K,'BackgroundTransparency')local S=d.SingleMotor.new(6)S:onStep(function(T)K.Size=UDim2.new(0,4,0,T)end)c.AddSignal(M.MouseEnter,function()P(N and 0.85 or 0.89)end)c.AddSignal(M.MouseLeave,function()P(N and 0.89 or 1)end)c.AddSignal(M.MouseButton1Down,function()P(0.92)end)c.AddSignal(M.MouseButton1Up,function()P(N and 0.85 or 0.89)end)function J.UpdateButton(T)if j.Multi then N=l.Value[I]if N then P(0.89)end else N=l.Value==I P(N and 0.89 or 1)end S:setGoal(d.Spring.new(N and 14 or 6,{frequency=6}))R(N and 0 or 1)end L.InputBegan:Connect(function(T)if T.UserInputType==Enum.UserInputType.MouseButton1 or T.UserInputType==Enum.UserInputType.Touch then local U=not N if l:GetActiveValues()==1 and not U and not j.AllowNull then else if j.Multi then N=U l.Value[I]=N and true or nil else N=U l.Value=N and I or nil for V,W in next,D do W:UpdateButton()end end J:UpdateButton()l:Display()k:SafeCallback(l.Callback,l.Value)k:SafeCallback(l.Changed,l.Value)end end end)J:UpdateButton()l:Display()D[M]=J end x=0 for J,K in next,D do if J.ButtonLabel then if J.ButtonLabel.TextBounds.X>x then x=J.ButtonLabel.TextBounds.X end end end x=x+30 z()y()end function l.SetValues(B,C)if C then l.Values=C end l:BuildDropdownList()end function l.OnChanged(B,C)l.Changed=C C(l.Value)end function l.SetValue(B,C)if l.Multi then local D={}for E,F in next,C do if table.find(l.Values,E)then D[E]=true end end l.Value=D else if not C then l.Value=nil elseif table.find(l.Values,C)then l.Value=C end end l:BuildDropdownList()k:SafeCallback(l.Callback,l.Value)k:SafeCallback(l.Changed,l.Value)end function l.Destroy(B)m:Destroy()k.Options[i]=nil end l:BuildDropdownList()l:Display()local B={}if type(j.Default)=='string'then local C=table.find(l.Values,j.Default)if C then table.insert(B,C)end elseif type(j.Default)=='table'then for C,D in next,j.Default do local E=table.find(l.Values,D)if E then table.insert(B,E)end end elseif type(j.Default)=='number'and l.Values[j.Default]~=nil then table.insert(B,j.Default)end if next(B)then for C=1,#B do local D=B[C]if j.Multi then l.Value[l.Values[D]]=true else l.Value=l.Values[D]end if not j.Multi then break end end l:BuildDropdownList()l:Display()end k.Options[i]=l return l end return g end,[23]=function()local aa,ab,ac,ad,ae=b(23)local af=ab.Parent.Parent local ag=ac(af.Creator)local ah,ai,aj,c=ag.New,ag.AddSignal,af.Components,{}c.__index=c c.__type='Input'function c.New(d,e,f)local g=d.Library assert(f.Title,'Input - Missing Title')f.Callback=f.Callback or function()end local h,i={Value=f.Default or'',Numeric=f.Numeric or false,Finished=f.Finished or false,Callback=f.Callback or function(h)end,Type='Input'},ac(aj.Element)(f.Title,f.Description,d.Container,false)h.SetTitle=i.SetTitle h.SetDesc=i.SetDesc local j=ac(aj.Textbox)(i.Frame,true)j.Frame.Position=UDim2.new(1,-10,0.5,0)j.Frame.AnchorPoint=Vector2.new(1,0.5)j.Frame.Size=UDim2.fromOffset(160,30)j.Input.Text=f.Default or''j.Input.PlaceholderText=f.Placeholder or''local k=j.Input function h.SetValue(l,m)if f.MaxLength and#m>f.MaxLength then m=m:sub(1,f.MaxLength)end if h.Numeric then if(not tonumber(m))and m:len()>0 then m=h.Value end end h.Value=m k.Text=m g:SafeCallback(h.Callback,h.Value)g:SafeCallback(h.Changed,h.Value)end if h.Finished then ai(k.FocusLost,function(l)if not l then return end h:SetValue(k.Text)end)else ai(k:GetPropertyChangedSignal'Text',function()h:SetValue(k.Text)end)end function h.OnChanged(l,m)h.Changed=m m(h.Value)end function h.Destroy(l)i:Destroy()g.Options[e]=nil end g.Options[e]=h return h end return c end,[24]=function()local aa,ab,ac,ad,ae=b(24)local af,ag=game:GetService'UserInputService',ab.Parent.Parent local ah=ac(ag.Creator)local ai,aj,c=ah.New,ag.Components,{}c.__index=c c.__type='Keybind'function c.New(d,e,f)local g=d.Library assert(f.Title,'KeyBind - Missing Title')assert(f.Default,'KeyBind - Missing default value.')local h,i,j={Value=f.Default,Toggled=false,Mode=f.Mode or'Toggle',Type='Keybind',Callback=f.Callback or function(h)end,ChangedCallback=f.ChangedCallback or function(h)end},false,ac(aj.Element)(f.Title,f.Description,d.Container,true)h.SetTitle=j.SetTitle h.SetDesc=j.SetDesc local k=ai('TextLabel',{FontFace=Font.new('rbxasset://fonts/families/GothamSSm.json',Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text=f.Default,TextColor3=Color3.fromRGB(240,240,240),TextSize=13,TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.new(0,0,0,14),Position=UDim2.new(0,0,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(255,255,255),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,ThemeTag={TextColor3='Text'}})local l=ai('TextButton',{Size=UDim2.fromOffset(0,30),Position=UDim2.new(1,-10,0.5,0),AnchorPoint=Vector2.new(1,0.5),BackgroundTransparency=0.9,Parent=j.Frame,AutomaticSize=Enum.AutomaticSize.X,ThemeTag={BackgroundColor3='Keybind'}},{ai('UICorner',{CornerRadius=UDim.new(0,5)}),ai('UIPadding',{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}),ai('UIStroke',{Transparency=0.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,ThemeTag={Color='InElementBorder'}}),k})function h.GetState(m)if af:GetFocusedTextBox()and h.Mode~='Always'then return false end if h.Mode=='Always'then return true elseif h.Mode=='Hold'then if h.Value=='None'then return false end local n=h.Value if n=='MouseLeft'or n=='MouseRight'then return n=='MouseLeft'and af:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)or n=='MouseRight'and af:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)else return af:IsKeyDown(Enum.KeyCode[h.Value])end else return h.Toggled end end function h.SetValue(m,n,o)n=n or h.Key o=o or h.Mode k.Text=n h.Value=n h.Mode=o end function h.OnClick(m,n)h.Clicked=n end function h.OnChanged(m,n)h.Changed=n n(h.Value)end function h.DoClick(m)g:SafeCallback(h.Callback,h.Toggled)g:SafeCallback(h.Clicked,h.Toggled)end function h.Destroy(m)j:Destroy()g.Options[e]=nil end ah.AddSignal(l.InputBegan,function(m)if m.UserInputType==Enum.UserInputType.MouseButton1 or m.UserInputType==Enum.UserInputType.Touch then i=true k.Text='...'wait(0.2)local n n=af.InputBegan:Connect(function(o)local p if o.UserInputType==Enum.UserInputType.Keyboard then p=o.KeyCode.Name elseif o.UserInputType==Enum.UserInputType.MouseButton1 then p='MouseLeft'elseif o.UserInputType==Enum.UserInputType.MouseButton2 then p='MouseRight'end local s s=af.InputEnded:Connect(function(t)if t.KeyCode.Name==p or p=='MouseLeft'and t.UserInputType==Enum.UserInputType.MouseButton1 or p=='MouseRight'and t.UserInputType==Enum.UserInputType.MouseButton2 then i=false k.Text=p h.Value=p g:SafeCallback(h.ChangedCallback,t.KeyCode or t.UserInputType)g:SafeCallback(h.Changed,t.KeyCode or t.UserInputType)n:Disconnect()s:Disconnect()end end)end)end end)ah.AddSignal(af.InputBegan,function(m)if not i and not af:GetFocusedTextBox()then if h.Mode=='Toggle'then local n=h.Value if n=='MouseLeft'or n=='MouseRight'then if n=='MouseLeft'and m.UserInputType==Enum.UserInputType.MouseButton1 or n=='MouseRight'and m.UserInputType==Enum.UserInputType.MouseButton2 then h.Toggled=not h.Toggled h:DoClick()end elseif m.UserInputType==Enum.UserInputType.Keyboard then if m.KeyCode.Name==n then h.Toggled=not h.Toggled h:DoClick()end end end end end)g.Options[e]=h return h end return c end,[25]=function()local aa,ab,ac,ad,ae=b(25)local af=ab.Parent.Parent local ag,ah,ai,aj=af.Components,ac(af.Packages.Flipper),ac(af.Creator),{}aj.__index=aj aj.__type='Paragraph'function aj.New(c,d)assert(d.Title,'Paragraph - Missing Title')d.Content=d.Content or''local e=ac(ag.Element)(d.Title,d.Content,aj.Container,false)e.Frame.BackgroundTransparency=0.92 e.Border.Transparency=0.6 return e end return aj end,[26]=function()local aa,ab,ac,ad,ae=b(26)local af,ag=game:GetService'UserInputService',ab.Parent.Parent local ah=ac(ag.Creator)local ai,aj,c=ah.New,ag.Components,{}c.__index=c c.__type='Slider'function c.New(d,e,f)local g=d.Library assert(f.Title,'Slider - Missing Title.')assert(f.Default,'Slider - Missing default value.')assert(f.Min,'Slider - Missing minimum value.')assert(f.Max,'Slider - Missing maximum value.')assert(f.Rounding,'Slider - Missing rounding value.')local h,i,j={Value=nil,Min=f.Min,Max=f.Max,Rounding=f.Rounding,Callback=f.Callback or function(h)end,Type='Slider'},false,ac(aj.Element)(f.Title,f.Description,d.Container,false)j.DescLabel.Size=UDim2.new(1,-170,0,14)h.SetTitle=j.SetTitle h.SetDesc=j.SetDesc local k=ai('ImageLabel',{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,-7,0.5,0),Size=UDim2.fromOffset(14,14),Image='http://www.roblox.com/asset/?id=12266946128',ThemeTag={ImageColor3='Accent'}})local l,m,n=ai('Frame',{BackgroundTransparency=1,Position=UDim2.fromOffset(7,0),Size=UDim2.new(1,-14,1,0)},{k}),ai('Frame',{Size=UDim2.new(0,0,1,0),ThemeTag={BackgroundColor3='Accent'}},{ai('UICorner',{CornerRadius=UDim.new(1,0)})}),ai('TextLabel',{FontFace=Font.new'rbxasset://fonts/families/GothamSSm.json',Text='Value',TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Right,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Size=UDim2.new(0,100,0,14),Position=UDim2.new(0,-4,0.5,0),AnchorPoint=Vector2.new(1,0.5),ThemeTag={TextColor3='SubText'}})local o=ai('Frame',{Size=UDim2.new(1,0,0,4),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),BackgroundTransparency=0.4,Parent=j.Frame,ThemeTag={BackgroundColor3='SliderRail'}},{ai('UICorner',{CornerRadius=UDim.new(1,0)}),ai('UISizeConstraint',{MaxSize=Vector2.new(150,math.huge)}),n,m,l})ah.AddSignal(k.InputBegan,function(p)if p.UserInputType==Enum.UserInputType.MouseButton1 or p.UserInputType==Enum.UserInputType.Touch then i=true end end)ah.AddSignal(k.InputEnded,function(p)if p.UserInputType==Enum.UserInputType.MouseButton1 or p.UserInputType==Enum.UserInputType.Touch then i=false end end)ah.AddSignal(af.InputChanged,function(p)if i and(p.UserInputType==Enum.UserInputType.MouseMovement or p.UserInputType==Enum.UserInputType.Touch)then local s=math.clamp((p.Position.X-l.AbsolutePosition.X)/l.AbsoluteSize.X,0,1)h:SetValue(h.Min+((h.Max-h.Min)*s))end end)function h.OnChanged(p,s)h.Changed=s s(h.Value)end function h.SetValue(p,s)p.Value=g:Round(math.clamp(s,h.Min,h.Max),h.Rounding)k.Position=UDim2.new((p.Value-h.Min)/(h.Max-h.Min),-7,0.5,0)m.Size=UDim2.fromScale((p.Value-h.Min)/(h.Max-h.Min),1)n.Text=tostring(p.Value)g:SafeCallback(h.Callback,p.Value)g:SafeCallback(h.Changed,p.Value)end function h.Destroy(p)j:Destroy()g.Options[e]=nil end h:SetValue(f.Default)g.Options[e]=h return h end return c end,[27]=function()local aa,ab,ac,ad,ae=b(27)local af,ag=game:GetService'TweenService',ab.Parent.Parent local ah=ac(ag.Creator)local ai,aj,c=ah.New,ag.Components,{}c.__index=c c.__type='Toggle'function c.New(d,e,f)local g=d.Library assert(f.Title,'Toggle - Missing Title')local h,i={Value=f.Default or false,Callback=f.Callback or function(h)end,Type='Toggle'},ac(aj.Element)(f.Title,f.Description,d.Container,true)i.DescLabel.Size=UDim2.new(1,-54,0,14)h.SetTitle=i.SetTitle h.SetDesc=i.SetDesc local j,k=ai('ImageLabel',{AnchorPoint=Vector2.new(0,0.5),Size=UDim2.fromOffset(14,14),Position=UDim2.new(0,2,0.5,0),Image='http://www.roblox.com/asset/?id=12266946128',ImageTransparency=0.5,ThemeTag={ImageColor3='ToggleSlider'}}),ai('UIStroke',{Transparency=0.5,ThemeTag={Color='ToggleSlider'}})local l=ai('Frame',{Size=UDim2.fromOffset(36,18),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Parent=i.Frame,BackgroundTransparency=1,ThemeTag={BackgroundColor3='Accent'}},{ai('UICorner',{CornerRadius=UDim.new(0,9)}),k,j})function h.OnChanged(m,n)h.Changed=n n(h.Value)end function h.SetValue(m,n)n=not not n h.Value=n ah.OverrideTag(k,{Color=h.Value and'Accent'or'ToggleSlider'})ah.OverrideTag(j,{ImageColor3=h.Value and'ToggleToggled'or'ToggleSlider'})af:Create(j,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(0,h.Value and 19 or 2,0.5,0)}):Play()af:Create(l,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=h.Value and 0 or 1}):Play()j.ImageTransparency=h.Value and 0 or 0.5 g:SafeCallback(h.Callback,h.Value)g:SafeCallback(h.Changed,h.Value)end function h.Destroy(m)i:Destroy()g.Options[e]=nil end ah.AddSignal(i.Frame.MouseButton1Click,function()h:SetValue(not h.Value)end)h:SetValue(h.Value)g.Options[e]=h return h end return c end,[28]=function()local aa,ab,ac,ad,ae=b(28)return{assets={['lucide-accessibility']='rbxassetid://10709751939',['lucide-activity']='rbxassetid://10709752035',['lucide-air-vent']='rbxassetid://10709752131',['lucide-airplay']='rbxassetid://10709752254',['lucide-alarm-check']='rbxassetid://10709752405',['lucide-alarm-clock']='rbxassetid://10709752630',['lucide-alarm-clock-off']='rbxassetid://10709752508',['lucide-alarm-minus']='rbxassetid://10709752732',['lucide-alarm-plus']='rbxassetid://10709752825',['lucide-album']='rbxassetid://10709752906',['lucide-alert-circle']='rbxassetid://10709752996',['lucide-alert-octagon']='rbxassetid://10709753064',['lucide-alert-triangle']='rbxassetid://10709753149',['lucide-align-center']='rbxassetid://10709753570',['lucide-align-center-horizontal']='rbxassetid://10709753272',['lucide-align-center-vertical']='rbxassetid://10709753421',['lucide-align-end-horizontal']='rbxassetid://10709753692',['lucide-align-end-vertical']='rbxassetid://10709753808',['lucide-align-horizontal-distribute-center']='rbxassetid://10747779791',['lucide-align-horizontal-distribute-end']='rbxassetid://10747784534',['lucide-align-horizontal-distribute-start']='rbxassetid://10709754118',['lucide-align-horizontal-justify-center']='rbxassetid://10709754204',['lucide-align-horizontal-justify-end']='rbxassetid://10709754317',['lucide-align-horizontal-justify-start']='rbxassetid://10709754436',['lucide-align-horizontal-space-around']='rbxassetid://10709754590',['lucide-align-horizontal-space-between']='rbxassetid://10709754749',['lucide-align-justify']='rbxassetid://10709759610',['lucide-align-left']='rbxassetid://10709759764',['lucide-align-right']='rbxassetid://10709759895',['lucide-align-start-horizontal']='rbxassetid://10709760051',['lucide-align-start-vertical']='rbxassetid://10709760244',['lucide-align-vertical-distribute-center']='rbxassetid://10709760351',['lucide-align-vertical-distribute-end']='rbxassetid://10709760434',['lucide-align-vertical-distribute-start']='rbxassetid://10709760612',['lucide-align-vertical-justify-center']='rbxassetid://10709760814',['lucide-align-vertical-justify-end']='rbxassetid://10709761003',['lucide-align-vertical-justify-start']='rbxassetid://10709761176',['lucide-align-vertical-space-around']='rbxassetid://10709761324',['lucide-align-vertical-space-between']='rbxassetid://10709761434',['lucide-anchor']='rbxassetid://10709761530',['lucide-angry']='rbxassetid://10709761629',['lucide-annoyed']='rbxassetid://10709761722',['lucide-aperture']='rbxassetid://10709761813',['lucide-apple']='rbxassetid://10709761889',['lucide-archive']='rbxassetid://10709762233',['lucide-archive-restore']='rbxassetid://10709762058',['lucide-armchair']='rbxassetid://10709762327',['lucide-arrow-big-down']='rbxassetid://10747796644',['lucide-arrow-big-left']='rbxassetid://10709762574',['lucide-arrow-big-right']='rbxassetid://10709762727',['lucide-arrow-big-up']='rbxassetid://10709762879',['lucide-arrow-down']='rbxassetid://10709767827',['lucide-arrow-down-circle']='rbxassetid://10709763034',['lucide-arrow-down-left']='rbxassetid://10709767656',['lucide-arrow-down-right']='rbxassetid://10709767750',['lucide-arrow-left']='rbxassetid://10709768114',['lucide-arrow-left-circle']='rbxassetid://10709767936',['lucide-arrow-left-right']='rbxassetid://10709768019',['lucide-arrow-right']='rbxassetid://10709768347',['lucide-arrow-right-circle']='rbxassetid://10709768226',['lucide-arrow-up']='rbxassetid://10709768939',['lucide-arrow-up-circle']='rbxassetid://10709768432',['lucide-arrow-up-down']='rbxassetid://10709768538',['lucide-arrow-up-left']='rbxassetid://10709768661',['lucide-arrow-up-right']='rbxassetid://10709768787',['lucide-asterisk']='rbxassetid://10709769095',['lucide-at-sign']='rbxassetid://10709769286',['lucide-award']='rbxassetid://10709769406',['lucide-axe']='rbxassetid://10709769508',['lucide-axis-3d']='rbxassetid://10709769598',['lucide-baby']='rbxassetid://10709769732',['lucide-backpack']='rbxassetid://10709769841',['lucide-baggage-claim']='rbxassetid://10709769935',['lucide-banana']='rbxassetid://10709770005',['lucide-banknote']='rbxassetid://10709770178',['lucide-bar-chart']='rbxassetid://10709773755',['lucide-bar-chart-2']='rbxassetid://10709770317',['lucide-bar-chart-3']='rbxassetid://10709770431',['lucide-bar-chart-4']='rbxassetid://10709770560',['lucide-bar-chart-horizontal']='rbxassetid://10709773669',['lucide-barcode']='rbxassetid://10747360675',['lucide-baseline']='rbxassetid://10709773863',['lucide-bath']='rbxassetid://10709773963',['lucide-battery']='rbxassetid://10709774640',['lucide-battery-charging']='rbxassetid://10709774068',['lucide-battery-full']='rbxassetid://10709774206',['lucide-battery-low']='rbxassetid://10709774370',['lucide-battery-medium']='rbxassetid://10709774513',['lucide-beaker']='rbxassetid://10709774756',['lucide-bed']='rbxassetid://10709775036',['lucide-bed-double']='rbxassetid://10709774864',['lucide-bed-single']='rbxassetid://10709774968',['lucide-beer']='rbxassetid://10709775167',['lucide-bell']='rbxassetid://10709775704',['lucide-bell-minus']='rbxassetid://10709775241',['lucide-bell-off']='rbxassetid://10709775320',['lucide-bell-plus']='rbxassetid://10709775448',['lucide-bell-ring']='rbxassetid://10709775560',['lucide-bike']='rbxassetid://10709775894',['lucide-binary']='rbxassetid://10709776050',['lucide-bitcoin']='rbxassetid://10709776126',['lucide-bluetooth']='rbxassetid://10709776655',['lucide-bluetooth-connected']='rbxassetid://10709776240',['lucide-bluetooth-off']='rbxassetid://10709776344',['lucide-bluetooth-searching']='rbxassetid://10709776501',['lucide-bold']='rbxassetid://10747813908',['lucide-bomb']='rbxassetid://10709781460',['lucide-bone']='rbxassetid://10709781605',['lucide-book']='rbxassetid://10709781824',['lucide-book-open']='rbxassetid://10709781717',['lucide-bookmark']='rbxassetid://10709782154',['lucide-bookmark-minus']='rbxassetid://10709781919',['lucide-bookmark-plus']='rbxassetid://10709782044',['lucide-bot']='rbxassetid://10709782230',['lucide-box']='rbxassetid://10709782497',['lucide-box-select']='rbxassetid://10709782342',['lucide-boxes']='rbxassetid://10709782582',['lucide-briefcase']='rbxassetid://10709782662',['lucide-brush']='rbxassetid://10709782758',['lucide-bug']='rbxassetid://10709782845',['lucide-building']='rbxassetid://10709783051',['lucide-building-2']='rbxassetid://10709782939',['lucide-bus']='rbxassetid://10709783137',['lucide-cake']='rbxassetid://10709783217',['lucide-calculator']='rbxassetid://10709783311',['lucide-calendar']='rbxassetid://10709789505',['lucide-calendar-check']='rbxassetid://10709783474',['lucide-calendar-check-2']='rbxassetid://10709783392',['lucide-calendar-clock']='rbxassetid://10709783577',['lucide-calendar-days']='rbxassetid://10709783673',['lucide-calendar-heart']='rbxassetid://10709783835',['lucide-calendar-minus']='rbxassetid://10709783959',['lucide-calendar-off']='rbxassetid://10709788784',['lucide-calendar-plus']='rbxassetid://10709788937',['lucide-calendar-range']='rbxassetid://10709789053',['lucide-calendar-search']='rbxassetid://10709789200',['lucide-calendar-x']='rbxassetid://10709789407',['lucide-calendar-x-2']='rbxassetid://10709789329',['lucide-camera']='rbxassetid://10709789686',['lucide-camera-off']='rbxassetid://10747822677',['lucide-car']='rbxassetid://10709789810',['lucide-carrot']='rbxassetid://10709789960',['lucide-cast']='rbxassetid://10709790097',['lucide-charge']='rbxassetid://10709790202',['lucide-check']='rbxassetid://10709790644',['lucide-check-circle']='rbxassetid://10709790387',['lucide-check-circle-2']='rbxassetid://10709790298',['lucide-check-square']='rbxassetid://10709790537',['lucide-chef-hat']='rbxassetid://10709790757',['lucide-cherry']='rbxassetid://10709790875',['lucide-chevron-down']='rbxassetid://10709790948',['lucide-chevron-first']='rbxassetid://10709791015',['lucide-chevron-last']='rbxassetid://10709791130',['lucide-chevron-left']='rbxassetid://10709791281',['lucide-chevron-right']='rbxassetid://10709791437',['lucide-chevron-up']='rbxassetid://10709791523',['lucide-chevrons-down']='rbxassetid://10709796864',['lucide-chevrons-down-up']='rbxassetid://10709791632',['lucide-chevrons-left']='rbxassetid://10709797151',['lucide-chevrons-left-right']='rbxassetid://10709797006',['lucide-chevrons-right']='rbxassetid://10709797382',['lucide-chevrons-right-left']='rbxassetid://10709797274',['lucide-chevrons-up']='rbxassetid://10709797622',['lucide-chevrons-up-down']='rbxassetid://10709797508',['lucide-chrome']='rbxassetid://10709797725',['lucide-circle']='rbxassetid://10709798174',['lucide-circle-dot']='rbxassetid://10709797837',['lucide-circle-ellipsis']='rbxassetid://10709797985',['lucide-circle-slashed']='rbxassetid://10709798100',['lucide-citrus']='rbxassetid://10709798276',['lucide-clapperboard']='rbxassetid://10709798350',['lucide-clipboard']='rbxassetid://10709799288',['lucide-clipboard-check']='rbxassetid://10709798443',['lucide-clipboard-copy']='rbxassetid://10709798574',['lucide-clipboard-edit']='rbxassetid://10709798682',['lucide-clipboard-list']='rbxassetid://10709798792',['lucide-clipboard-signature']='rbxassetid://10709798890',['lucide-clipboard-type']='rbxassetid://10709798999',['lucide-clipboard-x']='rbxassetid://10709799124',['lucide-clock']='rbxassetid://10709805144',['lucide-clock-1']='rbxassetid://10709799535',['lucide-clock-10']='rbxassetid://10709799718',['lucide-clock-11']='rbxassetid://10709799818',['lucide-clock-12']='rbxassetid://10709799962',['lucide-clock-2']='rbxassetid://10709803876',['lucide-clock-3']='rbxassetid://10709803989',['lucide-clock-4']='rbxassetid://10709804164',['lucide-clock-5']='rbxassetid://10709804291',['lucide-clock-6']='rbxassetid://10709804435',['lucide-clock-7']='rbxassetid://10709804599',['lucide-clock-8']='rbxassetid://10709804784',['lucide-clock-9']='rbxassetid://10709804996',['lucide-cloud']='rbxassetid://10709806740',['lucide-cloud-cog']='rbxassetid://10709805262',['lucide-cloud-drizzle']='rbxassetid://10709805371',['lucide-cloud-fog']='rbxassetid://10709805477',['lucide-cloud-hail']='rbxassetid://10709805596',['lucide-cloud-lightning']='rbxassetid://10709805727',['lucide-cloud-moon']='rbxassetid://10709805942',['lucide-cloud-moon-rain']='rbxassetid://10709805838',['lucide-cloud-off']='rbxassetid://10709806060',['lucide-cloud-rain']='rbxassetid://10709806277',['lucide-cloud-rain-wind']='rbxassetid://10709806166',['lucide-cloud-snow']='rbxassetid://10709806374',['lucide-cloud-sun']='rbxassetid://10709806631',['lucide-cloud-sun-rain']='rbxassetid://10709806475',['lucide-cloudy']='rbxassetid://10709806859',['lucide-clover']='rbxassetid://10709806995',['lucide-code']='rbxassetid://10709810463',['lucide-code-2']='rbxassetid://10709807111',['lucide-codepen']='rbxassetid://10709810534',['lucide-codesandbox']='rbxassetid://10709810676',['lucide-coffee']='rbxassetid://10709810814',['lucide-cog']='rbxassetid://10709810948',['lucide-coins']='rbxassetid://10709811110',['lucide-columns']='rbxassetid://10709811261',['lucide-command']='rbxassetid://10709811365',['lucide-compass']='rbxassetid://10709811445',['lucide-component']='rbxassetid://10709811595',['lucide-concierge-bell']='rbxassetid://10709811706',['lucide-connection']='rbxassetid://10747361219',['lucide-contact']='rbxassetid://10709811834',['lucide-contrast']='rbxassetid://10709811939',['lucide-cookie']='rbxassetid://10709812067',['lucide-copy']='rbxassetid://10709812159',['lucide-copyleft']='rbxassetid://10709812251',['lucide-copyright']='rbxassetid://10709812311',['lucide-corner-down-left']='rbxassetid://10709812396',['lucide-corner-down-right']='rbxassetid://10709812485',['lucide-corner-left-down']='rbxassetid://10709812632',['lucide-corner-left-up']='rbxassetid://10709812784',['lucide-corner-right-down']='rbxassetid://10709812939',['lucide-corner-right-up']='rbxassetid://10709813094',['lucide-corner-up-left']='rbxassetid://10709813185',['lucide-corner-up-right']='rbxassetid://10709813281',['lucide-cpu']='rbxassetid://10709813383',['lucide-croissant']='rbxassetid://10709818125',['lucide-crop']='rbxassetid://10709818245',['lucide-cross']='rbxassetid://10709818399',['lucide-crosshair']='rbxassetid://10709818534',['lucide-crown']='rbxassetid://10709818626',['lucide-cup-soda']='rbxassetid://10709818763',['lucide-curly-braces']='rbxassetid://10709818847',['lucide-currency']='rbxassetid://10709818931',['lucide-database']='rbxassetid://10709818996',['lucide-delete']='rbxassetid://10709819059',['lucide-diamond']='rbxassetid://10709819149',['lucide-dice-1']='rbxassetid://10709819266',['lucide-dice-2']='rbxassetid://10709819361',['lucide-dice-3']='rbxassetid://10709819508',['lucide-dice-4']='rbxassetid://10709819670',['lucide-dice-5']='rbxassetid://10709819801',['lucide-dice-6']='rbxassetid://10709819896',['lucide-dices']='rbxassetid://10723343321',['lucide-diff']='rbxassetid://10723343416',['lucide-disc']='rbxassetid://10723343537',['lucide-divide']='rbxassetid://10723343805',['lucide-divide-circle']='rbxassetid://10723343636',['lucide-divide-square']='rbxassetid://10723343737',['lucide-dollar-sign']='rbxassetid://10723343958',['lucide-download']='rbxassetid://10723344270',['lucide-download-cloud']='rbxassetid://10723344088',['lucide-droplet']='rbxassetid://10723344432',['lucide-droplets']='rbxassetid://10734883356',['lucide-drumstick']='rbxassetid://10723344737',['lucide-edit']='rbxassetid://10734883598',['lucide-edit-2']='rbxassetid://10723344885',['lucide-edit-3']='rbxassetid://10723345088',['lucide-egg']='rbxassetid://10723345518',['lucide-egg-fried']='rbxassetid://10723345347',['lucide-electricity']='rbxassetid://10723345749',['lucide-electricity-off']='rbxassetid://10723345643',['lucide-equal']='rbxassetid://10723345990',['lucide-equal-not']='rbxassetid://10723345866',['lucide-eraser']='rbxassetid://10723346158',['lucide-euro']='rbxassetid://10723346372',['lucide-expand']='rbxassetid://10723346553',['lucide-external-link']='rbxassetid://10723346684',['lucide-eye']='rbxassetid://10723346959',['lucide-eye-off']='rbxassetid://10723346871',['lucide-factory']='rbxassetid://10723347051',['lucide-fan']='rbxassetid://10723354359',['lucide-fast-forward']='rbxassetid://10723354521',['lucide-feather']='rbxassetid://10723354671',['lucide-figma']='rbxassetid://10723354801',['lucide-file']='rbxassetid://10723374641',['lucide-file-archive']='rbxassetid://10723354921',['lucide-file-audio']='rbxassetid://10723355148',['lucide-file-audio-2']='rbxassetid://10723355026',['lucide-file-axis-3d']='rbxassetid://10723355272',['lucide-file-badge']='rbxassetid://10723355622',['lucide-file-badge-2']='rbxassetid://10723355451',['lucide-file-bar-chart']='rbxassetid://10723355887',['lucide-file-bar-chart-2']='rbxassetid://10723355746',['lucide-file-box']='rbxassetid://10723355989',['lucide-file-check']='rbxassetid://10723356210',['lucide-file-check-2']='rbxassetid://10723356100',['lucide-file-clock']='rbxassetid://10723356329',['lucide-file-code']='rbxassetid://10723356507',['lucide-file-cog']='rbxassetid://10723356830',['lucide-file-cog-2']='rbxassetid://10723356676',['lucide-file-diff']='rbxassetid://10723357039',['lucide-file-digit']='rbxassetid://10723357151',['lucide-file-down']='rbxassetid://10723357322',['lucide-file-edit']='rbxassetid://10723357495',['lucide-file-heart']='rbxassetid://10723357637',['lucide-file-image']='rbxassetid://10723357790',['lucide-file-input']='rbxassetid://10723357933',['lucide-file-json']='rbxassetid://10723364435',['lucide-file-json-2']='rbxassetid://10723364361',['lucide-file-key']='rbxassetid://10723364605',['lucide-file-key-2']='rbxassetid://10723364515',['lucide-file-line-chart']='rbxassetid://10723364725',['lucide-file-lock']='rbxassetid://10723364957',['lucide-file-lock-2']='rbxassetid://10723364861',['lucide-file-minus']='rbxassetid://10723365254',['lucide-file-minus-2']='rbxassetid://10723365086',['lucide-file-output']='rbxassetid://10723365457',['lucide-file-pie-chart']='rbxassetid://10723365598',['lucide-file-plus']='rbxassetid://10723365877',['lucide-file-plus-2']='rbxassetid://10723365766',['lucide-file-question']='rbxassetid://10723365987',['lucide-file-scan']='rbxassetid://10723366167',['lucide-file-search']='rbxassetid://10723366550',['lucide-file-search-2']='rbxassetid://10723366340',['lucide-file-signature']='rbxassetid://10723366741',['lucide-file-spreadsheet']='rbxassetid://10723366962',['lucide-file-symlink']='rbxassetid://10723367098',['lucide-file-terminal']='rbxassetid://10723367244',['lucide-file-text']='rbxassetid://10723367380',['lucide-file-type']='rbxassetid://10723367606',['lucide-file-type-2']='rbxassetid://10723367509',['lucide-file-up']='rbxassetid://10723367734',['lucide-file-video']='rbxassetid://10723373884',['lucide-file-video-2']='rbxassetid://10723367834',['lucide-file-volume']='rbxassetid://10723374172',['lucide-file-volume-2']='rbxassetid://10723374030',['lucide-file-warning']='rbxassetid://10723374276',['lucide-file-x']='rbxassetid://10723374544',['lucide-file-x-2']='rbxassetid://10723374378',['lucide-files']='rbxassetid://10723374759',['lucide-film']='rbxassetid://10723374981',['lucide-filter']='rbxassetid://10723375128',['lucide-fingerprint']='rbxassetid://10723375250',['lucide-flag']='rbxassetid://10723375890',['lucide-flag-off']='rbxassetid://10723375443',['lucide-flag-triangle-left']='rbxassetid://10723375608',['lucide-flag-triangle-right']='rbxassetid://10723375727',['lucide-flame']='rbxassetid://10723376114',['lucide-flashlight']='rbxassetid://10723376471',['lucide-flashlight-off']='rbxassetid://10723376365',['lucide-flask-conical']='rbxassetid://10734883986',['lucide-flask-round']='rbxassetid://10723376614',['lucide-flip-horizontal']='rbxassetid://10723376884',['lucide-flip-horizontal-2']='rbxassetid://10723376745',['lucide-flip-vertical']='rbxassetid://10723377138',['lucide-flip-vertical-2']='rbxassetid://10723377026',['lucide-flower']='rbxassetid://10747830374',['lucide-flower-2']='rbxassetid://10723377305',['lucide-focus']='rbxassetid://10723377537',['lucide-folder']='rbxassetid://10723387563',['lucide-folder-archive']='rbxassetid://10723384478',['lucide-folder-check']='rbxassetid://10723384605',['lucide-folder-clock']='rbxassetid://10723384731',['lucide-folder-closed']='rbxassetid://10723384893',['lucide-folder-cog']='rbxassetid://10723385213',['lucide-folder-cog-2']='rbxassetid://10723385036',['lucide-folder-down']='rbxassetid://10723385338',['lucide-folder-edit']='rbxassetid://10723385445',['lucide-folder-heart']='rbxassetid://10723385545',['lucide-folder-input']='rbxassetid://10723385721',['lucide-folder-key']='rbxassetid://10723385848',['lucide-folder-lock']='rbxassetid://10723386005',['lucide-folder-minus']='rbxassetid://10723386127',['lucide-folder-open']='rbxassetid://10723386277',['lucide-folder-output']='rbxassetid://10723386386',['lucide-folder-plus']='rbxassetid://10723386531',['lucide-folder-search']='rbxassetid://10723386787',['lucide-folder-search-2']='rbxassetid://10723386674',['lucide-folder-symlink']='rbxassetid://10723386930',['lucide-folder-tree']='rbxassetid://10723387085',['lucide-folder-up']='rbxassetid://10723387265',['lucide-folder-x']='rbxassetid://10723387448',['lucide-folders']='rbxassetid://10723387721',['lucide-form-input']='rbxassetid://10723387841',['lucide-forward']='rbxassetid://10723388016',['lucide-frame']='rbxassetid://10723394389',['lucide-framer']='rbxassetid://10723394565',['lucide-frown']='rbxassetid://10723394681',['lucide-fuel']='rbxassetid://10723394846',['lucide-function-square']='rbxassetid://10723395041',['lucide-gamepad']='rbxassetid://10723395457',['lucide-gamepad-2']='rbxassetid://10723395215',['lucide-gauge']='rbxassetid://10723395708',['lucide-gavel']='rbxassetid://10723395896',['lucide-gem']='rbxassetid://10723396000',['lucide-ghost']='rbxassetid://10723396107',['lucide-gift']='rbxassetid://10723396402',['lucide-gift-card']='rbxassetid://10723396225',['lucide-git-branch']='rbxassetid://10723396676',['lucide-git-branch-plus']='rbxassetid://10723396542',['lucide-git-commit']='rbxassetid://10723396812',['lucide-git-compare']='rbxassetid://10723396954',['lucide-git-fork']='rbxassetid://10723397049',['lucide-git-merge']='rbxassetid://10723397165',['lucide-git-pull-request']='rbxassetid://10723397431',['lucide-git-pull-request-closed']='rbxassetid://10723397268',['lucide-git-pull-request-draft']='rbxassetid://10734884302',['lucide-glass']='rbxassetid://10723397788',['lucide-glass-2']='rbxassetid://10723397529',['lucide-glass-water']='rbxassetid://10723397678',['lucide-glasses']='rbxassetid://10723397895',['lucide-globe']='rbxassetid://10723404337',['lucide-globe-2']='rbxassetid://10723398002',['lucide-grab']='rbxassetid://10723404472',['lucide-graduation-cap']='rbxassetid://10723404691',['lucide-grape']='rbxassetid://10723404822',['lucide-grid']='rbxassetid://10723404936',['lucide-grip-horizontal']='rbxassetid://10723405089',['lucide-grip-vertical']='rbxassetid://10723405236',['lucide-hammer']='rbxassetid://10723405360',['lucide-hand']='rbxassetid://10723405649',['lucide-hand-metal']='rbxassetid://10723405508',['lucide-hard-drive']='rbxassetid://10723405749',['lucide-hard-hat']='rbxassetid://10723405859',['lucide-hash']='rbxassetid://10723405975',['lucide-haze']='rbxassetid://10723406078',['lucide-headphones']='rbxassetid://10723406165',['lucide-heart']='rbxassetid://10723406885',['lucide-heart-crack']='rbxassetid://10723406299',['lucide-heart-handshake']='rbxassetid://10723406480',['lucide-heart-off']='rbxassetid://10723406662',['lucide-heart-pulse']='rbxassetid://10723406795',['lucide-help-circle']='rbxassetid://10723406988',['lucide-hexagon']='rbxassetid://10723407092',['lucide-highlighter']='rbxassetid://10723407192',['lucide-history']='rbxassetid://10723407335',['lucide-home']='rbxassetid://10723407389',['lucide-hourglass']='rbxassetid://10723407498',['lucide-ice-cream']='rbxassetid://10723414308',['lucide-image']='rbxassetid://10723415040',['lucide-image-minus']='rbxassetid://10723414487',['lucide-image-off']='rbxassetid://10723414677',['lucide-image-plus']='rbxassetid://10723414827',['lucide-import']='rbxassetid://10723415205',['lucide-inbox']='rbxassetid://10723415335',['lucide-indent']='rbxassetid://10723415494',['lucide-indian-rupee']='rbxassetid://10723415642',['lucide-infinity']='rbxassetid://10723415766',['lucide-info']='rbxassetid://10723415903',['lucide-inspect']='rbxassetid://10723416057',['lucide-italic']='rbxassetid://10723416195',['lucide-japanese-yen']='rbxassetid://10723416363',['lucide-joystick']='rbxassetid://10723416527',['lucide-key']='rbxassetid://10723416652',['lucide-keyboard']='rbxassetid://10723416765',['lucide-lamp']='rbxassetid://10723417513',['lucide-lamp-ceiling']='rbxassetid://10723416922',['lucide-lamp-desk']='rbxassetid://10723417016',['lucide-lamp-floor']='rbxassetid://10723417131',['lucide-lamp-wall-down']='rbxassetid://10723417240',['lucide-lamp-wall-up']='rbxassetid://10723417356',['lucide-landmark']='rbxassetid://10723417608',['lucide-languages']='rbxassetid://10723417703',['lucide-laptop']='rbxassetid://10723423881',['lucide-laptop-2']='rbxassetid://10723417797',['lucide-lasso']='rbxassetid://10723424235',['lucide-lasso-select']='rbxassetid://10723424058',['lucide-laugh']='rbxassetid://10723424372',['lucide-layers']='rbxassetid://10723424505',['lucide-layout']='rbxassetid://10723425376',['lucide-layout-dashboard']='rbxassetid://10723424646',['lucide-layout-grid']='rbxassetid://10723424838',['lucide-layout-list']='rbxassetid://10723424963',['lucide-layout-template']='rbxassetid://10723425187',['lucide-leaf']='rbxassetid://10723425539',['lucide-library']='rbxassetid://10723425615',['lucide-life-buoy']='rbxassetid://10723425685',['lucide-lightbulb']='rbxassetid://10723425852',['lucide-lightbulb-off']='rbxassetid://10723425762',['lucide-line-chart']='rbxassetid://10723426393',['lucide-link']='rbxassetid://10723426722',['lucide-link-2']='rbxassetid://10723426595',['lucide-link-2-off']='rbxassetid://10723426513',['lucide-list']='rbxassetid://10723433811',['lucide-list-checks']='rbxassetid://10734884548',['lucide-list-end']='rbxassetid://10723426886',['lucide-list-minus']='rbxassetid://10723426986',['lucide-list-music']='rbxassetid://10723427081',['lucide-list-ordered']='rbxassetid://10723427199',['lucide-list-plus']='rbxassetid://10723427334',['lucide-list-start']='rbxassetid://10723427494',['lucide-list-video']='rbxassetid://10723427619',['lucide-list-x']='rbxassetid://10723433655',['lucide-loader']='rbxassetid://10723434070',['lucide-loader-2']='rbxassetid://10723433935',['lucide-locate']='rbxassetid://10723434557',['lucide-locate-fixed']='rbxassetid://10723434236',['lucide-locate-off']='rbxassetid://10723434379',['lucide-lock']='rbxassetid://10723434711',['lucide-log-in']='rbxassetid://10723434830',['lucide-log-out']='rbxassetid://10723434906',['lucide-luggage']='rbxassetid://10723434993',['lucide-magnet']='rbxassetid://10723435069',['lucide-mail']='rbxassetid://10734885430',['lucide-mail-check']='rbxassetid://10723435182',['lucide-mail-minus']='rbxassetid://10723435261',['lucide-mail-open']='rbxassetid://10723435342',['lucide-mail-plus']='rbxassetid://10723435443',['lucide-mail-question']='rbxassetid://10723435515',['lucide-mail-search']='rbxassetid://10734884739',['lucide-mail-warning']='rbxassetid://10734885015',['lucide-mail-x']='rbxassetid://10734885247',['lucide-mails']='rbxassetid://10734885614',['lucide-map']='rbxassetid://10734886202',['lucide-map-pin']='rbxassetid://10734886004',['lucide-map-pin-off']='rbxassetid://10734885803',['lucide-maximize']='rbxassetid://10734886735',['lucide-maximize-2']='rbxassetid://10734886496',['lucide-medal']='rbxassetid://10734887072',['lucide-megaphone']='rbxassetid://10734887454',['lucide-megaphone-off']='rbxassetid://10734887311',['lucide-meh']='rbxassetid://10734887603',['lucide-menu']='rbxassetid://10734887784',['lucide-message-circle']='rbxassetid://10734888000',['lucide-message-square']='rbxassetid://10734888228',['lucide-mic']='rbxassetid://10734888864',['lucide-mic-2']='rbxassetid://10734888430',['lucide-mic-off']='rbxassetid://10734888646',['lucide-microscope']='rbxassetid://10734889106',['lucide-microwave']='rbxassetid://10734895076',['lucide-milestone']='rbxassetid://10734895310',['lucide-minimize']='rbxassetid://10734895698',['lucide-minimize-2']='rbxassetid://10734895530',['lucide-minus']='rbxassetid://10734896206',['lucide-minus-circle']='rbxassetid://10734895856',['lucide-minus-square']='rbxassetid://10734896029',['lucide-monitor']='rbxassetid://10734896881',['lucide-monitor-off']='rbxassetid://10734896360',['lucide-monitor-speaker']='rbxassetid://10734896512',['lucide-moon']='rbxassetid://10734897102',['lucide-more-horizontal']='rbxassetid://10734897250',['lucide-more-vertical']='rbxassetid://10734897387',['lucide-mountain']='rbxassetid://10734897956',['lucide-mountain-snow']='rbxassetid://10734897665',['lucide-mouse']='rbxassetid://10734898592',['lucide-mouse-pointer']='rbxassetid://10734898476',['lucide-mouse-pointer-2']='rbxassetid://10734898194',['lucide-mouse-pointer-click']='rbxassetid://10734898355',['lucide-move']='rbxassetid://10734900011',['lucide-move-3d']='rbxassetid://10734898756',['lucide-move-diagonal']='rbxassetid://10734899164',['lucide-move-diagonal-2']='rbxassetid://10734898934',['lucide-move-horizontal']='rbxassetid://10734899414',['lucide-move-vertical']='rbxassetid://10734899821',['lucide-music']='rbxassetid://10734905958',['lucide-music-2']='rbxassetid://10734900215',['lucide-music-3']='rbxassetid://10734905665',['lucide-music-4']='rbxassetid://10734905823',['lucide-navigation']='rbxassetid://10734906744',['lucide-navigation-2']='rbxassetid://10734906332',['lucide-navigation-2-off']='rbxassetid://10734906144',['lucide-navigation-off']='rbxassetid://10734906580',['lucide-network']='rbxassetid://10734906975',['lucide-newspaper']='rbxassetid://10734907168',['lucide-octagon']='rbxassetid://10734907361',['lucide-option']='rbxassetid://10734907649',['lucide-outdent']='rbxassetid://10734907933',['lucide-package']='rbxassetid://10734909540',['lucide-package-2']='rbxassetid://10734908151',['lucide-package-check']='rbxassetid://10734908384',['lucide-package-minus']='rbxassetid://10734908626',['lucide-package-open']='rbxassetid://10734908793',['lucide-package-plus']='rbxassetid://10734909016',['lucide-package-search']='rbxassetid://10734909196',['lucide-package-x']='rbxassetid://10734909375',['lucide-paint-bucket']='rbxassetid://10734909847',['lucide-paintbrush']='rbxassetid://10734910187',['lucide-paintbrush-2']='rbxassetid://10734910030',['lucide-palette']='rbxassetid://10734910430',['lucide-palmtree']='rbxassetid://10734910680',['lucide-paperclip']='rbxassetid://10734910927',['lucide-party-popper']='rbxassetid://10734918735',['lucide-pause']='rbxassetid://10734919336',['lucide-pause-circle']='rbxassetid://10735024209',['lucide-pause-octagon']='rbxassetid://10734919143',['lucide-pen-tool']='rbxassetid://10734919503',['lucide-pencil']='rbxassetid://10734919691',['lucide-percent']='rbxassetid://10734919919',['lucide-person-standing']='rbxassetid://10734920149',['lucide-phone']='rbxassetid://10734921524',['lucide-phone-call']='rbxassetid://10734920305',['lucide-phone-forwarded']='rbxassetid://10734920508',['lucide-phone-incoming']='rbxassetid://10734920694',['lucide-phone-missed']='rbxassetid://10734920845',['lucide-phone-off']='rbxassetid://10734921077',['lucide-phone-outgoing']='rbxassetid://10734921288',['lucide-pie-chart']='rbxassetid://10734921727',['lucide-piggy-bank']='rbxassetid://10734921935',['lucide-pin']='rbxassetid://10734922324',['lucide-pin-off']='rbxassetid://10734922180',['lucide-pipette']='rbxassetid://10734922497',['lucide-pizza']='rbxassetid://10734922774',['lucide-plane']='rbxassetid://10734922971',['lucide-play']='rbxassetid://10734923549',['lucide-play-circle']='rbxassetid://10734923214',['lucide-plus']='rbxassetid://10734924532',['lucide-plus-circle']='rbxassetid://10734923868',['lucide-plus-square']='rbxassetid://10734924219',['lucide-podcast']='rbxassetid://10734929553',['lucide-pointer']='rbxassetid://10734929723',['lucide-pound-sterling']='rbxassetid://10734929981',['lucide-power']='rbxassetid://10734930466',['lucide-power-off']='rbxassetid://10734930257',['lucide-printer']='rbxassetid://10734930632',['lucide-puzzle']='rbxassetid://10734930886',['lucide-quote']='rbxassetid://10734931234',['lucide-radio']='rbxassetid://10734931596',['lucide-radio-receiver']='rbxassetid://10734931402',['lucide-rectangle-horizontal']='rbxassetid://10734931777',['lucide-rectangle-vertical']='rbxassetid://10734932081',['lucide-recycle']='rbxassetid://10734932295',['lucide-redo']='rbxassetid://10734932822',['lucide-redo-2']='rbxassetid://10734932586',['lucide-refresh-ccw']='rbxassetid://10734933056',['lucide-refresh-cw']='rbxassetid://10734933222',['lucide-refrigerator']='rbxassetid://10734933465',['lucide-regex']='rbxassetid://10734933655',['lucide-repeat']='rbxassetid://10734933966',['lucide-repeat-1']='rbxassetid://10734933826',['lucide-reply']='rbxassetid://10734934252',['lucide-reply-all']='rbxassetid://10734934132',['lucide-rewind']='rbxassetid://10734934347',['lucide-rocket']='rbxassetid://10734934585',['lucide-rocking-chair']='rbxassetid://10734939942',['lucide-rotate-3d']='rbxassetid://10734940107',['lucide-rotate-ccw']='rbxassetid://10734940376',['lucide-rotate-cw']='rbxassetid://10734940654',['lucide-rss']='rbxassetid://10734940825',['lucide-ruler']='rbxassetid://10734941018',['lucide-russian-ruble']='rbxassetid://10734941199',['lucide-sailboat']='rbxassetid://10734941354',['lucide-save']='rbxassetid://10734941499',['lucide-scale']='rbxassetid://10734941912',['lucide-scale-3d']='rbxassetid://10734941739',['lucide-scaling']='rbxassetid://10734942072',['lucide-scan']='rbxassetid://10734942565',['lucide-scan-face']='rbxassetid://10734942198',['lucide-scan-line']='rbxassetid://10734942351',['lucide-scissors']='rbxassetid://10734942778',['lucide-screen-share']='rbxassetid://10734943193',['lucide-screen-share-off']='rbxassetid://10734942967',['lucide-scroll']='rbxassetid://10734943448',['lucide-search']='rbxassetid://10734943674',['lucide-send']='rbxassetid://10734943902',['lucide-separator-horizontal']='rbxassetid://10734944115',['lucide-separator-vertical']='rbxassetid://10734944326',['lucide-server']='rbxassetid://10734949856',['lucide-server-cog']='rbxassetid://10734944444',['lucide-server-crash']='rbxassetid://10734944554',['lucide-server-off']='rbxassetid://10734944668',['lucide-settings']='rbxassetid://10734950309',['lucide-settings-2']='rbxassetid://10734950020',['lucide-share']='rbxassetid://10734950813',['lucide-share-2']='rbxassetid://10734950553',['lucide-sheet']='rbxassetid://10734951038',['lucide-shield']='rbxassetid://10734951847',['lucide-shield-alert']='rbxassetid://10734951173',['lucide-shield-check']='rbxassetid://10734951367',['lucide-shield-close']='rbxassetid://10734951535',['lucide-shield-off']='rbxassetid://10734951684',['lucide-shirt']='rbxassetid://10734952036',['lucide-shopping-bag']='rbxassetid://10734952273',['lucide-shopping-cart']='rbxassetid://10734952479',['lucide-shovel']='rbxassetid://10734952773',['lucide-shower-head']='rbxassetid://10734952942',['lucide-shrink']='rbxassetid://10734953073',['lucide-shrub']='rbxassetid://10734953241',['lucide-shuffle']='rbxassetid://10734953451',['lucide-sidebar']='rbxassetid://10734954301',['lucide-sidebar-close']='rbxassetid://10734953715',['lucide-sidebar-open']='rbxassetid://10734954000',['lucide-sigma']='rbxassetid://10734954538',['lucide-signal']='rbxassetid://10734961133',['lucide-signal-high']='rbxassetid://10734954807',['lucide-signal-low']='rbxassetid://10734955080',['lucide-signal-medium']='rbxassetid://10734955336',['lucide-signal-zero']='rbxassetid://10734960878',['lucide-siren']='rbxassetid://10734961284',['lucide-skip-back']='rbxassetid://10734961526',['lucide-skip-forward']='rbxassetid://10734961809',['lucide-skull']='rbxassetid://10734962068',['lucide-slack']='rbxassetid://10734962339',['lucide-slash']='rbxassetid://10734962600',['lucide-slice']='rbxassetid://10734963024',['lucide-sliders']='rbxassetid://10734963400',['lucide-sliders-horizontal']='rbxassetid://10734963191',['lucide-smartphone']='rbxassetid://10734963940',['lucide-smartphone-charging']='rbxassetid://10734963671',['lucide-smile']='rbxassetid://10734964441',['lucide-smile-plus']='rbxassetid://10734964188',['lucide-snowflake']='rbxassetid://10734964600',['lucide-sofa']='rbxassetid://10734964852',['lucide-sort-asc']='rbxassetid://10734965115',['lucide-sort-desc']='rbxassetid://10734965287',['lucide-speaker']='rbxassetid://10734965419',['lucide-sprout']='rbxassetid://10734965572',['lucide-square']='rbxassetid://10734965702',['lucide-star']='rbxassetid://10734966248',['lucide-star-half']='rbxassetid://10734965897',['lucide-star-off']='rbxassetid://10734966097',['lucide-stethoscope']='rbxassetid://10734966384',['lucide-sticker']='rbxassetid://10734972234',['lucide-sticky-note']='rbxassetid://10734972463',['lucide-stop-circle']='rbxassetid://10734972621',['lucide-stretch-horizontal']='rbxassetid://10734972862',['lucide-stretch-vertical']='rbxassetid://10734973130',['lucide-strikethrough']='rbxassetid://10734973290',['lucide-subscript']='rbxassetid://10734973457',['lucide-sun']='rbxassetid://10734974297',['lucide-sun-dim']='rbxassetid://10734973645',['lucide-sun-medium']='rbxassetid://10734973778',['lucide-sun-moon']='rbxassetid://10734973999',['lucide-sun-snow']='rbxassetid://10734974130',['lucide-sunrise']='rbxassetid://10734974522',['lucide-sunset']='rbxassetid://10734974689',['lucide-superscript']='rbxassetid://10734974850',['lucide-swiss-franc']='rbxassetid://10734975024',['lucide-switch-camera']='rbxassetid://10734975214',['lucide-sword']='rbxassetid://10734975486',['lucide-swords']='rbxassetid://10734975692',['lucide-syringe']='rbxassetid://10734975932',['lucide-table']='rbxassetid://10734976230',['lucide-table-2']='rbxassetid://10734976097',['lucide-tablet']='rbxassetid://10734976394',['lucide-tag']='rbxassetid://10734976528',['lucide-tags']='rbxassetid://10734976739',['lucide-target']='rbxassetid://10734977012',['lucide-tent']='rbxassetid://10734981750',['lucide-terminal']='rbxassetid://10734982144',['lucide-terminal-square']='rbxassetid://10734981995',['lucide-text-cursor']='rbxassetid://10734982395',['lucide-text-cursor-input']='rbxassetid://10734982297',['lucide-thermometer']='rbxassetid://10734983134',['lucide-thermometer-snowflake']='rbxassetid://10734982571',['lucide-thermometer-sun']='rbxassetid://10734982771',['lucide-thumbs-down']='rbxassetid://10734983359',['lucide-thumbs-up']='rbxassetid://10734983629',['lucide-ticket']='rbxassetid://10734983868',['lucide-timer']='rbxassetid://10734984606',['lucide-timer-off']='rbxassetid://10734984138',['lucide-timer-reset']='rbxassetid://10734984355',['lucide-toggle-left']='rbxassetid://10734984834',['lucide-toggle-right']='rbxassetid://10734985040',['lucide-tornado']='rbxassetid://10734985247',['lucide-toy-brick']='rbxassetid://10747361919',['lucide-train']='rbxassetid://10747362105',['lucide-trash']='rbxassetid://10747362393',['lucide-trash-2']='rbxassetid://10747362241',['lucide-tree-deciduous']='rbxassetid://10747362534',['lucide-tree-pine']='rbxassetid://10747362748',['lucide-trees']='rbxassetid://10747363016',['lucide-trending-down']='rbxassetid://10747363205',['lucide-trending-up']='rbxassetid://10747363465',['lucide-triangle']='rbxassetid://10747363621',['lucide-trophy']='rbxassetid://10747363809',['lucide-truck']='rbxassetid://10747364031',['lucide-tv']='rbxassetid://10747364593',['lucide-tv-2']='rbxassetid://10747364302',['lucide-type']='rbxassetid://10747364761',['lucide-umbrella']='rbxassetid://10747364971',['lucide-underline']='rbxassetid://10747365191',['lucide-undo']='rbxassetid://10747365484',['lucide-undo-2']='rbxassetid://10747365359',['lucide-unlink']='rbxassetid://10747365771',['lucide-unlink-2']='rbxassetid://10747397871',['lucide-unlock']='rbxassetid://10747366027',['lucide-upload']='rbxassetid://10747366434',['lucide-upload-cloud']='rbxassetid://10747366266',['lucide-usb']='rbxassetid://10747366606',['lucide-user']='rbxassetid://10747373176',['lucide-user-check']='rbxassetid://10747371901',['lucide-user-cog']='rbxassetid://10747372167',['lucide-user-minus']='rbxassetid://10747372346',['lucide-user-plus']='rbxassetid://10747372702',['lucide-user-x']='rbxassetid://10747372992',['lucide-users']='rbxassetid://10747373426',['lucide-utensils']='rbxassetid://10747373821',['lucide-utensils-crossed']='rbxassetid://10747373629',['lucide-venetian-mask']='rbxassetid://10747374003',['lucide-verified']='rbxassetid://10747374131',['lucide-vibrate']='rbxassetid://10747374489',['lucide-vibrate-off']='rbxassetid://10747374269',['lucide-video']='rbxassetid://10747374938',['lucide-video-off']='rbxassetid://10747374721',['lucide-view']='rbxassetid://10747375132',['lucide-voicemail']='rbxassetid://10747375281',['lucide-volume']='rbxassetid://10747376008',['lucide-volume-1']='rbxassetid://10747375450',['lucide-volume-2']='rbxassetid://10747375679',['lucide-volume-x']='rbxassetid://10747375880',['lucide-wallet']='rbxassetid://10747376205',['lucide-wand']='rbxassetid://10747376565',['lucide-wand-2']='rbxassetid://10747376349',['lucide-watch']='rbxassetid://10747376722',['lucide-waves']='rbxassetid://10747376931',['lucide-webcam']='rbxassetid://10747381992',['lucide-wifi']='rbxassetid://10747382504',['lucide-wifi-off']='rbxassetid://10747382268',['lucide-wind']='rbxassetid://10747382750',['lucide-wrap-text']='rbxassetid://10747383065',['lucide-wrench']='rbxassetid://10747383470',['lucide-x']='rbxassetid://10747384394',['lucide-x-circle']='rbxassetid://10747383819',['lucide-x-octagon']='rbxassetid://10747384037',['lucide-x-square']='rbxassetid://10747384217',['lucide-zoom-in']='rbxassetid://10747384552',['lucide-zoom-out']='rbxassetid://10747384679'}}end,[30]=function()local aa,ab,ac,ad,ae=b(30)local af={SingleMotor=ac(ab.SingleMotor),GroupMotor=ac(ab.GroupMotor),Instant=ac(ab.Instant),Linear=ac(ab.Linear),Spring=ac(ab.Spring),isMotor=ac(ab.isMotor)}return af end,[31]=function()local aa,ab,ac,ad,ae=b(31)local af,ag,ah,ai=game:GetService'RunService',ac(ab.Parent.Signal),function()end,{}ai.__index=ai function ai.new()return setmetatable({_onStep=ag.new(),_onStart=ag.new(),_onComplete=ag.new()},ai)end function ai.onStep(aj,c)return aj._onStep:connect(c)end function ai.onStart(aj,c)return aj._onStart:connect(c)end function ai.onComplete(aj,c)return aj._onComplete:connect(c)end function ai.start(aj)if not aj._connection then aj._connection=af.RenderStepped:Connect(function(c)aj:step(c)end)end end function ai.stop(aj)if aj._connection then aj._connection:Disconnect()aj._connection=nil end end ai.destroy=ai.stop ai.step=ah ai.getValue=ah ai.setGoal=ah function ai.__tostring(aj)return'Motor'end return ai end,[32]=function()local aa,ab,ac,ad,ae=b(32)return function()local af,ag=game:GetService'RunService',ac(ab.Parent.BaseMotor)describe('connection management',function()local ah=ag.new()it('should hook up connections on :start()',function()ah:start()expect(typeof(ah._connection)).to.equal'RBXScriptConnection'end)it('should remove connections on :stop() or :destroy()',function()ah:stop()expect(ah._connection).to.equal(nil)end)end)it('should call :step() with deltaTime',function()local ah,ai=(ag.new())function ah.step(aj,...)ai={...}ah:stop()end ah:start()local aj=af.RenderStepped:Wait()af.RenderStepped:Wait()expect(ai).to.be.ok()expect(ai[1]).to.equal(aj)end)end end,[33]=function()local aa,ab,ac,ad,ae=b(33)local af,ag,ah=ac(ab.Parent.BaseMotor),ac(ab.Parent.SingleMotor),ac(ab.Parent.isMotor)local ai=setmetatable({},af)ai.__index=ai local aj=function(aj)if ah(aj)then return aj end local c=typeof(aj)if c=='number'then return ag.new(aj,false)elseif c=='table'then return ai.new(aj,false)end error(('Unable to convert %q to motor; type %s is unsupported'):format(aj,c),2)end function ai.new(c,d)assert(c,'Missing argument #1: initialValues')assert(typeof(c)=='table','initialValues must be a table!')assert(not c.step,[[initialValues contains disallowed property "step". Did you mean to put a table of values here?]])local e=setmetatable(af.new(),ai)if d~=nil then e._useImplicitConnections=d else e._useImplicitConnections=true end e._complete=true e._motors={}for f,g in pairs(c)do e._motors[f]=aj(g)end return e end function ai.step(c,d)if c._complete then return true end local e=true for f,g in pairs(c._motors)do local h=g:step(d)if not h then e=false end end c._onStep:fire(c:getValue())if e then if c._useImplicitConnections then c:stop()end c._complete=true c._onComplete:fire()end return e end function ai.setGoal(c,d)assert(not d.step,[[goals contains disallowed property "step". Did you mean to put a table of goals here?]])c._complete=false c._onStart:fire()for e,f in pairs(d)do local g=assert(c._motors[e],('Unknown motor for key %s'):format(e))g:setGoal(f)end if c._useImplicitConnections then c:start()end end function ai.getValue(c)local d={}for e,f in pairs(c._motors)do d[e]=f:getValue()end return d end function ai.__tostring(c)return'Motor(Group)'end return ai end,[34]=function()local aa,ab,ac,ad,ae=b(34)return function()local af,ag,ah=ac(ab.Parent.GroupMotor),ac(ab.Parent.Instant),ac(ab.Parent.Spring)it('should complete when all child motors are complete',function()local ai=af.new({A=1,B=2},false)expect(ai._complete).to.equal(true)ai:setGoal{A=ag.new(3),B=ah.new(4,{frequency=7.5,dampingRatio=1})}expect(ai._complete).to.equal(false)ai:step(1.6666666666666665E-2)expect(ai._complete).to.equal(false)for aj=1,30 do ai:step(1.6666666666666665E-2)end expect(ai._complete).to.equal(true)end)it('should start when the goal is set',function()local ai,aj=af.new({A=0},false),false ai:onStart(function()aj=not aj end)ai:setGoal{A=ag.new(1)}expect(aj).to.equal(true)ai:setGoal{A=ag.new(1)}expect(aj).to.equal(false)end)it('should properly return all values',function()local ai=af.new({A=1,B=2},false)local aj=ai:getValue()expect(aj.A).to.equal(1)expect(aj.B).to.equal(2)end)it('should error when a goal is given to GroupMotor.new',function()local ai=pcall(function()af.new(ag.new(0))end)expect(ai).to.equal(false)end)it([[should error when a single goal is provided to GroupMotor:step]],function()local ai=pcall(function()af.new{a=1}:setGoal(ag.new(0))end)expect(ai).to.equal(false)end)end end,[35]=function()local aa,ab,ac,ad,ae=b(35)local af={}af.__index=af function af.new(ag)return setmetatable({_targetValue=ag},af)end function af.step(ag)return{complete=true,value=ag._targetValue}end return af end,[36]=function()local aa,ab,ac,ad,ae=b(36)return function()local af=ac(ab.Parent.Instant)it('should return a completed state with the provided value',function()local ag=af.new(1.23)local ah=ag:step(0.1,{value=0,complete=false})expect(ah.complete).to.equal(true)expect(ah.value).to.equal(1.23)end)end end,[37]=function()local aa,ab,ac,ad,ae=b(37)local af={}af.__index=af function af.new(ag,ah)assert(ag,'Missing argument #1: targetValue')ah=ah or{}return setmetatable({_targetValue=ag,_velocity=ah.velocity or 1},af)end function af.step(ag,ah,ai)local aj,c,d=ah.value,ag._velocity,ag._targetValue local e=ai*c local f=e>=math.abs(d-aj)aj=aj+e*(d>aj and 1 or-1)if f then aj=ag._targetValue c=0 end return{complete=f,value=aj,velocity=c}end return af end,[38]=function()local aa,ab,ac,ad,ae=b(38)return function()local af,ag=ac(ab.Parent.SingleMotor),ac(ab.Parent.Linear)describe('completed state',function()local ah,ai=af.new(0,false),ag.new(1,{velocity=1})ah:setGoal(ai)for aj=1,60 do ah:step(1.6666666666666665E-2)end it('should complete',function()expect(ah._state.complete).to.equal(true)end)it('should be exactly the goal value when completed',function()expect(ah._state.value).to.equal(1)end)end)describe('uncompleted state',function()local ah,ai=af.new(0,false),ag.new(1,{velocity=1})ah:setGoal(ai)for aj=1,59 do ah:step(1.6666666666666665E-2)end it('should be uncomplete',function()expect(ah._state.complete).to.equal(false)end)end)describe('negative velocity',function()local ah,ai=af.new(1,false),ag.new(0,{velocity=1})ah:setGoal(ai)for aj=1,60 do ah:step(1.6666666666666665E-2)end it('should complete',function()expect(ah._state.complete).to.equal(true)end)it('should be exactly the goal value when completed',function()expect(ah._state.value).to.equal(0)end)end)end end,[39]=function()local aa,ab,ac,ad,ae=b(39)local af={}af.__index=af function af.new(ag,ah)return setmetatable({signal=ag,connected=true,_handler=ah},af)end function af.disconnect(ag)if ag.connected then ag.connected=false for ah,ai in pairs(ag.signal._connections)do if ai==ag then table.remove(ag.signal._connections,ah)return end end end end local ag={}ag.__index=ag function ag.new()return setmetatable({_connections={},_threads={}},ag)end function ag.fire(ah,...)for ai,aj in pairs(ah._connections)do aj._handler(...)end for c,d in pairs(ah._threads)do coroutine.resume(d,...)end ah._threads={}end function ag.connect(ah,aj)local c=af.new(ah,aj)table.insert(ah._connections,c)return c end function ag.wait(ah)table.insert(ah._threads,coroutine.running())return coroutine.yield()end return ag end,[40]=function()local aa,ab,ac,ad,ae=b(40)return function()local af=ac(ab.Parent.Signal)it('should invoke all connections, instantly',function()local ag,ah,aj=(af.new())ag:connect(function(c)ah=c end)ag:connect(function(c)aj=c end)ag:fire'hello'expect(ah).to.equal'hello'expect(aj).to.equal'hello'end)it('should return values when :wait() is called',function()local ag=af.new()spawn(function()ag:fire(123,'hello')end)local ah,aj=ag:wait()expect(ah).to.equal(123)expect(aj).to.equal'hello'end)it('should properly handle disconnections',function()local ag,ah=af.new(),false local aj=ag:connect(function()ah=true end)aj:disconnect()ag:fire()expect(ah).to.equal(false)end)end end,[41]=function()local aa,ab,ac,ad,ae=b(41)local af=ac(ab.Parent.BaseMotor)local ag=setmetatable({},af)ag.__index=ag function ag.new(ah,aj)assert(ah,'Missing argument #1: initialValue')assert(typeof(ah)=='number','initialValue must be a number!')local c=setmetatable(af.new(),ag)if aj~=nil then c._useImplicitConnections=aj else c._useImplicitConnections=true end c._goal=nil c._state={complete=true,value=ah}return c end function ag.step(ah,aj)if ah._state.complete then return true end local c=ah._goal:step(ah._state,aj)ah._state=c ah._onStep:fire(c.value)if c.complete then if ah._useImplicitConnections then ah:stop()end ah._onComplete:fire()end return c.complete end function ag.getValue(ah)return ah._state.value end function ag.setGoal(ah,aj)ah._state.complete=false ah._goal=aj ah._onStart:fire()if ah._useImplicitConnections then ah:start()end end function ag.__tostring(ah)return'Motor(Single)'end return ag end,[42]=function()local aa,ab,ac,ad,ae=b(42)return function()local af,ag=ac(ab.Parent.SingleMotor),ac(ab.Parent.Instant)it('should assign new state on step',function()local ah=af.new(0,false)ah:setGoal(ag.new(5))ah:step(1.6666666666666665E-2)expect(ah._state.complete).to.equal(true)expect(ah._state.value).to.equal(5)end)it([[should invoke onComplete listeners when the goal is completed]],function()local ah,aj=af.new(0,false),false ah:onComplete(function()aj=true end)ah:setGoal(ag.new(5))ah:step(1.6666666666666665E-2)expect(aj).to.equal(true)end)it('should start when the goal is set',function()local ah,aj=af.new(0,false),false ah:onStart(function()aj=not aj end)ah:setGoal(ag.new(5))expect(aj).to.equal(true)ah:setGoal(ag.new(5))expect(aj).to.equal(false)end)end end,[43]=function()local aa,ab,ac,ad,ae=b(43)local af,ag,ah,aj=0.001,0.001,0.0001,{}aj.__index=aj function aj.new(c,d)assert(c,'Missing argument #1: targetValue')d=d or{}return setmetatable({_targetValue=c,_frequency=d.frequency or 4,_dampingRatio=d.dampingRatio or 1},aj)end function aj.step(c,d,e)local f,g,h,i,j=c._dampingRatio,c._frequency*2*math.pi,c._targetValue,d.value,d.velocity or 0 local k,l,m,n=i-h,(math.exp(-f*g*e))if f==1 then m=(k*(1+g*e)+j*e)*l+h n=(j*(1-g*e)-k*(g*g*e))*l elseif f<1 then local o=math.sqrt(1-f*f)local p,s,t=math.cos(g*o*e),(math.sin(g*o*e))if o>ah then t=s/o else local u=e*g t=u+((u*u)*(o*o)*(o*o)/20-o*o)*(u*u*u)/6 end local u if g*o>ah then u=s/(g*o)else local v=g*o u=e+((e*e)*(v*v)*(v*v)/20-v*v)*(e*e*e)/6 end m=(k*(p+f*t)+j*u)*l+h n=(j*(p-t*f)-k*(t*g))*l else local o=math.sqrt(f*f-1)local p,s=-g*(f-o),-g*(f+o)local t=(j-k*p)/(2*g*o)local u=k-t local v,w=u*math.exp(p*e),t*math.exp(s*e)m=v+w+h n=v*p+w*s end local o=math.abs(n)<af and math.abs(m-h)<ag return{complete=o,value=o and h or m,velocity=n}end return aj end,[44]=function()local aa,ab,ac,ad,ae=b(44)return function()local af,ag=ac(ab.Parent.SingleMotor),ac(ab.Parent.Spring)describe('completed state',function()local ah,aj=af.new(0,false),ag.new(1,{frequency=2,dampingRatio=0.75})ah:setGoal(aj)for c=1,100 do ah:step(1.6666666666666665E-2)end it('should complete',function()expect(ah._state.complete).to.equal(true)end)it('should be exactly the goal value when completed',function()expect(ah._state.value).to.equal(1)end)end)it('should inherit velocity',function()local ah=af.new(0,false)ah._state={complete=false,value=0,velocity=-5}local aj=ag.new(1,{frequency=2,dampingRatio=1})ah:setGoal(aj)ah:step(1.6666666666666665E-2)expect(ah._state.velocity<0).to.equal(true)end)end end,[45]=function()local aa,ab,ac,ad,ae=b(45)local af=function(af)local ag=tostring(af):match'^Motor%((.+)%)$'if ag then return true,ag else return false end end return af end,[46]=function()local aa,ab,ac,ad,ae=b(46)return function()local af,ag,ah=ac(ab.Parent.isMotor),ac(ab.Parent.SingleMotor),ac(ab.Parent.GroupMotor)local aj,c=ag.new(0),ah.new{}it('should properly detect motors',function()expect(af(aj)).to.equal(true)expect(af(c)).to.equal(true)end)it("shouldn't detect things that aren't motors",function()expect(af{}).to.equal(false)end)it('should return the proper motor type',function()local d,e=af(aj)local f,g=af(c)expect(e).to.equal'Single'expect(g).to.equal'Group'end)end end,[47]=function()local aa,ab,ac,ad,ae=b(47)local af={Names={'Dark','Darker','Light','Aqua','Amethyst','Rose'}}for ag,ah in next,ab:GetChildren()do local aj=ac(ah)af[aj.Name]=aj end return af end,[48]=function()local aa,ab,ac,ad,ae=b(48)return{Name='Amethyst',Accent=Color3.fromRGB(97,62,167),AcrylicMain=Color3.fromRGB(20,20,20),AcrylicBorder=Color3.fromRGB(110,90,130),AcrylicGradient=ColorSequence.new(Color3.fromRGB(85,57,139),Color3.fromRGB(40,25,65)),AcrylicNoise=0.92,TitleBarLine=Color3.fromRGB(95,75,110),Tab=Color3.fromRGB(160,140,180),Element=Color3.fromRGB(140,120,160),ElementBorder=Color3.fromRGB(60,50,70),InElementBorder=Color3.fromRGB(100,90,110),ElementTransparency=0.87,ToggleSlider=Color3.fromRGB(140,120,160),ToggleToggled=Color3.fromRGB(0,0,0),SliderRail=Color3.fromRGB(140,120,160),DropdownFrame=Color3.fromRGB(170,160,200),DropdownHolder=Color3.fromRGB(60,45,80),DropdownBorder=Color3.fromRGB(50,40,65),DropdownOption=Color3.fromRGB(140,120,160),Keybind=Color3.fromRGB(140,120,160),Input=Color3.fromRGB(140,120,160),InputFocused=Color3.fromRGB(20,10,30),InputIndicator=Color3.fromRGB(170,150,190),Dialog=Color3.fromRGB(60,45,80),DialogHolder=Color3.fromRGB(45,30,65),DialogHolderLine=Color3.fromRGB(40,25,60),DialogButton=Color3.fromRGB(60,45,80),DialogButtonBorder=Color3.fromRGB(95,80,110),DialogBorder=Color3.fromRGB(85,70,100),DialogInput=Color3.fromRGB(70,55,85),DialogInputLine=Color3.fromRGB(175,160,190),Text=Color3.fromRGB(240,240,240),SubText=Color3.fromRGB(170,170,170),Hover=Color3.fromRGB(140,120,160),HoverChange=0.04}end,[49]=function()local aa,ab,ac,ad,ae=b(49)return{Name='Aqua',Accent=Color3.fromRGB(60,165,165),AcrylicMain=Color3.fromRGB(20,20,20),AcrylicBorder=Color3.fromRGB(50,100,100),AcrylicGradient=ColorSequence.new(Color3.fromRGB(60,140,140),Color3.fromRGB(40,80,80)),AcrylicNoise=0.92,TitleBarLine=Color3.fromRGB(60,120,120),Tab=Color3.fromRGB(140,180,180),Element=Color3.fromRGB(110,160,160),ElementBorder=Color3.fromRGB(40,70,70),InElementBorder=Color3.fromRGB(80,110,110),ElementTransparency=0.84,ToggleSlider=Color3.fromRGB(110,160,160),ToggleToggled=Color3.fromRGB(0,0,0),SliderRail=Color3.fromRGB(110,160,160),DropdownFrame=Color3.fromRGB(160,200,200),DropdownHolder=Color3.fromRGB(40,80,80),DropdownBorder=Color3.fromRGB(40,65,65),DropdownOption=Color3.fromRGB(110,160,160),Keybind=Color3.fromRGB(110,160,160),Input=Color3.fromRGB(110,160,160),InputFocused=Color3.fromRGB(20,10,30),InputIndicator=Color3.fromRGB(130,170,170),Dialog=Color3.fromRGB(40,80,80),DialogHolder=Color3.fromRGB(30,60,60),DialogHolderLine=Color3.fromRGB(25,50,50),DialogButton=Color3.fromRGB(40,80,80),DialogButtonBorder=Color3.fromRGB(80,110,110),DialogBorder=Color3.fromRGB(50,100,100),DialogInput=Color3.fromRGB(45,90,90),DialogInputLine=Color3.fromRGB(130,170,170),Text=Color3.fromRGB(240,240,240),SubText=Color3.fromRGB(170,170,170),Hover=Color3.fromRGB(110,160,160),HoverChange=0.04}end,[50]=function()local aa,ab,ac,ad,ae=b(50)return{Name='Dark',Accent=Color3.fromRGB(96,205,255),AcrylicMain=Color3.fromRGB(60,60,60),AcrylicBorder=Color3.fromRGB(90,90,90),AcrylicGradient=ColorSequence.new(Color3.fromRGB(40,40,40),Color3.fromRGB(40,40,40)),AcrylicNoise=0.9,TitleBarLine=Color3.fromRGB(75,75,75),Tab=Color3.fromRGB(120,120,120),Element=Color3.fromRGB(120,120,120),ElementBorder=Color3.fromRGB(35,35,35),InElementBorder=Color3.fromRGB(90,90,90),ElementTransparency=0.87,ToggleSlider=Color3.fromRGB(120,120,120),ToggleToggled=Color3.fromRGB(0,0,0),SliderRail=Color3.fromRGB(120,120,120),DropdownFrame=Color3.fromRGB(160,160,160),DropdownHolder=Color3.fromRGB(45,45,45),DropdownBorder=Color3.fromRGB(35,35,35),DropdownOption=Color3.fromRGB(120,120,120),Keybind=Color3.fromRGB(120,120,120),Input=Color3.fromRGB(160,160,160),InputFocused=Color3.fromRGB(10,10,10),InputIndicator=Color3.fromRGB(150,150,150),Dialog=Color3.fromRGB(45,45,45),DialogHolder=Color3.fromRGB(35,35,35),DialogHolderLine=Color3.fromRGB(30,30,30),DialogButton=Color3.fromRGB(45,45,45),DialogButtonBorder=Color3.fromRGB(80,80,80),DialogBorder=Color3.fromRGB(70,70,70),DialogInput=Color3.fromRGB(55,55,55),DialogInputLine=Color3.fromRGB(160,160,160),Text=Color3.fromRGB(240,240,240),SubText=Color3.fromRGB(170,170,170),Hover=Color3.fromRGB(120,120,120),HoverChange=0.07}end,[51]=function()local aa,ab,ac,ad,ae=b(51)return{Name='Darker',Accent=Color3.fromRGB(72,138,182),AcrylicMain=Color3.fromRGB(30,30,30),AcrylicBorder=Color3.fromRGB(60,60,60),AcrylicGradient=ColorSequence.new(Color3.fromRGB(25,25,25),Color3.fromRGB(15,15,15)),AcrylicNoise=0.94,TitleBarLine=Color3.fromRGB(65,65,65),Tab=Color3.fromRGB(100,100,100),Element=Color3.fromRGB(70,70,70),ElementBorder=Color3.fromRGB(25,25,25),InElementBorder=Color3.fromRGB(55,55,55),ElementTransparency=0.82,DropdownFrame=Color3.fromRGB(120,120,120),DropdownHolder=Color3.fromRGB(35,35,35),DropdownBorder=Color3.fromRGB(25,25,25),Dialog=Color3.fromRGB(35,35,35),DialogHolder=Color3.fromRGB(25,25,25),DialogHolderLine=Color3.fromRGB(20,20,20),DialogButton=Color3.fromRGB(35,35,35),DialogButtonBorder=Color3.fromRGB(55,55,55),DialogBorder=Color3.fromRGB(50,50,50),DialogInput=Color3.fromRGB(45,45,45),DialogInputLine=Color3.fromRGB(120,120,120)}end,[52]=function()local aa,ab,ac,ad,ae=b(52)return{Name='Light',Accent=Color3.fromRGB(0,103,192),AcrylicMain=Color3.fromRGB(200,200,200),AcrylicBorder=Color3.fromRGB(120,120,120),AcrylicGradient=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255)),AcrylicNoise=0.96,TitleBarLine=Color3.fromRGB(160,160,160),Tab=Color3.fromRGB(90,90,90),Element=Color3.fromRGB(255,255,255),ElementBorder=Color3.fromRGB(180,180,180),InElementBorder=Color3.fromRGB(150,150,150),ElementTransparency=0.65,ToggleSlider=Color3.fromRGB(40,40,40),ToggleToggled=Color3.fromRGB(255,255,255),SliderRail=Color3.fromRGB(40,40,40),DropdownFrame=Color3.fromRGB(200,200,200),DropdownHolder=Color3.fromRGB(240,240,240),DropdownBorder=Color3.fromRGB(200,200,200),DropdownOption=Color3.fromRGB(150,150,150),Keybind=Color3.fromRGB(120,120,120),Input=Color3.fromRGB(200,200,200),InputFocused=Color3.fromRGB(100,100,100),InputIndicator=Color3.fromRGB(80,80,80),Dialog=Color3.fromRGB(255,255,255),DialogHolder=Color3.fromRGB(240,240,240),DialogHolderLine=Color3.fromRGB(228,228,228),DialogButton=Color3.fromRGB(255,255,255),DialogButtonBorder=Color3.fromRGB(190,190,190),DialogBorder=Color3.fromRGB(140,140,140),DialogInput=Color3.fromRGB(250,250,250),DialogInputLine=Color3.fromRGB(160,160,160),Text=Color3.fromRGB(0,0,0),SubText=Color3.fromRGB(40,40,40),Hover=Color3.fromRGB(50,50,50),HoverChange=0.16}end,[53]=function()local aa,ab,ac,ad,ae=b(53)return{Name='Rose',Accent=Color3.fromRGB(180,55,90),AcrylicMain=Color3.fromRGB(40,40,40),AcrylicBorder=Color3.fromRGB(130,90,110),AcrylicGradient=ColorSequence.new(Color3.fromRGB(190,60,135),Color3.fromRGB(165,50,70)),AcrylicNoise=0.92,TitleBarLine=Color3.fromRGB(140,85,105),Tab=Color3.fromRGB(180,140,160),Element=Color3.fromRGB(200,120,170),ElementBorder=Color3.fromRGB(110,70,85),InElementBorder=Color3.fromRGB(120,90,90),ElementTransparency=0.86,ToggleSlider=Color3.fromRGB(200,120,170),ToggleToggled=Color3.fromRGB(0,0,0),SliderRail=Color3.fromRGB(200,120,170),DropdownFrame=Color3.fromRGB(200,160,180),DropdownHolder=Color3.fromRGB(120,50,75),DropdownBorder=Color3.fromRGB(90,40,55),DropdownOption=Color3.fromRGB(200,120,170),Keybind=Color3.fromRGB(200,120,170),Input=Color3.fromRGB(200,120,170),InputFocused=Color3.fromRGB(20,10,30),InputIndicator=Color3.fromRGB(170,150,190),Dialog=Color3.fromRGB(120,50,75),DialogHolder=Color3.fromRGB(95,40,60),DialogHolderLine=Color3.fromRGB(90,35,55),DialogButton=Color3.fromRGB(120,50,75),DialogButtonBorder=Color3.fromRGB(155,90,115),DialogBorder=Color3.fromRGB(100,70,90),DialogInput=Color3.fromRGB(135,55,80),DialogInputLine=Color3.fromRGB(190,160,180),Text=Color3.fromRGB(240,240,240),SubText=Color3.fromRGB(170,170,170),Hover=Color3.fromRGB(200,120,170),HoverChange=0.04}end}do local ab,ac,ad,ae,af,ag,ah,aj,c,e,f,g,h,i,j,k=task,setmetatable,error,newproxy,getmetatable,next,table,unpack,coroutine,script,type,require,pcall,getfenv,setfenv,rawget local l,m,n,o,p,s,t,u,v,w,x=ah.insert,ah.remove,ah.freeze or function(l)return l end,ab and ab.defer or function(l,...)local m=c.create(l)c.resume(m,...)return m end,'0.0.0-venv',{},{},{},{},{},{}local y,z={GetChildren=function(y)local z,A=x[y],{}for B in ag,z do l(A,B)end return A end,FindFirstChild=function(y,z)if not z then ad('Argument 1 missing or nil',2)end for A in ag,x[y]do if A.Name==z then return A end end return end,GetFullName=function(y)local z,A=y.Name,y.Parent while A do z=A.Name..'.'..z A=A.Parent end return'VirtualEnv.'..z end},{}for A,B in ag,y do z[A]=function(C,...)if not x[C]then ad("Expected ':' not '.' calling member function "..A,1)end return B(C,...)end end local C=function(C,D,E)local F,G,H,I,J=ac({},{__mode='k'}),function(F)ad(F..' is not a valid (virtual) member of '..C..' "'..D..'"',1)end,function(F)ad('Unable to assign (virtual) property '..F..'. Property is read only',1)end,(ae(true))local K=af(I)K.__index=function(L,M)if M=='ClassName'then return C elseif M=='Name'then return D elseif M=='Parent'then return E elseif C=='StringValue'and M=='Value'then return J else local N=z[M]if N then return N end end for N in ag,F do if N.Name==M then return N end end G(M)end K.__newindex=function(L,M,N)if M=='ClassName'then H(M)elseif M=='Name'then D=N elseif M=='Parent'then if N==I then return end if E~=nil then x[E][I]=nil end E=N if N~=nil then x[N][I]=true end elseif C=='StringValue'and M=='Value'then J=N else G(M)end end K.__tostring=function()return D end x[I]=F if E~=nil then x[E][I]=true end return I end local function D(E,F)local G,H,I,J=E[1],E[2],E[3],E[4]local K=m(I,1)local L=C(H,K,F)s[G]=L if I then for M,N in ag,I do L[M]=N end end if J then for M,N in ag,J do D(N,L)end end return L end local E={}for F,G in ag,a do l(E,D(G))end for H,I in ag,aa do local J=s[H]t[J]=I local K=J.ClassName if K=='LocalScript'or K=='Script'then l(v,J)end end local J=function(J)local K,L=J.ClassName,u[J]if L and K=='ModuleScript'then return aj(L)end local M=t[J]if not M then return end if K=='LocalScript'or K=='Script'then M()return else local N={M()}u[J]=N return aj(N)end end function b(K)local L=s[K]local M=t[L]if not M then return end local N,O,P,Q,R,S,T=false,n{Version=p,Script=e,Shared=w,GetScript=function()return e end,GetShared=function()return w end},L,function(N,...)if x[N]and N.ClassName=='ModuleScript'and t[N]then return J(N)end return g(N,...)end local U,V=function(U,...)if not N then T()end if f(U)=='number'and U>=0 then if U==0 then return S else U=U+1 local V,W=h(i,U)if V and W==R then return S end end end return i(U,...)end,function(U,V,...)if not N then T()end if f(U)=='number'and U>=0 then if U==0 then return j(S,V)else U=U+1 local W,X=h(i,U)if W and X==R then return j(S,V)end end end return j(U,V,...)end function T()R=i(0)local W={maui=O,script=P,require=Q,getfenv=U,setfenv=V}S=ac({},{__index=function(X,Y)local Z=k(S,Y)if Z~=nil then return Z end local _=W[Y]if _~=nil then return _ end return R[Y]end})j(M,S)N=true end return O,P,Q,U,V end for K,L in ag,v do o(J,L)end do local M for N,O in ag,E do if O.ClassName=='ModuleScript'and O.Name=='MainModule'then M=O break end end if M then return J(M)end end end
]==========]

local RuntimeEnv = getgenv and getgenv() or _G
local storageFolder = "HaoToolHub"
local storageFile = storageFolder .. "/autoload.lua"
local fluentFile = storageFolder .. "/fluent.lua"
local sourceSaved = false

if makefolder then
    pcall(function()
        if not isfolder or not isfolder(storageFolder) then makefolder(storageFolder) end
    end)
end

if writefile then
    sourceSaved = pcall(function() writefile(storageFile, HAOTOOL_SOURCE) end)
    pcall(function() writefile(fluentFile, HAOTOOL_FLUENT_SOURCE) end)
end
RuntimeEnv.HAOTOOL_SOURCE_SAVED = sourceSaved
RuntimeEnv.HAOTOOL_EMBEDDED_FLUENT_SOURCE = HAOTOOL_FLUENT_SOURCE

local function failStartup(message)
    RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
    RuntimeEnv.HAOTOOL_RUNNING = nil
    RuntimeEnv.HAOTOOL_UI_READY = false
    RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = tostring(message)
    if type(RuntimeEnv.HAOTOOL_SHOW_STARTUP_ERROR) == "function" then
        pcall(RuntimeEnv.HAOTOOL_SHOW_STARTUP_ERROR, message)
    end
    if type(RuntimeEnv.HAOTOOL_DESTROY_UI) == "function" then
        pcall(RuntimeEnv.HAOTOOL_DESTROY_UI)
    end
    RuntimeEnv.HAOTOOL_TOGGLE_MENU = nil
    RuntimeEnv.HAOTOOL_DESTROY_UI = nil
end

local runner, compileError = loadstring(HAOTOOL_SOURCE)
if not runner then
    failStartup(compileError)
    warn("[HAOTOOL] Không biên dịch được tool: " .. tostring(compileError))
else
    local ok, runError = pcall(runner)
    if not ok then
        failStartup(runError)
        warn("[HAOTOOL] Tool gặp lỗi: " .. tostring(runError))
    elseif RuntimeEnv.HAOTOOL_UI_READY then
        RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = nil
    end
end
