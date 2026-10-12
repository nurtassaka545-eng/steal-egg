-- Steal a Egg v5 — Fly + Camera Follow + Submenu ESP + Auto Grab
-- Modern UI + Rainbow + Animation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CONFIG = {
    EggESP = true, PlayerESP = false, BestEggESP = true,
    AutoSteal = false, SpeedHack = false, AutoGrab = false,
    AntiBan = true, Rainbow = true, CameraFollow = true,
    FlySpeed = 50, SpeedHackSpeed = 120, GrabDelay = 0.5,
}

local RARITY = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Secret = 7, Cosmic = 8,
    Eternal = 9, Divine = 10,
}

local hue = 0
local function getRainbow()
    hue = (hue + 0.005) % 1
    return Color3.fromHSV(hue, 0.7, 1)
end

pcall(function()
    local env = getfenv and getfenv(0) or _G
    if env then
        env.getgenv = nil; env.getreg = nil; env.getgc = nil
        env.getupvalue = nil; env.getupvalues = nil
    end
end)

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
-- CAMERA FOLLOW (қарау функциясы)
-- ============================================
local cameraTarget = nil

local function setCameraTarget(part)
    cameraTarget = part
end

local function clearCameraTarget()
    cameraTarget = nil
end

-- Камераны нысанаға қарайды
task.spawn(function()
    while true do
        task.wait()
        if CONFIG.CameraFollow and cameraTarget and cameraTarget.Parent then
            local myChar = LP.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                -- Камера позициясы — ойыншы мен нысана арасында
                local targetPos = cameraTarget.Position
                local myPos = myHrp.Position
                local mid = (targetPos + myPos) / 2 + Vector3.new(0, 15, 0)
                local dir = (targetPos - myPos).Unit
                local camPos = mid - dir * 25
                Camera.CFrame = CFrame.new(camPos, targetPos)
            end
        end
    end
end)

-- ============================================
-- ESP
-- ============================================
local espCache = {}
local function createESP(part, color, label)
    if espCache[part] then espCache[part][1].Color3 = color; return end
    local box = Instance.new("SelectionBox")
    box.Adornee = part; box.Parent = part
    box.Color3 = color; box.LineThickness = 0.08; box.Transparency = 0.4
    
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 18)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true; bb.Parent = part
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = false
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb
    
    espCache[part] = { box, bb }
end

local function updateESP()
    for part, guis in pairs(espCache) do
        if not part.Parent then
            for _, g in ipairs(guis) do pcall(function() g:Destroy() end) end
            espCache[part] = nil
        end
    end
    local bestEgg = CONFIG.BestEggESP and getBestEgg() or nil
    if CONFIG.EggESP or CONFIG.BestEggESP then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                if CONFIG.BestEggESP and obj == bestEgg then
                    createESP(obj, Color3.fromRGB(255, 50, 50), "★ " .. obj.Name)
                elseif CONFIG.EggESP then
                    createESP(obj, Color3.fromRGB(50, 255, 50), obj.Name)
                end
            end
        end
    end
    if CONFIG.PlayerESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then createESP(hrp, Color3.fromRGB(255, 255, 50), plr.Name) end
            end
        end
    end
end

-- ============================================
-- FLY TO POSITION
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

local function getSpeed()
    return CONFIG.SpeedHack and CONFIG.SpeedHackSpeed or CONFIG.FlySpeed
end

-- ============================================
-- AUTO STEAL
-- ============================================
local stealing = false
local function autoSteal()
    if not CONFIG.AutoSteal or stealing then return end
    stealing = true
    local egg = getBestEgg()
    if not egg then stealing = false; return end
    
    setCameraTarget(egg)  -- камера яйцоға қарайды
    flyToPosition(egg.Position, getSpeed())
    task.wait(0.15)
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldBegin(); task.wait(0.1); prompt:InputHoldEnd()
            end)
        end
    end
    task.wait(CONFIG.GrabDelay)
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        setCameraTarget(spawn)
        flyToPosition(spawn.Position + Vector3.new(0, 5, 0), getSpeed())
    end
    task.wait(0.5)
    clearCameraTarget()
    stealing = false
end

