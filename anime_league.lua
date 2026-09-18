--=============================================================================
--  █████╗ ███████╗███████╗███████╗████████╗    ██╗██████╗
--  ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝    ██║██╔══██╗
--  ███████║███████╗███████╗███████╗   ██║       ██║██║  ██║
--  ██╔══██║╚════██║╚════██║╚════██║   ██║       ██║██║  ██║
--  ██║  ██║███████║███████║███████║   ██║       ██║██████╔╝
--  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝       ╚═╝╚═════╝
--   I D   T R A C K E R   •   v2.0
--
--   Monitors Workspace for newly spawned assets, extracts their
--   asset IDs and displays them in a clean, filterable UI.
--=============================================================================

local Players          = game:GetService("Players")
local StarterGui       = game:GetService("StarterGui")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer

--=============================================================================
--  CONFIG
--=============================================================================
local CONFIG = {
	MaxEntries         = 150,                       -- how many rows are kept
	ScanDelay          = 0.08,                      -- wait for properties to load
	HighlightDuration  = 6,                         -- seconds
	HighlightColor     = Color3.fromRGB(0, 255, 150),
	Notify             = true,                      -- StarterGui notifications
	Highlight          = true,                      -- auto-highlight new assets
	IgnoreOwnCharacter = true,                      -- ignore your own avatar
	PrintToConsole     = true,                      -- print to F9 console
}

--=============================================================================
--  THEME
--=============================================================================
local THEME = {
	Bg       = Color3.fromRGB(15, 17, 23),
	Panel    = Color3.fromRGB(24, 27, 36),
	PanelAlt = Color3.fromRGB(32, 36, 47),
	Hover    = Color3.fromRGB(42, 47, 62),
	Stroke   = Color3.fromRGB(48, 54, 70),
	Text     = Color3.fromRGB(233, 237, 245),
	SubText  = Color3.fromRGB(138, 147, 168),
	Accent   = Color3.fromRGB(88, 166, 255),
	Good     = Color3.fromRGB(0, 220, 160),
	Danger   = Color3.fromRGB(255, 92, 92),
	Warn     = Color3.fromRGB(255, 190, 80),
}

local FONT       = Enum.Font.Gotham
local FONT_BOLD  = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack
local FONT_MONO  = Enum.Font.Code

--=============================================================================
--  SMALL UI HELPERS
--=============================================================================
local function create(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(radius, parent)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(color, thickness, transparency, parent)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function addHover(btn, baseColor, hoverColor)
	btn.BackgroundColor3 = baseColor
	btn:SetAttribute("BaseColor", baseColor)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = btn:GetAttribute("BaseColor") }):Play()
	end)
end

local function setButtonColor(btn, color)
	btn:SetAttribute("BaseColor", color)
	TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = color }):Play()
end

--=============================================================================
--  GUI PARENT RESOLVER  (works in games & executors)
--=============================================================================
local function resolveGuiParent()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if ok and coreGui then
		local test = Instance.new("Folder")
		local ok2 = pcall(function() test.Parent = coreGui end)
		test:Destroy()
		if ok2 then return coreGui end
	end
	return LP:WaitForChild("PlayerGui")
end

--=============================================================================
--  BUILD UI
--=============================================================================
local screen = create("ScreenGui", {
	Name = "AssetTrackerUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9999,
}, resolveGuiParent())

local WINDOW_W, WINDOW_H = 470, 450

local main = create("Frame", {
	Name = "Window",
	Position = UDim2.fromOffset(24, 80),
	Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
	BackgroundColor3 = THEME.Bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, screen)
corner(12, main)
stroke(THEME.Stroke, 1, 0, main)

-- ── Header ──────────────────────────────────────────────────────────────────
local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
}, main)

create("Frame", { -- accent underline
	Position = UDim2.new(0, 0, 1, -1),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = THEME.Accent,
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
}, header)

local logoBox = create("Frame", {
	Position = UDim2.fromOffset(12, 10),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = THEME.Accent,
	BorderSizePixel = 0,
}, header)
corner(8, logoBox)
create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = FONT,
	Text = "🔍",
	TextSize = 15,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, logoBox)

