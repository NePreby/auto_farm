--[[
    Blox Fruits Auto Farm & Helper Script for Delta X
    Developed by Antigravity - Professional Game Developer
    Library: Rayfield UI (Tối ưu tuyệt đối cho Delta X & Mobile Executing)
--]]

-- Khởi tạo Rayfield Library (Thư viện UI hiện đại, mượt mà và hỗ trợ Delta X tốt nhất)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Antigravity Hub | Blox Fruits",
   LoadingTitle = "Antigravity Blox Fruits",
   LoadingSubtitle = "by Antigravity Developer",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AntigravityHub",
      FileName = "BloxFruitsConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = false
})

-- ==================== BIẾN CẤU HÌNH (SETTINGS) ====================
_G.AutoFarm = false
_G.AutoFarmSelectedMob = false
_G.SelectedMobName = ""
_G.AutoFarmChest = false
_G.SelectWeapon = "Melee" 

_G.AutoStats = false
_G.StatToUpgrade = "Melee" 

_G.AutoFruit = false
_G.AutoGacha = false

_G.SelectedIsland = "Starter Island"

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local TweenService = game:GetService("TweenService")

Player.CharacterAdded:Connect(function(char)
    Character = char
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

-- Bảng thông tin Quest theo cấp độ (Sea 1)
local QuestsData = {
    {MinLevel = 1, MaxLevel = 9, QuestName = "BanditQuest1", QuestNumber = 1, MobName = "Bandit", QuestNpc = Vector3.new(1059.3, 15.4, 1549.2), MobPosition = Vector3.new(1038.5, 16.4, 1621.8)},
    {MinLevel = 10, MaxLevel = 14, QuestName = "MonkeyQuest", QuestNumber = 1, MobName = "Monkey", QuestNpc = Vector3.new(-1598, 36.8, 153.2), MobPosition = Vector3.new(-1610, 36.8, 142)},
    {MinLevel = 15, MaxLevel = 29, QuestName = "MonkeyQuest", QuestNumber = 2, MobName = "Gorilla", QuestNpc = Vector3.new(-1598, 36.8, 153.2), MobPosition = Vector3.new(-1243, 6.2, -493)},
    {MinLevel = 30, MaxLevel = 59, QuestName = "PirateQuest", QuestNumber = 1, MobName = "Pirate", QuestNpc = Vector3.new(-1141, 4.7, 3896), MobPosition = Vector3.new(-1203, 4.7, 3915)},
    {MinLevel = 60, MaxLevel = 89, QuestName = "DesertQuest", QuestNumber = 1, MobName = "Desert Bandit", QuestNpc = Vector3.new(894, 6.4, 4390), MobPosition = Vector3.new(996, 6.4, 4363)},
    {MinLevel = 90, MaxLevel = 119, QuestName = "SnowQuest", QuestNumber = 1, MobName = "Snow Bandit", QuestNpc = Vector3.new(1385, 15, -4740), MobPosition = Vector3.new(1313, 26, -4641)}
}

-- ==================== CÁC HÀM TRỢ GIÚP (HELPER FUNCTIONS) ====================

local function toTarget(targetCFrame)
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local speed = 250
    
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, {CFrame = targetCFrame}, tweenInfo)
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
    
    tween:Play()
    tween.Completed:Wait()
end

local function attack()
    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(850, 520))
end

local function equipWeapon(weaponType)
    local backpack = Player.Backpack
    local character = Player.Character
    if not character then return end
    
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == weaponType then
            return
        end
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == weaponType then
            character.Humanoid:EquipTool(tool)
            return
        end
    end
end

local function getQuestData(level)
    for _, data in ipairs(QuestsData) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return QuestsData[1]
end

local function getEnemyList()
    local enemies = {}
    for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and not table.find(enemies, mob.Name) then
            table.insert(enemies, mob.Name)
        end
    end
    if #enemies == 0 then
        return {"Bandit", "Monkey", "Gorilla", "Pirate", "Desert Bandit", "Snow Bandit"}
    end
    return enemies
