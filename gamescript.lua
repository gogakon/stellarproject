local StellarLibrary = (loadstring(game:HttpGet("https://raw.githubusercontent.com/Infasion/Stellar-GUI/refs/heads/main/Stellarlib.lua")))()

local Window = StellarLibrary:Window({
	SubTitle = "Remote Spy",
	Size = UDim2.new(0, 500, 0, 320),
	TabWidth = 140
})

local Main = Window:Tab("Spy", "rbxassetid://10723407389")
local Settings = Window:Tab("Settings", "rbxassetid://10734950309")

local IgnoreList = {}
local LogRemotes = true

Main:Seperator("Remote Logger")

local LogLabel = Main:Label("Waiting for Remotes...")

local function HookRemote(remote)
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            if LogRemotes and not table.find(IgnoreList, remote.Name) then
                LogLabel:Set("[Event] " .. remote.Name)
                print("RemoteEvent Fired: " .. remote:GetFullName())
                print("Arguments:", ...)
            end
        end)
    end
end

-- Hook existing
for _, v in ipairs(game:GetDescendants()) do
    HookRemote(v)
end

-- Hook new
game.DescendantAdded:Connect(HookRemote)

Settings:Seperator("Controls")

Settings:Toggle("Enable Logging", true, "Toggle remote spying on/off", function(v)
    LogRemotes = v
end)

Settings:Button("Clear Console", function()
    print("\15") -- Clear console shortcut for some executors
    StellarLibrary:Notify("Console Cleared")
end)

Settings:Textbox("Ignore Remote Name", "Name...", function(v)
    table.insert(IgnoreList, v)
    StellarLibrary:Notify("Ignoring: " .. v)
end)
