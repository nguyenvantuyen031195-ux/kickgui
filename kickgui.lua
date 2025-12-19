task.wait(15)
local CURRENCY_NAME = "gingerbread_2025"
local CHECK_INTERVAL = 12 * 60 
local ClientData = require(game.ReplicatedStorage.ClientModules.Core.ClientData)
local player = game.Players.LocalPlayer
local startTime = os.time()

local lastValue = -1
local isVisible = true

--------------------------------------------------
--------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GingerbreadMonitor_Final_Scale"
screenGui.IgnoreGuiInset = true 
screenGui.DisplayOrder = 999999999 
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiList = Instance.new("UIListLayout")
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Padding = UDim.new(0, 0) -- Loại bỏ khoảng cách để tối ưu không gian cho chữ
uiList.Parent = mainFrame

-- Dòng 1: Thời gian chạy (TO)
local labelTime = Instance.new("TextLabel")
labelTime.Size = UDim2.new(1, 0, 0.2, 0) -- Chiếm 20% chiều cao
labelTime.BackgroundTransparency = 1
labelTime.TextColor3 = Color3.fromRGB(255, 255, 255)
labelTime.Font = Enum.Font.GothamBold
labelTime.TextScaled = true
labelTime.RichText = true
labelTime.Text = "0 : 0"
labelTime.Parent = mainFrame

-- Dòng 2: Tổng số (KHỔNG LỒ)
local labelTotal = Instance.new("TextLabel")
labelTotal.Size = UDim2.new(1, 0, 0.4, 0) -- Chiếm 40% chiều cao
labelTotal.BackgroundTransparency = 1
labelTotal.TextColor3 = Color3.fromRGB(255, 255, 255)
labelTotal.Font = Enum.Font.GothamBold
labelTotal.TextScaled = true
labelTotal.RichText = true
labelTotal.Text = "..."
labelTotal.Parent = mainFrame

-- Dòng 3: Chênh lệch (TO - Bằng dòng 1)
local labelDiff = Instance.new("TextLabel")
labelDiff.Size = UDim2.new(1, 0, 0.2, 0) -- Chiếm 20% chiều cao
labelDiff.BackgroundTransparency = 1
labelDiff.TextColor3 = Color3.fromRGB(255, 255, 255)
labelDiff.Font = Enum.Font.GothamBold
labelDiff.TextScaled = true
labelDiff.RichText = true
labelDiff.Text = "0"
labelDiff.Parent = mainFrame

-- NÚT TẮT/BẬT
local toggleBtn = Instance.new("TextButton")
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

--------------------------------------------------
-- LOGIC
--------------------------------------------------

local function updateColors(isError)
    local bgColor = isError and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 0, 0)
    local txtColor = isError and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    
    mainFrame.BackgroundColor3 = bgColor
    labelTime.TextColor3 = txtColor
    labelTotal.TextColor3 = txtColor
    labelDiff.TextColor3 = txtColor
end

local function updateClock()
    local elapsed = os.time() - startTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    labelTime.Text = "<b>" .. hours .. " : " .. minutes .. "</b>"
end

local function fetchGingerbread()
    local data = ClientData.get_data()[player.Name]
    if data then
        if data.inventory and data.inventory.currencies then
            return data.inventory.currencies[CURRENCY_NAME] or 0
        elseif data[CURRENCY_NAME] then
            return data[CURRENCY_NAME]
        end
    end
    return nil
end

local function performCheck()
    local currentValue = fetchGingerbread()
    if currentValue ~= nil then
        labelTotal.Text = "<b>" .. currentValue .. "</b>"
        
        if lastValue ~= -1 then
            local diff = currentValue - lastValue
            labelDiff.Text = "<b>" .. (diff > 0 and "+" or "") .. diff .. "</b>"
            
            if diff == 0 then
                updateColors(true)
                task.wait(2)
                player:Kick("\n[AUTO-STOP]\nGingerbread không đổi sau 12 phút.")
                return
            else
                updateColors(false)
            end
        else
            labelDiff.Text = "<b>0</b>"
        end
        lastValue = currentValue
    end
end

--------------------------------------------------
-- CHẠY HỆ THỐNG
--------------------------------------------------

task.spawn(function()
    while true do
        updateClock()
        task.wait(1)
    end
end)

performCheck()

task.spawn(function()
    while true do
        task.wait(CHECK_INTERVAL)
        performCheck()
    end
end)
