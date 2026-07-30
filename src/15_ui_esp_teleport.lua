-- ==================== TAB 5: ESP ====================
local ESPTab = UITabs.ESP
runFeature("Giao diện ESP", function()

local ESPTargetSection = ESPTab:AddSection("Đối tượng hiển thị")

ESPTargetSection:AddToggle("ESPPlayerToggle", {
    Title = "Đánh dấu người chơi",
    Description = "Hiển thị người chơi khác và có thể bỏ qua đồng đội",
    Default = _G.ESPPlayer,
    Callback = function(v) _G.ESPPlayer = v; if not v then clearESPKind("player") end end,
})

ESPTargetSection:AddToggle("ESPTeamCheckToggle", {
    Title = "Bỏ qua đồng đội",
    Description = "Bỏ qua đồng đội",
    Default = _G.ESPTeamCheck,
    Callback = function(v) _G.ESPTeamCheck = v end,
})

ESPTargetSection:AddToggle("ESPMobToggle", {
    Title = "Đánh dấu quái",
    Description = "Hiển thị quái thường",
    Default = _G.ESPMob,
    Callback = function(v) _G.ESPMob = v; if not v then clearESPKind("mob") end end,
})

ESPTargetSection:AddToggle("ESPBossToggle", {
    Title = "Đánh dấu Trùm",
    Description = "Hiển thị các Trùm thường, Trùm đột kích và Trùm trong dữ liệu",
    Default = _G.ESPBoss,
    Callback = function(v) _G.ESPBoss = v; if not v then clearESPKind("boss") end end,
})

ESPTargetSection:AddToggle("ESPChestToggle", {
    Title = "Đánh dấu Rương",
    Description = "Hiển thị rương",
    Default = _G.ESPChest,
    Callback = function(v) _G.ESPChest = v; if not v then clearESPKind("chest") end end,
})

ESPTargetSection:AddToggle("ESPFlowerToggle", {
    Title = "Đánh dấu Hoa",
    Description = "Hiển thị hoa",
    Default = _G.ESPFlower,
    Callback = function(v) _G.ESPFlower = v; if not v then clearESPKind("flower") end end,
})

ESPTargetSection:AddToggle("ESPIslandToggle", {
    Title = "Đánh dấu Đảo",
    Description = "Hiển thị tên đảo",
    Default = _G.ESPIsland,
    Callback = function(v)
        _G.ESPIsland = v
        setIslandESP(v)
    end,
})

local ESPStyleSection = ESPTab:AddSection("Khoảng cách & màu sắc")

ESPStyleSection:AddSlider("ESPDistSlider", {
    Title = "Khoảng cách hiển thị",
    Min = 100,
    Max = 10000,
    Default = _G.ESPDistance,
    Rounding = 0,
    Callback = function(v) _G.ESPDistance = v end,
})

ESPStyleSection:AddColorpicker("ESPPlayerColor", {
    Title = "Màu người chơi",
    Default = _G.ESPPlayerColor,
    Callback = function(v) _G.ESPPlayerColor = v end,
})

ESPStyleSection:AddColorpicker("ESPMobColorPick", {
    Title = "Màu quái",
    Default = _G.ESPMobColor,
    Callback = function(v) _G.ESPMobColor = v end,
})

ESPStyleSection:AddColorpicker("ESPBossColorPick", {
    Title = "Màu Trùm",
    Default = _G.ESPBossColor,
    Callback = function(v) _G.ESPBossColor = v end,
})

ESPStyleSection:AddColorpicker("ESPFruitColorPick", {
    Title = "Màu Trái",
    Default = _G.ESPFruitColor,
    Callback = function(v) _G.ESPFruitColor = v end,
})

ESPStyleSection:AddButton({
    Title = "Tắt và xóa toàn bộ đánh dấu",
    Callback = function()
        _G.ESPPlayer = false
        _G.ESPMob = false
        _G.ESPBoss = false
        _G.ESPChest = false
        _G.ESPFlower = false
        _G.ESPIsland = false
        _G.FruitESP = false
        for _, optionId in ipairs({
            "ESPPlayerToggle", "ESPMobToggle", "ESPBossToggle",
            "ESPChestToggle", "ESPFlowerToggle", "ESPIslandToggle", "FruitESPToggle",
        }) do
            local option = Fluent.Options and Fluent.Options[optionId]
            if option and option.SetValue then pcall(function() option:SetValue(false) end) end
        end
        clearAllESP()
        notify("ESP", "Đã tắt và xóa tất cả ESP", 2)
    end
})

end)

