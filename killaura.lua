-- Kill Aura | KIT PVP | Humanized + GUI
-- Lang: Luau | Target: Roblox Client Executor

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LP = Players.LocalPlayer

-- ─── CONFIG ───────────────────────────────────────────────────────────────────
local CFG = {
    Enabled    = false,
    Range      = 7,
    MinDelay   = 0.20,
    MaxDelay   = 0.38,
    MissChance = 0.06,
    FaceTarget = true,
    TeamCheck  = false,
    ToggleKey  = Enum.KeyCode.RightControl,
}

local lastSwing    = 0
local nextCooldown = 0

-- ─── CORE ─────────────────────────────────────────────────────────────────────
local function humanDelay()
    local base = CFG.MinDelay + math.random() * (CFG.MaxDelay - CFG.MinDelay)
    if math.random() < 0.12 then base = base + math.random() * 0.08 end
    return base
end

local function getChar()  return LP.Character end
local function getHRP(c)  return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c)  return c and c:FindFirstChild("Humanoid") end

local function getEquippedTool(char)
    if not char then return nil end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
end

local function nearestEnemy()
    local char    = getChar()
    local selfHRP = getHRP(char)
    if not selfHRP then return nil end
    local best, bestDist = nil, CFG.Range
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if CFG.TeamCheck and p.Team == LP.Team then continue end
        local pc  = p.Character
        if not pc then continue end
        local hrp = getHRP(pc)
        local hum = getHum(pc)
        if not hrp or not hum or hum.Health <= 0 then continue end
        local d = (selfHRP.Position - hrp.Position).Magnitude
        if d < bestDist then bestDist = d; best = pc end
    end
    return best
end

local function smoothFace(selfHRP, targetHRP)
    if not CFG.FaceTarget then return end
    local dir = (targetHRP.Position - selfHRP.Position) * Vector3.new(1,0,1)
    if dir.Magnitude < 0.01 then return end
    selfHRP.CFrame = CFrame.new(selfHRP.Position, selfHRP.Position + dir)
end

-- ─── GUI ──────────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillAuraGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

-- Main Frame
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 280)
Main.Position = UDim2.new(0, 20, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Stroke
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(80, 80, 180)
stroke.Thickness = 1.5

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚔ Kill Aura | KIT PVP"
Title.TextColor3 = Color3.fromRGB(220, 220, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Status dot
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 10, 0, 10)
StatusDot.Position = UDim2.new(1, -18, 0.5, -5)
StatusDot.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = TitleBar
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

-- helper: label
local function makeLabel(parent, text, posY)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 16)
    l.Position = UDim2.new(0, 10, 0, posY)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(180, 180, 210)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- helper: value label (right side)
local function makeValueLabel(parent, text, posY)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 50, 0, 16)
    l.Position = UDim2.new(1, -58, 0, posY)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(120, 180, 255)
    l.TextSize = 12
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Right
    l.Parent = parent
    return l
end

-- helper: slider
local function makeSlider(parent, posY, min, max, default, onChange)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, posY)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    track.BorderSizePixel = 0
    track.Parent = parent
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 100, 220)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min)/(max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(180, 190, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local trackPos  = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local rel = math.clamp((inp.Position.X - trackPos) / trackSize, 0, 1)
        local val = min + (max - min) * rel
        fill.Size  = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        onChange(val)
    end)

    return track
end

-- ── Toggle Button ─────────────────────────────────────────────────────────────
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 34)
ToggleBtn.Position = UDim2.new(0, 10, 0, 44)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "Kill Aura: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(220, 80, 80)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Main
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local function updateToggleVisual()
    if CFG.Enabled then
        ToggleBtn.Text = "Kill Aura: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(80, 220, 120)
        TweenService:Create(StatusDot, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        }):Play()
    else
        ToggleBtn.Text = "Kill Aura: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(220, 80, 80)
        TweenService:Create(StatusDot, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        }):Play()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    CFG.Enabled = not CFG.Enabled
    updateToggleVisual()
end)

