-- PHẦN 6: VÒNG LẶP NỀN (BACKGROUND LOOPS)
------------------------------------------------------------

-- ====== LOOP 1: Auto Farm Level ======
local lastFarmStatus = "Chờ bật Auto Farm Level"
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.05)

        if _G.AutoFarmLevel and modeCanMove("level") then
            runFeature("Auto Farm Level", function()
                local level = getPlayerLevel()
                local quest = getQuestData(level)
                local method = _G.FarmMethod or "Quest"
                if not quest then
                    lastFarmStatus = "Không có dữ liệu quest cho cấp " .. level
                    return
                end

                if method == "Quest" then
                    local expectedSignature = questSignature(quest)
                    if hasActiveQuest() and acceptedQuestSignature
                        and acceptedQuestSignature ~= expectedSignature then
                        lastFarmStatus = "Đang đổi sang quest đúng cấp"
                        abandonQuest()
                        acceptedQuestSignature = nil
                        task.wait(0.35)
                        return
                    end

                    if not hasActiveQuest() then
                        lastFarmStatus = "Đang nhận quest " .. tostring(quest.MobName)
                        startQuest(quest)
                        return
                    end
                end

                local targetMob
                if method == "Nearest" then
                    targetMob = findMob("", true)
                elseif method == "Selected Mob" then
                    targetMob = findMob(_G.SelectedMob, false)
                else
                    targetMob = findMob(quest.MobName, false)
                end

                if not targetMob then
                    clearFarmTarget()
                    if method == "Quest" then
                        lastFarmStatus = "Đang chờ quái " .. tostring(quest.MobName)
                        if ensureQuestArea(quest) then
                            toTarget(CFrame.new(quest.MobPosition))
                        end
                    elseif method == "Selected Mob" then
                        lastFarmStatus = "Chưa thấy quái " .. tostring(_G.SelectedMob)
                    else
                        lastFarmStatus = "Chưa thấy quái gần nhân vật"
                    end
                    return
                end

                local bringName = method == "Quest" and quest.MobName
                    or method == "Selected Mob" and _G.SelectedMob
                    or targetMob.Name
                lastFarmStatus = "Đang đánh " .. tostring(targetMob.Name)
                    .. " • " .. tostring(lastAttackMethod)
                engageTarget(targetMob, bringName, _G.SelectWeapon)
            end)
        else
            if not _G.AutoFarmLevel then
                lastFarmStatus = "Chờ bật Auto Farm Level"
            end
        end
    end
end)

-- ====== LOOP 2: Auto Farm Mastery ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.03)

        if _G.AutoFarmMastery and modeCanMove("mastery") then
            runFeature("Auto Farm Mastery", function()
                local targetMob = findMob("", true)
                if targetMob then
                    engageTarget(targetMob, targetMob.Name, _G.MasteryWeapon)
                else
                    clearFarmTarget()
                end
            end)
        end
    end
end)
-- ====== LOOP 3: Auto Farm Boss ======
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.03)

        if _G.AutoFarmBoss and modeCanMove("boss") then
            runFeature("Auto Farm Boss", function()
                local boss = findBoss(_G.SelectedBoss)
                if boss then
                    engageTarget(boss, boss.Name, _G.SelectWeapon)
                    return
                end

                local bossData = getBossData(_G.SelectedBoss)
                clearFarmTarget()
                if bossData then
                    toTarget(CFrame.new(bossData.Position))
                    task.wait(0.5)
                end
            end)
        end
    end
end)
-- ====== LOOP 4: Auto Farm Sea Beast ======
local lastSeaBeastWarning = 0
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.05)

        if _G.AutoFarmSeaBeast and modeCanMove("sea_beast") then
            runFeature("Auto Sea Beast", function()
                if WorldSea == 1 then
                    if os.clock() - lastSeaBeastWarning >= 15 then
                        lastSeaBeastWarning = os.clock()
                        notify("Quái biển", "Quái biển chỉ xuất hiện tại Biển 2 và Biển 3.", 5)
                    end
                    return
                end
                local candidates = {}
                for _, obj in ipairs(workspace:GetChildren()) do
                    table.insert(candidates, obj)
                    if obj:IsA("Folder") and string.find(string.lower(obj.Name), "sea", 1, true) then
                        for _, child in ipairs(obj:GetChildren()) do table.insert(candidates, child) end
                    end
                end

                for _, obj in ipairs(candidates) do
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local rootPart = obj:FindFirstChild("HumanoidRootPart")
                    local lowerName = string.lower(obj.Name)
                    if humanoid and humanoid.Health > 0 and rootPart
                        and (string.find(lowerName, "sea beast", 1, true)
                            or string.find(lowerName, "seabeast", 1, true)) then
                        engageTarget(obj, obj.Name, _G.SelectWeapon, true)
                        return
                    end
                end
                clearFarmTarget()
            end)
        end
    end
end)

-- Hoàn nguyên mục tiêu cũ khi đổi chế độ, tránh hai chế độ dùng chung tween/noclip.
local supervisedMovementMode = nil
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(0.15)
        local mode = getActiveMovementMode()
        if mode ~= supervisedMovementMode then
            if farmState ~= "idle" or activeFarmTarget or currentTween then
                stopFarmMovement()
            end
            supervisedMovementMode = mode
        elseif mode == nil and (farmState ~= "idle" or activeFarmTarget or currentTween) then
            stopFarmMovement()
        end
    end
end)
