--[[ 
    PHIÊN BẢN SỬA LỖI MẤT GUI TUYỆT ĐỐI
    - Giữ nguyên giao diện của bạn (Dòng 1: 0.2, Dòng 2: 0.4, Dòng 3: 0.2)
    - Cơ chế tự phục hồi dựa trên sự kiện ChildAdded (Roblox không thể ngắt)
]]

task.wait(35)

local player = game.Players.LocalPlayer
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60
local startTime = os.time()
local lastValue = -1
local isVisible = true
local isErrorState = false

--------------------------------------------------
-- HÀM TẠO GUI (Giao diện chuẩn của bạn)
--------------------------------------------------
local function CreateGUI()
    local PlayerGui = player:WaitForChild("PlayerGui")
    if PlayerGui:FindFirstChild("GINGER_MONITOR") then return end -- Tránh tạo trùng

    local sg = Instance.new("ScreenGui")
    sg.Name = "GINGER_MONITOR"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999999
    sg.ResetOnSpawn = false
    sg.Parent = PlayerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
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
    btn.Text = "ẨN / HIỆN"
    btn.Font = Enum.Font.GothamBold
    btn.Parent = sg

    btn.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        main.Visible = isVisible
    end)
end

--------------------------------------------------
-- CƠ CHẾ TỰ PHỤC HỒI (KEY FIX)
--------------------------------------------------
-- Mỗi khi PlayerGui được nạp lại (chuyển map), script sẽ tự vẽ lại GUI
player.PlayerGui.ChildAdded:Connect(function()
    task.wait(1) -- Chờ môi trường ổn định
    CreateGUI()
end)

-- Tạo GUI ngay lập tức
CreateGUI()

--------------------------------------------------
-- VÒNG LẶP CẬP NHẬT DỮ LIỆU
--------------------------------------------------
task.spawn(function()
    local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
    
    while true do
        local sg = player.PlayerGui:FindFirstChild("GINGER_MONITOR")
        local main = sg and sg:FindFirstChild("Main")
        
        if main then
            -- 1. Cập nhật đồng hồ
            local elapsed = os.time() - startTime
            main.LTime.Text = "<b>" .. math.floor(elapsed / 3600) .. " : " .. math.floor((elapsed % 3600) / 60) .. "</b>"
            
            -- 2. Cập nhật số liệu
            local data = ClientData.get_data()[player.Name]
            local val = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
            
            if val then
                main.LTotal.Text = "<b>" .. val .. "</b>"
                if lastValue ~= -1 then
                    local diff = val - lastValue
                    main.LDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>"
                else
                    main.LDiff.Text = "<b>0</b>"
                end
                lastValue = val
            end
        end
        task.wait(1)
    end
end)

-- Vòng lặp kiểm tra Kick (12 phút)
task.spawn(function()
    while true do
        task.wait(CHECK_INTERVAL)
        local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
        local data = ClientData.get_data()[player.Name]
        local currentValue = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
        
        if currentValue and lastValue ~= -1 and currentValue == lastValue then
            isErrorState = true
            CreateGUI() -- Ép cập nhật màu đỏ
            task.wait(2)
            player:Kick("Gingerbread không đổi 12 phút.")
        end
    end
end)
