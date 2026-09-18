
--=============================================================================
--  ASSET ID TRACKER  •  v2.4  (optimized)
--=============================================================================
local Players          = game:GetService("Players")
local StarterGui       = game:GetService("StarterGui")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer

local CONFIG = {
	MaxEntries          = 100,
	ScanBatch           = 0.35,
	ScanBudgetPerTick   = 60,
	HighlightDuration   = 5,
	HighlightColor      = Color3.fromRGB(0, 255, 150),
	IgnoreOwnCharacter  = true,
	PrintToConsole      = false,
	AutoHighlight       = false,
	NotifyEnabled       = true,
	NotifyPerIdCooldown = 14,
	NotifyMinGap        = 1.5,
	NotifyMaxPerSpawn   = 3,
	StartHidden         = true,
	ToggleKey           = Enum.KeyCode.RightShift,
}

local API = {
	Url     = "https://gowkxvflerlpnhzvluwk.supabase.co/functions/v1/rapid-processor",
	Key     = "sb_publishable_9OIUDI3bofUTXlexRtHb7w_dDbkskCQ",
	Channel = "egg",
}

local THEME = {
	Bg = Color3.fromRGB(15,17,23), Panel = Color3.fromRGB(24,27,36),
	PanelAlt = Color3.fromRGB(32,36,47), Hover = Color3.fromRGB(42,47,62),
	Stroke = Color3.fromRGB(48,54,70), Text = Color3.fromRGB(233,237,245),
	SubText = Color3.fromRGB(138,147,168), Accent = Color3.fromRGB(88,166,255),
	Good = Color3.fromRGB(0,220,160), Danger = Color3.fromRGB(255,92,92),
	Warn = Color3.fromRGB(255,190,80),
}

local FONT       = Enum.Font.Gotham
local FONT_BOLD  = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack
local FONT_MONO  = Enum.Font.Code

local function create(c, p, parent)
	local i = Instance.new(c)
	for k, v in pairs(p or {}) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end
local function corner(r, p) return create("UICorner", {CornerRadius = UDim.new(0,r)}, p) end
local function stroke(c, t, tr, p)
	return create("UIStroke", {Color=c, Thickness=t or 1, Transparency=tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p)
end

local function resolveGuiParent()
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
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

local screen = create("ScreenGui", {
	Name="AssetTrackerUI", ResetOnSpawn=false, IgnoreGuiInset=true,
	ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=9999,
}, resolveGuiParent())

--=============================================================================
--  FLOATING TOGGLE
--=============================================================================
local toggleBtn = create("TextButton", {
	Name="ToggleBtn", Position=UDim2.new(0,24,0,120),
	Size=UDim2.fromOffset(52,52), BackgroundColor3=THEME.Panel,
	BorderSizePixel=0, AutoButtonColor=false, Font=FONT, Text="🔍",
	TextSize=22, TextColor3=THEME.Text, ZIndex=20,
}, screen)
corner(26, toggleBtn)
local toggleStroke = stroke(THEME.Stroke, 2, 0, toggleBtn)

toggleBtn.MouseEnter:Connect(function()
	toggleBtn.BackgroundColor3 = THEME.Hover
	toggleStroke.Color = THEME.Accent
end)
toggleBtn.MouseLeave:Connect(function()
	toggleBtn.BackgroundColor3 = THEME.Panel
	toggleStroke.Color = THEME.Stroke
end)

--=============================================================================
--  MAIN WINDOW
--=============================================================================
local main = create("Frame", {
	Name="Window", Position=UDim2.fromOffset(90,80),
	Size=UDim2.fromOffset(500,500), BackgroundColor3=THEME.Bg,
	BorderSizePixel=0, ClipsDescendants=true, Visible=false,
}, screen)
corner(12, main)
stroke(THEME.Stroke, 1, 0, main)

local header = create("Frame", {
	Size=UDim2.new(1,0,0,46), BackgroundColor3=THEME.Panel, BorderSizePixel=0,
}, main)
create("Frame", {
	Position=UDim2.new(0,0,1,-1), Size=UDim2.new(1,0,0,1),
	BackgroundColor3=THEME.Accent, BackgroundTransparency=0.55, BorderSizePixel=0,
}, header)

local logoBox = create("Frame", {
	Position=UDim2.fromOffset(12,10), Size=UDim2.fromOffset(26,26),
	BackgroundColor3=THEME.Accent, BorderSizePixel=0,
}, header)
corner(8, logoBox)
create("TextLabel", {
	Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Font=FONT,
	Text="🔍", TextSize=15, TextColor3=Color3.new(1,1,1),
}, logoBox)
create("TextLabel", {
	Position=UDim2.fromOffset(48,9), Size=UDim2.new(1,-160,0,15),
	BackgroundTransparency=1, Font=FONT_BLACK, Text="ASSET ID TRACKER",
	TextSize=14, TextColor3=THEME.Text, TextXAlignment=Enum.TextXAlignment.Left,
}, header)
create("TextLabel", {
	Position=UDim2.fromOffset(48,25), Size=UDim2.new(1,-160,0,14),
	BackgroundTransparency=1, Font=FONT,
	Text="Live Workspace monitor  •  v2.4", TextSize=11,
	TextColor3=THEME.SubText, TextXAlignment=Enum.TextXAlignment.Left,
}, header)

local function headerButton(text, x, color)
	local b = create("TextButton", {
		AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,x,0,23),
		Size=UDim2.fromOffset(28,28), BackgroundColor3=THEME.PanelAlt,
		BorderSizePixel=0, AutoButtonColor=false, Font=FONT_BOLD,
		Text=text, TextSize=14, TextColor3=color or THEME.SubText,
	}, header)
	corner(8, b)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = THEME.Hover end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = THEME.PanelAlt end)
	return b
