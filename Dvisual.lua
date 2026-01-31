local oldGui = game:GetService("CoreGui"):FindFirstChild("DvisualUI_Final")
if oldGui then
    oldGui:Destroy()
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local TargetPlayer = nil
local Spectating = false
local Following = false
local FollowConnection = nil
local Headsitting = false
local HeadsitConnection = nil

local SavedAnimations = {
    ["Idle"] = nil, ["Walk"] = nil, ["Run"] = nil,
    ["Jump"] = nil, ["Fall"] = nil, ["Climb"] = nil, ["Swim"] = nil
}

local AnimationData = {
    ["Idle"] = { ["Elder"] = {"10921101664", "10921102574"}, ["Mage"] = {"707742142", "707855907"} },
    ["Walk"] = { ["Ninja"] = "656121766", ["Zombie"] = "616168032" },
    ["Run"] = { ["OldSchool"] = "10921240218", ["Superhero"] = "10921291831" },
    ["Jump"] = { ["Cartoony"] = "742637942", ["Stylized"] = "4708188025" },
    ["Fall"] = { ["Ghost"] = "616005863", ["Pirate"] = "750780242" },
    ["Climb"] = { ["Astronaut"] = "10921032124", ["Robot"] = "616086039" },
    ["Swim"] = { ["Bubbly"] = "910028158", ["Levitation"] = "10921138209" }
}

local function ApplyDesign(obj, radius, trans)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
    if trans then obj.BackgroundTransparency = trans end
end

--- --- 🔹 FUNGSI APPLY UNIVERSAL (VERSI PERBAIKAN) 🔹 --- ---
local function ApplyInstantAnimation(category, data)
    if not data then return end
    local char = player.Character
    local animate = char and char:FindFirstChild("Animate")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if animate and humanoid then
        -- Simpan pilihan agar tidak hilang saat pindah map
        SavedAnimations[category] = data
        
        -- Sesuaikan nama folder (Idle -> idle, Walk -> walk, dll)
        local folderName = category == "Idle" and "idle" or category:lower()
        local targetFolder = animate:FindFirstChild(folderName)
        
        if targetFolder then
            -- Buat klon dari script Animate untuk me-refresh total sistem animasi
            local animateClone = animate:Clone()
            local cloneFolder = animateClone:FindFirstChild(folderName)
            
            -- Bersihkan isi folder animasi yang lama di dalam klon
            cloneFolder:ClearAllChildren()
            
            -- Tentukan nama objek (Penting: Jump dan Fall punya nama khusus di Roblox)
            local animName = "Animation1"
            if folderName == "jump" then animName = "JumpAnim"
            elseif folderName == "fall" then animName = "FallAnim" end

            -- Fungsi pembantu membuat objek Animation dan StringValue (Wajib ada keduanya)
            local function CreateEntry(id, name, parent)
                local a = Instance.new("Animation")
                a.Name = name; a.AnimationId = "rbxassetid://"..id; a.Parent = parent
                local v = Instance.new("StringValue")
                v.Name = name; v.Parent = parent
            end

            -- Masukkan ID baru ke dalam klon
            if type(data) == "table" then
                for i, id in ipairs(data) do
                    CreateEntry(id, (i == 1 and animName) or ("Animation"..i), cloneFolder)
                end
            else
                CreateEntry(data, animName, cloneFolder)
            end

            -- Hancurkan script lama, hentikan semua animasi yang sedang jalan, dan pasang yang baru
            animate:Destroy()
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop(0) end
            animateClone.Parent = char
            
            -- Paksa refresh fisika karakter agar Walk/Run langsung berubah
            local s = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
            task.wait(0.05)
            humanoid.WalkSpeed = s
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            
            ShowNotification(category .. " Applied!")
        end
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "DvisualUI_Final" -- Nama ini harus sama dengan pengecekan di atas
gui.Parent = game:GetService("CoreGui")
gui.ResetOnSpawn = false

--- --- 🔹 SISTEM NOTIFIKASI 🔹 --- ---
local function ShowNotification(message)
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 200, 0, 40)
    notifFrame.Position = UDim2.new(1, 10, 1, -60)
    notifFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = gui

    local clr = Instance.new("UICorner", notifFrame)
    clr.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", notifFrame)
    stroke.Color = Color3.fromRGB(80, 80, 255)
    stroke.Thickness = 1.5

    local txt = Instance.new("TextLabel", notifFrame)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = "✅ " .. message
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 11

    notifFrame:TweenPosition(UDim2.new(1, -220, 1, -60), "Out", "Back", 0.5, true)
    
    task.delay(2.5, function()
        notifFrame:TweenPosition(UDim2.new(1, 10, 1, -60), "In", "Sine", 0.5, true)
        task.wait(0.5)
        notifFrame:Destroy()
    end)
end

-- Main Frame
local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Parent = gui
main.Size = UDim2.new(0, 600, 0, 400)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BackgroundTransparency = 0.2 
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true 

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = main

-- Title (Rata Kiri)
local title = Instance.new("TextLabel")
title.Parent = main
title.Size = UDim2.new(1, -100, 0, 45)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔥 Dvisual UI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

--- --- 🔹 SISTEM NAVIGASI 🔹 --- ---
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Parent = main
sidebar.Size = UDim2.new(0, 95, 1, -60)
sidebar.Position = UDim2.new(0, 10, 0, 50)
sidebar.BackgroundTransparency = 1 

local sideLayout = Instance.new("UIListLayout")
sideLayout.Parent = sidebar
sideLayout.Padding = UDim.new(0, 8)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

--- --- 🔹 BUBBLE CONTENT 🔹 --- ---
local contentBubble = Instance.new("Frame")
contentBubble.Name = "ContentBubble"
contentBubble.Parent = main
contentBubble.Size = UDim2.new(1, -125, 1, -65)
contentBubble.Position = UDim2.new(0, 115, 0, 50)
contentBubble.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
contentBubble.BackgroundTransparency = 0.5
Instance.new("UICorner", contentBubble).CornerRadius = UDim.new(0, 14)

local function CreateTabFrame(name, isVisible)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Tab"
    frame.Parent = contentBubble
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Visible = isVisible
    local layout = Instance.new("UIListLayout")
    layout.Parent = frame
    layout.Padding = UDim.new(0, 8)
    return frame
end

local infoTabFrame = CreateTabFrame("Info", true)
local homeTabFrame = CreateTabFrame("Home", false)
local avatarTabFrame = CreateTabFrame("Avatar", false)
local animTabFrame = CreateTabFrame("Animation", false) 
local characterTabFrame = CreateTabFrame("Character", false)
local movementTabFrame = CreateTabFrame("Movement", false)-- Tambahkan ini

local function showTab(tabName)
    infoTabFrame.Visible = (tabName == "Info")
    homeTabFrame.Visible = (tabName == "Home")
    avatarTabFrame.Visible = (tabName == "Avatar")
	animTabFrame.Visible = (tabName == "Animation") 
	characterTabFrame.Visible = (tabName == "Character")
	movementTabFrame.Visible = (tabName == "Movement")-- Tambahkan ini
end

local function CreateTabBtn(icon, label, name, hasSeparator)
    local btn = Instance.new("TextButton")
    btn.Parent = sidebar
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.95
    btn.Text = icon .. " " .. label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function() showTab(name) end)
    if hasSeparator then
        local sepContainer = Instance.new("Frame")
        sepContainer.Size = UDim2.new(1, 0, 0, 5)
        sepContainer.BackgroundTransparency = 1
        sepContainer.Parent = sidebar
        local sep = Instance.new("Frame")
        sep.Parent = sepContainer
        sep.Size = UDim2.new(0.8, 0, 0, 1)
        sep.Position = UDim2.new(0.1, 0, 0.5, 0)
        sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sep.BackgroundTransparency = 0.8
        sep.BorderSizePixel = 0
    end
