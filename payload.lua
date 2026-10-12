-- Steal a Egg v4 — Fly + Submenu ESP + Auto Grab
-- Modern UI + Rainbow + Animation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local CONFIG = {
    EggESP = true,
    PlayerESP = false,
    BestEggESP = true,
    AutoSteal = false,
    SpeedHack = false,
    AutoGrab = false,
    AntiBan = true,
    Rainbow = true,
    FlySpeed = 50,
    SpeedHackSpeed = 120,
    GrabDelay = 0.5,
}

local RARITY = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Secret = 7, Cosmic = 8,
    Eternal = 9, Divine = 10,
}

-- ============================================
-- RAINBOW
-- ============================================
local hue = 0
local function getRainbow()
    hue = (hue + 0.005) % 1
    return Color3.fromHSV(hue, 0.7, 1)
end

-- ============================================
-- ANTI-BAN
-- ============================================
local function antiBanInit()
    if not CONFIG.AntiBan then return end
    local env = getfenv and getfenv(0) or _G
    if env then
        pcall(function()
            env.getgenv = nil; env.getreg = nil; env.getgc = nil
            env.getupvalue = nil; env.getupvalues = nil
        end)
    end
end
antiBanInit()

-- ============================================
-- BEST EGG
-- ============================================
local function getBestEgg()
    local best, bestScore = nil, 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            local score = 0
            for rar, tier in pairs(RARITY) do
                if obj.Name:find(rar) then score = math.max(score, tier) end
            end
            score = score + obj.Size.Magnitude * 0.1
            if score > bestScore then best, bestScore = obj, score end
        end
    end
    return best, bestScore
end

-- ============================================
-- ESP CACHE
-- ============================================
local espCache = {}

local function clearESP()
    for part, guis in pairs(espCache) do
        for _, g in ipairs(guis) do
            pcall(function() g:Destroy() end)
        end
    end
    espCache = {}
end

local function createESP(part, color, label)
    if espCache[part] then
        espCache[part][1].Color3 = color
        return
    end
    local box = Instance.new("SelectionBox")
    box.Adornee = part
    box.Parent = part
    box.Color3 = color
    box.LineThickness = 0.08
    box.Transparency = 0.4
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Parent = bb
    espCache[part] = { box, bb }
end

-- ============================================
-- ESP UPDATE
-- ============================================
local function updateESP()
    -- cleanup destroyed
    for part, guis in pairs(espCache) do
        if not part.Parent then
            for _, g in ipairs(guis) do pcall(function() g:Destroy() end) end
            espCache[part] = nil
        end
    end

    local bestEgg = CONFIG.BestEggESP and getBestEgg() or nil

    -- Egg ESP / Best Egg ESP
    if CONFIG.EggESP or CONFIG.BestEggESP then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                if CONFIG.BestEggESP and obj == bestEgg then
                    createESP(obj, Color3.fromRGB(255, 50, 50), "★ BEST: " .. obj.Name)
                elseif CONFIG.EggESP then
                    createESP(obj, Color3.fromRGB(50, 255, 50), obj.Name)
                end
            end
        end
    end

    -- Player ESP
    if CONFIG.PlayerESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                if hrp then
                    createESP(hrp, Color3.fromRGB(255, 255, 50), plr.Name)
                end
            end
        end
    end
end

-- ============================================
-- FLY SYSTEM
-- ============================================
local flyEnabled = false
local flyBV, flyBG

local function startFly()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 1000
    flyBG.D = 50
    flyBG.Parent = hrp

    flyEnabled = true
    task.spawn(function()
        while flyEnabled and hrp.Parent do
            local speed = CONFIG.SpeedHack and CONFIG.SpeedHackSpeed or CONFIG.FlySpeed
            local cam = workspace.CurrentCamera
            local move = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end

            if move.Magnitude > 0 then
                flyBV.Velocity = move.Unit * speed
            else
                flyBV.Velocity = Vector3.zero
            end
            flyBG.CFrame = cam.CFrame
            task.wait()
        end
    end)
end

local function stopFly()
    flyEnabled = false
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ============================================
-- FLY TO TARGET (used by AutoSteal / AutoGrab)
-- ============================================
local function flyToPosition(pos, speed)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = hrp

    local distance
    repeat
        if not hrp.Parent then bv:Destroy(); return end
        local diff = pos - hrp.Position
        distance = diff.Magnitude
        bv.Velocity = diff.Unit * math.min(speed, distance * 4)
        task.wait()
    until distance < 4

    bv:Destroy()
end

-- ============================================
-- AUTO STEAL (fly to best egg)
-- ============================================
local stealing = false
local function autoSteal()
    if not CONFIG.AutoSteal or stealing then return end
    stealing = true

    local egg = getBestEgg()
    if not egg then stealing = false; return end

    local speed = CONFIG.SpeedHack and CONFIG.SpeedHackSpeed or CONFIG.FlySpeed

    -- Fly to egg
    flyToPosition(egg.Position, speed)
    task.wait(0.15)

    -- Activate prompts
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end
    end

    task.wait(CONFIG.GrabDelay)

    -- Fly back to base
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        flyToPosition(spawn.Position + Vector3.new(0, 5, 0), speed)
    end

    task.wait(0.3)
    stealing = false
end

