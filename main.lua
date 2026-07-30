--[[
    ================================================================================
    ⚡ ANTIGRAVITY HUB | BLOX FRUITS (FULL SCRIPT ALL SEAS 1, 2, 3)
    --------------------------------------------------------------------------------
    Developer: Antigravity Team
    UI Library: Fluent UI (Ultra Modern, High Performance, Mobile & PC Friendly)
    Executors Supported: Synapse, Fluxus, Delta, Solara, Wave, CodeX, Hydrogen, Arceus X
    ================================================================================
--]]

-- Chờ game load hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Tải Thư viện Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Khởi tạo Cửa sổ chính (Window)
local Window = Fluent:CreateWindow({
    Title = "Antigravity Hub | Blox Fruits",
    SubTitle = "All-In-One Script v3.5 (Sea 1, 2, 3)",
    TabWidth = 150,
    Size = UDim2.fromOffset(590, 460),
    Acrylic = false, -- Tắt mờ acrylic để tối ưu FPS cho Mobile/Máy yếu
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- ==================== CÁC TAB GIAO DIỆN ====================
local Tabs = {
    Main = Window:AddTab({ Title = "Trang Chính", Icon = "home" }),
    Farm = Window:AddTab({ Title = "Auto Farm", Icon = "swords" }),
    Raid = Window:AddTab({ Title = "Auto Raid", Icon = "shield-alert" }),
    Fruit = Window:AddTab({ Title = "Trái Ác Quỷ", Icon = "apple" }),
    ESP = Window:AddTab({ Title = "Hệ Thống ESP", Icon = "eye" }),
    Teleport = Window:AddTab({ Title = "Dịch Chuyển", Icon = "map-pin" }),
    Misc = Window:AddTab({ Title = "Người Chơi & Hack", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "settings" })
}

-- ==================== BIẾN CẤU HÌNH HỆ THỐNG ====================
_G.AutoFarmLevel = false
_G.AutoFarmNearest = false
_G.AutoMastery = false
_G.AutoBoss = false
_G.SelectedBoss = ""
_G.SelectWeapon = "Melee"
_G.BringMob = true
_G.FastAttack = true
_G.AutoHaki = true
_G.AutoKen = false

-- Raid
_G.AutoRaid = false
_G.SelectedChip = "Flame"
_G.AutoBuyChip = false
_G.AutoStartRaid = false

-- Fruit
_G.AutoFruitFinder = false
_G.AutoPickFruit = false
_G.AutoStoreFruit = true
_G.AutoGachaFruit = false

-- Stats
_G.AutoStats = false
_G.StatToUpgrade = "Melee"
_G.StatPointsPerClick = 3

-- ESP
_G.ESPPlayer = false
_G.ESPMob = false
_G.ESPFruit = false
_G.ESPChest = false
_G.ESPFlower = false

-- Movement & Player
_G.WalkSpeedHack = false
_G.WalkSpeedVal = 50
_G.JumpPowerHack = false
_G.JumpPowerVal = 100
_G.InfiniteJump = false
_G.SelectedIsland = "Starter Island"

-- Services
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Nhận diện Sea 1, Sea 2 hay Sea 3
local PlaceId = game.PlaceId
local WorldSea = 1
if PlaceId == 2753915549 then
    WorldSea = 1
elseif PlaceId == 4442272183 then
    WorldSea = 2
elseif PlaceId == 7449423635 then
    WorldSea = 3
end

-- ==================== MOBILE FLOATING TOGGLE BUTTON ====================
local CoreGui = game:GetService("CoreGui")
local ExistingGui = CoreGui:FindFirstChild("AGMobileToggle") or Player.PlayerGui:FindFirstChild("AGMobileToggle")
if ExistingGui then ExistingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AGMobileToggle"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Player.PlayerGui end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleButton"
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
ToggleBtn.BorderColor3 = Color3.fromRGB(59, 130, 246)
ToggleBtn.BorderSizePixel = 2
ToggleBtn.Text = "AG"
ToggleBtn.TextColor3 = Color3.fromRGB(96, 165, 250)
ToggleBtn.Font = Enum.Font.FredokaOne
ToggleBtn.TextSize = 20
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = ToggleBtn

local guiEnabled = true
ToggleBtn.MouseButton1Click:Connect(function()
    guiEnabled = not guiEnabled
    Window:RootEnabled(guiEnabled)
end)

-- ==================== DỮ LIỆU QUEST & ĐẢO THEO SEA ====================

local IslandsSea1 = {
    ["Starter Island"] = Vector3.new(1059, 15, 1549),
    ["Jungle"] = Vector3.new(-1598, 36, 153),
    ["Pirate Village"] = Vector3.new(-1182, 4, 3851),
    ["Desert"] = Vector3.new(944, 6, 4373),
    ["Frozen Village"] = Vector3.new(1255, 6, -4246),
    ["Marine Fortress"] = Vector3.new(-5036, 24, 4317),
    ["Skyland"] = Vector3.new(-4839, 717, -2620),
    ["Prison"] = Vector3.new(4875, 5, 735),
    ["Colosseum"] = Vector3.new(-1516, 7, -2994),
    ["Magma Village"] = Vector3.new(-5241, 8, 8504),
    ["Underwater City"] = Vector3.new(61163, 11, 1819),
    ["Fountain City"] = Vector3.new(5121, 5, 4110)
}

local IslandsSea2 = {
    ["Kingdom of Rose"] = Vector3.new(-456, 73, 2999),
    ["Cafe"] = Vector3.new(-380, 73, 300),
    ["Ushron / Green Zone"] = Vector3.new(-2450, 73, -3200),
    ["Graveyard"] = Vector3.new(-5400, 48, -700),
    ["Snow Mountain"] = Vector3.new(800, 400, -5300),
    ["Cold Area"] = Vector3.new(-6000, 15, -5000),
    ["Hot Area"] = Vector3.new(-5200, 15, -5200),
    ["Cursed Ship"] = Vector3.new(900, 125, 3300),
    ["Ice Castle"] = Vector3.new(5800, 28, -6200),
    ["Forgotten Island"] = Vector3.new(-3050, 240, -10150)
}

local IslandsSea3 = {
    ["Port Town"] = Vector3.new(-290, 7, 5300),
    ["Hydra Island"] = Vector3.new(5700, 600, 200),
    ["Great Tree"] = Vector3.new(2300, 450, -7000),
    ["Floating Turtle"] = Vector3.new(-12500, 330, -7500),
    ["Castle on the Sea"] = Vector3.new(-5000, 315, -3000),
    ["Haunted Castle"] = Vector3.new(-9500, 140, 5500),
    ["Peanut Land"] = Vector3.new(-2000, 50, -10200),
    ["Ice Cream Land"] = Vector3.new(-900, 65, -11000),
    ["Chocolate Land"] = Vector3.new(200, 30, -12000),
    ["Tiki Outpost"] = Vector3.new(-16300, 9, 450)
}

local QuestsSea1 = {
    {MinLevel = 1, MaxLevel = 9, QuestName = "BanditQuest1", QuestNumber = 1, MobName = "Bandit", QuestNpc = Vector3.new(1059.3, 15.4, 1549.2), MobPosition = Vector3.new(1038.5, 16.4, 1621.8)},
    {MinLevel = 10, MaxLevel = 14, QuestName = "MonkeyQuest", QuestNumber = 1, MobName = "Monkey", QuestNpc = Vector3.new(-1598, 36.8, 153.2), MobPosition = Vector3.new(-1610, 36.8, 142)},
    {MinLevel = 15, MaxLevel = 29, QuestName = "MonkeyQuest", QuestNumber = 2, MobName = "Gorilla", QuestNpc = Vector3.new(-1598, 36.8, 153.2), MobPosition = Vector3.new(-1243, 6.2, -493)},
    {MinLevel = 30, MaxLevel = 39, QuestName = "PirateQuest", QuestNumber = 1, MobName = "Pirate", QuestNpc = Vector3.new(-1141, 4.7, 3896), MobPosition = Vector3.new(-1203, 4.7, 3915)},
    {MinLevel = 40, MaxLevel = 59, QuestName = "PirateQuest", QuestNumber = 2, MobName = "Brute", QuestNpc = Vector3.new(-1141, 4.7, 3896), MobPosition = Vector3.new(-1145, 14, 4300)},
    {MinLevel = 60, MaxLevel = 89, QuestName = "DesertQuest", QuestNumber = 1, MobName = "Desert Bandit", QuestNpc = Vector3.new(894, 6.4, 4390), MobPosition = Vector3.new(996, 6.4, 4363)},
    {MinLevel = 90, MaxLevel = 99, QuestName = "DesertQuest", QuestNumber = 2, MobName = "Desert Officer", QuestNpc = Vector3.new(894, 6.4, 4390), MobPosition = Vector3.new(1582, 10, 4370)},
    {MinLevel = 100, MaxLevel = 119, QuestName = "SnowQuest", QuestNumber = 1, MobName = "Snow Bandit", QuestNpc = Vector3.new(1385, 15, -4740), MobPosition = Vector3.new(1313, 26, -4641)},
    {MinLevel = 120, MaxLevel = 149, QuestName = "SnowQuest", QuestNumber = 2, MobName = "Snowman", QuestNpc = Vector3.new(1385, 15, -4740), MobPosition = Vector3.new(1250, 26, -4580)},
    {MinLevel = 150, MaxLevel = 174, QuestName = "SkyQuest", QuestNumber = 1, MobName = "Chief Petit", QuestNpc = Vector3.new(-4839, 717, -2620), MobPosition = Vector3.new(-4950, 717, -2620)},
    {MinLevel = 175, MaxLevel = 189, QuestName = "SkyQuest", QuestNumber = 2, MobName = "Sky Bandit", QuestNpc = Vector3.new(-4839, 717, -2620), MobPosition = Vector3.new(-4850, 717, -2750)},
    {MinLevel = 190, MaxLevel = 209, QuestName = "SkyQuest", QuestNumber = 3, MobName = "Dark Master", QuestNpc = Vector3.new(-4839, 717, -2620), MobPosition = Vector3.new(-5250, 390, -2250)},
    {MinLevel = 210, MaxLevel = 249, QuestName = "PrisonerQuest", QuestNumber = 1, MobName = "Prisoner", QuestNpc = Vector3.new(4875, 5, 735), MobPosition = Vector3.new(4940, 5, 800)},
    {MinLevel = 250, MaxLevel = 299, QuestName = "ColosseumQuest", QuestNumber = 1, MobName = "Toga Warrior", QuestNpc = Vector3.new(-1516, 7, -2994), MobPosition = Vector3.new(-1800, 7, -3000)},
    {MinLevel = 300, MaxLevel = 329, QuestName = "MagmaQuest", QuestNumber = 1, MobName = "Military Soldier", QuestNpc = Vector3.new(-5241, 8, 8504), MobPosition = Vector3.new(-5400, 8, 8500)},
    {MinLevel = 330, MaxLevel = 374, QuestName = "MagmaQuest", QuestNumber = 2, MobName = "Military Spy", QuestNpc = Vector3.new(-5241, 8, 8504), MobPosition = Vector3.new(-5800, 8, 8800)},
    {MinLevel = 375, MaxLevel = 399, QuestName = "FishmanQuest", QuestNumber = 1, MobName = "Fishman Warrior", QuestNpc = Vector3.new(61163, 11, 1819), MobPosition = Vector3.new(60800, 18, 1500)},
    {MinLevel = 400, MaxLevel = 449, QuestName = "FishmanQuest", QuestNumber = 2, MobName = "Fishman Commando", QuestNpc = Vector3.new(61163, 11, 1819), MobPosition = Vector3.new(61800, 18, 1500)},
    {MinLevel = 450, MaxLevel = 474, QuestName = "SkyExp1Quest", QuestNumber = 1, MobName = "God's Guard", QuestNpc = Vector3.new(-4720, 845, -1950), MobPosition = Vector3.new(-4700, 845, -1900)},
    {MinLevel = 475, MaxLevel = 524, QuestName = "SkyExp1Quest", QuestNumber = 2, MobName = "Shanda", QuestNpc = Vector3.new(-4720, 845, -1950), MobPosition = Vector3.new(-7700, 5600, -1800)},
    {MinLevel = 525, MaxLevel = 549, QuestName = "SkyExp2Quest", QuestNumber = 1, MobName = "Royal Squad", QuestNpc = Vector3.new(-7900, 5600, -1800), MobPosition = Vector3.new(-7600, 5600, -1400)},
    {MinLevel = 550, MaxLevel = 624, QuestName = "SkyExp2Quest", QuestNumber = 2, MobName = "Royal Soldier", QuestNpc = Vector3.new(-7900, 5600, -1800), MobPosition = Vector3.new(-7800, 5600, -1600)},
    {MinLevel = 625, MaxLevel = 649, QuestName = "FountainQuest", QuestNumber = 1, MobName = "Galley Pirate", QuestNpc = Vector3.new(5121, 5, 4110), MobPosition = Vector3.new(5500, 5, 4000)},
    {MinLevel = 650, MaxLevel = 700, QuestName = "FountainQuest", QuestNumber = 2, MobName = "Galley Captain", QuestNpc = Vector3.new(5121, 5, 4110), MobPosition = Vector3.new(5600, 5, 4400)}
}

local MeleeNames = {
    "Combat", "Black Leg", "Electro", "Fishman Karate", "Dragon Claw", 
    "Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", 
    "Dragon Talon", "Godhuman", "Sanguine Art"
}

-- ==================== CÁC HÀM TRỢ GIÚP (CORE FUNCTIONS) ====================

-- Noclip tự động khi farm
local noclipConn = nil
local function setNoclip(state)
    if state then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                local char = Player.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
    end
end

-- Bay tới mục tiêu mượt mà (Tween Flight)
local currentTween = nil
local function toTarget(targetCFrame)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = char.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    
    if distance < 15 then
        rootPart.CFrame = targetCFrame
        return
    end
    
    local speed = 280
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    
    setNoclip(true)
    currentTween = TweenService:Create(rootPart, {CFrame = targetCFrame}, tweenInfo)
    currentTween:Play()
    currentTween.Completed:Wait()
    setNoclip(false)
end

-- Tự động bật Buso Haki & Observation Ken Haki
local function checkHaki()
    local char = Player.Character
    if not char then return end
    
    if _G.AutoHaki and not char:FindFirstChild("HasBuso") then
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
    end
    
    if _G.AutoKen and not char:FindFirstChild("HasKen") then
        pcall(function()
            local kenRemote = ReplicatedStorage:FindFirstChild("Ken") or ReplicatedStorage.Remotes:FindFirstChild("Ken")
            if kenRemote then kenRemote:FireServer(true) end
        end)
    end
end

-- Tấn công đa phương thức (Đảm bảo hoạt động trên mọi Executor)
local function attack()
    checkHaki()
    
    local char = Player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end
    
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    VirtualUser:CaptureController()
    VirtualUser:Button1Down(Vector2.new(0, 0))
end

-- Trang bị vũ khí theo cài đặt
local function equipWeapon(weaponType)
    local backpack = Player.Backpack
    local char = Player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then
        if weaponType == "Melee" and (table.find(MeleeNames, equipped.Name) or equipped.ToolTip == "Melee") then return end
        if weaponType == "Blox Fruit" and (equipped.ToolTip == "Blox Fruit" or equipped.Name:find("Fruit")) then return end
        if weaponType == "Sword" and (equipped.ToolTip == "Sword" or not table.find(MeleeNames, equipped.Name)) then return end
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local match = false
            if weaponType == "Melee" and (table.find(MeleeNames, tool.Name) or tool.ToolTip == "Melee") then match = true end
            if weaponType == "Blox Fruit" and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit")) then match = true end
            if weaponType == "Sword" and (tool.ToolTip == "Sword" or (not table.find(MeleeNames, tool.Name) and not tool.Name:find("Fruit"))) then match = true end
            
            if match then
                char.Humanoid:EquipTool(tool)
                return
            end
        end
    end
    
    local fallbackTool = backpack:FindFirstChildOfClass("Tool")
    if fallbackTool then char.Humanoid:EquipTool(fallbackTool) end
end

-- Gom quái vật lại gần (Bring Mob)
local function bringMobsNear(targetName, centerCFrame)
    if not _G.BringMob or not workspace:FindFirstChild("Enemies") then return end
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob.Name == targetName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            if (mob.HumanoidRootPart.Position - centerCFrame.Position).Magnitude <= 350 then
                mob.HumanoidRootPart.CFrame = centerCFrame
                mob.HumanoidRootPart.CanCollide = false
                mob.Humanoid.WalkSpeed = 0
            end
        end
    end
end

-- Lấy thông tin Quest phù hợp theo Level hiện tại
local function getQuestData(level)
    for _, data in ipairs(QuestsSea1) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return QuestsSea1[1]
end

-- Lấy danh sách tên quái vật hiện có xung quanh
local function getEnemyList()
    local enemies = {}
    if workspace:FindFirstChild("Enemies") then
        for _, mob in pairs(workspace.Enemies:GetChildren()) do
            if mob:FindFirstChild("Humanoid") and not table.find(enemies, mob.Name) then
                table.insert(enemies, mob.Name)
            end
        end
    end
    if #enemies == 0 then
        return {"Bandit", "Monkey", "Gorilla", "Pirate", "Desert Bandit", "Snow Bandit", "Galley Pirate"}
    end
    return enemies
end

-- Lấy danh sách tên Boss đang spawn trên bản đồ
local function getBossList()
    local bosses = {}
    if workspace:FindFirstChild("Enemies") then
        for _, mob in pairs(workspace.Enemies:GetChildren()) do
            if mob:FindFirstChild("Humanoid") and mob.Humanoid.MaxHealth > 5000 and not table.find(bosses, mob.Name) then
                table.insert(bosses, mob.Name)
            end
        end
    end
    if #bosses == 0 then
        return {"The Gorilla King", "Bobby", "Yeti", "Vice Admiral", "Swan", "Magma Admiral", "Fishman Lord"}
    end
    return bosses
end

-- ==================== VÒNG LẶP NỀN (BACKGROUND TASKS) ====================

-- 1. Auto Farm Level
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoFarmLevel then
            pcall(function()
                local level = Player.Data.Level.Value
                local quest = getQuestData(level)
                
                local questGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible
                
                if not hasQuest then
                    toTarget(CFrame.new(quest.QuestNpc))
                    task.wait(0.3)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", quest.QuestName, quest.QuestNumber)
                else
                    local targetMob = nil
                    if workspace:FindFirstChild("Enemies") then
                        for _, mob in pairs(workspace.Enemies:GetChildren()) do
                            if mob.Name == quest.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                                targetMob = mob
                                break
                            end
                        end
                    end
                    
                    if not targetMob then
                        toTarget(CFrame.new(quest.MobPosition))
                    else
                        equipWeapon(_G.SelectWeapon)
                        local char = Player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") and targetMob:FindFirstChild("HumanoidRootPart") then
                            setNoclip(true)
                            local farmPos = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                            char.HumanoidRootPart.CFrame = CFrame.new(farmPos.Position, targetMob.HumanoidRootPart.Position)
                            
                            if _G.BringMob then bringMobsNear(quest.MobName, targetMob.HumanoidRootPart.CFrame) end
                            attack()
                        end
                    end
                end
            end)
        else
            setNoclip(false)
        end
    end
end)

-- 2. Auto Farm Quái Gần Nhất (Nearest Mob Farm)
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoFarmNearest then
            pcall(function()
                local char = Player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                
                local nearestMob = nil
                local minDistance = math.huge
                
                if workspace:FindFirstChild("Enemies") then
                    for _, mob in pairs(workspace.Enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                            local dist = (mob.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                            if dist < minDistance then
                                minDistance = dist
                                nearestMob = mob
                            end
                        end
                    end
                end
                
                if nearestMob then
                    equipWeapon(_G.SelectWeapon)
                    setNoclip(true)
                    local farmPos = nearestMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                    char.HumanoidRootPart.CFrame = CFrame.new(farmPos.Position, nearestMob.HumanoidRootPart.Position)
                    attack()
                else
                    task.wait(0.5)
                end
            end)
        end
    end
end)

-- 3. Auto Farm Boss
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoBoss and _G.SelectedBoss ~= "" then
            pcall(function()
                local bossMob = nil
                if workspace:FindFirstChild("Enemies") then
                    for _, mob in pairs(workspace.Enemies:GetChildren()) do
                        if mob.Name == _G.SelectedBoss and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            bossMob = mob
                            break
                        end
                    end
                end
                
                if bossMob then
                    equipWeapon(_G.SelectWeapon)
                    local char = Player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and bossMob:FindFirstChild("HumanoidRootPart") then
                        setNoclip(true)
                        local farmPos = bossMob.HumanoidRootPart.CFrame * CFrame.new(0, 8, 0)
                        char.HumanoidRootPart.CFrame = CFrame.new(farmPos.Position, bossMob.HumanoidRootPart.Position)
                        attack()
                    end
                else
                    Fluent:Notify({ Title = "Auto Boss", Content = "Không tìm thấy Boss " .. _G.SelectedBoss .. "!", Duration = 3 })
                    task.wait(4)
                end
            end)
        end
    end
end)

-- 4. Auto Raid (Tự Động Mua Chip & Đi Raid)
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoRaid then
            pcall(function()
                -- 1. Auto Buy Chip
                if _G.AutoBuyChip then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.SelectedChip)
                end
                -- 2. Auto Start Raid
                if _G.AutoStartRaid then
                    fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.ClickDetector)
                end
                -- 3. Auto Farm Waves in Raid Dungeon
                local raidIsland = workspace:FindFirstChild("RaidIslands")
                if raidIsland then
                    for _, mob in pairs(workspace.Enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                            equipWeapon(_G.SelectWeapon)
                            local char = Player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                                attack()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Stats
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.AutoStats then
            pcall(function()
                local points = Player.Data.Points.Value
                if points > 0 then
                    local amount = math.min(points, _G.StatPointsPerClick or 3)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.StatToUpgrade, amount)
                end
            end)
        end
    end