end

-- ==================== LUỒNG CHẠY HỆ THỐNG (TASKS) ====================

-- 1. Auto Farm Level
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm then
            local currentLevel = Player.Data.Level.Value
            local quest = getQuestData(currentLevel)
            
            local hasQuest = Player.PlayerGui.Main.Quest.Visible
            if not hasQuest then
                toTarget(CFrame.new(quest.QuestNpc))
                task.wait(0.5)
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest", quest.QuestName, quest.QuestNumber)
            else
                local targetMob = nil
                for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
                    if mob.Name == quest.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        targetMob = mob
                        break
                    end
                end
                
                if not targetMob then
                    toTarget(CFrame.new(quest.MobPosition))
                else
                    equipWeapon(_G.SelectWeapon)
                    local character = Player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") and targetMob:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.CFrame = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 8, 0)
                        attack()
                    end
                end
            end
        end
    end
end)

-- 2. Auto Farm Quái Chỉ Định
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarmSelectedMob and _G.SelectedMobName ~= "" then
            local targetMob = nil
            for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
                if mob.Name == _G.SelectedMobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    targetMob = mob
                    break
                end
            end
            
            if targetMob then
                equipWeapon(_G.SelectWeapon)
                local character = Player.Character
                if character and character:FindFirstChild("HumanoidRootPart") and targetMob:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 8, 0)
                    attack()
                end
            else
                task.wait(0.5)
            end
        end
    end
end)

-- 3. Auto Farm Rương
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarmChest then
            local targetChest = nil
            for _, obj in pairs(game.Workspace:GetChildren()) do
                if obj.Name:find("Chest") and obj:IsA("Part") then
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
                    Content = "Không tìm thấy rương nào trên bản đồ hiện tại.",
                    Duration = 2,
                    Image = 4483363465,
                })
                task.wait(2)
            end
        end
    end
end)

-- 4. Auto Stats
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoStats then
            local points = Player.Data.Points.Value
            if points > 0 then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", _G.StatToUpgrade, 1)
            end
        end
    end
end)

-- 5. Auto Fruit Finder
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoFruit then
            for _, obj in pairs(game.Workspace:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                    Rayfield:Notify({
                        Title = "Fruit Finder",
                        Content = "Đã tìm thấy: " .. obj.Name .. ". Dịch chuyển ngay!",
                        Duration = 5,
                        Image = 4483363465,
                    })
                    if obj:FindFirstChild("Handle") then
                        toTarget(obj.Handle.CFrame)
                        task.wait(1)
                    end
                end
            end
        end
    end
end)

-- 6. Auto Gacha Fruit
task.spawn(function()
    while true do
        task.wait(5)
        if _G.AutoGacha then
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Cousin", "Buy")
            task.wait(10)
        end
    end
end)

-- ==================== GIAO DIỆN CHỌN CHỨC NĂNG (RAYFIELD UI) ====================

-- 1. TAB AUTO FARM
local FarmTab = Window:CreateTab("Auto Farm", 4483363465)
FarmTab:CreateSection("Tự Động Farm Level & Quái")

FarmTab:CreateToggle({
   Name = "Auto Farm Level",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
      _G.AutoFarm = Value
   end,
})

local enemyList = getEnemyList()
local MobDropdown = FarmTab:CreateDropdown({
   Name = "Chọn Quái Để Farm",
   Options = enemyList,
   CurrentOption = {enemyList[1] or "Bandit"},
   MultipleOptions = false,
   Flag = "MobDropdown",
   Callback = function(Option)
      _G.SelectedMobName = type(Option) == "table" and Option[1] or Option
   end,
})