end

CreateTabBtn("👤", "Info", "Info", true) 
CreateTabBtn("🏠", "Main", "Home", true)
CreateTabBtn("👕", "Avatar", "Avatar", false)
CreateTabBtn("🏃", "Animation", "Animation", false) 
CreateTabBtn("", "Character", "Character", false)
CreateTabBtn("⚡", "Move", "Movement", false)-- Tambahkan ini

--- --- 🔹 ISI TAB INFO 🔹 --- ---
local function CreateInfoLabel(text)
    local label = Instance.new("TextLabel")
    label.Parent = infoTabFrame
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = " • " .. text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
end

-- Logika Perhitungan Join Date
local function GetJoinDate()
    local daysOld = player.AccountAge
    -- Menghitung waktu bergabung berdasarkan waktu sekarang dikurangi umur akun (dalam detik)
    local joinTimestamp = os.time() - (daysOld * 86400)
    return os.date("%d %B %Y", joinTimestamp)
end

local gName = MarketService:GetProductInfo(game.PlaceId).Name
CreateInfoLabel("Name: " .. player.Name)
CreateInfoLabel("ID: " .. player.UserId)
CreateInfoLabel("Account Age: " .. player.AccountAge .. " Days")
CreateInfoLabel("Join Date: " .. GetJoinDate()) -- Menampilkan Join Date
CreateInfoLabel("Game: " .. gName)

--- --- 🔹 ISI TAB HOME 🔹 --- ---
local function AddScriptButton(name, callback, parent)
    local btn = Instance.new("TextButton")
    btn.Parent = parent or homeTabFrame
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.92
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

AddScriptButton("Emote", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FayintXhub/Animasi-Emote/refs/heads/main/No-Visual"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    ShowNotification("Animation Executed!")
end)

--- --- 🔹 ISI TAB AVATAR 🔹 --- ---
local avatarTitle = Instance.new("TextLabel")
avatarTitle.Parent = avatarTabFrame
avatarTitle.Size = UDim2.new(1, 0, 0, 25)
avatarTitle.BackgroundTransparency = 1
avatarTitle.Text = "Avatar Copier & Player List"
avatarTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
avatarTitle.Font = Enum.Font.GothamBold
avatarTitle.TextSize = 14

local profileHeader = Instance.new("Frame")
profileHeader.Parent = avatarTabFrame
profileHeader.Size = UDim2.new(1, 0, 0, 60)
profileHeader.BackgroundTransparency = 1

local avatarPreview = Instance.new("ImageLabel") 
avatarPreview.Parent = profileHeader
avatarPreview.Size = UDim2.new(0, 60, 0, 60)
avatarPreview.Position = UDim2.new(0, 0, 0, 0)
avatarPreview.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
avatarPreview.Image = "rbxassetid://0"
Instance.new("UICorner", avatarPreview).CornerRadius = UDim.new(0, 10)

local detailsFrame = Instance.new("Frame")
detailsFrame.Parent = profileHeader
detailsFrame.Size = UDim2.new(1, -70, 1, 0)
detailsFrame.Position = UDim2.new(0, 70, 0, 0) 
detailsFrame.BackgroundTransparency = 1

local detailsLayout = Instance.new("UIListLayout")
detailsLayout.Parent = detailsFrame
detailsLayout.Padding = UDim.new(0, 3)
detailsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function CreateDetailLabel(defaultText)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = detailsFrame
    lbl.Size = UDim2.new(0.6, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = defaultText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local userLabel = CreateDetailLabel("User: -")
local nickLabel = CreateDetailLabel("Nick: -")
local idLabel = CreateDetailLabel("ID: -")

local copyAvaBtn = Instance.new("TextButton")
copyAvaBtn.Parent = profileHeader
copyAvaBtn.Size = UDim2.new(0, 80, 0, 30)
copyAvaBtn.Position = UDim2.new(1, -80, 0.5, -15)
copyAvaBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
copyAvaBtn.Text = "👗 Copy Ava"
copyAvaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyAvaBtn.Font = Enum.Font.GothamBold
copyAvaBtn.TextSize = 10
Instance.new("UICorner", copyAvaBtn).CornerRadius = UDim.new(0, 6)

local currentTargetId = nil

local function updatePreview(name)
    local targetPlayer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if string.sub(string.lower(p.Name), 1, string.len(name)) == string.lower(name) or 
           string.sub(string.lower(p.DisplayName), 1, string.len(name)) == string.lower(name) then
            targetPlayer = p
            break
        end
    end
    if targetPlayer then
        currentTargetId = targetPlayer.UserId
        userLabel.Text = "User: " .. targetPlayer.Name
        nickLabel.Text = "Nick: " .. targetPlayer.DisplayName
        idLabel.Text = "ID: " .. currentTargetId
    end
    if currentTargetId then
        avatarPreview.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. currentTargetId .. "&width=420&height=420&format=png"
    end
end

-- --- 👗 LOGIKA COPY AVA DENGAN NOTIFIKASI 👗 ---
copyAvaBtn.MouseButton1Click:Connect(function()
    if currentTargetId then
        local success, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(currentTargetId)
        end)
        if success and desc then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local applySuccess = pcall(function()
                        if humanoid["ApplyDescriptionClientServer"] then
                            humanoid:ApplyDescriptionClientServer(desc)
                        else
                            humanoid:ApplyDescription(desc)
                        end
                    end)
                    if applySuccess then
                        ShowNotification("Avatar Applied Successfully!")
                    end
                end
            end
        end
    end
end)

--- --- 🔹 SISTEM ANIMASI UNIVERSAL 🔹 --- ---

local function ApplyInstantAnimation(category, data)
    local char = player.Character
    local animScript = char and char:FindFirstChild("Animate")
    if not animScript then return end

    -- Menyamakan nama kategori dengan nama folder di dalam script 'Animate'
    local folderName = category:lower()
    if folderName == "swimidle" then folderName = "swimidle" end
    
    local targetFolder = animScript:FindFirstChild(folderName)
    if targetFolder then
        -- Cek apakah data itu tabel {"123", "456"} atau cuma teks "789"
        if type(data) == "table" then
            if targetFolder:FindFirstChild("Animation1") then
                targetFolder.Animation1.AnimationId = "rbxassetid://" .. data[1]
            end
            if targetFolder:FindFirstChild("Animation2") and data[2] then
                targetFolder.Animation2.AnimationId = "rbxassetid://" .. data[2]
            end
        else
            -- Jika data cuma satu ID (string)
            if targetFolder:FindFirstChild("Animation1") then
                targetFolder.Animation1.AnimationId = "rbxassetid://" .. data
            end
        end

        -- Refresh karakter agar animasi langsung berubah
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do 
                track:Stop(0) 
            end
            animScript.Disabled = true
            task.wait(0.05)
            animScript.Disabled = false
            ShowNotification(category .. " Applied!")
        end
    end
end

--- --- 🔹 ISI TAB ANIMATION (SCROLLING SYSTEM) 🔹 --- ---

-- 1. Container Utama (Ganti Frame lama dengan ScrollingFrame)
local animTabContent = Instance.new("ScrollingFrame")
animTabContent.Size = UDim2.new(1, 0, 1, 0)
animTabContent.BackgroundTransparency = 1
animTabContent.ScrollBarThickness = 2
animTabContent.Parent = animTabFrame

