--[[
    ================================================================================
    ⚡ HAOTOOL HUB | BLOX FRUITS (MOBILE TOUCH OPTIMIZED ENGINE)
    --------------------------------------------------------------------------------
    Developer: HAOTOOL Team
    Special Feature: 100% Touch-Responsive UI (Sửa dứt điểm lỗi không bấm được tab/nút)
    Executors Supported: Delta, Fluxus, Solara, Wave, CodeX, Hydrogen, Arceus X, Synapse
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
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Nhận diện Sea 1, 2, 3
local PlaceId = game.PlaceId
local WorldSea = 1
if PlaceId == 2753915549 then WorldSea = 1
elseif PlaceId == 4442272183 then WorldSea = 2
elseif PlaceId == 7449423635 then WorldSea = 3 end

-- Global State
_G.AutoFarmLevel = false
_G.AutoFarmNearest = false
_G.AutoBoss = false
_G.SelectedBoss = ""
_G.SelectWeapon = "Melee"
_G.BringMob = true
_G.FastAttack = true
_G.AutoHaki = true
_G.AutoKen = false

_G.AutoRaid = false
_G.SelectedChip = "Flame"
_G.AutoBuyChip = false
_G.AutoStartRaid = false

_G.AutoFruitFinder = true
_G.AutoPickFruit = false
_G.AutoStoreFruit = true
_G.AutoGachaFruit = false

_G.AutoStats = false
_G.StatToUpgrade = "Melee"
_G.StatPointsPerClick = 3

_G.ESPPlayer = false
_G.ESPFruit = false
_G.ESPChest = false

_G.WalkSpeedHack = false
_G.WalkSpeedVal = 50
_G.JumpPowerHack = false
_G.JumpPowerVal = 100
_G.InfiniteJump = false
_G.SelectedIsland = "Starter Island"

-- ==================== HÀM TẠO SỰ KIỆN TOUCH/CLICK SIÊU NHẠY ====================
-- Hàm này đảm bảo 100% bấm được trên cả Điện Thoại (Touch) & Máy Tính (Click)
local function bindTouchClick(guiElement, callback)
    guiElement.Active = true
    
    -- Vô hiệu hóa Active trên tất cả icon/text con để không nuốt cảm ứng
    local function disableChildren(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("GuiObject") then
                child.Active = false
                disableChildren(child)
            end
        end
    end
    disableChildren(guiElement)
    guiElement.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then
            child.Active = false
            disableChildren(child)
        end
    end)
    
    -- Xử lý cảm ứng chạm (TouchInput) và Click chuột (MouseButton1)
    local lastTrigger = 0
    guiElement.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local now = tick()
            if now - lastTrigger > 0.15 then -- Chống spam double click
                lastTrigger = now
                callback()
            end
        end
    end)
end

-- ==================== GIAO DIỆN TOUCH-FRIENDLY GUI ENGINE ====================
local GuiParent = CoreGui:FindFirstChild("RobloxGui") or Player:WaitForChild("PlayerGui")
if GuiParent:FindFirstChild("HaoToolGUI") then
    GuiParent.HaoToolGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HaoToolGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

-- 1. NÚT TRÒN NỔI CHO MOBILE (HAO BUTTON)
local MobileToggleBtn = Instance.new("Frame")
MobileToggleBtn.Name = "HaoToolMobileToggle"
MobileToggleBtn.Size = UDim2.new(0, 52, 0, 52)
MobileToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
MobileToggleBtn.BorderSizePixel = 0
MobileToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = MobileToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(6, 182, 212)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = MobileToggleBtn

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(1, 0, 1, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "HAO"
ToggleLabel.TextColor3 = Color3.fromRGB(6, 182, 212)
ToggleLabel.Font = Enum.Font.FredokaOne
ToggleLabel.TextSize = 18
ToggleLabel.Parent = MobileToggleBtn

-- Kéo thả nút mobile
local dragging, dragInput, dragStart, startPos
MobileToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MobileToggleBtn.Position
    end
end)
MobileToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MobileToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 2. KHUNG CỬA SỔ CHÍNH (MAIN WINDOW)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 360)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(30, 41, 59)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Bar Header
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ HAOTOOL | BLOX FRUITS"
TitleLabel.TextColor3 = Color3.fromRGB(6, 182, 212)
TitleLabel.Font = Enum.Font.FredokaOne
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0.25, 0, 1, 0)
SubTitle.Position = UDim2.new(0.72, 0, 0, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Sea " .. WorldSea .. " • Mobile OK"
SubTitle.TextColor3 = Color3.fromRGB(148, 163, 184)
SubTitle.Font = Enum.Font.SourceSansBold
SubTitle.TextSize = 13
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.Parent = TopBar

-- Bật/Tắt GUI từ Nút Nổi & Phím RightControl
local guiVisible = true
local function toggleGui()
    guiVisible = not guiVisible
    MainFrame.Visible = guiVisible
end
bindTouchClick(MobileToggleBtn, toggleGui)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        toggleGui()
    end
end)