end
local minimizeBtn = headerButton("—", -12, THEME.Text)
local closeBtn    = headerButton("✕", -46, THEME.Danger)

local toolbar = create("Frame", {
	Position=UDim2.new(0,0,0,46), Size=UDim2.new(1,0,0,42), BackgroundTransparency=1,
}, main)

local searchBox = create("TextBox", {
	Position=UDim2.fromOffset(10,9), Size=UDim2.new(1,-230,0,26),
	BackgroundColor3=THEME.Panel, BorderSizePixel=0, Font=FONT,
	PlaceholderText="🔎  Search name, ID, class, path...",
	PlaceholderColor3=THEME.SubText, TextColor3=THEME.Text, TextSize=12,
	TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false,
}, toolbar)
corner(7, searchBox)
local searchStroke = stroke(THEME.Stroke, 1, 0.3, searchBox)
create("UIPadding", {PaddingLeft=UDim.new(0,9), PaddingRight=UDim.new(0,9)}, searchBox)
searchBox.Focused:Connect(function()
	searchStroke.Color = THEME.Accent; searchStroke.Transparency = 0
end)
searchBox.FocusLost:Connect(function()
	searchStroke.Color = THEME.Stroke; searchStroke.Transparency = 0.3
end)

local function toolButton(text, x, base, tc)
	local b = create("TextButton", {
		AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,x,0,22),
		Size=UDim2.fromOffset(32,26), BackgroundColor3=base,
		BorderSizePixel=0, AutoButtonColor=false, Font=FONT,
		Text=text, TextSize=14, TextColor3=tc or THEME.Text,
	}, toolbar)
	corner(7, b)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = THEME.Hover end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = base end)
	b:SetAttribute("RestColor", base)
	return b
end

local clearBtn     = toolButton("🗑", -10,  THEME.Panel)
local pauseBtn     = toolButton("⏸", -48,  THEME.Panel)
local notifyBtn    = toolButton("🔔", -86,  THEME.Panel)
local highlightBtn = toolButton("🎯", -124, THEME.PanelAlt, THEME.SubText)
local sendBtn      = toolButton("📤", -162, THEME.PanelAlt, THEME.SubText)

local statsBar = create("Frame", {
	Position=UDim2.new(0,0,0,88), Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
}, main)
local statsLabel = create("TextLabel", {
	Position=UDim2.fromOffset(14,0), Size=UDim2.new(1,-28,1,0),
	BackgroundTransparency=1, Font=FONT,
	Text="Found: 0   •   Shown: 0   •   Selected: none",
	TextSize=11, TextColor3=THEME.SubText, TextXAlignment=Enum.TextXAlignment.Left,
}, statsBar)

