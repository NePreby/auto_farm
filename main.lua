--[[
    Blox Fruits Auto Farm & Helper Script (Mobile Optimized for Delta X / Arceus / Hydrogen / CodeX)
    Developer: Antigravity
    Interface: Modern Mobile UI with Floating Toggle & High Contrast
--]]

-- Fast Load & Error Prevention
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ==================== LIBRARY & UI SETUP ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ Antigravity Hub | Blox Fruits (Sea 1)",
   LoadingTitle = "Antigravity Hub Loading...",
   LoadingSubtitle = "Tối ưu hóa cho Delta X & Mobile",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AntigravityHub",
      FileName = "BloxFruitsSea1Config"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = false,
   Theme = "Ocean" -- Vibrant high-contrast dark theme (Easy to see on mobile)
})

-- ==================== GLOBAL VARIABLES & SETTINGS ====================
_G.AutoFarm = false
_G.AutoFarmSelectedMob = false
_G.SelectedMobName = ""
_G.AutoFarmChest = false
_G.SelectWeapon = "Melee" 
_G.FastAttack = true
_G.BringMob = true
_G.AutoHaki = true

_G.AutoStats = false
_G.StatToUpgrade = "Melee" 
_G.StatPointsPerClick = 3

_G.AutoFruit = false
_G.AutoGacha = false
_G.AutoStoreFruit = true

_G.SelectedIsland = "Starter Island"

-- Services & References
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

-- ==================== MOBILE FLOATING TOGGLE BUTTON ====================
-- Tạo nút tròn nổi trên màn hình để ẩn/hiện Menu dễ dàng trên Mobile (Delta X)
local CoreGui = game:GetService("CoreGui")
local ExistingGui = CoreGui:FindFirstChild("AntigravityMobileToggle") or Player.PlayerGui:FindFirstChild("AntigravityMobileToggle")
if ExistingGui then ExistingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntigravityMobileToggle"
ScreenGui.ResetOnSpawn = false

-- Thử vào CoreGui, nếu không có quyền thì dùng PlayerGui
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = Player.PlayerGui
end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleButton"
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 55, 0, 55)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.25, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
ToggleBtn.BorderColor3 = Color3.fromRGB(0, 200, 255)
ToggleBtn.BorderSizePixel = 2
ToggleBtn.Text = "AG"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
ToggleBtn.Font = Enum.Font.FredokaOne
ToggleBtn.TextSize = 22
ToggleBtn.Active = true
ToggleBtn.Draggable = true -- Có thể kéo thả trên màn hình mobile

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = ToggleBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 200)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleBtn

local menuVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    menuVisible = not menuVisible
    if Rayfield.Window then
        -- Toggle Rayfield Main UI visibility
        for _, gui in pairs(CoreGui:GetChildren()) do
            if gui.Name == "Rayfield" or gui:FindFirstChild("Main") then
                gui.Enabled = menuVisible
            end
        end
        for _, gui in pairs(Player.PlayerGui:GetChildren()) do
            if gui.Name == "Rayfield" or gui:FindFirstChild("Main") then
                gui.Enabled = menuVisible
            end
        end
    end
end)

