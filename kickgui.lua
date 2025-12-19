--[[ 
    PHIÊN BẢN CHỐNG NGẮT SCRIPT (ANTI-TERMINATE)
    - Tự động phát hiện và khởi động lại toàn bộ hệ thống khi chuyển Map.
    - Ép buộc hiển thị ngay cả khi game load lại môi trường.
]]

-- Đợi 15 giây để map đầu tiên load xong hoàn toàn
task.wait(15)

local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 

-- Khởi tạo biến môi trường (Lưu ngoài vòng lặp)
_G.MonitorRunning = _G.MonitorRunning or false
if _G.MonitorRunning then return end -- Ngăn chạy đè nhiều script
_G.MonitorRunning = true

local startTime = os.time()
local lastValue = -1
local isVisible = true
local isError = false

--------------------------------------------------
-- HÀM TẠO GIAO DIỆN
--------------------------------------------------
local function BuildUI()
    local existing = PlayerGui:FindFirstChild("GINGER_MONITOR")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GINGER_MONITOR"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999999
    sg.ResetOnSpawn = false -- Cố gắng giữ lại
    sg.Parent = PlayerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(1, 0, 1, 0)
    main.BackgroundColor3 = isError and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 0, 0)
    main.BorderSizePixel = 0
    main.Visible = isVisible
    main.Parent = sg

    local list = Instance.new("UIListLayout")
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Parent = main

    local function createLabel(name, size)
        local l = Instance.new("TextLabel")
        l.Name = name
        l.Size = size
        l.BackgroundTransparency = 1
        l.TextColor3 = isError and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        l.Font = Enum.Font.GothamBold
        l.TextScaled = true
        l.RichText = true
        l.Parent = main
        return l
    end

    local lTime = createLabel("LTime", UDim2.new(1, 0, 0.2, 0))
    local lTotal = createLabel("LTotal", UDim2.new(1, 0, 0.4, 0))
    local lDiff = createLabel("LDiff", UDim2.new(1, 0, 0.2, 0))

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 45)
    btn.Position = UDim2.new(0.01, 0, 0.98, -50)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "ẨN / HIỆN"
    btn.Parent = sg

    btn.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        main.Visible = isVisible
    end)

    return main, lTime, lTotal, lDiff
end

--------------------------------------------------
-- VÒNG LẶP CHÍNH (Sử dụng Pcall để chống crash)
--------------------------------------------------

local function StartSystem()
    local main, lTime, lTotal, lDiff = BuildUI()
    
    -- Vòng lặp cập nhật UI & Đồng hồ (Cực nhanh để chống mất)
    task.spawn(function()
        while true do
            if not sg or not sg.Parent then
                 main, lTime, lTotal, lDiff = BuildUI()
            end
            
            local elapsed = os.time() - startTime
            lTime.Text = "<b>" .. math.floor(elapsed / 3600) .. " : " .. math.floor((elapsed % 3600) / 60) .. "</b>"
            task.wait(1)
        end
    end)

    -- Vòng lặp kiểm tra tiền
    task.spawn(function()
        local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
        
        while true do
            local success, result = pcall(function()
                local data = ClientData.get_data()[player.Name]
                local val = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
                
                if val then
                    lTotal.Text = "<b>" .. val .. "</b>"
                    if lastValue ~= -1 then
                        local diff = val - lastValue
                        lDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>"
                        
                        if diff == 0 then
                            isError = true
                            main.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                            lTime.TextColor3 = Color3.fromRGB(0,0,0)
                            lTotal.TextColor3 = Color3.fromRGB(0,0,0)
                            lDiff.TextColor3 = Color3.fromRGB(0,0,0)
                            task.wait(2)
                            player:Kick("GINGERBREAD KHÔNG ĐỔI!")
                        end
                    end
                    lastValue = val
                end
            end)
            task.wait(CHECK_INTERVAL)
        end
    end)
end

-- Lệnh quan trọng: Tự động chạy lại khi phát hiện môi trường game bị thay đổi
player.CharacterAdded:Connect(function()
    task.wait(5) -- Chờ nhân vật load xong map mới
    BuildUI()
end)

StartSystem()