create("TextLabel", {
	Position = UDim2.fromOffset(48, 9),
	Size = UDim2.new(1, -160, 0, 15),
	BackgroundTransparency = 1,
	Font = FONT_BLACK,
	Text = "ASSET ID TRACKER",
	TextSize = 14,
	TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

create("TextLabel", {
	Position = UDim2.fromOffset(48, 25),
	Size = UDim2.new(1, -160, 0, 14),
	BackgroundTransparency = 1,
	Font = FONT,
	Text = "Live Workspace monitor  •  v2.0",
	TextSize = 11,
	TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

-- header buttons
local function headerButton(text, xOffset, color)
	local b = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0, 23),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT_BOLD,
		Text = text,
		TextSize = 14,
		TextColor3 = color or THEME.SubText,
	}, header)
	corner(8, b)
	addHover(b, THEME.PanelAlt, THEME.Hover)
	return b
end

local minimizeBtn = headerButton("—", -12, THEME.Text)
local closeBtn    = headerButton("✕", -46, THEME.Danger)

-- ── Toolbar ─────────────────────────────────────────────────────────────────
local toolbar = create("Frame", {
	Position = UDim2.new(0, 0, 0, 46),
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
}, main)

local searchBox = create("TextBox", {
	Position = UDim2.fromOffset(10, 9),
	Size = UDim2.new(1, -190, 0, 26),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
	Font = FONT,
	Text = "",
	PlaceholderText = "🔎  Search name, ID, class, path...",
	PlaceholderColor3 = THEME.SubText,
	TextColor3 = THEME.Text,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
}, toolbar)
corner(7, searchBox)
local searchStroke = stroke(THEME.Stroke, 1, 0.3, searchBox)
create("UIPadding", {
	PaddingLeft = UDim.new(0, 9),
	PaddingRight = UDim.new(0, 9),
}, searchBox)

searchBox.Focused:Connect(function()
	TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = THEME.Accent, Transparency = 0 }):Play()
end)
searchBox.FocusLost:Connect(function()
	TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = THEME.Stroke, Transparency = 0.3 }):Play()
end)

-- toolbar toggle buttons
local function toolButton(text, xOffset, baseColor, textColor)
	local b = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0, 22),
		Size = UDim2.fromOffset(32, 26),
		BackgroundColor3 = baseColor,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT,
		Text = text,
		TextSize = 14,
		TextColor3 = textColor or THEME.Text,
	}, toolbar)
	corner(7, b)
	b:SetAttribute("BaseColor", baseColor)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), {
			BackgroundColor3 = (b:GetAttribute("BaseColor")):Lerp(Color3.new(1, 1, 1), 0.1),
		}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = b:GetAttribute("BaseColor") }):Play()
	end)
	return b
end

local clearBtn     = toolButton("🗑", -10,  THEME.Panel)
local pauseBtn     = toolButton("⏸", -48,  THEME.Panel)
local notifyBtn    = toolButton("🔔", -86,  THEME.Panel)
local highlightBtn = toolButton("🎯", -124, THEME.Panel)

-- ── Stats bar ───────────────────────────────────────────────────────────────
local statsBar = create("Frame", {
	Position = UDim2.new(0, 0, 0, 88),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
}, main)

local statsLabel = create("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(1, -28, 1, 0),
	BackgroundTransparency = 1,
	Font = FONT,
	Text = "Found: 0   •   Shown: 0",
	TextSize = 11,
	TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statsBar)

-- ── Log list ────────────────────────────────────────────────────────────────
local logFrame = create("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 110),
	Size = UDim2.new(1, -16, 1, -142),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.Stroke,
	ScrollBarImageTransparency = 0.3,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, main)
create("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, logFrame)
create("UIPadding", {
	PaddingTop = UDim.new(0, 2),
	PaddingBottom = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 4),
}, logFrame)

-- ── Footer ──────────────────────────────────────────────────────────────────
local footer = create("Frame", {
	Position = UDim2.new(0, 0, 1, -30),
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
}, main)
create("Frame", {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = THEME.Stroke,
	BorderSizePixel = 0,
}, footer)

