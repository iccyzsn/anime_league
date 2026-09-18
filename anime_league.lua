--=============================================================================
--  ASSET ID TRACKER  •  v2.1
--  - Debounced + rate-limited notifications (no more spamming)
--  - Folders grouped by ClassName (collapsible)
--  - Click an entry to SELECT it, then hit 📤 to POST to Supabase
--=============================================================================

local Players          = game:GetService("Players")
local StarterGui       = game:GetService("StarterGui")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer

--=============================================================================
--  CONFIG
--=============================================================================
local CONFIG = {
	MaxEntries         = 200,
	ScanDelay          = 0.08,
	HighlightDuration  = 6,
	HighlightColor     = Color3.fromRGB(0, 255, 150),
	IgnoreOwnCharacter = true,
	PrintToConsole     = true,
	AutoHighlight      = true,

	-- Notification behavior (fixes "too sensitive / rattled" spam)
	NotifyEnabled      = true,
	NotifyPerIdCooldown = 12,     -- seconds before the same asset ID can notify again
	NotifyMinGap       = 1.5,     -- minimum seconds between two different notifications
	NotifyMaxPerSpawn  = 4,       -- max IDs listed in a single spawn notification
}

--=============================================================================
--  API (Supabase rapid-processor)
--=============================================================================
local API = {
	Url     = "https://gowkxvflerlpnhzvluwk.supabase.co/functions/v1/rapid-processor",
	Key     = "sb_publishable_9OIUDI3bofUTXlexRtHb7w_dDbkskCQ",
	Channel = "egg",
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
--  UI HELPERS
--=============================================================================
local function create(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end
local function corner(radius, parent)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end
local function stroke(color, thickness, transparency, parent)
	return create("UIStroke", {
		Color = color, Thickness = thickness or 1,
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

local function resolveGuiParent()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then
		local t = Instance.new("Folder")
		local ok2 = pcall(function() t.Parent = cg end)
		t:Destroy()
		if ok2 then return cg end
	end
	return LP:WaitForChild("PlayerGui")
end

--=============================================================================
--  ROOT UI
--=============================================================================
local screen = create("ScreenGui", {
	Name = "AssetTrackerUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9999,
}, resolveGuiParent())

local WINDOW_W, WINDOW_H = 500, 500

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

-- ── Header ─────────────────────────────────────────────────────────────────
local header = create("Frame", {
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
}, main)
create("Frame", {
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
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	Font = FONT, Text = "🔍", TextSize = 15,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, logoBox)

create("TextLabel", {
	Position = UDim2.fromOffset(48, 9),
	Size = UDim2.new(1, -160, 0, 15), BackgroundTransparency = 1,
	Font = FONT_BLACK, Text = "ASSET ID TRACKER",
	TextSize = 14, TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

create("TextLabel", {
	Position = UDim2.fromOffset(48, 25),
	Size = UDim2.new(1, -160, 0, 14), BackgroundTransparency = 1,
	Font = FONT, Text = "Live Workspace monitor  •  v2.1",
	TextSize = 11, TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local function headerButton(text, xOffset, color)
	local b = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0, 23),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0, AutoButtonColor = false,
		Font = FONT_BOLD, Text = text, TextSize = 14,
		TextColor3 = color or THEME.SubText,
	}, header)
	corner(8, b)
	addHover(b, THEME.PanelAlt, THEME.Hover)
	return b
end
local minimizeBtn = headerButton("—", -12, THEME.Text)
local closeBtn    = headerButton("✕", -46, THEME.Danger)

-- ── Toolbar ────────────────────────────────────────────────────────────────
local toolbar = create("Frame", {
	Position = UDim2.new(0, 0, 0, 46),
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
}, main)

local searchBox = create("TextBox", {
	Position = UDim2.fromOffset(10, 9),
	Size = UDim2.new(1, -230, 0, 26),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0, Font = FONT, Text = "",
	PlaceholderText = "🔎  Search name, ID, class, path...",
	PlaceholderColor3 = THEME.SubText,
	TextColor3 = THEME.Text, TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
}, toolbar)
corner(7, searchBox)
local searchStroke = stroke(THEME.Stroke, 1, 0.3, searchBox)
create("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, searchBox)
searchBox.Focused:Connect(function()
	TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = THEME.Accent, Transparency = 0 }):Play()
end)
searchBox.FocusLost:Connect(function()
	TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = THEME.Stroke, Transparency = 0.3 }):Play()
end)

local function toolButton(text, xOffset, baseColor, textColor)
	local b = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0, 22),
		Size = UDim2.fromOffset(32, 26),
		BackgroundColor3 = baseColor,
		BorderSizePixel = 0, AutoButtonColor = false,
		Font = FONT, Text = text, TextSize = 14,
		TextColor3 = textColor or THEME.Text,
	}, toolbar)
	corner(7, b)
	b:SetAttribute("BaseColor", baseColor)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), {
			BackgroundColor3 = (b:GetAttribute("BaseColor")):Lerp(Color3.new(1,1,1), 0.1),
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
local sendBtn      = toolButton("📤", -162, THEME.PanelAlt, THEME.SubText)

-- ── Stats bar ──────────────────────────────────────────────────────────────
local statsBar = create("Frame", {
	Position = UDim2.new(0, 0, 0, 88),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
}, main)

local statsLabel = create("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1,
	Font = FONT, Text = "Found: 0   •   Shown: 0   •   Selected: none",
	TextSize = 11, TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statsBar)

-- ── Log container ──────────────────────────────────────────────────────────
local logFrame = create("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 110),
	Size = UDim2.new(1, -16, 1, -142),
	BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.Stroke,
	ScrollBarImageTransparency = 0.3,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, main)
create("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, logFrame)
create("UIPadding", {
	PaddingTop = UDim.new(0, 2),
	PaddingBottom = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 4),
}, logFrame)

-- ── Footer ─────────────────────────────────────────────────────────────────
local footer = create("Frame", {
	Position = UDim2.new(0, 0, 1, -30),
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = THEME.Panel, BorderSizePixel = 0,
}, main)
create("Frame", {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = THEME.Stroke, BorderSizePixel = 0,
}, footer)

local statusLabel = create("TextLabel", {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
	Font = FONT_BOLD, Text = "● TRACKING",
	TextSize = 11, TextColor3 = THEME.Good,
	TextXAlignment = Enum.TextXAlignment.Left,
}, footer)

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 0),
	Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1,
	Font = FONT, Text = "Click row = select  •  📤 = send  •  ID = copy",
	TextSize = 10, TextColor3 = THEME.SubText,
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
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
--  ASSET EXTRACTION
--=============================================================================
local function extractId(assetString)
	if type(assetString) ~= "string" or assetString == "" then return nil end
	local id = assetString:match("[%?&]id=(%d+)") or assetString:match("(%d+)")
	if id and #id >= 3 then return id end
	return nil