local mainListLayout = Instance.new("UIListLayout")
mainListLayout.Parent = animTabContent
mainListLayout.Padding = UDim.new(0, 10)
mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder

--- --- 🔹 DATA ANIMASI LENGKAP 🔹 --- ---

local AnimationData = {
    ["Idle"] = {
		["AuraAnimationPack"] = {"18747067405", "507766666"},
        ["2016 Animation (mm2)"] = {"387947158", "387947464"},
        ["(UGC) Oh Really?"] = {"98004748982532", "98004748982532"},
        ["Astronaut"] = {"891621366", "891633237"},
        ["Adidas Community"] = {"122257458498464", "102357151005774"},
        ["Bold"] = {"16738333868", "16738334710"},
        ["(UGC) Slasher"] = {"140051337061095", "140051337061095"},
        ["(UGC) Retro"] = {"80479383912838", "80479383912838"},
        ["(UGC) Magician"] = {"139433213852503", "139433213852503"},
        ["(UGC) John Doe"] = {"72526127498800", "72526127498800"},
        ["(UGC) Noli"] = {"139360856809483", "139360856809483"},
        ["(UGC) Coolkid"] = {"95203125292023", "95203125292023"},
        ["(UGC) Survivor Injured"] = {"73905365652295", "73905365652295"},
        ["(UGC) Retro Zombie"] = {"90806086002292", "90806086002292"},
        ["(UGC) 1x1x1x1"] = {"76780522821306", "76780522821306"},
        ["Borock"] = {"3293641938", "3293642554"},
        ["Bubbly"] = {"910004836", "910009958"},
        ["Cartoony"] = {"742637544", "742638445"},
        ["Confident"] = {"1069977950", "1069987858"},
        ["Catwalk Glam"] = {"133806214992291", "94970088341563"},
        ["Cowboy"] = {"1014390418", "1014398616"},
        ["Drooling Zombie"] = {"3489171152", "3489171152"},
        ["Elder"] = {"10921101664", "10921102574"},
        ["Ghost"] = {"616006778", "616008087"},
        ["Knight"] = {"657595757", "657568135"},
        ["Levitation"] = {"616006778", "616008087"},
        ["Mage"] = {"707742142", "707855907"},
        ["MrToilet"] = {"4417977954", "4417978624"},
        ["Ninja"] = {"656117400", "656118341"},
        ["NFL"] = {"92080889861410", "74451233229259"},
        ["OldSchool"] = {"10921230744", "10921232093"},
        ["Patrol"] = {"1149612882", "1150842221"},
        ["Pirate"] = {"750781874", "750782770"},
        ["Default Retarget"] = {"95884606664820", "95884606664820"},
        ["Very Long"] = {"18307781743", "18307781743"},
        ["Sway"] = {"560832030", "560833564"},
        ["Popstar"] = {"1212900985", "1150842221"},
        ["Princess"] = {"941003647", "941013098"},
        ["R6"] = {"12521158637", "12521162526"},
        ["R15 Reanimated"] = {"4211217646", "4211218409"},
        ["Realistic"] = {"17172918855", "17173014241"},
        ["Robot"] = {"616088211", "616089559"},
        ["Sneaky"] = {"1132473842", "1132477671"},
        ["Sports (Adidas)"] = {"18537376492", "18537371272"},
        ["Soldier"] = {"3972151362", "3972151362"},
        ["Stylish"] = {"616136790", "616138447"},
        ["Stylized Female"] = {"4708191566", "4708192150"},
        ["Superhero"] = {"10921288909", "10921290167"},
        ["Toy"] = {"782841498", "782845736"},
        ["Udzal"] = {"3303162274", "3303162549"},
        ["Vampire"] = {"1083445855", "1083450166"},
        ["Werewolf"] = {"1083195517", "1083214717"},
        ["Wicked (Popular)"] = {"118832222982049", "76049494037641"},
        ["No Boundaries (Walmart)"] = {"18747067405", "18747063918"},
        ["Zombie"] = {"616158929", "616160636"},
        ["(UGC) Zombie"] = {"77672872857991", "77672872857991"},
        ["(UGC) TailWag"] = {"129026910898635", "129026910898635"},
        ["[VOTE] warming up"] = {"83573330053643", "83573330053643"},
        ["cesus"] = {"115879733952840", "115879733952840"},
        ["[VOTE] Float"] = {"110375749767299", "110375749767299"},
        ["UGC Oneleft"] = {"121217497452435", "121217497452435"},
        ["AuraFarming"] = {"138665010911335", "138665010911335"},
        ["[VOTE] Mech Float"] = {"74447366032908", "74447366032908"},
        ["Badware"] = {"140131631438778", "140131631438778"},
        ["Wicked \"Dancing Through Life\""] = {"92849173543269", "132238900951109"},
        ["Unboxed By Amazon"] = {"98281136301627", "138183121662404"}
    },
    ["Walk"] = {
        ["AuraAnimationPack"] = "18747074203", ["Geto"] = "85811471336028", ["Patrol"] = "1151231493", ["Drooling Zombie"] = "3489174223", ["Adidas Community"] = "122150855457006", ["Levitation"] = "616013216", ["Catwalk Glam"] = "109168724482748", ["Knight"] = "10921127095", ["Pirate"] = "750785693", ["Bold"] = "16738340646", ["Sports (Adidas)"] = "18537392113", ["Zombie"] = "616168032", ["Astronaut"] = "891667138", ["Cartoony"] = "742640026", ["Ninja"] = "656121766", ["Confident"] = "1070017263", ["Wicked \"Dancing Through Life\""] = "73718308412641", ["Unboxed By Amazon"] = "90478085024465", ["Gojo"] = "95643163365384", ["R15 Reanimated"] = "4211223236", ["Ghost"] = "616013216", ["2016 Animation (mm2)"] = "387947975", ["(UGC) Zombie"] = "113603435314095", ["No Boundaries (Walmart)"] = "18747074203", ["Rthro"] = "10921269718", ["Werewolf"] = "1083178339", ["Wicked (Popular)"] = "92072849924640", ["Vampire"] = "1083473930", ["Popstar"] = "1212980338", ["Mage"] = "707897309", ["(UGC) Smooth"] = "76630051272791", ["R6"] = "12518152696", ["NFL"] = "110358958299415", ["Bubbly"] = "910034870", ["(UGC) Retro"] = "107806791584829", ["(UGC) Retro Zombie"] = "140703855480494", ["OldSchool"] = "10921244891", ["Elder"] = "10921111375", ["Stylish"] = "616146177", ["Stylized Female"] = "4708193840", ["Robot"] = "616095330", ["Sneaky"] = "1132510133", ["Superhero"] = "10921298616", ["Udzal"] = "3303162967", ["Toy"] = "782843345", ["Default Retarget"] = "115825677624788", ["Princess"] = "941028902", ["Cowboy"] = "1014421541"
    },
    ["Run"] = {
        ["AuraAnimationPack"] = "18747070484", ["Robot"] = "10921250460", ["Patrol"] = "1150967949", ["Drooling Zombie"] = "3489173414", ["Adidas Community"] = "82598234841035", ["Heavy Run"] = "3236836670", ["Catwalk Glam"] = "81024476153754", ["Knight"] = "10921121197", ["Pirate"] = "750783738", ["Bold"] = "16738337225", ["Sports (Adidas)"] = "18537384940", ["Zombie"] = "616163682", ["Astronaut"] = "10921039308", ["Cartoony"] = "10921076136", ["Ninja"] = "656118852", ["(UGC) Dog"] = "130072963359721", ["Wicked \"Dancing Through Life\""] = "135515454877967", ["Unboxed By Amazon"] = "134824450619865", ["Sneaky"] = "1132494274", ["Popstar"] = "1212980348", ["Wicked (Popular)"] = "72301599441680", ["R15 Reanimated"] = "4211220381", ["Mage"] = "10921148209", ["Ghost"] = "616013216", ["Confident"] = "1070001516", ["No Boundaries (Walmart)"] = "18747070484", ["Elder"] = "10921104374", ["Werewolf"] = "10921336997", ["Stylish"] = "10921276116", ["MrToilet"] = "4417979645", ["Levitation"] = "616010382", ["OldSchool"] = "10921240218", ["Vampire"] = "10921320299", ["Bubbly"] = "10921057244", ["Superhero"] = "10921291831", ["Toy"] = "10921306285", ["Princess"] = "941015281", ["Cowboy"] = "1014401683"
    },
    ["Jump"] = {
        ["AuraAnimationPack"] = "507765000", ["Robot"] = "616090535", ["Patrol"] = "1148811837", ["Levitation"] = "616008936", ["Knight"] = "910016857", ["Pirate"] = "750782230", ["Bold"] = "16738336650", ["Zombie"] = "616161997", ["Astronaut"] = "891627522", ["Cartoony"] = "742637942", ["Ninja"] = "656117878", ["Confident"] = "1069984524", ["R15 Reanimated"] = "4211219390", ["Werewolf"] = "1083218792", ["Mage"] = "10921149743", ["Sneaky"] = "1132489853", ["Superhero"] = "10921294559", ["Elder"] = "10921107367", ["OldSchool"] = "10921242013", ["Stylish"] = "616139451", ["Vampire"] = "1083455352", ["Toy"] = "10921308158", ["Princess"] = "941008832"
    },
    ["Fall"] = {
        ["Robot"] = "616087089", ["Patrol"] = "1148863382", ["Levitation"] = "616005863", ["Pirate"] = "750780242", ["Zombie"] = "616157476", ["Astronaut"] = "891617961", ["Cartoony"] = "742637151", ["Ninja"] = "656115606", ["Confident"] = "1069973677", ["R15 Reanimated"] = "4211216152", ["Werewolf"] = "1083189019", ["Mage"] = "707829716", ["OldSchool"] = "10921241244", ["Sneaky"] = "1132469004", ["Elder"] = "10921105765", ["Bubbly"] = "910001910", ["Vampire"] = "1083443587", ["Superhero"] = "10921293373", ["Toy"] = "782846423", ["Princess"] = "941000007", ["Cowboy"] = "1014384571"
    },
    ["Swim"] = {
        ["Sneaky"] = "1132500520", ["Patrol"] = "1151204998", ["Levitation"] = "10921138209", ["Knight"] = "10921125160", ["Pirate"] = "750784579", ["Zombie"] = "616165109", ["Mage"] = "707876443", ["Werewolf"] = "10921340419", ["OldSchool"] = "10921243048", ["Elder"] = "10921108971", ["Vampire"] = "10921324408", ["Toy"] = "10921309319", ["SuperHero"] = "10921295495"
    },
    ["Climb"] = {
        ["Robot"] = "616086039", ["Patrol"] = "1148811837", ["Levitation"] = "10921132092", ["Bold"] = "16738332169", ["Zombie"] = "616156119", ["Astronaut"] = "10921032124", ["Cartoony"] = "742636889", ["Ninja"] = "656114359", ["Confident"] = "1069946257", ["Mage"] = "707826056", ["OldSchool"] = "10921229866", ["Sneaky"] = "1132461372", ["Elder"] = "845392038", ["SuperHero"] = "10921286911", ["WereWolf"] = "10921329322", ["Vampire"] = "1083439238", ["Toy"] = "10921300839"
    }
}

