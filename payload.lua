-- Steal a Egg v2 | Auto Steal + Best Egg ESP + Anti-Ban
-- payload — keyui.lua арқылы іске қосылады

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local CONFIG = {
    AutoSteal = true,
    ESP = true,
    AntiBan = true,
    StealDelay = 0.8,
    ReturnToBase = true,
    WalkSpeedBoost = 32,
}

local RARITY = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Secret = 7, Cosmic = 8,
    Eternal = 9, Divine = 10,
}

-- ANTI-BAN
local function antiBanInit()
    if not CONFIG.AntiBan then return end
    local env = getfenv and getfenv(0) or _G
    if env then
        pcall(function()
            env.getgenv = nil; env.getreg = nil; env.getgc = nil
            env.getupvalue = nil; env.getupvalues = nil
        end)
    end
    pcall(function()
        local oldHttpGet = game.HttpGet
        game.HttpGet = function(self, url, ...)
            if type(url) == "string" and url:find("Delta") then return "" end
            return oldHttpGet(self, url, ...)
        end
    end)
end
antiBanInit()

-- BEST EGG
local function getBestEgg()
    local best, bestScore = nil, 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            local score = 0
            for rar, tier in pairs(RARITY) do
                if obj.Name:find(rar) then score = math.max(score, tier) end
            end
            score = score + obj.Size.Magnitude * 0.1
            if score > bestScore then
                best, bestScore = obj, score
            end
        end
    end
    return best, bestScore
end

-- ESP
local espCache = {}
local function createESP(part, isBest)
    if espCache[part] then return end
    local box = Instance.new("SelectionBox")
    box.Adornee = part
    box.Parent = part
    box.Color3 = isBest and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
    box.LineThickness = isBest and 0.15 or 0.05
    box.Transparency = isBest and 0.3 or 0.7
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = (isBest and "★ BEST: " or "") .. part.Name
    lbl.TextColor3 = isBest and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Parent = bb
    espCache[part] = { box, bb }
end

local function updateESP()
    if not CONFIG.ESP then return end
    for part, guis in pairs(espCache) do
        if not part.Parent then
            for _, g in ipairs(guis) do g:Destroy() end
            espCache[part] = nil
        end
    end
    local bestEgg = getBestEgg()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            createESP(obj, obj == bestEgg)
        end
    end
end

-- AUTO STEAL
local stealing = false
local function autoSteal()
    if not CONFIG.AutoSteal or stealing then return end
    stealing = true
    local egg = getBestEgg()
    if not egg then stealing = false; return end
    local oldPos = LP.Character and LP.Character.HumanoidRootPart.CFrame
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    local oldSpeed = hum and hum.WalkSpeed or 16
    if hum then hum.WalkSpeed = CONFIG.WalkSpeedBoost end
    if LP.Character and LP.Character.PrimaryPart then
        local offset = Vector3.new(math.random(-2, 2), 2, math.random(-2, 2))
        LP.Character.PrimaryPart.CFrame = CFrame.new(egg.Position + offset)
    end
    task.wait(0.15)
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end
    end
    task.wait(CONFIG.StealDelay)
    if CONFIG.ReturnToBase and oldPos and LP.Character and LP.Character.PrimaryPart then
        LP.Character.PrimaryPart.CFrame = oldPos
    end
    if hum then hum.WalkSpeed = oldSpeed end
    task.wait(math.random(50, 200) / 100)
    stealing = false
end

task.spawn(function()
    while true do task.wait(0.1); if CONFIG.ESP then updateESP() end end
end)
task.spawn(function()
    while true do task.wait(0.5); if CONFIG.AutoSteal then autoSteal() end end
end)

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealAEgg_Hub"
ScreenGui.Parent = game.CoreGui
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 180)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Steal a Egg v2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local function makeToggle(text, key, row)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 30)
    btn.Position = UDim2.new(0.1, 0, 0, 40 + row * 35)
    btn.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(30, 130, 60) or Color3.fromRGB(80, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.Text = text .. (CONFIG[key] and " [ON]" or " [OFF]")
    btn.Parent = Frame
    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(30, 130, 60) or Color3.fromRGB(80, 40, 40)
        btn.Text = text .. (CONFIG[key] and " [ON]" or " [OFF]")
    end)
end
makeToggle("Auto Steal", "AutoSteal", 0)
makeToggle("Best Egg ESP", "ESP", 1)
makeToggle("Anti-Ban", "AntiBan", 2)

print("[StealAEgg v2] loaded.")
