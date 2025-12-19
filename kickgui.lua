--[[ 
    HỆ THỐNG GIÁM SÁT GINGERBREAD 2025 - PHIÊN BẢN FIX LỖI PARSING
    - Chờ 35 giây trước khi chạy.
    - Sửa lỗi cú pháp "expected identifier".
    - Chống mất GUI khi chuyển map lần đầu.
]]

task.wait(35)

-- Cấu hình
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 
local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
local player = game.Players.LocalPlayer
local startTime = os.time()

local lastValue = -1
local isVisible = true
local isErrorState = false

--------------------------------------------------
-- HÀM TẠO GIAO DIỆN
--------------------------------------------------
local function CreateGUI()
    local PlayerGui = player:WaitForChild("PlayerGui")
    local old = PlayerGui:FindFirstChild("GingerbreadMonitor_Delayed")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GingerbreadMonitor_Delayed"
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

    local uiList = Instance.new("UIListLayout")
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.VerticalAlignment = Enum.VerticalAlignment.Center
    uiList.Parent = main

    local function makeLabel(name, size)
        local l = Instance.new("TextLabel")
        l.Name = name
        l.Size = size
        l.BackgroundTransparency = 1
        l.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        l.Font = Enum.Font.GothamBold
        l.TextScaled = true
        l.RichText = true
        l.Text = ""
        l.Parent = main
        return l
    end

    makeLabel("LTime", UDim2.new(1, 0, 0.2, 0))
    makeLabel("LTotal", UDim2.new(1, 0, 0.4, 0))
    makeLabel("LDiff", UDim2.new(1, 0, 0.2, 0))

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 45)
    btn.Position = UDim2.new(0.01, 0, 0.98, -50)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "ẨN / HIỆN"
    btn.Parent = sg

    btn.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        main.Visible = isVisible
    end)
end

--------------------------------------------------
-- LOGIC XỬ LÝ
--------------------------------------------------

local function fetchGingerbread()
    local success, data = pcall(function()
        return ClientData.get_data()[player.Name]
    end)
    if success and data then
        return (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME]) or data[CURRENCY_NAME]
    end
    return nil
end

local function performCheck()
    local currentValue = fetchGingerbread()
    local sg = player.PlayerGui:FindFirstChild("GingerbreadMonitor_Delayed")
    local main = sg and sg:FindFirstChild("MainFrame")

    if currentValue ~= nil and main then
        main.LTotal.Text = "<b>" .. tostring(currentValue) .. "</b>"
        
        if lastValue ~= -1 then
            local diff = currentValue - lastValue
            main.LDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. tostring(diff) .. "</b>"
            
            if diff == 0 then
                isErrorState = true
                main.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                task.wait(2)
                player:Kick("\n[HỆ THỐNG]\nGingerbread không đổi!")
            else
                isErrorState = false
                main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
        else
            main.LDiff.Text = "<b>0</b>"
        end
        lastValue = currentValue
    end
end

--------------------------------------------------
-- VẬN HÀNH
--------------------------------------------------

-- 1. Vòng lặp Bảo trì GUI & Đồng hồ (Chống mất GUI khi chuyển map)
task.spawn(function()
    while true do
        local sg = player.PlayerGui:FindFirstChild("GingerbreadMonitor_Delayed")
        if not sg then
            CreateGUI()
            sg = player.PlayerGui:FindFirstChild("GingerbreadMonitor_Delayed")
        end
        
        local main = sg:FindFirstChild("MainFrame")
        if main then
            local elapsed = os.time() - startTime
            main.LTime.Text = "<b>" .. math.floor(elapsed / 3600) .. " : " .. math.floor((elapsed % 3600) / 60) .. "</b>"
            
            -- Cập nhật số liên tục cho mượt
            local currentVal = fetchGingerbread()
            if currentVal then main.LTotal.Text = "<b>" .. tostring(currentVal) .. "</b>" end
        end
        task.wait(1)
    end
end)

-- 2. Vòng lặp Kiểm tra Kick (12 phút)
task.spawn(function()
    while lastValue == -1 do 
        lastValue = fetchGingerbread() 
        task.wait(1) 
    end
    
    while true do
        task.wait(CHECK_INTERVAL)
        performCheck()
    end
end)