end)

-- 6. Auto Fruit Finder, Auto Store & Gacha
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoFruitFinder or _G.AutoPickFruit then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                        Fluent:Notify({
                            Title = "Phát Hiện Trái Ác Quỷ! 🍎",
                            Content = "Tìm thấy: " .. obj.Name,
                            SubContent = "Đang di chuyển tới nhặt...",
                            Duration = 6
                        })
                        if _G.AutoPickFruit and obj:FindFirstChild("Handle") then
                            toTarget(obj.Handle.CFrame)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
        
        if _G.AutoStoreFruit then
            pcall(function()
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:find("Fruit") then
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", tool.Name, tool)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if _G.AutoGachaFruit then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            end)
            task.wait(15)
        end
    end
end)

-- 7. Movement Hacks & Anti AFK
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            if _G.WalkSpeedHack then
                char.Humanoid.WalkSpeed = _G.WalkSpeedVal
            end
            if _G.JumpPowerHack then
                char.Humanoid.JumpPower = _G.JumpPowerVal
            end
        end
    end)
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = Player.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end
end)

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- ==================== HỆ THỐNG ESP (VISUALS) ====================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "AntigravityESP"
ESPFolder.Parent = CoreGui

local function clearESP()
    ESPFolder:ClearAllChildren()
end

