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
