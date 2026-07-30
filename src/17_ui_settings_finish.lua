-- ==================== TAB 9: SETTINGS ====================
local SettingsTab = UITabs.Settings
runFeature("Giao diện Cài đặt", function()

SettingsTab:AddParagraph({
    Title = "Cá nhân hóa HAOTOOL",
    Content = "Đổi giao diện, phím tắt và lưu cấu hình của bạn."
})

local UtilitySection = SettingsTab:AddSection("Thông tin & dữ liệu")

UtilitySection:AddButton({
    Title = "Xem thông tin nhân vật",
    Description = "Xem thông tin nhân vật hiện tại",
    Callback = function()
        pcall(function()
            local lvl = getPlayerLevel()
            local beli = getPlayerBeli()
            local frag = "?"
            pcall(function() frag = Player.Data.Fragments.Value end)

            notify("📋 Thông Tin", string.format(
                "Cấp: %s\nTiền: %s\nMảnh: %s\nBiển: %d\nMáy chủ: %s",
                tostring(lvl), tostring(beli), tostring(frag), WorldSea, game.JobId:sub(1,12)
            ), 6)
        end)
    end
})

UtilitySection:AddButton({
    Title = "Kiểm tra hệ thống",
    Description = "Kiểm tra dịch vụ lõi, khả năng executor và lỗi gần nhất của từng vòng chạy.",
    Callback = function()
        local report = buildSystemDiagnostic()
        print("[HAOTOOL DIAGNOSTIC]\n" .. report)
        notify("🩺 Kiểm tra hệ thống", report, 10)
    end
})
UtilitySection:AddButton({
    Title = "Làm mới danh sách quái",
    Description = "Cập nhật danh sách quái hiện có",
    Callback = function()
        local enemies = getEnemyList()
        pcall(function()
            local option = Fluent.Options and Fluent.Options.SelectedMobDrop
            if option then
                option:SetValues(enemies)
                if not table.find(enemies, _G.SelectedMob) and enemies[1] ~= "(Không có quái)" then
                    _G.SelectedMob = enemies[1]
                    if option.SetValue then option:SetValue(enemies[1]) end
                end
            end
        end)
        notify("🔄", "Đã cập nhật danh sách quái: " .. #enemies .. " loại", 2)
    end
})

-- Lưu/Tải cấu hình (nếu SaveManager tồn tại)
if SaveManager and InterfaceManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)

        -- Đồng bộ mặc định của trình quản lý với giao diện mới.
        -- Cấu hình người dùng đã lưu (nếu có) vẫn được ưu tiên khi tải.
        if InterfaceManager.Settings then
            InterfaceManager.Settings.Theme = "Amethyst"
            InterfaceManager.Settings.MenuKeybind = "RightControl"
        end

        SaveManager:IgnoreThemeSettings()
        InterfaceManager:SetFolder("HaoToolHub")
        SaveManager:SetFolder("HaoToolHub/BloxFruits")
        InterfaceManager:BuildInterfaceSection(SettingsTab)
        -- InterfaceManager cung cấp sẵn chọn theme, acrylic, độ trong suốt
        -- và phím ẩn/hiện; không cần tạo thêm điều khiển trùng lặp.
        SaveManager:BuildConfigSection(SettingsTab)
    end)
end

end)

------------------------------------------------------------
-- PHẦN 8: HOÀN TẤT
------------------------------------------------------------

-- Chọn tab đầu tiên
pcall(function() Window:SelectTab(1) end)

-- Tải config tự động (nếu có)
pcall(function()
    if SaveManager then
        SaveManager:LoadAutoloadConfig()
    end
end)

-- Tự cập nhật trạng thái Trùm khi Trùm xuất hiện hoặc bị hạ.
task.spawn(function()
    while RuntimeEnv.HAOTOOL_RUN_TOKEN == CurrentRunToken do
        task.wait(2)
        if refreshBossInterface then pcall(refreshBossInterface, false) end
    end
end)

