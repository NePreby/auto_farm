-- ====== LOOP 5: Duy trì Haki / Observation ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.75)
        if _G.AutoHaki or _G.AutoKen or _G.AutoObsV2 then
            checkHaki()
        end
        if _G.AutoFarmObs then activateObservation(false) end
    end
end)

-- ====== LOOP 6: Auto Farm Bone ======
local BoneMobNames = {
    ["reborn skeleton"] = true,
    ["living zombie"] = true,
    ["demonic soul"] = true,
    ["posessed mummy"] = true,
    ["evil wraith"] = true,
}
local lastBoneWarning = 0

task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.08)
        if _G.AutoFarmBone and modeCanMove("bone") then
            runFeature("Auto Farm Bone", function()
                if WorldSea ~= 3 then
                    if os.clock() - lastBoneWarning >= 12 then
                        lastBoneWarning = os.clock()
                        notify("Kiếm Xương", "Chỉ kiếm Xương ổn định tại Lâu đài ma ở Biển 3.", 5)
                    end
                    return
                end

                local target = nil
                local nearest = math.huge
                local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local humanoid = mob:FindFirstChildOfClass("Humanoid")
                        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                        if BoneMobNames[normalizeMobName(mob.Name)] and humanoid
                            and humanoid.Health > 0 and mobRoot then
                            local distance = rootPart and (mobRoot.Position - rootPart.Position).Magnitude or 0
                            if distance < nearest then
                                nearest = distance
                                target = mob
                            end
                        end
                    end
                end

                if target then
                    engageTarget(target, target.Name, _G.SelectWeapon)
                else
                    clearFarmTarget()
                    toTarget(CFrame.new(IslandsSea3["Haunted Castle"]))
                end
            end)
        end
    end
end)

-- ====== LOOP 7: Auto Fruit Finder & Collector ======
local announcedFruits = setmetatable({}, {__mode = "k"})
local lastFruitStatus = "Chờ bật Auto Nhặt Trái"
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.5)

        if not _G.AutoCollectFruit then activeFruitTarget = nil end
        if _G.AutoFruitFinder or _G.AutoCollectFruit then
            runFeature("Theo dõi trái", function()
                local fruits = getSpawnedFruits()
                local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                lastFruitStatus = #fruits > 0 and ("Tìm thấy " .. #fruits .. " trái") or "Không có trái trên bản đồ"

                if _G.AutoFruitFinder then
                    for _, fruit in ipairs(fruits) do
                        if not announcedFruits[fruit] then
                            announcedFruits[fruit] = true
                            local handle = getFruitHandle(fruit)
                            local distance = rootPart and handle
                                and math.floor((handle.Position - rootPart.Position).Magnitude) or 0
                            notify("🍎 Phát hiện trái", fruit.Name .. " [" .. distance .. "m]", 6)
                        end
                    end
                end

                if _G.AutoCollectFruit then
                    local fruit = findNearestFruit()
                    activeFruitTarget = fruit
                    local handle = getFruitHandle(fruit)
                    if fruit and handle and modeCanMove("fruit") then
                        lastFruitStatus = "Đang nhặt " .. fruit.Name
                        toTarget(handle.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.12)
                        touchFruit(fruit)
                        if not fruit.Parent or not getFruitHandle(fruit) then
                            activeFruitTarget = nil
                            lastFruitStatus = "Đã nhặt " .. fruit.Name
                        end
                    elseif not fruit then
                        activeFruitTarget = nil
                    end
                end
            end)
        end
    end
end)
-- ====== LOOP 8: Auto Raid / Farm Fragment ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        local movementMode = getActiveMovementMode()
        local wantsRaid = (_G.AutoFarmFragment and movementMode == "fragment")
            or (_G.AutoRaid and (movementMode == nil or movementMode == "raid"))
        local wantsCombat = (_G.AutoRaidFarm and movementMode == "raid")
            or (_G.AutoFarmFragment and movementMode == "fragment")
        task.wait((wantsRaid and wantsCombat) and 0.05 or 0.8)

        if wantsRaid then
            runFeature("Auto Raid", function()
                if not isInRaid() then
                    startSelectedRaid()
                    return
                end

                if wantsCombat then
                    local targetMob = findMob("", true)
                    if targetMob then
                        engageTarget(targetMob, targetMob.Name, _G.SelectWeapon)
                    else
                        clearFarmTarget()
                    end
                end
            end)
        end
    end
