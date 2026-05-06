--// HAPUS GUI LAMA AGAR TIDAK MENUMPUK
local CoreGui = game:GetService("CoreGui")
local existingGui = CoreGui:FindFirstChild("SkyChanger_Universal")
if existingGui then
	existingGui:Destroy()
end

--// SERVICES
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

--// GUI OBJECTS
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleBar = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local MinimizeBtn = Instance.new("TextButton")
local ContentFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")

--// SCREEN GUI
ScreenGui.Name = "SkyChanger_Universal"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

--// MAIN FRAME (MODERN STAR SKY STYLE)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 12, 32) -- Dark Blue
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -170)
MainFrame.Size = UDim2.new(0, 280, 0, 340)
MainFrame.ClipsDescendants = true
MainFrame.BorderSizePixel = 0

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(90, 130, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(10,15,35)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20,25,60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8,12,32))
}
MainGradient.Rotation = 90
MainGradient.Parent = MainFrame

--// TITLE BAR
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 20, 50)
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = TitleBar

TitleLabel.Parent = TitleBar
TitleLabel.Text = "✦ Sky Changer"
TitleLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16

--// CLOSE BUTTON
CloseBtn.Parent = TitleBar
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 90)
CloseBtn.Position = UDim2.new(1, -32, 0, 8)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.BorderSizePixel = 0

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

--// MINIMIZE BUTTON
MinimizeBtn.Parent = TitleBar
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.TextColor3 = Color3.fromRGB(220,220,255)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 90)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 8)
MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
MinimizeBtn.BorderSizePixel = 0

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinimizeBtn

--// CONTENT FRAME
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 8, 0, 45)
ContentFrame.Size = UDim2.new(1, -16, 1, -53)
ContentFrame.CanvasSize = UDim2.new(0, 0, 10, 0)
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(120,160,255)
ContentFrame.BorderSizePixel = 0

UIListLayout.Parent = ContentFrame
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

--// SKY FUNCTION
local function changeCustomSky(Bk, Dn, Ft, Lf, Rt, Up)
	local sky = Lighting:FindFirstChildOfClass("Sky")

	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end

	sky.SkyboxBk = "rbxassetid://" .. Bk
	sky.SkyboxDn = "rbxassetid://" .. Dn
	sky.SkyboxFt = "rbxassetid://" .. Ft
	sky.SkyboxLf = "rbxassetid://" .. Lf
	sky.SkyboxRt = "rbxassetid://" .. Rt
	sky.SkyboxUp = "rbxassetid://" .. Up
end

--// BUTTON CREATOR
local function createSkyOption(name, skyData)
	local btn = Instance.new("TextButton")
	btn.Parent = ContentFrame
	btn.Size = UDim2.new(1, -4, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(18, 28, 65)
	btn.Text = "☁ " .. name
	btn.TextColor3 = Color3.fromRGB(230,240,255)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(80,120,255)
	btnStroke.Transparency = 0.4
	btnStroke.Parent = btn

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

--// SKYBOX LIST
createSkyOption("Cloud Skybox", {
	Bk = 225469345, Dn = 225469349, Ft = 225469359,
	Lf = 225469364, Rt = 225469372, Up = 225469380
})

createSkyOption("Snow Skybox", {
	Bk = 155657655, Dn = 155674246, Ft = 155657609,
	Lf = 155657671, Rt = 155657619, Up = 155674931
})

createSkyOption("Sea Skybox", {
	Bk = 144933338, Dn = 144931530, Ft = 144933262,
	Lf = 144933244, Rt = 144933299, Up = 144931564
})

createSkyOption("Overcast Skybox", {
	Bk = 376646792, Dn = 376646872, Ft = 376646833,
	Lf = 376646821, Rt = 376646768, Up = 376646842
})

createSkyOption("Purple Nebula", {
	Bk = 159454299, Dn = 159454296, Ft = 159454293,
	Lf = 159454286, Rt = 159454300, Up = 159454288
})

createSkyOption("Galaxy Sky", {
	Bk = 159248188, Dn = 159248183, Ft = 159248187,
	Lf = 159248173, Rt = 159248192, Up = 159248176
})

createSkyOption("Night Sky", {
	Bk = 12064107, Dn = 12064152, Ft = 12064121,
	Lf = 12063984, Rt = 12064115, Up = 12064131
})

createSkyOption("Pink Dream", {
	Bk = 271042516, Dn = 271077243, Ft = 271042556,
	Lf = 271042310, Rt = 271042467, Up = 271077958
})

createSkyOption("Horror Red", {
	Bk = 570557514, Dn = 570557775, Ft = 570557559,
	Lf = 570557620, Rt = 570557672, Up = 570557727
})

createSkyOption("Mountain Air", {
	Bk = 5084576400, Dn = 5084576400, Ft = 5084576400,
	Lf = 5084576400, Rt = 5084576400, Up = 5084576400
})

createSkyOption("Snow Sky", {
	Bk = 149397692, Dn = 149397686, Ft = 149397697,
	Lf = 149397684, Rt = 149397688, Up = 149397702
})

createSkyOption("Frozen Ice", {
	Bk = 218955819, Dn = 218953419, Ft = 218954524,
	Lf = 218958493, Rt = 218957134, Up = 218950090
})

--// MINIMIZE
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	if not minimized then
		MainFrame:TweenSize(UDim2.new(0, 280, 0, 38), "Out", "Quad", 0.3, true)
		ContentFrame.Visible = false
		MinimizeBtn.Text = "+"
	else
		MainFrame:TweenSize(UDim2.new(0, 280, 0, 340), "Out", "Quad", 0.3, true)
		ContentFrame.Visible = true
		MinimizeBtn.Text = "—"
	end
	minimized = not minimized
end)

--// CLOSE
CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

--// DRAGGING
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