--- --- 🔹 FUNGSI APPLY UNIVERSAL (SMART DETECTION) 🔹 --- ---

local function ApplyInstantAnimation(category, data)
    local char = player.Character
    local animate = char and char:FindFirstChild("Animate")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if animate and humanoid then
        SavedAnimations[category] = data
        local folderName = category == "Idle" and "idle" or category:lower()
        
        -- Gunakan Clone untuk memastikan script membaca ulang ID baru
        local animateClone = animate:Clone()
        local targetFolder = animateClone:FindFirstChild(folderName)
        
        if targetFolder then
            targetFolder:ClearAllChildren()
            
            local animName = "Animation1"
            if folderName == "jump" then animName = "JumpAnim"
            elseif folderName == "fall" then animName = "FallAnim" end

            local function CreateEntry(id, name, parent)
                local a = Instance.new("Animation")
                a.Name = name; a.AnimationId = "rbxassetid://"..id; a.Parent = parent
                local v = Instance.new("StringValue")
                v.Name = name; v.Parent = parent
            end

            if type(data) == "table" then
                for i, id in ipairs(data) do
                    CreateEntry(id, (i == 1 and animName) or ("Animation"..i), targetFolder)
                end
            else
                CreateEntry(data, animName, targetFolder)
            end

            -- Hancurkan yang lama dan pasang yang baru (Nuclear Refresh)
            animate:Destroy()
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop(0) end
            animateClone.Parent = char
            
            -- Trigger fisik
            humanoid:ChangeState(Enum.HumanoidStateType.Landing)
            local s = humanoid.WalkSpeed; humanoid.WalkSpeed = 0; task.wait(0.05); humanoid.WalkSpeed = s
        end
    end
end

local function ResetToDefaultAnimations()
    local char = player.Character
    local animate = char and char:FindFirstChild("Animate")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if animate and humanoid then
        -- 1. Kosongkan memori SavedAnimations agar tidak otomatis terpasang lagi
        for k, v in pairs(SavedAnimations) do SavedAnimations[k] = nil end

        -- 2. Buat klon bersih
        local animateClone = animate:Clone()
        local folders = {"idle", "walk", "run", "jump", "fall", "climb", "swim"}
        
        for _, name in pairs(folders) do
            local f = animateClone:FindFirstChild(name)
            if f then f:ClearAllChildren() end
        end

        -- 3. Ganti script Animate ke kondisi Default
        animate:Destroy()
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop(0) end
        task.wait(0.1)
        animateClone.Parent = char
        
        -- 4. Paksa update state
        humanoid:ChangeState(Enum.HumanoidStateType.Jump)
        task.wait(0.1)
        humanoid:ChangeState(Enum.HumanoidStateType.Landing)

        ShowNotification("Animations Reset to Default!")
    end
end

-- Urutan Tampilan
local CategoryOrder = {"Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim"}