task.spawn(function()
    while true do
        task.wait(1)
        if _G.ESPPlayer or _G.ESPMob or _G.ESPFruit or _G.ESPChest or _G.ESPFlower then
            clearESP()
            pcall(function()
                -- 1. Player ESP
                if _G.ESPPlayer then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local bgui = Instance.new("BillboardGui")
                            bgui.Parent = ESPFolder
                            bgui.Adornee = p.Character.HumanoidRootPart
                            bgui.Size = UDim2.new(0, 100, 0, 30)
                            bgui.AlwaysOnTop = true
                            
                            local text = Instance.new("TextLabel")
                            text.Parent = bgui
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.Text = "[Player] " .. p.Name
                            text.TextColor3 = Color3.fromRGB(0, 255, 200)
                            text.Font = Enum.Font.SourceSansBold
                            text.TextSize = 14
                        end
                    end
                end
                
                -- 2. Fruit ESP
                if _G.ESPFruit then
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                            local bgui = Instance.new("BillboardGui")
                            bgui.Parent = ESPFolder
                            bgui.Adornee = obj:FindFirstChild("Handle") or obj
                            bgui.Size = UDim2.new(0, 120, 0, 30)
                            bgui.AlwaysOnTop = true
                            
                            local text = Instance.new("TextLabel")
                            text.Parent = bgui
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.Text = "🍎 " .. obj.Name
                            text.TextColor3 = Color3.fromRGB(255, 100, 100)
                            text.Font = Enum.Font.SourceSansBold
                            text.TextSize = 15
                        end
                    end
                end
                
                -- 3. Chest ESP
                if _G.ESPChest then
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("Part") and obj.Name:lower():find("chest") then
                            local bgui = Instance.new("BillboardGui")
                            bgui.Parent = ESPFolder
                            bgui.Adornee = obj
                            bgui.Size = UDim2.new(0, 100, 0, 25)
                            bgui.AlwaysOnTop = true
                            
                            local text = Instance.new("TextLabel")
                            text.Parent = bgui
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.Text = "📦 Chest"
                            text.TextColor3 = Color3.fromRGB(255, 215, 0)
                            text.Font = Enum.Font.SourceSansBold
                            text.TextSize = 13
                        end
                    end
                end
            end)
        else
            clearESP()
        end
    end
end)