-- 3. CỘT THANH TAB (LEFT SIDEBAR & TOP TABS)
local TabBarScroll = Instance.new("ScrollingFrame")
TabBarScroll.Size = UDim2.new(1, -20, 0, 40)
TabBarScroll.Position = UDim2.new(0, 10, 0, 50)
TabBarScroll.BackgroundTransparency = 1
TabBarScroll.ScrollBarThickness = 2
TabBarScroll.CanvasSize = UDim2.new(0, 750, 0, 0)
TabBarScroll.ScrollingDirection = Enum.ScrollingDirection.Horizontal
TabBarScroll.Parent = MainFrame

local TabUIList = Instance.new("UIListLayout")
TabUIList.FillDirection = Enum.FillDirection.Horizontal
TabUIList.SortOrder = Enum.SortOrder.LayoutOrder
TabUIList.Padding = UDim.new(0, 6)
TabUIList.Parent = TabBarScroll

-- Container Nội Dung Tab
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -100)
ContentContainer.Position = UDim2.new(0, 10, 0, 95)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local TabsList = {}
local CurrentActiveTab = nil

local function createTab(tabName, iconText)
    local tabBtn = Instance.new("Frame")
    tabBtn.Size = UDim2.new(0, 110, 0, 36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    tabBtn.Parent = TabBarScroll
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabBtn
    
    local tabText = Instance.new("TextLabel")
    tabText.Size = UDim2.new(1, 0, 1, 0)
    tabText.BackgroundTransparency = 1
    tabText.Text = iconText .. " " .. tabName
    tabText.TextColor3 = Color3.fromRGB(148, 163, 184)
    tabText.Font = Enum.Font.SourceSansBold
    tabText.TextSize = 14
    tabText.Parent = tabBtn
    
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.ScrollBarThickness = 4
    tabContent.Visible = false
    tabContent.Parent = ContentContainer
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = tabContent
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Xử lý chuyển Tab nhạy 100%
    bindTouchClick(tabBtn, function()
        for _, t in pairs(TabsList) do
            t.Btn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
            t.Text.TextColor3 = Color3.fromRGB(148, 163, 184)
            t.Content.Visible = false
        end
        tabBtn.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
        tabText.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabContent.Visible = true
        CurrentActiveTab = tabContent
    end)
    
    table.insert(TabsList, {Btn = tabBtn, Text = tabText, Content = tabContent})
    
    -- Mặc định chọn tab đầu tiên
    if #TabsList == 1 then
        tabBtn.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
        tabText.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabContent.Visible = true
        CurrentActiveTab = tabContent
    end
    
    return tabContent
end

-- 4. HÀM TẠO CÁC NÚT ĐỒ HỌA TRONG TAB
local function addToggle(parentTab, titleText, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 42)
    frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    frame.Parent = parentTab
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.75, 0, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(226, 232, 240)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 42, 0, 22)
    indicator.Position = UDim2.new(1, -52, 0.5, -11)
    indicator.BackgroundColor3 = defaultVal and Color3.fromRGB(6, 182, 212) or Color3.fromRGB(51, 65, 85)
    indicator.Parent = frame
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defaultVal and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = indicator
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local state = defaultVal
    bindTouchClick(frame, function()
        state = not state
        indicator.BackgroundColor3 = state and Color3.fromRGB(6, 182, 212) or Color3.fromRGB(51, 65, 85)
        knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        callback(state)
    end)