-- 3. Fungsi Pembuat Baris Kategori
local function CreateAnimCategory(categoryName, data, order)
    local rowFrame = Instance.new("Frame")
    rowFrame.Name = categoryName .. "Row"
    rowFrame.Size = UDim2.new(1, 0, 0, 30)
    rowFrame.BackgroundTransparency = 1
    rowFrame.LayoutOrder = order
    rowFrame.Parent = animTabContent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.3, 0, 0, 30)
    label.Text = categoryName:upper()
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = rowFrame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.65, 0, 0, 24)
    toggle.Position = UDim2.new(0.35, 0, 0, 3)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggle.Text = "Select " .. categoryName .. " ▼"
    toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggle.Font = Enum.Font.GothamSemibold
    toggle.TextSize = 9
    toggle.Parent = rowFrame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 5)

    local search = Instance.new("TextBox")
    search.Size = UDim2.new(0.65, 0, 0, 22)
    search.Position = UDim2.new(0.35, 0, 0, 32)
    search.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    search.PlaceholderText = "🔍 Search..."
    search.Text = ""
    search.TextColor3 = Color3.fromRGB(255, 255, 255)
    search.Font = Enum.Font.Gotham
    search.TextSize = 9
    search.Visible = false
    search.Parent = rowFrame
    Instance.new("UICorner", search).CornerRadius = UDim.new(0, 5)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(0.65, 0, 0, 0)
    scroll.Position = UDim2.new(0.35, 0, 0, 56)
    scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.Visible = false
    scroll.Parent = rowFrame
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 5)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scroll
    listLayout.Padding = UDim.new(0, 2)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    toggle.MouseButton1Click:Connect(function()
        if scroll.Visible then
            search.Visible = false
            TweenService:Create(scroll, TweenInfo.new(0.2), {Size = UDim2.new(0.65, 0, 0, 0)}):Play()
            TweenService:Create(rowFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 30)}):Play()
            task.wait(0.2)
            scroll.Visible = false
        else
            scroll.Visible = true
            search.Visible = true
            TweenService:Create(rowFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 140)}):Play()
            TweenService:Create(scroll, TweenInfo.new(0.3), {Size = UDim2.new(0.65, 0, 0, 80)}):Play()
        end
    end)

    for name, ids in pairs(data) do
        local btn = Instance.new("TextButton")
        btn.Name = name:lower()
        btn.Size = UDim2.new(0.92, 0, 0, 20)
        btn.BackgroundTransparency = 0.95
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = "  " .. name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 9
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            toggle.Text = name .. " ▼"
            scroll.Visible = false
            search.Visible = false
            TweenService:Create(rowFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 30)}):Play()
            ApplyInstantAnimation(categoryName, ids)
        end)
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = search.Text:lower()
        for _, c in pairs(scroll:GetChildren()) do
            if c:IsA("TextButton") then
                c.Visible = string.find(c.Name, txt) and true or false
            end
        end
    end)

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
end

-- Eksekusi pembuatan kategori sesuai urutan
for i, catName in ipairs(CategoryOrder) do
    CreateAnimCategory(catName, AnimationData[catName] or {}, i)
end

-- Tombol Reset diletakkan setelah semua kategori (Idle sampai Swim) selesai dibuat
local resetBtnFrame = Instance.new("Frame")
resetBtnFrame.Name = "ResetAnimRow"
resetBtnFrame.Size = UDim2.new(1, 0, 0, 50) -- Memberi ruang lebih besar agar di tengah
resetBtnFrame.BackgroundTransparency = 1
resetBtnFrame.LayoutOrder = #CategoryOrder + 1
resetBtnFrame.Parent = animTabContent

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.8, 0, 0, 35)
resetBtn.Position = UDim2.new(0.1, 0, 0, 10) -- Membuatnya berada di tengah secara horizontal
resetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Warna merah agar mencolok
resetBtn.Text = "🔄 RESET ALL ANIMATIONS"
resetBtn.TextColor3 = Color3.new(1, 1, 1)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 12
resetBtn.Parent = resetBtnFrame
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

resetBtn.MouseButton1Click:Connect(function()
    ResetToDefaultAnimations()
end)

mainListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    animTabContent.CanvasSize = UDim2.new(0, 0, 0, mainListLayout.AbsoluteContentSize.Y + 20)
end)

-----------------------------------------------------------

local avatarInput = Instance.new("TextBox")
avatarInput.Parent = avatarTabFrame
avatarInput.Size = UDim2.new(1, 0, 0, 30)
avatarInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
avatarInput.PlaceholderText = "Type Name (Auto Search)..."
avatarInput.Text = ""
avatarInput.TextColor3 = Color3.fromRGB(255, 255, 255)
avatarInput.Font = Enum.Font.Gotham
avatarInput.TextSize = 12
Instance.new("UICorner", avatarInput).CornerRadius = UDim.new(0, 8)

avatarInput:GetPropertyChangedSignal("Text"):Connect(function()
    if avatarInput.Text ~= "" then updatePreview(avatarInput.Text) end
end)

local listControlContainer = Instance.new("Frame")
listControlContainer.Parent = avatarTabFrame
listControlContainer.Size = UDim2.new(1, 0, 0, 30)
listControlContainer.BackgroundTransparency = 1
local listControlLayout = Instance.new("UIListLayout")
listControlLayout.Parent = listControlContainer
listControlLayout.FillDirection = Enum.FillDirection.Horizontal
listControlLayout.Padding = UDim.new(0, 5)

local toggleListBtn = Instance.new("TextButton")
toggleListBtn.Parent = listControlContainer
toggleListBtn.Size = UDim2.new(0.7, -5, 1, 0)
toggleListBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleListBtn.Text = "▼ Show Player List"
toggleListBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
toggleListBtn.Font = Enum.Font.GothamSemibold
toggleListBtn.TextSize = 10
Instance.new("UICorner", toggleListBtn).CornerRadius = UDim.new(0, 8)

local refreshBtn = Instance.new("TextButton")
refreshBtn.Parent = listControlContainer
refreshBtn.Size = UDim2.new(0.3, 0, 1, 0)
refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
refreshBtn.Text = "🔄 Refresh"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 10
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)

local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Parent = avatarTabFrame
playerListScroll.Size = UDim2.new(1, 0, 0, 80)
playerListScroll.BackgroundTransparency = 0.8
playerListScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
playerListScroll.Visible = false 
playerListScroll.ScrollBarThickness = 2
Instance.new("UICorner", playerListScroll).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = playerListScroll
listLayout.Padding = UDim.new(0, 5)

local function refreshPlayerList()
    for _, v in pairs(playerListScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        local pBtn = Instance.new("TextButton")
        pBtn.Size = UDim2.new(1, -10, 0, 25); pBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        pBtn.Text = p.Name; pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        pBtn.Font = Enum.Font.Gotham; pBtn.TextSize = 11; pBtn.Parent = playerListScroll
        Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
        pBtn.MouseButton1Click:Connect(function()
            avatarInput.Text = p.Name; updatePreview(p.Name)
            playerListScroll.Visible = false; toggleListBtn.Text = "▼ Show Player List"
        end)
    end
end

local btnContainer = Instance.new("Frame")
btnContainer.Parent = avatarTabFrame
btnContainer.Size = UDim2.new(1, 0, 0, 30)
btnContainer.BackgroundTransparency = 1
local actBtnLayout = Instance.new("UIListLayout")
actBtnLayout.Parent = btnContainer
actBtnLayout.FillDirection = Enum.FillDirection.Horizontal
actBtnLayout.Padding = UDim.new(0, 5)

AddScriptButton("Copy ID", function()
    local cleanId = string.gsub(idLabel.Text, "ID: ", "")
    if cleanId ~= "-" and setclipboard then 
        setclipboard(cleanId) 
        ShowNotification("ID Copied: " .. cleanId)
    end
end, btnContainer)

AddScriptButton("Profile", function()
    local cleanId = string.gsub(idLabel.Text, "ID: ", "")
    if cleanId ~= "-" and setclipboard then 
        setclipboard("https://www.roblox.com/users/" .. cleanId .. "/profile") 
        ShowNotification("Profile Link Copied!")
    end
end, btnContainer)

AddScriptButton("Reset Ava", function()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local success, originalDesc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(player.UserId)
            end)
            if success and originalDesc then
                pcall(function()
                    if humanoid["ApplyDescriptionClientServer"] then
                        humanoid:ApplyDescriptionClientServer(originalDesc)
                    else
                        humanoid:ApplyDescription(originalDesc)
                    end
                end)
                ShowNotification("Avatar Reset!")
            end
        end
    end
end, btnContainer)