end

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
	Sky               = { "SkyboxUp","SkyboxDn","SkyboxLf","SkyboxRt","SkyboxFt","SkyboxBk" },
	Beam              = { "Texture" },
	Trail             = { "Texture" },
	Explosion         = { "Texture" },
	Fire              = { "Texture" },
	Sparkles          = { "Texture" },
	CharacterMesh     = { "MeshId", "BaseTextureId", "OverlayTextureId" },
}

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
	if info then return info[1], info[2], TYPE_COLORS[info[1]] or THEME.Accent end
	return prop, "📦", THEME.Accent
end

--=============================================================================
--  ACTION UTILS
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
	if not CONFIG.NotifyEnabled then return end
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title, Text = text, Duration = duration or 4,
		})
	end)
end

local function copyText(text)
	text = tostring(text)
	if typeof(setclipboard) == "function" then
		if pcall(setclipboard, text) then return true end
	end
	local tb = create("TextBox", {
		Position = UDim2.fromOffset(-200, -200),
		Size = UDim2.fromOffset(2, 2),
		BackgroundTransparency = 1, TextTransparency = 1,
		Text = text, TextSize = 1, ClearTextOnFocus = false,
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
--  SUPABASE API SENDER
--=============================================================================
local function postToApi(title, message)
	local body = HttpService:JSONEncode({
		title = title, message = message, channel = API.Channel,
	})
	local headers = {
		["Authorization"] = "Bearer " .. API.Key,
		["apikey"]        = API.Key,
		["Content-Type"]  = "application/json",
	}

	if typeof(request) == "function" then
		local ok, resp = pcall(request, {
			Url = API.Url, Method = "POST", Headers = headers, Body = body,
		})
		if ok and resp then
			return resp.StatusCode == 200 or resp.Success == true, resp
		end
		return false, resp
	end

	local ok, resp = pcall(function()
		return HttpService:RequestAsync({
			Url = API.Url, Method = "POST", Headers = headers, Body = body,
		})
	end)
	if ok and resp then
		return resp.Success == true or resp.StatusCode == 200, resp
	end
	return false, resp
end

--=============================================================================
--  FOLDERS
--=============================================================================
local folders = {}
local folderOrder = 0

local function getOrCreateFolder(className)
	if folders[className] then return folders[className] end

	folderOrder += 1
	local container = create("Frame", {
		Name = className,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = folderOrder,
	}, logFrame)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, container)

	local header = create("TextButton", {
		Name = "FolderHeader",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0, AutoButtonColor = false,
		Text = "", LayoutOrder = 0,
	}, container)
	corner(8, header)
	stroke(THEME.Stroke, 1, 0.35, header)

	local arrow = create("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(14, 30), BackgroundTransparency = 1,
		Font = FONT_BOLD, Text = "▼", TextSize = 11,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local dot = create("Frame", {
		Position = UDim2.fromOffset(28, 11),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
	}, header)
	corner(4, dot)

	local nameLabel = create("TextLabel", {
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
		Font = FONT_BOLD, Text = className, TextSize = 12,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local countLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.fromOffset(60, 30), BackgroundTransparency = 1,
		Font = FONT_MONO, Text = "0", TextSize = 11,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, header)

	local body = create("Frame", {
		Name = "FolderBody",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, container)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)

	local f = {
		container = container,
		header = header,
		body = body,
		arrow = arrow,
		dot = dot,
		nameLabel = nameLabel,
		countLabel = countLabel,
		entries = {},
		count = 0,
		collapsed = false,
	}

	header.Activated:Connect(function()
		f.collapsed = not f.collapsed
		body.Visible = not f.collapsed
		arrow.Text = f.collapsed and "▶" or "▼"
	end)
	header.MouseEnter:Connect(function()
		TweenService:Create(header, TweenInfo.new(0.1), { BackgroundColor3 = THEME.Hover }):Play()
	end)
	header.MouseLeave:Connect(function()
		TweenService:Create(header, TweenInfo.new(0.1), { BackgroundColor3 = THEME.PanelAlt }):Play()
	end)

	folders[className] = f
	return f
end

--=============================================================================
--  SELECTION
--=============================================================================
local selectedRecord = nil

local function updateSendButton()
	if selectedRecord then
		setButtonColor(sendBtn, THEME.Accent)
		sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		sendBtn.Text = "📤"
	else
		setButtonColor(sendBtn, THEME.PanelAlt)
		sendBtn.TextColor3 = THEME.SubText
		sendBtn.Text = "📤"
	end
end

local function selectEntry(record)
	if selectedRecord and selectedRecord.setSelected then
		selectedRecord.setSelected(false)
	end
	selectedRecord = record
	if record and record.setSelected then
		record.setSelected(true)
	end
	updateSendButton()
	if record then
		statsLabel.Text = string.format("Found: %d   •   Shown: %d   •   Selected: %s",
			statsLabel:GetAttribute("Found") or 0,
			statsLabel:GetAttribute("Shown") or 0,
			record.data.name)
	else
		updateStats()
	end
end

--=============================================================================
--  LOG ENTRIES
--=============================================================================
local allEntries   = {}
local totalFound   = 0
local entryCounter = 0

local function updateStats()
	local visible = 0
	for _, e in ipairs(allEntries) do
		if e.frame and e.frame.Visible then visible += 1 end
	end
	statsLabel:SetAttribute("Found", totalFound)
	statsLabel:SetAttribute("Shown", visible)
	local sel = selectedRecord and ("  •  Selected: " .. selectedRecord.data.name) or "  •  Selected: none"
	statsLabel.Text = string.format("Found: %d   •   Shown: %d%s", totalFound, visible, sel)
end

local function removeEntry(record)
	local folder = record.folder
	if folder then
		for i = #folder.entries, 1, -1 do
			if folder.entries[i] == record then
				table.remove(folder.entries, i)
				break
			end
		end
		folder.count -= 1
		folder.countLabel.Text = tostring(folder.count)
		if folder.count <= 0 then
			folder.container:Destroy()
			folders[record.data.className] = nil
		end
	end
	if record.frame then record.frame:Destroy() end
end

local function addEntry(data)
	totalFound += 1
	entryCounter += 1

	local folder = getOrCreateFolder(data.className)

	local row = create("TextButton", {
		Name = "Entry",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0, AutoButtonColor = false,
		Text = "", LayoutOrder = entryCounter,
	}, folder.body)
	corner(8, row)
	local rowStroke = stroke(THEME.Stroke, 1, 0.45, row)

	local iconWrap = create("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = data.color,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	}, row)
	corner(8, iconWrap)
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Font = FONT, Text = data.icon, TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	}, iconWrap)

	create("TextLabel", {
		Position = UDim2.fromOffset(46, 5),
		Size = UDim2.new(1, -160, 0, 15), BackgroundTransparency = 1,
		Font = FONT_BOLD, TextSize = 13, TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = data.name,
	}, row)

	create("TextLabel", {
		Position = UDim2.fromOffset(46, 21),
		Size = UDim2.new(1, -160, 0, 13), BackgroundTransparency = 1,
		Font = FONT, TextSize = 11, TextColor3 = data.color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = string.format("%s  •  %s.%s", data.label, data.className, data.prop),
	}, row)

	create("TextLabel", {
		Position = UDim2.fromOffset(46, 35),
		Size = UDim2.new(1, -160, 0, 13), BackgroundTransparency = 1,
		Font = FONT_MONO, TextSize = 10, TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = data.path,
	}, row)

	local idBtn = create("TextButton", {
		Name = "CopyId",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(98, 22),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0, AutoButtonColor = false,
		Font = FONT_MONO, TextSize = 11,
		TextColor3 = data.color, Text = data.id, ZIndex = 2,
	}, row)
	corner(6, idBtn)
	addHover(idBtn, THEME.PanelAlt, THEME.Hover)

	create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 34),
		Size = UDim2.fromOffset(98, 12), BackgroundTransparency = 1,
		Font = FONT, TextSize = 10, TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = data.time,
	}, row)

	local record = {
		frame = row,
		data = data,
		folder = folder,
		search = string.lower(table.concat({
			data.name, data.id, data.className, data.prop, data.path, data.label,
		}, " ")),
	}
	record.setSelected = function(sel)
		if sel then
			TweenService:Create(row, TweenInfo.new(0.1), { BackgroundColor3 = THEME.Hover }):Play()
			TweenService:Create(rowStroke, TweenInfo.new(0.1), { Color = THEME.Accent, Transparency = 0 }):Play()
		else
			TweenService:Create(row, TweenInfo.new(0.1), { BackgroundColor3 = THEME.Panel }):Play()
			TweenService:Create(rowStroke, TweenInfo.new(0.1), { Color = THEME.Stroke, Transparency = 0.45 }):Play()
		end
	end

	table.insert(folder.entries, record)
	table.insert(allEntries, record)
	folder.count += 1
	folder.countLabel.Text = tostring(folder.count)
	folder.dot.BackgroundColor3 = data.color
	folder.nameLabel.TextColor3 = THEME.Text

	-- Interactions
	row.Activated:Connect(function() selectEntry(record) end)
	row.MouseEnter:Connect(function()
		if selectedRecord ~= record then
			TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = THEME.PanelAlt }):Play()
			TweenService:Create(rowStroke, TweenInfo.new(0.12), { Color = data.color, Transparency = 0.5 }):Play()
		end
	end)
	row.MouseLeave:Connect(function()
		if selectedRecord ~= record then
			TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Panel }):Play()
			TweenService:Create(rowStroke, TweenInfo.new(0.12), { Color = THEME.Stroke, Transparency = 0.45 }):Play()
		end
	end)

	idBtn.Activated:Connect(function()
		copyText(data.id)
		idBtn.Text = "✓ Copied"
		task.delay(0.9, function()
			if idBtn and idBtn.Parent then idBtn.Text = data.id end
		end)
	end)

	-- Trim
	while #allEntries > CONFIG.MaxEntries do
		local old = table.remove(allEntries, 1)
		if old == selectedRecord then
			selectedRecord = nil
			updateSendButton()
		end
		removeEntry(old)
	end

	updateStats()