local statusLabel = create("TextLabel", {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = FONT_BOLD,
	Text = "● TRACKING",
	TextSize = 11,
	TextColor3 = THEME.Good,
	TextXAlignment = Enum.TextXAlignment.Left,
}, footer)

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 0),
	Size = UDim2.new(0.6, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = FONT,
	Text = "Click = highlight  •  ID = copy",
	TextSize = 10,
	TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Right,
}, footer)

--=============================================================================
--  DRAGGING
--=============================================================================
local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(main, header)

--=============================================================================
--  CORE LOGIC  •  ASSET EXTRACTION
--=============================================================================
local function extractId(assetString)
	if type(assetString) ~= "string" or assetString == "" then return nil end
	-- handles rbxassetid://123, http://...?id=123, rbxthumb://...&id=123
	local id = assetString:match("[%?&]id=(%d+)") or assetString:match("(%d+)")
	if id and #id >= 3 then return id end
	return nil
end

-- Which properties to read for each class
local ASSET_PROPS = {
	MeshPart          = { "MeshId", "TextureID" },
	SpecialMesh       = { "MeshId", "TextureId" },
	CylinderMesh      = { "MeshId", "TextureId" },
	BlockMesh         = { "MeshId" },
	Decal             = { "Texture" },
	Texture           = { "Texture" },
	SurfaceAppearance = { "ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap" },
	ParticleEmitter   = { "Texture" },
	Sound             = { "SoundId" },
	Animation         = { "AnimationId" },
	Tool              = { "TextureId" },
	ImageLabel        = { "Image" },
	ImageButton       = { "Image" },
	Shirt             = { "ShirtTemplate" },
	Pants             = { "PantsTemplate" },
	ShirtGraphic      = { "Graphic" },
	Sky               = { "SkyboxUp", "SkyboxDn", "SkyboxLf", "SkyboxRt", "SkyboxFt", "SkyboxBk" },
	Beam              = { "Texture" },
	Trail             = { "Texture" },
	Explosion         = { "Texture" },
	Fire              = { "Texture" },
	Sparkles          = { "Texture" },
	CharacterMesh     = { "MeshId", "BaseTextureId", "OverlayTextureId" },
	Accessory         = {},
	SurfaceGui        = {},
	BillboardGui      = {},
}

-- Icon + friendly label per property
local PROP_INFO = {
	MeshId           = { "Mesh", "🧊" },
	TextureId        = { "Texture", "🖼️" },
	TextureID        = { "Texture", "🖼️" },
	Texture          = { "Texture", "🖼️" },
	SoundId          = { "Sound", "🔊" },
	AnimationId      = { "Animation", "🎞️" },
	Image            = { "Image", "🖼️" },
	ShirtTemplate    = { "Shirt", "👕" },
	PantsTemplate    = { "Pants", "👖" },
	Graphic          = { "Graphic", "🎨" },
	ColorMap         = { "ColorMap", "🎨" },
	NormalMap        = { "NormalMap", "🗺️" },
	RoughnessMap     = { "Roughness", "🗺️" },
	MetalnessMap     = { "Metalness", "🗺️" },
	SkyboxUp         = { "Skybox", "🌌" },
	SkyboxDn         = { "Skybox", "🌌" },
	SkyboxLf         = { "Skybox", "🌌" },
	SkyboxRt         = { "Skybox", "🌌" },
	SkyboxFt         = { "Skybox", "🌌" },
	SkyboxBk         = { "Skybox", "🌌" },
	BaseTextureId    = { "Texture", "🖼️" },
	OverlayTextureId = { "Texture", "🖼️" },
}

-- Class overrides (ParticleEmitter.Texture is a particle, not a texture, etc.)
local CLASS_INFO = {
	ParticleEmitter = { "Particle", "✨" },
	Beam            = { "Beam", "💫" },
	Trail           = { "Trail", "💫" },
	Fire            = { "Fire", "🔥" },
	Explosion       = { "Explosion", "💥" },
	Decal           = { "Decal", "🏷️" },
	Sky             = { "Skybox", "🌌" },
	Sound           = { "Sound", "🔊" },
	Animation       = { "Animation", "🎞️" },
}

