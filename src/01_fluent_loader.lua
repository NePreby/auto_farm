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
