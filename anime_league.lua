local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ==========================================
-- 1. CREATE THE GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ItemInspectorGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 250)
mainFrame.Position = UDim2.new(1, -370, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Item Inspector"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -40)
scrollFrame.Position = UDim2.new(0, 10, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 5)
uiLayout.Parent = scrollFrame

-- Function to add text to the GUI
local function addInfoLine(text, isHeader)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, isHeader and 25 or 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = isHeader and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Font = isHeader and Enum.Font.GothamBold or Enum.Font.Code
    label.TextSize = 13
    label.Text = text
    label.Parent = scrollFrame
    label.LayoutOrder = isHeader and 0 or 1
end

-- ==========================================
-- 2. SCANNING LOGIC
-- ==========================================
local function extractId(str)
    if not str or str == "" then return nil end
    return str:match("%d+")
end

local function inspectItem(item)
    -- Clear old info
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end

    mainFrame.Visible = true
    
    -- Basic Properties
    addInfoLine("PROPERTIES", true)
    addInfoLine("Name: " .. item.Name)
    addInfoLine("Class: " .. item.ClassName)
    addInfoLine("Path: " .. item:GetFullName())

    -- Asset IDs
    addInfoLine("ASSET IDs", true)
    local foundIds = false

    if item:IsA("MeshPart") then
        local meshId = extractId(item.MeshId)
        local texId = extractId(item.TextureID)
        if meshId then addInfoLine("Mesh ID: " .. meshId) foundIds = true end
        if texId then addInfoLine("Texture ID: " .. texId) foundIds = true end
    end

    if item:IsA("Tool") then
        local texId = extractId(item.TextureId)
        if texId then addInfoLine("Tool Texture: " .. texId) foundIds = true end
    end

    -- Look inside the item for meshes/decals
    local specialMesh = item:FindFirstChildWhichIsA("SpecialMesh", true)
    if specialMesh then
        local meshId = extractId(specialMesh.MeshId)
        local texId = extractId(specialMesh.TextureId)
        if meshId then addInfoLine("SpecialMesh ID: " .. meshId) foundIds = true end
        if texId then addInfoLine("SM Texture ID: " .. texId) foundIds = true end
    end

    local decal = item:FindFirstChildWhichIsA("Decal", true)
    if decal then
        local texId = extractId(decal.Texture)
        if texId then addInfoLine("Decal ID: " .. texId) foundIds = true end
    end

    if not foundIds then
        addInfoLine("No asset IDs found on this object.")
    end
end

-- ==========================================
-- 3. CLICK DETECTION
-- ==========================================
-- Create a custom tool to equip
local inspectorTool = Instance.new("Tool")
inspectorTool.Name = "Item Inspector"
inspectorTool.RequiresHandle = false
inspectorTool.Parent = player.Backpack

inspectorTool.Equipped:Connect(function()
    -- Change cursor to a crosshair
    UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceOverride
    UserInputService.MouseIcon = "rbxasset://textures/Crosshair.png"
end)

inspectorTool.Activated:Connect(function()
    local target = mouse.Target
    if target then
        inspectItem(target)
    end
end)

inspectorTool.Unequipped:Connect(function()
    UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
end)

-- Close button logic
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)
