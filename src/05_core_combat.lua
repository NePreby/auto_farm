-- ====== Haki (Buso & Observation) ======
local lastBusoAttempt = 0
local lastObservationAttempt = 0

local function activateObservation(force)
    local now = os.clock()
    if not force and now - lastObservationAttempt < 2 then return false end
    if userPointerActive or UserInputService:GetFocusedTextBox() then return false end
    lastObservationAttempt = now

    return runFeature("Observation", function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local ken = remotes and remotes:FindFirstChild("Ken")
        if ken and ken:IsA("RemoteEvent") then
            ken:FireServer(true)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

local function checkHaki()
    local char = Player.Character
    if not char then return end
    local now = os.clock()

    if _G.AutoHaki and not char:FindFirstChild("HasBuso") and now - lastBusoAttempt >= 1 then
        lastBusoAttempt = now
        runFeature("Buso Haki", function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end)
    end

    if _G.AutoKen or _G.AutoObsV2 then
        activateObservation(false)
    end
end

-- Hệ thống đánh tự động ngầm 100% (Không click màn hình, trúng 100% sát thương)
local combatControllerCache = nil
local lastCombatControllerResolve = 0

local function findAttackController(value, depth, visited)
    if type(value) ~= "table" then return nil end
    visited = visited or {}
    if visited[value] then return nil end
    visited[value] = true

    local direct = rawget(value, "activeController")
    if type(direct) == "table"
        and (type(rawget(direct, "attack")) == "function"
            or type(rawget(direct, "Attack")) == "function") then
        return direct
    end
    if type(rawget(value, "attack")) == "function"
        or type(rawget(value, "Attack")) == "function" then
        return value
    end
    if depth <= 0 then return nil end

    local found = nil
    pcall(function()
        for _, nested in pairs(value) do
            found = findAttackController(nested, depth - 1, visited)
            if found then break end
        end
    end)
    return found
end

local function findControllerInFunction(fn)
    if type(fn) ~= "function" then return nil end
    local found = nil
    local bulkGetter = getupvalues or (debug and debug.getupvalues)
    if type(bulkGetter) == "function" then
        pcall(function()
            found = findAttackController(bulkGetter(fn), 3, {})
        end)
        if found then return found end
    end

    local singleGetter = getupvalue or (debug and debug.getupvalue)
    if type(singleGetter) == "function" then
        for index = 1, 30 do
            local ok, first, second = pcall(singleGetter, fn, index)
            if not ok then break end
            local value = second ~= nil and second or first
            if value == nil then break end
            found = findAttackController(value, 3, {})
            if found then return found end
        end
    end
    return nil
end

local function findControllerFromGC()
    if type(getgc) ~= "function" then return nil end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end

    for _, value in ipairs(objects) do
        if type(value) == "table" then
            local direct = rawget(value, "activeController")
            if type(direct) == "table"
                and (type(rawget(direct, "attack")) == "function"
                    or type(rawget(direct, "Attack")) == "function") then
                return direct
            end

            local attackFn = rawget(value, "attack") or rawget(value, "Attack")
            if type(attackFn) == "function"
                and (rawget(value, "timeToNextAttack") ~= nil
                    or rawget(value, "hitboxMagnitude") ~= nil
                    or rawget(value, "attacking") ~= nil) then
                return value
            end
        end
    end
    return nil
end

local function resolveCombatController(force)
    if combatControllerCache
        and (type(combatControllerCache.attack) == "function"
            or type(combatControllerCache.Attack) == "function") then
        return combatControllerCache
    end

    local now = os.clock()
    if not force and now - lastCombatControllerResolve < 2 then return nil end
    lastCombatControllerResolve = now

    local controller = nil
    local playerScripts = Player:FindFirstChild("PlayerScripts")
    local combatModule = playerScripts and playerScripts:FindFirstChild("CombatFramework", true)
    if combatModule and combatModule:IsA("ModuleScript") then
        local ok, framework = pcall(require, combatModule)
        if ok then
            controller = findAttackController(framework, 4, {})
                or findControllerInFunction(framework)
        end
    end
    controller = controller or findControllerFromGC()
    if controller then combatControllerCache = controller end
    return controller
end

-- Chỉ làm trong suốt animation đánh thường, không Stop track để marker damage vẫn được xử lý.
local function bindSilentAnimationWatcher(humanoid)
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end
    if animator == silentAnimator and silentAnimationConnection then return true end

    if silentAnimationConnection then
        pcall(function() silentAnimationConnection:Disconnect() end)
        silentAnimationConnection = nil
    end

    silentAnimator = animator
    silentAnimationConnection = animator.AnimationPlayed:Connect(function(track)
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
        task.defer(function()
            if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
            if not _G.NoAttackAnimation or skillSequenceBusy then return end
            if os.clock() > suppressAttackAnimationUntil then return end
            if not ACTION_ANIMATION_PRIORITIES[track.Priority] then return end
            pcall(function() track:AdjustWeight(0, 0) end)
        end)
    end)
    return true
end

local function armSilentAttack(humanoid)
    if not _G.NoAttackAnimation or skillSequenceBusy then return end
    if bindSilentAnimationWatcher(humanoid) then
        suppressAttackAnimationUntil = os.clock() + 0.18
    end
end

local function restoreAttackAnimationWeights()
    suppressAttackAnimationUntil = 0
    local animator = silentAnimator
    if not animator or not animator.Parent then return end
    pcall(function()
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if ACTION_ANIMATION_PRIORITIES[track.Priority] then
                track:AdjustWeight(1, 0.05)
            end
        end
    end)
end

-- Ưu tiên bộ điều khiển chiến đấu thật để đánh nền mà không chiếm chuột.
local function attack()
    local now = os.clock()
    local delay = math.clamp(tonumber(_G.AttackDelay) or 0.05, 0.01, 0.50)
    if _G.SafetyMode then delay = math.max(delay, 0.05) end
    if now - lastAttackTime < delay then return false end
    lastAttackTime = now
    checkHaki()

    local target = activeFarmTarget
    local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    if target ~= damageWatchTarget then
        damageWatchTarget = target
        damageWatchHealth = targetHumanoid and targetHumanoid.Health or nil
        damageWatchStartedAt = now
        lastConfirmedDamageAt = 0
    elseif targetHumanoid and damageWatchHealth and targetHumanoid.Health < damageWatchHealth then
        lastConfirmedDamageAt = now
    end
    if targetHumanoid then damageWatchHealth = targetHumanoid.Health end
    local noDamageFor = lastConfirmedDamageAt > 0
        and (now - lastConfirmedDamageAt) or (now - damageWatchStartedAt)

    local char = Player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    armSilentAttack(humanoid)
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool and equipWeapon then
        equipWeapon(_G.SelectWeapon or "Melee")
        tool = char:FindFirstChildOfClass("Tool")
    end
    if not tool then
        lastAttackMethod = "Không tìm thấy vũ khí trong Balo"
        return false
    end

    local methods = {}

    -- Bộ điều khiển thật: không thoát sớm chỉ vì pcall thành công.
    local controller = resolveCombatController(false)
    if controller then
        local controllerOk = pcall(function()
            controller.attacking = false
            controller.blocking = false
            controller.timeToNextAttack = 0
            controller.timeToNextBlock = 0
            controller.hitboxMagnitude = math.max(tonumber(controller.hitboxMagnitude) or 0, 60)
            local controllerAttack = controller.attack or controller.Attack
            if type(controllerAttack) == "function" then controllerAttack(controller) end
        end)
        if controllerOk then
            table.insert(methods, "Controller")
        else
            combatControllerCache = nil
        end
    end

    local toolOk = pcall(function() tool:Activate() end)
    if toolOk then table.insert(methods, "Tool") end

    -- Một số Tool mới có remote click riêng.
    local leftClickRemote = tool:FindFirstChild("LeftClickRemote")
    if leftClickRemote and leftClickRemote:IsA("RemoteEvent") and targetRoot then
        local leftClickOk = pcall(function()
            local direction = targetRoot.Position - char:GetPivot().Position
            if direction.Magnitude > 0 then direction = direction.Unit end
            leftClickRemote:FireServer(direction, 1)
        end)
        if leftClickOk then table.insert(methods, "ToolRemote") end
    end

    -- VirtualUser gửi đòn đánh vào bộ điều khiển game, không click lên nút menu.
    if RuntimeEnv.HAOTOOL_MENU_VISIBLE ~= true
        and not userPointerActive and now >= manualPointerPauseUntil
        and not UserInputService:GetFocusedTextBox() then
        sendingVirtualAttack = true
        local virtualOk = pcall(function()
            local camera = workspace.CurrentCamera
            local cameraCFrame = camera and camera.CFrame or CFrame.new()
            VirtualUser:Button1Down(Vector2.new(0, 0), cameraCFrame)
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0, 0), cameraCFrame)
        end)
        sendingVirtualAttack = false
        if virtualOk then table.insert(methods, "VirtualUser") end

        -- Nếu chưa có damage, gửi click vào giữa màn hình nhưng chỉ khi menu đã đóng.
        if noDamageFor >= 0.75 then
            sendingVirtualAttack = true
            local inputOk = pcall(function()
                local camera = workspace.CurrentCamera
                local size = camera and camera.ViewportSize or Vector2.new(800, 600)
                local x, y = math.floor(size.X * 0.5), math.floor(size.Y * 0.5)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.012)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
            sendingVirtualAttack = false
            if inputOk then table.insert(methods, "VIM") end
        end
    end

    -- Đường Net dùng BasePart thật trong danh sách hit; chỉ báo thành công khi remote thực sự được gửi.
    if target and targetRoot and now - lastNetAttackTime >= math.max(delay, 0.10) then
        lastNetAttackTime = now
        local netFired = false
        local netOk = pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local net = modules and modules:FindFirstChild("Net")
            local registerAttack = net and net:FindFirstChild("RE/RegisterAttack")
            local registerHit = net and net:FindFirstChild("RE/RegisterHit")
            if not registerAttack or not registerHit then return end
            if not registerAttack:IsA("RemoteEvent") or not registerHit:IsA("RemoteEvent") then return end
            local hitList = {targetRoot}
            registerAttack:FireServer(0)
            registerHit:FireServer(targetRoot, hitList)
            netFired = true
        end)
        if netOk and netFired then table.insert(methods, "NetHit") end
    end

    local damageState = lastConfirmedDamageAt > 0 and now - lastConfirmedDamageAt < 1
        and "Damage OK" or string.format("chờ damage %.1fs", noDamageFor)
    lastAttackMethod = damageState .. " • " .. (#methods > 0 and table.concat(methods, "+") or "không có đường đánh")
    return #methods > 0
end-- ====== Auto Skill (dùng Z, X, C, V) ======
local lastSkillTime = 0
local function useSkills(force)
    if not force and not _G.AutoSkill then return end
    if skillSequenceBusy or userPointerActive or os.clock() < manualPointerPauseUntil
        or UserInputService:GetFocusedTextBox() then return end

    local cooldown = math.max(0.5, tonumber(_G.SkillCooldown) or 1.5)
    if os.clock() - lastSkillTime < cooldown then return end
    lastSkillTime = os.clock()
    skillSequenceBusy = true

    task.spawn(function()
        runFeature("Auto Skill", function()
            local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
            for _, key in ipairs(keys) do
                if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then break end
                if userPointerActive or UserInputService:GetFocusedTextBox() then break end
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
                task.wait(0.12)
            end
        end)
        skillSequenceBusy = false
    end)
end

-- ====== Trang bị vũ khí theo loại ======
equipWeapon = function(weaponType)
    pcall(function()
        local char = Player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local backpack = Player:FindFirstChild("Backpack")
        if not char or not humanoid then return end

        weaponType = weaponType or _G.SelectWeapon or "Melee"

        -- Nếu nhân vật đã cầm đúng loại vũ khí trên tay
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped then
            local eqName = equipped.Name
            local eqTip = equipped.ToolTip or ""
            local isMatch = false
            if weaponType == "Melee" and (table.find(MeleeNames, eqName) or eqTip == "Melee" or eqName == "Combat" or eqTip:find("Melee") or eqName:lower():find("combat") or eqName:lower():find("style")) then isMatch = true end
            if weaponType == "Sword" and (table.find(SwordNames, eqName) or eqTip == "Sword" or eqTip:find("Sword") or eqName:lower():find("sword")) then isMatch = true end
            if weaponType == "Gun" and (table.find(GunNames, eqName) or eqTip == "Gun" or eqTip:find("Gun") or eqName:lower():find("gun")) then isMatch = true end
            if weaponType == "Blox Fruit" and (eqTip == "Blox Fruit" or eqName:find("Fruit") or eqTip:find("Fruit") or eqName:lower():find("fruit")) then isMatch = true end
            if isMatch then return end
        end

        -- Tìm trong Backpack vũ khí khớp với loại được chọn
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local tName = tool.Name
                    local tTip = tool.ToolTip or ""
                    local match = false
                    if weaponType == "Melee" and (table.find(MeleeNames, tName) or tTip == "Melee" or tName == "Combat" or tTip:find("Melee") or tName:lower():find("combat") or tName:lower():find("style")) then match = true end
                    if weaponType == "Sword" and (table.find(SwordNames, tName) or tTip == "Sword" or tTip:find("Sword") or tName:lower():find("sword")) then match = true end
                    if weaponType == "Gun" and (table.find(GunNames, tName) or tTip == "Gun" or tTip:find("Gun") or tName:lower():find("gun")) then match = true end
                    if weaponType == "Blox Fruit" and (tTip == "Blox Fruit" or tName:find("Fruit") or tTip:find("Fruit") or tName:lower():find("fruit")) then match = true end

                    if match then
                        tool.Parent = char
                        humanoid:EquipTool(tool)
                        return
                    end
                end
            end

            -- Fallback: Cầm Tool đầu tiên có trong Backpack
            local fallback = backpack:FindFirstChildOfClass("Tool")
            if fallback then
                fallback.Parent = char
                humanoid:EquipTool(fallback)
            end
        end
    end)
end

-- Chuẩn hóa tên model như "Monkey [Lv. 14]" hoặc "The Gorilla King [Boss]".
local function normalizeMobName(name)
    local normalized = string.lower(tostring(name or ""))
    normalized = normalized:gsub("%s*%[lv%.?%s*%d+%]%s*", "")
    normalized = normalized:gsub("%s*%[raid boss%]%s*", "")
    normalized = normalized:gsub("%s*%[boss%]%s*", "")
    normalized = normalized:gsub("^the%s+", "")
    normalized = normalized:gsub("^%s+", ""):gsub("%s+$", "")
    normalized = normalized:gsub("%s+", " ")
    return normalized
end

local function mobNameMatches(actualName, wantedName)
    if not actualName or not wantedName or wantedName == "" then return false end
    return normalizeMobName(actualName) == normalizeMobName(wantedName)
end


-- ====== Khóa và gom quái có thể hoàn nguyên ======
local frozenMobStates = setmetatable({}, {__mode = "k"})

local function grantSimulationRadius()
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Player, "SimulationRadius", math.huge)
        elseif setsimulationradius then
            setsimulationradius(math.huge, math.huge)
        end
    end)
