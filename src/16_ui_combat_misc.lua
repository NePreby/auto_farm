-- ==================== TAB 7: COMBAT ====================
local CombatTab = UITabs.Combat
runFeature("Giao diện Chiến đấu", function()

local CombatAutoSection = CombatTab:AddSection("Haki & phòng thủ tự động")

CombatAutoSection:AddToggle("AutoBusoToggle", {
    Title = "Tự động bật Haki vũ trang",
    Description = "Tự động bật Buso Haki (Haki Vũ Trang)",
    Default = _G.AutoHaki,
    Callback = function(v) _G.AutoHaki = v end,
})

CombatAutoSection:AddToggle("AutoKenToggle", {
    Title = "Tự động bật Haki quan sát",
    Description = "Tự động bật Ken Haki (Haki Quan Sát)",
    Default = _G.AutoKen,
    Callback = function(v) _G.AutoKen = v; if v then activateObservation(true) end end,
})

CombatAutoSection:AddToggle("AutoObsV2Toggle", {
    Title = "Duy trì Haki quan sát",
    Description = "Duy trì Observation sau khi hồi sinh; không tự mở khóa V2",
    Default = _G.AutoObsV2,
    Callback = function(v) _G.AutoObsV2 = v; if v then activateObservation(true) end end,
})

CombatAutoSection:AddToggle("AutoDodgeToggle", {
    Title = "Tự động né đòn",
    Description = "Tự động né tránh đạn/đòn đánh",
    Default = _G.AutoDodge,
    Callback = function(v) _G.AutoDodge = v end,
})

local CombatShopSection = CombatTab:AddSection("Cửa hàng phong cách cận chiến")

CombatShopSection:AddDropdown("FightingStyleShopDrop", {
    Title = "Chọn phong cách muốn mua",
    Description = "Giá được hiển thị ngay cạnh tên; mua lại phong cách đã sở hữu thường sẽ trang bị lại.",
    Values = CombatShop.StyleLabels,
    Default = CombatShop.GetStyleLabel(_G.SelectedFightingStyleShop),
    Callback = function(v)
        _G.SelectedFightingStyleShop = CombatShop.GetStyleId(v)
    end,
})

CombatShopSection:AddButton({
    Title = "Mua / trang bị phong cách đã chọn",
    Description = "Game tự kiểm tra tiền, Mảnh, thông thạo, nhiệm vụ và nguyên liệu.",
    Callback = function()
        task.spawn(function() CombatShop.BuyStyle(_G.SelectedFightingStyleShop) end)
    end,
})

CombatShopSection:AddButton({
    Title = "Xem giá và điều kiện",
    Description = "Hiện đầy đủ điều kiện của phong cách đang chọn.",
    Callback = function()
        CombatShop.ShowStyleInfo(_G.SelectedFightingStyleShop)
    end,
})

local AbilityShopSection = CombatTab:AddSection("Cửa hàng Haki & kỹ năng cơ bản")

AbilityShopSection:AddButton({
    Title = "Mua Nhảy trên không — 10.000 Beli",
    Description = "Tên nội bộ: Geppo / Air Jump.",
    Callback = function() CombatShop.BuyAbility("AirJump") end,
})

AbilityShopSection:AddButton({
    Title = "Mua Haki Vũ Trang — 25.000 Beli",
    Description = "Aura/Buso giúp đánh trúng mục tiêu hệ Nguyên tố.",
    Callback = function() CombatShop.BuyAbility("Aura") end,
})

AbilityShopSection:AddButton({
    Title = "Mua Bước nhanh — 100.000 Beli",
    Description = "Flash Step/Soru.",
    Callback = function() CombatShop.BuyAbility("FlashStep") end,
})

AbilityShopSection:AddButton({
    Title = "Mua Haki Quan Sát — 750.000 Beli",
    Description = "Yêu cầu cấp 300 trở lên và hoàn thành Saber Puzzle.",
    Callback = function() CombatShop.BuyAbility("Instinct") end,
})

AbilityShopSection:AddButton({
    Title = "Mua toàn bộ kỹ năng cơ bản — 885.000 Beli",
    Description = "Mua Air Jump, Aura, Flash Step và Instinct; game tự kiểm tra kỹ năng đã sở hữu.",
    Callback = function()
        task.spawn(function() CombatShop.BuyAllAbilities() end)
    end,
})

local CombatActionSection = CombatTab:AddSection("Kích hoạt nhanh")

CombatActionSection:AddButton({
    Title = "Bật Buso Haki",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
            notify("🥋", "Đã bật Buso Haki", 2)
        end)
    end
})

