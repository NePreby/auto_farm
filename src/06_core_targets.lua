-- ====== Lấy quest phù hợp level ======
local function getQuestData(level)
    local questTable
    if WorldSea == 1 then questTable = QuestsSea1
    elseif WorldSea == 2 then questTable = QuestsSea2
    elseif WorldSea == 3 then questTable = QuestsSea3
    else questTable = QuestsSea1
    end

    for _, data in ipairs(questTable) do
        if level >= data.MinLevel and level <= data.MaxLevel then
            return data
        end
    end
    -- Fallback: trả về quest cuối cùng nếu quá level
    return questTable[#questTable]
end

-- ====== Kiểm tra quest đang hoạt động ======
local function getQuestGui()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("Main")
    return mainGui and mainGui:FindFirstChild("Quest")
end

local function hasActiveQuest()
    local questGui = getQuestGui()
    return questGui ~= nil and questGui.Visible == true
end

local function getActiveQuestText()
    local questGui = getQuestGui()
    if not questGui or not questGui.Visible then return "" end

    local parts = {}
    for _, item in ipairs(questGui:GetDescendants()) do
        if (item:IsA("TextLabel") or item:IsA("TextButton")) and item.Text ~= "" then
            table.insert(parts, string.lower(item.Text))
        end
    end
    return table.concat(parts, " ")
end

local acceptedQuestSignature = nil
local function questSignature(quest)
    if not quest then return "" end
    return tostring(quest.QuestName) .. ":" .. tostring(quest.QuestNumber)
end

local function abandonQuest()
    runFeature("Bỏ nhiệm vụ cũ", function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
    end)
end

local lastSubmergedTravel = 0
local lastQuestWarning = 0

local function ensureQuestArea(quest)
    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    if quest.Travel == "Submerged" and rootPart.Position.Y > -1000 then
        if tick() - lastSubmergedTravel < 8 then return false end
        lastSubmergedTravel = tick()

        toTarget(CFrame.new(-16269.704, 25.229, 1373.660))
        task.wait(1)

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local submarineRemote = remotes and remotes:FindFirstChild("RF/SubmarineWorkerSpeak")
        if submarineRemote then
            pcall(function()
                submarineRemote:InvokeServer("TravelToSubmergedIsland")
            end)
            task.wait(5)
        else
            warn("[HAOTOOL] Không tìm thấy remote đi Submerged Island.")
            return false
        end
    elseif quest.Entrance
        and (rootPart.Position - quest.QuestNpc).Magnitude > 3000 then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", quest.Entrance)
        end)
        task.wait(1)
    end

    return true
end

local function startQuest(quest)
    clearFarmTarget()
    if not ensureQuestArea(quest) then return false end

    if not toTarget(CFrame.new(quest.QuestNpc)) then return false end
    if not _G.AutoFarmLevel then return false end

    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart or (rootPart.Position - quest.QuestNpc).Magnitude > 30 then
        return false
    end

    for _ = 1, 3 do
        if not _G.AutoFarmLevel then return false end
        if hasActiveQuest() then
            acceptedQuestSignature = questSignature(quest)
            return true
        end

        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer(
                "StartQuest", quest.QuestName, quest.QuestNumber
            )
        end)

        task.wait(0.7)
    end

    if not hasActiveQuest() and tick() - lastQuestWarning > 8 then
        lastQuestWarning = tick()
        warn(string.format(
            "[HAOTOOL] Nhận quest thất bại: %s #%s",
            tostring(quest.QuestName),
            tostring(quest.QuestNumber)
        ))
    end

    local active = hasActiveQuest()
    if active then acceptedQuestSignature = questSignature(quest) end
    return active
end

