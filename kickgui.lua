--[[ 
    PHIÊN BẢN SỬA LỖI HIỂN THỊ "LABEL"
    - Chờ 15 giây khởi động.
    - Cơ chế quét tìm Label liên tục (Dynamic Fetching).
    - Tự động hiện lại GUI nếu bị game xóa khi chuyển map.
]]

task.wait(15)

local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 

local startTime = os.time()
local lastValue = -1
local isVisible = true
local isErrorState = false

--------------------------------------------------
-- HÀM TẠO GIAO DIỆN
--------------------------------------------------
local function CreateGUI()
    local existing = PlayerGui:FindFirstChild("GINGER_MONITOR")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GINGER_MONITOR"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999999
    sg.ResetOnSpawn = false
    sg.Parent = PlayerGui

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(1, 0, 1, 0)
    main.BackgroundColor3 = isErrorState and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 0, 0)
    main.BorderSizePixel = 0
    main.Visible = isVisible
    main.Parent = sg

    local list = Instance.new("UIListLayout")
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Parent = main

    local function makeLabel(name, size)
        local l = Instance.new("TextLabel")
        l.Name = name
        l.Size = size
        l.BackgroundTransparency = 1
        l.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        l.Font = Enum.Font.GothamBold
        l.TextScaled = true
        l.RichText = true
        l.Text = "" -- Để trống để không hiện chữ "Label" mặc định
        l.Parent = main
        return l
    end

    makeLabel("TimeLabel", UDim2.new(1, 0, 0.2, 0))
    makeLabel("TotalLabel", UDim2.new(1, 0, 0.4, 0))
    makeLabel("DiffLabel", UDim2.new(1, 0, 0.2, 0))

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(0, 120, 0, 45)
    btn.Position = UDim2.new(0.01, 0, 0.98, -50)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "ẨN / HIỆN"
    btn.Font = Enum.Font.GothamBold
    btn.Parent = sg

    btn.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        main.Visible = isVisible
    end)
end

-- Hàm tìm kiếm các nhãn hiện đang có trong PlayerGui
local function GetUIElements()
    local sg = PlayerGui:FindFirstChild("GINGER_MONITOR")
    if sg and sg:FindFirstChild("MainFrame") then
        local main = sg.MainFrame
        return main, main:FindFirstChild("TimeLabel"), main:FindFirstChild("TotalLabel"), main:FindFirstChild("DiffLabel")
    end
    return nil
end

--------------------------------------------------
-- VẬN HÀNH
--------------------------------------------------

-- 1. Vòng lặp Bảo vệ GUI & Đồng hồ (Cập nhật mỗi giây)
task.spawn(function()
    while true do
        local main, lTime = GetUIElements()
        if not main then
            CreateGUI()
        else
            local elapsed = os.time() - startTime
            local h = math.floor(elapsed / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            if lTime then lTime.Text = "<b>" .. h .. " : " .. m .. "</b>" end
        end
        task.wait(1)
    end
end)

-- 2. Vòng lặp Kiểm tra tiền (Cập nhật mỗi 12 phút)
task.spawn(function()
    local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
    
    while true do
        local data = ClientData.get_data()[player.Name]
        local val = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
        
        local main, _, lTotal, lDiff = GetUIElements()
        
        if val and lTotal then
            lTotal.Text = "<b>" .. val .. "</b>"
            
            if lastValue ~= -1 then
                local diff = val - lastValue
                if lDiff then lDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>" end
                
                if diff == 0 then
                    isErrorState = true -- Kích hoạt trạng thái đỏ
                    player:Kick("\n[HỆ THỐNG]\nGingerbread không đổi!")
                    return
                end
            else
                if lDiff then lDiff.Text = "<b>0</b>" end
            end
            lastValue = val
        end
        task.wait(CHECK_INTERVAL)
    end
end)
