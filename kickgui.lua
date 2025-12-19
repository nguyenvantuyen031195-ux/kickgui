--[[ 
    PHIÊN BẢN CHỐNG LỖI CHUYỂN MAP LẦN ĐẦU
    - Tự động phát hiện nếu GUI bị game xóa do load map chưa xong.
    - Duy trì trạng thái nền Đen/Chữ Trắng và Đỏ/Đen khi lỗi.
    - Chữ siêu lớn, hiển thị trên cùng.
]]

task.wait(15) -- Chờ game load ổn định

local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 
local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local startTime = os.time()

local lastValue = -1
local isVisible = true
local isErrorState = false

--------------------------------------------------
-- HÀM TẠO GUI (Có cơ chế tự vệ)
--------------------------------------------------
local function CreateGUI()
    -- Tìm và dọn dẹp các bản lỗi trước đó
    local existing = PlayerGui:FindFirstChild("GingerbreadMonitor_Final")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GingerbreadMonitor_Final"
    sg.IgnoreGuiInset = true 
    sg.DisplayOrder = 999999999 
    sg.ResetOnSpawn = false -- Giữ lại khi chuyển các map sau
    sg.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = isErrorState and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Visible = isVisible
    frame.Parent = sg

    local uiList = Instance.new("UIListLayout")
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.VerticalAlignment = Enum.VerticalAlignment.Center
    uiList.Parent = frame

    -- Dòng 1: Thời gian
    local lTime = Instance.new("TextLabel")
    lTime.Name = "TimeLabel"
    lTime.Size = UDim2.new(1, 0, 0.2, 0)
    lTime.BackgroundTransparency = 1
    lTime.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    lTime.Font = Enum.Font.GothamBold
    lTime.TextScaled = true
    lTime.RichText = true
    lTime.Parent = frame

    -- Dòng 2: Tổng số
    local lTotal = Instance.new("TextLabel")
    lTotal.Name = "TotalLabel"
    lTotal.Size = UDim2.new(1, 0, 0.4, 0)
    lTotal.BackgroundTransparency = 1
    lTotal.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    lTotal.Font = Enum.Font.GothamBold
    lTotal.TextScaled = true
    lTotal.RichText = true
    lTotal.Text = "..."
    lTotal.Parent = frame

    -- Dòng 3: Chênh lệch
    local lDiff = Instance.new("TextLabel")
    lDiff.Name = "DiffLabel"
    lDiff.Size = UDim2.new(1, 0, 0.2, 0)
    lDiff.BackgroundTransparency = 1
    lDiff.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    lDiff.Font = Enum.Font.GothamBold
    lDiff.TextScaled = true
    lDiff.RichText = true
    lDiff.Parent = frame

    -- Nút Tắt/Bật
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
        frame.Visible = isVisible
    end)
    
    return sg
end

local screenGui = CreateGUI()

--------------------------------------------------
-- HỆ THỐNG GIÁM SÁT DỮ LIỆU & GUI
--------------------------------------------------

local function getElements()
    local sg = PlayerGui:FindFirstChild("GingerbreadMonitor_Final")
    if sg and sg:FindFirstChild("Frame") then -- Nếu bạn đổi tên Frame, hãy sửa ở đây
        local f = sg:FindFirstChildOfClass("Frame")
        return f, f:FindFirstChild("TimeLabel"), f:FindFirstChild("TotalLabel"), f:FindFirstChild("DiffLabel")
    end
    -- Nếu không tìm thấy, thử tìm lại dựa trên class
    local altSg = PlayerGui:FindFirstChild("GingerbreadMonitor_Final")
    if altSg then
        local f = altSg:FindFirstChildOfClass("Frame")
        if f then
            return f, f:FindFirstChild("TimeLabel"), f:FindFirstChild("TotalLabel"), f:FindFirstChild("DiffLabel")
        end
    end
    return nil
end

-- Vòng lặp 1: Bảo vệ GUI & Đồng hồ (Chạy mỗi 1 giây)
task.spawn(function()
    while true do
        local frame, lTime = getElements()
        if not frame then
            screenGui = CreateGUI() -- Tái tạo nếu mất
        else
            local elapsed = os.time() - startTime
            lTime.Text = "<b>" .. math.floor(elapsed / 3600) .. " : " .. math.floor((elapsed % 3600) / 60) .. "</b>"
        end
        task.wait(1)
    end
end)

-- Vòng lặp 2: Kiểm tra tiền (Chạy mỗi 12 phút)
task.spawn(function()
    local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
    
    while true do
        local data = ClientData.get_data()[player.Name]
        local currentValue = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
        
        local frame, _, lTotal, lDiff = getElements()

        if currentValue and lTotal then
            lTotal.Text = "<b>" .. currentValue .. "</b>"
            
            if lastValue ~= -1 then
                local diff = currentValue - lastValue
                lDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>"
                
                if diff == 0 then
                    isErrorState = true
                    if frame then 
                        frame.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                        for _, child in ipairs(frame:GetChildren()) do
                            if child:IsA("TextLabel") then child.TextColor3 = Color3.fromRGB(0,0,0) end
                        end
                    end
                    task.wait(2)
                    player:Kick("Gingerbread không đổi 12 phút.")
                    break
                end
            else
                lDiff.Text = "<b>0</b>"
            end
            lastValue = currentValue
        end
        task.wait(CHECK_INTERVAL)
    end
end)
