local StellarLibrary = (loadstring(game:HttpGet("https://raw.githubusercontent.com/Infasion/Stellar-GUI/refs/heads/main/Stellarlib.lua")))()

if StellarLibrary:LoadAnimation() then StellarLibrary:StartLoad() end
if StellarLibrary:LoadAnimation() then StellarLibrary:Loaded() end

local Window = StellarLibrary:Window({
	SubTitle = "Utility Hub",
	Size = UDim2.new(0, 500, 0, 320),
	TabWidth = 140
})

local Main = Window:Tab("Main", "rbxassetid://10723407389")
local CollisionTab = Window:Tab("Collision", "rbxassetid://10709810010")
local MovementTab = Window:Tab("Movement", "rbxassetid://10747373176")

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local FullbrightEnabled = false

CollisionTab:Seperator("Hitbox Settings")
local HitboxSize = 10
local HitboxTransparency = 0.5
local HitboxColor = Color3.fromRGB(255, 0, 0)
local HitboxEnabled = false

CollisionTab:Slider("Hitbox Size", 1, 50, 10, function(v)
    HitboxSize = v
end)

CollisionTab:Slider("Transparency", 0, 100, 50, function(v)
    HitboxTransparency = v / 100
end)
local ESPEnabled = false
local ESPColor = Color3.fromRGB(255, 0, 0)
local ESPGlow = true

CollisionTab:Seperator("ESP Settings")

CollisionTab:Toggle("Enable ESP", false, "Highlights players through walls", function(v)
    ESPEnabled = v
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("StellarHighlight")
            if highlight then highlight.Enabled = v end
        end
    end
end)

CollisionTab:Toggle("ESP Glow", true, "Adds a neon glow effect", function(v)
    ESPGlow = v
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("StellarHighlight")
            if highlight then 
                highlight.FillTransparency = v and 0.5 or 1
                highlight.OutlineTransparency = 0
            end
        end
    end
end)

local function CreateESP(player)
    player.CharacterAdded:Connect(function(char)
        local highlight = Instance.new("Highlight")
        highlight.Name = "StellarHighlight"
        highlight.FillColor = ESPColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = ESPGlow and 0.5 or 1
        highlight.OutlineTransparency = 0
        highlight.Enabled = ESPEnabled
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = player.Character
    end)
end

game:GetService("Players").PlayerAdded:Connect(CreateESP)

for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
    if p ~= game:GetService("Players").LocalPlayer then
        CreateESP(p)
    end
end

CollisionTab:Toggle("Enable Hitbox", false, "Expands character hitboxes", function(v)
    HitboxEnabled = v
end)

task.spawn(function()
    while task.wait(0.5) do
        if HitboxEnabled then
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                if player ~= game:GetService("Players").LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    hrp.Transparency = HitboxTransparency
                    hrp.Color = HitboxColor
                    hrp.CanCollide = false
                end
            end
        end
    end
end)

local OriginalSettings = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

local function ApplyFullbright()
    if FullbrightEnabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    end
end

Main:Seperator("Lighting Controls")

Main:Toggle("Enable Fullbright", false, "Removes shadows and increases brightness", function(v)
    FullbrightEnabled = v
    if FullbrightEnabled then
        ApplyFullbright()
    else
        Lighting.Brightness = OriginalSettings.Brightness
        Lighting.ClockTime = OriginalSettings.ClockTime
        Lighting.FogEnd = OriginalSettings.FogEnd
        Lighting.GlobalShadows = OriginalSettings.GlobalShadows
        Lighting.Ambient = OriginalSettings.Ambient
    end
end)

MovementTab:Seperator("Character Mods")

MovementTab:Slider("WalkSpeed", 16, 250, 16, function(v)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

MovementTab:Slider("JumpPower", 50, 500, 50, function(v)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)

local InfiniteJumpEnabled = false
MovementTab:Toggle("Infinite Jump", false, "Allows you to jump in the air", function(v)
    InfiniteJumpEnabled = v
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJumpEnabled and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local AimAssistEnabled = false
local AimAssistRadius = 100
local AimAssistSmoothness = 0.2
local TeamCheck = true

local AimTab = Window:Tab("Aim Assist", "rbxassetid://10709752906")

AimTab:Seperator("Main Settings")

AimTab:Toggle("Enable Aim Assist", false, "Smoothly tracks players near cursor", function(v)
    AimAssistEnabled = v
end)

AimTab:Toggle("Team Check", true, "Ignore teammates", function(v)
    TeamCheck = v
end)

AimTab:Slider("Radius", 50, 500, 100, function(v)
    AimAssistRadius = v
end)

AimTab:Slider("Smoothness", 1, 100, 20, function(v)
    AimAssistSmoothness = v / 100
end)

local function GetClosestPlayer()
    local closest = nil
    local shortestDist = AimAssistRadius
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= game:GetService("Players").LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if TeamCheck and p.Team == game:GetService("Players").LocalPlayer.Team then continue end
            
            local targetPart = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDist then
                    closest = targetPart
                    shortestDist = dist
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if AimAssistEnabled then
        local target = GetClosestPlayer()
        if target then
            local cam = workspace.CurrentCamera
            -- Create a look-at CFrame and smoothly interpolate the camera towards it
            local targetCFrame = CFrame.new(cam.CFrame.Position, target.Position)
            cam.CFrame = cam.CFrame:Lerp(targetCFrame, AimAssistSmoothness)
        end
    end
end)

Lighting.Changed:Connect(function()
    if FullbrightEnabled then
        ApplyFullbright()
    end
end)

StellarLibrary:Notify("Fullbright Script Loaded")
