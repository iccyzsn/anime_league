local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ==========================================
-- EGG DATABASE
-- ==========================================
local trackedEggs = {
    ["152975769"] = {DisplayName = "Flaming Egg", Price = "Rare", Rarity = "Fire", Color = Color3.fromRGB(255, 120, 30)},
    ["70549049033717"] = {DisplayName = "Sinister Egg", Price = "Secret", Rarity = "Dark", Color = Color3.fromRGB(220, 40, 60)},
    ["131792796847596"] = {DisplayName = "Galaxy Egg", Price = "1.5B", Rarity = "Divine", Color = Color3.fromRGB(180, 100, 255)},
    ["95155753812330"] = {DisplayName = "Soul Egg", Price = "Ethereal", Rarity = "Ghost", Color = Color3.fromRGB(120, 220, 255)},
    ["109698896973127"] = {DisplayName = "Skull Egg", Price = "Dark", Rarity = "Bone", Color = Color3.fromRGB(180, 180, 180)}
}

local excludePaths = {"Plots", "Ranch"} 
local activeEggs = {} 

-- ==========================================
-- 1. CREATE MODERN AESTHETIC GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggTrackerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local success = pcall(function()
    if gethui then
        screenGui.Parent = gethui()
    else
        if game:GetService("CoreGui"):FindFirstChild("EggTrackerGui") then
            game:GetService("CoreGui").EggTrackerGui:Destroy()
        end
        screenGui.Parent = game:GetService("CoreGui")
    end
end)
if not success then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Main Window Container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 310)
mainFrame.Position = UDim2.new(0, 20, 0.5, -155)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(255, 255, 255)
frameStroke.Transparency = 0.88
frameStroke.Thickness = 1.5
frameStroke.Parent = mainFrame

-- Title Bar (Draggable Header)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -20, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "EGG RADAR"
titleText.TextColor3 = Color3.fromRGB(240, 240, 245)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local subtitleText = Instance.new("TextLabel")
subtitleText.Size = UDim2.new(1, -20, 0, 12)
subtitleText.Position = UDim2.new(0, 15, 0, 24)
subtitleText.BackgroundTransparency = 1
subtitleText.Text = "Mesh ID Tracker & Zipline ESP"
subtitleText.TextColor3 = Color3.fromRGB(130, 135, 150)
subtitleText.Font = Enum.Font.Gotham
subtitleText.TextSize = 10
subtitleText.TextXAlignment = Enum.TextXAlignment.Left
subtitleText.Parent = titleBar

local headerDivider = Instance.new("Frame")
headerDivider.Size = UDim2.new(1, -20, 0, 1)
headerDivider.Position = UDim2.new(0, 10, 1, -1)
headerDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
headerDivider.BackgroundTransparency = 0.92
headerDivider.BorderSizePixel = 0
headerDivider.Parent = titleBar

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Scroll Area
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -16, 1, -52)
scrollFrame.Position = UDim2.new(0, 8, 0, 46)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 105, 120)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 6)
uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiLayout.Parent = scrollFrame

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 2)
uiPadding.PaddingBottom = UDim.new(0, 6)
uiPadding.PaddingLeft = UDim.new(0, 2)
uiPadding.PaddingRight = UDim.new(0, 4)
uiPadding.Parent = scrollFrame

-- Egg Item Cards
local eggUI = {}