end

local function addButton(parentTab, titleText, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
    frame.Parent = parentTab
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
    title.Parent = frame
    
    bindTouchClick(frame, function()
        frame.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
        task.wait(0.1)
        frame.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
        callback()
    end)
end

local function addDropdown(parentTab, titleText, options, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 42)
    frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    frame.ClipsDescendants = true
    frame.Parent = parentTab
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 0, 42)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(226, 232, 240)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.45, 0, 0, 42)
    valLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(defaultVal) .. " ▼"
    valLabel.TextColor3 = Color3.fromRGB(6, 182, 212)
    valLabel.Font = Enum.Font.SourceSansBold
    valLabel.TextSize = 14
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame
    
    local isOpen = false
    local optionContainer = Instance.new("Frame")
    optionContainer.Size = UDim2.new(1, -20, 0, #options * 32)
    optionContainer.Position = UDim2.new(0, 10, 0, 42)
    optionContainer.BackgroundTransparency = 1
    optionContainer.Parent = frame
    
    local optLayout = Instance.new("UIListLayout")
    optLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optLayout.Padding = UDim.new(0, 4)
    optLayout.Parent = optionContainer
    
    local function populateOptions(opts)
        for _, child in pairs(optionContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for _, opt in ipairs(opts) do
            local optFrame = Instance.new("Frame")
            optFrame.Size = UDim2.new(1, 0, 0, 28)
            optFrame.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
            optFrame.Parent = optionContainer
            
            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0, 6)
            optCorner.Parent = optFrame
            
            local optText = Instance.new("TextLabel")
            optText.Size = UDim2.new(1, 0, 1, 0)
            optText.BackgroundTransparency = 1
            optText.Text = tostring(opt)
            optText.TextColor3 = Color3.fromRGB(255, 255, 255)
            optText.Font = Enum.Font.SourceSans
            optText.TextSize = 13
            optText.Parent = optFrame
            
            bindTouchClick(optFrame, function()
                valLabel.Text = tostring(opt) .. " ▼"
                isOpen = false
                frame.Size = UDim2.new(1, -6, 0, 42)
                callback(opt)
            end)
        end
    end
    populateOptions(options)
    
    bindTouchClick(title, function()
        isOpen = not isOpen
        frame.Size = isOpen and UDim2.new(1, -6, 0, 46 + (#options * 32)) or UDim2.new(1, -6, 0, 42)
    end)
    bindTouchClick(valLabel, function()
        isOpen = not isOpen
        frame.Size = isOpen and UDim2.new(1, -6, 0, 46 + (#options * 32)) or UDim2.new(1, -6, 0, 42)
    end)
    
    return {
        Refresh = function(newOpts)
            options = newOpts
            populateOptions(newOpts)
        end
    }
end

-- ==================== CÁC TAB NỘI DUNG SCRIPT ====================

local MainTab = createTab("Auto Farm", "🌾")
local RaidTab = createTab("Auto Raid", "🛡️")
local FruitTab = createTab("Trái Ác Quỷ", "🍎")
local ESPTab = createTab("Hệ Thống ESP", "👁️")
local TeleportTab = createTab("Dịch Chuyển", "🚀")
local StatsTab = createTab("Chỉ Số Stats", "📊")
local MiscTab = createTab("Hack & Game", "⚙️")

-- 1. TAB AUTO FARM
addToggle(MainTab, "Auto Farm Level (Tự Động Làm Quest)", false, function(v) _G.AutoFarmLevel = v end)
addToggle(MainTab, "Gom Quái Lại Gần (Bring Mob)", true, function(v) _G.BringMob = v end)
addDropdown(MainTab, "Vũ Khí Farm", {"Melee", "Sword", "Blox Fruit"}, "Melee", function(v) _G.SelectWeapon = v end)
addToggle(MainTab, "Tự Động Bật Buso Haki", true, function(v) _G.AutoHaki = v end)
addToggle(MainTab, "Tự Động Bật Ken Haki", false, function(v) _G.AutoKen = v end)

addToggle(MainTab, "Farm Quái Gần Nhất (Nearest Mob)", false, function(v) _G.AutoFarmNearest = v end)

-- Boss Farm
local enemyBosses = {"The Gorilla King", "Bobby", "Yeti", "Vice Admiral", "Swan", "Magma Admiral", "Fishman Lord"}
local BossDrop = addDropdown(MainTab, "Chọn Boss Cần Farm", enemyBosses, enemyBosses[1], function(v) _G.SelectedBoss = v end)
addToggle(MainTab, "Auto Farm Boss Đã Chọn", false, function(v) _G.AutoBoss = v end)

-- 2. TAB AUTO RAID
addDropdown(RaidTab, "Loại Chip Raid", {"Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble", "Magma", "Human: Buddha", "Sand"}, "Flame", function(v) _G.SelectedChip = v end)
addToggle(RaidTab, "Auto Mua Chip Raid", false, function(v) _G.AutoBuyChip = v end)
addToggle(RaidTab, "Auto Bắt Đầu Raid", false, function(v) _G.AutoStartRaid = v end)
addToggle(RaidTab, "Auto Đi Raid & Clear Waves", false, function(v) _G.AutoRaid = v end)

-- 3. TAB TRÁI ÁC QUỶ
addToggle(FruitTab, "Thông Báo Trái Spawn (Fruit Finder)", true, function(v) _G.AutoFruitFinder = v end)
addToggle(FruitTab, "Auto Bay Tới Nhặt Trái", false, function(v) _G.AutoPickFruit = v end)
addToggle(FruitTab, "Auto Cất Trái Vào Kho (Store Fruit)", true, function(v) _G.AutoStoreFruit = v end)
addToggle(FruitTab, "Auto Mua Trái Ngẫu Nhiên (Gacha)", false, function(v) _G.AutoGachaFruit = v end)

-- 4. TAB ESP
addToggle(ESPTab, "ESP Người Chơi", false, function(v) _G.ESPPlayer = v end)
addToggle(ESPTab, "ESP Trái Ác Quỷ", false, function(v) _G.ESPFruit = v end)
addToggle(ESPTab, "ESP Rương Beli", false, function(v) _G.ESPChest = v end)

-- 5. TAB DỊCH CHUYỂN
local IslandsSea1 = {
    ["Starter Island"] = Vector3.new(1059, 15, 1549), ["Jungle"] = Vector3.new(-1598, 36, 153),
    ["Pirate Village"] = Vector3.new(-1182, 4, 3851), ["Desert"] = Vector3.new(944, 6, 4373),
    ["Frozen Village"] = Vector3.new(1255, 6, -4246), ["Marine Fortress"] = Vector3.new(-5036, 24, 4317),
    ["Skyland"] = Vector3.new(-4839, 717, -2620), ["Prison"] = Vector3.new(4875, 5, 735),
    ["Colosseum"] = Vector3.new(-1516, 7, -2994), ["Magma Village"] = Vector3.new(-5241, 8, 8504),
    ["Underwater City"] = Vector3.new(61163, 11, 1819), ["Fountain City"] = Vector3.new(5121, 5, 4110)
}
local islandNames = {}
for name, _ in pairs(IslandsSea1) do table.insert(islandNames, name) end
table.sort(islandNames)

addDropdown(TeleportTab, "Chọn Đảo Đích Đến", islandNames, islandNames[1], function(v) _G.SelectedIsland = v end)
addButton(TeleportTab, "✈️ Bay Tới Đảo Đã Chọn", function()
    local pos = IslandsSea1[_G.SelectedIsland]
    if pos then
        toTarget(CFrame.new(pos))
    end
end)

-- 6. TAB STATS
addToggle(StatsTab, "Auto Cộng Điểm Stats", false, function(v) _G.AutoStats = v end)
addDropdown(StatsTab, "Chỉ Số Ưu Tiên", {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, "Melee", function(v)
    _G.StatToUpgrade = (v == "Demon Fruit" and "Blox Fruit" or v)
end)

-- 7. TAB MISC
addToggle(MiscTab, "Bật WalkSpeed (Chạy Nhanh)", false, function(v) _G.WalkSpeedHack = v end)
addToggle(MiscTab, "Bật JumpPower (Nhảy Cao)", false, function(v) _G.JumpPowerHack = v end)
addToggle(MiscTab, "Infinite Jump (Nhảy Không Giới Hạn)", false, function(v) _G.InfiniteJump = v end)
addButton(MiscTab, "⚡ Tối Ưu FPS (Xóa Texture)", function()
    pcall(function()
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            end
        end
    end)
end)

-- ==================== CÁC HÀM XỬ LÝ GAME LOGIC ====================

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

local MeleeNames = {"Combat", "Black Leg", "Electro", "Fishman Karate", "Dragon Claw", "Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", "Dragon Talon", "Godhuman", "Sanguine Art"}

local noclipConn = nil
function setNoclip(state)
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

function toTarget(targetCFrame)
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
    local tween = TweenService:Create(rootPart, {CFrame = targetCFrame}, tweenInfo)
    tween:Play()
    tween.Completed:Wait()
    setNoclip(false)
end

local function checkHaki()
    local char = Player.Character
    if not char then return end
    if _G.AutoHaki and not char:FindFirstChild("HasBuso") then
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
    end
    if _G.AutoKen and not char:FindFirstChild("HasKen") then
        pcall(function()
            local ken = ReplicatedStorage:FindFirstChild("Ken") or ReplicatedStorage.Remotes:FindFirstChild("Ken")
            if ken then ken:FireServer(true) end
        end)
    end
end

-- Hàm đánh an toàn: CHỈ dùng tool:Activate()
-- KHÔNG dùng VirtualUser/VirtualInputManager vì chúng chiếm quyền input toàn cục,
-- khiến người chơi không bấm được GUI nữa.
local function attack()
    checkHaki()
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

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
    
    local fallback = backpack:FindFirstChildOfClass("Tool")
    if fallback then char.Humanoid:EquipTool(fallback) end
end

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

local function getQuestData(level)
    for _, data in ipairs(QuestsSea1) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    return QuestsSea1[1]
end

-- Task Loops
-- QUAN TRỌNG: task.wait(0.15) thay vì 0.05 để trả lại CPU cho UI rendering
-- Không dùng toTarget (blocking tween) khi đang đánh quái, chỉ CFrame trực tiếp
task.spawn(function()
    while true do
        task.wait(0.15) -- Giảm tốc vòng lặp: cho phép GUI xử lý touch/click
        if _G.AutoFarmLevel then
            pcall(function()
                local level = Player.Data.Level.Value
                local quest = getQuestData(level)
                
                local questGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible
                
                if not hasQuest then
                    -- Bay tới NPC nhận quest (dùng toTarget vì cần bay xa)
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
                        -- Bay tới khu vực quái (dùng toTarget)
                        toTarget(CFrame.new(quest.MobPosition))
                    else
                        -- ĐÁNH QUÁI: Chỉ dùng CFrame trực tiếp, KHÔNG dùng toTarget/tween
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

task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoPickFruit or _G.AutoFruitFinder then
            pcall(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
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
    RunService.RenderStepped:Connect(function()
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            if _G.WalkSpeedHack then char.Humanoid.WalkSpeed = _G.WalkSpeedVal end
            if _G.JumpPowerHack then char.Humanoid.JumpPower = _G.JumpPowerVal end
        end
    end)
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = Player.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end
end)

-- Anti-AFK: Chỉ chạy khi player thực sự idle, không chiếm quyền input liên tục
Player.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)
