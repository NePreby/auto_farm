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