-- ============================================
-- AUTO GRAB (0.5s instant grab + fly back)
-- ============================================
local grabbing = false
local function autoGrab()
    if not CONFIG.AutoGrab or grabbing then return end
    grabbing = true

    local egg = getBestEgg()
    if not egg then grabbing = false; return end

    local speed = CONFIG.SpeedHack and CONFIG.SpeedHackSpeed or CONFIG.FlySpeed

    -- Fly FAST to egg
    flyToPosition(egg.Position, speed * 1.5)

    -- Instant activate all prompts
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
        end
    end

    -- Instant fly back (0.5s total)
    task.wait(0.1)
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        flyToPosition(spawn.Position + Vector3.new(0, 5, 0), speed * 2)
    end

    task.wait(0.1)
    grabbing = false
end

-- ============================================
-- MAIN LOOPS
-- ============================================
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(updateESP)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if CONFIG.AutoSteal then pcall(autoSteal) end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if CONFIG.AutoGrab then pcall(autoGrab) end
    end
end)

-- ============================================
-- UI — MODERN + RAINBOW + SUBMENU
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealAEgg_v4"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 400)
Main.Position = UDim2.new(0.5, -150, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(255, 100, 200)
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Stroke.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 16, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Steal a Egg"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -70, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 30)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Content scroll
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -56)
Content.Position = UDim2.new(0, 12, 0, 48)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

-- layout
local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Content

-- ============================================
-- TOGGLE FACTORY
-- ============================================
local function makeToggle(parent, text, key, desc)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 46)
    Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Btn.Text = ""
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 4, 0.6, 0)
    Indicator.Position = UDim2.new(0, 0, 0.2, 0)
    Indicator.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(80, 80, 100)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Btn
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 0, 20)
    Label.Position = UDim2.new(0, 16, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(240, 240, 250)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Btn

    if desc then
        local D = Instance.new("TextLabel")
        D.Size = UDim2.new(1, -80, 0, 14)
        D.Position = UDim2.new(0, 16, 0, 26)
        D.BackgroundTransparency = 1
        D.Text = desc
        D.TextColor3 = Color3.fromRGB(110, 110, 130)
        D.TextSize = 10
        D.Font = Enum.Font.Gotham
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.Parent = Btn
    end

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 34, 0, 18)
    Switch.Position = UDim2.new(1, -46, 0.5, -9)
    Switch.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(50, 50, 65)
    Switch.BorderSizePixel = 0
    Switch.Parent = Btn
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = CONFIG[key] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Dot.BorderSizePixel = 0
    Dot.Parent = Switch
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    Btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        local on = CONFIG[key]
        TweenService:Create(Dot, TweenInfo.new(0.2), {
            Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        TweenService:Create(Switch, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(50, 50, 65)
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(80, 80, 100)
        }):Play()

        -- Special handlers
        if key == "AutoSteal" then
            if on then startFly() else if not CONFIG.AutoGrab then stopFly() end end
        end
        if key == "AutoGrab" then
            if on then startFly() else if not CONFIG.AutoSteal then stopFly() end end
        end
    end)

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(38, 38, 50) }):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(28, 28, 36) }):Play()
    end)

    return Btn
end

-- ============================================
-- ESP SUBMENU
-- ============================================
local espExpanded = false
local espSubFrame

local function makeESPButton()
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 46)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
    Btn.Text = ""
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.Parent = Content
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 0, 46)
    Arrow.Position = UDim2.new(1, -30, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▶"
    Arrow.TextColor3 = Color3.fromRGB(200, 200, 220)
    Arrow.TextSize = 14
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Parent = Btn

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 0, 20)
    Label.Position = UDim2.new(0, 16, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = "ESP"
    Label.TextColor3 = Color3.fromRGB(240, 240, 250)
    Label.TextSize = 15
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Btn

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -60, 0, 14)
    Desc.Position = UDim2.new(0, 16, 0, 26)
    Desc.BackgroundTransparency = 1
    Desc.Text = "Egg / Player / Best"
    Desc.TextColor3 = Color3.fromRGB(150, 130, 180)
    Desc.TextSize = 10
    Desc.Font = Enum.Font.Gotham
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Btn

    -- Submenu frame
    espSubFrame = Instance.new("Frame")
    espSubFrame.Size = UDim2.new(1, -8, 0, 0)
    espSubFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    espSubFrame.BorderSizePixel = 0
    espSubFrame.ClipsDescendants = true
    espSubFrame.Parent = Content
    Instance.new("UICorner", espSubFrame).CornerRadius = UDim.new(0, 8)

    local SubLayout = Instance.new("UIListLayout")
    SubLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SubLayout.Padding = UDim.new(0, 4)
    SubLayout.Parent = espSubFrame

    local SubPad = Instance.new("UIPadding")
    SubPad.PaddingTop = UDim.new(0, 6)
    SubPad.PaddingBottom = UDim.new(0, 6)
    SubPad.PaddingLeft = UDim.new(0, 8)
    SubPad.PaddingRight = UDim.new(0, 8)
    SubPad.Parent = espSubFrame

    -- Sub toggles (smaller)
    local function subToggle(text, key)
        local S = Instance.new("TextButton")
        S.Size = UDim2.new(1, -8, 0, 32)
        S.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        S.Text = ""
        S.BorderSizePixel = 0
        S.AutoButtonColor = false
        S.Parent = espSubFrame
        Instance.new("UICorner", S).CornerRadius = UDim.new(0, 6)

        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -50, 1, 0)
        L.Position = UDim2.new(0, 12, 0, 0)
        L.BackgroundTransparency = 1
        L.Text = text
        L.TextColor3 = Color3.fromRGB(230, 230, 240)
        L.TextSize = 12
        L.Font = Enum.Font.GothamMedium
        L.TextXAlignment = Enum.TextXAlignment.Left
        
