--[[
    ================================================================================
    ⚡ HAOTOOL | BLOX FRUITS
    --------------------------------------------------------------------------------
    Developer: HAOTOOL Team
    UI: Rayfield (Đã kiểm chứng hoạt động 100% trên Delta X, Fluxus, Solara)
    FIX: Không dùng VirtualUser/VirtualInputManager trong attack() 
         => GUI KHÔNG bị đơ khi bật farm
    ================================================================================
--]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Nhận diện Sea
local PlaceId = game.PlaceId
local WorldSea = 1
if PlaceId == 2753915549 then WorldSea = 1
elseif PlaceId == 4442272183 then WorldSea = 2
elseif PlaceId == 7449423635 then WorldSea = 3 end

-- ==================== RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ HAOTOOL | Blox Fruits (Sea " .. WorldSea .. ")",
   LoadingTitle = "HAOTOOL Loading...",
   LoadingSubtitle = "Tối ưu cho Mobile & PC",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "HaoToolHub",
      FileName = "BloxFruitsConfig"
   },
   Discord = { Enabled = false, Invite = "", RememberJoins = false },
   KeySystem = false,
   Theme = "Ocean"
})

-- ==================== BIẾN CẤU HÌNH ====================
_G.AutoFarmLevel = false
_G.SelectWeapon = "Melee"
_G.BringMob = false
_G.AutoHaki = true
_G.AutoKen = false

_G.AutoFarmChest = false

_G.AutoStats = false
_G.StatToUpgrade = "Melee"

_G.AutoFruitFinder = false
_G.AutoPickFruit = false
_G.AutoGachaFruit = false

_G.WalkSpeedHack = false
_G.WalkSpeedVal = 50
_G.JumpPowerHack = false
_G.JumpPowerVal = 100
_G.InfiniteJump = false

_G.SelectedIsland = "Starter Island"

-- ==================== DATA ====================
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

-- ==================== HÀM XỬ LÝ GAME ====================

-- Noclip
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

-- Bay tới mục tiêu
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
    setNoclip(true)
    local tween = TweenService:Create(rootPart, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    setNoclip(false)
end

-- Haki
local function checkHaki()
    local char = Player.Character
    if not char then return end
    if _G.AutoHaki and not char:FindFirstChild("HasBuso") then
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
    end
    if _G.AutoKen and not char:FindFirstChild("HasKen") then
        pcall(function()
            local ken = ReplicatedStorage.Remotes:FindFirstChild("Ken")
            if ken then ken:FireServer(true) end
        end)
    end
end

-- *** ĐÁNH QUÁI AN TOÀN ***
-- CHỈ dùng tool:Activate() — KHÔNG dùng VirtualUser hay VirtualInputManager
-- Lý do: VirtualUser:CaptureController() và SendMouseButtonEvent chiếm quyền
-- input toàn cục của Roblox => khiến người chơi không bấm được GUI nữa
local function attack()
    checkHaki()
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

-- Trang bị vũ khí
local function equipWeapon(weaponType)
    local backpack = Player.Backpack
    local char = Player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end

    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then
        if weaponType == "Melee" and (table.find(MeleeNames, equipped.Name) or equipped.ToolTip == "Melee") then return end
        if weaponType == "Blox Fruit" and (equipped.ToolTip == "Blox Fruit" or equipped.Name:find("Fruit")) then return end
        if weaponType == "Sword" and equipped.ToolTip == "Sword" then return end
    end

    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local match = false
            if weaponType == "Melee" and (table.find(MeleeNames, tool.Name) or tool.ToolTip == "Melee") then match = true end
            if weaponType == "Blox Fruit" and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit")) then match = true end
            if weaponType == "Sword" and tool.ToolTip == "Sword" then match = true end
            if match then
                char.Humanoid:EquipTool(tool)
                return
            end
        end
    end

    local fallback = backpack:FindFirstChildOfClass("Tool")
    if fallback then char.Humanoid:EquipTool(fallback) end
end

-- Gom quái
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

-- Quest data
local function getQuestData(level)
    for _, data in ipairs(QuestsSea1) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return QuestsSea1[1]
end

-- Danh sách quái
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
        return {"Bandit", "Monkey", "Gorilla", "Pirate", "Desert Bandit", "Snow Bandit"}
    end
    return enemies
end

-- ==================== VÒNG LẶP NỀN ====================

-- Auto Farm Level
task.spawn(function()
    while true do
        task.wait(0.15) -- 0.15s cho GUI kịp xử lý touch/click
        if _G.AutoFarmLevel then
            pcall(function()
                local level = Player.Data.Level.Value
                local quest = getQuestData(level)

                local questGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible

                if not hasQuest then
                    toTarget(CFrame.new(quest.QuestNpc))
                    task.wait(0.5)
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
                            char.HumanoidRootPart.CFrame = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
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

-- Auto Farm Chest
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoFarmChest then
            pcall(function()
                local targetChest = nil
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Part") and obj.Name:lower():find("chest") then
                        targetChest = obj
                        break
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

-- Auto Stats
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoStats then
            pcall(function()
                local points = Player.Data.Points.Value
                if points > 0 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.StatToUpgrade, 3)
                end
            end)
        end
    end
end)

-- Auto Fruit Finder
task.spawn(function()
    while true do
        task.wait(2)
        if _G.AutoFruitFinder or _G.AutoPickFruit then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                        Rayfield:Notify({
                            Title = "Trái Ác Quỷ!",
                            Content = "Phát hiện: " .. obj.Name,
                            Duration = 5,
                            Image = 4483363465,
                        })
                        if _G.AutoPickFruit and obj:FindFirstChild("Handle") then
                            toTarget(obj.Handle.CFrame)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Gacha
task.spawn(function()
    while true do
        task.wait(8)
        if _G.AutoGachaFruit then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            end)
        end
    end
end)

-- WalkSpeed / JumpPower
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            if _G.WalkSpeedHack then char.Humanoid.WalkSpeed = _G.WalkSpeedVal end
            if _G.JumpPowerHack then char.Humanoid.JumpPower = _G.JumpPowerVal end
        end
    end)
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = Player.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end
end)

