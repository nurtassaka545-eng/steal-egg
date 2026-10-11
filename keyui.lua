-- Steal a Egg v2 — Key System (nurtassoft)
-- loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/nurtassaka545-eng/steal-egg/main/keyui.lua"))()

local KEYS_URL = "https://raw.githubusercontent.com/nurtassaka545-eng/steal-egg/main/keys.txt"
local PAYLOAD_URL = "https://raw.githubusercontent.com/nurtassaka545-eng/steal-egg/main/payload.lua"
local ADMIN_KEY = "nurtassoft-ADMIN"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local function getHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id then return id end
    return tostring(LP.UserId) .. "-" .. tostring(LP.AccountAge)
end

local function checkKey(input)
    if input == ADMIN_KEY then
        return true, "admin", 0
    end
    local ok, body = pcall(function()
        return game:HttpGet(KEYS_URL .. "?t=" .. os.time())
    end)
    if not ok or not body then return false, "server-error", 0 end
    local hwid = getHWID()
    local now = os.time()
    for line in body:gmatch("[^\r\n]+") do
        local key, expiryStr, savedHwid = line:match("^([^|]+)|([^|]*)|(.*)$")
        if key and key == input then
            local expiry = tonumber(expiryStr) or 0
            if expiry > 0 and now > expiry then
                return false, "expired", expiry
            end
            if savedHwid and savedHwid ~= "" and savedHwid ~= "ADMIN" then
                if savedHwid ~= hwid then
                    return false, "hwid-mismatch", expiry
                end
            end
            local remaining = expiry > 0 and (expiry - now) or 0
            local plan = expiry == 0 and "admin" or (remaining > 86400 and "5d+" or "1d")
            return true, plan, expiry
        end
    end
    return false, "notfound", 0
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeySystem"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 340, 0, 190)
Frame.Position = UDim2.new(0.5, -170, 0.5, -95)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = Frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Steal a Egg v2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = Frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 16)
sub.Position = UDim2.new(0, 0, 0, 40)
sub.BackgroundTransparency = 1
sub.Text = "nurtassoft key required"
sub.TextColor3 = Color3.fromRGB(150, 150, 160)
sub.TextScaled = true
sub.Font = Enum.Font.Gotham
sub.Parent = Frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(0.85, 0, 0, 34)
box.Position = UDim2.new(0.075, 0, 0, 62)
box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "nurtassoft-XXXX-XXXX"
box.Text = ""
box.TextScaled = true
box.Font = Enum.Font.Gotham
box.ClearTextOnFocus = false
box.Parent = Frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = box

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0, 100)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 100, 100)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = Frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.85, 0, 0, 34)
btn.Position = UDim2.new(0.075, 0, 0, 126)
btn.BackgroundColor3 = Color3.fromRGB(30, 130, 60)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Text = "Кіру"
btn.TextScaled = true
btn.Font = Enum.Font.GothamBold
btn.Parent = Frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = btn

btn.MouseButton1Click:Connect(function()
    local input = box.Text
    if input == "" then
        status.Text = "Кілт енгіз"
        return
    end
    status.Text = "Тексерілуде..."
    status.TextColor3 = Color3.fromRGB(200, 200, 100)
    task.spawn(function()
        local ok, plan, expiry = checkKey(input)
        if ok then
            if plan == "admin" then
                status.Text = "OK — ADMIN (шексіз)"
            else
                local rem = expiry - os.time()
                local days = math.floor(rem / 86400)
                local hours = math.floor((rem % 86400) / 3600)
                status.Text = "OK — " .. days .. "к " .. hours .. "с қалды"
            end
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(0.6)
            Frame:Destroy()
            loadstring(game:HttpGet(PAYLOAD_URL .. "?t=" .. os.time()))()
        else
            local reasons = {
                ["notfound"] = "Кілт табылмады",
                ["expired"] = "Мерзімі бітті",
                ["hwid-mismatch"] = "Басқа құрылғыға байланған",
                ["server-error"] = "Сервер қатесі",
            }
            status.Text = reasons[plan] or ("Қате: " .. tostring(plan))
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end)
