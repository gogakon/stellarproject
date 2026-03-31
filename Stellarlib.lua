-- STELLAR UI Library (Optimized)
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

-- Cleanup previous instances
for _, name in ipairs({"STELLAR", "ScreenGui"}) do
	local obj = CoreGui:FindFirstChild(name)
	if obj then obj:Destroy() end
end

-- Theme
_G.Primary = Color3.fromRGB(100, 100, 100)
_G.Dark    = Color3.fromRGB(22, 22, 26)
_G.Third   = Color3.fromRGB(255, 0, 0)

-- Helpers
local function Round(parent, size)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, size)
	c.Parent = parent
end

local function Tween(obj, t, props, style, dir)
	return TS:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

local function New(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end

local function MakeDraggable(handle, frame)
	local dragging, dragInput, dragStart, startPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = i.Position
			startPos = frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			dragInput = i
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if i == dragInput and dragging then
			local d = i.Position - dragStart
			Tween(frame, 0.15, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)}):Play()
		end
	end)
end

-- Toggle Button (floating icon)
local ToggleGui = New("ScreenGui", {Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local ToggleFrame = New("Frame", {
	Name = "OutlineButton", ClipsDescendants = true,
	BackgroundColor3 = _G.Dark, Position = UDim2.new(0,10,0,10), Size = UDim2.new(0,50,0,50)
}, ToggleGui)
Round(ToggleFrame, 12)

local ToggleBtn = New("ImageButton", {
	BackgroundColor3 = _G.Dark, ImageColor3 = Color3.fromRGB(250,250,250),
	Image = "rbxassetid://105059922903197", AutoButtonColor = false,
	AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0,40,0,40)
}, ToggleFrame)
Round(ToggleBtn, 10)
MakeDraggable(ToggleBtn, ToggleFrame)
ToggleBtn.MouseButton1Click:Connect(function()
	local s = CoreGui:FindFirstChild("STELLAR")
	if s then s.Enabled = not s.Enabled end
end)

-- Notifications
local NotifGui = New("ScreenGui", {Name = "NotificationFrame", Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Global})
local NotifList = {}

local function RemoveOldest()
	if #NotifList > 0 then
		local f = table.remove(NotifList, 1)
		f:TweenPosition(UDim2.new(0.5,0,-0.2,0), "Out", "Quad", 0.4, true, function() f:Destroy() end)
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		if #NotifList > 0 then RemoveOldest() end
	end
end)

-- Config persistence
local SettingsLib = {SaveSettings = true, LoadAnimation = true}
local cfgPath = "STELLAR/Library/" .. LocalPlayer.Name .. ".json"

getgenv().LoadConfig = function()
	if not (readfile and writefile and isfile and isfolder) then return warn("Status: Undetected Executor") end
	if not isfolder("STELLAR") then makefolder("STELLAR") end
	if not isfolder("STELLAR/Library/") then makefolder("STELLAR/Library/") end
	if isfile(cfgPath) then
		for k, v in pairs(HttpService:JSONDecode(readfile(cfgPath))) do SettingsLib[k] = v end
	else
		writefile(cfgPath, HttpService:JSONEncode(SettingsLib))
	end
end

getgenv().SaveConfig = function()
	if not (readfile and writefile and isfile and isfolder) then return warn("Status: Undetected Executor") end
	if not isfile(cfgPath) then getgenv().LoadConfig() return end
	writefile(cfgPath, HttpService:JSONEncode(SettingsLib))
end

getgenv().LoadConfig()

-- Main library
local Update = {}

function Update:Notify(desc)
	local outline = New("Frame", {
		Name = "OutlineFrame", ClipsDescendants = true,
		BackgroundColor3 = Color3.fromRGB(30,30,30), BackgroundTransparency = 0.4,
		AnchorPoint = Vector2.new(0.5,1), Position = UDim2.new(0.5,0,-0.2,0),
		Size = UDim2.new(0,412,0,72)
	}, NotifGui)
	Round(outline, 12)

	local inner = New("Frame", {
		Name = "Frame", ClipsDescendants = true, BackgroundColor3 = _G.Dark, BackgroundTransparency = 0.1,
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0,400,0,60)
	}, outline)
	Round(inner, 10)

	New("ImageLabel", {BackgroundTransparency=1, Position=UDim2.new(0,8,0,8), Size=UDim2.new(0,45,0,45), Image="rbxassetid://105059922903197"}, inner)
	New("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0,55,0,14), Size=UDim2.new(0,10,0,20), Font=Enum.Font.GothamBold, Text="STELLAR", TextColor3=Color3.fromRGB(255,255,255), TextSize=16, TextXAlignment=Enum.TextXAlignment.Left}, inner)
	New("TextLabel", {BackgroundTransparency=1, Position=UDim2.new(0,55,0,33), Size=UDim2.new(0,10,0,10), Font=Enum.Font.GothamSemibold, Text=desc, TextColor3=Color3.fromRGB(200,200,200), TextTransparency=0.3, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, inner)

	outline:TweenPosition(UDim2.new(0.5,0, 0.1 + #NotifList * 0.1, 0), "Out", "Quad", 0.4, true)
	table.insert(NotifList, outline)
end

function Update:StartLoad()
	local Loader = New("ScreenGui", {Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 1000})
	local bg = New("Frame", {BackgroundColor3=Color3.fromRGB(5,5,5), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(1.5,0,1.5,0), BorderSizePixel=0}, Loader)
	local panel = New("Frame", {BackgroundColor3=Color3.fromRGB(5,5,5), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0.5,0,0.5,0), BorderSizePixel=0}, bg)

	New("TextLabel", {Text="STELLAR", Font=Enum.Font.FredokaOne, TextSize=50, TextColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.3,0), Size=UDim2.new(0.8,0,0.2,0)}, panel)
	local statusLabel = New("TextLabel", {Text="Please wait...", Font=Enum.Font.Gotham, TextSize=15, TextColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.6,0), Size=UDim2.new(0.8,0,0.2,0)}, panel)

	local barBg = New("Frame", {BackgroundColor3=Color3.fromRGB(50,50,50), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.7,0), Size=UDim2.new(0.7,0,0.05,0), ClipsDescendants=true, BorderSizePixel=0, ZIndex=2}, panel)
	local bar = New("Frame", {BackgroundColor3=Color3.fromRGB(255,0,0), Size=UDim2.new(0,0,1,0), ZIndex=3}, barBg)
	Round(barBg, 20); Round(bar, 20)

	local t1 = TS:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size=UDim2.new(0.25,0,1,0)})
	local t2 = TS:Create(bar, TweenInfo.new(1, Enum.EasingStyle.Linear), {Size=UDim2.new(1,0,1,0)})

	function Update:Loaded() t2:Play() end

	t1:Play()
	local running = true
	t1.Completed:Connect(function()
		t2.Completed:Connect(function()
			running = false
			statusLabel.Text = "Loaded!"
			task.wait(0.5)
			Loader:Destroy()
		end)
	end)

	task.spawn(function()
		local dots = 0
		while running do
			dots = (dots + 1) % 4
			statusLabel.Text = "Please wait" .. string.rep(".", dots)
			task.wait(0.5)
		end
	end)