-- ==================== DANH SÁCH ĐẢO VÀ TỌA ĐỘ (SEA 1) ====================
local IslandsData = {
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

-- Bảng thông tin Quest đầy đủ theo cấp độ (Sea 1: Level 1 -> 700)
local QuestsData = {
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

-- Danh sách vũ khí Melee phổ biến Blox Fruits
local MeleeNames = {
    "Combat", "Black Leg", "Electro", "Fishman Karate", "Dragon Claw", 
    "Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", 
    "Dragon Talon", "Godhuman", "Sanguine Art"
}

-- ==================== CÁC HÀM TRỢ GIÚP (HELPER FUNCTIONS) ====================

-- Noclip tự động khi di chuyển / farm
local noclipConnection = nil
local function enableNoclip(state)
    if state then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
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
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

-- Di chuyển mượt mà tới vị trí đích (Tween Flight)
local currentTween = nil
local function toTarget(targetCFrame)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = char.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    
    -- Nếu đã ở rất gần thì CFrame trực tiếp
    if distance < 15 then
        rootPart.CFrame = targetCFrame
        return
    end
    
    local speed = 280 -- Tốc độ bay an toàn chống nảy/kick
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    
    enableNoclip(true)
    currentTween = TweenService:Create(rootPart, {CFrame = targetCFrame}, tweenInfo)
    currentTween:Play()
    currentTween.Completed:Wait()
    enableNoclip(false)
end

-- Tự động kích hoạt Buso Haki
local function checkAndEnableHaki()
    if not _G.AutoHaki then return end
    local char = Player.Character
    if char and not char:FindFirstChild("HasBuso") then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end)
    end
end

-- Đánh quái đa phương thức (Hoạt động 100% trên Mobile & PC)
local function attack()
    checkAndEnableHaki()
    
    -- 1. Kích hoạt tool đang cầm
    local char = Player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
    end
    
    -- 2. Click ảo tương thích mọi độ phân giải màn hình
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    
    VirtualUser:CaptureController()
    VirtualUser:Button1Down(Vector2.new(0, 0))
end

-- Trang bị vũ khí thông minh (Smart Weapon Equip)
local function equipWeapon(weaponType)
    local backpack = Player.Backpack
    local char = Player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    
    -- Kiểm tra nếu đã cầm đúng loại vũ khí
    local currentlyEquipped = char:FindFirstChildOfClass("Tool")
    if currentlyEquipped then
        if weaponType == "Melee" and (table.find(MeleeNames, currentlyEquipped.Name) or currentlyEquipped.ToolTip == "Melee") then
            return
        elseif weaponType == "Blox Fruit" and (currentlyEquipped.ToolTip == "Blox Fruit" or currentlyEquipped.Name:find("Fruit")) then
            return
        elseif weaponType == "Sword" and (currentlyEquipped.ToolTip == "Sword" or not table.find(MeleeNames, currentlyEquipped.Name)) then
            return
        end
    end
    
    -- Tìm vũ khí trong Backpack
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local isMatch = false
            if weaponType == "Melee" then
                if table.find(MeleeNames, tool.Name) or tool.ToolTip == "Melee" then
                    isMatch = true
                end
            elseif weaponType == "Blox Fruit" then
                if tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit") then
                    isMatch = true
                end
            elseif weaponType == "Sword" then
                if tool.ToolTip == "Sword" or (not table.find(MeleeNames, tool.Name) and not tool.Name:find("Fruit")) then
                    isMatch = true
                end
            end
            
            if isMatch then
                char.Humanoid:EquipTool(tool)
                return
            end
        end
    end
    
    -- Fallback: Trang bị bất kỳ Tool đầu tiên tìm thấy nếu không khớp loại
    local firstTool = backpack:FindFirstChildOfClass("Tool")
    if firstTool then
        char.Humanoid:EquipTool(firstTool)
    end
end

-- Lấy Quest phù hợp theo Level
local function getQuestData(level)
    for _, data in ipairs(QuestsData) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return QuestsData[1]
end

-- Lấy danh sách quái vật hiện có xung quanh
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

-- Gom quái lại gần (Bring Mob / Magnet Mobs)
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

-- ==================== HỆ THỐNG VÒNG LẶP (TASKS) ====================

-- 1. Auto Farm Level (Thông minh & Ổn định)
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoFarm then
            pcall(function()
                local level = Player.Data.Level.Value
                local quest = getQuestData(level)
                
                -- Kiểm tra nhận nhiệm vụ
                local questGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible
                
                if not hasQuest then
                    toTarget(CFrame.new(quest.QuestNpc))
                    task.wait(0.3)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", quest.QuestName, quest.QuestNumber)
                else
                    -- Tìm quái mục tiêu
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
                            enableNoclip(true)
                            -- Đặt vị trí phía trên đầu quái 7 studs và quay mặt xuống quái
                            local farmPos = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                            char.HumanoidRootPart.CFrame = CFrame.new(farmPos.Position, targetMob.HumanoidRootPart.Position)
                            
                            if _G.BringMob then
                                bringMobsNear(quest.MobName, targetMob.HumanoidRootPart.CFrame)
                            end
                            
                            attack()
                        end
                    end
                end
            end)
        else
            enableNoclip(false)
        end
    end
end)

-- 2. Auto Farm Quái Chỉ Định
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoFarmSelectedMob and _G.SelectedMobName ~= "" then
            pcall(function()
                local targetMob = nil
                if workspace:FindFirstChild("Enemies") then
                    for _, mob in pairs(workspace.Enemies:GetChildren()) do
                        if mob.Name == _G.SelectedMobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            targetMob = mob
                            break
                        end
                    end
                end
                
                if targetMob then
                    equipWeapon(_G.SelectWeapon)
                    local char = Player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and targetMob:FindFirstChild("HumanoidRootPart") then
                        enableNoclip(true)
                        local farmPos = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
                        char.HumanoidRootPart.CFrame = CFrame.new(farmPos.Position, targetMob.HumanoidRootPart.Position)
                        
                        if _G.BringMob then
                            bringMobsNear(_G.SelectedMobName, targetMob.HumanoidRootPart.CFrame)
                        end
                        
                        attack()
                    end
                else
                    task.wait(0.5)
                end
            end)
        end
    end
