	local existingGui = game:GetService("CoreGui"):FindFirstChild("SkyChanger_Universal")
if existingGui then
	existingGui:Destroy()
end

-- Baru lanjutkan script normal
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleBar = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local MinimizeBtn = Instance.new("TextButton")
local ContentFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")

	local ScreenGui = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local TitleBar = Instance.new("Frame")
	local TitleLabel = Instance.new("TextLabel")
	local CloseBtn = Instance.new("TextButton")
	local MinimizeBtn = Instance.new("TextButton")
	local ContentFrame = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")

	-- Properti Utama
	ScreenGui.Name = "SkyChanger_Universal"
	ScreenGui.Parent = game:GetService("CoreGui")
	ScreenGui.ResetOnSpawn = false

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	MainFrame.Position = UDim2.new(0.5, -100, 0.5, -125)
	MainFrame.Size = UDim2.new(0, 200, 0, 250)
	MainFrame.ClipsDescendants = true

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 8)
	MainCorner.Parent = MainFrame

	-- Title Bar
	TitleBar.Name = "TitleBar"
	TitleBar.Parent = MainFrame
	TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	TitleBar.Size = UDim2.new(1, 0, 0, 30)

	TitleLabel.Parent = TitleBar
	TitleLabel.Text = "Sky Changer"
	TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
	TitleLabel.Size = UDim2.new(1, -60, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Font = Enum.Font.GothamBold

	-- Close Button
	CloseBtn.Parent = TitleBar
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.fromRGB(255,100,100)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
	CloseBtn.Position = UDim2.new(1, -25, 0, 5)
	CloseBtn.Size = UDim2.new(0, 20, 0, 20)

	-- Minimize Button
	MinimizeBtn.Parent = TitleBar
	MinimizeBtn.Text = "-"
	MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	MinimizeBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
	MinimizeBtn.Position = UDim2.new(1, -50, 0, 5)
	MinimizeBtn.Size = UDim2.new(0, 20, 0, 20)

	-- Content Frame
	ContentFrame.Parent = MainFrame
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Position = UDim2.new(0, 5, 0, 35)
	ContentFrame.Size = UDim2.new(1, -10, 1, -40)
	ContentFrame.CanvasSize = UDim2.new(0, 0, 3, 0)
	ContentFrame.ScrollBarThickness = 4

	UIListLayout.Parent = ContentFrame
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Fungsi Mengubah Skybox Custom (6 sisi berbeda)
	local function changeCustomSky(Bk, Dn, Ft, Lf, Rt, Up)
		local lighting = game:GetService("Lighting")
		local sky = lighting:FindFirstChildOfClass("Sky")

		if not sky then
			sky = Instance.new("Sky")
			sky.Parent = lighting
		end

		sky.SkyboxBk = "rbxassetid://" .. Bk
		sky.SkyboxDn = "rbxassetid://" .. Dn
		sky.SkyboxFt = "rbxassetid://" .. Ft
		sky.SkyboxLf = "rbxassetid://" .. Lf
		sky.SkyboxRt = "rbxassetid://" .. Rt
		sky.SkyboxUp = "rbxassetid://" .. Up
	end

	-- Fungsi Membuat Tombol
	local function createSkyOption(name, skyData)
		local btn = Instance.new("TextButton")
		btn.Parent = ContentFrame
		btn.Size = UDim2.new(1, -5, 0, 35)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.Text = name
		btn.TextColor3 = Color3.fromRGB(230, 230, 230)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			changeCustomSky(
				skyData.Bk,
				skyData.Dn,
				skyData.Ft,
				skyData.Lf,
				skyData.Rt,
				skyData.Up
			)
		end)
	end

	-- Daftar Skybox
	createSkyOption("Cloud Skybox", {
		Bk = 225469345,
		Dn = 225469349,
		Ft = 225469359,
		Lf = 225469364,
		Rt = 225469372,
		Up = 225469380
	})

	createSkyOption("Snow Skybox", {
		Bk = 155657655,
		Dn = 155674246,
		Ft = 155657609,
		Lf = 155657671,
		Rt = 155657619,
		Up = 155674931
	})	

	createSkyOption("Sea Skybox", {
		Bk = 144933338,
		Dn = 144931530,
		Ft = 144933262,
		Lf = 144933244,
		Rt = 144933299,
		Up = 144931564
	})	

	createSkyOption("Overcast Skybox", {
		Bk = 376646792,
		Dn = 376646872,
		Ft = 376646833,
		Lf = 376646821,
		Rt = 376646768,
		Up = 376646842
	})	


	createSkyOption("Purple Nebula", {
		Bk = 159454299,
		Dn = 159454296,
		Ft = 159454293,
		Lf = 159454286,
		Rt = 159454300,
		Up = 159454288
	})

	createSkyOption("Galaxy Sky", {
		Bk = 159248188,
		Dn = 159248183,
		Ft = 159248187,
		Lf = 159248173,
		Rt = 159248192,
		Up = 159248176
	})

	createSkyOption("Night Sky", {
		Bk = 12064107,
		Dn = 12064152,
		Ft = 12064121,
		Lf = 12063984,
		Rt = 12064115,
		Up = 12064131
	})

	createSkyOption("Pink Dream", {
		Bk = 271042516,
		Dn = 271077243,
		Ft = 271042556,
		Lf = 271042310,
		Rt = 271042467,
		Up = 271077958
	})

	createSkyOption("Horror Red", {
		Bk = 570557514,
		Dn = 570557775,
		Ft = 570557559,
		Lf = 570557620,
		Rt = 570557672,
		Up = 570557727
	})
	
	createSkyOption("Mountain Air", {
	Bk = 5084576400,
	Dn = 5084576400,
	Ft = 5084576400,
	Lf = 5084576400,
	Rt = 5084576400,
	Up = 5084576400
})

createSkyOption("Snow Sky", {
	Bk = 149397692,
	Dn = 149397686,
	Ft = 149397697,
	Lf = 149397684,
	Rt = 149397688,
	Up = 149397702
})

-- Frozen Ice Sky
createSkyOption("Frozen Ice", {
	Bk = 218955819,
	Dn = 218953419,
	Ft = 218954524,
	Lf = 218958493,
	Rt = 218957134,
	Up = 218950090
})

	-- Ubah CanvasSize agar scroll lebih panjang
	ContentFrame.CanvasSize = UDim2.new(0, 0, 8, 0)

	-- Minimize Logic
	local minimized = false
	MinimizeBtn.MouseButton1Click:Connect(function()
		if not minimized then
			MainFrame:TweenSize(UDim2.new(0, 200, 0, 30), "Out", "Quad", 0.3, true)
			ContentFrame.Visible = false
			MinimizeBtn.Text = "+"
		else
			MainFrame:TweenSize(UDim2.new(0, 200, 0, 250), "Out", "Quad", 0.3, true)
			ContentFrame.Visible = true
			MinimizeBtn.Text = "-"
		end
		minimized = not minimized
	end)

	-- Close Logic
	CloseBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	-- Dragging
	local UserInputService = game:GetService("UserInputService")
	local dragging = false
	local dragStart
	local startPos

	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	TitleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
