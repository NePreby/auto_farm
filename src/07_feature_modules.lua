-- ====== Notify helper ======
local function notify(title, content, duration)
    pcall(function()
        Fluent:Notify({
            Title = title or "HAOTOOL",
            Content = content or "",
            Duration = duration or 4,
        })
    end)
end

-- ====== Cửa hàng cận chiến & kỹ năng ======
local CombatShop = {}
do
local styleEntries = {
    {
        Id = "Dark Step",
        Label = "Dark Step — 150.000 Beli",
        Price = "150.000 Beli",
        Requirement = "Không yêu cầu.",
        Command = "BuyBlackLeg",
    },
    {
        Id = "Electric",
        Label = "Electric — 500.000 Beli",
        Price = "500.000 Beli",
        Requirement = "Không yêu cầu.",
        Command = "BuyElectro",
    },
    {
        Id = "Water Kung Fu",
        Label = "Water Kung Fu — 750.000 Beli",
        Price = "750.000 Beli",
        Requirement = "Không yêu cầu.",
        Command = "BuyFishmanKarate",
    },
    {
        Id = "Dragon Breath",
        Label = "Dragon Breath — 1.500 Mảnh",
        Price = "1.500 Mảnh",
        Requirement = "Từ Biển 2.",
        Special = "DragonBreath",
    },
    {
        Id = "Superhuman",
        Label = "Superhuman — 3.000.000 Beli",
        Price = "3.000.000 Beli",
        Requirement = "300 thông thạo Dark Step, Electric, Water Kung Fu và Dragon Breath.",
        Command = "BuySuperhuman",
    },
    {
        Id = "Death Step",
        Label = "Death Step — 2.500.000 Beli + 5.000 Mảnh",
        Price = "2.500.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Dark Step và đã mở phòng bằng Library Key.",
        Command = "BuyDeathStep",
    },
    {
        Id = "Sharkman Karate",
        Label = "Sharkman Karate — 2.500.000 Beli + 5.000 Mảnh",
        Price = "2.500.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Water Kung Fu và Water Key.",
        Command = "BuySharkmanKarate",
    },
    {
        Id = "Electric Claw",
        Label = "Electric Claw — 3.000.000 Beli + 5.000 Mảnh",
        Price = "3.000.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Electric và hoàn thành nhiệm vụ Previous Hero.",
        Command = "BuyElectricClaw",
    },
    {
        Id = "Dragon Talon",
        Label = "Dragon Talon — 3.000.000 Beli + 5.000 Mảnh",
        Price = "3.000.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo Dragon Breath và Fire Essence.",
        Command = "BuyDragonTalon",
    },
    {
        Id = "Godhuman",
        Label = "Godhuman — 5.000.000 Beli + 5.000 Mảnh",
        Price = "5.000.000 Beli + 5.000 Mảnh",
        Requirement = "400 thông thạo 5 phong cách nâng cao; 20 Fish Tail, 20 Magma Ore, 10 Dragon Scale, 10 Mystic Droplet.",
        Command = "BuyGodhuman",
    },
    {
        Id = "Sanguine Art",
        Label = "Sanguine Art — 5.000.000 Beli + 5.000 Mảnh",
        Price = "5.000.000 Beli + 5.000 Mảnh",
        Requirement = "Leviathan Heart; 2 Dark Fragment, 20 Vampire Fang và 20 Demonic Wisp.",
        Command = "BuySanguineArt",
    },
}

local abilityEntries = {
    {
        Id = "AirJump",
        Name = "Nhảy trên không",
        Price = "10.000 Beli",
        Requirement = "Không yêu cầu.",
        Args = {"BuyHaki", "Geppo"},
    },
    {
        Id = "Aura",
        Name = "Haki Vũ Trang / Aura",
        Price = "25.000 Beli",
        Requirement = "Không yêu cầu.",
        Args = {"BuyHaki", "Buso"},
    },
    {
        Id = "FlashStep",
        Name = "Bước nhanh / Flash Step",
        Price = "100.000 Beli",
        Requirement = "Không yêu cầu.",
        Args = {"BuyHaki", "Soru"},
    },
    {
        Id = "Instinct",
        Name = "Haki Quan Sát / Instinct",
        Price = "750.000 Beli",
        Requirement = "Cấp 300 trở lên và đã hoàn thành Saber Puzzle.",
        Args = {"KenTalk", "Buy"},
    },
}