CombatActionSection:AddButton({
    Title = "Bật Ken Haki",
    Callback = function()
        if activateObservation(true) then
            notify("👁️", "Đã gửi thao tác bật Observation", 2)
        end
    end
})

CombatActionSection:AddButton({
    Title = "Duy trì Haki quan sát",
    Description = "Chỉ bật/duy trì Observation hiện có; không tự mở khóa V2.",
    Callback = function()
        if activateObservation(true) then
            notify("🔮", "Đã gửi thao tác duy trì Observation", 2)
        end
    end
})

end)

-- ==================== TAB 8: MISC ====================
local MiscTab = UITabs.Misc
runFeature("Giao diện Tiện ích", function()

local MovementSection = MiscTab:AddSection("Di chuyển nhân vật")

-- Speed & Jump
MovementSection:AddToggle("WalkSpeedToggle", {
    Title = "Điều chỉnh tốc độ chạy",
    Default = _G.WalkSpeedHack,
    Callback = function(v) _G.WalkSpeedHack = v; if not v then restoreMovementStats("WalkSpeed") end end,
})

MovementSection:AddSlider("WalkSpeedSlider", {
    Title = "Tốc Độ Chạy",
    Min = 16,
    Max = 300,
    Default = _G.WalkSpeedVal,
    Rounding = 0,
    Callback = function(v) _G.WalkSpeedVal = v end,
})

MovementSection:AddToggle("JumpPowerToggle", {
    Title = "Điều chỉnh sức nhảy",
    Default = _G.JumpPowerHack,
    Callback = function(v) _G.JumpPowerHack = v; if not v then restoreMovementStats("JumpPower") end end,
})

MovementSection:AddSlider("JumpPowerSlider", {
    Title = "Sức Nhảy",
    Min = 50,
    Max = 500,
    Default = _G.JumpPowerVal,
    Rounding = 0,
    Callback = function(v) _G.JumpPowerVal = v end,
})

MovementSection:AddToggle("InfiniteJumpToggle", {
    Title = "Nhảy vô hạn",
    Description = "Nhảy không giới hạn trên không",
    Default = _G.InfiniteJump,
    Callback = function(v) _G.InfiniteJump = v end,
})

MovementSection:AddToggle("InfiniteEnergyToggle", {
    Title = "Năng lượng vô hạn",
    Description = "Năng lượng không giới hạn",
    Default = _G.InfiniteEnergy,
    Callback = function(v) _G.InfiniteEnergy = v end,
})

-- Stats
local StatsSection = MiscTab:AddSection("Chỉ số tự động")

StatsSection:AddToggle("AutoStatsToggle", {
    Title = "Tự động cộng điểm chỉ số",
    Default = _G.AutoStats,
    Callback = function(v) _G.AutoStats = v end,
})

StatsSection:AddDropdown("StatDropdown", {
    Title = "Chọn chỉ số",
    Values = statLabels,
    Default = statValueToLabel[_G.StatToUpgrade] or statLabels[1],
    Callback = function(v) _G.StatToUpgrade = statLabelToValue[v] or _G.StatToUpgrade end,
})

-- Mã quà tặng
local RewardCodeSection = MiscTab:AddSection("Mã x2 EXP & đặt lại chỉ số")

RewardCodeSection:AddParagraph({
    Title = "Danh sách mã đang hoạt động",
    Content = "Đã đối chiếu ngày 31/07/2026 • 18 mã x2 EXP • 3 mã đặt lại chỉ số."
})

RewardCodeSection:AddToggle("AutoRedeemExpCodesToggle", {
    Title = "Tự nhập mã x2 EXP",
    Description = "Tự nhập một lần sau khi vào game; thời gian x2 EXP hợp lệ sẽ cộng dồn.",
    Default = _G.AutoRedeemExpCodes,
    Callback = function(v)
        _G.AutoRedeemExpCodes = v
        if v then RewardCodes.SetPending("exp") end
    end,
})

RewardCodeSection:AddToggle("AutoRedeemResetCodesToggle", {
    Title = "Tự nhập mã đặt lại chỉ số",
    Description = "Cảnh báo: mã hợp lệ sẽ đặt lại toàn bộ điểm đã cộng. Mặc định tắt.",
    Default = _G.AutoRedeemResetCodes,
    Callback = function(v)
        _G.AutoRedeemResetCodes = v
        if v then RewardCodes.SetPending("reset") end
    end,
})

RewardCodeSection:AddButton({
    Title = "Nhập lại toàn bộ mã x2 EXP",
    Description = "Thử lại cả mã mới lẫn mã đã thử trong phiên hiện tại.",
    Callback = function()
        task.spawn(function() RewardCodes.RedeemExp(true) end)
    end,
})

RewardCodeSection:AddButton({
    Title = "Nhập mã đặt lại chỉ số ngay",
    Description = "Chỉ dùng khi bạn thực sự muốn xóa cách cộng điểm hiện tại.",
    Callback = function()
        task.spawn(function() RewardCodes.RedeemReset(true) end)
    end,
})

-- Anti-AFK
local ProtectionSection = MiscTab:AddSection("Bảo vệ phiên chơi")

ProtectionSection:AddToggle("AntiAFKToggle", {
    Title = "Chống mất kết nối khi đứng yên",
    Description = "Ngăn game ngắt kết nối do đứng yên quá lâu",
    Default = _G.AntiAFK,
    Callback = function(v) _G.AntiAFK = v end,
})

-- FPS Boost
local PerformanceSection = MiscTab:AddSection("Hiệu năng & hiển thị")

PerformanceSection:AddButton({
    Title = "Tối ưu FPS",
    Description = "Tắt họa tiết và hiệu ứng hạt để giảm giật; vào lại máy chủ để hoàn tác.",
    Callback = function()
        pcall(function()
            local removed = 0
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                    removed = removed + 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj:Destroy()
                    removed = removed + 1
                end
            end
            -- Đơn giản hóa material
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
            -- Giảm chất lượng ánh sáng
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            notify("⚡ FPS Boost", "Đã xóa " .. removed .. " hiệu ứng + đơn giản hóa vật liệu", 3)
        end)
    end
})

PerformanceSection:AddButton({
    Title = "Chế độ nền trắng",
    Description = "Xóa bầu trời và đổi nền thành màu trắng",
    Callback = function()
        pcall(function()
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            for _, obj in pairs(Lighting:GetChildren()) do
                if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds")
                    or obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
                    or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
                    obj:Destroy()
                end
            end
            notify("⬜", "White Screen đã bật", 2)
        end)
    end
})

PerformanceSection:AddButton({
    Title = "Chế độ nền đen",
    Description = "Xóa bầu trời và đổi nền thành màu đen",
    Callback = function()
        pcall(function()
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.Brightness = 0
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            for _, obj in pairs(Lighting:GetChildren()) do
                if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds")
                    or obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
                    or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
                    obj:Destroy()
                end
            end
            notify("⬛", "Black Screen đã bật", 2)
        end)
    end
})

-- Server Hop
local MiscServerSection = MiscTab:AddSection("Tự động đổi máy chủ")

MiscServerSection:AddButton({
    Title = "Đổi máy chủ ngay",
    Description = "Chuyển sang máy chủ công khai khác",
    Callback = function()
        notify("Đổi máy chủ", "Đang tìm máy chủ...", 2)
        serverHop()
    end
})

MiscServerSection:AddToggle("ServerHopNoFruitToggle", {
    Title = "Tự đổi máy chủ khi không có Trái",
    Description = "Tự động chuyển sang máy chủ ít người nếu không tìm thấy Trái",
    Default = _G.ServerHopNoFruit,
    Callback = function(v) _G.ServerHopNoFruit = v end,
})

end)