-- ── Range Slider ──────────────────────────────────────────────────────────────
makeLabel(Main, "Range", 90)
local RangeVal = makeValueLabel(Main, CFG.Range.." st", 90)
makeSlider(Main, 110, 3, 20, CFG.Range, function(v)
    CFG.Range = math.floor(v + 0.5)
    RangeVal.Text = CFG.Range.." st"
end)

-- ── Min Delay Slider ──────────────────────────────────────────────────────────
makeLabel(Main, "Min Delay", 130)
local MinVal = makeValueLabel(Main, string.format("%.2fs", CFG.MinDelay), 130)
makeSlider(Main, 150, 0.10, 0.50, CFG.MinDelay, function(v)
    CFG.MinDelay = math.floor(v * 100 + 0.5) / 100
    if CFG.MinDelay > CFG.MaxDelay then CFG.MinDelay = CFG.MaxDelay end
    MinVal.Text = string.format("%.2fs", CFG.MinDelay)
end)

-- ── Max Delay Slider ──────────────────────────────────────────────────────────
makeLabel(Main, "Max Delay", 170)
local MaxVal = makeValueLabel(Main, string.format("%.2fs", CFG.MaxDelay), 170)
makeSlider(Main, 190, 0.20, 0.80, CFG.MaxDelay, function(v)
    CFG.MaxDelay = math.floor(v * 100 + 0.5) / 100
    if CFG.MaxDelay < CFG.MinDelay then CFG.MaxDelay = CFG.MinDelay end
    MaxVal.Text = string.format("%.2fs", CFG.MaxDelay)
end)

-- ── Face Target Toggle ────────────────────────────────────────────────────────
local FaceBtn = Instance.new("TextButton")
FaceBtn.Size = UDim2.new(1, -20, 0, 28)
FaceBtn.Position = UDim2.new(0, 10, 0, 212)
FaceBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
FaceBtn.BorderSizePixel = 0
FaceBtn.Text = "Face Target: ON"
FaceBtn.TextColor3 = Color3.fromRGB(80, 220, 120)
FaceBtn.TextSize = 12
FaceBtn.Font = Enum.Font.Gotham
FaceBtn.Parent = Main
Instance.new("UICorner", FaceBtn).CornerRadius = UDim.new(0, 6)

FaceBtn.MouseButton1Click:Connect(function()
    CFG.FaceTarget = not CFG.FaceTarget
    FaceBtn.Text = "Face Target: " .. (CFG.FaceTarget and "ON" or "OFF")
    FaceBtn.TextColor3 = CFG.FaceTarget
        and Color3.fromRGB(80, 220, 120)
        or  Color3.fromRGB(220, 80, 80)
end)

-- ── Hotkey hint ───────────────────────────────────────────────────────────────
local HintLabel = Instance.new("TextLabel")
HintLabel.Size = UDim2.new(1, -20, 0, 20)
HintLabel.Position = UDim2.new(0, 10, 0, 250)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "Toggle: RightCtrl  |  Drag to move"
HintLabel.TextColor3 = Color3.fromRGB(90, 90, 110)
HintLabel.TextSize = 10
HintLabel.Font = Enum.Font.Gotham
HintLabel.Parent = Main

-- ─── MAIN LOOP ────────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    local now = tick()
    if now - lastSwing < nextCooldown then return end

    local char    = getChar()
    if not char   then return end
    local selfHRP = getHRP(char)
    local selfHum = getHum(char)
    if not selfHRP or not selfHum or selfHum.Health <= 0 then return end

    local tool = getEquippedTool(char)
    if not tool then return end

    local target = nearestEnemy()
    if not target then return end
    local targetHRP = getHRP(target)
    if not targetHRP then return end

    if math.random() < CFG.MissChance then
        lastSwing    = now
        nextCooldown = humanDelay() * 0.4
        return
    end

    smoothFace(selfHRP, targetHRP)
    tool:Activate()
    lastSwing    = now
    nextCooldown = humanDelay()
end)

-- ─── KEYBOARD TOGGLE ──────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == CFG.ToggleKey then
        CFG.Enabled = not CFG.Enabled
        updateToggleVisual()
    end
end)

LP.CharacterAdded:Connect(function() end)
