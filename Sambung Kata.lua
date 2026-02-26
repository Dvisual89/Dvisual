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
local URL_KAMUS = "https://raw.githubusercontent.com/geovedi/indonesian-wordlist/master/01-kbbi3-2001-sort-alpha.lst"
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
mainFrame.Active = true -- Penting agar input terdeteksi di mobile
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
titleLabel.Text = "   KAMUS UDIN"
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.Parent = titleBar

-- Container Buttons (Close & Minimize)
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
searchInput.PlaceholderText = "Mencari..."
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

-- // TAMBAHKAN FUNGSI INI // --
local function autoTypeWord(kata)
    task.spawn(function()
        -- Ambil teks yang sudah ada di kolom input chat/text box jika mungkin
        -- Namun, karena kita tidak bisa membaca isi chat game secara langsung dengan mudah,
        -- kita gunakan logika: mengetik sisa huruf berdasarkan input di searchInput.
        local currentInput = string.lower(searchInput.Text)
        
        -- Hitung sisa huruf yang harus diketik
        local sisaKata = ""
        if string.sub(kata, 1, #currentInput) == currentInput then
            sisaKata = string.sub(kata, #currentInput + 1)
        else
            sisaKata = kata
        end

        -- Simulasi mengetik HANYA sisa karakter
        for i = 1, #sisaKata do
            local char = sisaKata:sub(i, i):upper()
            local key = Enum.KeyCode[char]
            if key then
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.125) 
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
        
        -- Simulasi tekan ENTER
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
end

-- // LOGIKA PENCARIAN // --
local function cariKata()
    local inputTeks = string.lower(string.match(searchInput.Text, "%a+") or "")
    for _, child in pairs(resultList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    if inputTeks == "" then return end
    
    local hasilDitemukan = {}
    for _, kataDiKamus in ipairs(KamusIndonesia) do
        if string.sub(kataDiKamus, 1, #inputTeks) == inputTeks and not KataTerpakai[kataDiKamus] then
            table.insert(hasilDitemukan, kataDiKamus)
        end
    end
    
    table.sort(hasilDitemukan, function(a, b)
		if sortMode == "UD" then
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
        else -- Mode "LONG"
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

        -- // UBAH BAGIAN INI DI DALAM LOOP // --
        btn.MouseButton1Click:Connect(function()
            autoTypeWord(kata) -- Panggil fungsi autotype
            KataTerpakai[kata] = true
            searchInput.Text = "" 
            cariKata() 
        end)
    end
    resultList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

-- // LOAD DATABASE // --
task.spawn(function()
    local sukses, respons = pcall(function() return game:HttpGet(URL_KAMUS) end)
    if sukses then
        for baris in string.gmatch(respons, "[^\r\n]+") do
            local kata = string.match(baris, "^(%a+)")
            if kata then table.insert(KamusIndonesia, string.lower(kata)) end
        end
        searchInput.PlaceholderText = "Cari awalan..."
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

-- // FILTER & EVENTS // --
filterBtn.MouseButton1Click:Connect(function()
    -- Logika perpindahan mode (Cycle: SHORT -> LONG -> NYA -> IF -> UH -> NG -> SME -> US -> IK -> SHORT)
    if sortMode == "SHORT" then
        sortMode = "LONG"
    elseif sortMode == "LONG" then
        sortMode = "NYA"
    elseif sortMode == "NYA" then
        sortMode = "IF"
    elseif sortMode == "IF" then
        sortMode = "UH"
    elseif sortMode == "UH" then
        sortMode = "NG"
    elseif sortMode == "NG" then
        sortMode = "SME"
    elseif sortMode == "SME" then
        sortMode = "US"
    elseif sortMode == "US" then
        sortMode = "IK"
	elseif sortMode == "IK" then
		sortMode = "UD"
    else 
        sortMode = "SHORT"
    end
    
    -- Update tampilan UI tombol
    filterBtn.Text = sortMode
    if sortMode == "SHORT" then
        filterBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
    elseif sortMode == "LONG" then
        filterBtn.TextColor3 = Color3.fromRGB(255, 100, 255)
    elseif sortMode == "NYA" then
        filterBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
    elseif sortMode == "IF" then
        filterBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
    elseif sortMode == "UH" then
        filterBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif sortMode == "NG" then
        filterBtn.TextColor3 = Color3.fromRGB(150, 255, 100)
    elseif sortMode == "SME" then
        filterBtn.TextColor3 = Color3.fromRGB(255, 255, 100)
    elseif sortMode == "US" then
        filterBtn.TextColor3 = Color3.fromRGB(255, 150, 255)
    elseif sortMode == "IK" then
        filterBtn.TextColor3 = Color3.fromRGB(100, 255, 255)
	elseif sortMode == "UD" then
        filterBtn.TextColor3 = Color3.fromRGB(255, 120, 0) -- Warna Oranye untuk UD
    end
    
    cariKata()
end)

searchInput:GetPropertyChangedSignal("Text"):Connect(cariKata)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- // FIXED DRAGGING LOGIC (HP & PC SUPPORT) // --
local dragging, dragInput, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