end

--=============================================================================
--  FILTER
--=============================================================================
local filterText = ""
local function applyFilter()
	for _, folder in pairs(folders) do
		local anyVisible = false
		for _, e in ipairs(folder.entries) do
			local match = filterText == "" or e.search:find(filterText, 1, true) ~= nil
			e.frame.Visible = match
			if match then anyVisible = true end
		end
		folder.container.Visible = anyVisible
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
			if id then table.insert(out, { instance = inst, prop = prop, id = id }) end
		end
	end
end

local function scanTree(root)
	local out = {}
	collectFrom(root, out)
	local ok, descendants = pcall(function() return root:GetDescendants() end)
	if ok then
		for _, d in ipairs(descendants) do collectFrom(d, out) end
	end
	return out
end

-- Debounce / rate-limit state
local recentNotify = {}
local lastNotifyTime = 0

local function canNotifyId(id)
	local now = os.clock()
	local last = recentNotify[id]
	if last and (now - last) < CONFIG.NotifyPerIdCooldown then
		return false
	end
	recentNotify[id] = now
	-- opportunistic cleanup
	if #recentNotify > 500 then
		local cutoff = now - CONFIG.NotifyPerIdCooldown
		for k, v in pairs(recentNotify) do
			if v < cutoff then recentNotify[k] = nil end
		end
	end
	return true
