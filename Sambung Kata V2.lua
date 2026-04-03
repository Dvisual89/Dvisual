-- KONFIGURASI NAMA UI
local UI_NAME = "ModernScriptUI_Minimized"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- // DATABASE CONFIG // --
-- Menggunakan database gabungan yang lebih lengkap
local URL_KAMUS = "https://raw.githubusercontent.com/Lionel-Yong/Kamus-Besar-Bahasa-Indonesia/master/kbbi.txt"
local KamusIndonesia = {} 
local KataTerpakai = {}   
local sortMode = "SHORT" 
local isMinimized = false
local originalSize = UDim2.new(0, 185, 0, 250)

-- 1. FUNGSI PENGHANCUR
local existingUI = PlayerGui:FindFirstChild(UI_NAME)
if existingUI then existingUI:Destroy() end

-- 2. BUAT UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = UI_NAME
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = originalSize
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true 
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(50, 50, 50)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "   KAMUS UDIN V2"
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.Parent = titleBar

-- Container Buttons
local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(0, 70, 0, 40)
btnContainer.Position = UDim2.new(1, -75, 0, 0)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "×"
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(0.5, 5, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = btnContainer
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- Minimize Button
local minBtn = Instance.new("TextButton")
minBtn.Text = "−"
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(0, 0, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = btnContainer
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

-- // MAIN CONTENT AREA // --
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -40)
contentFrame.Position = UDim2.new(0, 0, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Search Bar
local searchBarFrame = Instance.new("Frame")
searchBarFrame.Size = UDim2.new(0.55, 0, 0, 35)
searchBarFrame.Position = UDim2.new(0.05, 0, 0, 5)
searchBarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
searchBarFrame.Parent = contentFrame
Instance.new("UICorner", searchBarFrame).CornerRadius = UDim.new(0, 6)

local searchInput = Instance.new("TextBox")
searchInput.Size = UDim2.new(1, -10, 1, 0)
searchInput.Position = UDim2.new(0, 10, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.PlaceholderText = "Memuat data..."
searchInput.Text = ""
searchInput.TextColor3 = Color3.new(1, 1, 1)
searchInput.Font = Enum.Font.Gotham
searchInput.TextSize = 14
searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.Parent = searchBarFrame

-- Refresh Button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 35, 0, 35)
refreshBtn.Position = UDim2.new(0.62, 0, 0, 5)
refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
refreshBtn.Text = "↻"
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 18
refreshBtn.Parent = contentFrame
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)

-- Filter Button
local filterBtn = Instance.new("TextButton")
filterBtn.Size = UDim2.new(0, 60, 0, 35)
filterBtn.Position = UDim2.new(0.75, 0, 0, 5)
filterBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
filterBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
filterBtn.Text = "SHORT"
filterBtn.Font = Enum.Font.GothamBold
filterBtn.TextSize = 10
filterBtn.Parent = contentFrame
Instance.new("UICorner", filterBtn).CornerRadius = UDim.new(0, 6)

local resultList = Instance.new("ScrollingFrame")
resultList.Size = UDim2.new(0.9, 0, 1, -60)
resultList.Position = UDim2.new(0.05, 0, 0, 50)
resultList.BackgroundTransparency = 1
resultList.ScrollBarThickness = 2
resultList.Parent = contentFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = resultList

-- Dropdown Menu Container
local dropdownFrame = Instance.new("ScrollingFrame")
dropdownFrame.Size = UDim2.new(0, 80, 0, 150)
dropdownFrame.Position = UDim2.new(0.75, -20, 0, 45) -- Muncul di bawah tombol filter
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
dropdownFrame.BorderSizePixel = 1
dropdownFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
dropdownFrame.ScrollBarThickness = 3
dropdownFrame.Visible = false
dropdownFrame.ZIndex = 10 -- Agar berada di atas list hasil
dropdownFrame.Parent = contentFrame

local dropdownLayout = Instance.new("UIListLayout", dropdownFrame)
Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)

