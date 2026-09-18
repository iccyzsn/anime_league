local Workspace = game:GetService("Workspace")

-- ==========================================
-- SETTINGS
-- ==========================================
local ESP_COLOR = Color3.fromRGB(0, 255, 0) -- Green arrow

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
-- Checks if the item is an actual egg, not a base/spawn, and not in a pen
local function isValidEgg(obj)
    -- Must be a physical object
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return false end
    
    -- Ignore EggBases and EggSpawns
    if string.find(obj.Name, "Base") or string.find(obj.Name, "Spawn") then return false end
    
    -- Must have "Egg" in the name
    if not string.find(obj.Name, "Egg") then return false end
    
    -- IGNORE pens/ranches
    local path = obj:GetFullName()
    if string.find(path, "Plots") or string.find(path, "Ranch") then 
        return false 
    end
    
    return true
end

-- Finds the actual 3D part to attach the ESP to
local function getAdornee(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

-- ==========================================
-- ESP CREATION
-- ==========================================
local function applyEggESP(egg)
    -- Prevent duplicates
    if egg:FindFirstChild("EggESP_Arrow") then return end

    local adornee = getAdornee(egg)
    if not adornee then return end

    -- Create Highlight so it's easy to see
    local highlight = Instance.new("Highlight")
    highlight.Name = "EggESP_Highlight"
    highlight.FillColor = ESP_COLOR
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.Parent = egg

    -- Create the Arrow GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggESP_Arrow"
    billboard.Size = UDim2.new(0, 100, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 4, 0) -- Floats 4 studs above
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Adornee = adornee
    billboard.Parent = egg

    -- The Arrow (Points down)
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(1, 0, 0, 30)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = ESP_COLOR
    arrow.TextScaled = true
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = billboard

    -- The Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(2, 0, 0, 20)
    nameLabel.Position = UDim2.new(-0.5, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = string.gsub(egg.Name, "_", " ")
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
end

-- ==========================================
-- SCANNING LOGIC
-- ==========================================
-- Scan for eggs already spawned
for _, obj in ipairs(Workspace:GetDescendants()) do
    if isValidEgg(obj) then
        applyEggESP(obj)
    end
end

-- Listen for NEW eggs spawning
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.2) -- Give it a second to load properties
    if isValidEgg(obj) then
        applyEggESP(obj)
    end
end)

print("Egg ESP Loaded! Ignoring Bases and Pens.")