-- Anti-AFK
Player.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

-- ==================== TAB GIAO DIỆN RAYFIELD ====================

-- TAB 1: AUTO FARM
local FarmTab = Window:CreateTab("Auto Farm", 4483363465)
FarmTab:CreateSection("Farm Level Tự Động")

FarmTab:CreateToggle({
   Name = "Auto Farm Level (Làm Quest)",
   CurrentValue = false,
   Flag = "AutoFarmLevel",
   Callback = function(Value)
      _G.AutoFarmLevel = Value
   end,
})

FarmTab:CreateDropdown({
   Name = "Chọn Vũ Khí",
   Options = {"Melee", "Sword", "Blox Fruit"},
   CurrentOption = {"Melee"},
   MultipleOptions = false,
   Flag = "WeaponDropdown",
   Callback = function(Option)
      _G.SelectWeapon = type(Option) == "table" and Option[1] or Option
   end,
})

FarmTab:CreateToggle({
   Name = "Gom Quái Lại Gần (Bring Mob)",
   CurrentValue = false,
   Flag = "BringMob",
   Callback = function(Value)
      _G.BringMob = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Buso Haki",
   CurrentValue = true,
   Flag = "AutoHaki",
   Callback = function(Value)
      _G.AutoHaki = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Ken Haki",
   CurrentValue = false,
   Flag = "AutoKen",
   Callback = function(Value)
      _G.AutoKen = Value
   end,
})

FarmTab:CreateSection("Thu Thập Beli")

FarmTab:CreateToggle({
   Name = "Auto Farm Rương (Beli)",
   CurrentValue = false,
   Flag = "AutoChest",
   Callback = function(Value)
      _G.AutoFarmChest = Value
   end,
})

-- TAB 2: DỊCH CHUYỂN
local TeleportTab = Window:CreateTab("Dịch Chuyển", 4483363465)
TeleportTab:CreateSection("Bay Tới Đảo (Sea " .. WorldSea .. ")")

local islandNames = {}
for name, _ in pairs(IslandsSea1) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

TeleportTab:CreateDropdown({
   Name = "Chọn Đảo",
   Options = islandNames,
   CurrentOption = {"Starter Island"},
   MultipleOptions = false,
   Flag = "IslandDropdown",
   Callback = function(Option)
      _G.SelectedIsland = type(Option) == "table" and Option[1] or Option
   end,
})

