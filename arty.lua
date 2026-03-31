--[[
    ArtilleryTrajectory.lua
    ========================
    Visualizes the firing trajectory of artillery pieces using the
    Desmos-based formula:  y = x*tan(a) - (g*x^2) / (2*(v*cos(a))^2)

    Artillery force (g) values per piece:
        12 lb Cannon         = 104
        4 inch Howitzer      = 223
        Mortar 1/4 powder    = 590
        Mortar 2/4 powder    = 374
        Mortar 3/4 powder    = 250
        Mortar 4/4 powder    = 181

    Usage:
        - Place this LocalScript inside StarterPlayerScripts (or a LocalScript in StarterGui)
        - It will create a ScreenGui with a dropdown to select any BasePart in workspace.Structures
        - Choose your artillery type, set the angle, and click "Fire" to draw the arc
        - The arc is drawn with neon Parts that auto-clean after DISPLAY_TIME seconds

    Notes:
        - v is fixed at 773 (as per the Desmos calculator)
        - "a" is the angle in DEGREES, converted to radians internally
        - The trajectory is drawn in world space, projected forward from the
          selected part's LookVector (or CFrame.LookVector)
        - Works on a flat plain (y=0 ground reference from the part's position)
--]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")

local player             = Players.LocalPlayer
local playerGui          = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONSTANTS
-- ============================================================
local V                  = 773          -- fixed muzzle-velocity constant
local STEP               = 0.5          -- horizontal step size (studs) for arc points
local MAX_RANGE          = 2000         -- max x to sample before giving up
local DISPLAY_TIME       = 20           -- seconds before the arc fades away
local BEAM_RADIUS        = 0.1          -- thickness of each arc segment part
local ARC_COLOR          = Color3.fromRGB(255, 80, 0)   -- orange neon
local GROUND_OFFSET      = 0           -- y-offset: 0 = ground is at the part's Y

local ARTILLERY_PRESETS  = {
    { name = "12 lb Cannon",        g = 104  },
    { name = "4 inch Howitzer",     g = 223  },
    { name = "Mortar 1/4 powder",   g = 590  },
    { name = "Mortar 2/4 powder",   g = 374  },
    { name = "Mortar 3/4 powder",   g = 250  },
    { name = "Mortar 4/4 powder",   g = 181  },
}

-- ============================================================
-- STATE
-- ============================================================
local selectedStructure  = nil
local selectedArtillery  = ARTILLERY_PRESETS[1]
local currentAngle       = 45           -- degrees
local arcFolder          = nil          -- Instance folder holding current arc parts

-- Highlight state: remembers the original material/color of the selected part
local highlightedPart    = nil
local originalMaterial   = nil
local originalColor      = nil

local HIGHLIGHT_COLOR    = Color3.fromRGB(0, 255, 60)   -- bright neon green

local function clearHighlight()
    if highlightedPart and highlightedPart.Parent then
        highlightedPart.Material = originalMaterial
        highlightedPart.Color    = originalColor
    end
    highlightedPart  = nil
    originalMaterial = nil
    originalColor    = nil
end

local function setHighlight(part)
    clearHighlight()
    if not part or not part.Parent then return end
    highlightedPart  = part
    originalMaterial = part.Material
    originalColor    = part.Color
    part.Material    = Enum.Material.Neon
    part.Color       = HIGHLIGHT_COLOR
end

-- ============================================================
-- MATH HELPERS
-- ============================================================

local function trajectoryY(x, angleDeg, g)
    local a    = math.rad(angleDeg)
    local cosA = math.cos(a)
    local tanA = math.tan(a)
    return x * tanA - (g * x * x) / (2 * (V * cosA) ^ 2)
end

local function maxRange(angleDeg, g)
    local a = math.rad(angleDeg)
    return (V * V / g) * math.sin(2 * a)
end

local function maxHeightAndRange(angleDeg, g)
    local a    = math.rad(angleDeg)
    local cosA = math.cos(a)
    local tanA = math.tan(a)
    local m    = (V * V / g) * math.sin(2 * a) / 2
    local j    = (g * m * m) / (2 * (V * cosA) ^ 2)
    local h    = m * tanA - j
    return h, m * 2
end

-- ============================================================
-- ARC DRAWING
-- ============================================================

local function clearArc()
    if arcFolder then
        arcFolder:Destroy()
        arcFolder = nil
    end
end

local function drawArc(originCFrame, angleDeg, g)
    clearArc()

    local folder = Instance.new("Folder")
    folder.Name  = "ArtilleryArc"
    folder.Parent = workspace
    arcFolder    = folder

    local origin  = originCFrame.Position
    
    -- Mortars in this game often have their LookVector pointing backwards relative to the barrel
    -- We check if the name contains mortar and flip the direction if so
    local isMortar = selectedStructure.Name:lower():find("mortar")
    local forward = isMortar and -originCFrame.LookVector or originCFrame.LookVector
    
    local up      = Vector3.new(0, 1, 0)

    local range   = maxRange(angleDeg, g)
    local xLimit  = math.min(range, MAX_RANGE)

    local prevPoint = nil
    local x = 0

    while x <= xLimit + STEP do
        local yOffset = trajectoryY(x, angleDeg, g)
        if yOffset < -origin.Y - 50 then break end

        local worldPoint = origin
            + forward * x
            + up      * yOffset

        if prevPoint then
            local mid    = (prevPoint + worldPoint) / 2
            local dist   = (worldPoint - prevPoint).Magnitude
            local dir    = (worldPoint - prevPoint).Unit

            local seg    = Instance.new("Part")
            seg.Size     = Vector3.new(BEAM_RADIUS, BEAM_RADIUS, dist)
            seg.CFrame   = CFrame.lookAt(mid, mid + dir)
            seg.Anchored = true
            seg.CanCollide = false
            seg.CanQuery   = false
            seg.CanTouch   = false
            seg.CastShadow = false
            seg.Material   = Enum.Material.Neon
            seg.Color      = ARC_COLOR
            seg.Parent     = folder
        end

        prevPoint = worldPoint
        x = x + STEP
    end

    local impactX     = range
    local impactPoint = origin + forward * impactX
    local dot         = Instance.new("Part")
    dot.Shape         = Enum.PartType.Ball
    dot.Size          = Vector3.new(1.5, 1.5, 1.5)
    dot.Position      = impactPoint
    dot.Anchored      = true
    dot.CanCollide    = false
    dot.CanQuery      = false
    dot.Material      = Enum.Material.Neon
    dot.Color         = Color3.fromRGB(255, 220, 0)
    dot.Parent        = folder

    local billboard   = Instance.new("BillboardGui")
    billboard.Size    = UDim2.new(0, 180, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent  = dot

    local label       = Instance.new("TextLabel")
    label.Size        = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3  = Color3.fromRGB(255, 220, 0)
    label.TextStrokeTransparency = 0
    label.Font        = Enum.Font.GothamBold
    label.TextScaled  = true
    label.Text        = string.format("Impact: %.1f studs", impactX)
    label.Parent      = billboard

    task.delay(DISPLAY_TIME, function()
        if folder and folder.Parent then
            folder:Destroy()
            if arcFolder == folder then arcFolder = nil end
        end
    end)
end

-- ============================================================
-- SCAN workspace.Structures FOR PARTS
-- ============================================================

-- Only surfaces parts whose name contains "cannon", "howitzer", or "mortar"
local ALLOWED_KEYWORDS = { "cannon", "howitzer", "mortar" }

local function isArtilleryPart(part)
    local nameLower = part.Name:lower()
    for _, kw in ipairs(ALLOWED_KEYWORDS) do
        if nameLower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function getStructureParts()
    local results = {}
    local structuresFolder = workspace:FindFirstChild("Structures")
    if not structuresFolder then return results end

    local function recurse(inst)
        for _, child in ipairs(inst:GetChildren()) do
            if child:IsA("BasePart") and isArtilleryPart(child) then
                table.insert(results, child)
            end
            recurse(child)
        end
    end
    recurse(structuresFolder)
    return results
end

-- Returns a filtered list of parts whose display name contains the query (case-insensitive)
local function filterParts(parts, query)
    if query == "" then return parts end
    local q = query:lower()
    local filtered = {}
    for _, part in ipairs(parts) do
        local displayName = part:GetFullName():gsub("workspace%.Structures%.", "")
        if displayName:lower():find(q, 1, true) then
            table.insert(filtered, part)
        end
    end
    return filtered
end

-- ============================================================
-- GUI BUILDER
-- ============================================================

local function buildGui()
    local old = playerGui:FindFirstChild("ArtilleryUI")
    if old then old:Destroy() end

    local screenGui            = Instance.new("ScreenGui")
    screenGui.Name             = "ArtilleryUI"
    screenGui.ResetOnSpawn     = false
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.Parent           = playerGui

    -- Main panel
    local panel                = Instance.new("Frame")
    panel.Name                 = "Panel"
    panel.Size                 = UDim2.new(0, 320, 0, 420)
    panel.Position             = UDim2.new(0, 16, 0.5, -210)
    panel.BackgroundColor3     = Color3.fromRGB(18, 18, 22)
    panel.BorderSizePixel      = 0
    panel.Parent               = screenGui

    local corner               = Instance.new("UICorner")
    corner.CornerRadius        = UDim.new(0, 10)
    corner.Parent              = panel

    local stroke               = Instance.new("UIStroke")
    stroke.Color               = Color3.fromRGB(255, 80, 0)
    stroke.Thickness           = 1.5
    stroke.Parent              = panel

    -- Title
    local title                = Instance.new("TextLabel")
    title.Size                 = UDim2.new(1, 0, 0, 44)
    title.Position             = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3     = Color3.fromRGB(255, 80, 0)
    title.BorderSizePixel      = 0
    title.Text                 = "Artillery Trajectory"
    title.TextColor3           = Color3.fromRGB(255, 255, 255)
    title.Font                 = Enum.Font.GothamBold
    title.TextSize             = 16
    title.Parent               = panel

    local titleCorner          = Instance.new("UICorner")
    titleCorner.CornerRadius   = UDim.new(0, 10)
    titleCorner.Parent         = title

    local titleFix             = Instance.new("Frame")
    titleFix.Size              = UDim2.new(1, 0, 0, 10)
    titleFix.Position          = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3  = Color3.fromRGB(255, 80, 0)
    titleFix.BorderSizePixel   = 0
    titleFix.Parent            = title

    local function makeLabel(text, yPos)
        local lbl              = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, -24, 0, 18)
        lbl.Position           = UDim2.new(0, 12, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Text               = text
        lbl.TextColor3         = Color3.fromRGB(160, 160, 170)
        lbl.Font               = Enum.Font.Gotham
        lbl.TextSize           = 12
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.Parent             = panel
        return lbl
    end

    local function makeDropdown(yPos, placeholder)
        local btn              = Instance.new("TextButton")
        btn.Size               = UDim2.new(1, -24, 0, 34)
        btn.Position           = UDim2.new(0, 12, 0, yPos)
        btn.BackgroundColor3   = Color3.fromRGB(30, 30, 36)
        btn.BorderSizePixel    = 0
        btn.Text               = placeholder
        btn.TextColor3         = Color3.fromRGB(220, 220, 230)
        btn.Font               = Enum.Font.Gotham
        btn.TextSize           = 13
        btn.TextXAlignment     = Enum.TextXAlignment.Left
        btn.TextTruncate       = Enum.TextTruncate.AtEnd
        local btnPad           = Instance.new("UIPadding")
        btnPad.PaddingLeft     = UDim.new(0, 10)
        btnPad.Parent          = btn
        local btnCorner        = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent       = btn
        local btnStroke        = Instance.new("UIStroke")
        btnStroke.Color        = Color3.fromRGB(60, 60, 70)
        btnStroke.Thickness    = 1
        btnStroke.Parent       = btn

        local chevron          = Instance.new("TextLabel")
        chevron.Size           = UDim2.new(0, 24, 1, 0)
        chevron.Position       = UDim2.new(1, -28, 0, 0)
        chevron.BackgroundTransparency = 1
        chevron.Text           = "▾"
        chevron.TextColor3     = Color3.fromRGB(160, 160, 170)
        chevron.Font           = Enum.Font.Gotham
        chevron.TextSize       = 14
        chevron.Parent         = btn

        btn.Parent             = panel
        return btn
    end

    -- ---- Structure dropdown ----
    makeLabel("Structure (from workspace.Structures)", 52)

    local structBtn            = makeDropdown(72, "— select structure —")
    local structDropdown       = nil   -- the whole dropdown container (search box + list)
    local structParts          = {}

    -- Builds or destroys the dropdown container with a search box + scrolling list
    local function buildStructDropdown()
        if structDropdown then
            structDropdown:Destroy()
            structDropdown = nil
            return
        end

        structParts = getStructureParts()

        -- Outer container
        local container            = Instance.new("Frame")
        container.Name             = "StructDropdown"
        container.Size             = UDim2.new(0, 296, 0, 220)
        container.Position         = UDim2.new(0, 12, 0, 108)
        container.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        container.BorderSizePixel  = 0
        container.ZIndex           = 10
        container.ClipsDescendants = false

        local cCorner              = Instance.new("UICorner")
        cCorner.CornerRadius       = UDim.new(0, 6)
        cCorner.Parent             = container

        local cStroke              = Instance.new("UIStroke")
        cStroke.Color              = Color3.fromRGB(70, 70, 80)
        cStroke.Thickness          = 1
        cStroke.Parent             = container

        -- Search box
        local searchBox            = Instance.new("TextBox")
        searchBox.Size             = UDim2.new(1, -12, 0, 30)
        searchBox.Position         = UDim2.new(0, 6, 0, 5)
        searchBox.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
        searchBox.BorderSizePixel  = 0
        searchBox.PlaceholderText  = "🔍  Search structures..."
        searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
        searchBox.Text             = ""
        searchBox.TextColor3       = Color3.fromRGB(220, 220, 230)
        searchBox.Font             = Enum.Font.Gotham
        searchBox.TextSize         = 12
        searchBox.TextXAlignment   = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        searchBox.ZIndex           = 11

        local sbCorner             = Instance.new("UICorner")
        sbCorner.CornerRadius      = UDim.new(0, 5)
        sbCorner.Parent            = searchBox

        local sbPad                = Instance.new("UIPadding")
        sbPad.PaddingLeft          = UDim.new(0, 8)
        sbPad.Parent               = searchBox

        searchBox.Parent           = container

        -- Scroll frame for results
        local scroll               = Instance.new("ScrollingFrame")
        scroll.Size                = UDim2.new(1, 0, 1, -42)
        scroll.Position            = UDim2.new(0, 0, 0, 40)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel     = 0
        scroll.ScrollBarThickness  = 4
        scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
        scroll.ZIndex              = 11
        scroll.Parent              = container

        local layout               = Instance.new("UIListLayout")
        layout.Parent              = scroll

        -- Populate scroll with filtered parts
        local function populateList(query)
            -- Clear existing items (buttons AND the "no results" label)
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end

            local filtered = filterParts(structParts, query)

            if #filtered == 0 then
                local noResult         = Instance.new("TextLabel")
                noResult.Size          = UDim2.new(1, 0, 0, 30)
                noResult.BackgroundTransparency = 1
                noResult.Text          = "No results found."
                noResult.TextColor3    = Color3.fromRGB(120, 120, 130)
                noResult.Font          = Enum.Font.Gotham
                noResult.TextSize      = 12
                noResult.ZIndex        = 12
                noResult.Parent        = scroll
                scroll.CanvasSize      = UDim2.new(0, 0, 0, 30)
                return
            end

            scroll.CanvasSize = UDim2.new(0, 0, 0, #filtered * 30)

            for _, part in ipairs(filtered) do
                local displayName      = part:GetFullName():gsub("workspace%.Structures%.", "")

                local item             = Instance.new("TextButton")
                item.Size              = UDim2.new(1, 0, 0, 30)
                item.BackgroundColor3  = Color3.fromRGB(28, 28, 34)
                item.BorderSizePixel   = 0
                item.Text              = displayName
                item.TextColor3        = Color3.fromRGB(210, 210, 220)
                item.Font              = Enum.Font.Gotham
                item.TextSize          = 12
                item.TextXAlignment    = Enum.TextXAlignment.Left
                item.TextTruncate      = Enum.TextTruncate.AtEnd
                item.ZIndex            = 12

                local iPad             = Instance.new("UIPadding")
                iPad.PaddingLeft       = UDim.new(0, 10)
                iPad.Parent            = item

                item.MouseButton1Click:Connect(function()
                    selectedStructure  = part
                    structBtn.Text     = displayName
                    setHighlight(part)
                    structDropdown:Destroy()
                    structDropdown     = nil
                end)
                item.MouseEnter:Connect(function()
                    item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                end)
                item.MouseLeave:Connect(function()
                    item.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
                end)
                item.Parent            = scroll
            end
        end

        -- Initial population (no filter)
        populateList("")

        -- Update list whenever the search text changes
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            populateList(searchBox.Text)
        end)

        container.Parent           = panel
        structDropdown             = container

        -- Auto-focus the search box so the player can type immediately
        task.defer(function()
            searchBox:CaptureFocus()
        end)
    end

    structBtn.MouseButton1Click:Connect(function()
        buildStructDropdown()
    end)

    -- ---- Artillery type dropdown ----
    makeLabel("Artillery type (g force)", 118)

    local artilleryBtn         = makeDropdown(138, ARTILLERY_PRESETS[1].name .. " (g=" .. ARTILLERY_PRESETS[1].g .. ")")
    local artilleryList        = nil

    local function buildArtilleryList()
        if artilleryList then artilleryList:Destroy() artilleryList = nil return end

        artilleryList          = Instance.new("Frame")
        artilleryList.Size     = UDim2.new(0, 296, 0, #ARTILLERY_PRESETS * 34)
        artilleryList.Position = UDim2.new(0, 12, 0, 174)
        artilleryList.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        artilleryList.BorderSizePixel  = 0
        artilleryList.ZIndex   = 10
        local alCorner         = Instance.new("UICorner")
        alCorner.CornerRadius  = UDim.new(0, 6)
        alCorner.Parent        = artilleryList
        local alStroke         = Instance.new("UIStroke")
        alStroke.Color         = Color3.fromRGB(70, 70, 80)
        alStroke.Thickness     = 1
        alStroke.Parent        = artilleryList

        local layout           = Instance.new("UIListLayout")
        layout.Parent          = artilleryList

        for _, preset in ipairs(ARTILLERY_PRESETS) do
            local item         = Instance.new("TextButton")
            item.Size          = UDim2.new(1, 0, 0, 34)
            item.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            item.BorderSizePixel  = 0
            item.Text          = preset.name .. "  (g=" .. preset.g .. ")"
            item.TextColor3    = Color3.fromRGB(210, 210, 220)
            item.Font          = Enum.Font.Gotham
            item.TextSize      = 12
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.ZIndex        = 11
            local iPad         = Instance.new("UIPadding")
            iPad.PaddingLeft   = UDim.new(0, 10)
            iPad.Parent        = item

            item.MouseButton1Click:Connect(function()
                selectedArtillery  = preset
                artilleryBtn.Text  = preset.name .. " (g=" .. preset.g .. ")"
                artilleryList:Destroy()
                artilleryList      = nil
            end)
            item.MouseEnter:Connect(function()
                item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            end)
            item.MouseLeave:Connect(function()
                item.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            end)
            item.Parent        = artilleryList
        end

        artilleryList.Parent   = panel
    end

    artilleryBtn.MouseButton1Click:Connect(function()
        buildArtilleryList()
    end)

    -- ---- Angle slider ----
    makeLabel("Launch angle (degrees): " .. currentAngle .. "°", 186)

    local allLabels            = panel:GetDescendants()
    local angLabel             = nil
    for _, d in ipairs(allLabels) do
        if d:IsA("TextLabel") and d.Text:find("Launch angle") then
            angLabel           = d
        end
    end

    local sliderTrack          = Instance.new("Frame")
    sliderTrack.Size           = UDim2.new(1, -24, 0, 6)
    sliderTrack.Position       = UDim2.new(0, 12, 0, 208)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderTrack.BorderSizePixel  = 0
    local stCorner             = Instance.new("UICorner")
    stCorner.CornerRadius      = UDim.new(1, 0)
    stCorner.Parent            = sliderTrack
    sliderTrack.Parent         = panel

    local sliderFill           = Instance.new("Frame")
    sliderFill.Size            = UDim2.new((currentAngle - 1) / 88, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
    sliderFill.BorderSizePixel  = 0
    local sfCorner             = Instance.new("UICorner")
    sfCorner.CornerRadius      = UDim.new(1, 0)
    sfCorner.Parent            = sliderFill
    sliderFill.Parent          = sliderTrack

    local sliderKnob           = Instance.new("TextButton")
    sliderKnob.Size            = UDim2.new(0, 18, 0, 18)
    sliderKnob.AnchorPoint     = Vector2.new(0.5, 0.5)
    sliderKnob.Position        = UDim2.new((currentAngle - 1) / 88, 0, 0, 3)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.Text            = ""
    sliderKnob.BorderSizePixel  = 0
    local skCorner             = Instance.new("UICorner")
    skCorner.CornerRadius      = UDim.new(1, 0)
    skCorner.Parent            = sliderKnob
    sliderKnob.Parent          = sliderTrack

    local dragging             = false
    sliderKnob.MouseButton1Down:Connect(function()
        dragging               = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging           = false
        end
    end)
    RunService.Heartbeat:Connect(function()
        if not dragging then return end
        local mouse            = player:GetMouse()
        local trackAbsPos      = sliderTrack.AbsolutePosition
        local trackAbsSize     = sliderTrack.AbsoluteSize
        local rel              = (mouse.X - trackAbsPos.X) / trackAbsSize.X
        rel                    = math.clamp(rel, 0, 1)
        currentAngle           = math.floor(1 + rel * 88)
        sliderFill.Size        = UDim2.new(rel, 0, 1, 0)
        sliderKnob.Position    = UDim2.new(rel, 0, 0.5, 0)
        if angLabel then
            angLabel.Text      = "Launch angle (degrees): " .. currentAngle .. "°"
        end
    end)

    -- ---- Stats display ----
    local statsFrame           = Instance.new("Frame")
    statsFrame.Size            = UDim2.new(1, -24, 0, 60)
    statsFrame.Position        = UDim2.new(0, 12, 0, 228)
    statsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    statsFrame.BorderSizePixel  = 0
    local sfr                  = Instance.new("UICorner")
    sfr.CornerRadius           = UDim.new(0, 6)
    sfr.Parent                 = statsFrame
    statsFrame.Parent          = panel

    local statsLabel           = Instance.new("TextLabel")
    statsLabel.Size            = UDim2.new(1, -16, 1, 0)
    statsLabel.Position        = UDim2.new(0, 8, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text            = "Select a structure and press Fire to see stats."
    statsLabel.TextColor3      = Color3.fromRGB(160, 160, 170)
    statsLabel.Font            = Enum.Font.Gotham
    statsLabel.TextSize        = 12
    statsLabel.TextWrapped     = true
    statsLabel.TextXAlignment  = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment  = Enum.TextYAlignment.Center
    statsLabel.Parent          = statsFrame

    -- ---- Fire button ----
    local fireBtn              = Instance.new("TextButton")
    fireBtn.Size               = UDim2.new(1, -24, 0, 42)
    fireBtn.Position           = UDim2.new(0, 12, 0, 300)
    fireBtn.BackgroundColor3   = Color3.fromRGB(255, 80, 0)
    fireBtn.BorderSizePixel    = 0
    fireBtn.Text               = "FIRE  ►"
    fireBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
    fireBtn.Font               = Enum.Font.GothamBold
    fireBtn.TextSize           = 15
    local fbCorner             = Instance.new("UICorner")
    fbCorner.CornerRadius      = UDim.new(0, 8)
    fbCorner.Parent            = fireBtn
    fireBtn.Parent             = panel

    fireBtn.MouseEnter:Connect(function()
        fireBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 0)
    end)
    fireBtn.MouseLeave:Connect(function()
        fireBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
    end)

    fireBtn.MouseButton1Click:Connect(function()
        if not selectedStructure or not selectedStructure.Parent then
            statsLabel.Text    = "Error: No structure selected, or it no longer exists."
            return
        end

        local g                = selectedArtillery.g
        local angle            = currentAngle
        local cf               = selectedStructure.CFrame

        local peakH, rangeStuds = maxHeightAndRange(angle, g)

        drawArc(cf, angle, g)

        statsLabel.Text = string.format(
            "Artillery: %s  |  g=%d  |  Angle: %d°\nRange: %.1f studs  |  Peak height: %.1f studs\nArc clears in %ds",
            selectedArtillery.name, g, angle, rangeStuds, peakH, DISPLAY_TIME
        )
    end)

    -- ---- Clear button ----
    local clearBtn             = Instance.new("TextButton")
    clearBtn.Size              = UDim2.new(1, -24, 0, 32)
    clearBtn.Position          = UDim2.new(0, 12, 0, 350)
    clearBtn.BackgroundColor3  = Color3.fromRGB(38, 38, 46)
    clearBtn.BorderSizePixel   = 0
    clearBtn.Text              = "Clear arc"
    clearBtn.TextColor3        = Color3.fromRGB(180, 180, 190)
    clearBtn.Font              = Enum.Font.Gotham
    clearBtn.TextSize          = 13
    local cbCorner             = Instance.new("UICorner")
    cbCorner.CornerRadius      = UDim.new(0, 8)
    cbCorner.Parent            = clearBtn
    clearBtn.Parent            = panel

    clearBtn.MouseButton1Click:Connect(function()
        clearArc()
        statsLabel.Text        = "Arc cleared."
    end)

    -- ---- Refresh structures button ----
    local refreshBtn           = Instance.new("TextButton")
    refreshBtn.Size            = UDim2.new(1, -24, 0, 28)
    refreshBtn.Position        = UDim2.new(0, 12, 0, 388)
    refreshBtn.BackgroundTransparency = 1
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text            = "↺  Refresh structure list"
    refreshBtn.TextColor3      = Color3.fromRGB(255, 80, 0)
    refreshBtn.Font            = Enum.Font.Gotham
    refreshBtn.TextSize        = 12
    refreshBtn.Parent          = panel

    refreshBtn.MouseButton1Click:Connect(function()
        clearHighlight()
        selectedStructure      = nil
        structBtn.Text         = "— select structure —"
        if structDropdown then structDropdown:Destroy() structDropdown = nil end
        statsLabel.Text        = "Structure list refreshed."
    end)
end

-- ============================================================
-- INIT
-- ============================================================-- ============================================================
-- CLICK TO SELECT LOGIC
-- ============================================================

local function handleWorldClick(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
        
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        local structures = workspace:FindFirstChild("Structures")
        if not structures then return end
        params.FilterDescendantsInstances = {structures}
        
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
        
        if result and result.Instance:IsA("BasePart") then
            local part = result.Instance
            if isArtilleryPart(part) then
                selectedStructure = part
                setHighlight(part)
                
                -- Update the UI button text if it exists
                local gui = playerGui:FindFirstChild("ArtilleryUI")
                if gui then
                    local pnl = gui:FindFirstChild("Panel")
                    local btn = pnl and pnl:FindFirstChild("TextButton") -- The first dropdown is structure
                    if btn then
                        btn.Text = part:GetFullName():gsub("workspace%.Structures%.", "")
                    end
                    
                    local stats = pnl and pnl:FindFirstChild("Frame") and pnl.Frame:FindFirstChild("TextLabel")
                    if stats then
                        stats.Text = "Selected via click: " .. part.Name
                    end
                end
                
                -- Close dropdown if open
                local existingDropdown = gui and gui.Panel:FindFirstChild("StructDropdown")
                if existingDropdown then existingDropdown:Destroy() end
            end
        end
    end
end

UserInputService.InputBegan:Connect(handleWorldClick)
buildGui()
print("[ArtilleryTrajectory] Loaded. Open the panel on the left side of your screen.")