local TYPE_COLORS = {
	Mesh      = Color3.fromRGB(110, 190, 255),
	Texture   = Color3.fromRGB(255, 170, 90),
	Decal     = Color3.fromRGB(255, 140, 200),
	Sound     = Color3.fromRGB(180, 140, 255),
	Animation = Color3.fromRGB(120, 255, 190),
	Particle  = Color3.fromRGB(255, 230, 120),
	Image     = Color3.fromRGB(255, 170, 90),
	Shirt     = Color3.fromRGB(140, 220, 140),
	Pants     = Color3.fromRGB(140, 180, 240),
	Graphic   = Color3.fromRGB(255, 200, 120),
	Skybox    = Color3.fromRGB(150, 180, 255),
	Beam      = Color3.fromRGB(150, 220, 255),
	Trail     = Color3.fromRGB(150, 220, 255),
	Fire      = Color3.fromRGB(255, 130, 80),
	Explosion = Color3.fromRGB(255, 110, 90),
	ColorMap  = Color3.fromRGB(255, 160, 120),
	NormalMap = Color3.fromRGB(160, 200, 255),
	Roughness = Color3.fromRGB(190, 190, 190),
	Metalness = Color3.fromRGB(200, 200, 220),
}

local function describe(className, prop)
	local info = CLASS_INFO[className] or PROP_INFO[prop]
	if info then
		return info[1], info[2], TYPE_COLORS[info[1]] or THEME.Accent
	end
	return prop, "📦", THEME.Accent
end

--=============================================================================
--  ACTIONS
--=============================================================================
local function highlightInstance(inst, duration)
	if not inst or not inst.Parent then return end
	if inst:FindFirstChild("AssetTrackerHighlight") then
		inst.AssetTrackerHighlight:Destroy()
	end
	local h = create("Highlight", {
		Name = "AssetTrackerHighlight",
		FillColor = CONFIG.HighlightColor,
		FillTransparency = 0.65,
		OutlineColor = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 0.15,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	}, inst)
	Debris:AddItem(h, duration or CONFIG.HighlightDuration)
end

local function notify(title, text, duration)
	if not CONFIG.Notify then return end
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 4,
		})
	end)
end

local function copyText(text)
	text = tostring(text)
	if typeof(setclipboard) == "function" then
		if pcall(setclipboard, text) then return true end
	end
	-- fallback for vanilla Roblox clients
	local tb = create("TextBox", {
		Position = UDim2.fromOffset(-200, -200),
		Size = UDim2.fromOffset(2, 2),
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Text = text,
		TextSize = 1,
		ClearTextOnFocus = false,
	}, screen)
	tb:CaptureFocus()
	tb.SelectionStart = 1
	tb.CursorPosition = #tb.Text + 1
	task.delay(0.6, function()
		pcall(function() tb:ReleaseFocus() end)
		tb:Destroy()
	end)
	return true
end

--=============================================================================
--  LOG ENTRY MANAGEMENT
--=============================================================================
local allEntries  = {}
local layoutOrder = 0
local totalFound  = 0

local function updateStats()
	local visible = 0
	for _, e in ipairs(allEntries) do
		if e.frame.Visible then visible += 1 end
	end
	statsLabel.Text = string.format("Found: %d   •   Shown: %d", totalFound, visible)
end