-- ==================== TAB 6: TELEPORT ====================
local TeleportTab = UITabs.Teleport
runFeature("Giao diện Di chuyển", function()

local IslandSection = TeleportTab:AddSection("Đảo tại Biển " .. WorldSea)

-- Lấy danh sách đảo theo Sea hiện tại
local currentIslands = getSeaIslands()
islandNames = {}
for name, _ in pairs(currentIslands) do
    table.insert(islandNames, name)
end
table.sort(islandNames)
if #islandNames > 0 and (_G.SelectedIsland == "" or not currentIslands[_G.SelectedIsland]) then
    _G.SelectedIsland = islandNames[1]
end

IslandSection:AddDropdown("IslandDrop", {
    Title = "Chọn Đảo (Biển " .. WorldSea .. ")",
    Values = islandNames,
    Default = (_G.SelectedIsland ~= "" and _G.SelectedIsland or 1),
    Callback = function(v) _G.SelectedIsland = v end,
})

IslandSection:AddButton({
    Title = "✈️ Bay Tới Đảo",
    Description = "Bay tới đảo đã chọn",
    Callback = function()
        local targetPos = currentIslands[_G.SelectedIsland]
        if targetPos then
            notify("✈️ Teleport", "Đang bay tới " .. _G.SelectedIsland .. "...", 3)
            local arrived = manualTeleportTo(CFrame.new(targetPos))
            notify(arrived and "✅ Đã Đến" or "⚠️ Di chuyển bị gián đoạn", _G.SelectedIsland, 2)
        else
            notify("❌ Lỗi", "Không tìm thấy đảo", 2)
        end
    end
})

-- Teleport NPC quan trọng
if #ImportantNPCs > 0 then
    local NPCSection = TeleportTab:AddSection("NPC quan trọng")

    local npcNames = {}
    for _, npc in ipairs(ImportantNPCs) do
        table.insert(npcNames, npc.Name)
    end
    if _G.SelectedNPC == "" or not table.find(npcNames, _G.SelectedNPC) then
        _G.SelectedNPC = npcNames[1]
    end

    NPCSection:AddDropdown("NPCDrop", {
        Title = "Chọn NPC",
        Values = npcNames,
        Default = (_G.SelectedNPC ~= "" and _G.SelectedNPC or 1),
        Callback = function(v) _G.SelectedNPC = v end,
    })

    NPCSection:AddButton({
        Title = "👤 Bay Tới NPC",
        Callback = function()
            for _, npc in ipairs(ImportantNPCs) do
                if npc.Name == _G.SelectedNPC then
                    notify("✈️ Teleport", "Đang bay tới " .. npc.Name, 3)
                    local arrived = manualTeleportTo(CFrame.new(npc.Position))
                    notify(arrived and "✅ Đã đến NPC" or "⚠️ Di chuyển bị gián đoạn", npc.Name, 2)
                    break
                end
            end
        end
    })
end

-- Teleport Boss
local BossTeleportSection = TeleportTab:AddSection("Trùm")

if _G.SelectedBossTP == "" or not table.find(currentBossNames, _G.SelectedBossTP) then
    _G.SelectedBossTP = currentBossNames[1] or ""
end

BossTeleportSection:AddDropdown("BossTPDrop", {
    Title = "Chọn Trùm",
    Values = bossStatusLabels,
    Default = bossNameToStatusLabel[_G.SelectedBossTP] or bossStatusLabels[1],
    Callback = function(v)
        _G.SelectedBossTP = bossStatusLabelToName[v] or _G.SelectedBossTP
    end,
})

BossTeleportSection:AddButton({
    Title = "💀 Bay tới Trùm",
    Callback = function()
        local bossData = getBossData(_G.SelectedBossTP)
        if bossData then
            notify("✈️ Teleport", "Đang bay tới " .. bossData.Name, 3)
            local arrived = manualTeleportTo(CFrame.new(bossData.Position))
            notify(arrived and "✅ Đã đến Trùm" or "⚠️ Di chuyển bị gián đoạn", bossData.Name, 2)
        end
    end
})

-- Teleport tới Fruit
local FruitTeleportSection = TeleportTab:AddSection("Trái ác quỷ")

FruitTeleportSection:AddButton({
    Title = "🍎 Bay Tới Trái Gần Nhất",
    Description = "Tìm và bay tới trái ác quỷ gần nhất",
    Callback = function()
        local closestFruit = findNearestFruit()
        local handle = getFruitHandle(closestFruit)
        if closestFruit and handle then
            notify("Dịch chuyển Trái", "Đang bay tới " .. closestFruit.Name, 3)
            local arrived = manualTeleportTo(handle.CFrame * CFrame.new(0, 2, 0))
            notify(arrived and "✅ Đã đến trái" or "⚠️ Di chuyển bị gián đoạn", closestFruit.Name, 2)
        else
            notify("❌", "Không tìm thấy trái trên map", 2)
        end
    end
})


-- Quick Teleport đến các Sea khác
local SeaSection = TeleportTab:AddSection("Chuyển vùng biển")

SeaSection:AddButton({
    Title = "🌊 Đi Biển 1",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(2753915549, Player)
        end)
    end
})

SeaSection:AddButton({
    Title = "🌊 Đi Biển 2",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(4442272183, Player)
        end)
    end
})

SeaSection:AddButton({
    Title = "🌊 Đi Biển 3",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(7449423635, Player)
        end)
    end
})

end)