local styleById, styleIdByLabel, abilityById = {}, {}, {}
CombatShop.StyleLabels = {}
for _, entry in ipairs(styleEntries) do
    styleById[entry.Id] = entry
    styleIdByLabel[entry.Label] = entry.Id
    table.insert(CombatShop.StyleLabels, entry.Label)
end
for _, entry in ipairs(abilityEntries) do
    abilityById[entry.Id] = entry
end

local function invokeCombatShop(...)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF or not commF:IsA("RemoteFunction") then
        return false, "Không tìm thấy hệ thống cửa hàng của game."
    end

    local args = table.pack(...)
    local ok, result = pcall(function()
        return commF:InvokeServer(table.unpack(args, 1, args.n))
    end)
    return ok, result
end

local function resultText(ok, result)
    if not ok then return "Lỗi: " .. tostring(result) end
    if result == nil or tostring(result) == "" then return "Game đã nhận yêu cầu mua." end
    return "Phản hồi game: " .. tostring(result)
end

CombatShop.GetStyleId = function(label)
    return styleIdByLabel[label] or label
end

CombatShop.GetStyleLabel = function(styleId)
    local entry = styleById[styleId]
    return entry and entry.Label or CombatShop.StyleLabels[1]
end

CombatShop.GetStyleInfo = function(styleId)
    return styleById[styleId]
end

CombatShop.BuyStyle = function(styleId)
    local entry = styleById[styleId]
    if not entry then
        notify("Cửa hàng cận chiến", "Chưa chọn phong cách hợp lệ.", 4)
        return false
    end

    local ok, result
    if entry.Special == "DragonBreath" then
        invokeCombatShop("BlackbeardReward", "DragonClaw", "1")
        ok, result = invokeCombatShop("BlackbeardReward", "DragonClaw", "2")
    else
        ok, result = invokeCombatShop(entry.Command)
    end

    notify(
        "Mua " .. entry.Id,
        "Giá: " .. entry.Price .. "\nĐiều kiện: " .. entry.Requirement
            .. "\n" .. resultText(ok, result),
        7
    )
    return ok, result
end

CombatShop.ShowStyleInfo = function(styleId)
    local entry = styleById[styleId]
    if not entry then return end
    notify(
        entry.Id,
        "Giá: " .. entry.Price .. "\nĐiều kiện: " .. entry.Requirement,
        8
    )
end

CombatShop.BuyAbility = function(abilityId)
    local entry = abilityById[abilityId]
    if not entry then return false end
    local ok, result = invokeCombatShop(table.unpack(entry.Args))
    notify(
        "Mua " .. entry.Name,
        "Giá: " .. entry.Price .. "\nĐiều kiện: " .. entry.Requirement
            .. "\n" .. resultText(ok, result),
        6
    )
    return ok, result
end

CombatShop.BuyAllAbilities = function()
    local summary = {}
    for _, entry in ipairs(abilityEntries) do
        local ok, result = invokeCombatShop(table.unpack(entry.Args))
        table.insert(summary, entry.Name .. ": " .. resultText(ok, result))
        task.wait(0.2)
    end
    notify(
        "Mua toàn bộ kỹ năng cơ bản",
        "Tổng giá khi chưa sở hữu: 885.000 Beli\n" .. table.concat(summary, "\n"),
        10
    )
end
end

-- ====== Tự cất trái: bỏ qua trái trùng và giữ trái trùng trên tay ======
local FruitStorage = {}
do
local fruitStoreState = setmetatable({}, {__mode = "k"})
local lastFruitStoreStatus = "Chưa kiểm tra trái đang giữ"

local FruitIdentityAliases = {
    kilo = "rocket", rocket = "rocket",
    chop = "blade", blade = "blade",
    falcon = "eagle", eagle = "eagle",
    barrier = "creation", creation = "creation",
    door = "portal", portal = "portal",
    paw = "pain", pain = "pain",
    soul = "spirit", spirit = "spirit",
    revive = "ghost", ghost = "ghost",
    string = "spider", spider = "spider",
}

