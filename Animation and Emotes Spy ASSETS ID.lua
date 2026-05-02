-- [[ UDIN SPY MODERN V2 - LUXURY EDITION ]] --
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

if CoreGui:FindFirstChild("UdinSpyModern") then
    CoreGui.UdinSpyModern:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UdinSpyModern"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- FRAME UTAMA
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BackgroundTransparency = 0.15
Frame.Position = UDim2.new(0.05, 0, 0.3, 0)
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.Active = true
Frame.Draggable = true
Frame.ClipsDescendants = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 12)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Thickness = 1.5
FrameStroke.Color = Color3.fromRGB(45, 45, 45)
FrameStroke.Parent = Frame

-- HEADER BAR
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = Frame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 45)

local Title = Instance.new("TextLabel")
Title.Parent = Header
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "UDIN SPY"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- TOMBOL CLOSE
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Header
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Position = UDim2.new(1, -30, 0, 12)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

-- TOMBOL MINIMIZE
local MiniBtn = Instance.new("TextButton")
MiniBtn.Parent = Header
MiniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MiniBtn.Position = UDim2.new(1, -60, 0, 12)
MiniBtn.Size = UDim2.new(0, 20, 0, 20)
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Text = "−"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.TextSize = 18

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0)
MiniCorner.Parent = MiniBtn

-- SEARCH BAR SECTION
local SearchFrame = Instance.new("Frame")
SearchFrame.Parent = Frame
SearchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SearchFrame.Position = UDim2.new(0, 15, 0, 50)
SearchFrame.Size = UDim2.new(1, -30, 0, 38)

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchFrame

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Thickness = 1
SearchStroke.Color = Color3.fromRGB(60, 60, 60)
SearchStroke.Parent = SearchFrame

local SearchBar = Instance.new("TextBox")
SearchBar.Parent = SearchFrame
SearchBar.BackgroundTransparency = 1
SearchBar.Size = UDim2.new(1, -10, 1, 0)
SearchBar.Position = UDim2.new(0, 10, 0, 0)
SearchBar.Font = Enum.Font.Gotham
SearchBar.PlaceholderText = "Search Player Name..."
SearchBar.Text = ""
SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBar.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
SearchBar.TextSize = 13
SearchBar.TextXAlignment = Enum.TextXAlignment.Left

-- CONTROL BUTTONS (ALL & CLEAR)
local Controls = Instance.new("Frame")
Controls.Parent = Frame
Controls.BackgroundTransparency = 1
Controls.Position = UDim2.new(0, 15, 0, 95)
Controls.Size = UDim2.new(1, -30, 0, 25)

local CopyAllBtn = Instance.new("TextButton")
CopyAllBtn.Parent = Controls
CopyAllBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
CopyAllBtn.Size = UDim2.new(0.48, 0, 1, 0)
CopyAllBtn.Font = Enum.Font.GothamBold
CopyAllBtn.Text = "COPY ALL"
CopyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyAllBtn.TextSize = 10

Instance.new("UICorner", CopyAllBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Parent = Controls
ClearBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ClearBtn.Position = UDim2.new(0.52, 0, 0, 0)
ClearBtn.Size = UDim2.new(0.48, 0, 1, 0)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.Text = "CLEAR LOG"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.TextSize = 10

Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

-- LOG LIST SECTION
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Parent = Frame
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.Position = UDim2.new(0, 15, 0, 130)
ScrollingFrame.Size = UDim2.new(1, -30, 1, -145)
ScrollingFrame.ScrollBarThickness = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

-- LOGIC: MINIMIZE
local minimized = false
MiniBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 300, 0, 45) or UDim2.new(0, 300, 0, 400)
    TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = targetSize}):Play()
    MiniBtn.Text = minimized and "+" or "−"
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- LOGIC: LOG ANIMATION
local loggedHistory = {}

local function logAnim(id, name)
    local Allowed = {["walkanim"]=1, ["runanim"]=1, ["animation1"]=1, ["animation2"]=1, ["jumpanim"]=1, ["fallanim"]=1, ["swimidle"]=1, ["swim"]=1, ["climbanim"]=1}
    if not Allowed[name:lower()] or loggedHistory[id] then return end
    loggedHistory[id] = name

    local LogFrame = Instance.new("Frame")
    LogFrame.Parent = ScrollingFrame
    LogFrame.Size = UDim2.new(1, 0, 0, 40)
    LogFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    
    local LogCorner = Instance.new("UICorner", LogFrame)
    LogCorner.CornerRadius = UDim.new(0, 6)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Parent = LogFrame
    NameLabel.BackgroundTransparency = 1
    NameLabel.Position = UDim2.new(0, 10, 0, 0)
    NameLabel.Size = UDim2.new(0.6, -10, 1, 0)
    NameLabel.Font = Enum.Font.GothamMedium
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    NameLabel.TextSize = 12
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Parent = LogFrame
    CopyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    CopyBtn.Position = UDim2.new(0.6, 0, 0.2, 0)
    CopyBtn.Size = UDim2.new(0.35, 0, 0.6, 0)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.Text = id
    CopyBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    CopyBtn.TextSize = 10
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 4)

    CopyBtn.MouseButton1Click:Connect(function()
        setclipboard(id)
        CopyBtn.Text = "COPIED"
        task.wait(0.5)
        CopyBtn.Text = id
    end)

    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

-- BUTTON EVENTS
ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(ScrollingFrame:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    loggedHistory = {}
end)

CopyAllBtn.MouseButton1Click:Connect(function()
    local res = ""
    for id, name in pairs(loggedHistory) do res = res .. name .. ": " .. id .. "\n" end
    if res ~= "" then setclipboard(res) CopyAllBtn.Text = "DONE!" task.wait(1) CopyAllBtn.Text = "COPY ALL" end
end)

local function startSpying(targetName)
    local target = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(targetName:lower()) or p.DisplayName:lower():find(targetName:lower()) then
            target = p break
        end
    end

    if target and target.Character then
        Title.Text = "SPYING: " .. target.DisplayName:upper()
        local animator = target.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
        if animator then
            animator.AnimationPlayed:Connect(function(tr)
                local id = tr.Animation.AnimationId:match("%d+")
                if id then logAnim(id, tr.Name) end
            end)
        end
    end
end

SearchBar.FocusLost:Connect(function(enter) if enter then startSpying(SearchBar.Text) end end)