-- ====== Tìm quái theo tên (gần nhất) ======
local function getFruitHandle(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end

    local handle = obj:FindFirstChild("Handle", true)
    if handle and handle:IsA("BasePart") then return handle end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end

    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return part
end

local function isFruitObject(obj)
    if not obj or not (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart")) then
        return false
    end
    local lowerName = string.lower(obj.Name)
    local hasFruitName = string.find(lowerName, "fruit", 1, true) ~= nil
        or string.find(lowerName, "trái", 1, true) ~= nil
    return hasFruitName and getFruitHandle(obj) ~= nil
end

local function getSpawnedFruits()
    local fruits, seen = {}, {}
    local function addFrom(container, recursive)
        if not container then return end
        local objects = recursive and container:GetDescendants() or container:GetChildren()
        for _, obj in ipairs(objects) do
            if isFruitObject(obj) and not seen[obj] then
                seen[obj] = true
                table.insert(fruits, obj)
            end
        end
    end

    addFrom(workspace, false)
    for _, folderName in ipairs({"Fruit", "Fruits", "SpawnedFruits"}) do
        addFrom(workspace:FindFirstChild(folderName), true)
    end
    return fruits
end

local function findNearestFruit()
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local closest, closestDistance = nil, math.huge
    for _, fruit in ipairs(getSpawnedFruits()) do
        local handle = getFruitHandle(fruit)
        if handle then
            local distance = rootPart and (handle.Position - rootPart.Position).Magnitude or 0
            if distance < closestDistance then
                closest, closestDistance = fruit, distance
            end
        end
    end
    return closest, closestDistance
end

local function touchFruit(fruit)
    local handle = getFruitHandle(fruit)
    local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not handle or not rootPart then return false end

    if type(firetouchinterest) == "function" then
        local ok = runFeature("Nhặt trái", function()
            firetouchinterest(rootPart, handle, 0)
            task.wait(0.08)
            firetouchinterest(rootPart, handle, 1)
        end)
        return ok
    end

    -- Fallback: chạm vật lý vào Handle khi executor không có firetouchinterest.
    rootPart.CFrame = handle.CFrame
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.35)
    return not fruit.Parent or getFruitHandle(fruit) == nil
end
local function findMob(mobName, useNearest)
    if not workspace:FindFirstChild("Enemies") then return nil end
    local char = Player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")

    local closest = nil
    local closestDist = math.huge

    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
            and mob:FindFirstChild("HumanoidRootPart") then

            local nameMatch = (mobName == "" or mobName == nil or mobNameMatches(mob.Name, mobName))
            if useNearest then nameMatch = true end

            if nameMatch then
                if rootPart then
                    local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = mob
                    end
                else
                    closest = mob
                    break
                end
            end
        end
    end
    return closest
end

-- ====== Tìm boss ======
findBoss = function(bossName)
    if not workspace:FindFirstChild("Enemies") then return nil end
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mobNameMatches(mob.Name, bossName)
            and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
            and mob:FindFirstChild("HumanoidRootPart") then
            return mob
        end
    end
    return nil
end

-- ====== Lấy danh sách quái hiện có ======
local function getEnemyList()
    local enemies = {}
    pcall(function()
        if workspace:FindFirstChild("Enemies") then
            for _, mob in pairs(workspace.Enemies:GetChildren()) do
                if mob:FindFirstChild("Humanoid") and not table.find(enemies, mob.Name) then
                    table.insert(enemies, mob.Name)
                end
            end
        end
    end)
    if #enemies == 0 then
        return {"(Không có quái)"}
    end
    table.sort(enemies)
    return enemies
end

-- ====== Lấy danh sách boss theo Sea ======
local function getBossList()
    local bosses, known = {}, {}
    local bossTable = WorldSea == 1 and BossesSea1
        or WorldSea == 2 and BossesSea2 or BossesSea3

    local function addBoss(name)
        local clean = normalizeMobName(name)
        if clean ~= "" and not known[clean] then
            known[clean] = true
            -- gsub trả về 2 giá trị; ngoặc ép còn 1 giá trị cho table.insert.
            table.insert(bosses, (clean:gsub("(%a)([%w']*)", function(a, b)
                return string.upper(a) .. b
            end)))
        end
    end

    for _, boss in ipairs(bossTable) do addBoss(boss.Name) end
    local containers = {workspace:FindFirstChild("Enemies"), ReplicatedStorage:FindFirstChild("Enemies"), ReplicatedStorage}
    for _, container in ipairs(containers) do
        if container then
            for _, mob in ipairs(container:GetChildren()) do
                local lowerName = string.lower(mob.Name)
                if string.find(lowerName, "[boss]", 1, true)
                    or string.find(lowerName, "[raid boss]", 1, true) then
                    addBoss(mob.Name)
                end
            end
        end
    end
    table.sort(bosses)
    return bosses
end

-- ====== Tìm boss data theo tên ======
local function getBossData(bossName)
    local tables = {BossesSea1, BossesSea2, BossesSea3}
    local idx = math.clamp(WorldSea, 1, 3)
    for _, b in ipairs(tables[idx]) do
        if mobNameMatches(b.Name, bossName) then return b end
    end
    return nil
end

local function getBossStatusList(bossNames)
    local labels, labelToName, nameToLabel = {}, {}, {}
    local aliveNames = {}

    for _, bossName in ipairs(bossNames or getBossList()) do
        local boss = findBoss(bossName)
        local label
        if boss then
            label = "🟢 " .. bossName .. " — Đang xuất hiện"
            table.insert(aliveNames, bossName)
        else
            label = "⚫ " .. bossName .. " — Chưa xuất hiện"
        end
        table.insert(labels, label)
        labelToName[label] = bossName
        nameToLabel[bossName] = label
    end

    local summary = "Đang xuất hiện: " .. #aliveNames .. "/" .. #labels
    if #aliveNames > 0 then
        summary = summary .. "\n🟢 " .. table.concat(aliveNames, ", ")
    else
        summary = summary .. "\nHiện chưa có Trùm nào trong máy chủ."
    end
    return labels, labelToName, nameToLabel, summary, table.concat(labels, "\n")
end

-- ====== Chuyển máy chủ, ưu tiên máy chủ ít người ======
local serverHopBusy = false
local function serverHop(preferLowPopulation, wantedMaximum)
    if serverHopBusy then return false, "Hệ thống đang tìm máy chủ." end
    serverHopBusy = true

    local ok, result = pcall(function()
        local available, visitedFallback = {}, {}
        local visited = RuntimeEnv.HAOTOOL_VISITED_SERVERS or {}
        RuntimeEnv.HAOTOOL_VISITED_SERVERS = visited
        local cursor = nil

        -- Đọc tối đa 300 máy chủ công khai rồi sắp theo số người và độ trễ.
        for _ = 1, 3 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor and cursor ~= "" then
                url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
            end

            local data = HttpService:JSONDecode(game:HttpGet(url, true))
            for _, server in ipairs(data.data or {}) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(visited[server.id] and visitedFallback or available, server)
                end
            end
            cursor = data.nextPageCursor
            if not cursor or cursor == "" then break end
        end

        local candidates = #available > 0 and available or visitedFallback
        table.sort(candidates, function(a, b)
            if a.playing == b.playing then
                return (tonumber(a.ping) or math.huge) < (tonumber(b.ping) or math.huge)
            end
            return a.playing < b.playing
        end)
        if #candidates == 0 then error("Không tìm thấy máy chủ còn chỗ trống.") end

        local chosen = nil
        if preferLowPopulation then
            local maximum = math.clamp(tonumber(wantedMaximum) or 5, 1, 12)
            for _, server in ipairs(candidates) do
                if server.playing <= maximum then
                    chosen = server
                    break
                end
            end
            chosen = chosen or candidates[1]
        else
            chosen = candidates[math.random(1, math.min(#candidates, 20))]
        end

        visited[chosen.id] = true
        saveTeleportState()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, Player)
        return chosen
    end)

    serverHopBusy = false
    if not ok then return false, tostring(result) end
    return true, result
end

