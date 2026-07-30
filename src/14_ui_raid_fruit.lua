-- ==================== TAB 3: RAID ====================
local RaidTab = UITabs.Raid
runFeature("Giao diện Raid", function()

local RaidMainSection = RaidTab:AddSection("Đột kích & thức tỉnh")

RaidMainSection:AddToggle("AutoRaidToggle", {
    Title = "Tự động bắt đầu đột kích",
    Description = "Tự động bắt đầu đột kích với chip được chọn",
    Default = _G.AutoRaid,
    Callback = function(v) _G.AutoRaid = v end,
})

RaidMainSection:AddToggle("AutoRaidFarmToggle", {
    Title = "Tự động đánh trong đột kích",
    Description = "Tự động đánh quái bên trong khu đột kích",
    Default = _G.AutoRaidFarm,
    Callback = function(v)
        _G.AutoRaidFarm = v
        if not v and not _G.AutoFarmLevel and not _G.AutoFarmMastery
            and not _G.AutoFarmBoss and not _G.AutoFarmSeaBeast then
            stopFarmMovement()
        end
    end,
})

RaidMainSection:AddDropdown("RaidChipDrop", {
    Title = "Chọn chip đột kích",
    Values = RaidChips,
    Default = _G.RaidChip,
    Callback = function(v) _G.RaidChip = v end,
})

RaidMainSection:AddToggle("AutoAwakeningToggle", {
    Title = "Tự động thức tỉnh",
    Description = "Tự kiểm tra và thức tỉnh kỹ năng khi đang ở phòng Thức tỉnh",
    Default = _G.AutoAwakening,
    Callback = function(v) _G.AutoAwakening = v end,
})

RaidMainSection:AddButton({
    Title = "🔄 Bắt đầu đột kích ngay",
    Description = "Bắt đầu đột kích với chip đã chọn",
    Callback = function()
        if WorldSea == 1 then
            notify("Đột kích", "Đột kích chỉ mở tại Biển 2 hoặc Biển 3.", 4)
        elseif startSelectedRaid() then
            notify("⚡ Đột kích", "Đã gửi thao tác bắt đầu đột kích " .. _G.RaidChip .. ".", 3)
        end
    end
})

end)

-- ==================== TAB 4: FRUIT ====================
local FruitTab = UITabs.Fruit
runFeature("Giao diện Trái", function()

local FruitAutoSection = FruitTab:AddSection("Theo dõi & tự động nhặt")

FruitAutoSection:AddToggle("AutoFindFruitToggle", {
    Title = "Báo khi Trái xuất hiện",
    Description = "Thông báo khi có Trái ác quỷ xuất hiện trên bản đồ",
    Default = _G.AutoFruitFinder,
    Callback = function(v) _G.AutoFruitFinder = v end,
})

FruitAutoSection:AddToggle("AutoCollectFruitToggle", {
    Title = "Tự động nhặt Trái",
    Description = "Ưu tiên bay tới nhặt Trái, sau đó tự quay lại luyện cấp",
    Default = _G.AutoCollectFruit,
    Callback = function(v)
        local wasFruitMode = getActiveMovementMode() == "fruit"
        _G.AutoCollectFruit = v
        if not v then
            activeFruitTarget = nil
            if wasFruitMode then stopFarmMovement() end
        end
    end,
})

FruitAutoSection:AddToggle("AutoStoreFruitToggle", {
    Title = "Tự động cất Trái vào kho",
    Description = "Cất trái vừa nhặt; nếu kho đã có trái đó thì giữ trái trùng ngoài tay.",
    Default = _G.AutoStoreFruit,
    Callback = function(v) _G.AutoStoreFruit = v end,
})

FruitAutoSection:AddToggle("FruitESPToggle", {
    Title = "Đánh dấu Trái ác quỷ",
    Description = "Hiển thị vị trí Trái ác quỷ trên bản đồ",
    Default = _G.FruitESP,
    Callback = function(v) _G.FruitESP = v end,
})

FruitAutoSection:AddToggle("AutoGachaToggle", {
    Title = "Tự động mua Trái ngẫu nhiên",
    Description = "Gửi yêu cầu mua trái mỗi 30 giây; game vẫn áp dụng tiền và thời gian chờ",
    Default = _G.AutoGachaFruit,
    Callback = function(v) _G.AutoGachaFruit = v end,
})

local FruitActionSection = FruitTab:AddSection("Thao tác nhanh")

FruitActionSection:AddButton({
    Title = "Kiểm tra và cất trái đang giữ",
    Description = "Cất trái chưa có trong kho; trái trùng sẽ được giữ ngoài tay.",
    Callback = function()
        task.spawn(function()
            local stored, duplicates, failed = FruitStorage.StoreNow(true)
            notify(
                "Kiểm tra kho trái",
                string.format("Đã cất %d • Trùng %d • Lỗi %d\n%s",
                    stored, duplicates, failed, FruitStorage.GetStatus()),
                6
            )
        end)
    end,
})

FruitActionSection:AddButton({
    Title = "Mua trái ngẫu nhiên",
    Description = "Mua một Trái ngẫu nhiên từ người bán Trái ác quỷ",
    Callback = function()
        pcall(function()
            local res = ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            notify("🎰 Mua Trái ngẫu nhiên", tostring(res or "Đã gửi yêu cầu Mua trái"), 6)
        end)
    end
})

FruitActionSection:AddButton({
    Title = "Quét trái trên toàn bản đồ",
    Description = "Quét các Trái thật đang nằm trên bản đồ",
    Callback = function()
        local fruits = getSpawnedFruits()
        if #fruits == 0 then
            notify("🔍 Quét xong", "Không tìm thấy trái nào trên map", 3)
            return
        end
        for index, fruit in ipairs(fruits) do
            local handle = getFruitHandle(fruit)
            notify("🍎 Trái #" .. index, fruit.Name .. " tại " .. tostring(handle and handle.Position), 5)
        end
        notify("🔍 Quét xong", "Tìm thấy " .. #fruits .. " trái!", 3)
    end
})


FruitActionSection:AddButton({
    Title = "Mở cửa hàng trái",
    Description = "Nạp dữ liệu và mở cửa hàng Trái nếu game đã tạo giao diện.",
    Callback = function()
        local opened = false
        runFeature("Mở cửa hàng trái", function()
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits") end)
            local pGui = Player:FindFirstChild("PlayerGui")
            local mainGui = pGui and pGui:FindFirstChild("Main")
            if mainGui then
                for _, name in ipairs({"FruitShop", "FruitStore", "FruitDealer", "Shop", "FruitInventory", "ShopFrame"}) do
                    local shop = mainGui:FindFirstChild(name, true)
                    if shop and shop:IsA("GuiObject") then
                        shop.Visible = true
                        opened = true
                    end
                end
            end
        end)
        if opened then
            notify("🍎 Cửa hàng trái", "Đã mở giao diện cửa hàng trái quỷ.", 4)
        else
            notify("🍎 Cửa hàng trái", "Đã nạp dữ liệu cửa hàng từ máy chủ.", 5)
        end
    end
})

end)