-- Đồng bộ lại giao diện theo đúng trạng thái trước khi chuyển server.
if type(teleportState) == "table" and Fluent and Fluent.Options then
    local teleportOptionMap = {
        AutoFarmLevel = "AutoFarmLevel",
        AutoFarmMastery = "AutoFarmMastery",
        MasteryWeaponDrop = "MasteryWeapon",
        SelectWeaponDrop = "SelectWeapon",
        FarmMethodDrop = "FarmMethod",
        SelectedMobDrop = "SelectedMob",
        FarmHeightSlider = "FarmHeight",
        FarmDistanceSlider = "FarmDistance",
        HoldFarmPositionToggle = "HoldFarmPosition",
        FreezeTargetToggle = "FreezeTarget",
        SafetyModeToggle = "SafetyMode",
        BackgroundAttackToggle = "BackgroundAttack",
        NoAttackAnimationToggle = "NoAttackAnimation",
        AttackDelaySlider = "AttackDelay",
        HitboxSizeSlider = "HitboxSize",
        BringMobToggle = "BringMob",
        BringRadiusSlider = "BringRadius",
        AutoSkillToggle = "AutoSkill",
        SkillCDSlider = "SkillCooldown",
        AutoFarmBoss = "AutoFarmBoss",
        SelectedBossDrop = "SelectedBoss",
        AutoFarmSeaBeast = "AutoFarmSeaBeast",
        AutoFarmObs = "AutoFarmObs",
        AutoFarmBone = "AutoFarmBone",
        AutoFarmFragment = "AutoFarmFragment",
        AutoFarmChest = "AutoFarmChest",
        AutoRaidToggle = "AutoRaid",
        AutoRaidFarmToggle = "AutoRaidFarm",
        RaidChipDrop = "RaidChip",
        AutoAwakeningToggle = "AutoAwakening",
        AutoFindFruitToggle = "AutoFruitFinder",
        AutoCollectFruitToggle = "AutoCollectFruit",
        AutoStoreFruitToggle = "AutoStoreFruit",
        FruitESPToggle = "FruitESP",
        AutoGachaToggle = "AutoGachaFruit",
        ESPPlayerToggle = "ESPPlayer",
        ESPTeamCheckToggle = "ESPTeamCheck",
        ESPMobToggle = "ESPMob",
        ESPBossToggle = "ESPBoss",
        ESPChestToggle = "ESPChest",
        ESPFlowerToggle = "ESPFlower",
        ESPIslandToggle = "ESPIsland",
        ESPDistSlider = "ESPDistance",
        IslandDrop = "SelectedIsland",
        NPCDrop = "SelectedNPC",
        BossTPDrop = "SelectedBossTP",
        AutoBusoToggle = "AutoHaki",
        AutoKenToggle = "AutoKen",
        AutoObsV2Toggle = "AutoObsV2",
        AutoDodgeToggle = "AutoDodge",
        FightingStyleShopDrop = "SelectedFightingStyleShop",
        WalkSpeedToggle = "WalkSpeedHack",
        WalkSpeedSlider = "WalkSpeedVal",
        JumpPowerToggle = "JumpPowerHack",
        JumpPowerSlider = "JumpPowerVal",
        InfiniteJumpToggle = "InfiniteJump",
        InfiniteEnergyToggle = "InfiniteEnergy",
        AutoStatsToggle = "AutoStats",
        StatDropdown = "StatToUpgrade",
        AntiAFKToggle = "AntiAFK",
        ServerHopNoFruitToggle = "ServerHopNoFruit",
        LowServerMaxPlayersSlider = "LowServerMaxPlayers",
        AutoRedeemExpCodesToggle = "AutoRedeemExpCodes",
        AutoRedeemResetCodesToggle = "AutoRedeemResetCodes",
        AutoChooseTeamToggle = "AutoChooseTeam",
        PreferredTeamDrop = "PreferredTeam",
        ESPPlayerColor = "ESPPlayerColor",
        ESPMobColorPick = "ESPMobColor",
        ESPBossColorPick = "ESPBossColor",
        ESPFruitColorPick = "ESPFruitColor",
    }

    for optionId, stateKey in pairs(teleportOptionMap) do
        local option = Fluent.Options[optionId]
        local value = teleportState[stateKey]
        if option and value ~= nil and option.SetValue then
            local displayValue = value
            if optionId == "MasteryWeaponDrop" or optionId == "SelectWeaponDrop" then
                displayValue = weaponValueToLabel[value] or value
            elseif optionId == "FarmMethodDrop" then
                displayValue = farmMethodValueToLabel[value] or value
            elseif optionId == "StatDropdown" then
                displayValue = statValueToLabel[value] or value
            elseif optionId == "PreferredTeamDrop" then
                displayValue = teamValueToLabel[value] or value
            elseif optionId == "FightingStyleShopDrop" then
                displayValue = CombatShop.GetStyleLabel(value)
            elseif optionId == "SelectedBossDrop" or optionId == "BossTPDrop" then
                displayValue = bossNameToStatusLabel[value] or value
            end
            pcall(function() option:SetValue(displayValue) end)
        end
    end
end


if Window and Window.SelectTab then
    pcall(function() Window:SelectTab(1) end)
end

RuntimeEnv.HAOTOOL_UI_READY = createdTabCount == 9
RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = nil

-- Thông báo load thành công
notify(
    "HAOTOOL • Sẵn sàng",
    "Biển " .. WorldSea
        .. "  •  " .. #(WorldSea == 1 and QuestsSea1 or WorldSea == 2 and QuestsSea2 or QuestsSea3) .. " nhiệm vụ"
        .. "  •  " .. #islandNames .. " đảo"
        .. "\nGiao diện: " .. createdTabCount .. "/9 tab"
        .. "\nRightControl hoặc nút H để ẩn / hiện giao diện"
        .. (teleportReloadReady and "  •  Tự nạp khi đổi máy chủ: BẬT" or "  •  Trình thực thi không hỗ trợ tự nạp"),
    6
)

print("=====================================")
print("⚡ HAOTOOL v2.3.4 — ĐÃ KHỞI ĐỘNG THÀNH CÔNG")
print("🌊 Biển: " .. WorldSea)
print("📌 RightControl để ẩn hoặc hiện giao diện")
print("=====================================")

end

buildMainInterface()