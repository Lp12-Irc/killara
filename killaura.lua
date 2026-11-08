-- Kill Aura | KIT PVP | Humanized
-- Lang: Luau | Target: Roblox Client Executor | Win: tool:Activate() jitter

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

local CFG = {
    Enabled    = true,
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

local function humanDelay()
    local base = CFG.MinDelay + math.random() * (CFG.MaxDelay - CFG.MinDelay)
    if math.random() < 0.12 then
        base = base + math.random() * 0.08
    end
    return base
end

local function getChar()   return LP.Character end
local function getHRP(c)   return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c)   return c and c:FindFirstChild("Humanoid") end

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
        if d < bestDist then
            bestDist = d
            best     = pc
        end
    end

    return best
end

local function smoothFace(selfHRP, targetHRP)
    if not CFG.FaceTarget then return end
    local dir = (targetHRP.Position - selfHRP.Position) * Vector3.new(1, 0, 1)
    if dir.Magnitude < 0.01 then return end
    selfHRP.CFrame = CFrame.new(selfHRP.Position, selfHRP.Position + dir)
end

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

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == CFG.ToggleKey then
        CFG.Enabled = not CFG.Enabled
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title    = "Kill Aura",
                Text     = CFG.Enabled and "ON" or "OFF",
                Duration = 2,
            })
        end)
    end
end)

LP.CharacterAdded:Connect(function() end)