-- ==================== CẤU HÌNH CÁC TAB FLUENT ====================

-- 1. TAB TRANG CHÍNH (MAIN)
Tabs.Main:AddParagraph({
    Title = "Chào mừng tới Antigravity Hub! 🚀",
    Content = "Script hỗ trợ tự động Farm Level, Boss, Raid, Trái Ác Quỷ tối ưu mượt mà cho mọi Executor."
})

Tabs.Main:AddToggle("AutoFarmLevel", {
    Title = "Auto Farm Level (Tự Động Làm Quest)",
    Default = false,
    Callback = function(Value) _G.AutoFarmLevel = Value end
})

Tabs.Main:AddToggle("BringMob", {
    Title = "Gom Quái Lại Gần (Bring Mob)",
    Default = true,
    Callback = function(Value) _G.BringMob = Value end
})

Tabs.Main:AddDropdown("SelectWeapon", {
    Title = "Vũ Khí Sử Dụng",
    Values = {"Melee", "Sword", "Blox Fruit"},
    Default = "Melee",
    Callback = function(Value) _G.SelectWeapon = Value end
})

Tabs.Main:AddToggle("AutoHaki", {
    Title = "Tự Động Bật Haki Vũ Trang (Buso)",
    Default = true,
    Callback = function(Value) _G.AutoHaki = Value end
})