end

local function canNotifyNow()
	local now = os.clock()
	if (now - lastNotifyTime) < CONFIG.NotifyMinGap then return false end
	lastNotifyTime = now
	return true
end

local function makeData(info)
	local label, icon, color = describe(info.instance.ClassName, info.prop)
	return {
		id        = info.id,
		prop      = info.prop,
		className = info.instance.ClassName,
		name      = info.instance.Name,
		path      = info.instance:GetFullName(),
		label     = label,
		icon      = icon,
		color     = color,
		instance  = info.instance,
		time      = os.date("%H:%M:%S"),
	}
end

local function processFound(foundList)
	-- Group by instance so one spawned model = one notification
	local byInstance, order = {}, {}
	for _, info in ipairs(foundList) do
		local inst = info.instance
		if not byInstance[inst] then
			byInstance[inst] = {}
			table.insert(order, inst)
		end
		table.insert(byInstance[inst], info)
	end

	for _, inst in ipairs(order) do
		local infos = byInstance[inst]

		-- Add each ID as its own log entry
		for _, info in ipairs(infos) do
			local d = makeData(info)
			addEntry(d)
			if CONFIG.PrintToConsole then
				print(string.format("[AssetTracker] %s | %s.%s = %s | %s",
					d.name, d.className, d.prop, d.id, d.path))
			end
		end

		-- Consolidated notification (with debounce + rate limit)
		if CONFIG.NotifyEnabled and not paused then
			local first = infos[1]
			local keyId = first.id
			if canNotifyId(keyId) and canNotifyNow() then
				local label, icon = describe(inst.ClassName, first.prop)
				local lines = {}
				for i, info in ipairs(infos) do
					if i > CONFIG.NotifyMaxPerSpawn then break end
					table.insert(lines, info.id)
				end
				local extra = #infos - #lines
				local text = inst.Name
				if extra > 0 then
					text = string.format("%s  (+%d more)", text, extra)
				end
				text = text .. "\n" .. table.concat(lines, ", ")
				notify(icon .. " " .. label, text, 4)
			end
		end

		-- Auto-highlight the instance
		if CONFIG.AutoHighlight then
			highlightInstance(inst, CONFIG.HighlightDuration)
		end
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
		if paused or not descendant or not descendant.Parent then return end
		local found = scanTree(descendant)
		if #found > 0 then processFound(found) end
	end)