toggleListBtn.MouseButton1Click:Connect(function()
    playerListScroll.Visible = not playerListScroll.Visible
    toggleListBtn.Text = playerListScroll.Visible and "▲ Hide Player List" or "▼ Show Player List"
end)

refreshBtn.MouseButton1Click:Connect(function() 
    refreshPlayerList() 
    ShowNotification("Player List Refreshed!")
end)

refreshPlayerList()

-- --- 🔹 PAKSA URUTAN TAB CHARACTER 🔹 --- --

-- 0. Setup Layout (PENTING)
local layout = characterTabFrame:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", characterTabFrame)
layout.SortOrder = Enum.SortOrder.LayoutOrder -- Mengaktifkan sistem ranking angka
layout.Padding = UDim.new(0, 10)

-- 1. SEARCH BOX (LayoutOrder = 1) -> PASTI DI ATAS
local searchBox = Instance.new("TextBox")
searchBox.Parent = characterTabFrame
searchBox.LayoutOrder = 1 -- Angka terkecil = posisi teratas
searchBox.Size = UDim2.new(1, -10, 0, 35)
searchBox.PlaceholderText = "Ketik nama player..."
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
Instance.new("UICorner", searchBox)

-- 2. PROFILE FRAME (LayoutOrder = 2) -> DI BAWAH SEARCH
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Parent = characterTabFrame
ProfileFrame.LayoutOrder = 2
ProfileFrame.Size = UDim2.new(1, -10, 0, 100)
ProfileFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", ProfileFrame)

-- (Isi ProfileFrame tidak butuh LayoutOrder karena mereka bukan anak langsung dari characterTabFrame)
local AvatarPreview = Instance.new("ImageLabel")
AvatarPreview.Parent = ProfileFrame
AvatarPreview.Size = UDim2.new(0, 70, 0, 70)
AvatarPreview.Position = UDim2.new(0, 10, 0.5, -35)
AvatarPreview.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", AvatarPreview).CornerRadius = UDim.new(1, 0)

local DataLabel = Instance.new("TextLabel")
DataLabel.Parent = ProfileFrame
DataLabel.Size = UDim2.new(1, -100, 1, 0)
DataLabel.Position = UDim2.new(0, 90, 0, 0)
DataLabel.BackgroundTransparency = 1
DataLabel.Text = "Status: Menunggu Input..."
DataLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DataLabel.Font = Enum.Font.Gotham
DataLabel.TextSize = 11
DataLabel.TextXAlignment = "Left"
DataLabel.RichText = true

-- --- 🔹 FUNGSI TOMBOL 🔹 ---
local function CreateActionBtn(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 1, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn)
    return btn
end

-- 3. BARIS TOMBOL 1 (LayoutOrder = 3)
local Row1 = Instance.new("Frame")
Row1.Parent = characterTabFrame
Row1.LayoutOrder = 3
Row1.Size = UDim2.new(1, -10, 0, 32)
Row1.BackgroundTransparency = 1

local TPBtn = CreateActionBtn("Teleport", Color3.fromRGB(60, 120, 255))
TPBtn.Parent = Row1
TPBtn.Position = UDim2.new(0, 0, 0, 0)

local HeadsitBtn = CreateActionBtn("Headsit: OFF", Color3.fromRGB(255, 100, 150))
HeadsitBtn.Parent = Row1
HeadsitBtn.Position = UDim2.new(0.52, 0, 0, 0)

-- 4. BARIS TOMBOL 2 (LayoutOrder = 4)
local Row2 = Instance.new("Frame")
Row2.Parent = characterTabFrame
Row2.LayoutOrder = 4
Row2.Size = UDim2.new(1, -10, 0, 32)
Row2.BackgroundTransparency = 1

local ViewBtn = CreateActionBtn("Spectate: OFF", Color3.fromRGB(150, 60, 255))
ViewBtn.Parent = Row2
ViewBtn.Position = UDim2.new(0, 0, 0, 0)

local BpBtn = CreateActionBtn("Backpack: OFF", Color3.fromRGB(255, 140, 0))
BpBtn.Parent = Row2
BpBtn.Position = UDim2.new(0.52, 0, 0, 0)

-- 5. BARIS TOMBOL 3 (LayoutOrder = 5) -> TEPAT DI BAWAH SPECTATE
local Row3 = Instance.new("Frame")
Row3.Parent = characterTabFrame
Row3.LayoutOrder = 5 -- Urutan ke-5 setelah Row2
Row3.Size = UDim2.new(1, -10, 0, 32)
Row3.BackgroundTransparency = 1

local followBtn = CreateActionBtn("Follow Player: OFF", Color3.fromRGB(0, 180, 100))
followBtn.Parent = Row3
followBtn.Position = UDim2.new(0, 0, 0, 0)
followBtn.Size = UDim2.new(1, 0, 1, 0) -- Ukuran penuh satu baris agar terlihat rapi

-- --- 🔹 LOGIKA PENCARIAN PLAYER (SISTEM LOCK DIPERBAIKI) 🔹 --- --

local TempTarget = nil -- Variabel bantu agar TargetPlayer asli tidak langsung berubah

local function UpdateSearch()
    local text = searchBox.Text:lower()
    if text ~= "" then
        for _, v in pairs(game.Players:GetPlayers()) do
            -- Mencari secara agresif untuk PREVIEW saja
            if v.Name:lower():match(text) or v.DisplayName:lower():match(text) then
                TempTarget = v -- Simpan ke Target Sementara
                
                -- Ambil Foto Thumbnail
                local content, isReady = game.Players:GetUserThumbnailAsync(
                    v.UserId, 
                    Enum.ThumbnailType.HeadShot, 
                    Enum.ThumbnailSize.Size150x150
                )
                
                -- Hitung Age dan Join Date
                local daysOld = v.AccountAge
                local joinDate = os.date("%d %B %Y", os.time() - (daysOld * 86400))
                
                -- Update Tampilan Preview (Tapi TargetPlayer asli masih yang lama)
                AvatarPreview.Image = content
                DataLabel.Text = string.format(
                    "<b>Target:</b> %s\n" ..
                    "<b>ID:</b> %d\n" ..
                    "<b>Account Age:</b> <font color='#FFD700'>%d Days</font>\n" ..
                    "<b>Join Date:</b> <font color='#00FF7F'>%s</font>\n" ..
                    "<b>Status:</b> <font color='#FFA500'>Press ENTER to Lock</font>",
                    v.DisplayName, v.UserId, daysOld, joinDate
                )
                return 
            end
        end
    end
    
    -- Jika kolom kosong, kita tidak hapus TargetPlayer, hanya reset preview jika belum lock
    TempTarget = nil
    if not TargetPlayer then
        AvatarPreview.Image = ""
        DataLabel.Text = "Status: Mencari player..."
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSearch)

searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        if TempTarget then
            -- Di sinilah TargetPlayer asli baru kita ganti
            TargetPlayer = TempTarget 
            
            -- Mengubah status menjadi LOCKED dengan warna biru
            local currentText = DataLabel.Text
            DataLabel.Text = currentText:gsub("Press ENTER to Lock", "<font color='#6078FF'>LOCKED</font>")
            
            ShowNotification("Target Locked: " .. TargetPlayer.DisplayName)
        elseif searchBox.Text == "" then
             
            ShowNotification("Search kosong.")
        else
            ShowNotification("Player tidak ditemukan!")
        end
    end
