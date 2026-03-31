local StellarLibrary = (loadstring(game:HttpGet("https://raw.githubusercontent.com/Infasion/Stellar-GUI/refs/heads/main/Stellarlib.lua")))()

if StellarLibrary:LoadAnimation() then StellarLibrary:StartLoad() end
if StellarLibrary:LoadAnimation() then StellarLibrary:Loaded() end

local UIS = game:GetService("UserInputService")
local Window = StellarLibrary:Window({
	SubTitle = "chud",
	Size = UIS.TouchEnabled and UDim2.new(0, 380, 0, 260) or UDim2.new(0, 500, 0, 320),
	TabWidth = 140
})

local Information = Window:Tab("Information", "rbxassetid://128891143813807")
local General     = Window:Tab("Main",        "rbxassetid://10723407389")
local Tab3        = Window:Tab("Farming",     "rbxassetid://10723415335")
local Tab4        = Window:Tab("Items",       "rbxassetid://10709782497")
local Tab5        = Window:Tab("Setting",     "rbxassetid://10734950309")
local Tab6        = Window:Tab("Local Player","rbxassetid://10747373176")
local Tab7        = Window:Tab("Hold Skill",  "rbxassetid://10734984606")
local Settings    = Window:Tab("Setting",     "rbxassetid://98216376967992")

-- Information Tab
Information:Seperator("Announcements")
local Info = Information:Label("Important")

-- General Tab
General:Seperator("Main")

local Time = General:Label("Executor Time")
task.spawn(function()
	while task.wait() do
		pcall(function()
			local t = math.floor(workspace.DistributedGameTime + 0.5)
			Time:Set(("[Game Time] Hours: %d | Min: %d | Sec: %d"):format(
				math.floor(t / 3600) % 24,
				math.floor(t / 60) % 60,
				t % 60
			))
		end)
	end
end)

local FpsLabel = General:Label("Client")
task.spawn(function()
	while task.wait(0.1) do
		pcall(function() FpsLabel:Set("[FPS] : " .. workspace:GetRealPhysicsFPS()) end)
	end
end)

local PingLabel = General:Label("Ping")
task.spawn(function()
	local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
	while task.wait(0.1) do
		pcall(function() PingLabel:Set("[Ping] : " .. ping:GetValueString()) end)
	end
end)

General:Button("Copy Discord Link", function()
	setclipboard("https://discord.gg/FmMuvkaWvG")
	StellarLibrary:Notify("Copied!", 3)
end)

General:Label("Status : label")

-- Dropdown
General:Seperator("Dropdown")
General:Dropdown("Type", {"Option 1", "Option 2", "Option 3"}, nil, function(selected)
	print("Selected:", selected)
end)

-- Toggle
General:Seperator("Toggle")
General:Toggle("Type", {"Option 1", "Option 2", "Option 3"}, "Toggle with desc", function(v) print("Toggle:", v) end)
General:Toggle("Type", {"Option 1", "Option 2", "Option 3"}, nil, function(v) print("Toggle:", v) end)

-- Slider
General:Seperator("Slider")
General:Slider("Farm Distance", 0, 50, 25, function(v) print("Farm Distance:", v) end)

General:Line()

local JobLabel = General:Label("Server Job ID :")

General:Button("Copy Server Job ID", function()
	setclipboard(game.JobId)
	StellarLibrary:Notify("Copied!", 3)
end)

General:Textbox("Enter Server Job ID", true, function(v) print("Job ID:", v) end)

General:Button("Join Server", function()
	print("Teleporting to Job ID...")
end)