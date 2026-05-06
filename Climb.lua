local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local RunService = game:GetService("RunService")

-- KONFIGURASI
local CLIMB_SPEED = 12
local IS_CLIMBING = false

-- UI SETUP
local screenGui = Instance.new("ScreenGui", Player.PlayerGui)
screenGui.Name = "AnimMonitorGui"

local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.new(0, 160, 0, 45)
toggleBtn.Position = UDim2.new(0.8, 0, 0.8, 0)
toggleBtn.Text = "TEST CLIMB: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.Code

local uiCorner = Instance.new("UICorner", toggleBtn)

-- FUNGSI UNTUK MENDAPATKAN ANIMASI CLIMB ASLI DARI AVATAR
local function getClimbAnimation()
    local animateScript = Character:FindFirstChild("Animate")
    if animateScript and animateScript:FindFirstChild("climb") then
        local climbObj = animateScript.climb:FindFirstChildOfClass("Animation")
        return climbObj
    end
    return nil
end

local currentTrack = nil

local function toggleClimb()
    IS_CLIMBING = not IS_CLIMBING
    
    if IS_CLIMBING then
        toggleBtn.Text = "CLIMB: ACTIVE"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        -- Ambil animasi climb asli dari karakter
        local anim = getClimbAnimation()
        if anim then
            print("Memantau Animasi ID: " .. tostring(anim.AnimationId))
            currentTrack = Humanoid:LoadAnimation(anim)
            currentTrack:Play()
            currentTrack:AdjustSpeed(0) -- Mulai dari diam
        end
        
        Humanoid.PlatformStand = true
    else
        toggleBtn.Text = "TEST CLIMB: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
        if currentTrack then currentTrack:Stop() end
        Humanoid.PlatformStand = false
    end
end

toggleBtn.MouseButton1Click:Connect(toggleClimb)

RunService.Heartbeat:Connect(function()
    if IS_CLIMBING then
        -- Memberikan daya angkat agar ava melayang ke atas
        RootPart.Velocity = Vector3.new(0, CLIMB_SPEED, 0)
        
        -- Sinkronisasi kecepatan animasi dengan gerakan
        if currentTrack then
            currentTrack:AdjustSpeed(1)
        end
    end
end)