-- // FUNGSI AUTOTYPE // --
local function autoTypeWord(kata)
    task.spawn(function()
        local currentInput = string.lower(searchInput.Text)
        local sisaKata = ""
        if string.sub(kata, 1, #currentInput) == currentInput then
            sisaKata = string.sub(kata, #currentInput + 1)
        else
            sisaKata = kata
        end

        for i = 1, #sisaKata do
            local char = sisaKata:sub(i, i):upper()
            local key = Enum.KeyCode[char]
            if key then
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.17) 
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
        
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
end

-- // LOGIKA PENCARIAN // --
local function cariKata()
    local inputTeks = string.lower(string.match(searchInput.Text, "%a+") or "")
    
    -- Tutup dropdown otomatis saat mengetik agar tidak menghalangi hasil
    dropdownFrame.Visible = false 

    for _, child in pairs(resultList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    if inputTeks == "" then return end
    
    local hasilDitemukan = {}
    for _, kataDiKamus in ipairs(KamusIndonesia) do
        -- PERUBAHAN: Ditambahkan syarat #kataDiKamus >= 3
        if #kataDiKamus >= 3 and string.sub(kataDiKamus, 1, #inputTeks) == inputTeks and not KataTerpakai[kataDiKamus] then
            table.insert(hasilDitemukan, kataDiKamus)
        end
    end
    
    table.sort(hasilDitemukan, function(a, b)
        if sortMode == "X" then
        local aX = string.sub(a, -1) == "x"
        local bX = string.sub(b, -1) == "x"
        if aX ~= bX then return aX end
        return #a < #b
		elseif sortMode == "UD" then
            local aUd = string.sub(a, -2) == "ud"
            local bUd = string.sub(b, -2) == "ud"
            if aUd ~= bUd then return aUd end
            return #a < #b
        elseif sortMode == "IK" then
            local aIk = string.sub(a, -2) == "ik"
            local bIk = string.sub(b, -2) == "ik"
            if aIk ~= bIk then return aIk end
            return #a < #b
        elseif sortMode == "US" then
            local aUs = string.sub(a, -2) == "us"
            local bUs = string.sub(b, -2) == "us"
            if aUs ~= bUs then return aUs end
            return #a < #b
        elseif sortMode == "SME" then
            local aSme = string.sub(a, -3) == "sme"
            local bSme = string.sub(b, -3) == "sme"
            if aSme ~= bSme then return aSme end
            return #a < #b
        elseif sortMode == "NG" then
            local aNg = string.sub(a, -2) == "ng"
            local bNg = string.sub(b, -2) == "ng"
            if aNg ~= bNg then return aNg end
            return #a < #b
        elseif sortMode == "UH" then
            local aUh = string.sub(a, -2) == "uh"
            local bUh = string.sub(b, -2) == "uh"
            if aUh ~= bUh then return aUh end
            return #a < #b
        elseif sortMode == "IF" then
            local aIf = string.sub(a, -2) == "if"
            local bIf = string.sub(b, -2) == "if"
            if aIf ~= bIf then return aIf end
            return #a < #b
        elseif sortMode == "NYA" then
            local aNya = string.sub(a, -3) == "nya"
            local bNya = string.sub(b, -3) == "nya"
            if aNya ~= bNya then return aNya end
            return #a < #b
        elseif sortMode == "SHORT" then
            return #a < #b
        else 
            return #a > #b
        end
    end)

    for i = 1, math.min(#hasilDitemukan, 30) do
        local kata = hasilDitemukan[i]
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -5, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        btn.Text = "  " .. kata:upper()
        btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = resultList
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            autoTypeWord(kata)
            KataTerpakai[kata] = true
            searchInput.Text = "" 
            cariKata() 
        end)
    end
    resultList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

-- // LOAD DATABASE (SISTEM CADANGAN) // --
task.spawn(function()
    searchInput.PlaceholderText = "Sedang memuat..."
    
    local links = {
        "https://raw.githubusercontent.com/geovedi/indonesian-wordlist/master/01-kbbi3-2001-sort-alpha.lst",
        "https://raw.githubusercontent.com/Lionel-Yong/Kamus-Besar-Bahasa-Indonesia/master/kbbi.txt",
        "https://raw.githubusercontent.com/pujangga123/indonesian-wordlist/master/indonesian-words.txt"
    }

    local sukses = false
    local respons = ""

    for _, url in ipairs(links) do
        if not sukses then
            local s, r = pcall(function() return game:HttpGet(url) end)
            if s and #r > 100 then
                sukses = s
                respons = r
            end
        end
    end

    if sukses then
        local count = 0
        for baris in string.gmatch(respons, "[^\r\n]+") do
            local kata = string.match(baris, "^(%a+)")
            if kata and #kata >= 3 then 
                table.insert(KamusIndonesia, string.lower(kata)) 
                count = count + 1
            end
        end
        searchInput.PlaceholderText = "Siap ("..count.." kata)"
    else
        searchInput.PlaceholderText = "Koneksi Bermasalah!"
    end
end)

-- // MINIMIZE LOGIC // --
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and UDim2.new(0, 185, 0, 40) or originalSize
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    contentFrame.Visible = not isMinimized
    minBtn.Text = isMinimized and "+" or "−"
end)

-- // REFRESH LOGIC // --
refreshBtn.MouseButton1Click:Connect(function()
    KataTerpakai = {}
    searchInput.Text = ""
    cariKata()
    local rot = TweenService:Create(refreshBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = refreshBtn.Rotation + 360})
    local col = TweenService:Create(refreshBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(0, 255, 150)})
    rot:Play()
    col:Play()
    rot.Completed:Connect(function()
        refreshBtn.Rotation = 0
        refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    end)
end)

-- Konfigurasi Filter
local filters = {
    {name = "SHORT", color = Color3.fromRGB(0, 255, 200)},
    {name = "LONG",  color = Color3.fromRGB(255, 100, 255)},
    {name = "NYA",   color = Color3.fromRGB(255, 200, 0)},
    {name = "IF",    color = Color3.fromRGB(100, 200, 255)},
    {name = "UH",    color = Color3.fromRGB(255, 100, 100)},
    {name = "NG",    color = Color3.fromRGB(150, 255, 100)},
    {name = "SME",   color = Color3.fromRGB(255, 255, 100)},
    {name = "US",    color = Color3.fromRGB(255, 150, 255)},
    {name = "IK",    color = Color3.fromRGB(100, 255, 255)},
    {name = "UD",    color = Color3.fromRGB(255, 120, 0)},
    {name = "X",     color = Color3.fromRGB(255, 255, 255)}
}

-- Fungsi untuk membuat tombol di dalam dropdown
for _, info in ipairs(filters) do
    local opt = Instance.new("TextButton")
    opt.Size = UDim2.new(1, 0, 0, 25)
    opt.BackgroundTransparency = 1
    opt.Text = info.name
    opt.TextColor3 = info.color
    opt.Font = Enum.Font.GothamBold
    opt.TextSize = 10
    opt.ZIndex = 11
    opt.Parent = dropdownFrame

    opt.MouseButton1Click:Connect(function()
        sortMode = info.name
        filterBtn.Text = info.name
        filterBtn.TextColor3 = info.color
        dropdownFrame.Visible = false -- Tutup menu setelah pilih
        cariKata()
    end)
end
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, #filters * 25)

-- Logika Buka/Tutup Menu saat tombol filter diklik
filterBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

searchInput:GetPropertyChangedSignal("Text"):Connect(cariKata)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- // DRAGGING LOGIC // --
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