local logFrame = create("ScrollingFrame", {
	Position=UDim2.fromOffset(8,110), Size=UDim2.new(1,-16,1,-142),
	BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=4,
	ScrollBarImageColor3=THEME.Stroke, ScrollBarImageTransparency=0.3,
	CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y,
	ScrollingDirection=Enum.ScrollingDirection.Y,
}, main)
create("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, logFrame)
create("UIPadding", {
	PaddingTop=UDim.new(0,2), PaddingBottom=UDim.new(0,8), PaddingRight=UDim.new(0,4),
}, logFrame)

local footer = create("Frame", {
	Position=UDim2.new(0,0,1,-30), Size=UDim2.new(1,0,0,30),
	BackgroundColor3=THEME.Panel, BorderSizePixel=0,
}, main)
create("Frame", {
	Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,1),
	BackgroundColor3=THEME.Stroke, BorderSizePixel=0,
}, footer)
local statusLabel = create("TextLabel", {
	Position=UDim2.fromOffset(12,0), Size=UDim2.new(0.5,0,1,0),
	BackgroundTransparency=1, Font=FONT_BOLD, Text="● TRACKING",
	TextSize=11, TextColor3=THEME.Good, TextXAlignment=Enum.TextXAlignment.Left,
}, footer)
create("TextLabel", {
	AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,0),
	Size=UDim2.new(0.6,0,1,0), BackgroundTransparency=1, Font=FONT,
	Text="RightShift = hide  •  Click row = select  •  📤 = send",
	TextSize=10, TextColor3=THEME.SubText, TextXAlignment=Enum.TextXAlignment.Right,
}, footer)

local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end
makeDraggable(main, header)
makeDraggable(toggleBtn)

--=============================================================================
--  ASSET TABLE (hoisted, avoid closures)
--=============================================================================
local ASSET_PROPS = {
	MeshPart={"MeshId","TextureID"}, SpecialMesh={"MeshId","TextureId"},
	CylinderMesh={"MeshId","TextureId"}, BlockMesh={"MeshId"},
	Decal={"Texture"}, Texture={"Texture"},
	SurfaceAppearance={"ColorMap","NormalMap","RoughnessMap","MetalnessMap"},
	ParticleEmitter={"Texture"}, Sound={"SoundId"}, Animation={"AnimationId"},
	Tool={"TextureId"}, ImageLabel={"Image"}, ImageButton={"Image"},
	Shirt={"ShirtTemplate"}, Pants={"PantsTemplate"}, ShirtGraphic={"Graphic"},
	Sky={"SkyboxUp","SkyboxDn","SkyboxLf","SkyboxRt","SkyboxFt","SkyboxBk"},
	Beam={"Texture"}, Trail={"Texture"}, Explosion={"Texture"},
	Fire={"Texture"}, Sparkles={"Texture"},
	CharacterMesh={"MeshId","BaseTextureId","OverlayTextureId"},
}

local PROP_INFO = {
	MeshId={"Mesh","🧊"}, TextureId={"Texture","🖼️"}, TextureID={"Texture","🖼️"},
	Texture={"Texture","🖼️"}, SoundId={"Sound","🔊"}, AnimationId={"Animation","🎞️"},
	Image={"Image","🖼️"}, ShirtTemplate={"Shirt","👕"}, PantsTemplate={"Pants","👖"},
	Graphic={"Graphic","🎨"}, ColorMap={"ColorMap","🎨"}, NormalMap={"NormalMap","🗺️"},
	RoughnessMap={"Roughness","🗺️"}, MetalnessMap={"Metalness","🗺️"},
	SkyboxUp={"Skybox","🌌"}, SkyboxDn={"Skybox","🌌"}, SkyboxLf={"Skybox","🌌"},
	SkyboxRt={"Skybox","🌌"}, SkyboxFt={"Skybox","🌌"}, SkyboxBk={"Skybox","🌌"},
	BaseTextureId={"Texture","🖼️"}, OverlayTextureId={"Texture","🖼️"},
}
local CLASS_INFO = {
	ParticleEmitter={"Particle","✨"}, Beam={"Beam","💫"}, Trail={"Trail","💫"},
	Fire={"Fire","🔥"}, Explosion={"Explosion","💥"}, Decal={"Decal","🏷️"},
	Sky={"Skybox","🌌"}, Sound={"Sound","🔊"}, Animation={"Animation","🎞️"},
}
local TYPE_COLORS = {
	Mesh=Color3.fromRGB(110,190,255), Texture=Color3.fromRGB(255,170,90),
	Decal=Color3.fromRGB(255,140,200), Sound=Color3.fromRGB(180,140,255),
	Animation=Color3.fromRGB(120,255,190), Particle=Color3.fromRGB(255,230,120),
	Image=Color3.fromRGB(255,170,90), Shirt=Color3.fromRGB(140,220,140),
	Pants=Color3.fromRGB(140,180,240), Graphic=Color3.fromRGB(255,200,120),
	Skybox=Color3.fromRGB(150,180,255), Beam=Color3.fromRGB(150,220,255),
	Trail=Color3.fromRGB(150,220,255), Fire=Color3.fromRGB(255,130,80),
	Explosion=Color3.fromRGB(255,110,90), ColorMap=Color3.fromRGB(255,160,120),
	NormalMap=Color3.fromRGB(160,200,255), Roughness=Color3.fromRGB(190,190,190),
	Metalness=Color3.fromRGB(200,200,220),
}
local function describe(className, prop)
	local info = CLASS_INFO[className] or PROP_INFO[prop]
	if info then return info[1], info[2], TYPE_COLORS[info[1]] or THEME.Accent end
	return prop, "📦", THEME.Accent