local function addEntry(data)
	totalFound += 1

	local row = create("TextButton", {
		Name = "Entry",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = layoutOrder,
	}, logFrame)
	layoutOrder += 1
	corner(8, row)
	local rowStroke = stroke(THEME.Stroke, 1, 0.45, row)

	-- icon badge
	local iconWrap = create("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = data.color,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	}, row)
	corner(8, iconWrap)
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = data.icon,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	}, iconWrap)

	-- name
	create("TextLabel", {
		Position = UDim2.fromOffset(46, 5),
		Size = UDim2.new(1, -160, 0, 15),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 13,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = data.name,
	}, row)

	-- type line
	create("TextLabel", {
		Position = UDim2.fromOffset(46, 21),
		Size = UDim2.new(1, -160, 0, 13),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 11,
		TextColor3 = data.color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = string.format("%s  •  %s.%s", data.label, data.className, data.prop),
	}, row)

	-- path line
	create("TextLabel", {
		Position = UDim2.fromOffset(46, 35),
		Size = UDim2.new(1, -160, 0, 13),
		BackgroundTransparency = 1,
		Font = FONT_MONO,
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = data.path,
	}, row)

	-- ID / copy button
	local idBtn = create("TextButton", {
		Name = "CopyId",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(98, 22),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT_MONO,
		TextSize = 11,
		TextColor3 = data.color,
		Text = data.id,
		ZIndex = 2,
	}, row)
	corner(6, idBtn)
	addHover(idBtn, THEME.PanelAlt, THEME.Hover)

	-- timestamp
	create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 34),
		Size = UDim2.fromOffset(98, 12),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = data.time,
	}, row)

	-- interactions
	row.Activated:Connect(function()
		highlightInstance(data.instance, 3)
	end)

	row.MouseEnter:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = THEME.PanelAlt }):Play()
		TweenService:Create(rowStroke, TweenInfo.new(0.12), { Color = data.color, Transparency = 0.5 }):Play()
	end)
	row.MouseLeave:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Panel }):Play()
		TweenService:Create(rowStroke, TweenInfo.new(0.12), { Color = THEME.Stroke, Transparency = 0.45 }):Play()
	end)

	idBtn.Activated:Connect(function()
		copyText(data.id)
		idBtn.Text = "✓ Copied"
		task.delay(0.9, function()
			if idBtn and idBtn.Parent then idBtn.Text = data.id end
		end)
	end)

	local record = {
		frame = row,
		data = data,
		search = string.lower(table.concat({
			data.name, data.id, data.className, data.prop, data.path, data.label,
		}, " ")),
	}
	table.insert(allEntries, record)

	-- trim old entries
	while #allEntries > CONFIG.MaxEntries do
		local old = table.remove(allEntries, 1)
		if old.frame then old.frame:Destroy() end
	end

	updateStats()
end

--=============================================================================
--  FILTERING
--=============================================================================
local filterText = ""

local function applyFilter()
	for _, e in ipairs(allEntries) do
		local match = filterText == ""
			or e.search:find(filterText, 1, true) ~= nil
		e.frame.Visible = match
	end
	updateStats()
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	filterText = string.lower(searchBox.Text)
	applyFilter()
end)

--=============================================================================
--  SCANNER
--=============================================================================
local scanned = setmetatable({}, { __mode = "k" })
local paused = false

local function collectFrom(inst, out)
	if scanned[inst] then return end
	scanned[inst] = true

	local props = ASSET_PROPS[inst.ClassName]
	if not props then return end

	for _, prop in ipairs(props) do
		local ok, value = pcall(function() return inst[prop] end)
		if ok and type(value) == "string" and value ~= "" then
			local id = extractId(value)
			if id then
				table.insert(out, { instance = inst, prop = prop, id = id })
			end
		end
	end
end

local function scanTree(root)
	local out = {}
	collectFrom(root, out)
	local ok, descendants = pcall(function() return root:GetDescendants() end)
	if ok then
		for _, d in ipairs(descendants) do
			collectFrom(d, out)
		end
	end
	return out
end

