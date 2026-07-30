-- PHẦN 4: HÀM CỐT LÕI (CORE FUNCTIONS)
------------------------------------------------------------

-- ====== Noclip ======
local noclipConn = nil
local noclipOriginal = setmetatable({}, {__mode = "k"})
local function restoreCharacterCollision()
    for part, canCollide in pairs(noclipOriginal) do
        pcall(function()
            if part and part.Parent then part.CanCollide = canCollide end
        end)
        noclipOriginal[part] = nil
    end
end

local function setNoclip(state)
    if state then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
                runFeature("Noclip", function()
                    local char = Player.Character
                    if not char then return end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if noclipOriginal[part] == nil then
                                noclipOriginal[part] = part.CanCollide
                            end
                            part.CanCollide = false
                        end
                    end
                end)
            end)
        end
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        restoreCharacterCollision()
    end
end

-- ====== Trạng thái farm: tách di chuyển và chiến đấu ======
local currentTween = nil
local movementSerial = 0
local activeFarmTarget = nil
local activeFruitTarget = nil
local farmState = "idle"
local lastAttackTime = 0
local lastAttackMethod = "Chưa đánh"
local lastCombatMaintenance = 0
local lastEquipCheck = 0
local lastPreparedTarget = nil
local restoreFrozenMobs = function() end
local userPointerActive = false
local sendingVirtualAttack = false
local manualPointerPauseUntil = 0
local equipWeapon
local damageWatchTarget = nil
local damageWatchHealth = nil
local damageWatchStartedAt = 0
local lastConfirmedDamageAt = 0
local lastNetAttackTime = 0
local manualMovementActive = false
local manualMovementPauseUntil = 0
local manualTravelSerial = 0
local skillSequenceBusy = false
local silentAnimator = nil
local silentAnimationConnection = nil
local suppressAttackAnimationUntil = 0

local ACTION_ANIMATION_PRIORITIES = {
    [Enum.AnimationPriority.Action] = true,
    [Enum.AnimationPriority.Action2] = true,
    [Enum.AnimationPriority.Action3] = true,
    [Enum.AnimationPriority.Action4] = true,
}

-- Chỉ một chế độ được quyền di chuyển nhân vật tại một thời điểm.
local function getActiveMovementMode()
    if manualMovementActive or os.clock() < manualMovementPauseUntil then return "manual" end
    -- Trái đang tồn tại được nhặt trước, sau đó tự trả quyền di chuyển cho farm.
    if _G.AutoCollectFruit and activeFruitTarget and activeFruitTarget.Parent then return "fruit" end
    if _G.AutoFarmLevel then return "level" end
    if _G.AutoFarmBoss then return "boss" end
    if _G.AutoFarmMastery then return "mastery" end
    if _G.AutoFarmSeaBeast then return "sea_beast" end
    if _G.AutoFarmBone then return "bone" end
    if _G.AutoFarmFragment then return "fragment" end
    if _G.AutoRaid and _G.AutoRaidFarm then return "raid" end
    if _G.AutoFarmChest then return "chest" end
    return nil
end

local function modeCanMove(mode)
    return getActiveMovementMode() == mode
end

local function isPointerInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

UserInputService.InputBegan:Connect(function(input)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if sendingVirtualAttack or not isPointerInput(input) then return end
    userPointerActive = true
end)

UserInputService.InputEnded:Connect(function(input)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if sendingVirtualAttack or not isPointerInput(input) then return end
    userPointerActive = false
    manualPointerPauseUntil = os.clock() + 0.18
end)

local function clearFarmTarget()
    local wasAttacking = farmState == "attacking"
    local hadTarget = activeFarmTarget ~= nil
    activeFarmTarget = nil
    if wasAttacking then
        farmState = "idle"
        setNoclip(false)
    end
    if wasAttacking or hadTarget then
        restoreFrozenMobs()
        lastPreparedTarget = nil
    end

    local char = Player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function stopFarmMovement()
    movementSerial = movementSerial + 1
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    clearFarmTarget()
    restoreFrozenMobs()
    farmState = "idle"
    setNoclip(false)
end

local function getFarmCFrame(targetRoot)
    local height = tonumber(_G.FarmHeight) or 8
    local distance = tonumber(_G.FarmDistance) or 0
    return targetRoot.CFrame * CFrame.new(0, height, distance)
end

local function holdFarmTarget(target)
    if not target or not target.Parent then
        clearFarmTarget()
        return
    end

    movementSerial = movementSerial + 1
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end

    activeFarmTarget = target
    farmState = "attacking"
    setNoclip(true)
end

-- Giữ nhân vật đứng yên tương đối với quái; không chạy/chase trong lúc đánh.
RunService.Heartbeat:Connect(function()
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    pcall(function()
        if farmState ~= "attacking" or not activeFarmTarget then return end
        if not _G.HoldFarmPosition then return end
        if not activeFarmTarget.Parent then
            clearFarmTarget()
            return
        end

        local targetHumanoid = activeFarmTarget:FindFirstChildOfClass("Humanoid")
        local targetRoot = activeFarmTarget:FindFirstChild("HumanoidRootPart")
        local char = Player.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot
            or not rootPart or not humanoid then
            clearFarmTarget()
            return
        end

        rootPart.CFrame = getFarmCFrame(targetRoot)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        humanoid.AutoRotate = false
        humanoid:Move(Vector3.zero, false)
    end)
end)

-- ====== Bay tới mục tiêu (Tween), tự hủy khi chuyển sang đánh ======
local function toTarget(targetCFrame)
    if typeof(targetCFrame) == "Vector3" then targetCFrame = CFrame.new(targetCFrame) end
    if typeof(targetCFrame) ~= "CFrame" then return false end
    movementSerial = movementSerial + 1
    local requestId = movementSerial
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    clearFarmTarget()
    farmState = "moving"

    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end

    local rootPart = char.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude

    if distance < 15 then
        rootPart.CFrame = targetCFrame
        rootPart.AssemblyLinearVelocity = Vector3.zero
        farmState = "idle"
        setNoclip(false)
        return true
    end

    local speed = 300
    setNoclip(true)
    local tween = TweenService:Create(
        rootPart,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    currentTween = tween
    tween:Play()
    tween.Completed:Wait()

    if requestId ~= movementSerial then return false end
    if currentTween == tween then currentTween = nil end
    if farmState == "moving" then farmState = "idle" end
    setNoclip(false)

    return (rootPart.Position - targetCFrame.Position).Magnitude <= 25
end

-- Dịch chuyển thủ công có quyền ưu tiên, tránh vòng farm hủy tween ngay sau khi bấm nút.
local function manualTeleportTo(targetCFrame)
    if typeof(targetCFrame) == "Vector3" then targetCFrame = CFrame.new(targetCFrame) end
    if typeof(targetCFrame) ~= "CFrame" then return false end

    manualTravelSerial = manualTravelSerial + 1
    local travelId = manualTravelSerial
    manualMovementActive = true
    manualMovementPauseUntil = os.clock() + 3
    stopFarmMovement()

    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart and (rootPart.Position - targetCFrame.Position).Magnitude > 3500 then
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local commF = remotes and remotes:FindFirstChild("CommF_")
            if commF then commF:InvokeServer("requestEntrance", targetCFrame.Position) end
        end)
        task.wait(0.8)
    end

    local arrived = toTarget(targetCFrame)
    if travelId == manualTravelSerial then
        manualMovementActive = false
        manualMovementPauseUntil = os.clock() + 3
    end
    return arrived
end

