--[[
    Blox Fruits Auto Farm & Helper Script for Delta X
    Developed by Antigravity - Professional Game Developer
    
    Tính năng:
    - Auto Farm Level (Tự nhận quest, tự dịch chuyển, tự đánh)
    - Auto Farm Quái Chỉ Định (Chọn quái thủ công trong menu)
    - Auto Farm Rương (Nhặt rương vàng/bạc quanh bản đồ)
    - Auto Stats (Tự nâng điểm chỉ số)
    - Auto Fruit Finder (Dịch chuyển nhặt trái ác quỷ khi xuất hiện)
    - Teleport (Di chuyển qua các đảo bằng Menu chọn đảo)
    - Auto Gacha Fruit (Tự mua trái ngẫu nhiên từ Blox Fruit Dealer Cousin)
    - Anti-AFK (Tránh bị ngắt kết nối khi treo máy)
--]]

-- Khởi tạo Orion Library (UI thân thiện với thiết bị di động / Delta Executor)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Antigravity Hub | Blox Fruits UI", HidePremium = false, SaveConfig = true, ConfigFolder = "AntigravityBloxFruits"})

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

-- Đảm bảo Character luôn cập nhật
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

-- Hàm dịch chuyển Tween mượt mà tránh Anticheat
local function toTarget(targetCFrame)
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local speed = 250 -- Tốc độ chạy an toàn
    
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, {CFrame = targetCFrame}, tweenInfo)
    
    -- Tắt va chạm trong khi bay để không bị kẹt tường/núi
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
    
    tween:Play()
    tween.Completed:Wait()
end

-- Tự động đánh (Virtual Click)
local function attack()
    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(850, 520))
end

-- Tự trang bị vũ khí
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

-- Nhận thông tin nhiệm vụ dựa theo cấp độ
local function getQuestData(level)
    for _, data in ipairs(QuestsData) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return QuestsData[1]
end

-- Tìm danh sách quái có trong server hiện tại để đưa vào menu chọn quái
local function getEnemyList()
    local enemies = {}
    for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and not table.find(enemies, mob.Name) then
            table.insert(enemies, mob.Name)
        end
    end
    -- Nếu trống thì dùng các quái mặc định
    if #enemies == 0 then
        return {"Bandit", "Monkey", "Gorilla", "Pirate", "Desert Bandit", "Snow Bandit"}
    end
    return enemies
end

-- ==================== LUỒNG CHẠY HỆ THỐNG (TASKS) ====================