end

local function extractId(s)
	if type(s) ~= "string" or s == "" then return nil end
	local id = s:match("[%?&]id=(%d+)") or s:match("(%d+)")
	if id and #id >= 3 then return id end
	return nil
end

--=============================================================================
--  HIGHLIGHT POOL (reuse — Highlights are costly)
--=============================================================================
local hlPool, hlIdx = {}, 0
local function getHighlight()
	if #hlPool < 4 then
		local h = Instance.new("Highlight")
		h.FillColor = CONFIG.HighlightColor
		h.FillTransparency = 0.7
		h.OutlineColor = Color3.new(1,1,1)
		h.OutlineTransparency = 0.2
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Name = "AssetTrackerHighlight"
		table.insert(hlPool, h)
		return h
	end
	hlIdx = hlIdx % #hlPool + 1
	return hlPool[hlIdx]
end

local function highlightInstance(inst, dur)
	if not inst or not inst.Parent then return end
	local h = getHighlight()
	h.Parent = inst
	task.delay(dur or CONFIG.HighlightDuration, function()
		if h.Parent == inst then h.Parent = nil end
	end)
end

local function notify(title, text, dur)
	if not CONFIG.NotifyEnabled then return end
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title=title, Text=text, Duration=dur or 4,
		})
	end)
end

local function copyText(text)
	text = tostring(text)
	if typeof(setclipboard) == "function" then
		if pcall(setclipboard, text) then return true end
	end
end

local function postToApi(title, message)
	local body = HttpService:JSONEncode({title=title, message=message, channel=API.Channel})
	local headers = {
		["Authorization"]="Bearer "..API.Key,
		["apikey"]=API.Key,
		["Content-Type"]="application/json",
	}
	if typeof(request) == "function" then
		local ok, resp = pcall(request, {
			Url=API.Url, Method="POST", Headers=headers, Body=body,
		})
		if ok and resp then return resp.StatusCode==200 or resp.Success==true, resp end
		return false, resp
	end
	local ok, resp = pcall(function()
		return HttpService:RequestAsync({
			Url=API.Url, Method="POST", Headers=headers, Body=body,
		})
	end)
	if ok and resp then return resp.Success==true or resp.StatusCode==200, resp end
	return false, resp
end

--=============================================================================
--  FOLDERS
--=============================================================================
local folders, folderOrder = {}, 0