local LegacyFruitInternalNames = {
    buddha = "Human-Human: Buddha",
    phoenix = "Bird-Bird: Phoenix",
    falcon = "Bird-Bird: Falcon",
}

local function fruitBaseName(value)
    if type(value) ~= "string" then return "" end
    local text = string.lower(value)
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    text = text:gsub("%s+fruit%s*$", "")

    local afterColon = text:match(":%s*(.+)$")
    if afterColon and afterColon ~= "" then
        text = afterColon
    elseif string.find(text, "-", 1, true) then
        text = text:match("^([^%-]+)") or text
    end

    text = text:gsub("[^%w]", "")
    return FruitIdentityAliases[text] or text
end

local function fruitToolIdentityValues(tool)
    local values, seen = {}, {}
    local function add(value)
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(values, value)
        end
    end

    add(tool and tool.Name)
    if tool then
        for _, attributeName in ipairs({"FruitName", "OriginalName", "InternalName", "ItemName"}) do
            local ok, value = pcall(function() return tool:GetAttribute(attributeName) end)
            if ok then add(value) end
        end
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("StringValue") then
                local lowerName = string.lower(child.Name)
                if string.find(lowerName, "fruit", 1, true)
                    or string.find(lowerName, "original", 1, true)
                    or string.find(lowerName, "item", 1, true) then
                    add(child.Value)
                end
            end
        end
    end
    return values
end

local function getFruitRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    return commF and commF:IsA("RemoteFunction") and commF or nil
end

local function buildFruitNameSet(data)
    local names = {}
    if type(data) ~= "table" then return names end

    for key, entry in pairs(data) do
        local rawName = nil
        if type(entry) == "string" then
            rawName = entry
        elseif type(entry) == "table" then
            rawName = entry.Name or entry.name or entry.FruitName or entry.ItemName
        elseif type(key) == "string" then
            rawName = key
        end

        local base = fruitBaseName(rawName)
        if base ~= "" then names[base] = rawName end
    end
    return names
end

local function fetchStoredFruitNames()
    local commF = getFruitRemote()
    if not commF then return nil, "Không tìm thấy kho trái của game." end

    local ok, inventory = pcall(function()
        return commF:InvokeServer("getInventoryFruits")
    end)
    if not ok or type(inventory) ~= "table" then
        return nil, "Chưa đọc được danh sách trái trong kho."
    end
    return buildFruitNameSet(inventory), inventory
end

local function resolveFruitInternalName(tool)
    local identityValues = fruitToolIdentityValues(tool)
    local wantedBases = {}
    local directInternalName = nil
    for _, value in ipairs(identityValues) do
        local base = fruitBaseName(value)
        if base ~= "" then wantedBases[base] = true end
        local lowerValue = string.lower(value)
        if string.find(value, "-", 1, true)
            and not string.find(lowerValue, " fruit", 1, true) then
            directInternalName = directInternalName or value
        end
    end

    local commF = getFruitRemote()
    if commF then
        local ok, catalog = pcall(function() return commF:InvokeServer("GetFruits") end)
        if ok and type(catalog) == "table" then
            for _, entry in pairs(catalog) do
                local name = type(entry) == "table" and (entry.Name or entry.name) or nil
                if name and wantedBases[fruitBaseName(name)] then
                    return name
                end
            end
        end
    end

    if directInternalName then return directInternalName end

    for base in pairs(wantedBases) do
        if LegacyFruitInternalNames[base] then
            return LegacyFruitInternalNames[base]
        end
    end

    local displayName = tool and tool.Name or ""
    displayName = displayName:gsub("%s+[Ff][Rr][Uu][Ii][Tt]%s*$", "")
    displayName = displayName:gsub("^%s+", ""):gsub("%s+$", "")
    if displayName == "" then return nil end
    if string.find(displayName, "-", 1, true) then return displayName end
    return displayName .. "-" .. displayName
end

