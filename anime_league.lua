local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ==========================================
-- EGG DATABASE (PUT YOUR MESH IDs HERE)
-- ==========================================
local trackedEggs = {
    ["PUT_AURORA_ID_HERE"] = {DisplayName = "Aurora Egg", Price = "300,000,000", Rarity = "Divine", Color = Color3.fromRGB(0, 255, 255)},
    ["PUT_GALAXY_ID_HERE"] = {DisplayName = "Galaxy Egg", Price = "1,500,000,000", Rarity = "Divine", Color = Color3.fromRGB(180, 100, 255)},
    ["PUT_BLACKHOLE_ID_HERE"] = {DisplayName = "Black Hole Egg", Price = "100,000,000,000", Rarity = "Ethereal", Color = Color3.fromRGB(80, 80, 80)},
    ["PUT_CHERUB_ID_HERE"] = {DisplayName = "Cherub Egg", Price = "1,000,000,000,000", Rarity = "Ethereal", Color = Color3.fromRGB(255, 255, 100)}
}

local excludePaths = {"Plots", "Ranch"} -- Ignores eggs inside pens
local activeEggs = {} 

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
title.Text = "🥚 Egg Tracker (Mesh ID)"
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

local eggUI = {}

for meshId, data in pairs(trackedEggs) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 50)
    row.BackgroundColor3 = Color3.fromRGB(30, 40, 35)
    row.Parent = scrollFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.DisplayName
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
    
    eggUI[data.DisplayName] = {Row = row, Status = statusLabel}
end

-- ==========================================
-- 2. ESP & ZIPLINE LOGIC
-- ==========================================
local function extractId(str)
    if not str or str == "" then return nil end
    return str:match("%d+")
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

    local espColor = trackedEggs[displayName] and trackedEggs[displayName].Color or Color3.new(1,1,1)
    -- Fix: If tracked by ID, we get color from the data
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
    highlight.FillTransparency = 0.3
    highlight.Parent = egg

    local eggAtt = Instance.new("Attachment")
    eggAtt.Name = "EggZiplineAtt"
    eggAtt.Parent = adornee

    local beam = Instance.new("Beam")
    beam.Name = "ZiplineBeam"
    beam.Attachment1 = eggAtt
    beam.Color = ColorSequence.new(espColor)
    beam.Width0 = 0.15
    beam.Width1 = 0.15
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.2)
    beam.Parent = adornee

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TrackerTag"
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    billboard.Parent = egg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    activeEggs[egg] = beam
end

-- New function to check Mesh IDs
local function checkEggByMesh(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
    
    local path = obj:GetFullName()
    for _, exclude in ipairs(excludePaths) do
        if string.find(path, exclude) then return nil end
    end
    
    -- Get the MeshPart ID
    if obj:IsA("MeshPart") then
        local meshId = extractId(obj.MeshId)
        if meshId and trackedEggs[meshId] then
            return trackedEggs[meshId].DisplayName
        end
    end
    
    -- Get the SpecialMesh ID if it's inside the object
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
-- 3. BACKGROUND TRACKER & ZIPLINE RENDERER
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
                ui.Status.Text = "AVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(0, 255, 0)
                ui.Row.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
            else
                ui.Status.Text = "Unavailable"
                ui.Status.TextColor3 = Color3.fromRGB(255, 50, 50)
                ui.Row.BackgroundColor3 = Color3.fromRGB(30, 40, 35)
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

print("Mesh ID Egg Zipline Tracker Loaded!")