local function getOrCreateFolder(className)
	local f = folders[className]
	if f then return f end
	folderOrder += 1

	local container = create("Frame", {
		Name=className, Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
		LayoutOrder=folderOrder,
	}, logFrame)
	create("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, container)

	local hdr = create("TextButton", {
		Name="FolderHeader", Size=UDim2.new(1,0,0,30),
		BackgroundColor3=THEME.PanelAlt, BorderSizePixel=0,
		AutoButtonColor=false, Text="", LayoutOrder=0,
	}, container)
	corner(8, hdr)
	stroke(THEME.Stroke, 1, 0.35, hdr)

	local arrow = create("TextLabel", {
		Position=UDim2.fromOffset(10,0), Size=UDim2.fromOffset(14,30),
		BackgroundTransparency=1, Font=FONT_BOLD, Text="▼",
		TextSize=11, TextColor3=THEME.SubText,
		TextXAlignment=Enum.TextXAlignment.Left,
	}, hdr)
	local dot = create("Frame", {
		Position=UDim2.fromOffset(28,11), Size=UDim2.fromOffset(8,8),
		BackgroundColor3=THEME.Accent, BorderSizePixel=0,
	}, hdr)
	corner(4, dot)
	local nameLabel = create("TextLabel", {
		Position=UDim2.fromOffset(42,0), Size=UDim2.new(1,-100,1,0),
		BackgroundTransparency=1, Font=FONT_BOLD, Text=className,
		TextSize=12, TextColor3=THEME.Text,
		TextXAlignment=Enum.TextXAlignment.Left,
	}, hdr)
	local countLabel = create("TextLabel", {
		AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-10,0,0),
		Size=UDim2.fromOffset(60,30), BackgroundTransparency=1,
		Font=FONT_MONO, Text="0", TextSize=11,
		TextColor3=THEME.SubText, TextXAlignment=Enum.TextXAlignment.Right,
	}, hdr)

	local body = create("Frame", {
		Name="FolderBody", Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
		LayoutOrder=1,
	}, container)
	create("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, body)

	f = {
		container=container, header=hdr, body=body, arrow=arrow, dot=dot,
		nameLabel=nameLabel, countLabel=countLabel,
		entries={}, count=0, collapsed=false,
	}
	hdr.Activated:Connect(function()
		f.collapsed = not f.collapsed
		body.Visible = not f.collapsed
		arrow.Text = f.collapsed and "▶" or "▼"
	end)
	hdr.MouseEnter:Connect(function() hdr.BackgroundColor3 = THEME.Hover end)
	hdr.MouseLeave:Connect(function() hdr.BackgroundColor3 = THEME.PanelAlt end)

	folders[className] = f
	return f
end

--=============================================================================
--  SELECTION + ENTRY MANAGEMENT
--=============================================================================
local selectedRecord = nil
local allEntries = {}
local totalFound = 0
local entryCounter = 0

local function updateSendButton()
	if selectedRecord then
		sendBtn.BackgroundColor3 = THEME.Accent
		sendBtn:SetAttribute("RestColor", THEME.Accent)
		sendBtn.TextColor3 = Color3.new(1,1,1)
	else
		sendBtn.BackgroundColor3 = THEME.PanelAlt
		sendBtn:SetAttribute("RestColor", THEME.PanelAlt)
		sendBtn.TextColor3 = THEME.SubText
	end
	sendBtn.Text = "📤"
end

function updateStats()
	local visible = 0
	for i = 1, #allEntries do
		local e = allEntries[i]
		if e.frame and e.frame.Visible then visible += 1 end
	end
	local sel = selectedRecord and ("  •  Selected: " .. selectedRecord.data.name) or "  •  Selected: none"
	statsLabel.Text = string.format("Found: %d   •   Shown: %d%s", totalFound, visible, sel)
end

local function selectEntry(record)
	if selectedRecord then
		local prev = selectedRecord
		prev.frame.BackgroundColor3 = THEME.Panel
		prev.frame.UIStroke.Color = THEME.Stroke
		prev.frame.UIStroke.Transparency = 0.45
	end
	selectedRecord = record
	record.frame.BackgroundColor3 = THEME.Hover
	record.frame.UIStroke.Color = THEME.Accent
	record.frame.UIStroke.Transparency = 0
	updateSendButton()
	updateStats()
end

local function removeEntry(record)
	local folder = record.folder
	if folder then
		for i = #folder.entries, 1, -1 do
			if folder.entries[i] == record then
				table.remove(folder.entries, i); break
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
		Name="Entry", Size=UDim2.new(1,0,0,58),
		BackgroundColor3=THEME.Panel, BorderSizePixel=0,
		AutoButtonColor=false, Text="", LayoutOrder=entryCounter,
	}, folder.body)
	corner(8, row)
	local rowStroke = stroke(THEME.Stroke, 1, 0.45, row)

	local iconWrap = create("Frame", {
		Position=UDim2.fromOffset(8,8), Size=UDim2.fromOffset(30,30),
		BackgroundColor3=data.color, BackgroundTransparency=0.82, BorderSizePixel=0,
	}, row)
	corner(8, iconWrap)
	create("TextLabel", {
		Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Font=FONT,
		Text=data.icon, TextSize=16, TextColor3=Color3.new(1,1,1),
	}, iconWrap)

	create("TextLabel", {
		Position=UDim2.fromOffset(46,5), Size=UDim2.new(1,-160,0,15),
		BackgroundTransparency=1, Font=FONT_BOLD, TextSize=13,
		TextColor3=THEME.Text, TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd, Text=data.name,
	}, row)
	create("TextLabel", {
		Position=UDim2.fromOffset(46,21), Size=UDim2.new(1,-160,0,13),
		BackgroundTransparency=1, Font=FONT, TextSize=11,
		TextColor3=data.color, TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
		Text=string.format("%s  •  %s.%s", data.label, data.className, data.prop),
	}, row)
	create("TextLabel", {
		Position=UDim2.fromOffset(46,35), Size=UDim2.new(1,-160,0,13),
		BackgroundTransparency=1, Font=FONT_MONO, TextSize=10,
		TextColor3=THEME.SubText, TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd, Text=data.path,
	}, row)

	local idBtn = create("TextButton", {
		Name="CopyId", AnchorPoint=Vector2.new(1,0),
		Position=UDim2.new(1,-8,0,8), Size=UDim2.fromOffset(98,22),
		BackgroundColor3=THEME.PanelAlt, BorderSizePixel=0,
		AutoButtonColor=false, Font=FONT_MONO, TextSize=11,
		TextColor3=data.color, Text=data.id, ZIndex=3,
	}, row)
	corner(6, idBtn)
	idBtn.MouseEnter:Connect(function() idBtn.BackgroundColor3 = THEME.Hover end)
	idBtn.MouseLeave:Connect(function() idBtn.BackgroundColor3 = THEME.PanelAlt end)

	create("TextLabel", {
		AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-8,0,34),
		Size=UDim2.fromOffset(98,12), BackgroundTransparency=1, Font=FONT,
		TextSize=10, TextColor3=THEME.SubText,
		TextXAlignment=Enum.TextXAlignment.Right, Text=data.time,
	}, row)

	local record = {
		frame=row, data=data, folder=folder,
		search=string.lower(data.name.." "..data.id.." "..data.className.." "..
			data.prop.." "..data.path.." "..data.label),
	}

	table.insert(folder.entries, record)
	table.insert(allEntries, record)
	folder.count += 1
	folder.countLabel.Text = tostring(folder.count)
	folder.dot.BackgroundColor3 = data.color

	local hoveringIdBtn = false
	idBtn.MouseEnter:Connect(function() hoveringIdBtn = true end)
	idBtn.MouseLeave:Connect(function() hoveringIdBtn = false end)

	row.Activated:Connect(function()
		if hoveringIdBtn then return end
		selectEntry(record)
	end)
	row.MouseEnter:Connect(function()
		if selectedRecord ~= record then row.BackgroundColor3 = THEME.PanelAlt end
	end)
	row.MouseLeave:Connect(function()
		if selectedRecord ~= record then row.BackgroundColor3 = THEME.Panel end
	end)

	idBtn.Activated:Connect(function()
		copyText(data.id)
		idBtn.Text = "✓ Copied"
		task.delay(0.9, function()
			if idBtn.Parent then idBtn.Text = data.id end
		end)
	end)

	while #allEntries > CONFIG.MaxEntries do
		local old = table.remove(allEntries, 1)
		if old == selectedRecord then selectedRecord = nil; updateSendButton() end
		removeEntry(old)
	end