end)

-- ====== LOOP 9: Auto Awakening ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(5)
        if _G.AutoAwakening then
            runFeature("Auto Awakening", function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakener", "Check")
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakener", "Awaken")
            end)
        end
    end
end)

-- ====== LOOP 10: Auto Stats ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.3)
        if _G.AutoStats then
            runFeature("Auto Stats", function()
                local data = getPlayerData()
                local pointsObj = data and data:FindFirstChild("Points")
                if pointsObj and pointsObj.Value > 0 then
                    local statName = _G.StatToUpgrade == "Blox Fruit"
                        and "Demon Fruit" or _G.StatToUpgrade
                    ReplicatedStorage.Remotes.CommF_:InvokeServer(
                        "AddPoint", statName, math.min(pointsObj.Value, 3)
                    )
                end
            end)
        end
    end
end)

-- ====== LOOP 11: Auto Farm Chest ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.5)
        if _G.AutoFarmChest and modeCanMove("chest") then
            runFeature("Auto Farm Chest", function()
                local targetChest = nil
                local char = Player.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                local closestDist = math.huge

                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():find("chest") then
                        if rootPart then
                            local d = (obj.Position - rootPart.Position).Magnitude
                            if d < closestDist then
                                closestDist = d
                                targetChest = obj
                            end
                        else
                            targetChest = obj
                            break
                        end
                    end
                end

                if targetChest then
                    toTarget(targetChest.CFrame)
                    task.wait(0.3)
                end
            end)
        end
    end
end)

-- ====== LOOP 12: Auto Gacha Fruit ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(30)
        if _G.AutoGachaFruit then
            runFeature("Auto Gacha", function()
                local res = nil
                pcall(function()
                    res = ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
                end)
                local msg = tostring(res or "Đã gửi yêu cầu mua trái ngẫu nhiên.")
                notify("🎰 Mua Trái ngẫu nhiên", msg, 6)
            end)
        end
    end
end)

-- ====== LOOP 13: Speed / Jump / Energy ======
local humanoidDefaults = setmetatable({}, {__mode = "k"})
local function rememberHumanoidDefaults(humanoid)
    if humanoid and not humanoidDefaults[humanoid] then
        humanoidDefaults[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
        }
    end
end

local function restoreMovementStats(statName)
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local defaults = humanoid and humanoidDefaults[humanoid]
    if not humanoid or not defaults then return end
    if statName == nil or statName == "WalkSpeed" then humanoid.WalkSpeed = defaults.WalkSpeed end
    if statName == nil or statName == "JumpPower" then humanoid.JumpPower = defaults.JumpPower end
end

task.spawn(function()
    RunService.RenderStepped:Connect(function()
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
        runFeature("Di chuyển", function()
            local char = Player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            rememberHumanoidDefaults(humanoid)

            if _G.WalkSpeedHack then humanoid.WalkSpeed = tonumber(_G.WalkSpeedVal) or 50 end
            if _G.JumpPowerHack then humanoid.JumpPower = tonumber(_G.JumpPowerVal) or 100 end

            if _G.InfiniteEnergy then
                local energy = char:FindFirstChild("Energy")
                    or Player:FindFirstChild("Energy")
                if energy and (energy:IsA("NumberValue") or energy:IsA("IntValue")) then
                    energy.Value = math.max(energy.Value, 5000)
                end
            end
        end)
    end)
end)