local function getOwnedFruitTools()
    local tools, seen = {}, {}
    local function scan(container)
        if not container then return end
        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool") and isFruitObject(object) and not seen[object] then
                seen[object] = true
                table.insert(tools, object)
            end
        end
    end
    scan(Player.Character)
    scan(Player:FindFirstChildOfClass("Backpack"))
    return tools
end

local function holdDuplicateFruit(tool)
    if not tool or not tool.Parent then return end
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if humanoid and backpack and tool.Parent == backpack then
        pcall(function() humanoid:EquipTool(tool) end)
    end
end

local function storeOwnedFruitTool(tool, force)
    if not tool or not tool.Parent or not isFruitObject(tool) then return "ignored" end
    local state = fruitStoreState[tool]
    if not state then
        state = {nextAttempt = 0, duplicateNotified = false}
        fruitStoreState[tool] = state
    end
    if not force and os.clock() < state.nextAttempt then return "waiting" end
    state.nextAttempt = os.clock() + 5

    local storedNames, inventoryError = fetchStoredFruitNames()
    if not storedNames then
        lastFruitStoreStatus = inventoryError
        return "failed"
    end

    local toolBase = ""
    for _, value in ipairs(fruitToolIdentityValues(tool)) do
        toolBase = fruitBaseName(value)
        if toolBase ~= "" then break end
    end
    if toolBase == "" then
        lastFruitStoreStatus = "Không nhận diện được " .. tostring(tool.Name)
        return "failed"
    end

    if storedNames[toolBase] then
        holdDuplicateFruit(tool)
        lastFruitStoreStatus = tool.Name .. " đã có trong kho — giữ ngoài tay"
        if not state.duplicateNotified then
            state.duplicateNotified = true
            notify("Trái đã có trong kho", tool.Name .. " được giữ ngoài tay, không cất lại.", 5)
        end
        return "duplicate"
    end

    local internalName = resolveFruitInternalName(tool)
    local commF = getFruitRemote()
    if not internalName or not commF then
        lastFruitStoreStatus = "Chưa xác định được tên kho của " .. tool.Name
        return "failed"
    end

    local ok, result = pcall(function()
        return commF:InvokeServer("StoreFruit", internalName, tool)
    end)
    if not ok then
        lastFruitStoreStatus = "Cất " .. tool.Name .. " thất bại"
        return "failed"
    end

    task.wait(0.35)
    local afterNames = fetchStoredFruitNames()
    local stored = not tool.Parent or (afterNames and afterNames[toolBase] ~= nil)
    if stored then
        lastFruitStoreStatus = "Đã cất " .. tool.Name .. " vào kho"
        notify("Đã cất trái", tool.Name .. " → kho trái", 4)
        return "stored"
    end

    local resultText = string.lower(tostring(result or ""))
    if string.find(resultText, "already", 1, true)
        or string.find(resultText, "đã có", 1, true) then
        holdDuplicateFruit(tool)
        lastFruitStoreStatus = tool.Name .. " đã có trong kho — giữ ngoài tay"
        return "duplicate"
    end

    lastFruitStoreStatus = "Game chưa xác nhận cất " .. tool.Name
    return "failed"
end

local function storeOwnedFruitsNow(force)
    local stored, duplicates, failed = 0, 0, 0
    for _, tool in ipairs(getOwnedFruitTools()) do
        local result = storeOwnedFruitTool(tool, force)
        if result == "stored" then
            stored = stored + 1
        elseif result == "duplicate" then
            duplicates = duplicates + 1
        elseif result == "failed" then
            failed = failed + 1
        end
        task.wait(0.15)
    end
    return stored, duplicates, failed
end

task.spawn(function()
    task.wait(2)
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        if _G.AutoStoreFruit then
            runFeature("Tự cất trái", function() storeOwnedFruitsNow(false) end)
            task.wait(0.8)
        else
            task.wait(1.5)
        end
    end
end)

FruitStorage.StoreNow = storeOwnedFruitsNow
FruitStorage.GetStatus = function() return lastFruitStoreStatus end
end

