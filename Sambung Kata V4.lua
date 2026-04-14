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
	local URL_KAMUS = "https://raw.githubusercontent.com/Lionel-Yong/Kamus-Besar-Bahasa-Indonesia/master/kbbi.txt"
	local KamusIndonesia = {} 
	local KataTerpakai = {}   
	local sortMode = "SHORT" 
	local isMinimized = false
	local originalSize = UDim2.new(0, 185, 0, 280) -- Ukuran ditambah sedikit untuk slider
	local typeDelay = 0.12 -- Default speed
	local antiBotDelay = false -- Mode Jeda Acak
	local antiBotMistyping = false -- Mode Salah Ketik & Koreksi
	local isEnglishMode = false -- Default ke Indonesia
	local KamusInggris = {} 
	local URL_INGGRIS = "https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt"

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

	-- Tombol Toggle Bahasa
	local langBtn = Instance.new("TextButton")
	langBtn.Size = UDim2.new(0, 35, 0, 35)
	langBtn.Position = UDim2.new(0.48, 0, 0, 5) -- Posisi di antara Search dan Refresh
	langBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	langBtn.Text = "ID"
	langBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	langBtn.Font = Enum.Font.GothamBold
	langBtn.TextSize = 14
	langBtn.Parent = contentFrame
	Instance.new("UICorner", langBtn).CornerRadius = UDim.new(0, 6)

	-- Update Tombol Bahasa agar memanggil fungsi di atas
langBtn.MouseButton1Click:Connect(function()
    isEnglishMode = not isEnglishMode
    langBtn.Text = isEnglishMode and "EN" or "ID"
    langBtn.TextColor3 = isEnglishMode and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 255, 255)
    
    -- Paksa jalankan ulang pencarian dengan database baru
    cariKata() 