-- ====== LOOP 14: Infinite Jump ======
UserInputService.JumpRequest:Connect(function()
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if _G.InfiniteJump then
        pcall(function()
            local char = Player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- ====== LOOP 15: Anti-AFK ======
Player.Idled:Connect(function()
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    if _G.AntiAFK then
        runFeature("Anti AFK", function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end)
    end
end)

-- ====== LOOP 16: ESP Update Loop ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(1.5)
        runFeature("ESP", function()
            local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            local seen = {}
            local maxDistance = math.max(100, tonumber(_G.ESPDistance) or 2000)

            if _G.ESPPlayer then
                for _, plr in ipairs(Players:GetPlayers()) do
                    local char = plr.Character
                    local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    local sameTeam = _G.ESPTeamCheck and plr.Team ~= nil and plr.Team == Player.Team
                    if plr ~= Player and targetRoot and humanoid and humanoid.Health > 0 and not sameTeam
                        and (targetRoot.Position - rootPart.Position).Magnitude <= maxDistance then
                        seen[char] = true
                        createESP(char, "player", _G.ESPPlayerColor,
                            plr.DisplayName .. "  HP " .. math.floor(humanoid.Health))
                    end
                end
            end

            local enemies = workspace:FindFirstChild("Enemies")
            if (_G.ESPMob or _G.ESPBoss) and enemies then
                for _, mob in ipairs(enemies:GetChildren()) do
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    local targetRoot = mob:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and targetRoot
                        and (targetRoot.Position - rootPart.Position).Magnitude <= maxDistance then
                        local lowerName = string.lower(mob.Name)
                        local isBoss = string.find(lowerName, "[boss]", 1, true) ~= nil
                            or string.find(lowerName, "[raid boss]", 1, true) ~= nil
                            or getBossData(mob.Name) ~= nil
                        if isBoss and _G.ESPBoss then
                            seen[mob] = true
                            createESP(mob, "boss", _G.ESPBossColor,
                                "⭐ " .. normalizeMobName(mob.Name) .. "  HP " .. math.floor(humanoid.Health))
                        elseif not isBoss and _G.ESPMob then
                            seen[mob] = true
                            createESP(mob, "mob", _G.ESPMobColor, normalizeMobName(mob.Name))
                        end
                    end
                end
            end

            if _G.FruitESP then
                for _, fruit in ipairs(getSpawnedFruits()) do
                    local handle = getFruitHandle(fruit)
                    if handle and (handle.Position - rootPart.Position).Magnitude <= maxDistance then
                        seen[fruit] = true
                        createESP(fruit, "fruit", _G.ESPFruitColor, "🍎 " .. fruit.Name)
                    end
                end
            end

            if _G.ESPChest or _G.ESPFlower then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Position - rootPart.Position).Magnitude <= maxDistance then
                        local lowerName = string.lower(obj.Name)
                        if _G.ESPChest and string.find(lowerName, "chest", 1, true) then
                            seen[obj] = true
                            createESP(obj, "chest", _G.ESPChestColor, "📦 Chest")
                        elseif _G.ESPFlower and (string.find(lowerName, "flower", 1, true)
                            or string.find(lowerName, "flora", 1, true)) then
                            seen[obj] = true
                            createESP(obj, "flower", _G.ESPFlowerColor, "🌸 " .. obj.Name)
                        end
                    end
                end
            end

            pruneESP(seen)
            if _G.ESPIsland and #islandParts == 0 then setIslandESP(true) end
            if not _G.ESPIsland and #islandParts > 0 then clearIslandESP() end
        end)
    end
end)
-- ====== LOOP 17: Auto Dodge ======
local lastDodgeTime = 0
local HazardWords = {"projectile", "bullet", "missile", "blast", "attack", "slash", "beam"}
local function looksLikeHazard(part)
    if not part:IsA("BasePart") or part.Anchored then return false end
    local lowerName = string.lower(part.Name)
    for _, word in ipairs(HazardWords) do
        if string.find(lowerName, word, 1, true) then return true end
    end
    return false
end