local function handleFound(info)
	local inst = info.instance
	if not inst or not inst.Parent then return end

	local label, icon, color = describe(inst.ClassName, info.prop)

	local data = {
		id        = info.id,
		prop      = info.prop,
		className = inst.ClassName,
		name      = inst.Name,
		path      = inst:GetFullName(),
		label     = label,
		icon      = icon,
		color     = color,
		instance  = inst,
		time      = os.date("%H:%M:%S"),
	}

	if CONFIG.PrintToConsole then
		print(string.format("[AssetTracker] %s | %s.%s = %s | %s",
			inst.Name, inst.ClassName, info.prop, info.id, data.path))
	end

	addEntry(data)

	if CONFIG.Notify then
		notify(icon .. "  " .. label .. " Found", string.format("%s\nID: %s", inst.Name, info.id))
	end

	if CONFIG.Highlight then
		highlightInstance(inst, CONFIG.HighlightDuration)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if paused then return end
	if scanned[descendant] then return end

	if CONFIG.IgnoreOwnCharacter then
		local char = LP.Character
		if char and descendant:IsDescendantOf(char) then return end
	end

	task.delay(CONFIG.ScanDelay, function()
		if paused then return end
		if not descendant or not descendant.Parent then return end
		local found = scanTree(descendant)
		for _, info in ipairs(found) do
			handleFound(info)
		end
	end)
end)

--=============================================================================
--  UI INTERACTIONS
--=============================================================================
-- pause / resume
pauseBtn.Activated:Connect(function()
	paused = not paused
	if paused then
		pauseBtn.Text = "▶"
		setButtonColor(pauseBtn, THEME.Warn)
		pauseBtn.TextColor3 = Color3.fromRGB(30, 25, 10)
		statusLabel.Text = "❚❚ PAUSED"
		statusLabel.TextColor3 = THEME.Warn
	else
		pauseBtn.Text = "⏸"
		setButtonColor(pauseBtn, THEME.Panel)
		pauseBtn.TextColor3 = THEME.Text
		statusLabel.Text = "● TRACKING"
		statusLabel.TextColor3 = THEME.Good
	end
end)

-- clear log
clearBtn.Activated:Connect(function()
	for _, e in ipairs(allEntries) do
		if e.frame then e.frame:Destroy() end
	end
	allEntries = {}
	totalFound = 0
	layoutOrder = 0
	updateStats()
end)

-- notify toggle
local notifyOn = CONFIG.Notify
notifyBtn.Activated:Connect(function()
	notifyOn = not notifyOn
	CONFIG.Notify = notifyOn
	if notifyOn then
		notifyBtn.Text = "🔔"
		setButtonColor(notifyBtn, THEME.Panel)
		notifyBtn.TextColor3 = THEME.Text
	else
		notifyBtn.Text = "🔕"
		setButtonColor(notifyBtn, THEME.PanelAlt)
		notifyBtn.TextColor3 = THEME.SubText
	end
end)

-- highlight toggle
local highlightOn = CONFIG.Highlight
highlightBtn.Activated:Connect(function()
	highlightOn = not highlightOn
	CONFIG.Highlight = highlightOn
	if highlightOn then
		highlightBtn.Text = "🎯"
		setButtonColor(highlightBtn, THEME.Panel)
		highlightBtn.TextColor3 = THEME.Text
	else
		highlightBtn.Text = "🚫"
		setButtonColor(highlightBtn, THEME.PanelAlt)
		highlightBtn.TextColor3 = THEME.SubText
	end
end)

-- minimize
local miniBtn = create("TextButton", {
	Name = "Reopen",
	Position = main.Position,
	Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Font = FONT,
	Text = "🔍",
	TextSize = 20,
	TextColor3 = THEME.Text,
	Visible = false,
	ZIndex = 10,
}, screen)
corner(23, miniBtn)
stroke(THEME.Stroke, 1, 0, miniBtn)
addHover(miniBtn, THEME.Panel, THEME.PanelAlt)

makeDraggable(miniBtn)

minimizeBtn.Activated:Connect(function()
	miniBtn.Position = main.Position
	main.Visible = false
	miniBtn.Visible = true
end)

miniBtn.Activated:Connect(function()
	main.Position = miniBtn.Position
	main.Visible = true
	miniBtn.Visible = false
end)

-- close
closeBtn.Activated:Connect(function()
	pcall(function() screen:Destroy() end)
	print("[AssetTracker] UI closed.")
end)

--=============================================================================
--  DONE
--=============================================================================
updateStats()
applyFilter()

print("╔══════════════════════════════════════════╗")
print("║   ASSET ID TRACKER v2.0  —  LOADED       ║")
print("║   Watching Workspace for new assets...   ║")
print("╚══════════════════════════════════════════╝")
