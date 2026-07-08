local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- KONFIGURASI
local CLIMB_SPEED = 12
local IS_CLIMBING = false
local IS_SWIMMING = false

-- UI UTAMA (ScreenGui)
local screenGui = Instance.new("ScreenGui", Player.PlayerGui)
screenGui.Name = "AnimMonitorGui"
screenGui.ResetOnSpawn = false

--- 1. TOMBOL UTAMA UNTUK BUKA MENU ---
local openMenuBtn = Instance.new("TextButton", screenGui)
openMenuBtn.Size = UDim2.new(0, 130, 0, 40)
openMenuBtn.Position = UDim2.new(0.02, 0, 0.85, 0)
openMenuBtn.Text = "Open Anim Tool"
openMenuBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
openMenuBtn.TextColor3 = Color3.new(1, 1, 1)
openMenuBtn.Font = Enum.Font.SourceSansBold
openMenuBtn.TextSize = 16
Instance.new("UICorner", openMenuBtn).CornerRadius = UDim.new(0, 6)

--- 2. PANEL MENU UTAMA ---
local menuPanel = Instance.new("Frame", screenGui)
menuPanel.Size = UDim2.new(0, 220, 0, 170)
menuPanel.Position = UDim2.new(0.5, -110, 0.4, -85)
menuPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menuPanel.Visible = false
Instance.new("UICorner", menuPanel).CornerRadius = UDim.new(0, 8)

-- Judul Menu
local menuTitle = Instance.new("TextLabel", menuPanel)
menuTitle.Size = UDim2.new(1, 0, 0, 30)
menuTitle.Text = "Anim Debugger"
menuTitle.TextColor3 = Color3.new(1, 1, 1)
menuTitle.Font = Enum.Font.SourceSansBold
menuTitle.TextSize = 16
menuTitle.BackgroundTransparency = 1

--- 3. TOMBOL CLOSE (X) ---
local closeBtn = Instance.new("TextButton", menuPanel)
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

--- 4. TOMBOL AKTIFKAN CLIMB ---
local toggleClimbBtn = Instance.new("TextButton", menuPanel)
toggleClimbBtn.Size = UDim2.new(0, 180, 0, 40)
toggleClimbBtn.Position = UDim2.new(0.5, -90, 0, 40)
toggleClimbBtn.Text = "TEST CLIMB: OFF"
toggleClimbBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleClimbBtn.TextColor3 = Color3.new(1, 1, 1)
toggleClimbBtn.Font = Enum.Font.Code
toggleClimbBtn.TextSize = 14
Instance.new("UICorner", toggleClimbBtn)

--- 5. TOMBOL AKTIFKAN SWIM ---
local toggleSwimBtn = Instance.new("TextButton", menuPanel)
toggleSwimBtn.Size = UDim2.new(0, 180, 0, 40)
toggleSwimBtn.Position = UDim2.new(0.5, -90, 0, 95)
toggleSwimBtn.Text = "TEST SWIM: OFF"
toggleSwimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleSwimBtn.TextColor3 = Color3.new(1, 1, 1)
toggleSwimBtn.Font = Enum.Font.Code
toggleSwimBtn.TextSize = 14
Instance.new("UICorner", toggleSwimBtn)


--- LOGIKA DRAGGABLE (BISA DIGESER) ---
local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	menuPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

menuPanel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = menuPanel.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

menuPanel.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)


--- LOGIKA UTAMA ANIMASI ---

local currentClimbTrack = nil
local swimForce = nil

-- Mencari Animasi Asli
local function getAnimId(animName)
	local animateScript = Character:FindFirstChild("Animate")
	if animateScript and animateScript:FindFirstChild(animName) then
		local obj = animateScript[animName]:FindFirstChildOfClass("Animation")
		return obj and obj.AnimationId or "Tidak Ditemukan"
	end
	return "Tidak Ditemukan"
end

-- Toggle Climb
local function toggleClimb()
	if IS_SWIMMING then return end
	IS_CLIMBING = not IS_CLIMBING
	
	if IS_CLIMBING then
		toggleClimbBtn.Text = "CLIMB: ACTIVE"
		toggleClimbBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		
		local animateScript = Character:FindFirstChild("Animate")
		if animateScript and animateScript:FindFirstChild("climb") then
			local anim = animateScript.climb:FindFirstChildOfClass("Animation")
			if anim then
				print(" Memantau Animasi Climb ID: " .. tostring(anim.AnimationId))
				currentClimbTrack = Humanoid:LoadAnimation(anim)
				currentClimbTrack:Play()
				currentClimbTrack:AdjustSpeed(0)
			end
		end
		Humanoid.PlatformStand = true
	else
		toggleClimbBtn.Text = "TEST CLIMB: OFF"
		toggleClimbBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		if currentClimbTrack then currentClimbTrack:Stop() end
		Humanoid.PlatformStand = false
	end
end

-- Toggle Swim (FIXED VERSION)
local function toggleSwim()
	if IS_CLIMBING then return end
	IS_SWIMMING = not IS_SWIMMING
	
	if IS_SWIMMING then
		toggleSwimBtn.Text = "SWIM: ACTIVE"
		toggleSwimBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
		print(" Memantau Animasi Swim ID: " .. getAnimId("swim"))
		
		-- KUNCI UTAMA: Matikan state GettingUp agar Roblox tidak membatalkan renang secara paksa
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
		
		-- Buat BodyForce anti gravitasi khusus berenang agar ava melayang mulus
		swimForce = Instance.new("BodyForce")
		swimForce.Force = Vector3.new(0, workspace.Gravity * RootPart:GetMass(), 0)
		swimForce.Parent = RootPart
	else
		toggleSwimBtn.Text = "TEST SWIM: OFF"
		toggleSwimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		
		if swimForce then
			swimForce:Destroy()
			swimForce = nil
		end
		
		-- Kembalikan state awal ke normal
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function openMenu()
	menuPanel.Visible = true
	openMenuBtn.Visible = false
end

local function closeMenu()
	menuPanel.Visible = false
	openMenuBtn.Visible = true
	if IS_CLIMBING then toggleClimb() end
	if IS_SWIMMING then toggleSwim() end
end

toggleClimbBtn.MouseButton1Click:Connect(toggleClimb)
toggleSwimBtn.MouseButton1Click:Connect(toggleSwim)
openMenuBtn.MouseButton1Click:Connect(openMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)

-- Loop Utama (Heartbeat)
RunService.Heartbeat:Connect(function()
	if IS_CLIMBING and RootPart then
		RootPart.Velocity = Vector3.new(0, CLIMB_SPEED, 0)
		if currentClimbTrack then currentClimbTrack:AdjustSpeed(1) end
	elseif IS_SWIMMING and RootPart then
		-- Paksa terus state swimming secara agresif di setiap frame
		Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	end
end)

Humanoid.Died:Connect(function()
	if currentClimbTrack then currentClimbTrack:Stop() end
	if swimForce then swimForce:Destroy() end
	screenGui:Destroy()
end)
