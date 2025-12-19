--[[ 
    PHIÊN BẢN CHỐNG MẤT GUI (Dựa trên bản gốc của bạn)
    - Giữ nguyên giao diện: Nền đen/Chữ trắng, Nút ẩn hiện, Chữ siêu to.
    - Chống mất GUI: Tự động vẽ lại nếu bị game xóa sau khi chuyển map.
    - Delay 15s trước khi khởi chạy.
]]

task.wait(15)

-- Cấu hình
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 
local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local startTime = os.time()

local lastValue = -1
local isVisible = true
local isErrorState = false

--------------------------------------------------
-- HÀM TẠO GIAO DIỆN (ĐƯỢC GỌI LẠI NẾU MẤT)
--------------------------------------------------
local screenGui, mainFrame, labelTime, labelTotal, labelDiff, toggleBtn

local function CreateGUI()
    -- Dọn dẹp bản cũ nếu có
    local old = PlayerGui:FindFirstChild("GingerbreadMonitor_Delayed")
    if old then old:Destroy() end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GingerbreadMonitor_Delayed"
    screenGui.IgnoreGuiInset = true 
    screenGui.DisplayOrder = 999999999 
    screenGui.ResetOnSpawn = false -- Giúp GUI sống sót khi reset nhân vật
    screenGui.Parent = PlayerGui

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = isErrorState and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 0, 0)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = isVisible
    mainFrame.Parent = screenGui

    local uiList = Instance.new("UIListLayout")
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.VerticalAlignment = Enum.VerticalAlignment.Center
    uiList.Parent = mainFrame

    -- Dòng 1: Thời gian chạy (Size 0.2 của bạn)
    labelTime = Instance.new("TextLabel")
    labelTime.Size = UDim2.new(1, 0, 0.2, 0)
    labelTime.BackgroundTransparency = 1
    labelTime.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    labelTime.Font = Enum.Font.GothamBold
    labelTime.TextScaled = true
    labelTime.RichText = true
    labelTime.Parent = mainFrame

    -- Dòng 2: Tổng số (Size 0.4 của bạn)
    labelTotal = Instance.new("TextLabel")
    labelTotal.Size = UDim2.new(1, 0, 0.4, 0)
    labelTotal.BackgroundTransparency = 1
    labelTotal.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    labelTotal.Font = Enum.Font.GothamBold
    labelTotal.TextScaled = true
    labelTotal.RichText = true
    labelTotal.Text = "..."
    labelTotal.Parent = mainFrame

    -- Dòng 3: Chênh lệch (Size 0.2 của bạn)
    labelDiff = Instance.new("TextLabel")
    labelDiff.Size = UDim2.new(1, 0, 0.2, 0)
    labelDiff.BackgroundTransparency = 1
    labelDiff.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    labelDiff.Font = Enum.Font.GothamBold
    labelDiff.TextScaled = true
    labelDiff.RichText = true
    labelDiff.Text = "0"
    labelDiff.Parent = mainFrame

    -- Nút Tắt/Bật
    toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 45)
    toggleBtn.Position = UDim2.new(0.01, 0, 0.98, -50)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Text = "ẨN / HIỆN"
    toggleBtn.Parent = screenGui

    toggleBtn.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        mainFrame.Visible = isVisible
    end)
end

--------------------------------------------------
-- LOGIC CẬP NHẬT
--------------------------------------------------

local function performCheck()
    local data = ClientData.get_data()[player.Name]
    local currentValue = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
    
    if currentValue ~= nil and labelTotal then
        labelTotal.Text = "<b>" .. currentValue .. "</b>"
        
        if lastValue ~= -1 then
            local diff = currentValue - lastValue
            if labelDiff then labelDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>" end
            
            if diff == 0 then
                isErrorState = true
                if mainFrame then mainFrame.BackgroundColor3 = Color3.fromRGB(200, 0, 0) end
                task.wait(2)
                player:Kick("\n[HỆ THỐNG GIÁM SÁT]\nGingerbread không đổi trong 12 phút.")
                return
            else
                isErrorState = false
                if mainFrame then mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
            end
        end
        lastValue = currentValue
    end
end

--------------------------------------------------
-- VÒNG LẶP HỆ THỐNG
--------------------------------------------------

CreateGUI()

-- Vòng lặp 1: Cập nhật đồng hồ & Tự phục hồi GUI nếu bị mất
task.spawn(function()
    while true do
        if not screenGui or not screenGui.Parent then
            CreateGUI()
        end
        
        local elapsed = os.time() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        if labelTime then 
            labelTime.Text = "<b>" .. hours .. " : " .. minutes .. "</b>" 
        end
        
        task.wait(1)
    end
end)

-- Vòng lặp 2: Kiểm tra 12 phút
task.spawn(function()
    -- Cập nhật số liệu ngay lần đầu sau 15s chờ
    performCheck()
    
    while true do
        task.wait(CHECK_INTERVAL)
        performCheck()
    end
end)