-- ============================================
-- AUTO GRAB
-- ============================================
local grabbing = false
local function autoGrab()
    if not CONFIG.AutoGrab or grabbing then return end
    grabbing = true
    local egg = getBestEgg()
    if not egg then grabbing = false; return end
    
    setCameraTarget(egg)
    flyToPosition(egg.Position, getSpeed() * 1.5)
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd()
            end)
        end
    end
    task.wait(0.1)
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        setCameraTarget(spawn)
        flyToPosition(spawn.Position + Vector3.new(0, 5, 0), getSpeed() * 2)
    end
    task.wait(0.3)
    clearCameraTarget()
    grabbing = false
end

task.spawn(function()
    while true do task.wait(0.1); pcall(updateESP) end
end)
task.spawn(function()
    while true do task.wait(0.2); if CONFIG.AutoSteal then pcall(autoSteal) end end
end)
task.spawn(function()
    while true do task.wait(0.1); if CONFIG.AutoGrab then pcall(autoGrab) end end
end)

-- ============================================
-- UI — SMALLER
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealAEgg_v5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 350)
Main.Position = UDim2.new(0.5, -130, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(255, 100, 200)
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Stroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 10)
TitleFix.Position = UDim2.new(0, 0, 1, -10)
TitleFix.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -70, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Steal a Egg v5"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 13
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -58, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 30)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -46)
Content.Position = UDim2.new(0, 10, 0, 42)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 4)
Layout.Parent = Content

local function makeToggle(text, key, desc)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -6, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Btn.Text = ""; Btn.BorderSizePixel = 0; Btn.AutoButtonColor = false
    Btn.Parent = Content
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 7)
    
    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 3, 0.6, 0); Ind.Position = UDim2.new(0, 0, 0.2, 0)
    Ind.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(80, 80, 100)
    Ind.BorderSizePixel = 0; Ind.Parent = Btn
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(1, 0)
    
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -60, 0, 16); L.Position = UDim2.new(0, 12, 0, 4)
    L.BackgroundTransparency = 1; L.Text = text
    L.TextColor3 = Color3.fromRGB(240, 240, 250); L.TextSize = 11
    L.Font = Enum.Font.GothamMedium; L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = Btn
    
    if desc then
        local D = Instance.new("TextLabel")
        D.Size = UDim2.new(1, -60, 0, 12); D.Position = UDim2.new(0, 12, 0, 20)
        D.BackgroundTransparency = 1; D.Text = desc
        D.TextColor3 = Color3.fromRGB(110, 110, 130); D.TextSize = 8
        D.Font = Enum.Font.Gotham; D.TextXAlignment = Enum.TextXAlignment.Left
        D.Parent = Btn
    end
    
    local Sw = Instance.new("Frame")
    Sw.Size = UDim2.new(0, 28, 0, 15); Sw.Position = UDim2.new(1, -38, 0.5, -7.5)
    Sw.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(50, 50, 65)
    Sw.BorderSizePixel = 0; Sw.Parent = Btn
    Instance.new("UICorner", Sw).CornerRadius = UDim.new(1, 0)
    
    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 11, 0, 11)
    Dot.Position = CONFIG[key] and UDim2.new(1, -13, 0.5, -5.5) or UDim2.new(0, 2, 0.5, -5.5)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.BorderSizePixel = 0
    Dot.Parent = Sw
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    
    Btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        local on = CONFIG[key]
        TweenService:Create(Dot, TweenInfo.new(0.2), {Position = on and UDim2.new(1, -13, 0.5, -5.5) or UDim2.new(0, 2, 0.5, -5.5)}):Play()
        TweenService:Create(Sw, TweenInfo.new(0.2), {BackgroundColor3 = on and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(50, 50, 65)}):Play()
        TweenService:Create(Ind, TweenInfo.new(0.2), {BackgroundColor3 = on and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(80, 80, 100)}):Play()
    end)
end