end)

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

	-- // SPEED SLIDER UI // --
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(0.9, 0, 0, 20)
	sliderFrame.Position = UDim2.new(0.05, 0, 0, 45)
	sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	sliderFrame.Parent = contentFrame
	Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 4)

	local sliderLabel = Instance.new("TextLabel")
	sliderLabel.Size = UDim2.new(1, 0, 1, 0)
	sliderLabel.BackgroundTransparency = 1
	sliderLabel.Text = "SPEED: 0.17s"
	sliderLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	sliderLabel.Font = Enum.Font.GothamBold
	sliderLabel.TextSize = 9
	sliderLabel.ZIndex = 2
	sliderLabel.Parent = sliderFrame

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(0.5, 0, 1, 0) -- Start at middle
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderFrame
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 4)

	-- // UPDATE LOGIKA SLIDER // --
	local function updateSlider(input)
		-- Perbaikan: Menggunakan antiBotDelay (bukan antiBotMode) agar sinkron dengan tombol
		if antiBotDelay then return end 
		
		local pos = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		
		-- MAPPING: 0.30s (Kiri) sampai 0.05s (Kanan)
		typeDelay = 0.30 - (pos * 0.25) 
		sliderLabel.Text = string.format("DELAY: %.2fs", typeDelay)
	end

	local sliding = false
	sliderFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			updateSlider(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)

	local resultList = Instance.new("ScrollingFrame")
	resultList.Size = UDim2.new(0.9, 0, 1, -95) -- Ukuran disesuaikan karena ada slider
	resultList.Position = UDim2.new(0.05, 0, 0, 70) -- Posisi turun sedikit
	resultList.BackgroundTransparency = 1
	resultList.ScrollBarThickness = 2
	resultList.Parent = contentFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = resultList

	-- Dropdown Menu Container
	local dropdownFrame = Instance.new("ScrollingFrame")
	dropdownFrame.Size = UDim2.new(0, 80, 0, 150)
	dropdownFrame.Position = UDim2.new(0.75, -20, 0, 45) 
	dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	dropdownFrame.BorderSizePixel = 1
	dropdownFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
	dropdownFrame.ScrollBarThickness = 3
	dropdownFrame.Visible = false
	dropdownFrame.ZIndex = 10 
	dropdownFrame.Parent = contentFrame

	local dropdownLayout = Instance.new("UIListLayout", dropdownFrame)
	Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)

	-- // FUNGSI AUTOTYPE // --
	local function autoTypeWord(kata)
		task.spawn(function()
			local currentInput = string.lower(searchInput.Text)
			local sisaKata = (string.sub(kata, 1, #currentInput) == currentInput) 
							and string.sub(kata, #currentInput + 1) 
							or kata

			local neighbors = {
				A="S", S="AD", D="SF", F="DG", G="FH", H="GJ", J="HK", K="JL", L="K",
				Q="W", W="QE", E="WR", R="ET", T="RY", Y="TU", U="YI", I="UO", O="IP", P="O",
				Z="X", X="ZC", C="XV", V="CB", B="VN", N="BM", M="N"
			}

			local i = 1
			while i <= #sisaKata do
				local char = sisaKata:sub(i, i):upper()
				local key = Enum.KeyCode[char]
				
				if key then
					-- // LOGIKA MISTYPING DENGAN INERSIA (Sadar setelah beberapa huruf) //
					if antiBotMistyping and math.random(1, 25) == 1 then 
						-- Tentukan berapa banyak huruf "salah" yang diketik sebelum sadar (1-4 huruf)
						local inersia = math.random(1, 4)
						local hurufTerlanjurDiketis = {}

						for j = 1, inersia do
							local targetChar = sisaKata:sub(i + j - 1, i + j - 1)
							if not targetChar or targetChar == "" then break end
							
							-- Huruf pertama adalah typo tetangga, sisanya bisa typo atau huruf lanjutannya
							local typoChar
							if j == 1 then
								local neighborChars = neighbors[targetChar:upper()] or "ASDF"
								typoChar = neighborChars:sub(math.random(1, #neighborChars), math.random(1, #neighborChars))
							else
								-- Simulasi jari terpeleset ke tombol acak atau tetap lanjut mengetik kata asli tapi salah posisi
								typoChar = (math.random(1, 2) == 1) and targetChar or "X" 
							end

							local typoKey = Enum.KeyCode[typoChar:upper()]
							if typoKey then
								VirtualInputManager:SendKeyEvent(true, typoKey, false, game)
								task.wait(math.random(5, 12) / 100)
								VirtualInputManager:SendKeyEvent(false, typoKey, false, game)
								table.insert(hurufTerlanjurDiketis, typoKey)
								task.wait(typeDelay)
							end
						end

						-- Jeda "Reaction Time" (Momen menyadari kesalahan)
						task.wait(math.random(30, 70) / 100) 

						-- Hapus semua huruf yang salah (Backspacing)
						for count = 1, #hurufTerlanjurDiketis do
							VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
							task.wait(math.random(4, 10) / 100) -- Kecepatan hapus bervariasi
							VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
							task.wait(0.05)
						end

						-- Jeda sebelum memperbaiki
						task.wait(math.random(20, 40) / 100)
						
						-- Jangan naikkan index 'i', agar dia mengulang huruf yang sama tadi dengan benar
					else
						-- // PENGETIKAN NORMAL //
						local actualDelay = typeDelay
						if antiBotDelay then
							actualDelay = typeDelay + (math.random(-40, 120) / 1000)
						end

						VirtualInputManager:SendKeyEvent(true, key, false, game)
						task.wait(math.max(0.02, actualDelay))
						VirtualInputManager:SendKeyEvent(false, key, false, game)
						
						task.wait(actualDelay / 2)
						i = i + 1 -- Lanjut ke huruf berikutnya
					end
				else
					i = i + 1
				end
			end
			
			-- Verifikasi Akhir & Enter
			task.wait(0.1) 
			local targetBox = UserInputService:GetFocusedTextBox()
			if targetBox and string.lower(targetBox.Text) ~= string.lower(kata) then
				repeat task.wait(0.05) until string.lower(targetBox.Text) == string.lower(kata)
			end
			
			local enterDelay = antiBotDelay and (0.15 + math.random(10, 30) / 100) or 0.1
			task.wait(enterDelay)
			
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
		end)
	end

	-- // LOGIKA PENCARIAN // --
	local function cariKata()
    local rawText = searchInput.Text or ""
    local inputTeks = string.lower(rawText:gsub("%s+", ""))
    
    dropdownFrame.Visible = false 

    -- Bersihkan list
    for _, child in pairs(resultList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    if inputTeks == "" then return end
    
    -- Pilih database berdasarkan mode
    local databaseAktif = isEnglishMode and KamusInggris or KamusIndonesia
    
    -- Jika database masih kosong (sedang mendownload), beri tahu user
    if #databaseAktif == 0 then
        searchInput.PlaceholderText = "Database belum siap..."
        return 
    end

    local hasilDitemukan = {}
    for _, kataDiKamus in ipairs(databaseAktif) do
        if #kataDiKamus >= 3 and string.sub(kataDiKamus, 1, #inputTeks) == inputTeks and not KataTerpakai[kataDiKamus] then
            table.insert(hasilDitemukan, kataDiKamus)
        end
    end
		
		table.sort(hasilDitemukan, function(a, b)
			if sortMode == "KILLER" then
				local hurufMati = {["x"]=1, ["z"]=2, ["q"]=3, ["v"]=4, ["j"]=5}
				local akhirA = hurufMati[string.sub(a, -1)] or 10
				local akhirB = hurufMati[string.sub(b, -1)] or 10
				
				if akhirA ~= akhirB then
					return akhirA < akhirB -- Prioritaskan X, lalu Z, dst.
				end
				return #a > #b -- Jika sama-sama akhiran sulit, pilih yang paling panjang
			elseif sortMode == "NORMAL" then
				local aNormal = #a >= 5 and #a <= 8
				local bNormal = #b >= 5 and #b <= 8
				if aNormal ~= bNormal then return aNormal end
				return #a < #b -- Jika sama-sama normal, utamakan yang lebih pendek
			elseif sortMode == "KS" then
				local aKs = string.sub(a, -2) == "ks"
				local bKs = string.sub(b, -2) == "ks"
				if aKs ~= bKs then return aKs end
				return #a < #b
			elseif sortMode == "X" then
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

	-- // LOAD DATABASE // --
	task.spawn(function()
		searchInput.PlaceholderText = "Mencari Database..."
		
		-- Menambah lebih banyak sumber repositori kata bahasa Indonesia
		local links = {
			"https://raw.githubusercontent.com/Lionel-Yong/Kamus-Besar-Bahasa-Indonesia/master/kbbi.txt",
			"https://raw.githubusercontent.com/pujangga123/indonesian-wordlist/master/indonesian-words.txt",
			"https://raw.githubusercontent.com/geovedi/indonesian-wordlist/master/01-kbbi3-2001-sort-alpha.lst",
			"https://raw.githubusercontent.com/ajie6fd/Kamus-Bahasa-Indonesia/master/daftar_kata.txt",
			"https://raw.githubusercontent.com/HadiDotSh/Indonesian-Wordlist/master/indonesian-words-list.txt",
			-- Tambahkan ini ke list links Anda
	"https://raw.githubusercontent.com/sastrawi/sastrawi/master/data/kata-dasar.txt", -- Database dasar Sastrawi
	"https://raw.githubusercontent.com/kilat-nusantara/indonesian-word-list/master/indonesian-words.txt", -- List dari Kilat Nusantara (Sangat Luas)
	"https://raw.githubusercontent.com/hermansyah/Kamus-Indonesia-Inggris/master/kamus.txt", -- Kamus gabungan (bisa diekstraksi kata Indo-nya)
	"https://raw.githubusercontent.com/irfani/indonesian-wordlist/master/indonesian-wordlist.txt" -- List tambahan dari irfani
		}

		local kataUnik = {} -- Menggunakan tabel temporary agar tidak ada kata duplikat
		local count = 0

		for _, url in ipairs(links) do
			local s, r = pcall(function() return game:HttpGet(url) end)
			if s and #r > 100 then
				-- Proses ekstraksi kata
				for baris in string.gmatch(r, "[^\r\n]+") do
					-- Membersihkan kata dari spasi, angka, atau simbol
					local kata = string.lower(string.match(baris, "%a+") or "")
					
					-- Filter: Minimal 3 huruf dan belum ada di daftar
					if #kata >= 3 and not kataUnik[kata] then
						kataUnik[kata] = true
						table.insert(KamusIndonesia, kata)
						count = count + 1
					end
				end
			end
			-- Update teks progres setiap kali satu link selesai dimuat
			searchInput.PlaceholderText = "Memuat: " .. count .. " kata..."
		end

		if count > 0 then
			searchInput.PlaceholderText = "Siap (" .. count .. " Kata)"
		else
			searchInput.PlaceholderText = "Koneksi Bermasalah!"
		end
		
		-- Bersihkan tabel temporary untuk menghemat memori
		kataUnik = nil 
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

	-- Filter Buttons Logic
	local filters = {
		{name = "KILLER", color = Color3.fromRGB(255, 0, 0)},
		{name = "NORMAL", color = Color3.fromRGB(0, 255, 100)},
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
		{name = "X",     color = Color3.fromRGB(255, 255, 255)},
		{name = "KS", color = Color3.fromRGB(255, 50, 150)},
	}

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
			dropdownFrame.Visible = false
			cariKata()
		end)
	end
	dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, #filters * 25)

	filterBtn.MouseButton1Click:Connect(function()
		dropdownFrame.Visible = not dropdownFrame.Visible
	end)

	searchInput:GetPropertyChangedSignal("Text"):Connect(cariKata)
	closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

	-- Tombol Anti-Bot: Random Delay
	local delayBtn = Instance.new("TextButton")
	delayBtn.Size = UDim2.new(0.43, 0, 0, 25)
	delayBtn.Position = UDim2.new(0.05, 0, 1, -28)
	delayBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	delayBtn.Text = "RANDOM DELAY"
	delayBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	delayBtn.Font = Enum.Font.GothamBold
	delayBtn.TextSize = 8
	delayBtn.Parent = contentFrame
	Instance.new("UICorner", delayBtn).CornerRadius = UDim.new(0, 6)

	-- Tombol Anti-Bot: Mistyping
	local mistypingBtn = Instance.new("TextButton")
	mistypingBtn.Size = UDim2.new(0.43, 0, 0, 25)
	mistypingBtn.Position = UDim2.new(0.52, 0, 1, -28)
	mistypingBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mistypingBtn.Text = "HUMAN TYPO"
	mistypingBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	mistypingBtn.Font = Enum.Font.GothamBold
	mistypingBtn.TextSize = 8
	mistypingBtn.Parent = contentFrame
	Instance.new("UICorner", mistypingBtn).CornerRadius = UDim.new(0, 6)

	-- Event Listener Delay
	delayBtn.MouseButton1Click:Connect(function()
		antiBotDelay = not antiBotDelay
		delayBtn.TextColor3 = antiBotDelay and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		delayBtn.BackgroundColor3 = antiBotDelay and Color3.fromRGB(30, 50, 30) or Color3.fromRGB(40, 40, 40)
		
		-- Lock slider jika delay otomatis aktif
		sliderFrame.BackgroundTransparency = antiBotDelay and 0.5 or 0
		sliderLabel.Text = antiBotDelay and "AUTO DELAY" or string.format("DELAY: %.2fs", typeDelay)
	end)

	-- Event Listener Mistyping
	mistypingBtn.MouseButton1Click:Connect(function()
		antiBotMistyping = not antiBotMistyping
		mistypingBtn.TextColor3 = antiBotMistyping and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		mistypingBtn.BackgroundColor3 = antiBotMistyping and Color3.fromRGB(30, 50, 30) or Color3.fromRGB(40, 40, 40)
	end)

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

	task.spawn(function()
		-- Load English Database
		local s, r = pcall(function() return game:HttpGet(URL_INGGRIS) end)
		if s then
			for baris in string.gmatch(r, "[^\r\n]+") do
				local kata = string.lower(string.match(baris, "%a+") or "")
				if #kata >= 3 then
					table.insert(KamusInggris, kata)
				end
			end
		end
		-- Database Indonesia (kode kamu yang sudah ada di bawahnya...)
	end)