end)

-- 3. Auto Farm Rương (Beli Chest Farm)
task.spawn(function()
    while true do
        task.wait(0.1)
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
                    task.wait(0.2)
                else
                    Rayfield:Notify({
                        Title = "Chest Farm",
                        Content = "Không tìm thấy rương nào trên bản đồ!",
                        Duration = 2,
                        Image = 4483363465,
                    })
                    task.wait(3)
                end
            end)
        end
    end
end)

-- 4. Auto Stats (Tự động cộng điểm tiềm năng nhanh)
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.AutoStats then
            pcall(function()
                local points = Player.Data.Points.Value
                if points > 0 then
                    local addAmount = math.min(points, _G.StatPointsPerClick or 3)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.StatToUpgrade, addAmount)
                end
            end)
        end
    end
end)

-- 5. Auto Fruit Finder & Auto Store Fruit
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoFruit then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                        Rayfield:Notify({
                            Title = "Fruit Finder 🍎",
                            Content = "Đã phát hiện: " .. obj.Name .. "! Đang bay tới nhặt...",
                            Duration = 5,
                            Image = 4483363465,
                        })
                        if obj:FindFirstChild("Handle") then
                            toTarget(obj.Handle.CFrame)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
        
        -- Cất trái ác quỷ vào kho tự động
        if _G.AutoStoreFruit then
            pcall(function()
                local backpack = Player.Backpack
                for _, tool in pairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:find("Fruit") then
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", tool.Name, tool)
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Gacha Fruit (Mua trái ngẫu nhiên)
task.spawn(function()
    while true do
        task.wait(5)
        if _G.AutoGacha then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            end)
            task.wait(10)
        end
    end
end)

-- ==================== GIAO DIỆN RAYFIELD UI (VIBRANT & MOBILE FRIENDLY) ====================

-- 1. TAB AUTO FARM
local FarmTab = Window:CreateTab("🌾 Auto Farm", 4483363465)
FarmTab:CreateSection("Cấu Hình Farm Level & Quái")

FarmTab:CreateToggle({
   Name = "Auto Farm Level (Tự Động Làm Quest)",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
      _G.AutoFarm = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Gom Quái Lại Gần (Bring Mob)",
   CurrentValue = true,
   Flag = "BringMob",
   Callback = function(Value)
      _G.BringMob = Value
   end,
})

FarmTab:CreateDropdown({
   Name = "Chọn Vũ Khí Đánh Quái",
   Options = {"Melee", "Sword", "Blox Fruit"},
   CurrentOption = {"Melee"},
   MultipleOptions = false,
   Flag = "WeaponDropdown",
   Callback = function(Option)
      _G.SelectWeapon = type(Option) == "table" and Option[1] or Option
   end,
})

FarmTab:CreateSection("Farm Quái Chỉ Định")

local enemyList = getEnemyList()
local MobDropdown = FarmTab:CreateDropdown({
   Name = "Chọn Loại Quái Cần Farm",
   Options = enemyList,
   CurrentOption = {enemyList[1] or "Bandit"},
   MultipleOptions = false,
   Flag = "MobDropdown",
   Callback = function(Option)
      _G.SelectedMobName = type(Option) == "table" and Option[1] or Option
   end,
})

FarmTab:CreateButton({
   Name = "🔄 Làm Mới Danh Sách Quái",
   Callback = function()
      local newList = getEnemyList()
      MobDropdown:Refresh(newList, true)
      Rayfield:Notify({
          Title = "Thông báo",
          Content = "Đã cập nhật danh sách quái vật!",
          Duration = 2,
          Image = 4483363465,
      })
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Farm Quái Đã Chọn",
   CurrentValue = false,
   Flag = "AutoFarmMob",
   Callback = function(Value)
      _G.AutoFarmSelectedMob = Value
   end,
})

FarmTab:CreateSection("Thu Thập Beli & Rương")

FarmTab:CreateToggle({
   Name = "Auto Farm Rương (Nhặt Beli)",
   CurrentValue = false,
   Flag = "AutoChest",
   Callback = function(Value)
      _G.AutoFarmChest = Value
   end,
})

-- 2. TAB DỊCH CHUYỂN
local TeleportTab = Window:CreateTab("🚀 Dịch Chuyển", 4483363465)
TeleportTab:CreateSection("Bay Tới Các Đảo (Sea 1)")