-- ====== Tự nhập mã x2 EXP / đặt lại chỉ số ======
local RewardCodes = {}
do
-- Danh sách đối chiếu ngày 31/07/2026; game tự bỏ qua mã đã dùng hoặc hết hạn.
local ActiveExpCodes = {
    "EASTEREXP", "LIGHTNINGABUSE", "KITTGAMING", "SUB2FER999",
    "ENYU_IS_PRO", "MAGICBUS", "JCWK", "STARCODEHEO", "BLUXXY",
    "SUB2GAMERROBOT_EXP1", "SUB2NOOBMASTER123", "SUB2DAIGROCK",
    "AXIORE", "TANTAIGAMING", "STRAWHATMAINE", "SUB2OFFICIALNOOBIE",
    "THEGREATACE", "SUB2CAPTAINMAUi",
}
local ActiveResetCodes = {
    "KITT_RESET", "SUB2GAMERROBOT_RESET1", "SUB2UNCLEKIZARU",
}

local redeemAttemptedByCode = {}
local codeCategoryAttempted = {exp = false, reset = false}
local redeemBatchBusy = false
local lastCodeStatus = "Chưa nhập mã"

local function redeemRewardCode(code)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local redeem = remotes and remotes:FindFirstChild("Redeem")
    if not redeem then return false, "Không tìm thấy hệ thống nhập mã." end

    if redeem:IsA("RemoteFunction") then
        local ok, result = pcall(function() return redeem:InvokeServer(code) end)
        return ok, result
    end
    if redeem:IsA("RemoteEvent") then
        local ok, result = pcall(function()
            redeem:FireServer(code)
            return "Đã gửi"
        end)
        return ok, result
    end
    return false, "Remote nhập mã không hợp lệ."
end

local function redeemCodeBatch(codes, label, force)
    if redeemBatchBusy then return false, "Hệ thống đang nhập nhóm mã khác." end
    redeemBatchBusy = true

    local submitted, accepted, rejected, failed = 0, 0, 0, 0
    for _, code in ipairs(codes) do
        if RuntimeEnv.HAOTOOL_RUN_TOKEN ~= CurrentRunToken then break end
        if force or not redeemAttemptedByCode[code] then
            redeemAttemptedByCode[code] = true
            submitted = submitted + 1
            local ok, result = redeemRewardCode(code)
            if ok then
                local resultText = string.lower(tostring(result or ""))
                if string.find(resultText, "already", 1, true)
                    or string.find(resultText, "invalid", 1, true)
                    or string.find(resultText, "expired", 1, true) then
                    rejected = rejected + 1
                else
                    accepted = accepted + 1
                end
            else
                failed = failed + 1
            end
            task.wait(0.18)
        end
    end

    redeemBatchBusy = false
    lastCodeStatus = string.format(
        "%s: gửi %d • nhận %d • đã dùng/hết hạn %d • lỗi %d",
        label, submitted, accepted, rejected, failed
    )
    notify("Nhập mã " .. label, lastCodeStatus, 6)
    return true, lastCodeStatus
end

task.spawn(function()
    local teamWaitStarted = os.clock()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken
        and Player.Team == nil and os.clock() - teamWaitStarted < 20 do
        task.wait(0.5)
    end
    task.wait(1)

    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        if _G.AutoRedeemExpCodes and not codeCategoryAttempted.exp then
            codeCategoryAttempted.exp = true
            redeemCodeBatch(ActiveExpCodes, "x2 EXP", false)
        elseif _G.AutoRedeemResetCodes and not codeCategoryAttempted.reset then
            codeCategoryAttempted.reset = true
            redeemCodeBatch(ActiveResetCodes, "đặt lại chỉ số", false)
        end
        task.wait(1)
    end
end)

RewardCodes.SetPending = function(category)
    if category == "exp" or category == "reset" then
        codeCategoryAttempted[category] = false
    end
end
RewardCodes.RedeemExp = function(force)
    return redeemCodeBatch(ActiveExpCodes, "x2 EXP", force == true)
end
RewardCodes.RedeemReset = function(force)
    return redeemCodeBatch(ActiveResetCodes, "đặt lại chỉ số", force == true)
end
end

-- ====== Tự chọn phe khi vào game / đổi máy chủ ======
local lastTeamAttempt = 0

