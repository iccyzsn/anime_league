local Workspace = game:GetService("Workspace")

-- ==========================================
-- SETTINGS
-- ==========================================
local EGG_KEYWORD = "Egg" -- Looks for items with "Egg" in the name
local EXCLUDE_PATH = "Plots.Plot" -- Ignores eggs inside pens/plots
local ESP_HEIGHT = 5 -- How high above the egg the arrow appears

-- ==========================================
-- ESP CREATION
-- ==========================================
local function createEggESP(egg)
    -- Prevent duplicate ESP
    if egg:FindFirstChild("EggESP") then return end

    -- Check if the egg is inside a pen/plot. If it is, stop here.
    local eggPath = egg:GetFullName()
    if string.find(eggPath, EXCLUDE_PATH) then
        return
    end

    -- Create the Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggESP"
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, ESP_HEIGHT, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 150 -- Hides ESP if you are too far away
    billboard.Adornee = egg
    billboard.Parent = egg

    -- Create the Arrow (Points down at the egg)
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(1, 0, 0, 25)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green arrow
    arrow.TextScaled = true
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = billboard

    -- Create the Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 25)
    nameLabel.BackgroundTransparency = 1
    -- Removes underscores (Sinister_Egg -> Sinister Egg)
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
-- Scan for eggs already in the game
local function scanExistingEggs()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.find(obj.Name, EGG_KEYWORD) then
            createEggESP(obj)
        end
    end
end

-- Listen for new eggs spawning into the game
Workspace.DescendantAdded:Connect(function(obj)
    -- Wait a tiny second to ensure the item is fully loaded
    task.wait(0.1)
    
    if obj:IsA("BasePart") and string.find(obj.Name, EGG_KEYWORD) then
        -- Double check it's not in a pen
        if not string.find(obj:GetFullName(), EXCLUDE_PATH) then
            createEggESP(obj)
        end
    end
end)

scanExistingEggs()
print("Egg ESP Loaded! Ignoring eggs inside plots/pens.")