local islandNames = {}
for name, _ in pairs(IslandsData) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

TeleportTab:CreateDropdown({
   Name = "Chọn Đảo Đích Đến",
   Options = islandNames,
   CurrentOption = {"Starter Island"},
   MultipleOptions = false,
   Flag = "IslandDropdown",
   Callback = function(Option)
      _G.SelectedIsland = type(Option) == "table" and Option[1] or Option
   end,
})

TeleportTab:CreateButton({
   Name = "✈️ Bắt Đầu Bay Tới Đảo",
   Callback = function()
      local targetPos = IslandsData[_G.SelectedIsland]
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

-- 3. TAB CHỈ SỐ (STATS)
local StatsTab = Window:CreateTab("📊 Chỉ Số Stats", 4483363465)
StatsTab:CreateSection("Tự Động Nâng Điểm Tiềm Năng")

StatsTab:CreateToggle({
   Name = "Tự Động Cộng Điểm Stats",
   CurrentValue = false,
   Flag = "AutoStats",
   Callback = function(Value)
      _G.AutoStats = Value
   end,
})

StatsTab:CreateDropdown({
   Name = "Chọn Chỉ Số Ưu Tiên",
   Options = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"},
   CurrentOption = {"Melee"},
   MultipleOptions = false,
   Flag = "StatDropdown",
   Callback = function(Option)
      local val = type(Option) == "table" and Option[1] or Option
      if val == "Demon Fruit" then val = "Blox Fruit" end
      _G.StatToUpgrade = val
   end,
})

StatsTab:CreateSlider({
   Name = "Số Điểm Cộng Mỗi Lần",
   Range = {1, 10},
   Increment = 1,
   Suffix = "Điểm",
   CurrentValue = 3,
   Flag = "StatAmountSlider",
   Callback = function(Value)
      _G.StatPointsPerClick = Value
   end,
})

-- 4. TAB TRÁI ÁC QUỶ (FRUITS)
local FruitTab = Window:CreateTab("🍎 Trái Ác Quỷ", 4483363465)
FruitTab:CreateSection("Săn & Mua Trái Ác Quỷ")

FruitTab:CreateToggle({
   Name = "Auto Tìm Trái Rơi (Fruit Finder)",
   CurrentValue = false,
   Flag = "AutoFruit",
   Callback = function(Value)
      _G.AutoFruit = Value
   end,
})

FruitTab:CreateToggle({
   Name = "Auto Mua Trái Ngẫu Nhiên (Random Fruit Gacha)",
   CurrentValue = false,
   Flag = "AutoGacha",
   Callback = function(Value)
      _G.AutoGacha = Value
   end,
})

FruitTab:CreateToggle({
   Name = "Tự Động Cất Trái Vào Kho (Store Fruit)",
   CurrentValue = true,
   Flag = "AutoStoreFruit",
   Callback = function(Value)
      _G.AutoStoreFruit = Value
   end,
})

-- 5. TAB HỆ THỐNG
local SystemTab = Window:CreateTab("⚙️ Hệ Thống Mobile", 4483363465)
SystemTab:CreateSection("Tối Ưu FPS & Giảm Lag Mobile")

SystemTab:CreateToggle({
   Name = "Tự Động Bật Haki Vũ Trang (Auto Buso)",
   CurrentValue = true,
   Flag = "AutoHaki",
   Callback = function(Value)
      _G.AutoHaki = Value
   end,
})

SystemTab:CreateButton({
   Name = "⚡ Tối Ưu FPS (Xóa Texture Giảm Lag)",
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
          Title = "Tối Ưu Hóa",
          Content = "Đã bật chế độ siêu mượt FPS!",
          Duration = 3,
          Image = 4483363465,
      })
   end,
})

SystemTab:CreateButton({
   Name = "📋 Sao Chép Link Discord Hub",
   Callback = function()
      pcall(function()
          setclipboard("https://discord.gg/antigravity-hub")
      end)
      Rayfield:Notify({
          Title = "Hệ thống",
          Content = "Đã sao chép link Discord vào Clipboard!",
          Duration = 3,
          Image = 4483363465,
      })
   end,
})

-- Anti-AFK Chống Disconnect Sau 20 Phút
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

Rayfield:Notify({
    Title = "Antigravity Hub Loaded! 🚀",
    Content = "Bấm nút 'AG' màu xanh trên màn hình để Bật/Tắt Menu!",
    Duration = 5,
    Image = 4483363465,
})

Rayfield:LoadConfiguration()