end)

-- --- 🔹 LOGIKA TOMBOL CHARACTER (Sesuai PREVIEW CHARACTER.lua) 🔹 --- --
-- 1. Fungsi Teleport (Pas di Posisi)
TPBtn.MouseButton1Click:Connect(function()
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = TargetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0.5, 0)
        ShowNotification("Teleported to: " .. TargetPlayer.DisplayName)
    else
        ShowNotification("Lock player dulu di Search!")
    end
end)

-- 2. Fungsi Spectate
ViewBtn.MouseButton1Click:Connect(function()
    if TargetPlayer and TargetPlayer.Character then
        Spectating = not Spectating
        ViewBtn.Text = Spectating and "Spectate: ON" or "Spectate: OFF"
        ViewBtn.BackgroundColor3 = Spectating and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(150, 60, 255)
        workspace.CurrentCamera.CameraSubject = Spectating and TargetPlayer.Character.Humanoid or player.Character.Humanoid
    end
end)

-- 3. Fungsi Headsit (Posisi Duduk & Kunci Total)
HeadsitBtn.MouseButton1Click:Connect(function()
    if not TargetPlayer then 
        ShowNotification("Cari player dan tekan ENTER untuk Lock!")
        return 
    end
    
    Headsitting = not Headsitting
    HeadsitBtn.Text = Headsitting and "Headsit: ON" or "Headsit: OFF"
    HeadsitBtn.BackgroundColor3 = Headsitting and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(255, 100, 150)

    if Headsitting then
        HeadsitConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local targetChar = TargetPlayer.Character
            
            if Headsitting and targetChar and targetChar:FindFirstChild("Head") and char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if hum and hrp then
                    -- --- 🔹 KUNCI MATI (ANTI-LOMPAT & ANTI-GERAK) 🔹 --- --
                    hum.Sit = true             -- Paksa pose duduk
                    hum.JumpPower = 0         -- Mematikan kemampuan lompat
                    hum.WalkSpeed = 0         -- Mematikan kemampuan jalan
                    hrp.Velocity = Vector3.new(0, 0, 0) -- Menghapus sisa gaya dorong
                    
                    -- Tempel tepat di kepala target
                    hrp.CFrame = targetChar.Head.CFrame * CFrame.new(0, 1.7, 0)
                end
            end
        end)
        ShowNotification("Headsit Locked: Tidak bisa gerak/lompat")
    else
        -- --- 🔹 RESET (KEMBALI NORMAL) 🔹 --- --
        if HeadsitConnection then HeadsitConnection:Disconnect() end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Sit = false
            hum.JumpPower = 50 -- Standar Roblox
            hum.WalkSpeed = 16  -- Standar Roblox
        end
    end
end)

-- 4. Fungsi Backpack (Posisi Duduk & Kunci Total di Punggung)
BpBtn.MouseButton1Click:Connect(function()
    if not TargetPlayer then ShowNotification("Lock player dulu!") return end
    Backpacking = not Backpacking
    
    -- Matikan Headsit jika menyalakan Backpack
    if Backpacking and Headsitting then 
        Headsitting = false 
        HeadsitBtn.Text = "Headsit: OFF"
        if HeadsitConnection then HeadsitConnection:Disconnect() end
    end

    BpBtn.Text = Backpacking and "Backpack: ON" or "Backpack: OFF"
    BpBtn.BackgroundColor3 = Backpacking and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(255, 140, 0)

    if Backpacking then
        BpConnection = RunService.Heartbeat:Connect(function()
            local myChar = player.Character
            local targetChar = TargetPlayer.Character
            if Backpacking and targetChar and targetChar:FindFirstChild("HumanoidRootPart") and myChar then
                local myHum = myChar:FindFirstChildOfClass("Humanoid")
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")

                if myHum and myHRP then
                    -- KUNCI MATI: Duduk, Power Lompat 0, Kecepatan 0
                    myHum.Sit = true
                    myHum.JumpPower = 0
                    myHum.WalkSpeed = 0
                    myHRP.Velocity = Vector3.new(0, 0, 0)
                    
                    -- Tempel di belakang punggung (Offset 1.2)
                    myHRP.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1.2)
                end
            end
        end)
    else
        if BpConnection then BpConnection:Disconnect() end
        -- Kembalikan kontrol saat OFF
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character.Humanoid.Sit = false
            player.Character.Humanoid.JumpPower = 50
            player.Character.Humanoid.WalkSpeed = 16
        end
    end
end)

followBtn.MouseButton1Click:Connect(function()
    -- Pastikan sudah lock player di search box
    if not TargetPlayer then 
        ShowNotification("Cari nama & tekan ENTER dulu!") 
        return 
    end
    
    Following = not Following -- Ganti status True/False
    
    if Following then
        -- SAAT ON
        followBtn.Text = "Follow Player: ON"
        followBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Warna Merah saat aktif
        ShowNotification("Follow Aktif: Mengikuti " .. TargetPlayer.DisplayName)
        
        -- Memulai loop pergerakan
        FollowConnection = RunService.Heartbeat:Connect(function()
            if Following and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myHum = player.Character:FindFirstChildOfClass("Humanoid")
                local targetPos = TargetPlayer.Character.HumanoidRootPart.Position
                
                if myHum then
                    -- Jarak berhenti sedikit (2 unit) supaya tidak menabrak target
                    myHum:MoveTo(targetPos) 
                end
            else
                -- Jika target hilang/keluar game, otomatis matikan
                Following = false
                if FollowConnection then FollowConnection:Disconnect() end
                followBtn.Text = "Follow Player: OFF"
                followBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            end
        end)
    else
        -- SAAT OFF (Berhenti Mengikuti)
        if FollowConnection then 
            FollowConnection:Disconnect() 
            FollowConnection = nil
        end
        
        local myHum = player.Character:FindFirstChildOfClass("Humanoid")
        if myHum then
            -- Perintah berhenti di tempat saat ini
            myHum:MoveTo(player.Character.HumanoidRootPart.Position) 
        end
        
        followBtn.Text = "Follow Player: OFF"
        followBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100) -- Kembali Hijau
        ShowNotification("Follow Berhenti")
    end
end)