Tabs.Main:AddToggle("AutoKen", {
    Title = "Tự Động Bật Haki Quan Sát (Ken)",
    Default = false,
    Callback = function(Value) _G.AutoKen = Value end
})

-- 2. TAB AUTO FARM SPECIALTY
Tabs.Farm:AddSection("Farm Nâng Cao & Boss")

Tabs.Farm:AddToggle("AutoFarmNearest", {
    Title = "Auto Farm Quái Gần Nhất",
    Default = false,
    Callback = function(Value) _G.AutoFarmNearest = Value end
})

local bossOptions = getBossList()
local BossDropdown = Tabs.Farm:AddDropdown("SelectedBoss", {
    Title = "Chọn Boss Cần Farm",
    Values = bossOptions,
    Default = bossOptions[1] or "",
    Callback = function(Value) _G.SelectedBoss = Value end
})

Tabs.Farm:AddButton({
    Title = "Làm Mới Danh Sách Boss Spawn",
    Callback = function()
        local newBosses = getBossList()
        BossDropdown:SetValues(newBosses)
        Fluent:Notify({ Title = "Thông Báo", Content = "Đã cập nhật danh sách Boss!", Duration = 3 })
    end
})

Tabs.Farm:AddToggle("AutoBoss", {
    Title = "Auto Săn Boss Đã Chọn",
    Default = false,
    Callback = function(Value) _G.AutoBoss = Value end
})

