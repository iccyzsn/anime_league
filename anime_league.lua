local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ==========================================
-- EGG DATABASE
-- ==========================================
local trackedEggs = {
    ["Aurora Egg"] = {Price = "300,000,000", Rarity = "Divine", Color = Color3.fromRGB(0, 255, 255)},
    ["Galaxy Egg"] = {Price = "1,500,000,000", Rarity = "Divine", Color = Color3.fromRGB(180, 100, 255)},
    ["Black Hole Egg"] = {Price = "100,000,000,000", Rarity = "Ethereal", Color = Color3.fromRGB(80, 80, 80)},
    ["Cherub Egg"] = {Price = "1,000,000,000,000", Rarity = "Ethereal", Color = Color3.fromRGB(255, 255, 100)}
}

local excludePaths = {"Plots", "Ranch"} -- Ignores eggs inside pens

-- ==========================================
-- 1. CREATE THE GUI PANEL
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggTrackerGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 210)
mainFrame.Position = UDim2.new(0, 15, 0.5, -105)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(10, 20, 15)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🥚 Egg Tracker"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 5)
uiLayout.Parent = scrollFrame

-- Store UI references for each egg
local eggUI = {}

-- Create a row for each egg in the panel
for eggName, data in pairs(trackedEggs) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 50)
    row.BackgroundColor3 = Color3.fromRGB(30, 40, 35)
    row.Parent = scrollFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggName
    nameLabel.TextColor3 = data.Color
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = row
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.6, 0, 0, 20)
    infoLabel.Position = UDim2.new(0, 5, 0, 25)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = data.Price .. " | " .. data.Rarity
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Font = Enum.Font.Code
    infoLabel.TextSize = 11
    infoLabel.Parent = row
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.4, -5, 0, 20)
    statusLabel.Position = UDim2.new(0.6, 0, 0, 25)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Unavailable"
    statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 11
    statusLabel.Parent = row
    
    eggUI[eggName] = {Row = row, Status = statusLabel}
end

-- ==========================================
-- 2. ESP & SCANNING LOGIC
-- ==========================================
local function getAdornee(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function applyESP(egg, eggName)
    if egg:FindFirstChild("TrackerESP") then return end
    local adornee = getAdornee(egg)
    if not adornee then return end

    local espColor = trackedEggs[eggName].Color

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "TrackerESP"
    highlight.FillColor = espColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.3
    highlight.Parent = egg

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TrackerESP"
    billboard.Size = UDim2.new(0, 150, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    billboard.Parent = egg

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(1, 0, 0, 30)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = espColor
    arrow.TextScaled = true
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 30)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
end

-- Check if object is one of our target eggs and not in a pen
local function checkEgg(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
    
    -- Remove underscores to match our list (e.g., Aurora_Egg -> Aurora Egg)
    local cleanName = string.gsub(obj.Name, "_", " ")
    
    if not trackedEggs[cleanName] then return nil end
    
    local path = obj:GetFullName()
    for _, exclude in ipairs(excludePaths) do
        if string.find(path, exclude) then return nil end
    end
    
    return cleanName
end

-- ==========================================
-- 3. BACKGROUND TRACKER LOOP
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        local foundEggs = {}
        
        -- Scan workspace for eggs
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local eggName = checkEgg(obj)
            if eggName then
                foundEggs[eggName] = true
                applyESP(obj, eggName)
            end
        end
        
        -- Update GUI Status
        for eggName, ui in pairs(eggUI) do
            if foundEggs[eggName] then
                ui.Status.Text = "AVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(0, 255, 0)
                ui.Row.BackgroundColor3 = Color3.fromRGB(40, 80, 50) -- Turn row green
            else
                ui.Status.Text = "Unavailable"
                ui.Status.TextColor3 = Color3.fromRGB(255, 50, 50)
                ui.Row.BackgroundColor3 = Color3.fromRGB(30, 40, 35) -- Default color
            end
        end
    end
end)

print("Egg Tracker Panel Loaded!")
