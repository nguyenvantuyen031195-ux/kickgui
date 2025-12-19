--[[
    GINGERBREAD MONITOR 2025 - PHIÊN BẢN CHỮ SIÊU LỚN (EQUAL SIZE)
    - Cả 3 dòng (Tổng, Chênh lệch, Thời gian) có kích thước to bằng nhau.
    - Chống mất GUI 100% bằng CoreGui/gethui.
    - Nền Đen/Chữ Xanh -> Lỗi: Nền Đỏ/Chữ Đen.
]]

task.wait(15)

local player = game.Players.LocalPlayer
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60

local startTime = os.time()
local lastValue = -1
local isErrorState = false
local isVisible = true

--------------------------------------------------
-- HỆ THỐNG GIAO DIỆN (BẤT TỬ)
--------------------------------------------------
local HopGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIList = Instance.new("UIListLayout")

-- Gắn vào khu vực bất tử (CoreGui hoặc gethui)
if gethui then
    HopGui.Parent = gethui()
elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
    HopGui.Parent = game:GetService("CoreGui").RobloxGui
else
    HopGui.Parent = game:GetService("CoreGui")
end

HopGui.Name = "GingerSystem_MaxFont"
HopGui.IgnoreGuiInset = true
HopGui.DisplayOrder = 999999

MainFrame.Name = "MainFrame"
MainFrame.Parent = HopGui
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 1

UIList.Parent = MainFrame
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.VerticalAlignment = Enum.VerticalAlignment.Center
UIList.Padding = UDim.new(0.01, 0) -- Khoảng cách cực nhỏ để chữ nở to nhất

-- Hàm tạo nhãn với kích thước đồng nhất
local function createLabel(name)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Parent = MainFrame
    -- Mỗi dòng chiếm ~30% chiều cao để 3 dòng cộng lại là ~90% màn hình
    label.Size = UDim2.new(0.98, 0, 0.3, 0) 
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.FredokaOne
    label.TextColor3 = Color3.fromRGB(0, 255, 127) -- Chữ xanh
    label.TextScaled = true
    label.RichText = true
    label.Text = ""
    
    return label
end

-- Khởi tạo 3 dòng to bằng nhau
local LTotal = createLabel("LTotal") -- Dòng 1
local LDiff  = createLabel("LDiff")  -- Dòng 2
local LTime  = createLabel("LTime")  -- Dòng 3

-- Nút Bấm Ẩn/Hiện
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = HopGui
ToggleBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 1, -50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "HIDE GUI"
ToggleBtn.Font = Enum.Font.FredokaOne
ToggleBtn.TextSize = 14
ToggleBtn.ZIndex = 10

ToggleBtn.MouseButton1Click:Connect(function()
    isVisible = not isVisible
    MainFrame.Visible = isVisible
end)

--------------------------------------------------
-- LOGIC DỮ LIỆU & KIỂM TRA
--------------------------------------------------
local function GetValue()
    local success, ClientData = pcall(function()
        return require(game.ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
    end)
    if success and ClientData then
        local data = ClientData.get_data()[player.Name]
        if data then
            return (data.inventory and data.inventory.currencies and data.inventory.currencies[CURRENCY_NAME]) or data[CURRENCY_NAME]
        end
    end
    return nil
end

local function ApplyStyle(err)
    isErrorState = err
    local bg = err and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 0)
    local txt = err and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 127)
    
    MainFrame.BackgroundColor3 = bg
    LTotal.TextColor3 = txt
    LDiff.TextColor3 = txt
    LTime.TextColor3 = txt
end

-- Vòng lặp cập nhật (Mỗi giây)
task.spawn(function()
    while true do
        -- Cập nhật Thời gian
        local elapsed = os.time() - startTime
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        LTime.Text = h .. " : " .. m
        
        -- Cập nhật Số liệu
        local currentVal = GetValue()
        if currentVal then
            LTotal.Text = tostring(currentVal)
            if lastValue ~= -1 then
                local diff = currentVal - lastValue
                LDiff.Text = (diff > 0 and "+" or "") .. tostring(diff)
            else
                LDiff.Text = "0"
            end
        end
        task.wait(15)
    end
end)

-- Vòng lặp kiểm tra Kick (12 phút)
task.spawn(function()
    -- Lấy mốc dữ liệu đầu tiên
    repeat lastValue = GetValue() task.wait(1) until lastValue ~= nil
    
    while true do
        task.wait(CHECK_INTERVAL)
        local newVal = GetValue()
        
        if newVal ~= nil then
            if newVal == lastValue then
                ApplyStyle(true) -- Đổi màu cảnh báo
                task.wait(2)
                player:Kick("\n[HỆ THỐNG]\nGingerbread không thay đổi trong 12 phút!")
                return
            else
                lastValue = newVal
                ApplyStyle(false) -- Trở lại bình thường
            end
        end
    end
end)
