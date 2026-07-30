-- ==================== TAB 2: FARM ====================
local FarmTab = UITabs.Farm
runFeature("Giao diện Farm", function()

local FarmCoreSection = FarmTab:AddSection("Luyện cấp và thông thạo")
local changingCoreFarmMode = false

local function disableOtherCoreFarm(optionId, globalKey)
    _G[globalKey] = false
    local option = Fluent.Options and Fluent.Options[optionId]
    if option and option.SetValue then
        pcall(function() option:SetValue(false) end)
    end
end

FarmCoreSection:AddToggle("AutoFarmLevel", {
    Title = "Tự động luyện cấp",
    Description = "Tự động nhận nhiệm vụ → đánh quái → lên cấp",
    Default = _G.AutoFarmLevel,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if v and not changingCoreFarmMode then
            changingCoreFarmMode = true
            disableOtherCoreFarm("AutoFarmMastery", "AutoFarmMastery")
            changingCoreFarmMode = false
        end
        if v and hasActiveQuest() then
            abandonQuest()
            acceptedQuestSignature = nil
        end
        if not v and not _G.AutoFarmMastery and not _G.AutoFarmBoss
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmCoreSection:AddToggle("AutoFarmMastery", {
    Title = "Tự động luyện thông thạo",
    Description = "Tự động tăng thông thạo cho vũ khí được chọn",
    Default = _G.AutoFarmMastery,
    Callback = function(v)
        _G.AutoFarmMastery = v
        if v and not changingCoreFarmMode then
            changingCoreFarmMode = true
            disableOtherCoreFarm("AutoFarmLevel", "AutoFarmLevel")
            changingCoreFarmMode = false
        end
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmBoss
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmCoreSection:AddDropdown("MasteryWeaponDrop", {
    Title = "Vũ khí luyện thông thạo",
    Values = weaponLabels,
    Default = weaponValueToLabel[_G.MasteryWeapon] or weaponLabels[1],
    Callback = function(v) _G.MasteryWeapon = weaponLabelToValue[v] or _G.MasteryWeapon end,
})

FarmCoreSection:AddDropdown("SelectWeaponDrop", {
    Title = "Chọn vũ khí để đánh",
    Values = weaponLabels,
    Default = weaponValueToLabel[_G.SelectWeapon] or weaponLabels[1],
    Callback = function(v) _G.SelectWeapon = weaponLabelToValue[v] or _G.SelectWeapon end,
})

FarmCoreSection:AddDropdown("FarmMethodDrop", {
    Title = "Phương thức luyện cấp",
    Values = farmMethodLabels,
    Default = farmMethodValueToLabel[_G.FarmMethod] or farmMethodLabels[1],
    Callback = function(v) _G.FarmMethod = farmMethodLabelToValue[v] or _G.FarmMethod end,
})

local currentEnemyNames = getEnemyList()
if _G.SelectedMob == "" and currentEnemyNames[1] ~= "(Không có quái)" then
    _G.SelectedMob = currentEnemyNames[1]
end
FarmCoreSection:AddDropdown("SelectedMobDrop", {
    Title = "Chọn quái (khi dùng Quái đã chọn)",
    Values = currentEnemyNames,
    Default = (_G.SelectedMob ~= "" and _G.SelectedMob or 1),
    Callback = function(v) _G.SelectedMob = v end,
})

local FarmPositionSection = FarmTab:AddSection("Vị trí & chiến đấu")

FarmPositionSection:AddSlider("FarmHeightSlider", {
    Title = "Độ cao so với quái",
    Description = "Số âm đứng thấp hơn, số dương đứng cao hơn.",
    Min = -20,
    Max = 30,
    Default = _G.FarmHeight,
    Rounding = 0,
    Callback = function(v) _G.FarmHeight = v end,
})

FarmPositionSection:AddSlider("FarmDistanceSlider", {
    Title = "Khoảng cách trước / sau",
    Description = "0 là ngay trên quái; tăng để lùi ra sau.",
    Min = 0,
    Max = 25,
    Default = _G.FarmDistance,
    Rounding = 0,
    Callback = function(v) _G.FarmDistance = v end,
})

FarmPositionSection:AddToggle("HoldFarmPositionToggle", {
    Title = "Giữ vị trí khi đánh",
    Description = "Ngăn nhân vật vừa đánh vừa chạy hoặc giật quanh quái.",
    Default = _G.HoldFarmPosition,
    Callback = function(v) _G.HoldFarmPosition = v end,
})

FarmPositionSection:AddToggle("FreezeTargetToggle", {
    Title = "Khóa di chuyển của quái",
    Description = "Giữ mục tiêu đứng yên trong lúc đánh.",
    Default = _G.FreezeTarget,
    Callback = function(v)
        _G.FreezeTarget = v
        if not v then restoreFrozenMobs() end
    end,
})

FarmPositionSection:AddToggle("SafetyModeToggle", {
    Title = "Giới hạn hoạt động",
    Description = "Giới hạn tốc độ, vùng đánh và phạm vi gom quái để giảm thao tác quá nhanh.",
    Default = _G.SafetyMode,
    Callback = function(v)
        _G.SafetyMode = v
        notify(
            v and "Đã bật giới hạn an toàn" or "Đã tắt giới hạn an toàn",
            v and "Tốc độ tối thiểu 0.05, hitbox tối đa 18, gom quái tối đa 350."
                or "Tốc độ và phạm vi cao hơn có thể làm tăng rủi ro.",
            5
        )
    end,
})

FarmPositionSection:AddToggle("BackgroundAttackToggle", {
    Title = "Đánh nền, không chiếm chuột",
    Description = "Ưu tiên bộ điều khiển chiến đấu của game và tự dùng phương án dự phòng khi cần.",
    Default = _G.BackgroundAttack,
    Callback = function(v) _G.BackgroundAttack = v end,
})

FarmPositionSection:AddToggle("NoAttackAnimationToggle", {
    Title = "Ẩn hoạt ảnh đánh thường",
    Description = "Ẩn chuyển động đấm/chém nhưng không dừng mốc sát thương; tạm nhường khi dùng kỹ năng.",
    Default = _G.NoAttackAnimation,
    Callback = function(v)
        _G.NoAttackAnimation = v
        if not v then restoreAttackAnimationWeights() end
    end,
})

FarmPositionSection:AddSlider("AttackDelaySlider", {
    Title = "Độ trễ đánh thường",
    Description = "Thấp hơn sẽ nhanh hơn; khi giới hạn an toàn bật, mức thực tế không thấp hơn 0.05.",
    Min = 0.01,
    Max = 0.50,
    Default = _G.AttackDelay,
    Rounding = 2,
    Callback = function(v) _G.AttackDelay = v end,
})

FarmPositionSection:AddSlider("HitboxSizeSlider", {
    Title = "Kích thước vùng tiếp xúc",
    Min = 2,
    Max = 30,
    Default = _G.HitboxSize,
    Rounding = 0,
    Callback = function(v) _G.HitboxSize = v end,
})

FarmPositionSection:AddToggle("BringMobToggle", {
    Title = "Gom quái cùng loại",
    Description = "Kéo các quái cùng tên về mục tiêu đang đánh.",
    Default = _G.BringMob,
    Callback = function(v)
        _G.BringMob = v
        if not v then restoreFrozenMobs() end
    end,
})

FarmPositionSection:AddSlider("BringRadiusSlider", {
    Title = "Bán kính gom quái",
    Min = 50,
    Max = 1000,
    Default = _G.BringRadius,
    Rounding = 0,
    Callback = function(v) _G.BringRadius = v end,
})

FarmPositionSection:AddToggle("AutoSkillToggle", {
    Title = "Tự dùng kỹ năng Z, X, C, V",
    Description = "Dùng lần lượt các kỹ năng khi đang giữ vị trí.",
    Default = _G.AutoSkill,
    Callback = function(v) _G.AutoSkill = v end,
})

FarmPositionSection:AddSlider("SkillCDSlider", {
    Title = "Hồi chiêu kỹ năng",
    Min = 0.5,
    Max = 5,
    Default = _G.SkillCooldown,
    Rounding = 1,
    Callback = function(v) _G.SkillCooldown = v end,
})

local FarmBossSection = FarmTab:AddSection("Trùm và tài nguyên")

refreshBossCache()
if #currentBossNames > 0 and (_G.SelectedBoss == "" or not table.find(currentBossNames, _G.SelectedBoss)) then
    _G.SelectedBoss = currentBossNames[1]
end

bossStatusParagraph = FarmBossSection:AddParagraph({
    Title = "Trạng thái Trùm trong máy chủ",
    Content = bossStatusSummary,
})

FarmBossSection:AddToggle("AutoFarmBoss", {
    Title = "Tự động đánh Trùm",
    Description = "Tự động tìm và đánh Trùm được chọn",
    Default = _G.AutoFarmBoss,
    Callback = function(v)
        _G.AutoFarmBoss = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

FarmBossSection:AddDropdown("SelectedBossDrop", {
    Title = "Chọn Trùm",
    Values = bossStatusLabels,
    Default = bossNameToStatusLabel[_G.SelectedBoss] or bossStatusLabels[1],
    Callback = function(v)
        _G.SelectedBoss = bossStatusLabelToName[v] or _G.SelectedBoss
    end,
})

refreshBossInterface = function(showNotice)
    local previousSignature = bossStatusSignature
    refreshBossCache()
    if not showNotice and previousSignature == bossStatusSignature then return end

    if #currentBossNames > 0 and not table.find(currentBossNames, _G.SelectedBoss) then
        _G.SelectedBoss = currentBossNames[1]
    end
    if #currentBossNames > 0 and not table.find(currentBossNames, _G.SelectedBossTP) then
        _G.SelectedBossTP = currentBossNames[1]
    end

    local selectedByOption = {
        SelectedBossDrop = _G.SelectedBoss,
        BossTPDrop = _G.SelectedBossTP,
    }
    for optionId, selectedName in pairs(selectedByOption) do
        local option = Fluent.Options and Fluent.Options[optionId]
        if option then
            pcall(function() option:SetValues(bossStatusLabels) end)
            local selectedLabel = bossNameToStatusLabel[selectedName] or bossStatusLabels[1]
            if selectedLabel and option.SetValue then
                pcall(function() option:SetValue(selectedLabel) end)
            end
        end
    end

    if bossStatusParagraph and bossStatusParagraph.SetDesc then
        pcall(function() bossStatusParagraph:SetDesc(bossStatusSummary) end)
    end
    if showNotice then
        notify("Danh sách Trùm", "Đã cập nhật trạng thái " .. #currentBossNames .. " Trùm.", 3)
    end
end

FarmBossSection:AddButton({
    Title = "Làm mới danh sách Trùm",
    Description = "Cập nhật ngay trạng thái đang xuất hiện hoặc chưa xuất hiện.",
    Callback = function() refreshBossInterface(true) end,
})
FarmBossSection:AddToggle("AutoFarmSeaBeast", {
    Title = "Tự động đánh Quái biển",
    Default = _G.AutoFarmSeaBeast,
    Callback = function(v)
        _G.AutoFarmSeaBeast = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmBoss then
            stopFarmMovement()
        end
    end,
})

FarmBossSection:AddToggle("AutoFarmObs", {
    Title = "Tự động luyện Haki quan sát",
    Description = "Duy trì Haki quan sát; kinh nghiệm chỉ tăng khi né đòn trong game",
    Default = _G.AutoFarmObs,
    Callback = function(v) _G.AutoFarmObs = v end,
})

FarmBossSection:AddToggle("AutoFarmBone", {
    Title = "Tự động kiếm Xương",
    Default = _G.AutoFarmBone,
    Callback = function(v) _G.AutoFarmBone = v end,
})

FarmBossSection:AddToggle("AutoFarmFragment", {
    Title = "Tự động kiếm Mảnh qua đột kích",
    Description = "Mua chip, bắt đầu đột kích và đánh quái để nhận Mảnh.",
    Default = _G.AutoFarmFragment,
    Callback = function(v) _G.AutoFarmFragment = v end,
})

FarmBossSection:AddToggle("AutoFarmChest", {
    Title = "Tự động nhặt Rương",
    Description = "Tự động tìm và mở rương",
    Default = _G.AutoFarmChest,
    Callback = function(v) _G.AutoFarmChest = v end,
})

end)