Tabs.Farm:AddSection("Tự Động Cộng Điểm Potential Stats")

Tabs.Farm:AddToggle("AutoStats", {
    Title = "Tự Động Cộng Điểm Stats",
    Default = false,
    Callback = function(Value) _G.AutoStats = Value end
})

Tabs.Farm:AddDropdown("StatToUpgrade", {
    Title = "Chọn Chỉ Số Cộng",
    Values = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"},
    Default = "Melee",
    Callback = function(Value)
        _G.StatToUpgrade = (Value == "Demon Fruit" and "Blox Fruit" or Value)
    end
})

Tabs.Farm:AddSlider("StatPointsPerClick", {
    Title = "Số Điểm Cộng Mỗi Lần",
    Min = 1,
    Max = 10,
    Default = 3,
    Rounding = 1,
    Callback = function(Value) _G.StatPointsPerClick = Value end
})

-- 3. TAB AUTO RAID
Tabs.Raid:AddSection("Auto Raid Dungeon")

Tabs.Raid:AddDropdown("SelectedChip", {
    Title = "Chọn Loại Chip Raid",
    Values = {"Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble", "Magma", "Human: Buddha", "Sand"},
    Default = "Flame",
    Callback = function(Value) _G.SelectedChip = Value end
})

Tabs.Raid:AddToggle("AutoBuyChip", {
    Title = "Tự Động Mua Chip Raid",
    Default = false,
    Callback = function(Value) _G.AutoBuyChip = Value end
})