local function normalizedPreferredTeam()
    return _G.PreferredTeam == "Marines" and "Marines" or "Pirates"
end

local function teamIsSelected()
    return Player.Team ~= nil and Player.Neutral == false
end

local function choosePreferredTeam(force)
    if not force and not _G.AutoChooseTeam then
        return false, "Tự chọn phe đang tắt."
    end
    if teamIsSelected() and not force then
        return true, "Nhân vật đã có phe."
    end

    local now = os.clock()
    if not force and now - lastTeamAttempt < 1 then
        return false, "Đang chờ lần thử kế tiếp."
    end
    lastTeamAttempt = now

    local picker = RuntimeEnv.HAOTOOL_STARTUP_TEAM_PICKER
    if type(picker) == "function" then
        local ok, selected, message = pcall(picker, normalizedPreferredTeam())
        if ok then return selected == true, tostring(message or "") end
    end

    local sent = false
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")
        if commF and commF:IsA("RemoteFunction") then
            commF:InvokeServer("SetTeam", normalizedPreferredTeam())
            sent = true
        end
    end)
    task.wait(0.5)
    if teamIsSelected() then return true, "Đã chọn phe." end
    return false, sent and "Đã gửi yêu cầu; đang chờ game xác nhận."
        or "Không tìm thấy hệ thống chọn phe."
end

RuntimeEnv.HAOTOOL_TEAM_CONTROLLER_READY = true
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        if _G.AutoChooseTeam and not teamIsSelected() then
            choosePreferredTeam(false)
            task.wait(0.7)
        else
            task.wait(2)
        end
    end
end)
-- ====== Raid helpers: mua chip rồi bấm nút raid thật trên bản đồ ======
local lastRaidStartAttempt = 0
local lastRaidCapabilityWarning = 0

local function isInRaid()
    local mainGui = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("Main")
    local raidTimer = mainGui and mainGui:FindFirstChild("RaidTimer", true)
    if raidTimer and raidTimer.Visible then return true end

    local origin = workspace:FindFirstChild("_WorldOrigin")
    local locations = origin and origin:FindFirstChild("Locations")
    if locations then
        for index = 1, 5 do
            if locations:FindFirstChild("Island " .. index) then return true end
        end
    end
    return false
end

local function hasRaidChip()
    local function containsChip(container)
        if not container then return false end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and string.find(string.lower(item.Name), "microchip", 1, true) then
                return true
            end
        end
        return false
    end
    return containsChip(Player:FindFirstChild("Backpack")) or containsChip(Player.Character)
end

local function findRaidStartDetector()
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("ClickDetector") then
            local fullName = string.lower(item:GetFullName())
            if string.find(fullName, "raidsummon", 1, true) then
                return item
            end
        end
    end
    return nil
end

local function purchaseRaidChip()
    if hasRaidChip() then return true end
    local ok = runFeature("Mua chip raid", function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Check")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.RaidChip)
    end)
    if ok then task.wait(1) end
    return hasRaidChip()
end

local function startSelectedRaid()
    local now = os.clock()
    if isInRaid() then return false end
    local level = getPlayerLevel()
    if WorldSea == 1 or level < 1100 then
        if now - lastRaidCapabilityWarning >= 15 then
            lastRaidCapabilityWarning = now
            notify("Đột kích chưa mở khóa", "Cần đạt cấp 1100 và ở Biển 2 hoặc Biển 3 để tự mua chip.", 6)
        end
        return false
    end
    if now - lastRaidStartAttempt < 8 then return false end
    lastRaidStartAttempt = now

    if not purchaseRaidChip() then return false end
    local detector = findRaidStartDetector()
    if detector and type(fireclickdetector) == "function" then
        local ok = runFeature("Bắt đầu raid", function()
            fireclickdetector(detector)
        end)
        if ok then task.wait(2) end
        return ok
    end

    if now - lastRaidCapabilityWarning >= 15 then
        lastRaidCapabilityWarning = now
        notify("Đột kích cần thao tác", "Đã mua chip nhưng trình thực thi không bấm được nút; hãy đứng tại phòng đột kích và bấm nút một lần.", 6)
    end
    return false
end

------------------------------------------------------------