end

local function freezeMob(mob)
    if not mob or not mob.Parent then return end

    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    local rootPart = mob:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end

    if not frozenMobStates[mob] then
        frozenMobStates[mob] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            AutoRotate = humanoid.AutoRotate,
            PlatformStand = humanoid.PlatformStand,
            Anchored = rootPart.Anchored,
            CanCollide = rootPart.CanCollide,
            Size = rootPart.Size,
        }
    end

    rootPart.CanCollide = false
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    -- Nối dài Hitbox chiều cao lên phía trên để nhân vật ở độ cao 12+ vẫn chạm Hitbox và đánh trúng 100%
    local farmHeight = math.abs(tonumber(_G.FarmHeight) or 12)
    local hitboxLimit = _G.SafetyMode and 18 or 60
    local hitboxSize = math.clamp(tonumber(_G.HitboxSize) or 14, 4, hitboxLimit)
    local verticalSize = math.clamp(farmHeight * 2.5 + 20, hitboxSize, 90)

    rootPart.Size = Vector3.new(hitboxSize, verticalSize, hitboxSize)

    if _G.FreezeTarget then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        -- Không neo/PlatformStand mục tiêu: hai trạng thái này có thể làm bộ đánh của game bỏ qua sát thương.
        humanoid.PlatformStand = false
        rootPart.Anchored = false
    end