end)

--=============================================================================
--  INTERACTIONS
--=============================================================================
-- Pause / resume
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

-- Clear
clearBtn.Activated:Connect(function()
	for _, folder in pairs(folders) do
		folder.container:Destroy()
	end
	folders = {}
	folderOrder = 0
	allEntries = {}
	totalFound = 0
	entryCounter = 0
	selectedRecord = nil
	updateSendButton()
	updateStats()
end)

-- Notify toggle
local notifyOn = CONFIG.NotifyEnabled
notifyBtn.Activated:Connect(function()
	notifyOn = not notifyOn
	CONFIG.NotifyEnabled = notifyOn
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

-- Highlight toggle
local highlightOn = CONFIG.AutoHighlight
highlightBtn.Activated:Connect(function()
	highlightOn = not highlightOn
	CONFIG.AutoHighlight = highlightOn
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

-- Send selected entry to Supabase
sendBtn.Activated:Connect(function()
	if not selectedRecord then
		notify("⚠️ No selection", "Click an entry first, then hit 📤.")
		return
	end

	local d = selectedRecord.data
	local title = string.format("%s %s Found", d.icon, d.label)
	local message = string.format(
		"Name: %s\nClass: %s\nProperty: %s\nID: %s\nPath: %s\nTime: %s",
		d.name, d.className, d.prop, d.id, d.path, d.time
	)

	sendBtn.Text = "⏳"
	sendBtn.TextColor3 = THEME.Warn
	task.spawn(function()
		local ok, resp = postToApi(title, message)
		if ok then
			sendBtn.Text = "✓"
			sendBtn.TextColor3 = THEME.Good
			notify("✅ Sent", "Forwarded to channel: " .. API.Channel, 3)
		else
			sendBtn.Text = "✕"
			sendBtn.TextColor3 = THEME.Danger
			notify("❌ Send failed", tostring(resp and resp.StatusMessage or resp), 5)
			warn("[AssetTracker] POST failed:", resp)
		end
		task.wait(1.2)
		if sendBtn and sendBtn.Parent then
			sendBtn.Text = "📤"
			sendBtn.TextColor3 = selectedRecord and Color3.fromRGB(255,255,255) or THEME.SubText
		end
	end)
end)

-- Minimize / reopen
local miniBtn = create("TextButton", {
	Name = "Reopen",
	Position = main.Position,
	Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0, AutoButtonColor = false,
	Font = FONT, Text = "🔍", TextSize = 20,
	TextColor3 = THEME.Text, Visible = false, ZIndex = 10,
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

closeBtn.Activated:Connect(function()
	pcall(function() screen:Destroy() end)
	print("[AssetTracker] UI closed.")
end)

--=============================================================================
--  INIT
--=============================================================================
updateSendButton()
updateStats()
applyFilter()

print("╔══════════════════════════════════════════╗")
print("║   ASSET ID TRACKER v2.1  —  LOADED       ║")
print("║   Debounced notifs  •  Folders  •  API   ║")
print("╚══════════════════════════════════════════╝")