Tabs.Raid:AddToggle("AutoStartRaid", {
    Title = "Tự Động Nhấn Bắt Đầu Raid",
    Default = false,
    Callback = function(Value) _G.AutoStartRaid = Value end
})

Tabs.Raid:AddToggle("AutoRaid", {
    Title = "Bật Tự Động Đi Raid & Cleared Waves",
    Default = false,
    Callback = function(Value) _G.AutoRaid = Value end
})

-- 4. TAB TRÁI ÁC QUỶ (FRUIT)
Tabs.Fruit:AddSection("Săn & Mua Trái Ác Quỷ")

Tabs.Fruit:AddToggle("AutoFruitFinder", {
    Title = "Thông Báo Khi Trái Spawn (Fruit Finder)",
    Default = true,
    Callback = function(Value) _G.AutoFruitFinder = Value end
})

Tabs.Fruit:AddToggle("AutoPickFruit", {
    Title = "Tự Động Bay Tới Nhặt Trái",
    Default = false,
    Callback = function(Value) _G.AutoPickFruit = Value end
})

Tabs.Fruit:AddToggle("AutoStoreFruit", {
    Title = "Tự Động Cất Trái Vào Kho (Store Fruit)",
    Default = true,
    Callback = function(Value) _G.AutoStoreFruit = Value end
})