FarmTab:CreateButton({
   Name = "Làm Mới Danh Sách Quái",
   Callback = function()
      local newList = getEnemyList()
      MobDropdown:Refresh(newList, true)
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

FarmTab:CreateDropdown({
   Name = "Chọn Vũ Khí Sử Dụng",
   Options = {"Melee", "Sword", "Blox Fruit"},
   CurrentOption = {"Melee"},
   MultipleOptions = false,
   Flag = "WeaponDropdown",
   Callback = function(Option)
      _G.SelectWeapon = type(Option) == "table" and Option[1] or Option
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Farm Rương (Beli)",
   CurrentValue = false,
   Flag = "AutoChest",
   Callback = function(Value)
      _G.AutoFarmChest = Value
   end,
})

-- 2. TAB DỊCH CHUYỂN
local TeleportTab = Window:CreateTab("Dịch Chuyển", 4483363465)
TeleportTab:CreateSection("Chọn Đảo Cần Bay Tới")

local islandNames = {}
for name, _ in pairs(IslandsData) do
    table.insert(islandNames, name)
end

TeleportTab:CreateDropdown({
   Name = "Chọn Đảo Đích",
   Options = islandNames,
   CurrentOption = {"Starter Island"},
   MultipleOptions = false,
   Flag = "IslandDropdown",
   Callback = function(Option)
      _G.SelectedIsland = type(Option) == "table" and Option[1] or Option
   end,
})

TeleportTab:CreateButton({
   Name = "Bắt Đầu Bay Tới Đảo",
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
local StatsTab = Window:CreateTab("Chỉ Số (Stats)", 4483363465)
StatsTab:CreateSection("Tự Động Nâng Điểm Tiềm Năng")

StatsTab:CreateToggle({
   Name = "Tự Động Cộng Điểm",
   CurrentValue = false,
   Flag = "AutoStats",
   Callback = function(Value)
      _G.AutoStats = Value
   end,
})

StatsTab:CreateDropdown({
   Name = "Chọn Chỉ Số Ưu Tiên",
   Options = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"},
   CurrentOption = {"Melee"},
   MultipleOptions = false,
   Flag = "StatDropdown",
   Callback = function(Option)
      _G.StatToUpgrade = type(Option) == "table" and Option[1] or Option
   end,
})

-- 4. TAB TRÁI ÁC QUỶ (FRUITS)
local FruitTab = Window:CreateTab("Trái Ác Quỷ", 4483363465)
FruitTab:CreateSection("Trợ Năng Trái Ác Quỷ")

FruitTab:CreateToggle({
   Name = "Auto Tìm Trái Ác Quỷ (Fruit Finder)",
   CurrentValue = false,
   Flag = "AutoFruit",
   Callback = function(Value)
      _G.AutoFruit = Value
   end,
})

FruitTab:CreateToggle({
   Name = "Auto Gacha Fruit (Dealer Cousin)",
   CurrentValue = false,
   Flag = "AutoGacha",
   Callback = function(Value)
      _G.AutoGacha = Value
   end,
})

-- 5. TAB HỆ THỐNG
local SystemTab = Window:CreateTab("Hệ Thống", 4483363465)
SystemTab:CreateSection("Tối Ưu Game & Anti-AFK")

SystemTab:CreateButton({
   Name = "Tối Ưu FPS (Làm Mượt)",
   Callback = function()
      for _, obj in pairs(game:GetDescendants()) do
          if obj:IsA("BasePart") or obj:IsA("MeshPart") then
              obj.Material = Enum.Material.SmoothPlastic
          elseif obj:IsA("Decal") or obj:IsA("Texture") then
              obj:Destroy()
          end
      end
      Rayfield:Notify({
          Title = "Tối Ưu Hóa",
          Content = "Đã bật chế độ mượt FPS!",
          Duration = 3,
          Image = 4483363465,
      })
   end,
})

SystemTab:CreateButton({
   Name = "Sao Chép Link Discord",
   Callback = function()
      setclipboard("https://discord.gg/antigravity-hub")
      Rayfield:Notify({
          Title = "Hệ thống",
          Content = "Đã sao chép link Discord vào Clipboard!",
          Duration = 3,
          Image = 4483363465,
      })
   end,
})

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

Rayfield:LoadConfiguration()
