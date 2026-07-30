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

-- Nhận diện Sea hiện tại dựa trên PlaceId
local PlaceId = game.PlaceId
local WorldSea = 1
if PlaceId == 2753915549 then WorldSea = 1
elseif PlaceId == 4442272183 then WorldSea = 2
elseif PlaceId == 7449423635 then WorldSea = 3
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
