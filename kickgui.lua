--[[
    GINGERBREAD MONITOR 2025 - PERSISTENT & RESPONSIVE
    - CoreGui/gethui: Chống mất GUI 100%.
    - Responsive: Tự động co giãn theo mọi độ phân giải màn hình.
    - Toggle Button: Nút ẩn/hiện hệ thống.
    - Logic 12 phút: Kick nếu số không đổi.
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

-- Gắn vào CoreGui hoặc gethui (Học tập từ script bạn gửi)
if gethui then
    HopGui.Parent = gethui()
elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
    HopGui.Parent = game:GetService("CoreGui").RobloxGui
else
    HopGui.Parent = game:GetService("CoreGui")
end

HopGui.Name = "GingerSystem_V3"
HopGui.IgnoreGuiInset = true
HopGui.DisplayOrder = 999999

-- Khung chính full màn hình
MainFrame.Name = "MainFrame"
MainFrame.Parent = HopGui
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 1

UIList.Parent = MainFrame
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.VerticalAlignment = Enum.VerticalAlignment.Center
UIList.Padding = UDim.new(0.05, 0)

-- Hàm tạo nhãn tự co giãn
local function createLabel(name, heightScale)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Parent = MainFrame
    label.Size = UDim2.new(0.8, 0, heightScale, 0) -- Chiều ngang chiếm 80% màn hình
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.FredokaOne
    label.TextColor3 = Color3.fromRGB(0, 255, 127) -- Màu xanh mặc định
    label.TextScaled = true
    label.RichText = true
    
    -- Ràng buộc tỷ lệ để không bị méo khi đổi độ phân giải
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 5 -- Tỷ lệ rộng:cao
    aspect.Parent = label
    
    return label
end

local LTotal = createLabel("LTotal", 0.3)
local LDiff = createLabel("LDiff", 0.2)
local LTime = createLabel("LTime", 0.1)

-- Nút Bấm Ẩn/Hiện (Nằm trên cùng)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = HopGui
ToggleBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 1, -50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "ẨN / HIỆN"
ToggleBtn.Font = Enum.Font.FredokaOne
ToggleBtn.TextSize = 14
ToggleBtn.ZIndex = 10 -- Luôn nằm trên MainFrame

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
        local elapsed = os.time() - startTime
        LTime.Text = math.floor(elapsed / 3600) .. " : " .. math.floor((elapsed % 3600) / 60)
        
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
        task.wait(1)
    end
end)

-- Vòng lặp kiểm tra Kick (12 phút)
task.spawn(function()
    repeat lastValue = GetValue() task.wait(1) until lastValue ~= nil
    
    while true do
        task.wait(CHECK_INTERVAL)
        local newVal = GetValue()
        
        if newVal ~= nil then
            if newVal == lastValue then
                ApplyStyle(true) -- Chuyển sang Đỏ/Đen
                task.wait(2)
                player:Kick("\n[HỆ THỐNG]\nSố Gingerbread không đổi trong 12 phút!")
                return
            else
                lastValue = newVal
                ApplyStyle(false) -- Giữ Xanh/Đen
            end
        end
    end
end)