--- --- 🔹 ISI TAB MOVEMENT 🔹 --- ---
local function CreateMovementSetting(name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Parent = movementTabFrame
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = container
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = name .. " [" .. default .. "]"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    local input = Instance.new("TextBox")
    input.Parent = container
    input.Size = UDim2.new(1, 0, 0, 25)
    input.Position = UDim2.new(0, 0, 0, 20)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    input.Text = tostring(default)
    input.TextColor3 = Color3.fromRGB(0, 255, 0)
    input.Font = Enum.Font.GothamBold
    input.PlaceholderText = "Enter value..."
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    input.FocusLost:Connect(function(enter)
        local val = tonumber(input.Text)
        if val then
            label.Text = name .. " [" .. val .. "]"
            callback(val)
        else
            input.Text = tostring(default)
        end
    end)
end

-- Walk Speed
CreateMovementSetting("Walk Speed", 0, 500, 16, function(v)
    player.Character.Humanoid.WalkSpeed = v
end)

-- Jump Power
CreateMovementSetting("Jump Power", 0, 500, 50, function(v)
    player.Character.Humanoid.UseJumpPower = true
    player.Character.Humanoid.JumpPower = v
end)

-- Fly Speed (Mengatur variabel lokal untuk Fly jika kamu punya script fly)
local flySpeedValue = 50
CreateMovementSetting("Fly Speed", 0, 1000, 50, function(v)
    flySpeedValue = v
    ShowNotification("Fly Speed set to: " .. v)
end)

--- --- 🔹 CONTROL & MINIMIZE LOGIC 🔹 --- ---
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = main; closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -40, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); closeBtn.Text = "×"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local minBtn = Instance.new("TextButton")
minBtn.Parent = main; minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -75, 0, 8)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); minBtn.BackgroundTransparency = 0.9; minBtn.Text = "—"; minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local isMinimized = false
local originalSize = UDim2.new(0, 600, 0, 400)

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        sidebar.Visible = false; contentBubble.Visible = false; title.Visible = false; closeBtn.Visible = false
        TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, 35, 0, 35), Position = UDim2.new(0.025, 0, 0.5, 0)}):Play()
        minBtn.Text = "🚀"; minBtn.Size = UDim2.new(1, 0, 1, 0); minBtn.Position = UDim2.new(0, 0, 0, 0); minBtn.BackgroundTransparency = 1
    else
        minBtn.Text = "—"; minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -75, 0, 8); minBtn.BackgroundTransparency = 0.9
        TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = originalSize, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        task.delay(0.3, function() 
            title.Visible = true; sidebar.Visible = true; contentBubble.Visible = true; closeBtn.Visible = true
        end)
    end
end

-- --- 🔹 LOGIKA FITUR (BACKPACK & SPECTATE) 🔹 --- --
local Backpacking = false
local BpConnection = nil

-- Fungsi Backpack
BpBtn.MouseButton1Click:Connect(function()
    if not TargetPlayer then return end
    Backpacking = not Backpacking
    BpBtn.Text = Backpacking and "Backpack: ON" or "Backpack: OFF"
    if Backpacking then
        BpConnection = RunService.Heartbeat:Connect(function()
            if Backpacking and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = TargetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1.2)
            end
        end)
    else
        if BpConnection then BpConnection:Disconnect() end
    end
end)

-- --- 🔹 NOTIFIKASI PEMAIN TARGET LEAVE 🔹 --- --
Players.PlayerRemoving:Connect(function(leftPlayer)
    -- Cek apakah pemain yang keluar adalah pemain yang sedang kita targetkan
    if TargetPlayer and leftPlayer == TargetPlayer then
        ShowNotification("Target: " .. leftPlayer.DisplayName .. " has left the game!")
        
        -- Reset status spectate jika sedang melihat pemain tersebut
        if Spectating then
            Spectating = false
            workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
            ViewBtn.Text = "Spectate: OFF"
            ViewBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 255)
        end
        
        -- Kosongkan target
        TargetPlayer = nil
        userLabel.Text = "User: -"
        nickLabel.Text = "Nick: -"
        idLabel.Text = "ID: -"
        avatarPreview.Image = "rbxassetid://0"
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.B then
        toggleMinimize()
    end
end)

minBtn.MouseButton1Click:Connect(toggleMinimize)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Handler ini memastikan saat karakter spawn ulang, variabel di script tetap akurat
player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5) -- Beri waktu sistem memuat komponen
    local humanoid = newChar:WaitForChild("Humanoid")
    print("Karakter diperbarui untuk eksekusi saat ini.")
end)

-- 🔹 INTEGRASI LOGIKA FLY SYSTEM BROKEN 🔹
local Flying = false
local FlySpeed = 50
local BodyGyro, BodyVelocity
local FlyConnection

local function StartFlying()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    Flying = true
    
    -- Menggunakan BodyGyro & BodyVelocity sesuai logika SystemBroken
    BodyGyro = Instance.new("BodyGyro", root)
    BodyGyro.P = 9e4
    BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.CFrame = root.CFrame

    BodyVelocity = Instance.new("BodyVelocity", root)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    -- Loop pergerakan halus (RunService) dari SystemBroken
    FlyConnection = RunService.RenderStepped:Connect(function()
        if Flying and root and hum.Parent then
            local camera = workspace.CurrentCamera
            local moveDir = Vector3.new(0, 0, 0)
            
            -- Kontrol Keyboard
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
            
            BodyVelocity.Velocity = moveDir * FlySpeed
            BodyGyro.CFrame = camera.CFrame
            hum.PlatformStand = true -- Mematikan animasi agar tidak goyang (Sama seperti SystemBroken)
        end
    end)
end

local function StopFlying()
    Flying = false
    if FlyConnection then FlyConnection:Disconnect() end
    if BodyGyro then BodyGyro:Destroy() end
    if BodyVelocity then BodyVelocity:Destroy() end
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

-- Menambahkan tombol ke tab Movement (⚡) di script Anda
if movementTabFrame then
    local flyBtn = AddScriptButton("Fly: OFF", function()
        if not Flying then
            StartFlying()
            ShowNotification("Fly Activated (SystemBroken Mode)")
        else
            StopFlying()
            ShowNotification("Fly Deactivated")
        end
    end, movementTabFrame)

    -- Loop kecil untuk update teks tombol secara otomatis
    task.spawn(function()
        while task.wait(0.2) do
            if flyBtn then
                flyBtn.Text = Flying and "Fly: ON" or "Fly: OFF"
                flyBtn.BackgroundColor3 = Flying and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(150, 60, 255)
            end
        end
    end)
end

--- --- --- --- --- --- --- --- --- --- --- --- ---
-- FITUR AVATAR LIGHT (Mode Lampu)
--- --- --- --- --- --- --- --- --- --- --- --- ---
local AvaLightActive = false
local LightParts = {}

local function ToggleAvaLight()
    local char = player.Character
    if not char then return end
    
    AvaLightActive = not AvaLightActive
    
    if AvaLightActive then
        -- Menambahkan cahaya ke HumanoidRootPart agar menyebar dari tengah
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local pLight = Instance.new("PointLight")
            pLight.Brightness = 1.5 -- Seberapa terang
            pLight.Range = 40      -- Jarak pancaran cahaya
            pLight.Color = Color3.fromRGB(255, 255, 255)
            pLight.Parent = root
            table.insert(LightParts, pLight)
        end

        -- Membuat seluruh tubuh bersinar (Efek Glow)
        local highlight = Instance.new("Highlight")
        highlight.Name = "AvaGlow"
        highlight.FillColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = char
        table.insert(LightParts, highlight)
        
        ShowNotification("Avatar Light: ON")
    else
        -- Mematikan semua efek lampu
        for _, obj in pairs(LightParts) do
            if obj then obj:Destroy() end
        end
        local oldGlow = char:FindFirstChild("AvaGlow")
        if oldGlow then oldGlow:Destroy() end
        
        LightParts = {}
        ShowNotification("Avatar Light: OFF")
    end
end

-- Menambahkan tombol ke tab Movement (⚡)
if movementTabFrame then
    local avaLightBtn = AddScriptButton("Ava Light: OFF", function()
        ToggleAvaLight()
    end, movementTabFrame)

    -- Update tampilan tombol
    task.spawn(function()
        while task.wait(0.2) do
            if avaLightBtn then
                avaLightBtn.Text = AvaLightActive and "Ava Light: ON" or "Ava Light: OFF"
                avaLightBtn.BackgroundColor3 = AvaLightActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
                avaLightBtn.TextColor3 = AvaLightActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            end
        end
    end)
end