for meshId, data in pairs(trackedEggs) do
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.Parent = scrollFrame
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(255, 255, 255)
    cardStroke.Transparency = 0.94
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    -- Left Accent Bar (Matches Egg Theme Color)
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -12)
    accent.Position = UDim2.new(0, 6, 0, 6)
    accent.BackgroundColor3 = data.Color
    accent.BorderSizePixel = 0
    accent.Parent = card
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent

    -- Egg Title
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, -15, 0, 18)
    nameLabel.Position = UDim2.new(0, 16, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Parent = card

    -- Sub-details (Price / Rarity)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.6, -15, 0, 14)
    infoLabel.Position = UDim2.new(0, 16, 0, 24)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = data.Rarity .. " • " .. data.Price
    infoLabel.TextColor3 = Color3.fromRGB(130, 135, 150)
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.Parent = card

    -- Dynamic Status Dot
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(1, -85, 0.5, -3)
    statusDot.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    -- Status Text Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 72, 0, 20)
    statusLabel.Position = UDim2.new(1, -75, 0.5, -10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "UNAVAILABLE"
    statusLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 9
    statusLabel.Parent = card

    eggUI[data.DisplayName] = {Card = card, Status = statusLabel, Dot = statusDot, Stroke = cardStroke}
end

-- ==========================================
-- 2. ESP & ZIPLINE LOGIC
-- ==========================================
local function extractId(str)
    if not str or str == "" then return nil end
    return string.match(str, "%d+")
end

local function getAdornee(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function setupZipline(egg, displayName)
    if egg:GetAttribute("ZiplineActive") then return end
    local adornee = getAdornee(egg)
    if not adornee then return end

    local espColor = Color3.new(1, 1, 1)
    for _, data in pairs(trackedEggs) do
        if data.DisplayName == displayName then
            espColor = data.Color
            break
        end
    end

    egg:SetAttribute("ZiplineActive", true)

    local highlight = Instance.new("Highlight")
    highlight.Name = "TrackerHighlight"
    highlight.FillColor = espColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.35
    highlight.Parent = egg

    local eggAtt = Instance.new("Attachment")
    eggAtt.Name = "EggZiplineAtt"
    eggAtt.Parent = adornee

    local beam = Instance.new("Beam")
    beam.Name = "ZiplineBeam"
    beam.Attachment1 = eggAtt
    beam.Color = ColorSequence.new(espColor)
    beam.Width0 = 0.12
    beam.Width1 = 0.12
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.25)
    beam.Parent = adornee

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TrackerTag"
    billboard.Size = UDim2.new(0, 140, 0, 26)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    billboard.Parent = egg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.TextColor3 = espColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    activeEggs[egg] = beam
end

local function checkEggByMesh(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
    
    local path = obj:GetFullName()
    for _, exclude in ipairs(excludePaths) do
        if string.find(path, exclude) then return nil end
    end
    
    if obj:IsA("MeshPart") then
        local meshId = extractId(obj.MeshId)
        if meshId and trackedEggs[meshId] then
            return trackedEggs[meshId].DisplayName
        end
    end
    
    local specialMesh = obj:FindFirstChildWhichIsA("SpecialMesh", true)
    if specialMesh then
        local meshId = extractId(specialMesh.MeshId)
        if meshId and trackedEggs[meshId] then
            return trackedEggs[meshId].DisplayName
        end
    end
    
    return nil
end

-- ==========================================
-- 3. BACKGROUND TRACKER & RENDER LOOPS
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        local foundEggs = {}
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local displayName = checkEggByMesh(obj)
            if displayName then
                foundEggs[displayName] = true
                setupZipline(obj, displayName)
            end
        end
        
        for displayName, ui in pairs(eggUI) do
            if foundEggs[displayName] then
                ui.Status.Text = "ACTIVE"
                ui.Status.TextColor3 = Color3.fromRGB(60, 230, 120)
                ui.Dot.BackgroundColor3 = Color3.fromRGB(60, 230, 120)
                ui.Card.BackgroundTransparency = 0.15
                ui.Stroke.Transparency = 0.75
                ui.Stroke.Color = Color3.fromRGB(60, 230, 120)
            else
                ui.Status.Text = "UNAVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(140, 145, 160)
                ui.Dot.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
                ui.Card.BackgroundTransparency = 0.35
                ui.Stroke.Transparency = 0.94
                ui.Stroke.Color = Color3.fromRGB(255, 255, 255)
            end
        end

        for egg, _ in pairs(activeEggs) do
            if not egg or not egg.Parent then
                activeEggs[egg] = nil
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        if not hrp:FindFirstChild("PlayerZiplineAtt") then
            local att = Instance.new("Attachment")
            att.Name = "PlayerZiplineAtt"
            att.Parent = hrp
        end
        
        local playerAtt = hrp:FindFirstChild("PlayerZiplineAtt")
        
        for egg, beam in pairs(activeEggs) do
            if egg and egg.Parent and beam and beam.Parent then
                beam.Attachment0 = playerAtt
            else
                activeEggs[egg] = nil
            end
        end
    end
end)

-- Notification
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Radar Ready",
        Text = "Egg Radar UI initialized successfully.",
        Duration = 4
    })
end)
