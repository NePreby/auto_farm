-- ==================== TAB 1: MAIN ====================
-- Tên tab ngắn, đồng nhất và ưu tiên tiếng Việt để dễ quét nhanh.
local createdTabCount = 0
local function addTabSafe(name, title)
    -- Không dùng icon mạng ở đây: một icon tải lỗi không được phép chặn các tab sau.
    local ok, tabOrError = pcall(function()
        return Window:AddTab({Title = title})
    end)
    if ok and tabOrError then
        createdTabCount = createdTabCount + 1
        return tabOrError
    end

    featureErrors["Tab " .. name] = tostring(tabOrError)
    return nil
end

-- Tạo tuần tự toàn bộ tab trước khi thêm điều khiển.
local UITabs = {}
UITabs.Main = addTabSafe("Tổng quan", "Tổng quan")
UITabs.Farm = addTabSafe("Luyện cấp", "Tự động luyện cấp")
UITabs.Raid = addTabSafe("Đột kích", "Đột kích")
UITabs.Fruit = addTabSafe("Trái ác quỷ", "Trái ác quỷ")
UITabs.ESP = addTabSafe("Đánh dấu", "Đánh dấu đối tượng")
UITabs.Teleport = addTabSafe("Di chuyển", "Di chuyển")
UITabs.Combat = addTabSafe("Chiến đấu", "Chiến đấu")
UITabs.Misc = addTabSafe("Tiện ích", "Tiện ích")
UITabs.Settings = addTabSafe("Cài đặt", "Cài đặt")
RuntimeEnv.HAOTOOL_TAB_COUNT = createdTabCount
local currentBossNames = {}
local bossStatusLabels = {}
local bossStatusLabelToName = {}
local bossNameToStatusLabel = {}
local bossStatusSummary = ""
local bossStatusSignature = ""
local bossStatusParagraph = nil
local refreshBossInterface = nil
local islandNames

local weaponLabels = {"Cận chiến", "Kiếm", "Súng", "Trái ác quỷ"}
local weaponLabelToValue = {
    ["Cận chiến"] = "Melee",
    ["Kiếm"] = "Sword",
    ["Súng"] = "Gun",
    ["Trái ác quỷ"] = "Blox Fruit",
}
local weaponValueToLabel = {
    ["Melee"] = "Cận chiến",
    ["Sword"] = "Kiếm",
    ["Gun"] = "Súng",
    ["Blox Fruit"] = "Trái ác quỷ",
}
local farmMethodLabels = {"Nhiệm vụ", "Quái gần nhất", "Quái đã chọn"}
local farmMethodLabelToValue = {
    ["Nhiệm vụ"] = "Quest",
    ["Quái gần nhất"] = "Nearest",
    ["Quái đã chọn"] = "Selected Mob",
}
local farmMethodValueToLabel = {
    ["Quest"] = "Nhiệm vụ",
    ["Nearest"] = "Quái gần nhất",
    ["Selected Mob"] = "Quái đã chọn",
}
local statLabels = {"Cận chiến", "Phòng thủ", "Kiếm", "Súng", "Trái ác quỷ"}
local statLabelToValue = {
    ["Cận chiến"] = "Melee",
    ["Phòng thủ"] = "Defense",
    ["Kiếm"] = "Sword",
    ["Súng"] = "Gun",
    ["Trái ác quỷ"] = "Blox Fruit",
}
local statValueToLabel = {
    ["Melee"] = "Cận chiến",
    ["Defense"] = "Phòng thủ",
    ["Sword"] = "Kiếm",
    ["Gun"] = "Súng",
    ["Blox Fruit"] = "Trái ác quỷ",
}
local teamLabels = {"Hải Tặc", "Hải Quân"}
local teamLabelToValue = {
    ["Hải Tặc"] = "Pirates",
    ["Hải Quân"] = "Marines",
}
local teamValueToLabel = {
    ["Pirates"] = "Hải Tặc",
    ["Marines"] = "Hải Quân",
}

local function refreshBossCache()
    currentBossNames = getBossList()
    bossStatusLabels, bossStatusLabelToName, bossNameToStatusLabel,
        bossStatusSummary, bossStatusSignature = getBossStatusList(currentBossNames)
end
refreshBossCache()