end

--=============================================================================
--  FILTER
--=============================================================================
local filterText = ""
local function applyFilter()
	for _, folder in pairs(folders) do
		local anyVisible = false
		local entries = folder.entries
		for i = 1, #entries do
			local e = entries[i]
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
--  BATCHED SCANNER  (the actual perf fix)
--=============================================================================
local seen = setmetatable({}, {__mode="k"})
local paused = false
local queue = {}

-- Class pre-filter — only queue objects that either hold assets or are containers
local CONTAINER_CLASSES = {Model=true, Folder=true, Tool=true, Accessory=true}

Workspace.DescendantAdded:Connect(function(d)
	if paused or seen[d] then return end

	-- Skip if parent is already queued/seen (it'll be scanned with the parent)
	local p = d.Parent
	if p and seen[p] then return end

	local cls = d.ClassName
	if not (ASSET_PROPS[cls] or CONTAINER_CLASSES[cls] or d:IsA("BasePart")) then
		return
	end

	if CONFIG.IgnoreOwnCharacter then
		local char = LP.Character
		if char and d:IsDescendantOf(char) then return end
	end

	seen[d] = true
	queue[#queue + 1] = d
	if #queue > 500 then
		-- emergency drop — never let the queue blow up
		for i = 1, 200 do queue[i] = nil end
	end
end)

local function collectFrom(inst, out)
	local props = ASSET_PROPS[inst.ClassName]
	if not props then return end
	-- Single pcall wraps the whole loop (fast path)
	local ok = pcall(function()
		for i = 1, #props do
			local prop = props[i]
			local value = inst[prop]
			if type(value) == "string" and value ~= "" then
				local id = extractId(value)
				if id then
					out[#out + 1] = {instance=inst, prop=prop, id=id}
				end
			end
		end
	end)
end

local recentNotify, lastNotifyTime = {}, 0
local function canNotifyId(id)
	local now = os.clock()
	local last = recentNotify[id]
	if last and (now - last) < CONFIG.NotifyPerIdCooldown then return false end
	recentNotify[id] = now
	return true
end
local function canNotifyNow()
	local now = os.clock()
	if (now - lastNotifyTime) < CONFIG.NotifyMinGap then return false end
	lastNotifyTime = now
	return true
end

local function processFound(foundList)
	local byInst, order = {}, {}
	for i = 1, #foundList do
		local info = foundList[i]
		local inst = info.instance
		local b = byInst[inst]
		if b then
			b[#b + 1] = info
		else
			byInst[inst] = {info}
			order[#order + 1] = inst
		end
	end

	for oi = 1, #order do
		local inst = order[oi]
		local infos = byInst[inst]
		for ii = 1, #infos do
			local info = infos[ii]
			local label, icon, color = describe(inst.ClassName, info.prop)
			local d = {
				id=info.id, prop=info.prop, className=inst.ClassName,
				name=inst.Name, path=inst:GetFullName(),
				label=label, icon=icon, color=color,
				time=os.date("%H:%M:%S"),
			}
			addEntry(d)
			if CONFIG.PrintToConsole then
				print(string.format("[Tracker] %s | %s.%s = %s",
					d.name, d.className, d.prop, d.id))
			end
		end

		if CONFIG.NotifyEnabled and not paused then
			local first = infos[1]
			if canNotifyId(first.id) and canNotifyNow() then
				local label, icon = describe(inst.ClassName, first.prop)
				local lines = {}
				local lim = math.min(#infos, CONFIG.NotifyMaxPerSpawn)
				for i = 1, lim do lines[#lines + 1] = infos[i].id end
				local extra = #infos - lim
				local text = inst.Name .. (extra > 0 and ("  (+"..extra.." more)") or "")
				text = text .. "\n" .. table.concat(lines, ", ")
				notify(icon .. " " .. label, text, 4)
			end
		end

		if CONFIG.AutoHighlight then
			highlightInstance(inst, CONFIG.HighlightDuration)
		end
	end
end

-- Background batch processor — this is what makes it fast
task.spawn(function()
	while true do
		task.wait(CONFIG.ScanBatch)
		if paused or #queue == 0 then continue end

		local budget = CONFIG.ScanBudgetPerTick
		local processed = 0
		local found = {}

		while #queue > 0 and processed < budget do
			local inst = table.remove(queue, 1)
			processed += 1
			if inst and inst.Parent then
				-- scan self
				collectFrom(inst, found)
				-- scan descendants (mark them seen so they don't get re-queued)
				local ok, desc = pcall(function() return inst:GetDescendants() end)
				if ok and desc then
					for i = 1, #desc do
						local c = desc[i]
						if not seen[c] then
							seen[c] = true
							collectFrom(c, found)
						end
					end
				end
			end
		end

		if #found > 0 then
			processFound(found)
			updateStats()
		end
	end
end)

--=============================================================================
--  SHOW / HIDE
--=============================================================================
local uiVisible = false
local function setUIVisible(state)
	uiVisible = state
	if state then
		main.Position = UDim2.fromOffset(toggleBtn.AbsolutePosition.X, toggleBtn.AbsolutePosition.Y)
		main.Visible = true
		toggleBtn.Visible = false
	else
		toggleBtn.Position = UDim2.fromOffset(main.AbsolutePosition.X, main.AbsolutePosition.Y)
		main.Visible = false
		toggleBtn.Visible = true
	end
end
toggleBtn.Activated:Connect(function() setUIVisible(true) end)
minimizeBtn.Activated:Connect(function() setUIVisible(false) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CONFIG.ToggleKey then setUIVisible(not uiVisible) end
end)

--=============================================================================
--  TOOLBAR ACTIONS
--=============================================================================
pauseBtn.Activated:Connect(function()
	paused = not paused
	if paused then
		pauseBtn.Text = "▶"
		pauseBtn.BackgroundColor3 = THEME.Warn
		pauseBtn:SetAttribute("RestColor", THEME.Warn)
		pauseBtn.TextColor3 = Color3.fromRGB(30,25,10)
		statusLabel.Text = "❚❚ PAUSED"
		statusLabel.TextColor3 = THEME.Warn
	else
		pauseBtn.Text = "⏸"
		pauseBtn.BackgroundColor3 = THEME.Panel
		pauseBtn:SetAttribute("RestColor", THEME.Panel)
		pauseBtn.TextColor3 = THEME.Text
		statusLabel.Text = "● TRACKING"
		statusLabel.TextColor3 = THEME.Good
	end
end)

clearBtn.Activated:Connect(function()
	for _, f in pairs(folders) do f.container:Destroy() end
	folders = {}; folderOrder = 0
	allEntries = {}; totalFound = 0; entryCounter = 0
	selectedRecord = nil
	queue = {}
	updateSendButton(); updateStats()
end)

notifyBtn.Activated:Connect(function()
	CONFIG.NotifyEnabled = not CONFIG.NotifyEnabled
	if CONFIG.NotifyEnabled then
		notifyBtn.Text = "🔔"
		notifyBtn.BackgroundColor3 = THEME.Panel
		notifyBtn:SetAttribute("RestColor", THEME.Panel)
		notifyBtn.TextColor3 = THEME.Text
	else
		notifyBtn.Text = "🔕"
		notifyBtn.BackgroundColor3 = THEME.PanelAlt
		notifyBtn:SetAttribute("RestColor", THEME.PanelAlt)
		notifyBtn.TextColor3 = THEME.SubText
	end
end)

highlightBtn.Activated:Connect(function()
	CONFIG.AutoHighlight = not CONFIG.AutoHighlight
	if CONFIG.AutoHighlight then
		highlightBtn.Text = "🎯"
		highlightBtn.BackgroundColor3 = THEME.Panel
		highlightBtn:SetAttribute("RestColor", THEME.Panel)
		highlightBtn.TextColor3 = THEME.Text
	else
		highlightBtn.Text = "🚫"
		highlightBtn.BackgroundColor3 = THEME.PanelAlt
		highlightBtn:SetAttribute("RestColor", THEME.PanelAlt)
		highlightBtn.TextColor3 = THEME.SubText
	end
end)

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
			notify("✅ Sent", "Forwarded to channel: "..API.Channel, 3)
		else
			sendBtn.Text = "✕"
			sendBtn.TextColor3 = THEME.Danger
			notify("❌ Send failed", tostring(resp and resp.StatusMessage or resp), 5)
		end
		task.wait(1.2)
		if sendBtn.Parent then
			sendBtn.Text = "📤"
			sendBtn.TextColor3 = selectedRecord and Color3.new(1,1,1) or THEME.SubText
		end
	end)
end)

closeBtn.Activated:Connect(function()
	pcall(function() screen:Destroy() end)
end)

if CONFIG.StartHidden then
	uiVisible = false
	main.Visible = false
	toggleBtn.Visible = true
else
	setUIVisible(true)
end

updateSendButton()
updateStats()
applyFilter()

print("[AssetTracker v2.4] loaded — click 🔍 or press RightShift")