end

restoreFrozenMobs = function()
    for mob, state in pairs(frozenMobStates) do
        pcall(function()
            if mob and mob.Parent then
                local humanoid = mob:FindFirstChildOfClass("Humanoid")
                local rootPart = mob:FindFirstChild("HumanoidRootPart")
                if humanoid then
                    humanoid.WalkSpeed = state.WalkSpeed
                    humanoid.JumpPower = state.JumpPower
                    humanoid.AutoRotate = state.AutoRotate
                    humanoid.PlatformStand = state.PlatformStand
                end
                if rootPart then
                    rootPart.CanCollide = state.CanCollide
                    rootPart.Anchored = state.Anchored
                    rootPart.Size = state.Size
                end
            end
        end)
        frozenMobStates[mob] = nil
    end
end

local function bringMobsNear(targetName, centerCFrame)
    if not _G.BringMob then return end
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return end
        grantSimulationRadius()

        local radiusLimit = _G.SafetyMode and 350 or 1000
        local radius = math.clamp(tonumber(_G.BringRadius) or 300, 50, radiusLimit)
        for _, mob in pairs(enemies:GetChildren()) do
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            local rootPart = mob:FindFirstChild("HumanoidRootPart")

            if mobNameMatches(mob.Name, targetName)
                and humanoid and humanoid.Health > 0 and rootPart then
                local distance = (rootPart.Position - centerCFrame.Position).Magnitude
                if distance <= radius or mob == lastPreparedTarget then
                    freezeMob(mob)
                    -- Giữ quái đứng im 100% tại đúng 1 vị trí cố định trên mặt đất (không bị trôi hay di chuyển)
                    rootPart.CFrame = centerCFrame
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function engageTarget(target, targetName, weaponType, forceSkills)
    if not target or not target.Parent then
        clearFarmTarget()
        return false
    end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not targetRoot then
        clearFarmTarget()
        return false
    end

    holdFarmTarget(target)

    local now = os.clock()
    if target ~= lastPreparedTarget or now - lastCombatMaintenance >= 0.15 then
        grantSimulationRadius()
        freezeMob(target)
        -- Sử dụng vị trí mặt đất cố định của quái chính làm tâm gom quái
        local groundCFrame = CFrame.new(targetRoot.Position)
        bringMobsNear(targetName or target.Name, groundCFrame)
        lastPreparedTarget = target
        lastCombatMaintenance = now
    end

    if now - lastEquipCheck >= 0.35 then
        equipWeapon(weaponType or _G.SelectWeapon)
        lastEquipCheck = now
    end

    attack()
    useSkills(forceSkills)
    return true
end