local MainTab = UITabs.Main
runFeature("Giao diện Tổng quan", function()

local tabStatus = "Đã tạo " .. createdTabCount .. "/9 tab"
if createdTabCount < 9 then
    for featureName, message in pairs(featureErrors) do
        if string.sub(featureName, 1, 4) == "Tab " then
            tabStatus = tabStatus .. "\n" .. featureName .. ": " .. string.sub(tostring(message), 1, 220)
            break
        end
    end
end
MainTab:AddParagraph({
    Title = "Trạng thái giao diện • V" .. RequestedScriptVersion,
    Content = tabStatus,
})
MainTab:AddParagraph({
    Title = "⚡  Xin chào, " .. Player.DisplayName,
    Content = "BIỂN  " .. WorldSea
        .. "    •    CẤP  " .. tostring(getPlayerLevel())
        .. "    •    TIỀN  " .. tostring(getPlayerBeli())
        .. "\nMáy chủ  " .. game.JobId:sub(1, 8) .. "..."
        .. "\n\nRightControl hoặc nút H  •  Ẩn / hiện bảng điều khiển"
})

local ServerSection = MainTab:AddSection("Kết nối máy chủ")

ServerSection:AddParagraph({
    Title = "Máy chủ hiện tại",
    Content = tostring(#Players:GetPlayers()) .. " người đang chơi",
})

ServerSection:AddParagraph({
    Title = "Trạng thái tự chọn phe",
    Content = tostring(RuntimeEnv.HAOTOOL_STARTUP_TEAM_STATUS or "Chưa chạy"),
})

ServerSection:AddSlider("LowServerMaxPlayersSlider", {
    Title = "Số người tối đa mong muốn",
    Description = "Hệ thống ưu tiên máy chủ có số người bằng hoặc thấp hơn mức này.",
    Min = 1,
    Max = 12,
    Default = _G.LowServerMaxPlayers,
    Rounding = 0,
    Callback = function(v) _G.LowServerMaxPlayers = v end,
})

ServerSection:AddToggle("AutoChooseTeamToggle", {
    Title = "Tự chọn phe khi vào game",
    Description = "Tự chọn lại phe sau khi vào game hoặc đổi máy chủ.",
    Default = _G.AutoChooseTeam,
    Callback = function(v)
        _G.AutoChooseTeam = v
        if v and not teamIsSelected() then
            task.spawn(function() choosePreferredTeam(true) end)
        end
    end,
})

ServerSection:AddDropdown("PreferredTeamDrop", {
    Title = "Phe ưu tiên",
    Description = "Phe sẽ tự chọn ở màn hình bắt đầu.",
    Values = teamLabels,
    Default = teamValueToLabel[_G.PreferredTeam] or teamLabels[1],
    Callback = function(v)
        _G.PreferredTeam = teamLabelToValue[v] or _G.PreferredTeam
    end,
})

ServerSection:AddButton({
    Title = "Chọn phe ngay",
    Description = "Gửi lại yêu cầu nếu đang dừng ở màn hình chọn phe.",
    Callback = function()
        task.spawn(function()
            local ok, message = choosePreferredTeam(true)
            local label = teamValueToLabel[normalizedPreferredTeam()] or normalizedPreferredTeam()
            notify(ok and "Đã chọn phe" or "Chưa chọn được phe", ok and label or tostring(message), 4)
        end)
    end,
})

ServerSection:AddButton({
    Title = "Chuyển sang máy chủ ít người",
    Description = "Quét tối đa 300 máy chủ và chọn máy có ít người nhất.",
    Callback = function()
        notify("Đổi máy chủ", "Đang tìm máy chủ ít người...", 3)
        local ok, message = serverHop(true, _G.LowServerMaxPlayers)
        if not ok then notify("Không thể đổi máy chủ", tostring(message), 5) end
    end,
})

ServerSection:AddButton({
    Title = "Vào lại máy chủ",
    Description = "Kết nối lại đúng máy chủ hiện tại.",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
        end)
    end
})

ServerSection:AddButton({
    Title = "Chuyển máy chủ ngẫu nhiên",
    Description = "Chuyển sang một máy chủ công khai khác.",
    Callback = function()
        notify("Đổi máy chủ", "Đang tìm máy chủ...", 3)
        serverHop()
    end
})
ServerSection:AddButton({
    Title = "Buộc dựng lại toàn bộ menu",
    Description = "Xóa cửa sổ hiện tại và nạp lại đủ 9 tab từ bản đã lưu.",
    Callback = function()
        RuntimeEnv.HAOTOOL_UI_READY = false
        rebuildMainInterface()
    end
})

end)