end

function Update:SaveSettings() return SettingsLib.SaveSettings end
function Update:LoadAnimation() return SettingsLib.LoadAnimation end

function Update:Window(Config)
	assert(Config.SubTitle, "v4")
	local WSize = Config.Size
	local TabW = Config.TabWidth
	local abc, currentPage = false, ""

	local STELLAR = New("ScreenGui", {Name="STELLAR", Parent=CoreGui, DisplayOrder=999})

	local OutlineMain = New("Frame", {
		Name="OutlineMain", ClipsDescendants=true, AnchorPoint=Vector2.new(0.5,0.5),
		BackgroundColor3=Color3.fromRGB(30,30,30), BackgroundTransparency=0.4,
		Position=UDim2.new(0.5,0,0.45,0), Size=UDim2.new(0,0,0,0)
	}, STELLAR)
	Round(OutlineMain, 15)
	OutlineMain:TweenSize(UDim2.new(0, WSize.X.Offset+15, 0, WSize.Y.Offset+15), "Out", "Quad", 0.4, true)

	local Main = New("Frame", {
		Name="Main", ClipsDescendants=true, AnchorPoint=Vector2.new(0.5,0.5),
		BackgroundColor3=Color3.fromRGB(24,24,26), Position=UDim2.new(0.5,0,0.5,0), Size=WSize
	}, OutlineMain)
	Round(Main, 12)

	-- Resize handle
	local DragButton = New("Frame", {
		Name="DragButton", Position=UDim2.new(1,5,1,5), AnchorPoint=Vector2.new(1,1),
		Size=UDim2.new(0,15,0,15), BackgroundColor3=_G.Primary, BackgroundTransparency=1, ZIndex=10
	}, Main)
	New("UICorner", {CornerRadius=UDim.new(0,99)}, DragButton)

	-- Top bar
	local Top = New("Frame", {Name="Top", BackgroundColor3=Color3.fromRGB(10,10,10), BackgroundTransparency=1, Size=UDim2.new(1,0,0,40)}, Main)
	Round(Top, 5)

	local hubText = "STELLAR"
	local hubSize = TextService:GetTextSize(hubText, 20, Enum.Font.GothamBold, Vector2.new(math.huge, math.huge))
	local NameHub = New("TextLabel", {
		Name="NameHub", BackgroundTransparency=1, RichText=true,
		Position=UDim2.new(0,15,0.5,0), AnchorPoint=Vector2.new(0,0.5), Size=UDim2.new(0,hubSize.X,0,25),
		Font=Enum.Font.GothamBold, Text=hubText, TextSize=20,
		TextColor3=Color3.fromRGB(255,255,255), TextXAlignment=Enum.TextXAlignment.Left
	}, Top)

	local subSize = TextService:GetTextSize(Config.SubTitle, 15, Enum.Font.Cartoon, Vector2.new(math.huge, math.huge))
	New("TextLabel", {
		Name="SubTitle", BackgroundTransparency=1,
		Position=UDim2.new(0, hubSize.X+8, 0.5, 0), AnchorPoint=Vector2.new(0,0.5),
		Size=UDim2.new(0,subSize.X,0,25), Font=Enum.Font.Cartoon,
		Text=Config.SubTitle, TextSize=15, TextColor3=Color3.fromRGB(150,150,150)
	}, NameHub)

	-- Top buttons helper
	local function TopBtn(img, xOff)
		local b = New("ImageButton", {
			BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5),
			Position=UDim2.new(1,xOff,0.5,0), Size=UDim2.new(0,20,0,20),
			Image=img, ImageColor3=Color3.fromRGB(245,245,245)
		}, Top)
		Round(b, 3)
		return b
	end

	local CloseButton   = TopBtn("rbxassetid://7743878857", -15)
	local ResizeButton  = TopBtn("rbxassetid://10734886735", -50)
	local SettingsButton = TopBtn("rbxassetid://10734950020", -85)

	CloseButton.MouseButton1Click:Connect(function()
		local s = CoreGui:FindFirstChild("STELLAR")
		if s then s.Enabled = not s.Enabled end
	end)

	-- Settings overlay
	local BgSettings = New("Frame", {
		Name="BackgroundSettings", ClipsDescendants=true, Active=true,
		BackgroundColor3=Color3.fromRGB(10,10,10), BackgroundTransparency=0.3,
		Size=UDim2.new(1,0,1,0), Visible=false
	}, OutlineMain)
	Round(BgSettings, 15)

	local SettingsFrame = New("Frame", {
		Name="SettingsFrame", ClipsDescendants=true,
		BackgroundColor3=Color3.fromRGB(24,24,26),
		AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0.7,0,0.7,0)
	}, BgSettings)
	Round(SettingsFrame, 15)

	New("TextLabel", {
		BackgroundTransparency=1, Position=UDim2.new(0,20,0,15), Size=UDim2.new(1,0,0,20),
		Font=Enum.Font.GothamBold, Text="Library Settings", TextSize=20,
		TextColor3=Color3.fromRGB(245,245,245), TextXAlignment=Enum.TextXAlignment.Left
	}, SettingsFrame)

	local CloseSettings = New("ImageButton", {
		BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0),
		Position=UDim2.new(1,-20,0,15), Size=UDim2.new(0,20,0,20),
		Image="rbxassetid://10747384394", ImageColor3=Color3.fromRGB(245,245,245)
	}, SettingsFrame)
	Round(CloseSettings, 3)
	CloseSettings.MouseButton1Click:Connect(function() BgSettings.Visible = false end)
	SettingsButton.MouseButton1Click:Connect(function() BgSettings.Visible = true end)

	local SettingsMenuList = New("Frame", {
		Name="SettingsMenuList", ClipsDescendants=true,
		BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(24,24,26),
		Position=UDim2.new(0,0,0,50), Size=UDim2.new(1,0,1,-70)
	}, SettingsFrame)
	Round(SettingsMenuList, 5)

	local ScrollSettings = New("ScrollingFrame", {
		Name="ScrollSettings", Active=true, BackgroundTransparency=1,
		Size=UDim2.new(1,0,1,0), ScrollBarThickness=3, ScrollingDirection=Enum.ScrollingDirection.Y
	}, SettingsMenuList)
	local SettingsListLayout = New("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8)}, ScrollSettings)
	New("UIPadding", {}, ScrollSettings)

	-- Settings components
	local function CreateCheckbox(title, state, callback)
		local checked = state or false
		local bg = New("Frame", {Name="Background", ClipsDescendants=true, BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(24,24,26), Size=UDim2.new(1,0,0,20)}, ScrollSettings)
		New("TextLabel", {
			BackgroundTransparency=1, Position=UDim2.new(0,60,0.5,0), Size=UDim2.new(1,-60,0,20),
			Font=Enum.Font.Code, AnchorPoint=Vector2.new(0,0.5), Text=title or "", TextSize=15,
			TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Left
		}, bg)
		local cb = New("ImageButton", {
			Name="Checkbox", BackgroundColor3=Color3.fromRGB(100,100,100),
			AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,30,0.5,0), Size=UDim2.new(0,20,0,20),
			Image="rbxassetid://10709790644", ImageTransparency=1, ImageColor3=Color3.fromRGB(245,245,245)
		}, bg)
		Round(cb, 5)
		local function refresh()
			cb.ImageTransparency = checked and 0 or 1
			cb.BackgroundColor3 = checked and Color3.fromRGB(255,0,0) or Color3.fromRGB(100,100,100)
		end
		refresh(); pcall(callback, checked)
		cb.MouseButton1Click:Connect(function()
			checked = not checked; refresh(); pcall(callback, checked)
		end)
	end

	local function CreateSettingsButton(title, callback)
		local bg = New("Frame", {Name="Background", ClipsDescendants=true, BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(24,24,26), Size=UDim2.new(1,0,0,30)}, ScrollSettings)
		local btn = New("TextButton", {
			Name="Button", BackgroundColor3=Color3.fromRGB(255,0,0),
			Size=UDim2.new(0.8,0,0,30), Font=Enum.Font.Code, Text=title or "Button",
			AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,0),
			TextColor3=Color3.fromRGB(255,255,255), TextSize=15, AutoButtonColor=false
		}, bg)
		Round(btn, 5)
		btn.MouseButton1Click:Connect(callback)
	end

	CreateCheckbox("Save Settings", SettingsLib.SaveSettings, function(s) SettingsLib.SaveSettings=s; getgenv().SaveConfig() end)
	CreateCheckbox("Loading Animation", SettingsLib.LoadAnimation, function(s) SettingsLib.LoadAnimation=s; getgenv().SaveConfig() end)
	CreateSettingsButton("Reset Config", function()
		if isfolder("STELLAR") then delfolder("STELLAR") end
		Update:Notify("Config has been reset!")
	end)

	-- Tab sidebar
	local Tab = New("Frame", {
		Name="Tab", BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(45,45,45),
		Position=UDim2.new(0,8,0,Top.Size.Y.Offset),
		Size=UDim2.new(0,TabW, Config.Size.Y.Scale, Config.Size.Y.Offset - Top.Size.Y.Offset - 8)
	}, Main)
	Round(Tab, 5)

	local ScrollTab = New("ScrollingFrame", {
		Name="ScrollTab", Active=true, BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(10,10,10),
		Size=UDim2.new(1,0,1,0), ScrollBarThickness=0, ScrollingDirection=Enum.ScrollingDirection.Y
	}, Tab)
	local TabListLayout = New("UIListLayout", {Name="TabListLayout", SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2)}, ScrollTab)
	New("UIPadding", {Name="PPD"}, ScrollTab)

	-- Page area
	local Page = New("Frame", {
		Name="Page", BackgroundColor3=_G.Dark, BackgroundTransparency=1,
		Position=UDim2.new(0, TabW+18, 0, Top.Size.Y.Offset),
		Size=UDim2.new(Config.Size.X.Scale, Config.Size.X.Offset-TabW-25, Config.Size.Y.Scale, Config.Size.Y.Offset-Top.Size.Y.Offset-8)
	}, Main)
	Round(Page, 3)

	local MainPage = New("Frame", {Name="MainPage", ClipsDescendants=true, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0)}, Page)
	New("UICorner", {CornerRadius=UDim.new(0,5)}, MainPage)

	local PageList = New("Folder", {Name="PageList"}, MainPage)
	local UIPageLayout = New("UIPageLayout", {
		SortOrder=Enum.SortOrder.LayoutOrder, EasingDirection=Enum.EasingDirection.InOut,
		EasingStyle=Enum.EasingStyle.Quad, FillDirection=Enum.FillDirection.Vertical,
		Padding=UDim.new(0,10), TweenTime=0,
		GamepadInputEnabled=false, ScrollWheelInputEnabled=false, TouchInputEnabled=false
	}, PageList)

	MakeDraggable(Top, OutlineMain)

	UIS.InputBegan:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Insert then
			local s = CoreGui:FindFirstChild("STELLAR")
			if s then s.Enabled = not s.Enabled end
		end
	end)

	-- Resize drag
	local resizeDragging = false
	DragButton.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then resizeDragging = true end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then resizeDragging = false end
	end)
	UIS.InputChanged:Connect(function(i)
		if resizeDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local nx = math.clamp(i.Position.X - Main.AbsolutePosition.X, WSize.X.Offset, math.huge)
			local ny = math.clamp(i.Position.Y - Main.AbsolutePosition.Y, WSize.Y.Offset, math.huge)
			OutlineMain.Size = UDim2.new(0, nx+15, 0, ny+15)
			Main.Size = UDim2.new(0, nx, 0, ny)
			Page.Size = UDim2.new(0, math.clamp(i.Position.X - Page.AbsolutePosition.X - 8, WSize.X.Offset-TabW-25, math.huge), 0, math.clamp(i.Position.Y - Page.AbsolutePosition.Y - 8, WSize.Y.Offset-Top.Size.Y.Offset-10, math.huge))
			Tab.Size = UDim2.new(0, TabW, 0, math.clamp(i.Position.Y - Tab.AbsolutePosition.Y - 8, WSize.Y.Offset-Top.Size.Y.Offset-10, math.huge))
		end
	end)

	local uitab = {}

	function uitab:Tab(text, img)
		local TabButton = New("TextButton", {
			Name=text.."Unique", Text="", BackgroundColor3=Color3.fromRGB(100,100,100), BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,35), Font=Enum.Font.Nunito, TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.9
		}, ScrollTab)
		Round(TabButton, 6)

		local SelectedTab = New("Frame", {
			Name="SelectedTab", BackgroundColor3=_G.Third, Size=UDim2.new(0,3,0,0),
			Position=UDim2.new(0,0,0.5,0), AnchorPoint=Vector2.new(0,0.5)
		}, TabButton)
		New("UICorner", {CornerRadius=UDim.new(0,100)}, SelectedTab)

		local Title = New("TextLabel", {
			Name="Title", BackgroundTransparency=1, Position=UDim2.new(0,30,0.5,0), AnchorPoint=Vector2.new(0,0.5),
			Size=UDim2.new(0,100,0,30), Font=Enum.Font.Roboto, Text=text,
			TextColor3=Color3.fromRGB(255,255,255), TextTransparency=0.4, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left
		}, TabButton)

		local IDK = New("ImageLabel", {
			Name="IDK", BackgroundTransparency=1, ImageTransparency=0.3,
			Position=UDim2.new(0,7,0.5,0), AnchorPoint=Vector2.new(0,0.5), Size=UDim2.new(0,15,0,15), Image=img
		}, TabButton)

		local MainFramePage = New("ScrollingFrame", {
			Name=text.."_Page", Active=true, BackgroundTransparency=1, BackgroundColor3=_G.Dark,
			Size=UDim2.new(1,0,1,0), ScrollBarThickness=0, ScrollingDirection=Enum.ScrollingDirection.Y
		}, PageList)
		New("UIPadding", {}, MainFramePage)
		local UIListLayout = New("UIListLayout", {Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder}, MainFramePage)

		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local function selectTab()
			for _, v in next, ScrollTab:GetChildren() do
				if v:IsA("TextButton") then
					Tween(v, 0.3, {BackgroundTransparency=1}):Play()
					Tween(v.SelectedTab, 0, {Size=UDim2.new(0,3,0,0)}):Play()
					Tween(v.IDK, 0.3, {ImageTransparency=0.4}):Play()
					Tween(v.Title, 0.3, {TextTransparency=0.4}):Play()
				end
			end
			Tween(TabButton, 0.3, {BackgroundTransparency=0.8}):Play()
			Tween(SelectedTab, 0.3, {Size=UDim2.new(0,3,0,15)}):Play()
			Tween(IDK, 0.3, {ImageTransparency=0}):Play()
			Tween(Title, 0.3, {TextTransparency=0}):Play()
		end

		TabButton.MouseButton1Click:Connect(function()
			selectTab()
			currentPage = text.."_Page"
			for _, v in next, PageList:GetChildren() do
				if v.Name == currentPage then UIPageLayout:JumpTo(v) break end
			end
		end)

		if not abc then selectTab(); UIPageLayout:JumpToIndex(1); abc = true end

		game:GetService("RunService").Stepped:Connect(function()
			pcall(function()
				MainFramePage.CanvasSize = UDim2.new(0,0,0, UIListLayout.AbsoluteContentSize.Y)
				ScrollTab.CanvasSize = UDim2.new(0,0,0, TabListLayout.AbsoluteContentSize.Y)
				ScrollSettings.CanvasSize = UDim2.new(0,0,0, SettingsListLayout.AbsoluteContentSize.Y)
			end)
		end)

		-- Fullscreen toggle
		local defaultSize = true
		ResizeButton.MouseButton1Click:Connect(function()
			defaultSize = not defaultSize
			if not defaultSize then
				OutlineMain:TweenPosition(UDim2.new(0.5,0,0.45,0),"Out","Quad",0.2,true)
				Main:TweenSize(UDim2.new(1,0,1,0),"Out","Quad",0.4,true,function()
					Page:TweenSize(UDim2.new(0,Main.AbsoluteSize.X-Tab.AbsoluteSize.X-25,0,Main.AbsoluteSize.Y-Top.AbsoluteSize.Y-10),"Out","Quad",0.4,true)
					Tab:TweenSize(UDim2.new(0,TabW,0,Main.AbsoluteSize.Y-Top.AbsoluteSize.Y-10),"Out","Quad",0.4,true)
				end)
				OutlineMain:TweenSize(UDim2.new(1,-10,1,-10),"Out","Quad",0.4,true)
				ResizeButton.Image = "rbxassetid://10734895698"
			else
				Main:TweenSize(UDim2.new(0,WSize.X.Offset,0,WSize.Y.Offset),"Out","Quad",0.4,true,function()
					Page:TweenSize(UDim2.new(0,Main.AbsoluteSize.X-Tab.AbsoluteSize.X-25,0,Main.AbsoluteSize.Y-Top.AbsoluteSize.Y-10),"Out","Quad",0.4,true)
					Tab:TweenSize(UDim2.new(0,TabW,0,Main.AbsoluteSize.Y-Top.AbsoluteSize.Y-10),"Out","Quad",0.4,true)
				end)
				OutlineMain:TweenSize(UDim2.new(0,WSize.X.Offset+15,0,WSize.Y.Offset+15),"Out","Quad",0.4,true)
				ResizeButton.Image = "rbxassetid://10734886735"
			end
		end)

		local main = {}

		function main:Button(text, callback)
			local btn = New("Frame", {Name="Button", BackgroundTransparency=1, BackgroundColor3=_G.Primary, Size=UDim2.new(1,0,0,36)}, MainFramePage)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, btn)

			local label = New("TextLabel", {
				Name="TextLabel", BackgroundTransparency=1, BackgroundColor3=_G.Primary,
				AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,20,0.5,0), Size=UDim2.new(1,-50,1,0),
				Font=Enum.Font.Cartoon, RichText=true, Text=text,
				TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Color3.fromRGB(255,255,255), TextSize=15, ClipsDescendants=true
			}, btn)
			New("ImageLabel", {
				Name="ArrowRight", BackgroundTransparency=1, AnchorPoint=Vector2.new(0,0.5),
				Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(0,15,0,15),
				Image="rbxassetid://10709768347", ImageColor3=Color3.fromRGB(255,255,255)
			}, btn)

			local clickBtn = New("TextButton", {
				Name="TextButton", BackgroundColor3=Color3.fromRGB(200,200,200), BackgroundTransparency=0.8,
				AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-1,0.5,0), Size=UDim2.new(0,25,0,25),
				Font=Enum.Font.Nunito, Text="", TextColor3=Color3.fromRGB(255,255,255), TextSize=15, AutoButtonColor=false
			}, btn)
			Round(clickBtn, 4)
			New("ImageLabel", {
				BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
				Size=UDim2.new(0,15,0,15), Image="rbxassetid://10734898355", ImageColor3=Color3.fromRGB(255,255,255)
			}, clickBtn)
			clickBtn.MouseButton1Click:Connect(callback)
		end

		function main:Toggle(text, config, desc, callback)
			config = config or false
			local toggled = config
			local btn = New("TextButton", {
				Name="Button", BackgroundColor3=_G.Primary, BackgroundTransparency=0.8,
				AutoButtonColor=false, Font=Enum.Font.SourceSans, Text="", TextColor3=Color3.fromRGB(0,0,0), TextSize=11
			}, MainFramePage)
			Round(btn, 5)

			local titleLabel = New("TextLabel", {
				BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(150,150,150),
				Font=Enum.Font.Cartoon, Text=text, TextColor3=Color3.fromRGB(255,255,255), TextSize=15,
				TextXAlignment=Enum.TextXAlignment.Left, AnchorPoint=Vector2.new(0,0.5)
			}, btn)
			local descLabel = New("TextLabel", {
				BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(100,100,100),
				Size=UDim2.new(0,280,0,16), Font=Enum.Font.Gotham,
				TextColor3=Color3.fromRGB(150,150,150), TextSize=10, TextXAlignment=Enum.TextXAlignment.Left
			}, titleLabel)

			if desc then
				titleLabel.Size = UDim2.new(1,0,0,35)
				titleLabel.Position = UDim2.new(0,15,0.5,-5)
				descLabel.Text = desc
				descLabel.Position = UDim2.new(0,0,0,22)
				btn.Size = UDim2.new(1,0,0,46)
			else
				titleLabel.Size = UDim2.new(1,0,0,35)
				titleLabel.Position = UDim2.new(0,15,0.5,0)
				descLabel.Visible = false
				btn.Size = UDim2.new(1,0,0,36)
			end

			local toggleFrame = New("Frame", {
				Name="ToggleFrame", BackgroundColor3=_G.Dark, BackgroundTransparency=1,
				Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,35,0,20), AnchorPoint=Vector2.new(1,0.5)
			}, btn)
			New("UICorner", {CornerRadius=UDim.new(0,10)}, toggleFrame)

			local toggleImg = New("TextButton", {
				Name="ToggleImage", BackgroundColor3=Color3.fromRGB(200,200,200), BackgroundTransparency=0.8,
				Size=UDim2.new(1,0,1,0), Text="", AutoButtonColor=false
			}, toggleFrame)
			Round(toggleImg, 10)

			local circle = New("Frame", {
				Name="Circle", BackgroundColor3=Color3.fromRGB(255,255,255),
				Position=UDim2.new(0,3,0.5,0), Size=UDim2.new(0,14,0,14), AnchorPoint=Vector2.new(0,0.5)
			}, toggleImg)
			New("UICorner", {CornerRadius=UDim.new(0,10)}, circle)

			local function setToggle(state)
				toggled = state
				if state then
					circle:TweenPosition(UDim2.new(0,17,0.5,0),"Out","Sine",0.2,true)
					Tween(toggleImg, 0.4, {BackgroundColor3=_G.Third, BackgroundTransparency=0}):Play()
				else
					circle:TweenPosition(UDim2.new(0,4,0.5,0),"Out","Sine",0.2,true)
					Tween(toggleImg, 0.4, {BackgroundColor3=Color3.fromRGB(200,200,200), BackgroundTransparency=0.8}):Play()
				end
			end

			toggleImg.MouseButton1Click:Connect(function()
				setToggle(not toggled)
				pcall(callback, toggled)
			end)

			if config then setToggle(true); pcall(callback, true) end
		end

		function main:Dropdown(text, options, default, callback)
			local isdropping = false
			local activeItem = default and tostring(default) or nil

			local drop = New("Frame", {
				Name="Dropdown", BackgroundColor3=_G.Primary, BackgroundTransparency=0.8,
				ClipsDescendants=false, Size=UDim2.new(1,0,0,40)
			}, MainFramePage)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, drop)

			New("TextLabel", {
				Name="DropTitle", BackgroundTransparency=1, BackgroundColor3=_G.Primary,
				Size=UDim2.new(1,0,0,30), Font=Enum.Font.Cartoon, Text=text,
				TextColor3=Color3.fromRGB(255,255,255), TextSize=15, TextXAlignment=Enum.TextXAlignment.Left,
				Position=UDim2.new(0,15,0,5)
			}, drop)

			local selectBtn = New("TextButton", {
				Name="SelectItems", BackgroundColor3=Color3.fromRGB(24,24,26), TextColor3=Color3.fromRGB(255,255,255),
				Position=UDim2.new(1,-5,0,5), Size=UDim2.new(0,100,0,30), AnchorPoint=Vector2.new(1,0),
				Font=Enum.Font.GothamMedium, AutoButtonColor=false, TextSize=9, ZIndex=1, ClipsDescendants=true,
				Text = activeItem and ("   "..activeItem) or "   Select Items", TextXAlignment=Enum.TextXAlignment.Left
			}, drop)
			Round(selectBtn, 5)

			New("ImageLabel", {
				Name="ArrowDown", BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0),
				Position=UDim2.new(1,-110,0,10), Size=UDim2.new(0,20,0,20),
				Image="rbxassetid://10709790948", ImageColor3=Color3.fromRGB(255,255,255)
			}, drop)
			local ArrowDown = drop:FindFirstChild("ArrowDown")

			local dropFrame = New("Frame", {
				Name="DropdownFrameScroll", BackgroundColor3=Color3.fromRGB(24,24,26), ClipsDescendants=true,
				Size=UDim2.new(1,0,0,100), Position=UDim2.new(0,5,0,40), Visible=false
			}, drop)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, dropFrame)

			local dropScroll = New("ScrollingFrame", {
				Name="DropScroll", ScrollingDirection=Enum.ScrollingDirection.Y, Active=true,
				BackgroundTransparency=1, BorderSizePixel=0,
				Position=UDim2.new(0,0,0,10), Size=UDim2.new(1,0,0,80), ClipsDescendants=true, ScrollBarThickness=3, ZIndex=3
			}, dropFrame)
			local ddPad = New("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)}, dropScroll)
			local ddLayout = New("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,1)}, dropScroll)
			New("UIPadding", {PaddingLeft=UDim.new(0,5)}, dropScroll)

			local function updateSelection(selected)
				for _, v in next, dropScroll:GetChildren() do
					if v:IsA("TextButton") then
						local si = v:FindFirstChild("SelectedItems")
						local isMatch = selected == v.Text
						v.BackgroundTransparency = isMatch and 0.8 or 1
						v.TextTransparency = isMatch and 0 or 0.5
						if si then si.BackgroundTransparency = isMatch and 0 or 1 end
					end
				end
				selectBtn.Text = "   " .. selected
				activeItem = selected
			end

			local function addItem(t)
				local item = New("TextButton", {
					Name="Item", BackgroundColor3=_G.Primary, BackgroundTransparency=1,
					Size=UDim2.new(1,0,0,30), Font=Enum.Font.Nunito, Text=tostring(t),
					TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
					TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4
				}, dropScroll)
				New("UIPadding", {PaddingLeft=UDim.new(0,8)}, item)
				New("UICorner", {CornerRadius=UDim.new(0,5)}, item)
				local si = New("Frame", {
					Name="SelectedItems", BackgroundColor3=_G.Third, BackgroundTransparency=1,
					Size=UDim2.new(0,3,0.4,0), Position=UDim2.new(0,-8,0.5,0), AnchorPoint=Vector2.new(0,0.5), ZIndex=4
				}, item)
				New("UICorner", {CornerRadius=UDim.new(0,999)}, si)
				item.MouseButton1Click:Connect(function()
					callback(item.Text)
					updateSelection(item.Text)
				end)
				return item
			end

			for _, v in next, options do addItem(v) end
			if default then pcall(callback, default); updateSelection(tostring(default)) end
			dropScroll.CanvasSize = UDim2.new(0,0,0, ddLayout.AbsoluteContentSize.Y)

			selectBtn.MouseButton1Click:Connect(function()
				isdropping = not isdropping
				if isdropping then
					Tween(dropFrame, 0.3, {Size=UDim2.new(1,-10,0,100)}):Play()
					dropFrame.Visible = true
					Tween(drop, 0.3, {Size=UDim2.new(1,0,0,145)}):Play()
					Tween(ArrowDown, 0.3, {Rotation=180}):Play()
				else
					Tween(dropFrame, 0.3, {Size=UDim2.new(1,-10,0,0)}):Play()
					dropFrame.Visible = false
					Tween(drop, 0.3, {Size=UDim2.new(1,0,0,40)}):Play()
					Tween(ArrowDown, 0.3, {Rotation=0}):Play()
				end
			end)

			local dropfunc = {}
			function dropfunc:Add(t) addItem(t) end
			function dropfunc:Clear()
				selectBtn.Text = "   Select Items"
				isdropping = false; dropFrame.Visible = false
				for _, v in next, dropScroll:GetChildren() do
					if v:IsA("TextButton") then v:Destroy() end
				end
			end
			return dropfunc
		end

		function main:Slider(text, min, max, set, callback)
			local Value = set
			local sl = New("Frame", {Name="Slider", BackgroundTransparency=1, BackgroundColor3=_G.Primary, Size=UDim2.new(1,0,0,35)}, MainFramePage)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, sl)

			local inner = New("Frame", {
				Name="sliderr", BackgroundColor3=_G.Primary, BackgroundTransparency=0.8,
				Size=UDim2.new(1,0,0,35)
			}, sl)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, inner)

			New("TextLabel", {
				BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(150,150,150),
				Position=UDim2.new(0,15,0.5,0), AnchorPoint=Vector2.new(0,0.5), Size=UDim2.new(1,0,0,30),
				Font=Enum.Font.Cartoon, Text=text, TextColor3=Color3.fromRGB(255,255,255), TextSize=15, TextXAlignment=Enum.TextXAlignment.Left
			}, inner)

			local bar = New("Frame", {
				Name="bar", BackgroundColor3=Color3.fromRGB(200,200,200), BackgroundTransparency=0.8,
				Size=UDim2.new(0,100,0,4), Position=UDim2.new(1,-10,0.5,0), AnchorPoint=Vector2.new(1,0.5)
			}, inner)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, bar)

			local valLabel = New("TextLabel", {
				BackgroundTransparency=1, Position=UDim2.new(0,-38,0.5,0), AnchorPoint=Vector2.new(0,0.5),
				Size=UDim2.new(0,30,0,30), Font=Enum.Font.GothamMedium, Text=tostring(set),
				TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextXAlignment=Enum.TextXAlignment.Right
			}, bar)

			local bar1 = New("Frame", {
				Name="bar1", BackgroundColor3=_G.Third, BackgroundTransparency=0, Size=UDim2.new(set/max,0,0,4)
			}, bar)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, bar1)

			local circle = New("Frame", {
				Name="circlebar", BackgroundColor3=Color3.fromRGB(255,255,255),
				Position=UDim2.new(1,0,0,-5), AnchorPoint=Vector2.new(0.5,0), Size=UDim2.new(0,13,0,13)
			}, bar1)
			New("UICorner", {CornerRadius=UDim.new(0,100)}, circle)

			pcall(callback, Value)

			local slDragging = false
			local function startDrag(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slDragging = true end
			end
			circle.InputBegan:Connect(startDrag); bar.InputBegan:Connect(startDrag)
			UIS.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slDragging = false end
			end)
			UIS.InputChanged:Connect(function(i)
				if slDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					local px = math.clamp(i.Position.X - bar.AbsolutePosition.X, 0, 100)
					bar1.Size = UDim2.new(0, px, 0, 4)
					circle.Position = UDim2.new(0, math.clamp(px-5, 0, 100), 0, -5)
					Value = math.floor((max-min)/100 * px + min)
					valLabel.Text = tostring(Value)
					pcall(callback, Value)
				end
			end)
		end

		function main:Textbox(text, _, callback)
			local frame = New("Frame", {
				Name="Textbox", BackgroundColor3=_G.Primary, BackgroundTransparency=0.8, Size=UDim2.new(1,0,0,35)
			}, MainFramePage)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, frame)
			New("TextLabel", {
				BackgroundTransparency=1, Position=UDim2.new(0,15,0.5,0), AnchorPoint=Vector2.new(0,0.5),
				Text=text, Size=UDim2.new(1,0,0,35), Font=Enum.Font.Nunito,
				TextColor3=Color3.fromRGB(255,255,255), TextSize=15, TextXAlignment=Enum.TextXAlignment.Left
			}, frame)
			local tb = New("TextBox", {
				BackgroundColor3=Color3.fromRGB(200,200,200), BackgroundTransparency=0.8,
				Position=UDim2.new(1,-5,0.5,0), AnchorPoint=Vector2.new(1,0.5), Size=UDim2.new(0,80,0,25),
				Font=Enum.Font.Gotham, Text="", TextColor3=Color3.fromRGB(225,225,225), TextSize=11, ClipsDescendants=true
			}, frame)
			New("UICorner", {CornerRadius=UDim.new(0,5)}, tb)
			tb.FocusLost:Connect(function() callback(tb.Text) end)
		end

		function main:Label(text)
			local frame = New("Frame", {
				Name="Frame", BackgroundTransparency=1, BackgroundColor3=_G.Primary, Size=UDim2.new(1,0,0,30)
			}, MainFramePage)
			local lbl = New("TextLabel", {
				Name="Label", BackgroundTransparency=1, Size=UDim2.new(1,-30,0,30),
				Font=Enum.Font.Nunito, Position=UDim2.new(0,30,0.5,0), AnchorPoint=Vector2.new(0,0.5),
				TextColor3=Color3.fromRGB(225,225,225), TextSize=15, Text=text, TextXAlignment=Enum.TextXAlignment.Left
			}, frame)
			New("ImageLabel", {
				BackgroundTransparency=1, Position=UDim2.new(0,10,0.5,0), AnchorPoint=Vector2.new(0,0.5),
				Size=UDim2.new(0,14,0,14), Image="rbxassetid://10723415903", ImageColor3=Color3.fromRGB(200,200,200)
			}, frame)
			local labelfunc = {}
			function labelfunc:Set(t) lbl.Text = t end
			return labelfunc
		end

		function main:Seperator(text)
			local sep = New("Frame", {
				Name="Seperator", BackgroundTransparency=1, BackgroundColor3=_G.Primary, Size=UDim2.new(1,0,0,36)
			}, MainFramePage)
			local gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, _G.Dark), ColorSequenceKeypoint.new(0.4, _G.Primary),
				ColorSequenceKeypoint.new(0.5, _G.Primary), ColorSequenceKeypoint.new(0.6, _G.Primary),
				ColorSequenceKeypoint.new(1, _G.Dark)
			})
			for _, cfg in ipairs({
				{name="Sep1", anchor=Vector2.new(0,0.5), pos=UDim2.new(0,0,0.5,0), size=UDim2.new(0.15,0,0,1)},
				{name="Sep3", anchor=Vector2.new(1,0.5), pos=UDim2.new(1,0,0.5,0), size=UDim2.new(0.15,0,0,1)},
			}) do
				local line = New("TextLabel", {Name=cfg.name, BackgroundColor3=Color3.fromRGB(255,255,255), AnchorPoint=cfg.anchor, Position=cfg.pos, Size=cfg.size, BorderSizePixel=0, Text=""}, sep)
				New("UIGradient", {Color=gradient}, line)
			end
			New("TextLabel", {
				Name="Sep2", BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5),
				Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(1,0,0,36),
				Font=Enum.Font.GothamBold, Text=text, TextColor3=Color3.fromRGB(255,255,255), TextSize=14
			}, sep)
		end

		function main:Line()
			local wrapper = New("Frame", {
				Name="Linee", BackgroundTransparency=1, BackgroundColor3=Color3.fromRGB(255,255,255),
				Position=UDim2.new(0,0,0.12,0), Size=UDim2.new(1,0,0,20)
			}, MainFramePage)
			local line = New("Frame", {
				Name="Line", BackgroundColor3=Color3.new(125,125,125), BorderSizePixel=0,
				Position=UDim2.new(0,0,0,10), Size=UDim2.new(1,0,0,1)
			}, wrapper)
			New("UIGradient", {Color=ColorSequence.new({
				ColorSequenceKeypoint.new(0,_G.Dark), ColorSequenceKeypoint.new(0.4,_G.Primary),
				ColorSequenceKeypoint.new(0.5,_G.Primary), ColorSequenceKeypoint.new(0.6,_G.Primary),
				ColorSequenceKeypoint.new(1,_G.Dark)
			})}, line)
		end

		return main
	end

	return uitab
end

return Update