Tabs.Fruit:AddToggle("AutoGachaFruit", {
    Title = "Tự Động Mua Trái Ngẫu Nhiên (Random Fruit)",
    Default = false,
    Callback = function(Value) _G.AutoGachaFruit = Value end
})

-- 5. TAB ESP VISUALS
Tabs.ESP:AddSection("Hệ Thống Nhìn Xuyên Vật Cản (ESP)")

Tabs.ESP:AddToggle("ESPPlayer", {
    Title = "ESP Người Chơi",
    Default = false,
    Callback = function(Value) _G.ESPPlayer = Value end
})

Tabs.ESP:AddToggle("ESPFruit", {
    Title = "ESP Trái Ác Quỷ",
    Default = false,
    Callback = function(Value) _G.ESPFruit = Value end
})

Tabs.ESP:AddToggle("ESPChest", {
    Title = "ESP Rương Beli",
    Default = false,
    Callback = function(Value) _G.ESPChest = Value end
})

-- 6. TAB DỊCH CHUYỂN (TELEPORT)
Tabs.Teleport:AddSection("Dịch Chuyển Đảo Sea " .. WorldSea)

local currentIslands = (WorldSea == 1 and IslandsSea1) or (WorldSea == 2 and IslandsSea2) or IslandsSea3
local islandList = {}
for name, _ in pairs(currentIslands) do table.insert(islandList, name) end
table.sort(islandList)

Tabs.Teleport:AddDropdown("SelectedIsland", {
    Title = "Chọn Đảo Đích Đến",
    Values = islandList,
    Default = islandList[1] or "",
    Callback = function(Value) _G.SelectedIsland = Value end
})

Tabs.Teleport:AddButton({
    Title = "✈️ Bay Tới Đảo Đã Chọn",
    Callback = function()
        local pos = currentIslands[_G.SelectedIsland]
        if pos then
            Fluent:Notify({ Title = "Dịch Chuyển", Content = "Đang bay tới " .. _G.SelectedIsland, Duration = 4 })
            toTarget(CFrame.new(pos))
        end
    end
})

-- 7. TAB MISC & MOVEMENT HACK
Tabs.Misc:AddSection("Hack Di Chuyển & Tối Ưu Game")

Tabs.Misc:AddToggle("WalkSpeedHack", {
    Title = "Bật Tăng Tốc Độ Chạy (WalkSpeed)",
    Default = false,
    Callback = function(Value) _G.WalkSpeedHack = Value end
})

Tabs.Misc:AddSlider("WalkSpeedVal", {
    Title = "Tốc Độ Chạy",
    Min = 16,
    Max = 200,
    Default = 50,
    Rounding = 1,
    Callback = function(Value) _G.WalkSpeedVal = Value end
})

Tabs.Misc:AddToggle("JumpPowerHack", {
    Title = "Bật Tăng Sức Nhảy (JumpPower)",
    Default = false,
    Callback = function(Value) _G.JumpPowerHack = Value end
})

Tabs.Misc:AddSlider("JumpPowerVal", {
    Title = "Sức Nhảy",
    Min = 50,
    Max = 300,
    Default = 100,
    Rounding = 1,
    Callback = function(Value) _G.JumpPowerVal = Value end
})

Tabs.Misc:AddToggle("InfiniteJump", {
    Title = "Nhảy Không Giới Hạn (Infinite Jump)",
    Default = false,
    Callback = function(Value) _G.InfiniteJump = Value end
})

Tabs.Misc:AddButton({
    Title = "⚡ Tối Ưu FPS (Xóa Texture Giảm Lag)",
    Callback = function()
        pcall(function()
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                    obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                end
            end
        end)
        Fluent:Notify({ Title = "Tối Ưu FPS", Content = "Đã xóa Texture giúp mượt game!", Duration = 3 })
    end
})

-- 8. TAB SETTINGS
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Antigravity Hub Loaded! 🚀",
    Content = "Nhấn nút 'AG' màu xanh trên màn hình hoặc phím RightControl để Bật/Tắt Menu GUI!",
    Duration = 6
})

SaveManager:LoadAutoloadConfig()