TeleportTab:CreateButton({
   Name = "Bay Tới Đảo Đã Chọn",
   Callback = function()
      local targetPos = IslandsSea1[_G.SelectedIsland]
      if targetPos then
          Rayfield:Notify({
              Title = "Dịch Chuyển",
              Content = "Đang bay tới " .. _G.SelectedIsland,
              Duration = 3,
              Image = 4483363465,
          })
          toTarget(CFrame.new(targetPos))
      end
   end,
})

-- TAB 3: CHỈ SỐ STATS
local StatsTab = Window:CreateTab("Chỉ Số Stats", 4483363465)
StatsTab:CreateSection("Tự Động Cộng Điểm")

StatsTab:CreateToggle({
   Name = "Auto Cộng Điểm Stats",
   CurrentValue = false,
   Flag = "AutoStats",
   Callback = function(Value)
      _G.AutoStats = Value
   end,
})

StatsTab:CreateDropdown({
   Name = "Chỉ Số Ưu Tiên",
   Options = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"},
   CurrentOption = {"Melee"},
   MultipleOptions = false,
   Flag = "StatDropdown",
   Callback = function(Option)
      _G.StatToUpgrade = type(Option) == "table" and Option[1] or Option
   end,
})

-- TAB 4: TRÁI ÁC QUỶ
local FruitTab = Window:CreateTab("Trái Ác Quỷ", 4483363465)
FruitTab:CreateSection("Săn Trái Ác Quỷ")

FruitTab:CreateToggle({
   Name = "Thông Báo Khi Trái Spawn",
   CurrentValue = false,
   Flag = "AutoFruit",
   Callback = function(Value)
      _G.AutoFruitFinder = Value
   end,
})

FruitTab:CreateToggle({
   Name = "Auto Bay Tới Nhặt Trái",
   CurrentValue = false,
   Flag = "AutoPickFruit",
   Callback = function(Value)
      _G.AutoPickFruit = Value
   end,
})

FruitTab:CreateToggle({
   Name = "Auto Mua Trái Ngẫu Nhiên (Gacha)",
   CurrentValue = false,
   Flag = "AutoGacha",
   Callback = function(Value)
      _G.AutoGachaFruit = Value
   end,
})

-- TAB 5: HỆ THỐNG
local MiscTab = Window:CreateTab("Hệ Thống", 4483363465)
MiscTab:CreateSection("Hack Di Chuyển")

MiscTab:CreateToggle({
   Name = "Tăng Tốc Chạy (WalkSpeed)",
   CurrentValue = false,
   Flag = "WalkSpeedHack",
   Callback = function(Value)
      _G.WalkSpeedHack = Value
   end,
})

MiscTab:CreateSlider({
   Name = "Tốc Độ Chạy",
   Range = {16, 200},
   Increment = 1,
   Suffix = " Speed",
   CurrentValue = 50,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
      _G.WalkSpeedVal = Value
   end,
})

MiscTab:CreateToggle({
   Name = "Tăng Sức Nhảy (JumpPower)",
   CurrentValue = false,
   Flag = "JumpPowerHack",
   Callback = function(Value)
      _G.JumpPowerHack = Value
   end,
})

MiscTab:CreateSlider({
   Name = "Sức Nhảy",
   Range = {50, 300},
   Increment = 1,
   Suffix = " Power",
   CurrentValue = 100,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
      _G.JumpPowerVal = Value
   end,
})

MiscTab:CreateToggle({
   Name = "Nhảy Vô Hạn (Infinite Jump)",
   CurrentValue = false,
   Flag = "InfiniteJump",
   Callback = function(Value)
      _G.InfiniteJump = Value
   end,
})

MiscTab:CreateSection("Tối Ưu Game")

MiscTab:CreateButton({
   Name = "Tối Ưu FPS (Xóa Texture)",
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
      Rayfield:Notify({
          Title = "Tối Ưu FPS",
          Content = "Đã xóa texture giảm lag!",
          Duration = 3,
          Image = 4483363465,
      })
   end,
})

-- Load cấu hình đã lưu
Rayfield:LoadConfiguration()