task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.15)
        if _G.AutoDodge and getActiveMovementMode() == nil
            and os.clock() - lastDodgeTime >= 0.8 then
            runFeature("Auto Dodge", function()
                local char = Player.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                if not humanoid or humanoid.Health <= 0 or not rootPart then return end

                local containers = {workspace:FindFirstChild("_WorldOrigin"), workspace:FindFirstChild("Effects")}
                for _, container in ipairs(containers) do
                    if container then
                        for _, obj in ipairs(container:GetDescendants()) do
                            if looksLikeHazard(obj) and (obj.Position - rootPart.Position).Magnitude < 28 then
                                local side = math.random(0, 1) == 0 and -10 or 10
                                rootPart.CFrame = rootPart.CFrame * CFrame.new(side, 0, 0)
                                rootPart.AssemblyLinearVelocity = Vector3.zero
                                lastDodgeTime = os.clock()
                                return
                            end
                        end
                    end
                end
            end)
        end
    end
end)
-- ====== LOOP 18: Server Hop khi hết mob/trái ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(30)
        if _G.ServerHopNoFruit then
            runFeature("Server Hop Fruit", function()
                local hasFruit = #getSpawnedFruits() > 0
                if not hasFruit then
                    notify("Đổi máy chủ", "Không có Trái, đang chuyển máy chủ ít người...", 3)
                    task.wait(2)
                    serverHop(true, _G.LowServerMaxPlayers)
                end
            end)
        end
    end
end)

-- ====== Sự kiện khi chết → thông báo + tiếp tục farm ======
Player.CharacterAdded:Connect(function(char)
    if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then return end
    task.wait(1)
    if _G.AutoChooseTeam and not teamIsSelected() then
        choosePreferredTeam(false)
    end
    if _G.AutoFarmLevel or _G.AutoFarmMastery or _G.AutoFarmBoss then
        notify("💀 Đã hồi sinh", "Tiếp tục hoạt động tự động...", 3)
    end
end)

local function buildSystemDiagnostic()
    local passed, failed, notes = 0, {}, {}
    local function check(name, condition)
        if condition then
            passed = passed + 1
        else
            table.insert(failed, name)
        end
    end

    local char = Player.Character
    check("Nhân vật", char and char:FindFirstChildOfClass("Humanoid")
        and char:FindFirstChild("HumanoidRootPart"))
    check("Player.Data.Level", Player:FindFirstChild("Data")
        and Player.Data:FindFirstChild("Level"))
    check("Remote CommF_", ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("CommF_"))
    check("Folder Enemies", workspace:FindFirstChild("Enemies"))
    check("Dữ liệu quest Sea hiện tại", getQuestData(
        getPlayerLevel()
    ) ~= nil)
    check("VirtualInputManager", VirtualInputManager ~= nil)

    if type(firetouchinterest) ~= "function" then
        table.insert(notes, "Nhặt trái: dùng fallback chạm trực tiếp")
    end
    if type(fireclickdetector) ~= "function" then
        table.insert(notes, "Raid: cần tự bấm nút khởi động")
    end
    if not teleportReloadReady then
        table.insert(notes, "Đổi server: executor không hỗ trợ tự nạp")
    end

    local runtimeErrors = {}
    for featureName, info in pairs(featureErrors) do
        table.insert(runtimeErrors, featureName .. ": " .. tostring(info.Message))
    end
    table.sort(runtimeErrors)

    if RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR then
        table.insert(notes, "Lỗi khởi động: " .. tostring(RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR))
    end

    local status = "Kiểm tra lõi: " .. passed .. "/" .. (passed + #failed)
    if #failed > 0 then status = status .. "\nThiếu: " .. table.concat(failed, ", ") end
    if #notes > 0 then status = status .. "\nLưu ý: " .. table.concat(notes, "; ") end
    if #runtimeErrors > 0 then
        status = status .. "\nLỗi gần nhất: " .. table.concat(runtimeErrors, " | ")
    else
        status = status .. "\nKhông ghi nhận lỗi vòng chạy."
    end
    status = status .. "\nChế độ di chuyển: " .. tostring(getActiveMovementMode() or "không")
    status = status .. "\nFarm: " .. tostring(lastFarmStatus)
    status = status .. "\nTrái: " .. tostring(lastFruitStatus)
    status = status .. "\nĐánh: " .. tostring(lastAttackMethod)
    return status
end
------------------------------------------------------------