-- 1. Auto Farm Level
spawn(function()
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

-- 2. Auto Farm Quái Chỉ Định (Farm Mobs Selected)
spawn(function()
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
                -- Nếu không tìm thấy quái trực tiếp trên map, quét từ Enemy Spawns (nếu có)
                -- Hoặc thông báo cho người dùng
                task.wait(0.5)
            end
        end
    end
end)

-- 3. Auto Farm Rương (Chest Farm)
spawn(function()
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
                OrionLib:MakeNotification({
                    Name = "Chest Farm",
                    Content = "Không tìm thấy rương nào trên bản đồ hiện tại. Đang tìm lại...",
                    Time = 2
                })
                task.wait(2)
            end
        end
    end
end)

-- 4. Auto Stats
spawn(function()
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
spawn(function()
    while true do
        task.wait(1)
        if _G.AutoFruit then
            for _, obj in pairs(game.Workspace:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
                    OrionLib:MakeNotification({
                        Name = "Fruit Finder",
                        Content = "Đã tìm thấy: " .. obj.Name .. ". Dịch chuyển ngay!",
                        Time = 5
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

-- 6. Auto Gacha Fruit (Blox Fruit Dealer Cousin Gacha)
spawn(function()
    while true do
        task.wait(5)
        if _G.AutoGacha then
            -- Mua Random Fruit từ npc Dealer Cousin
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Cousin", "Buy")
            task.wait(10) -- Tránh spam liên tục làm lag game
        end
    end
end)


-- ==================== GIAO DIỆN CHỌN CHỨC NĂNG (GUI) ====================

-- 1. Tab Auto Farm
local FarmTab = Window:NewTab("Auto Farm")
local FarmSec = FarmTab:NewSection({"Tự Động Farm Level / Quái"})

FarmSec:NewToggle("Auto Farm Level", "Tự động nhận quest và tăng cấp", function(state)
    _G.AutoFarm = state
end)

local enemyList = getEnemyList()
local MobDropdown = FarmSec:NewDropdown("Chọn Quái Để Farm", "Chọn cụ thể quái bạn muốn tiêu diệt", enemyList, function(currentOption)
    _G.SelectedMobName = currentOption
end)

-- Nút cập nhật danh sách quái thực tế trong Server
FarmSec:NewButton("Làm Mới Danh Sách Quái", "Cập nhật quái hiện tại xung quanh", function()
    local newList = getEnemyList()
    MobDropdown:Refresh(newList, true)
end)

FarmSec:NewToggle("Auto Farm Quái Đã Chọn", "Chỉ diệt duy nhất loại quái đã chọn ở dropdown trên", function(state)
    _G.AutoFarmSelectedMob = state
end)

FarmSec:NewDropdown("Chọn Vũ Khí Sử Dụng", "Loại vũ khí bạn muốn trang bị khi farm", {"Melee", "Sword", "Blox Fruit"}, function(currentOption)
    _G.SelectWeapon = currentOption
end)

FarmSec:NewToggle("Auto Farm Rương", "Bay nhặt toàn bộ rương tiền trên bản đồ", function(state)
    _G.AutoFarmChest = state
end)


-- 2. Tab Dịch Chuyển (Teleport)
local TeleportTab = Window:NewTab("Dịch Chuyển")
local TeleportSec = TeleportTab:NewSection({"Chọn Đảo Cần Bay Tới"})

local islandNames = {}
for name, _ in pairs(IslandsData) do
    table.insert(islandNames, name)
end

TeleportSec:NewDropdown("Chọn Đảo Đích", "Chọn đảo bạn muốn di chuyển đến", islandNames, function(currentOption)
    _G.SelectedIsland = currentOption
end)

TeleportSec:NewButton("Bắt Đầu Bay", "Dịch chuyển an toàn đến đảo đã chọn", function()
    local targetPos = IslandsData[_G.SelectedIsland]
    if targetPos then
        OrionLib:MakeNotification({
            Name = "Dịch Chuyển",
            Content = "Đang bay tới " .. _G.SelectedIsland,
            Time = 3
        })
        toTarget(CFrame.new(targetPos))
    end
end)


-- 3. Tab Chỉ Số (Stats)
local StatsTab = Window:NewTab("Chỉ Số (Stats)")
local StatsSec = StatsTab:NewSection({"Tự Động Nâng Chỉ Số"})

StatsSec:NewToggle("Tự Động Cộng Điểm", "Bật để tự động phân bổ điểm tiềm năng", function(state)
    _G.AutoStats = state
end)

StatsSec:NewDropdown("Chọn Chỉ Số Nâng", "Chỉ số bạn muốn ưu tiên nâng trước", {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"}, function(currentOption)
    _G.StatToUpgrade = currentOption
end)


-- 4. Tab Trái Ác Quỷ (Fruits)
local FruitTab = Window:NewTab("Trái Ác Quỷ")
local FruitSec = FruitTab:NewSection({"Trợ Năng Trái Ác Quỷ"})

FruitSec:NewToggle("Auto Tìm Trái Ác Quỷ", "Tự động bay nhặt trái ác quỷ xuất hiện trên đất liền", function(state)
    _G.AutoFruit = state
end)

FruitSec:NewToggle("Auto Gacha Fruit", "Tự động mua ngẫu nhiên trái ác quỷ từ Dealer Cousin", function(state)
    _G.AutoGacha = state
end)


-- 5. Tab Hệ Thống & Tránh AFK
local SystemTab = Window:NewTab("Hệ Thống")
local SystemSec = SystemTab:NewSection({"Tính Năng Bổ Trợ"})

SystemSec:NewButton("Tối Ưu FPS (Làm Mượt)", "Giảm chất lượng hình ảnh giúp treo game không giật lag", function()
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj:Destroy()
        end
    end
    OrionLib:MakeNotification({
        Name = "Tối Ưu Hóa",
        Content = "Đã bật chế độ mượt FPS!",
        Time = 3
    })
end)

SystemSec:NewButton("Sao Chép Link Hỗ Trợ Discord", "Lấy link cộng đồng hỗ trợ", function()
    setclipboard("https://discord.gg/antigravity-hub")
    OrionLib:MakeNotification({
        Name = "Hệ thống",
        Content = "Đã sao chép link Discord vào Clipboard!",
        Time = 3
    })
end)

-- Kích hoạt Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

OrionLib:Init()