local function makeESPButton()
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -6, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
    Btn.Text = ""; Btn.BorderSizePixel = 0; Btn.AutoButtonColor = false
    Btn.Parent = Content
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 7)
    
    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 16, 0, 36); Arrow.Position = UDim2.new(1, -22, 0, 0)
    Arrow.BackgroundTransparency = 1; Arrow.Text = "▶"
    Arrow.TextColor3 = Color3.fromRGB(200, 200, 220); Arrow.TextSize = 11
    Arrow.Font = Enum.Font.GothamBold; Arrow.Parent = Btn
    
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -50, 0, 16); L.Position = UDim2.new(0, 12, 0, 4)
    L.BackgroundTransparency = 1; L.Text = "ESP"
    L.TextColor3 = Color3.fromRGB(240, 240, 250); L.TextSize = 12
    L.Font = Enum.Font.GothamBold; L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = Btn
    
    local D = Instance.new("TextLabel")
    D.Size = UDim2.new(1, -50, 0, 12); D.Position = UDim2.new(0, 12, 0, 20)
    D.BackgroundTransparency = 1; D.Text = "Egg / Player / Best"
    D.TextColor3 = Color3.fromRGB(150, 130, 180); D.TextSize = 8
    D.Font = Enum.Font.Gotham; D.TextXAlignment = Enum.TextXAlignment.Left
    D.Parent = Btn
    
    local SubFrame = Instance.new("Frame")
    SubFrame.Size = UDim2.new(1, -6, 0, 0)
    SubFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    SubFrame.BorderSizePixel = 0; SubFrame.ClipsDescendants = true
    SubFrame.Parent = Content
    Instance.new("UICorner", SubFrame).CornerRadius = UDim.new(0, 7)
    
    local SubLayout = Instance.new("UIListLayout")
    SubLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SubLayout.Padding = UDim.new(0, 3)
    SubLayout.Parent = SubFrame
    
    local SubPad = Instance.new("UIPadding")
    SubPad.PaddingTop = UDim.new(0, 5); SubPad.PaddingBottom = UDim.new(0, 5)
    SubPad.PaddingLeft = UDim.new(0, 6); SubPad.PaddingRight = UDim.new(0, 6)
    SubPad.Parent = SubFrame
    
    local function subToggle(text, key)
        local S = Instance.new("TextButton")
        S.Size = UDim2.new(1, -6, 0, 26)
        S.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        S.Text = ""; S.BorderSizePixel = 0; S.AutoButtonColor = false
        S.Parent = SubFrame
        Instance.new("UICorner", S).CornerRadius = UDim.new(0, 5)
        
        local SL = Instance.new("TextLabel")
        SL.Size = UDim2.new(1, -40, 1, 0); SL.Position = UDim2.new(0, 10, 0, 0)
        SL.BackgroundTransparency = 1; SL.Text = text
        SL.TextColor3 = Color3.fromRGB(230, 230, 240); SL.TextSize = 10
        SL.Font = Enum.Font.GothamMedium; SL.TextXAlignment = Enum.TextXAlignment.Left
        SL.Parent = S
        
        local SD = Instance.new("Frame")
        SD.Size = UDim2.new(0, 11, 0, 11); SD.Position = UDim2.new(1, -18, 0.5, -5.5)
        SD.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(60, 60, 80)
        SD.BorderSizePixel = 0; SD.Parent = S
        Instance.new("UICorner", SD).CornerRadius = UDim.new(1, 0)
        
        S.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            TweenService:Create(SD, TweenInfo.new(0.2), {
                BackgroundColor3 = CONFIG[key] and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(60, 60, 80)
            }):Play()
        end)
    end
    subToggle("Egg ESP", "EggESP")
    subToggle("Player ESP", "PlayerESP")
    subToggle("Best Egg ESP", "BestEggESP")
    
    local expanded = false
    Btn.MouseButton1Click:Connect(function()
        expanded = not expanded
        TweenService:Create(SubFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = expanded and UDim2.new(1, -6, 0, 92) or UDim2.new(1, -6, 0, 0)
        }):Play()
        Arrow.Text = expanded and "▼" or "▶"
    end)
end

makeESPButton()
makeToggle("Auto Steal", "AutoSteal", "Ұшып яйцоға барып ұрлайды")
makeToggle("Auto Grab", "AutoGrab", "0.5с яйцо алып базаға қайтады")
makeToggle("Speed Hack", "SpeedHack", "Ұшу жылдамдығын арттырады")
makeToggle("Camera Follow", "CameraFollow", "Камера яйцоға қарайды")
makeToggle("Anti-Ban", "AntiBan", "Античиттен қорғаныс")
makeToggle("Rainbow Mode", "Rainbow", "Түс өзгерту")

-- DRAG
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 260, 0, 36) or UDim2.new(0, 260, 0, 350)
    }):Play()
    MinBtn.Text = minimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
end)

Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 260, 0, 350),
    Position = UDim2.new(0.5, -130, 0.5, -175)
}):Play()

task.spawn(function()
    while ScreenGui.Parent do
        if CONFIG.Rainbow then
            Stroke.Color = getRainbow()
            TitleText.TextColor3 = getRainbow()
        else
            Stroke.Color = Color3.fromRGB(255, 100, 200)
            TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        task.wait(0.05)
        end
        
