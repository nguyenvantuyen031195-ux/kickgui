--[[ 
    PHIÊN BẢN CHỐNG XÓA TUYỆT ĐỐI
    - Tự động phát hiện môi trường mới sau khi chuyển Map.
    - Chạy vòng lặp bảo vệ GUI liên tục mỗi 0.5 giây.
]]

task.wait(15)

local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 
local ClientData = require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
local player = game.Players.LocalPlayer
local startTime = os.time()

local lastValue = -1
local isVisible = true
local isErrorState = false

--------------------------------------------------
-- HÀM TẠO GUI CẤP CAO
--------------------------------------------------
local function CreateGUI()
    -- Tìm và xóa mọi bản sao cũ trước khi tạo mới
    for _, old in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
        if old.Name == "GingerbreadMonitor_Final" then
            old:Destroy()
        end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GingerbreadMonitor_Final"
    sg.IgnoreGuiInset = true 
    sg.DisplayOrder = 999999999 
    sg.ResetOnSpawn = false
    sg.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = isErrorState and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Visible = isVisible
    frame.Parent = sg

    local uiList = Instance.new("UIListLayout")
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.VerticalAlignment = Enum.VerticalAlignment.Center
    uiList.Parent = frame

    local lTime = Instance.new("TextLabel")
    lTime.Name = "TimeLabel"
    lTime.Size = UDim2.new(1, 0, 0.2, 0)
    lTime.BackgroundTransparency = 1
    lTime.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    lTime.Font = Enum.Font.GothamBold
    lTime.TextScaled = true
    lTime.RichText = true
    lTime.Parent = frame

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

    local lDiff = Instance.new("TextLabel")
    lDiff.Name = "DiffLabel"
    lDiff.Size = UDim2.new(1, 0, 0.2, 0)
    lDiff.BackgroundTransparency = 1
    lDiff.TextColor3 = isErrorState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    lDiff.Font = Enum.Font.GothamBold
    lDiff.TextScaled = true
    lDiff.RichText = true
    lDiff.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleButton"
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
-- HỆ THỐNG BẢO VỆ VÀ CẬP NHẬT
--------------------------------------------------

-- Hàm lấy label an toàn (phòng trường hợp GUI bị tạo lại nửa chừng)
local function getLabel(name)
    local sg = player.PlayerGui:FindFirstChild("GingerbreadMonitor_Final")
    if sg and sg:FindFirstChild("MainFrame") then
        return sg.MainFrame:FindFirstChild(name)
    end
    return nil
end

task.spawn(function()
    while true do
        -- 1. Bảo vệ GUI: Nếu bị mất hoặc xóa, tạo lại ngay
        if not player.PlayerGui:FindFirstChild("GingerbreadMonitor_Final") then
            screenGui = CreateGUI()
        end

        -- 2. Cập nhật đồng hồ
        local lTime = getLabel("TimeLabel")
        if lTime then
            local elapsed = os.time() - startTime
            lTime.Text = "<b>" .. math.floor(elapsed / 3600) .. " : " .. math.floor((elapsed % 3600) / 60) .. "</b>"
        end
        
        task.wait(0.5)
    end
end)

local function performCheck()
    local data = ClientData.get_data()[player.Name]
    local currentValue = data and (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME] or data[CURRENCY_NAME])
    
    local lTotal = getLabel("TotalLabel")
    local lDiff = getLabel("DiffLabel")
    local frame = (player.PlayerGui:FindFirstChild("GingerbreadMonitor_Final") or {}).MainFrame

    if currentValue and lTotal then
        lTotal.Text = "<b>" .. currentValue .. "</b>"
        
        if lastValue ~= -1 then
            local diff = currentValue - lastValue
            if lDiff then lDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>" end
            
            if diff == 0 then
                isErrorState = true
                -- Cập nhật màu đỏ ngay lập tức
                if frame then frame.BackgroundColor3 = Color3.fromRGB(200, 0, 0) end
                task.wait(2)
                player:Kick("Gingerbread đứng im 12 phút.")
                return
            else
                isErrorState = false
                if frame then frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
            end
        end
        lastValue = currentValue
    end
end

-- Vòng lặp check 12 phút
task.spawn(function()
    while true do
        performCheck()
        task.wait(CHECK_INTERVAL)
    end
end)
