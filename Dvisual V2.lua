-- ============================================================
-- DVISUAL LICENSE SYSTEM - FIXED
-- ============================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

local API_URL = "https://dvisual-api.budiksh6.workers.dev"
local API_TOKEN = "dimskuyyy21"
local VERSION = "1.0.1"

-- License key tidak lagi disimpan sebagai nilai default di dalam script.
-- Pengguna wajib memasukkannya melalui UI sebelum menu utama dibuka.
local RuntimeEnvironment = (getgenv and getgenv()) or _G

local function NormalizeLicenseKey(value)
    return tostring(value or "")
        :upper()
        :gsub("%s+", "")
end

local LICENSE_KEY = ""
RuntimeEnvironment.DVISUAL_LICENSE_KEY = nil

local LICENSE_FOLDER = "DVisual"
local LICENSE_FILE = LICENSE_FOLDER.."/license.json"


local function SaveLicenseData(data)

    if not isfolder(LICENSE_FOLDER) then
        makefolder(LICENSE_FOLDER)
    end

    writefile(
        LICENSE_FILE,
        HttpService:JSONEncode(data)
    )

end


local function LoadLicenseData()

    if not isfile(LICENSE_FILE) then
        return nil
    end


    local ok,result = pcall(function()

        return HttpService:JSONDecode(
            readfile(LICENSE_FILE)
        )

    end)


    if ok then
        return result
    end

end



local function RemoveSavedLicense()

    if isfile(LICENSE_FILE) then
        delfile(LICENSE_FILE)
    end

end

-- ============================================================
-- LICENSE LOCAL STORAGE
-- ============================================================

local function LoadLicenseKey()

    if isfile(LICENSE_FILE) then
        
        local saved = readfile(
            LICENSE_FILE
        )

        return NormalizeLicenseKey(saved)

    end


    return nil

end



local function RemoveSavedLicense()

    if isfile(LICENSE_FILE) then

        delfile(
            LICENSE_FILE
        )

    end

end

local REQUEST_FUNCTION =
    request
    or http_request
    or (syn and syn.request)
    or (fluxus and fluxus.request)

local LicenseState = {
    Active = false,
    Type = "Unknown",
    Session = nil,
    LastError = nil
}

local function GetLicenseTimeLeft()

    if not LicenseState.ExpireAt then
        return "Lifetime"
    end


    local expireTimestamp =
        DateTime.fromIsoDate(LicenseState.ExpireAt).UnixTimestamp


    local remaining =
        expireTimestamp - os.time()


    if remaining <= 0 then
        return "Expired"
    end


    local days =
        math.floor(remaining / 86400)


    local hours =
        math.floor(
            (remaining % 86400) / 3600
        )


    local minutes =
        math.floor(
            (remaining % 3600) / 60
        )


    return string.format(
        "%dD %02dH %02dM",
        days,
        hours,
        minutes
    )

end

local function GetRemainingTime(expire)


    if not expire then
        return "Unknown"
    end


    local ok, expireTime = pcall(function()
    return DateTime.fromIsoDate(expire).UnixTimestamp
	end)

	if not ok then
		return "Invalid Date"
	end


    local remain =
    expireTime - os.time()


    if remain <= 0 then
        return "Expired"
    end


    local days =
    math.floor(remain / 86400)


    local hours =
    math.floor((remain % 86400)/3600)


    local minutes =
    math.floor((remain % 3600)/60)


    local seconds =
    remain % 60


    return string.format(
        "%dd %02dh %02dm %02ds",
        days,
        hours,
        minutes,
        seconds
    )

end

local function ValidateLocalLicenseKey(key)
    if type(key) ~= "string" or key == "" then
        return false, "License key is empty"
    end

    if #key < 8 or #key > 100 then
        return false, "License key format is invalid"
    end

    return true
end

local function APIRequest(path, data)
    if type(REQUEST_FUNCTION) ~= "function" then
        return nil, "Executor does not support HTTP request"
    end

    local encodedOk, encodedBody = pcall(function()
        return HttpService:JSONEncode(data or {})
    end)

    if not encodedOk then
        return nil, "Failed to encode request data"
    end

    local requestOk, response = pcall(function()
        return REQUEST_FUNCTION({
            Url = API_URL .. path,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["X-API-Key"] = API_TOKEN,
                ["X-Dvisual-Version"] = VERSION
            },
            Body = encodedBody
        })
    end)

    if not requestOk then
        return nil, "Request failed: " .. tostring(response)
    end

    if type(response) ~= "table" then
        return nil, "Invalid response from license server"
    end

    local statusCode = tonumber(response.StatusCode or response.Status or 0) or 0
    if statusCode ~= 0 and (statusCode < 200 or statusCode >= 300) then
        return nil, "License server returned HTTP " .. tostring(statusCode), statusCode
    end

    return response, nil, statusCode
end

local function DecodeAPIResponse(response)
    if type(response) ~= "table" then
        return nil, "Response is not a table"
    end

    local body = response.Body
    if type(body) ~= "string" or body == "" then
        return {}, nil
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeOk or type(decoded) ~= "table" then
        return nil, "License server returned invalid JSON"
    end

    return decoded, nil
end

local function CheckLicense(candidateKey)
    local normalizedKey = NormalizeLicenseKey(candidateKey)
    local valid, validationError = ValidateLocalLicenseKey(normalizedKey)
    if not valid then
        LicenseState.LastError = validationError
        warn("[Dvisual] " .. validationError)
        return false
    end

    local response, requestError = APIRequest("/license/check", {
        userid = player.UserId,
        username = player.Name,
        key = normalizedKey,
        version = VERSION,
        placeid = game.PlaceId,
        jobid = game.JobId
    })

    if not response then
        LicenseState.LastError = requestError
        warn("[Dvisual] License check failed: " .. tostring(requestError))
        return false
    end

    local data, decodeError = DecodeAPIResponse(response)
    if not data then
        LicenseState.LastError = decodeError
        warn("[Dvisual] License check failed: " .. tostring(decodeError))
        return false
    end

    local accepted = data.success == true or data.valid == true
    if not accepted then
        local serverError = tostring(data.error or data.message or "License rejected")
        LicenseState.LastError = serverError
        warn("[Dvisual] " .. serverError)
        return false
    end

    LICENSE_KEY = normalizedKey

	RuntimeEnvironment.DVISUAL_LICENSE_KEY = LICENSE_KEY


	LicenseState.Expire =
	data.expire



	pcall(function()

		SaveLicenseData({

			key = LICENSE_KEY,

			expire = data.expire,

			userid = player.UserId

		})

	end)


	-- simpan license lokal
	pcall(function()

		SaveLicenseKey(
			LICENSE_KEY
		)

	end)
    LicenseState.Active = true
    LicenseState.Type = tostring(data.type or data.license_type or "Valid")
    LicenseState.Session = data.session or data.session_token or data.token
	LicenseState.ExpireAt = data.expire or data.expire_at
    LicenseState.LastError = nil

    print("[Dvisual] License accepted:", LicenseState.Type)
    return true
end

local function SendReport()
    if not LicenseState.Active then
        return false
    end

    local gameName = "Unknown"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    local response, requestError = APIRequest("/report", {
        userid = player.UserId,
        username = player.Name,
        displayname = player.DisplayName,
        executor = (identifyexecutor and identifyexecutor()) or "Unknown",
        version = VERSION,
        placeid = game.PlaceId,
        gamename = gameName,
        jobid = game.JobId,
        license_type = LicenseState.Type,
        session = LicenseState.Session,
        device = "",
        country = ""
    })

    if not response then
        warn("[Dvisual] Report failed: " .. tostring(requestError))
        return false
    end

    print("[Dvisual] Report sent")
    return true
end

-- ============================================================
-- AUTO LICENSE LOGIN
-- ============================================================

local function TrySavedLicense()

    local savedKey = LoadLicenseKey()


    if not savedKey then
        return false
    end


    print("[Dvisual] Checking saved license...")


    local success = CheckLicense(
        savedKey
    )


    if success then

        print("[Dvisual] Saved license accepted")

        return true

    end



    -- kalau gagal hapus cache

    RemoveSavedLicense()


    print(
        "[Dvisual] Saved license invalid, requesting new key"
    )


    return false

end

-- ============================================================
-- LICENSE INPUT UI
-- ============================================================
local function CreateLicensePrompt()
    local promptParent = game:GetService("CoreGui")

    if gethui then
        local ok, customParent = pcall(gethui)
        if ok and customParent then
            promptParent = customParent
        end
    end

    local oldPrompt = promptParent:FindFirstChild("DvisualLicensePrompt")
    if oldPrompt then
        oldPrompt:Destroy()
    end

    local promptGui = Instance.new("ScreenGui")
    promptGui.Name = "DvisualLicensePrompt"
    promptGui.ResetOnSpawn = false
    promptGui.IgnoreGuiInset = true
    promptGui.DisplayOrder = 999999
    promptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    promptGui.Parent = promptParent

    if protect_gui then
        pcall(protect_gui, promptGui)
    elseif syn and syn.protect_gui then
        pcall(syn.protect_gui, promptGui)
    end

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(7, 9, 14)
    overlay.BackgroundTransparency = 0.18
    overlay.BorderSizePixel = 0
    overlay.Active = true
    overlay.Parent = promptGui

    local panel = Instance.new("Frame")
    panel.Name = "LicensePanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0, 390, 0, 270)
    panel.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = overlay

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 18)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(92, 115, 255)
    panelStroke.Transparency = 0.15
    panelStroke.Thickness = 1.3
    panelStroke.Parent = panel

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 32, 47)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 20, 29))
    })
    gradient.Rotation = 35
    gradient.Parent = panel

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, -28, 0, 4)
    accent.Position = UDim2.new(0, 14, 0, 12)
    accent.BorderSizePixel = 0
    accent.BackgroundColor3 = Color3.fromRGB(98, 119, 255)
    accent.Parent = panel

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local accentGradient = Instance.new("UIGradient")
    accentGradient.Color = ColorSequence.new(
        Color3.fromRGB(98, 119, 255),
        Color3.fromRGB(116, 225, 255)
    )
    accentGradient.Parent = accent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 24, 0, 28)
    titleLabel.Size = UDim2.new(1, -48, 0, 32)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Dvisual License"
    titleLabel.TextColor3 = Color3.fromRGB(247, 249, 255)
    titleLabel.TextSize = 21
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = panel

    local description = Instance.new("TextLabel")
    description.BackgroundTransparency = 1
    description.Position = UDim2.new(0, 24, 0, 63)
    description.Size = UDim2.new(1, -48, 0, 38)
    description.Font = Enum.Font.GothamMedium
    description.Text = "Masukkan license key untuk membuka Dvisual."
    description.TextColor3 = Color3.fromRGB(172, 181, 204)
    description.TextSize = 12
    description.TextWrapped = true
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.Parent = panel

    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyInput"
    keyBox.Position = UDim2.new(0, 24, 0, 112)
    keyBox.Size = UDim2.new(1, -48, 0, 44)
    keyBox.BackgroundColor3 = Color3.fromRGB(31, 37, 52)
    keyBox.BorderSizePixel = 0
    keyBox.ClearTextOnFocus = false
    keyBox.Font = Enum.Font.GothamSemibold
    keyBox.PlaceholderText = "DV-XXXXXX-XXXXXX"
    keyBox.PlaceholderColor3 = Color3.fromRGB(115, 124, 148)
    keyBox.Text = ""
    keyBox.TextColor3 = Color3.fromRGB(245, 247, 255)
    keyBox.TextSize = 14
    keyBox.TextXAlignment = Enum.TextXAlignment.Left
    keyBox.Parent = panel

    local keyPadding = Instance.new("UIPadding")
    keyPadding.PaddingLeft = UDim.new(0, 14)
    keyPadding.PaddingRight = UDim.new(0, 14)
    keyPadding.Parent = keyBox

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 11)
    keyCorner.Parent = keyBox

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Color3.fromRGB(74, 88, 126)
    keyStroke.Transparency = 0.25
    keyStroke.Thickness = 1
    keyStroke.Parent = keyBox

    local statusLabel = Instance.new("TextLabel")
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(0, 24, 0, 162)
    statusLabel.Size = UDim2.new(1, -48, 0, 28)
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 112, 112)
    statusLabel.TextSize = 11
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = panel

    local submitButton = Instance.new("TextButton")
    submitButton.Name = "Submit"
    submitButton.Position = UDim2.new(0, 24, 1, -62)
    submitButton.Size = UDim2.new(1, -104, 0, 38)
    submitButton.BackgroundColor3 = Color3.fromRGB(93, 113, 255)
    submitButton.BorderSizePixel = 0
    submitButton.AutoButtonColor = true
    submitButton.Font = Enum.Font.GothamBold
    submitButton.Text = "VERIFY KEY"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.TextSize = 12
    submitButton.Parent = panel

    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 11)
    submitCorner.Parent = submitButton

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "Close"
    closeButton.Position = UDim2.new(1, -72, 1, -62)
    closeButton.Size = UDim2.new(0, 48, 0, 38)
    closeButton.BackgroundColor3 = Color3.fromRGB(45, 51, 68)
    closeButton.BorderSizePixel = 0
    closeButton.AutoButtonColor = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(220, 225, 238)
    closeButton.TextSize = 13
    closeButton.Parent = panel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 11)
    closeCorner.Parent = closeButton

    local resultEvent = Instance.new("BindableEvent")
    local verifying = false
    local closed = false

    local function SetBusy(isBusy)
        verifying = isBusy
        keyBox.TextEditable = not isBusy
        submitButton.Active = not isBusy
        submitButton.AutoButtonColor = not isBusy
        submitButton.Text = isBusy and "VERIFYING..." or "VERIFY KEY"
        submitButton.BackgroundColor3 = isBusy
            and Color3.fromRGB(65, 73, 105)
            or Color3.fromRGB(93, 113, 255)
    end

    local function SubmitKey()
        if verifying or closed then
            return
        end

        local enteredKey = NormalizeLicenseKey(keyBox.Text)
        keyBox.Text = enteredKey

        local localValid, localError = ValidateLocalLicenseKey(enteredKey)
        if not localValid then
            statusLabel.TextColor3 = Color3.fromRGB(255, 112, 112)
            statusLabel.Text = tostring(localError)
            return
        end

        SetBusy(true)
        statusLabel.TextColor3 = Color3.fromRGB(166, 190, 255)
        statusLabel.Text = "Menghubungkan ke license server..."

        task.spawn(function()
            local accepted = CheckLicense(enteredKey)

            if accepted then
                statusLabel.TextColor3 = Color3.fromRGB(105, 231, 155)
                statusLabel.Text = "Key valid. Membuka Dvisual..."
                task.wait(0.45)

                if not closed then
                    closed = true
                    resultEvent:Fire(true)
                end
            else
                SetBusy(false)
                statusLabel.TextColor3 = Color3.fromRGB(255, 112, 112)
                statusLabel.Text = tostring(LicenseState.LastError or "License key ditolak")
                keyBox:CaptureFocus()
            end
        end)
    end

    submitButton.MouseButton1Click:Connect(SubmitKey)
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            SubmitKey()
        end
    end)

    closeButton.MouseButton1Click:Connect(function()
        if closed then return end
        closed = true
        LicenseState.LastError = "License prompt closed by user"
        resultEvent:Fire(false)
    end)

    task.defer(function()
        if keyBox.Parent then
            keyBox:CaptureFocus()
        end
    end)

    local accepted = resultEvent.Event:Wait()
    resultEvent:Destroy()
    promptGui:Destroy()
    return accepted == true
end

-- ============================================================
-- LICENSE GATE
-- ============================================================


local licenseAccepted = false


local saved = LoadLicenseData()


if saved then

    print("[Dvisual] Checking saved license")

    print(
        "Remaining:",
        GetRemainingTime(saved.expire)
    )


    licenseAccepted =
    CheckLicense(saved.key)


end



if not licenseAccepted then

    licenseAccepted =
    CreateLicensePrompt()

end



if not licenseAccepted then

    warn(
    "[Dvisual] Access Denied"
    )

    return

end

task.spawn(SendReport)


-- ============================================================
-- LICENSE HEARTBEAT
-- ============================================================
local HeartbeatRunning = true
local ConsecutiveHeartbeatFailures = 0
local MAX_HEARTBEAT_FAILURES = 5

local function StopLicenseHeartbeat()
    HeartbeatRunning = false
end

RuntimeEnvironment.DVISUAL_STOP_LICENSE_HEARTBEAT = StopLicenseHeartbeat

task.spawn(function()
    while HeartbeatRunning and LicenseState.Active do
        task.wait(30)

        if not HeartbeatRunning or not LicenseState.Active then
            break
        end

        local response, requestError, statusCode = APIRequest("/heartbeat", {
            userid = player.UserId,
            key = LICENSE_KEY,
            session = LicenseState.Session,
            version = VERSION,
            placeid = game.PlaceId,
            jobid = game.JobId
        })

        if not response then
            ConsecutiveHeartbeatFailures = ConsecutiveHeartbeatFailures + 1
            warn(
                "[Dvisual] Heartbeat failed ("
                .. tostring(ConsecutiveHeartbeatFailures)
                .. "/"
                .. tostring(MAX_HEARTBEAT_FAILURES)
                .. "): "
                .. tostring(requestError)
            )

            -- HTTP 401/403 berarti akses memang ditolak, bukan sekadar jaringan putus.
            if statusCode == 401 or statusCode == 403 then
                LicenseState.Active = false
                LicenseState.LastError = requestError
                break
            end
        else
            local heartbeatData = DecodeAPIResponse(response)

            if type(heartbeatData) == "table"
                and (heartbeatData.success == false or heartbeatData.valid == false) then
                LicenseState.Active = false
                LicenseState.LastError = tostring(
                    heartbeatData.error
                    or heartbeatData.message
                    or "License heartbeat rejected"
                )
                warn("[Dvisual] " .. LicenseState.LastError)
                break
            end

            ConsecutiveHeartbeatFailures = 0
            print("[Dvisual] Heartbeat OK")
        end

        -- Kegagalan jaringan berulang menghentikan heartbeat, tetapi tidak membuat loop tak terbatas.
        if ConsecutiveHeartbeatFailures >= MAX_HEARTBEAT_FAILURES then
            warn("[Dvisual] Heartbeat stopped after repeated connection failures")
            break
        end
    end

    HeartbeatRunning = false
end)

local oldGui = game:GetService("CoreGui"):FindFirstChild("DvisualUI_Final")
if oldGui then
    oldGui:Destroy()
end

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketService = game:GetService("MarketplaceService")

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local TargetPlayer = nil
local Spectating = false
local Following = false
local FollowConnection = nil
local Headsitting = false
local HeadsitConnection = nil
local Flying = false
local FlySpeed = 50 -- Nilai awal; dapat diubah lewat UI
local FlyConnection = nil
local FlyShortcutConnection = nil
local FlyHumanoidDiedConnection = nil
local BodyGyro = nil
local BodyVelocity = nil
local PreviousFlyHumanoidState = nil

local SavedAnimations = {
    ["Idle"] = nil, ["Walk"] = nil, ["Run"] = nil,
    ["Jump"] = nil, ["Fall"] = nil, ["Climb"] = nil,
    ["SwimIdle"] = nil, ["Swim"] = nil
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
title.Text = "🔥 Dvisual V2 by Udin"
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

if name == "Home" then
    local grid = Instance.new("UIGridLayout")
    grid.Parent = frame
    grid.CellSize = UDim2.new(0.49, -5, 0, 35)
    grid.CellPadding = UDim2.new(0, 5, 0, 5)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
else
    local layout = Instance.new("UIListLayout")
    layout.Parent = frame
    layout.Padding = UDim.new(0, 8)
end

    return frame
end

local infoTabFrame = CreateTabFrame("Info", true)
local homeTabFrame = CreateTabFrame("Home", false)
local avatarTabFrame = CreateTabFrame("Avatar", false)
local animTabFrame = CreateTabFrame("Animation", false) 
local characterTabFrame = CreateTabFrame("Character", false)
local movementTabFrame = CreateTabFrame("Movement", false)
movementTabFrame.ClipsDescendants = true

local function showTab(tabName)
    infoTabFrame.Visible = (tabName == "Info")
    homeTabFrame.Visible = (tabName == "Home")
    avatarTabFrame.Visible = (tabName == "Avatar")
	animTabFrame.Visible = (tabName == "Animation") 
	characterTabFrame.Visible = (tabName == "Character")
	movementTabFrame.Visible = (tabName == "Movement")
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

-- ============================================================
-- LICENSE TIME INFO
-- ============================================================

local licenseTimeInfo = Instance.new("TextLabel")
licenseTimeInfo.Parent = infoTabFrame
licenseTimeInfo.Size = UDim2.new(1,0,0,25)
licenseTimeInfo.BackgroundTransparency = 1
licenseTimeInfo.Text = " • License: Calculating..."
licenseTimeInfo.TextColor3 = Color3.fromRGB(105,231,155)
licenseTimeInfo.Font = Enum.Font.GothamBold
licenseTimeInfo.TextSize = 12
licenseTimeInfo.TextXAlignment = Enum.TextXAlignment.Left


task.spawn(function()

    while licenseTimeInfo.Parent do

        local expire =
            LicenseState.ExpireAt
            or LicenseState.Expire


        local remaining =
            GetRemainingTime(expire)


        licenseTimeInfo.Text =
            " • License Time: "..remaining


        if remaining == "Expired" then

            licenseTimeInfo.TextColor3 =
                Color3.fromRGB(255,100,100)

        elseif remaining == "Lifetime" then

            licenseTimeInfo.TextColor3 =
                Color3.fromRGB(100,180,255)

        else

            licenseTimeInfo.TextColor3 =
                Color3.fromRGB(105,231,155)

        end


        task.wait(1)

    end

end)

local function BorrowSelectedPlayerAvatar(targetUsername)
    local targetPlayer = Players:FindFirstChild(targetUsername)
    if targetPlayer then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if hum then
            local success, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(targetPlayer.UserId)
            end)
            
            if success and desc then
                pcall(function()
                    if hum["ApplyDescriptionClientServer"] then
                        hum:ApplyDescriptionClientServer(desc)
                    else
                        hum:ApplyDescription(desc)
                    end
                end)
                ShowNotification("Successfully borrowed avatar!")
            else
                ShowNotification("Failed to fetch player data.")
            end
        end
    else
        ShowNotification("Player not found in server.")
    end
end

local function ApplySteal(targetUserId)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local success, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(targetUserId)
        end)
        if success and desc then
            -- Menggunakan pcall untuk menghindari error jika proses apply gagal
            pcall(function()
                hum:ApplyDescription(desc)
            end)
            ShowNotification("Avatar Copied!")
        else
            ShowNotification("Failed to fetch Avatar.")
        end
    end
end

--- --- 🔹 ISI TAB HOME 🔹 --- ---
local function AddScriptButton(name, callback, parent)
    local targetParent = parent or homeTabFrame
    local btn = Instance.new("TextButton")
    btn.Parent = targetParent

    -- Tombol sebelumnya memiliki lebar 0 pixel. Teksnya masih terlihat,
    -- tetapi area kliknya tidak ada dan teks meluber ke sidebar.
    -- Ukuran diatur berdasarkan layout parent agar selalu berada di tengah
    -- dan mempunyai area klik yang benar.
    local gridLayout = targetParent:FindFirstChildOfClass("UIGridLayout")
    local listLayout = targetParent:FindFirstChildOfClass("UIListLayout")

    if gridLayout then
        -- UIGridLayout akan menentukan ukuran final tombol.
        btn.Size = UDim2.new(1, 0, 1, 0)
    elseif listLayout and listLayout.FillDirection == Enum.FillDirection.Horizontal then
        -- Container aksi Avatar berisi tiga tombol horizontal.
        btn.Size = UDim2.new(1 / 3, -4, 1, 0)
    elseif targetParent == movementTabFrame then
        -- Beri margin kiri/kanan agar tombol Movement rapi dan terpusat.
        btn.Size = UDim2.new(1, -8, 0, 34)
    else
        btn.Size = UDim2.new(1, 0, 0, 30)
    end

    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.92
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.TextYAlignment = Enum.TextYAlignment.Center
    btn.TextWrapped = true
    btn.AutoButtonColor = true
    btn.Active = true
    btn.Selectable = true
    btn.ZIndex = 3

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

AddScriptButton("Laser", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KNTLX69/SXTHR666/refs/heads/main/SIEXTHER-HYTAMKAN"))()
    ShowNotification("Laser Executed!")
end)

AddScriptButton("Animate SPy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Dvisual89/Dvisual/refs/heads/main/Animation%20and%20Emotes%20Spy%20ASSETS%20ID.lua"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Sky Changer", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Dvisual89/Dvisual/refs/heads/main/skybox.lua"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Bring Coil", function()
    loadstring(game:HttpGet("https://gist.githubusercontent.com/Ahma174/4e504a62e822daa3039192afa9752713/raw/8ff97c8f86d016ef9ad719f03c3aaf0ccc897bd1/gistfile1.txt"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Sambung Kata V5", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Dvisual89/Dvisual/refs/heads/main/Sambung%20Kata%20V5.lua"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Fly Controller", function()
    loadstring(game:HttpGet("https://encrypt-x.pages.dev/Scripts?Id=kuramaid04"))("kuramaid04")
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Koin Hutan", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Dvisual89/Dvisual/refs/heads/main/Koin%20Hutan.lua"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Drop Kick", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/gsm231/Fe-DropKick/refs/heads/main/V0.1"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Hide Invis FE", function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/Kixdev/roblox-invisible-hybrid-script/main/main.lua"))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Hide Player Cine", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kixdev/hide-players-roblox/refs/heads/main/main.lua", true))()
    ShowNotification("Animation Executed!")
end)

AddScriptButton("Remotespy Fayint", function()
    loadstring(game:HttpGet("https://fayintz.my.id/api/loader/Scanner-Remote"))()
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
				["Effortless Aura"] = {"109023565617920", "101782607233045"},
				["Pixel Animation"] = {"130194283182451", "136782362569794"},
				["Zombie New"] = {"128132851784308", "94392532437836"},
				["Thief Animation"] = {"70765889938975", "87903617826484"},
				["Macho Man"] = {"124837298681300", "111997581428800"},
				["Handstand"] = {"73956906322787", "135783589150448"},
				["Animal 1"] = {"128838183008466", "99689776099970"},
				["Diva Animation"] = {"125002802413463", "135832836685353"},
				["Sashy Animation"] = {"86331391001512", "126880205034345"},
				["Boxer Animation"] = {"117573788129745", "115401318197877"},
				["Endless Aura"] = {"121544739965950", "128694271964813"},
				["Aura Animation Pack"] = {"116944673851292", "105356446763414"},
				["Goofy Animation"] = {"81262806023290", "133670703261396"},
				["Furry Animation"] = {"111821292044705", "90705157329932"},
				["Superhero 2 Animation"] = {"127540423685755", "96954038650210"},
				["Springy Animation"] = {"91686730043262", "83065673922334"},
				["Nonchalant Animation"] = {"129560720895838", "116285713212355"},
				["Spyder Animation"] = {"112316814377814", "103439018552145"},
				["Tall Animation"] = {"119900649290589", "79810617204918"},
				["FIFA Football Animation"] = {"126206315312833", "115127123362265"},
				["Doll Animation"] = {"106864431745423", "102002404154887"},
				["Flipped Animation"] = {"91883473454076", "121016684306842"},
				["Source Animation"] = {"103431494817087", "95523063739871"},
				["Deltarune Roaring Knight"] = {"137524832029481", "112301424506019"},
				["Hatsune Miku VOCALOID"] = {"105521323066042", "132090379340717"},
				["Mimic Animation"] = {"118763458478828", "135884580161540"},
				["Girl Animation"] = {"134102049024846", "94218291379339"},
				["Crawl Animation"] = {"83355864061118"},
				["Springtap Animation"] = {"78235464008167"},
				["Skipping Animation"] = {"74803881612975", "113188043990631"},
				["Deltarune Lightner"] = {"132384974092060", "76952428326181"},
				["Fighter Animation"] = {"82769073034261", "95961933254232"},
				["CAT Animation"] = {"110290852805486", "78932174316934"},
				["Kawaii Girl"] = {"91290152009095"},
				["Backward Animation"] = {"110142123884844", "74788506079005"},
				["Cool Boy Animation"] = {"138243880544114"},
				["Scared Animation"] = {"120879126406241", "90962592517596"},
				["Rolling Animation Pack"] = {"120879126406241", "84689831662753"},
				["Sprinter Animation"] = {"78670233456525", "72865479116768"},
				["64 Dude Pack"] = {"127032691162714"},
				["Flamboyant Animation"] = {"82252617239232"},
				["Deltarune Flowery"] = {"86146687944344", "106542935528223"},
				["Fort Builder Animation"] = {"87010315132588"},
				["Dog Animation"] = {"95381333710727", "88658004353559"},
				["Flying Animation Pack"] = {"110459850241477"},
				["Scaredy Animation Pack"] = {"81132307439918", "73922098864695"},
				["Anime Idol Animation"] = {"90362640523158", "87473213463123"},
				["Ring Runner Animation"] = {"125644996161480", "126321996675925"},
				["Glitch Animation"] = {"118195246541519"},
				["Viltrumite Animation"] = {"99904423750888", "131365143981468"},
				["Super Saiyan Goku DBZ"] = {"79770827380799", "88434732011038"},
				["Anime Ninja"] = {"73210192075588", "120601740200526"},
				["Bycyclist"] = {"126390120399173", "136791517336633"},
				["Spyder Hero Animation"] = {"87722152938224", "121619775156126"},
				["Spantom NEO / Possessed"] = {"73004172890672", "88730428465454"},
				["Enchanted Fairy Animation"] = {"73650178233095", "91910561917902"},
				["R6 Energy"] = {"120018952257243"},
				["Chill Sans Animation"] = {"119023489901719"},
				["Dizzy Animation Pack"] = {"132806359718468", "103572794348956"},
				["Springy Animation Pack"] = {"91686730043262", "83065673922334"},
				["Undead Animation Pack"] = {"75569223813368", "112244741866688"},
				["Joy Animation Pack"] = {"119957475250242", "101200477339169"},
				["Average Stand User"] = {"71892045500531", "104888565378032"},
				["Goofball Animation Pack"] = {"122445268463393", "87096122085440"},
				["Military Animation Pack"] = {"78000479058193", "134726029897802"},
				["Cartoony Scared Animation"] = {"131042351421446"},
				["Skater Animation Pack"] = {"122545331332536", "72665864569945"},
				["Gremlin"] = {"101918025133407", "101918025133407"},
				["(UGC) Uget"] = {"99638411514722", "10713992055"},
				["(UGC) Udin"] = {"75750638564696", "71692149930645"},
				["Billie Ellish"] = {"102934602884410", "92151291669373"},
				["Katseye"] = {"108187809145790", "72329200359275"},
				["Glow Motion"] = {"137764781910579", "96439737641086"},
				["Adidas Aura"] = {"110211186840347", "114191137265065"},
				["AuraAnimationPack"] = {"18747067405", "507766666"},
				["2016 Animation (mm2)"] = {"387947158", "387947464"},
				["AuraFarming"] = {"138665010911335", "138665010911335"},
				["Borock"] = {"3293641938", "3293642554"},
				["cesus"] = {"115879733952840", "115879733952840"},
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
				["(UGC) Retro Zombie"] = "140703855480494", ["(UGC) Retro"] = "107806791584829", ["(UGC) Smooth"] = "76630051272791", ["(UGC) Udin"] = "125451074692113", ["(UGC) Uget"] = "102622695004986", ["(UGC) Zombie"] = "113603435314095", ["2016 Animation (mm2)"] = "387947975", ["64 Dude Pack"] = "90014316242626", ["Adidas Aura"] = "83842218823011", ["Adidas Community"] = "122150855457006", ["Animal 1"] = "112238064449133", ["Anime Idol Animation"] = "123892408552826", ["Anime Ninja"] = "121509954212911", ["Astronaut"] = "891667138", ["Aura Animation Pack"] = "97462772841800", ["AuraAnimationPack"] = "18747074203", ["Average Stand User"] = "102431627444820", ["Backward Animation"] = "106882619223954", ["Billie Ellish"] = "111071007924288", ["Bold"] = "16738340646", ["Boxer Animation"] = "124531990122756", ["Bubbly"] = "910034870", ["Bycyclist"] = "98707881660541", ["CAT Animation"] = "128562578525167", ["Cartoony"] = "742640026", ["Cartoony Scared Animation"] = "85244122440192", ["Catwalk Glam"] = "109168724482748", ["Chill Sans Animation"] = "102322585064571", ["Confident"] = "1070017263", ["Cool Boy Animation"] = "122378149078729", ["Cowboy"] = "1014421541", ["Crawl Animation"] = "106855154141348", ["Default Retarget"] = "115825677624788", ["Deltarune Flowery"] = "74638723073919", ["Deltarune Lightner"] = "88605898422576", ["Deltarune Roaring Knight"] = "89143328199760", ["Diva Animation"] = "89565112287783", ["Dizzy Animation Pack"] = "110106034100313", ["Dog Animation"] = "96823669333608", ["Doll Animation"] = "122687078497889", ["Drooling Zombie"] = "3489174223", ["Effortless Aura"] = "96565230403734", ["Elder"] = "10921111375", ["Enchanted Fairy Animation"] = "94547195663763", ["Endless Aura"] = "140535536297327", ["FIFA Football Animation"] = "131389117059632", ["Fighter Animation"] = "136268128987143", ["Flamboyant Animation"] = "76647815644055", ["Flipped Animation"] = "93477017949252", ["Flying Animation Pack"] = "79965952836445", ["Fort Builder Animation"] = "88678863016661", ["Furry Animation"] = "104011441852459", ["Geto"] = "85811471336028", ["Ghost"] = "616013216", ["Girl Animation"] = "92999715416329", ["Glitch Animation"] = "70532084598346", ["Glow Motion"] = "85809016093530", ["Gojo"] = "95643163365384", ["Goofball Animation Pack"] = "115844278492913", ["Goofy Animation"] = "104206572530707", ["Gremlin"] = "76359514564810", ["Handstand"] = "82055796073914", ["Hatsune Miku VOCALOID"] = "107150123451401", ["Joy Animation Pack"] = "112597572150963", ["Katseye"] = "99182913548783", ["Kawaii Girl"] = "130976129535418", ["Knight"] = "10921127095", ["Levitation"] = "616013216", ["Macho Man"] = "92292256587514", ["Mage"] = "707897309", ["Military Animation Pack"] = "126435309103395", ["Mimic Animation"] = "96268950468279", ["NFL"] = "110358958299415", ["Ninja"] = "656121766", ["No Boundaries (Walmart)"] = "18747074203", ["Nonchalant Animation"] = "89854001699438", ["OldSchool"] = "10921244891", ["Patrol"] = "1151231493", ["Piksel Animation"] = "82742503182065", ["Pirate"] = "750785693", ["Popstar"] = "1212980338", ["Princess"] = "941028902", ["R15 Reanimated"] = "4211223236", ["R6"] = "12518152696", ["R6 Energy"] = "123210125864900", ["Ring Runner Animation"] = "131115506570135", ["Robot"] = "616095330", ["Rolling Animation Pack"] = "128241131366768", ["Rthro"] = "10921269718", ["Sashy Animation"] = "136879687900769", ["Scared Animation"] = "138468792534506", ["Scaredy Animation Pack"] = "94718858900785", ["Skater Animation Pack"] = "73059365804498", ["Skipping Animation"] = "102861298511025", ["Sneaky"] = "1132510133", ["Source Animation"] = "114340880259217", ["Spantom NEO / Possessed"] = "133330127310021", ["Sports (Adidas)"] = "18537392113", ["Sprinter Animation"] = "106176122428044", ["Springtap Animation"] = "83918921463631", ["Springy Animation"] = "90966053497240", ["Spyder Animation"] = "109976439277879", ["Spyder Hero Animation"] = "119802088850397", ["Stylish"] = "616146177", ["Stylized Female"] = "4708193840", ["Super Saiyan Goku DBZ"] = "110637848614810", ["Superhero"] = "10921298616", ["Superhero 2 Animation"] = "129560262949359", ["Tall Animation"] = "125858005892679", ["Thief Animation"] = "116391452602396", ["Toy"] = "782843345", ["Udzal"] = "3303162967", ["Unboxed By Amazon"] = "90478085024465", ["Undead Animation Pack"] = "122375411238115", ["Vampire"] = "1083473930", ["Viltrumite Animation"] = "132624199623293", ["Werewolf"] = "1083178339", ["Wicked (Popular)"] = "92072849924640", ["Wicked \"Dancing Through Life\""] = "73718308412641", ["Zombie"] = "616168032", ["Zombie New"] = "81931167118728"
			},
			["Run"] = {
				["Effortless Aura"] = "94645534606796",
				["Pixel Animation"] = "99550252660076",
				["Zombie New"] = "126853923835932",
				["Thief Animation"] = "100222972388612",
				["Macho Man"] = "114032421862095",
				["Handstand"] = "139569292637224",
				["Animal 1"] = "97412731442167",
				["Diva Animation"] = "96071091521000",
				["Sashy Animation"] = "140344184340309",
				["Boxer Animation"] = "87858017151514",
				["Endless Aura"] = "131446204283995",
				["Aura Animation Pack"] = "72394449489636",
				["Goofy Animation"] = "137164011194425",
				["Furry Animation"] = "87770060317862",
				["Superhero 2 Animation"] = "91705781577408",
				["Springy Animation"] = "84892003036631",
				["Nonchalant Animation"] = "122740418633770",
				["Spyder Animation"] = "119985832593347",
				["Tall Animation"] = "85638084368229",
				["FIFA Football Animation"] = "101650118148392",
				["Doll Animation"] = "121605642130190",
				["Flipped Animation"] = "102272249399047",
				["Source Animation"] = "107131844732590",
				["Deltarune Roaring Knight"] = "123556908617762",
				["Hatsune Miku VOCALOID"] = "123740808341795",
				["Mimic Animation"] = "133480606285488",
				["Girl Animation"] = "116206647177962",
				["Crawl Animation"] = "132928374449919",
				["Springtap Animation"] = "118118944467818",
				["Skipping Animation"] = "118751915605378",
				["Deltarune Lightner"] = "90244043983451",
				["Fighter Animation"] = "74340216141866",
				["CAT Animation"] = "102032294179355",
				["Kawaii Girl"] = "82718166343916",
				["Backward Animation"] = "120123580654919",
				["Cool Boy Animation"] = "88944083168261",
				["Scared Animation"] = "94292858675799",
				["Rolling Animation Pack"] = "100998966618362",
				["Sprinter Animation"] = "77128372412361",
				["64 Dude Pack"] = "129706643244921",
				["Flamboyant Animation"] = "98054766954797",
				["Deltarune Flowery"] = "99617705167958",
				["Fort Builder Animation"] = "102682283977442",
				["Dog Animation"] = "115999580293417",
				["Flying Animation Pack"] = "139769144653486",
				["Scaredy Animation Pack"] = "121427254479232",
				["Anime Idol Animation"] = "133887249482857",
				["Ring Runner Animation"] = "132275453694553",
				["Glitch Animation"] = "133291236719695",
				["Viltrumite Animation"] = "137392594073546",
				["Super Saiyan Goku DBZ"] = "126476030340764",
				["Anime Ninja"] = "118321428692216",
				["Bycyclist"] = "102775737211919",
				["Spyder Hero Animation"] = "97619860065816",
				["Spantom NEO / Possessed"] = "102159146926867",
				["Enchanted Fairy Animation"] = "76909584337943",
				["R6 Energy"] = "136019284650192",
				["Chill Sans Animation"] = "111734473441681",
				["Dizzy Animation Pack"] = "138305342272849",
				["Springy Animation Pack"] = "84892003036631",
				["Undead Animation Pack"] = "105582003875509",
				["Joy Animation Pack"] = "96521659811743",
				["Average Stand User"] = "83938395060770",
				["Goofball Animation Pack"] = "111398265976262",
				["Military Animation Pack"] = "134701391074214",
				["Cartoony Scared Animation"] = "72842409551212",
				["Skater Animation Pack"] = "89156629057954",
				["(UGC) Uget"] = "102622695004986",
				["(UGC) Udin"] = "137157431400864",
				["Billie Ellish"] = "98611796189880",
				["Katseye"] = "73117360545482",
				["Glow Motion"] = "101925097435036",
				["Adidas Aura"] = "118320322718866",
				["Robot"] = "10921250460",
				["Patrol"] = "1150967949",
				["Drooling Zombie"] = "3489173414",
				["Adidas Community"] = "82598234841035",
				["Heavy Run (Udzal / Borock)"] = "3236836670",
				["Catwalk Glam"] = "81024476153754",
				["Knight"] = "10921121197",
				["Pirate"] = "750783738",
				["Bold"] = "16738337225",
				["Sports (Adidas)"] = "18537384940",
				["Zombie"] = "616163682",
				["Astronaut"] = "10921039308",
				["Cartoony"] = "10921076136",
				["Ninja"] = "656118852",
				["(UGC) Dog"] = "130072963359721",
				["Wicked \"Dancing Through Life\""] = "135515454877967",
				["Unboxed By Amazon"] = "134824450619865",
				["[UGC] Flipping"] = "124427738251511",
				["Sneaky"] = "1132494274",
				["R6"] = "12518152696",
				["[VOTE] Aura"] = "120142877225965",
				["Popstar"] = "1212980348",
				["[UGC] reset"] = "0",
				["Wicked (Popular)"] = "72301599441680",
				["[UGC] chibi"] = "85887415033585",
				["R15 Reanimated"] = "4211220381",
				["Mage"] = "10921148209",
				["Ghost"] = "616013216",
				["Rthro"] = "10921261968",
				["Confident"] = "1070001516",
				["Stylized Female"] = "4708192705",
				["No Boundaries (Walmart)"] = "18747070484",
				["Elder"] = "10921104374",
				["Werewolf"] = "10921336997",
				["[UGC] Girly"] = "128578785610052",
				["Stylish"] = "10921276116",
				["(UGC) Pride"] = "116462200642360",
				["NFL"] = "117333533048078",
				["(UGC) Soccer"] = "116881956670910",
				["MrToilet"] = "4417979645",
				["[VOTE] Float"] = "71267457613791",
				["Levitation"] = "616010382",
				["(UGC) Retro"] = "107806791584829",
				["(UGC) Retro Zombie"] = "140703855480494",
				["OldSchool"] = "10921240218",
				["Vampire"] = "10921320299",
				["furry"] = "102269417125238",
				["Bubbly"] = "10921057244",
				["fake wicked"] = "138992096476836",
				["2016 Animation (mm2)"] = "387947975",
				["[UGC] ball"] = "132499588684957",
				["Superhero"] = "10921291831",
				["Toy"] = "10921306285",
				["Default Retarget"] = "102294264237491",
				["Princess"] = "941015281",
				["Cowboy"] = "1014401683"
			},
			["Jump"] = {
				["Effortless Aura"] = "89471740791625",
				["Pixel Animation"] = "85535465961669",
				["Zombie New"] = "135714499879455",
				["Thief Animation"] = "117109494570159",
				["Macho Man"] = "118579258550162",
				["Handstand"] = "73779824944177",
				["Animal 1"] = "123565665274439",
				["Diva Animation"] = "101775864038046",
				["Sashy Animation"] = "78405222440170",
				["Boxer Animation"] = "114665625725595",
				["Endless Aura"] = "87182355463462",
				["Aura Animation Pack"] = "110741235266373",
				["Goofy Animation"] = "102201742827296",
				["Furry Animation"] = "102635582722041",
				["Superhero 2 Animation"] = "76297310003744",
				["Springy Animation"] = "91907092633520",
				["Nonchalant Animation"] = "97798483904259",
				["Spyder Animation"] = "87979233462906",
				["Tall Animation"] = "71122628522377",
				["FIFA Football Animation"] = "86067810999134",
				["Doll Animation"] = "100084997353034",
				["Flipped Animation"] = "118538125606545",
				["Source Animation"] = "113193697536711",
				["Deltarune Roaring Knight"] = "112021059200039",
				["Hatsune Miku VOCALOID"] = "97139072399156",
				["Mimic Animation"] = "87039529807392",
				["Girl Animation"] = "99426770900488",
				["Crawl Animation"] = "80062892367225",
				["Springtap Animation"] = "88697890125511",
				["Skipping Animation"] = "135973105848296",
				["Deltarune Lightner"] = "95895195683197",
				["Fighter Animation"] = "93532983238161",
				["CAT Animation"] = "78123184265997",
				["Kawaii Girl"] = "112613895102125",
				["Backward Animation"] = "78278285450952",
				["Cool Boy Animation"] = "135685674199878",
				["Scared Animation"] = "111147456573108",
				["Rolling Animation Pack"] = "114751541427034",
				["Sprinter Animation"] = "129165391997568",
				["64 Dude Pack"] = "76570630008633",
				["Flamboyant Animation"] = "120983173565332",
				["Deltarune Flowery"] = "104259166633616",
				["Fort Builder Animation"] = "85803808149741",
				["Dog Animation"] = "127563386068232",
				["Flying Animation Pack"] = "123057997432919",
				["Scaredy Animation Pack"] = "111564218335533",
				["Anime Idol Animation"] = "122308108037183",
				["Ring Runner Animation"] = "112789048551215",
				["Glitch Animation"] = "87784517289295",
				["Viltrumite Animation"] = "115670697049931",
				["Super Saiyan Goku DBZ"] = "114126293185852",
				["Anime Ninja"] = "113663008530766",
				["Bycyclist"] = "129144847881258",
				["Spyder Hero Animation"] = "100489525375356",
				["Spantom NEO / Possessed"] = "73866711064819",
				["Enchanted Fairy Animation"] = "120533712803667",
				["R6 Energy"] = "72333829074581",
				["Chill Sans Animation"] = "107273629375596",
				["Dizzy Animation Pack"] = "110741235266373", -- Menggunakan ID Jump dari data sejenis karena data asli Dizzy terlewat di daftar inputmu, atau sesuaikan dengan kebutuhanmu.
				["Springy Animation Pack"] = "91907092633520",
				["Undead Animation Pack"] = "84905555577866",
				["Joy Animation Pack"] = "82500357520736",
				["Average Stand User"] = "85412574030124",
				["Goofball Animation Pack"] = "131815435947100",
				["Military Animation Pack"] = "114270132403423",
				["Cartoony Scared Animation"] = "99032559646949",
				["Skater Animation Pack"] = "79140034056165",
				["Billie Ellish"] = "122079822566965",
				["Katseye"] = "103632305262747",
				["Glow Motion	"] = "74159004634379",
				["Adidas Aura"] = "109996626521204",
				["Robot"] = "616090535",
				["Patrol"] = "1148811837",
				["Adidas Community"] = "75290611992385",
				["Levitation"] = "616008936",
				["Catwalk Glam"] = "116936326516985",
				["Knight"] = "910016857",
				["Pirate"] = "750782230",
				["Bold"] = "16738336650",
				["Sports (Adidas)"] = "18537380791",
				["Zombie"] = "616161997",
				["Astronaut"] = "891627522",
				["Cartoony"] = "742637942",
				["Ninja"] = "656117878",
				["Confident"] = "1069984524",
				["Wicked \"Dancing Through Life\""] = "78508480717326",
				["Unboxed By Amazon"] = "121454505477205",
				["R6"] = "12520880485",
				["R15 Reanimated"] = "4211219390",
				["Ghost"] = "616008936",
				["Rthro"] = "10921263860",
				["No Boundaries (Walmart)"] = "18747069148",
				["Werewolf"] = "1083218792",
				["Cowboy"] = "1014394726",
				["UGC"] = "91788124131212",
				["[VOTE] Animal"] = "131203832825082",
				["Popstar"] = "1212954642",
				["Mage"] = "10921149743",
				["Sneaky"] = "1132489853",
				["Superhero"] = "10921294559",
				["Elder"] = "10921107367",
				["(UGC) Retro"] = "139390570947836",
				["NFL"] = "119846112151352",
				["OldSchool"] = "10921242013",
				["Stylized Female"] = "4708188025",
				["Stylish"] = "616139451",
				["Bubbly"] = "910016857",
				["[VOTE] Float"] = "75611679208549",
				["[VOTE] Aura"] = "93382302369459",
				["Vampire"] = "1083455352",
				["Wicked (Popular)"] = "104325245285198",
				["Toy"] = "10921308158",
				["Default Retarget"] = "117150377950987",
				["Princess"] = "941008832",
				["[UGC] happy"] = "72388373557525"
			},
			["Fall"] = {
				["Effortless Aura"] = "116066537140570",
				["Pixel Animation"] = "136658360392607",
				["Zombie New"] = "138550244171866",
				["Thief Animation"] = "84593260785426",
				["Macho Man"] = "80042889753518",
				["Handstand"] = "85631336834768",
				["Animal 1"] = "124705831982259",
				["Diva Animation"] = "123267706208603",
				["Sashy Animation"] = "125781313219969",
				["Boxer Animation"] = "138924660292608",
				["Endless Aura"] = "119546655136861",
				["Aura Animation Pack"] = "88037637684328",
				["Goofy Animation"] = "73467825158433",
				["Furry Animation"] = "137079985547592",
				["Superhero 2 Animation"] = "98754219549882",
				["Springy Animation"] = "97093456206868",
				["Nonchalant Animation"] = "136077916815007",
				["Spyder Animation"] = "71112238570777",
				["Tall Animation"] = "86589811780536",
				["FIFA Football Animation"] = "132430735809748",
				["Doll Animation"] = "77955211844487",
				["Flipped Animation"] = "111992832150062",
				["Source Animation"] = "89091800114758",
				["Deltarune Roaring Knight"] = "123533341016227",
				["Hatsune Miku VOCALOID"] = "120197524028617",
				["Mimic Animation"] = "122265777573948",
				["Girl Animation"] = "85681129938720",
				["Crawl Animation"] = "89338081505868",
				["Springtap Animation"] = "116204982054666",
				["Skipping Animation"] = "110124538147223",
				["Deltarune Lightner"] = "120134087550054",
				["Fighter Animation"] = "123719735160766",
				["CAT Animation"] = "134287440300976",
				["Kawaii Girl"] = "99819053949589",
				["Backward Animation"] = "82628145391214",
				["Cool Boy Animation"] = "116555453859893",
				["Scared Animation"] = "118828218865394",
				["Rolling Animation Pack"] = "99937257951807",
				["Sprinter Animation"] = "121360493289215",
				["64 Dude Pack"] = "119190893282260",
				["Flamboyant Animation"] = "88016907618874",
				["Deltarune Flowery"] = "86738128273450",
				["Fort Builder Animation"] = "113719495125909",
				["Dog Animation"] = "112503796812564",
				["Flying Animation Pack"] = "105524079566851",
				["Scaredy Animation Pack"] = "105642662748426",
				["Anime Idol Animation"] = "88818300221585",
				["Ring Runner Animation"] = "137128181467405",
				["Glitch Animation"] = "88817521039352",
				["Viltrumite Animation"] = "120193221019191",
				["Super Saiyan Goku DBZ"] = "128955435997920",
				["Anime Ninja"] = "81390797808921",
				["Bycyclist"] = "110684787086498",
				["Spyder Hero Animation"] = "98539846382858",
				["Spantom NEO / Possessed"] = "133987955520718",
				["Enchanted Fairy Animation"] = "100947971756348",
				["R6 Energy"] = "97816824721166",
				["Chill Sans Animation"] = "93162668307847",
				["Dizzy Animation Pack"] = "138967706335414",
				["Springy Animation Pack"] = "97093456206868",
				["Undead Animation Pack"] = "126046952017221",
				["Joy Animation Pack"] = "132095139090357",
				["Average Stand User"] = "128463375681708",
				["Goofball Animation Pack"] = "133855117712851",
				["Military Animation Pack"] = "128770242110666",
				["Cartoony Scared Animation"] = "112622015483553",
				["Skater Animation Pack"] = "74577850128919",
				["Billie Ellish"] = "81072141180299",
				["Katseye"] = "127802717128367",
				["Glow Motion	"] = "98070939608691",
				["Adidas Aura"] = "95603166884636",
				["Robot"] = "616087089",
				["Patrol"] = "1148863382",
				["Adidas Community"] = "98600215928904",
				["Levitation"] = "616005863",
				["Catwalk Glam"] = "92294537340807",
				["Knight"] = "10921122579",
				["Pirate"] = "750780242",
				["Bold"] = "16738333171",
				["Sports (Adidas)"] = "18537367238",
				["Zombie"] = "616157476",
				["Astronaut"] = "891617961",
				["Cartoony"] = "742637151",
				["Ninja"] = "656115606",
				["Confident"] = "1069973677",
				["Wicked \"Dancing Through Life\""] = "78147885297412",
				["Unboxed By Amazon"] = "94788218468396",
				["R6"] = "12520972571",
				["[UGC] skydiving"] = "102674302534126",
				["R15 Reanimated"] = "4211216152",
				["Rthro"] = "10921262864",
				["No Boundaries (Walmart)"] = "18747062535",
				["Werewolf"] = "1083189019",
				["[VOTE] TPose"] = "139027266704971",
				["Mage"] = "707829716",
				["[VOTE] Animal"] = "77069224396280",
				["Wicked (Popular)"] = "121152442762481",
				["Popstar"] = "1212900995",
				["NFL"] = "129773241321032",
				["OldSchool"] = "10921241244",
				["Sneaky"] = "1132469004",
				["Elder"] = "10921105765",
				["Bubbly"] = "910001910",
				["Stylish"] = "616134815",
				["Stylized Female"] = "4708186162",
				["Vampire"] = "1083443587",
				["Superhero"] = "10921293373",
				["Toy"] = "782846423",
				["Default Retarget"] = "110205622518029",
				["Princess"] = "941000007",
				["Cowboy"] = "1014384571"
			},
			["SwimIdle"] = {
				["Effortless Aura"] = "81300782326314",
				["Pixel Animation"] = "94158089787378",
				["Zombie New"] = "110009455126489",
				["Thief Animation"] = "121910338002771",
				["Macho Man"] = "131977318163408",
				["Handstand"] = "116729337549524",
				["Animal 1"] = "83674681023731",
				["Diva Animation"] = "110805432217543",
				["Sashy Animation"] = "122160900085928",
				["Boxer Animation"] = "139780452405763",
				["Endless Aura"] = "98233901195014",
				["Aura Animation Pack"] = "122428596382805",
				["Goofy Animation"] = "126526415537624",
				["Furry Animation"] = "82429732905677",
				["Superhero 2 Animation"] = "77233341714077",
				["Springy Animation"] = "119848788778683",
				["Nonchalant Animation"] = "84514602075159",
				["Spyder Animation"] = "112797027322908",
				["Tall Animation"] = "80607193603720",
				["FIFA Football Animation"] = "126374248226168", -- Diubah dari SwimIdle menjadi SwimIdleAnim agar konsisten
				["Doll Animation"] = "102295671153666",
				["Flipped Animation"] = "132599495056073",
				["Source Animation"] = "125630712519130",
				["Deltarune Roaring Knight"] = "90343462890601",
				["Hatsune Miku VOCALOID"] = "102315774941466",
				["Mimic Animation"] = "72278717298066",
				["Girl Animation"] = "110136283989000",
				["Crawl Animation"] = "74473525991473",
				["Springtap Animation"] = "117284454364209",
				["Skipping Animation"] = "99339395597471",
				["Deltarune Lightner"] = "134874787954669",
				["Fighter Animation"] = "105708355740396",
				["CAT Animation"] = "95184993554421",
				["Kawaii Girl"] = "88806403184108",
				["Backward Animation"] = "119843816272151",
				["Cool Boy Animation"] = "104944026664963",
				["Scared Animation"] = "138097548494858",
				["Rolling Animation Pack"] = "112237056566091",
				["Sprinter Animation"] = "93318613232641",
				["64 Dude Pack"] = "112290070370553",
				["Flamboyant Animation"] = "98014296366197",
				["Deltarune Flowery"] = "117768865291440",
				["Fort Builder Animation"] = "96108655488529",
				["Dog Animation"] = "98153475504778",
				["Flying Animation Pack"] = "92868601296385",
				["Scaredy Animation Pack"] = "130638932312502",
				["Anime Idol Animation"] = "104522256032445",
				["Ring Runner Animation"] = "110044869435847",
				["Glitch Animation"] = "124314548544388",
				["Viltrumite Animation"] = "98558468196290",
				["Super Saiyan Goku DBZ"] = "107604957235630",
				["Anime Ninja"] = "101575330561679",
				["Bycyclist"] = "87621024705272",
				["Spyder Hero Animation"] = "134596146214715",
				["Spantom NEO / Possessed"] = "75508377918010",
				["Enchanted Fairy Animation"] = "76251363220411",
				["R6 Energy"] = "104277155139523",
				["Chill Sans Animation"] = "74218635888481",
				["Dizzy Animation Pack"] = "106771870638345",
				["Springy Animation Pack"] = "119848788778683",
				["Undead Animation Pack"] = "100158041286882",
				["Joy Animation Pack"] = "99097308388511",
				["Average Stand User"] = "97683234617563",
				["Goofball Animation Pack"] = "119316088851325",
				["Military Animation Pack"] = "94947677525036",
				["Cartoony Scared Animation"] = "133042131084842",
				["Skater Animation Pack"] = "124958165704948",
				["Billie Ellish"] = "78535650384589",
				["Katseye"] = "138619485942849",
				["Glow Motion	"] = "112946194103503",
				["Adidas Aura"] = "94922130551805",
				["Sneaky"] = "1132506407",
				["SuperHero"] = "10921297391",
				["Adidas Community"] = "109346520324160",
				["Levitation"] = "10921139478",
				["Catwalk Glam"] = "98854111361360",
				["Knight"] = "10921125935",
				["Pirate"] = "750785176",
				["Bold"] = "16738339817",
				["Sports (Adidas)"] = "18537387180",
				["Stylized"] = "4708190607",
				["Astronaut"] = "891663592",
				["Cartoony"] = "10921079380",
				["Wicked (Popular)"] = "113199415118199",
				["Mage"] = "707894699",
				["Wicked \"Dancing Through Life\""] = "129183123083281",
				["Unboxed By Amazon"] = "129126268464847",
				["R6"] = "12518152696",
				["Rthro"] = "10921265698",
				["CowBoy"] = "1014411816",
				["No Boundaries (Walmart)"] = "18747071682",
				["Werewolf"] = "10921341319",
				["NFL"] = "79090109939093",
				["OldSchool"] = "10921244018",
				["Robot"] = "10921253767",
				["Elder"] = "10921110146",
				["Bubbly"] = "910030921",
				["Patrol"] = "1151221899",
				["Vampire"] = "10921325443",
				["Popstar"] = "1212998578",
				["Ninja"] = "656118341",
				["Toy"] = "10921310341",
				["Confident"] = "1070012133",
				["Princess"] = "941025398",
				["Stylish"] = "10921281964"
			},	
			["Swim"] = {
				["Effortless Aura"] = "117171954618884",
				["Pixel Animation"] = "88366029713748",
				["Zombie New"] = "128306388995312",
				["Thief Animation"] = "89683009725103",
				["Macho Man"] = "127168420900272",
				["Handstand"] = "130414392214126",
				["Animal 1"] = "81203142958025",
				["Diva Animation"] = "71670155016522",
				["Sashy Animation"] = "118654001883068",
				["Boxer Animation"] = "108716879605474",
				["Endless Aura"] = "98062782127543",
				["Aura Animation Pack"] = "89953069685667",
				["Goofy Animation"] = "126596960206946",
				["Furry Animation"] = "99909547692332",
				["Superhero 2 Animation"] = "117805798207407",
				["Springy Animation"] = "96755605239227",
				["Nonchalant Animation"] = "132629439283196",
				["Spyder Animation"] = "83601876689057",
				["Tall Animation"] = "111520973763635",
				["FIFA Football Animation"] = "108081720993195", -- Diubah dari Swim menjadi SwimAnim agar konsisten
				["Doll Animation"] = "72286334897096",
				["Flipped Animation"] = "84282224936615",
				["Source Animation"] = "138896282229034",
				["Deltarune Roaring Knight"] = "85951145485283",
				["Hatsune Miku VOCALOID"] = "79045686879709",
				["Mimic Animation"] = "70830316239539",
				["Girl Animation"] = "71193765485393",
				["Crawl Animation"] = "99020550039537",
				["Springtap Animation"] = "118014563991506",
				["Skipping Animation"] = "125814609315053",
				["Deltarune Lightner"] = "74706907022678",
				["Fighter Animation"] = "104181483125675",
				["CAT Animation"] = "121630691341699",
				["Kawaii Girl"] = "132695170830847",
				["Backward Animation"] = "84648855827251",
				["Cool Boy Animation"] = "106184241701131",
				["Scared Animation"] = "134768801755881",
				["Rolling Animation Pack"] = "134710769875456",
				["Sprinter Animation"] = "72288972627238",
				["64 Dude Pack"] = "117383461146849",
				["Flamboyant Animation"] = "101558383641133",
				["Deltarune Flowery"] = "71319238496163",
				["Fort Builder Animation"] = "72542963858544",
				["Dog Animation"] = "132221845122396",
				["Flying Animation Pack"] = "81879314799078",
				["Scaredy Animation Pack"] = "76324807912230",
				["Anime Idol Animation"] = "122465610433758",
				["Ring Runner Animation"] = "90222175555090",
				["Glitch Animation"] = "70788156947773",
				["Viltrumite Animation"] = "89726849381725",
				["Super Saiyan Goku DBZ"] = "78050054964903",
				["Anime Ninja"] = "79334351265355",
				["Bycyclist"] = "116700888013068",
				["Spyder Hero Animation"] = "84071038652577",
				["Spantom NEO / Possessed"] = "80942709056195",
				["Enchanted Fairy Animation"] = "86081248001349",
				["R6 Energy"] = "95646894571032",
				["Chill Sans Animation"] = "75292875299669",
				["Dizzy Animation Pack"] = "120870384477970",
				["Springy Animation Pack"] = "96755605239227",
				["Undead Animation Pack"] = "118047872378239",
				["Joy Animation Pack"] = "130449455445013",
				["Average Stand User"] = "120109773672647",
				["Goofball Animation Pack"] = "129792208676361",
				["Military Animation Pack"] = "101144554567851",
				["Cartoony Scared Animation"] = "108211027123133",
				["Skater Animation Pack"] = "84327447783021",
				["Billie Ellish"] = "121824746242877",
				["Glow Motion	"] = "83003487432457",
				["Adidas Aura"] = "134530128383903",
				["Sneaky"] = "1132500520",
				["Patrol"] = "1151204998",
				["Adidas Community"] = "133308483266208",
				["Levitation"] = "10921138209",
				["Catwalk Glam"] = "134591743181628",
				["Knight"] = "10921125160",
				["Pirate"] = "750784579",
				["Bold"] = "16738339158",
				["Sports (Adidas)"] = "18537389531",
				["Zombie"] = "616165109",
				["Astronaut"] = "891663592",
				["Cartoony"] = "10921079380",
				["Wicked (Popular)"] = "99384245425157",
				["Mage"] = "707876443",
				["PopStar"] = "1212998578",
				["Unboxed By Amazon"] = "105962919001086",
				["R6"] = "12518152696",
				["[VOTE] Boat"] = "85689117221382",
				["Rthro"] = "10921264784",
				["CowBoy"] = "1014406523",
				["No Boundaries (Walmart)"] = "18747073181",
				["Werewolf"] = "10921340419",
				["NFL"] = "132697394189921",
				["OldSchool"] = "10921243048",
				["Wicked \"Dancing Through Life\""] = "110657013921774",
				["Elder"] = "10921108971",
				["Bubbly"] = "910028158",
				["Robot"] = "10921253142",
				["[VOTE] Aura"] = "80645586378736",
				["Vampire"] = "10921324408",
				["Stylish"] = "10921281000",
				["Toy"] = "10921309319",
				["SuperHero"] = "10921295495",
				["Princess"] = "941018893",
				["Confident"] = "1070009914"
			},
			["Climb"] = {
				["Effortless Aura"] = "71035701144022",
				["Pixel Animation"] = "95918841204099",
				["Zombie New"] = "88141282105123",
				["Thief Animation"] = "92740123805321",
				["Macho Man"] = "78970248553045",
				["Handstand"] = "71656254569935",
				["Animal 1"] = "75085836535654",
				["Diva Animation"] = "82648420312191",
				["Sashy Animation"] = "140473714536897",
				["Boxer Animation"] = "137457094552376",
				["Endless Aura"] = "78662570655863",
				["Aura Animation Pack"] = "111484939727375",
				["Goofy Animation"] = "129770628615500",
				["Furry Animation"] = "76660530164497",
				["Superhero 2 Animation"] = "111005757834850",
				["Springy Animation"] = "126871763160364",
				["Nonchalant Animation"] = "80469823264981",
				["Spyder Animation"] = "119278342251995",
				["Tall Animation"] = "136864827926480",
				["FIFA Football Animation"] = "76308547227345",
				["Doll Animation"] = "133036321350493",
				["Flipped Animation"] = "123377530718827",
				["Source Animation"] = "113206640558817",
				["Deltarune Roaring Knight"] = "130838770836801",
				["Hatsune Miku VOCALOID"] = "134498720833612",
				["Mimic Animation"] = "123003008386212",
				["Girl Animation"] = "89680810623277",
				["Crawl Animation"] = "116517328871164",
				["Springtap Animation"] = "107011358286483",
				["Skipping Animation"] = "77194920086366",
				["Deltarune Lightner"] = "128302833093896",
				["Fighter Animation"] = "116941684773601",
				["CAT Animation"] = "108766758553438",
				["Kawaii Girl"] = "80930364087694",
				["Backward Animation"] = "104129492613301",
				["Cool Boy Animation"] = "76876652470272",
				["Scared Animation"] = "86055922141659",
				["Rolling Animation Pack"] = "135793463019488",
				["Sprinter Animation"] = "106811773988912",
				["64 Dude Pack"] = "126244015418784",
				["Flamboyant Animation"] = "71052974757321",
				["Deltarune Flowery"] = "137438601334170",
				["Fort Builder Animation"] = "117247405024609",
				["Dog Animation"] = "102432224680747",
				["Flying Animation Pack"] = "111869743592051",
				["Scaredy Animation Pack"] = "94321502394594",
				["Anime Idol Animation"] = "118835852098962",
				["Ring Runner Animation"] = "122695668611357",
				["Glitch Animation"] = "99974229390885",
				["Viltrumite Animation"] = "116738664195186",
				["Super Saiyan Goku DBZ"] = "93034375616821",
				["Anime Ninja"] = "134405384832108",
				["Bycyclist"] = "88267082364595",
				["Spyder Hero Animation"] = "107399238368839",
				["Spantom NEO / Possessed"] = "121649548877615",
				["Enchanted Fairy Animation"] = "140663406485180",
				["R6 Energy"] = "91619266991895",
				["Chill Sans Animation"] = "82737482702137",
				["Dizzy Animation Pack"] = "93550710314258",
				["Springy Animation Pack"] = "126871763160364",
				["Undead Animation Pack"] = "90717850151516",
				["Joy Animation Pack"] = "110061716873830",
				["Average Stand User"] = "81711030643960",
				["Goofball Animation Pack"] = "74300477238670",
				["Military Animation Pack"] = "78206334686341",
				["Cartoony Scared Animation"] = "80797877336654",
				["Skater Animation Pack"] = "71627831922485",
				["Billie Ellish"] = "117873469361430",
				["Katseye"] = "106213237973858",
				["Glow Motion	"] = "108236155509584",
				["Adidas Aura"] = "97824616490448",
				["Robot"] = "616086039",
				["Patrol"] = "1148811837",
				["Adidas Community"] = "88763136693023",
				["Levitation"] = "10921132092",
				["Catwalk Glam"] = "119377220967554",
				["Knight"] = "10921125160",
				["[VOTE] Animal"] = "124810859712282",
				["Bold"] = "16738332169",
				["Sports (Adidas)"] = "18537363391",
				["Zombie"] = "616156119",
				["Astronaut"] = "10921032124",
				["Cartoony"] = "742636889",
				["Ninja"] = "656114359",
				["Confident"] = "1069946257",
				["Wicked \"Dancing Through Life\""] = "129447497744818",
				["Unboxed By Amazon"] = "121145883950231",
				["R6"] = "12520982150",
				["Ghost"] = "616003713",
				["Rthro"] = "10921257536",
				["CowBoy"] = "1014380606",
				["No Boundaries (Walmart)"] = "18747060903",
				["Mage"] = "707826056",
				["[VOTE] sticky"] = "77520617871799",
				["Reanimated R15"] = "4211214992",
				["Popstar"] = "1213044953",
				["(UGC) Retro"] = "121075390792786",
				["NFL"] = "134630013742019",
				["OldSchool"] = "10921229866",
				["Sneaky"] = "1132461372",
				["Elder"] = "845392038",
				["Stylized Female"] = "4708184253",
				["Stylish"] = "10921271391",
				["SuperHero"] = "10921286911",
				["WereWolf"] = "10921329322",
				["Vampire"] = "1083439238",
				["Toy"] = "10921300839",
				["Wicked (Popular)"] = "131326830509784",
				["Princess"] = "940996062",
				["[VOTE] Rope"] = "134977367563514"
			}
		}

--- --- 🔹 FUNGSI APPLY UNIVERSAL + SET ANIMASI 🔹 --- ---

-- Urutan kategori yang dipakai oleh dropdown biasa dan Set Animasi.
local CategoryOrder = {"Idle", "Walk", "Run", "Jump", "Fall", "Climb", "SwimIdle", "Swim"}

-- Referensi tombol kategori agar teksnya ikut berubah saat sebuah set diterapkan.
local AnimationCategoryToggles = {}
local AnimationSetToggle = nil

-- Snapshot animasi yang dipakai karakter sebelum Dvisual menggantinya.
-- Snapshot ini hanya diambil satu kali, tepat sebelum perubahan animasi pertama.
local PreviousAnimations = {}
local HasCapturedPreviousAnimations = false

-- Nama child Animation tidak wajib sama pada semua versi Animate,
-- tetapi nama-nama ini mengikuti struktur Animate Roblox yang umum.
local AnimationObjectNames = {
    Idle = "Animation1",
    Walk = "WalkAnim",
    Run = "RunAnim",
    Jump = "JumpAnim",
    Fall = "FallAnim",
    Climb = "ClimbAnim",
    SwimIdle = "SwimIdle",
    Swim = "Swim"
}

local function GetAnimationFolderName(category)
    return category == "Idle" and "idle" or category:lower()
end

local function CopyAnimationValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copied = {}
    for index, item in ipairs(value) do
        copied[index] = item
    end
    return copied
end

local function CopyAnimationMap(source)
    local copied = {}
    for _, category in ipairs(CategoryOrder) do
        if source[category] ~= nil then
            copied[category] = CopyAnimationValue(source[category])
        end
    end
    return copied
end

local function ExtractAnimationId(animationId)
    local value = tostring(animationId or "")
    return value:match("(%d+)")
end

local function ReadAnimationCategory(animateScript, category)
    local folder = animateScript:FindFirstChild(GetAnimationFolderName(category))
    if not folder then
        return nil
    end

    local preferredName = AnimationObjectNames[category] or "Animation1"
    local entries = {}

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Animation") then
            local id = ExtractAnimationId(child.AnimationId)
            if id then
                table.insert(entries, {
                    Id = id,
                    Name = child.Name
                })
            end
        end
    end

    table.sort(entries, function(a, b)
        local function GetRank(entry)
            if entry.Name == preferredName then
                return 1
            end

            local number = tonumber(entry.Name:match("^Animation(%d+)$"))
            if number then
                return number
            end

            return 999
        end

        local rankA = GetRank(a)
        local rankB = GetRank(b)

        if rankA ~= rankB then
            return rankA < rankB
        end

        return a.Name < b.Name
    end)

    if #entries == 0 then
        return nil
    end

    if #entries == 1 then
        return entries[1].Id
    end

    local ids = {}
    for index, entry in ipairs(entries) do
        ids[index] = entry.Id
    end
    return ids
end

local function CapturePreviousAnimations(animateScript)
    if HasCapturedPreviousAnimations or not animateScript then
        return HasCapturedPreviousAnimations
    end

    local capturedCount = 0
    local snapshot = {}

    for _, category in ipairs(CategoryOrder) do
        local data = ReadAnimationCategory(animateScript, category)
        if data ~= nil then
            snapshot[category] = data
            capturedCount = capturedCount + 1
        end
    end

    if capturedCount > 0 then
        PreviousAnimations = snapshot
        HasCapturedPreviousAnimations = true
        return true
    end

    return false
end

local function ConfigureAnimationCategory(animateClone, category, data)
    local folderName = GetAnimationFolderName(category)
    local targetFolder = animateClone:FindFirstChild(folderName)

    if not targetFolder or data == nil then
        return false
    end

    targetFolder:ClearAllChildren()

    local firstAnimationName = AnimationObjectNames[category] or "Animation1"

    local function CreateEntry(id, name)
        if id == nil then return end

        local animation = Instance.new("Animation")
        animation.Name = name
        animation.AnimationId = "rbxassetid://" .. tostring(id)
        animation.Parent = targetFolder

        -- Dipertahankan agar kompatibel dengan struktur script sebelumnya.
        local value = Instance.new("StringValue")
        value.Name = name
        value.Value = tostring(id)
        value.Parent = targetFolder
    end

    if type(data) == "table" then
        for index, id in ipairs(data) do
            local entryName = index == 1 and firstAnimationName or ("Animation" .. index)
            CreateEntry(id, entryName)
        end
    else
        CreateEntry(data, firstAnimationName)
    end

    if category == "Idle" then
        local firstIdle = targetFolder:FindFirstChild(firstAnimationName)
        if firstIdle and firstIdle:IsA("Animation") then
            local weight1 = Instance.new("NumberValue")
            weight1.Name = "Weight"
            weight1.Value = 9
            weight1.Parent = firstIdle
        end

        local secondIdle = targetFolder:FindFirstChild("Animation2")
        if secondIdle and secondIdle:IsA("Animation") then
            local weight2 = Instance.new("NumberValue")
            weight2.Name = "Weight"
            weight2.Value = 1
            weight2.Parent = secondIdle
        end
    end

    return true
end

-- Memasang satu atau banyak kategori hanya dengan satu kali clone/refresh Animate.
-- Ini lebih stabil daripada menghancurkan Animate delapan kali secara berurutan.
local function ApplyAnimationBatch(animationMap)
    local char = player.Character
    local animate = char and char:FindFirstChild("Animate")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if not animate or not humanoid then
        ShowNotification("Character or Animate is not ready.")
        return false
    end

    -- Simpan animasi awal sebelum perubahan pertama dilakukan.
    CapturePreviousAnimations(animate)

    local animateClone = animate:Clone()
    local appliedCount = 0

    for _, category in ipairs(CategoryOrder) do
        local data = animationMap[category]
        if data ~= nil and ConfigureAnimationCategory(animateClone, category, data) then
            SavedAnimations[category] = data
            appliedCount = appliedCount + 1
        end
    end

    if appliedCount == 0 then
        animateClone:Destroy()
        return false
    end

    animate:Destroy()

    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end

    animateClone.Parent = char

    -- Memaksa Animate membaca konfigurasi baru.
    humanoid:ChangeState(Enum.HumanoidStateType.Landing)
    local oldWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0
    task.wait(0.05)
    humanoid.WalkSpeed = oldWalkSpeed

    return true, appliedCount
end

local function ApplyInstantAnimation(category, data)
    return ApplyAnimationBatch({[category] = data})
end

-- Normalisasi nama membuat "SuperHero" dan "Superhero" dianggap set yang sama,
-- serta mengabaikan spasi/tab yang tidak sengaja ada di AnimationData.
local function NormalizeAnimationSetName(name)
    return tostring(name)
        :lower()
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end

-- Membentuk SEMUA set secara otomatis langsung dari AnimationData.
-- Set tidak wajib lengkap. Jika sebuah kategori tidak tersedia, kategori itu
-- tidak akan diubah ketika set dipilih dan tetap memakai animasi sebelumnya.
local function BuildAllAnimationSets()
    local indexedSets = {}

    for _, category in ipairs(CategoryOrder) do
        for realName, animationData in pairs(AnimationData[category] or {}) do
            local normalizedName = NormalizeAnimationSetName(realName)
            local setInfo = indexedSets[normalizedName]

            if not setInfo then
                setInfo = {
                    Name = tostring(realName):match("^%s*(.-)%s*$"),
                    Animations = {},
                    SourceNames = {},
                    CategoryCount = 0,
                    AvailableCategories = {}
                }
                indexedSets[normalizedName] = setInfo
            end

            -- Hindari penambahan hitungan dua kali jika ada nama duplikat
            -- pada kategori yang sama.
            if setInfo.Animations[category] == nil then
                setInfo.CategoryCount = setInfo.CategoryCount + 1
                table.insert(setInfo.AvailableCategories, category)
            end

            setInfo.Animations[category] = animationData
            setInfo.SourceNames[category] = realName
        end
    end

    local allSets = {}

    for _, setInfo in pairs(indexedSets) do
        table.sort(setInfo.AvailableCategories, function(a, b)
            local ai = table.find(CategoryOrder, a) or 999
            local bi = table.find(CategoryOrder, b) or 999
            return ai < bi
        end)
        table.insert(allSets, setInfo)
    end

    table.sort(allSets, function(a, b)
        -- Set lengkap ditaruh lebih dahulu, lalu diurutkan berdasarkan nama.
        if a.CategoryCount ~= b.CategoryCount then
            return a.CategoryCount > b.CategoryCount
        end
        return a.Name:lower() < b.Name:lower()
    end)

    return allSets
end

local function ApplyAnimationSet(setInfo)
    if not setInfo or not setInfo.Animations then
        ShowNotification("Animation set is invalid.")
        return
    end

    local success, appliedCount = ApplyAnimationBatch(setInfo.Animations)

    if success then
        for _, category in ipairs(CategoryOrder) do
            -- Hanya perbarui kategori yang benar-benar tersedia pada set.
            -- Kategori yang tidak ada tetap memakai pilihan sebelumnya.
            if setInfo.Animations[category] ~= nil then
                local toggle = AnimationCategoryToggles[category]
                if toggle then
                    local sourceName = setInfo.SourceNames[category] or setInfo.Name
                    toggle.Text = sourceName .. " ▼"
                end
            end
        end

        ShowNotification(setInfo.Name .. " set applied (" .. tostring(appliedCount) .. "/8 available)!")
    else
        ShowNotification("Failed to apply animation set.")
    end
end

local function ResetToPreviousAnimations()
    local char = player.Character
    local animate = char and char:FindFirstChild("Animate")

    -- Jika belum pernah mengganti animasi, ambil kondisi yang sedang dipakai sekarang.
    if not HasCapturedPreviousAnimations and animate then
        CapturePreviousAnimations(animate)
    end

    if not HasCapturedPreviousAnimations or next(PreviousAnimations) == nil then
        ShowNotification("Previous animations were not found.")
        return
    end

    -- Hapus pilihan custom lama terlebih dahulu agar kategori yang tersimpan
    -- benar-benar kembali ke snapshot sebelum Dvisual melakukan perubahan.
    for _, category in ipairs(CategoryOrder) do
        SavedAnimations[category] = nil
    end

    local success, restoredCount = ApplyAnimationBatch(CopyAnimationMap(PreviousAnimations))

    if success then
        if AnimationSetToggle then
            AnimationSetToggle.Text = "Previous Animations Restored ▼"
        end

        for _, category in ipairs(CategoryOrder) do
            local toggle = AnimationCategoryToggles[category]
            if toggle then
                if PreviousAnimations[category] ~= nil then
                    toggle.Text = "Previous " .. category .. " ▼"
                else
                    toggle.Text = "Select " .. category .. " ▼"
                end
            end
        end

        ShowNotification("Previous animations restored (" .. tostring(restoredCount) .. "/8)!")
    else
        ShowNotification("Failed to restore previous animations.")
    end
end

-- Baris dropdown SET ANIMASI. Semua paket, termasuk yang tidak lengkap, diambil otomatis dari AnimationData.
local function CreateAnimationSetCategory(order)
    local animationSets = BuildAllAnimationSets()

    local rowFrame = Instance.new("Frame")
    rowFrame.Name = "AnimationSetRow"
    rowFrame.Size = UDim2.new(1, 0, 0, 30)
    rowFrame.BackgroundTransparency = 1
    rowFrame.LayoutOrder = order
    rowFrame.Parent = animTabContent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.3, 0, 0, 30)
    label.Text = "SET ANIMASI"
    label.TextColor3 = Color3.fromRGB(120, 190, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = rowFrame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.65, 0, 0, 24)
    toggle.Position = UDim2.new(0.35, 0, 0, 3)
    toggle.BackgroundColor3 = Color3.fromRGB(55, 80, 130)
    toggle.Text = "Select Animation Set (" .. tostring(#animationSets) .. ") ▼"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamSemibold
    toggle.TextSize = 9
    toggle.Parent = rowFrame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 5)
    AnimationSetToggle = toggle

    local search = Instance.new("TextBox")
    search.Size = UDim2.new(0.65, 0, 0, 22)
    search.Position = UDim2.new(0.35, 0, 0, 32)
    search.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    search.PlaceholderText = "🔍 Search all animation sets..."
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

    local function CloseDropdown()
        search.Visible = false
        TweenService:Create(scroll, TweenInfo.new(0.2), {
            Size = UDim2.new(0.65, 0, 0, 0)
        }):Play()
        TweenService:Create(rowFrame, TweenInfo.new(0.2), {
            Size = UDim2.new(1, 0, 0, 30)
        }):Play()
        task.wait(0.2)
        scroll.Visible = false
    end

    toggle.MouseButton1Click:Connect(function()
        if scroll.Visible then
            CloseDropdown()
        else
            scroll.Visible = true
            search.Visible = true
            TweenService:Create(rowFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 0, 160)
            }):Play()
            TweenService:Create(scroll, TweenInfo.new(0.3), {
                Size = UDim2.new(0.65, 0, 0, 100)
            }):Play()
        end
    end)

    for _, setInfo in ipairs(animationSets) do
        local button = Instance.new("TextButton")
        button.Name = NormalizeAnimationSetName(setInfo.Name)
        button.Size = UDim2.new(0.92, 0, 0, 20)
        button.BackgroundTransparency = 0.92
        button.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
        button.Text = "  " .. setInfo.Name .. "  • " .. tostring(setInfo.CategoryCount) .. "/8"
        button.TextColor3 = Color3.fromRGB(230, 240, 255)
        button.Font = Enum.Font.Gotham
        button.TextSize = 9
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = scroll
        button:SetAttribute("AvailableCount", setInfo.CategoryCount)
        button:SetAttribute("AvailableCategories", table.concat(setInfo.AvailableCategories, ", "))
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

        button.MouseButton1Click:Connect(function()
            toggle.Text = setInfo.Name .. " • " .. tostring(setInfo.CategoryCount) .. "/8 ▼"
            CloseDropdown()
            ApplyAnimationSet(setInfo)
        end)
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = NormalizeAnimationSetName(search.Text)

        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child.Visible = searchText == "" or string.find(child.Name, searchText, 1, true) ~= nil
            end
        end
    end)

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
end

-- Set Animasi selalu berada paling atas.
CreateAnimationSetCategory(0)

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
    AnimationCategoryToggles[categoryName] = toggle

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
    ResetToPreviousAnimations()
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

-- --- 🔹 ISI TAB MOVEMENT 🔹 ---
-- Semua state movement disimpan dalam satu tempat agar Reset Movement,
-- Fly, dan respawn tidak saling menimpa.
local StopFlying
local SetAvaLight
local ApplyAvaLightToCharacter
local CleanupMovementFeatures
local ResetMovement

local MovementControls = {}

-- Pusatkan seluruh elemen tab Movement. Elemen tetap memakai lebar penuh
-- dengan sedikit margin sehingga tidak masuk ke area sidebar.
local movementLayout = movementTabFrame and movementTabFrame:FindFirstChildOfClass("UIListLayout")
if movementLayout then
    movementLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    movementLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    movementLayout.Padding = UDim.new(0, 8)
end

local MovementDefaults = {
    Captured = false,
    WalkSpeed = 16,
    UseJumpPower = true,
    JumpPower = 50,
    JumpHeight = 7.2,
    FlySpeed = FlySpeed
}

local function CaptureMovementDefaults(character, force)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum then
        return false
    end

    if force or not MovementDefaults.Captured then
        MovementDefaults.WalkSpeed = hum.WalkSpeed
        MovementDefaults.UseJumpPower = hum.UseJumpPower
        MovementDefaults.JumpPower = hum.JumpPower
        MovementDefaults.JumpHeight = hum.JumpHeight

        -- FlySpeed bukan properti Humanoid, jadi baseline-nya cukup disimpan sekali.
        if not MovementDefaults.Captured then
            MovementDefaults.FlySpeed = FlySpeed
        end

        MovementDefaults.Captured = true
    end

    return true
end

CaptureMovementDefaults(player.Character, true)

local function UpdateMovementControl(controlName, value)
    local control = MovementControls[controlName]
    if not control then return end

    control.Input.Text = tostring(value)
    control.Label.Text = control.DisplayName .. " [" .. tostring(value) .. "]"
end

local function CreateMovementSetting(name, minValue, maxValue, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Parent = movementTabFrame
    container.Size = UDim2.new(1, -8, 0, 50)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = container
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = name .. " [" .. tostring(defaultValue) .. "]"
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
    input.Text = tostring(defaultValue)
    input.TextColor3 = Color3.fromRGB(0, 255, 0)
    input.Font = Enum.Font.GothamBold
    input.PlaceholderText = "Input angka..."
    input.ClearTextOnFocus = false
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local control = {
        DisplayName = name,
        Label = label,
        Input = input,
        Min = minValue,
        Max = maxValue,
        Default = defaultValue
    }
    MovementControls[name] = control

    input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if not value then
            input.Text = tostring(control.Default)
            label.Text = name .. " [" .. tostring(control.Default) .. "]"
            ShowNotification(name .. " harus berupa angka")
            return
        end

        value = math.clamp(value, minValue, maxValue)
        control.Default = value
        UpdateMovementControl(name, value)
        callback(value)
    end)

    return control
end

local initialWalkSpeed = MovementDefaults.WalkSpeed
local initialJumpPower = MovementDefaults.JumpPower
local initialFlySpeed = MovementDefaults.FlySpeed

CreateMovementSetting("Walk Speed", 0, 500, initialWalkSpeed, function(value)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = value
    end
end)

CreateMovementSetting("Jump Power", 0, 500, initialJumpPower, function(value)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = value
    end
end)

CreateMovementSetting("Fly Speed", 0, 1000, initialFlySpeed, function(value)
    FlySpeed = value
    _G.FlySpeed = value
    ShowNotification("Fly Speed: " .. tostring(value))
end)

if movementTabFrame then
    AddScriptButton("Reset Movement", function()
        if ResetMovement then
            ResetMovement()
        end
    end, movementTabFrame)
end


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
closeBtn.MouseButton1Click:Connect(function()
    if CleanupMovementFeatures then
        CleanupMovementFeatures()
    end
    if StopLicenseHeartbeat then
        StopLicenseHeartbeat()
    end
    gui:Destroy()
end)

-- ============================================================
-- DVISUAL - FLY BODY DIRECTION FIX
-- Ganti seluruh blok Fly pada script terbaru dengan blok ini.
-- Mulai dari komentar "FLY SYSTEM" sampai sebelum blok AVA LIGHT.
-- ============================================================

local flyBtn = nil

local function UpdateFlyButton()
    if not flyBtn or not flyBtn.Parent then
        return
    end

    flyBtn.Text = Flying and "Fly: ON" or "Fly: OFF"
    flyBtn.BackgroundColor3 = Flying
        and Color3.fromRGB(60, 180, 100)
        or Color3.fromRGB(150, 60, 255)
end

-- Menghapus semua sisa pengontrol Fly yang mungkin tertinggal.
local function RemoveFlyPhysics(root)
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyHumanoidDiedConnection then
        FlyHumanoidDiedConnection:Disconnect()
        FlyHumanoidDiedConnection = nil
    end

    if BodyGyro then
        BodyGyro:Destroy()
        BodyGyro = nil
    end

    if BodyVelocity then
        BodyVelocity:Destroy()
        BodyVelocity = nil
    end

    -- Membersihkan object lama jika script sebelumnya pernah membuat duplikat.
    if root then
        local oldGyro = root:FindFirstChild("DvisualFlyGyro")
        if oldGyro then
            oldGyro:Destroy()
        end

        local oldVelocity = root:FindFirstChild("DvisualFlyVelocity")
        if oldVelocity then
            oldVelocity:Destroy()
        end
    end
end

-- Mengembalikan arah badan dan kontrol Humanoid setelah Fly dimatikan.
local function RestoreBodyControl(character)
    local char = character or player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not hum or hum.Health <= 0 then
        return
    end

    -- Hapus momentum dan putaran dari BodyGyro/BodyVelocity.
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        -- Tegakkan badan dan arahkan secara horizontal mengikuti kamera.
        local camera = workspace.CurrentCamera
        local lookVector = camera and camera.CFrame.LookVector or root.CFrame.LookVector
        local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)

        if flatLook.Magnitude > 0.001 then
            root.CFrame = CFrame.lookAt(
                root.Position,
                root.Position + flatLook.Unit,
                Vector3.yAxis
            )
        else
            local currentLook = root.CFrame.LookVector
            local flatCurrentLook = Vector3.new(currentLook.X, 0, currentLook.Z)

            if flatCurrentLook.Magnitude > 0.001 then
                root.CFrame = CFrame.lookAt(
                    root.Position,
                    root.Position + flatCurrentLook.Unit,
                    Vector3.yAxis
                )
            end
        end
    end

    -- Paksa kontrol karakter kembali normal.
    hum.PlatformStand = false
    hum.Sit = false
    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)

    -- Beberapa game mengubah state kembali satu frame setelah BodyMover dihapus.
    -- Karena itu pemulihan dilakukan sekali lagi setelah physics update.
    task.spawn(function()
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()

        if hum.Parent and hum.Health > 0 then
            hum.PlatformStand = false
            hum.Sit = false
            hum.AutoRotate = true
            hum:ChangeState(Enum.HumanoidStateType.Running)

            if root and root.Parent then
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end

StopFlying = function(silent)
    Flying = false

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    RemoveFlyPhysics(root)
    RestoreBodyControl(char)

    PreviousFlyHumanoidState = nil
    UpdateFlyButton()

    if not silent then
        ShowNotification("Fly: OFF | Kontrol arah dipulihkan")
    end
end

local function StartFlying(silent)
    if Flying then
        UpdateFlyButton()
        return true
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not root or not hum or hum.Health <= 0 then
        ShowNotification("Karakter belum siap untuk Fly")
        return false
    end

    -- Bersihkan sisa object Fly tanpa menjalankan proses pemulihan arah.
    RemoveFlyPhysics(root)

    PreviousFlyHumanoidState = {
        PlatformStand = hum.PlatformStand,
        AutoRotate = hum.AutoRotate
    }

    Flying = true
    hum.PlatformStand = true
    hum.AutoRotate = false

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "DvisualFlyGyro"
    BodyGyro.P = 9e4
    BodyGyro.D = 1000
    BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.CFrame = root.CFrame
    BodyGyro.Parent = root

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "DvisualFlyVelocity"
    BodyVelocity.P = 9e4
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVelocity.Parent = root

    FlyHumanoidDiedConnection = hum.Died:Connect(function()
        StopFlying(true)
    end)

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Flying or not root:IsDescendantOf(workspace) or hum.Health <= 0 then
            StopFlying(true)
            return
        end

        local camera = workspace.CurrentCamera
        if not camera or not BodyVelocity or not BodyGyro then
            StopFlying(true)
            return
        end

        local moveDirection = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection -= camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection -= camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            moveDirection += Vector3.yAxis
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
            moveDirection -= Vector3.yAxis
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        BodyVelocity.Velocity = moveDirection * FlySpeed

        -- Hanya gunakan arah horizontal kamera.
        -- Tubuh tidak lagi ikut miring ke atas/bawah bersama kamera.
        local cameraLook = camera.CFrame.LookVector
        local flatCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z)

        if flatCameraLook.Magnitude > 0.001 then
            BodyGyro.CFrame = CFrame.lookAt(
                root.Position,
                root.Position + flatCameraLook.Unit,
                Vector3.yAxis
            )
        end

        hum.PlatformStand = true
        hum.AutoRotate = false
    end)

    UpdateFlyButton()

    if not silent then
        ShowNotification("Fly: ON | Q naik, E turun")
    end

    return true
end

if movementTabFrame then
    flyBtn = AddScriptButton("Fly: OFF", function()
        if Flying then
            StopFlying(false)
        else
            StartFlying(false)
        end
    end, movementTabFrame)

    UpdateFlyButton()
end

if FlyShortcutConnection then
    FlyShortcutConnection:Disconnect()
    FlyShortcutConnection = nil
end

FlyShortcutConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.F then
        if Flying then
            StopFlying(false)
        else
            StartFlying(false)
        end
    end
end)

--- --- --- --- --- --- --- --- --- --- --- --- ---
-- FITUR AVATAR LIGHT (BERSIH, IDEMPOTEN, DAN SUPPORT RESPAWN)
--- --- --- --- --- --- --- --- --- --- --- --- ---
local AvaLightActive = false
local LightParts = {}
local avaLightBtn = nil

local function UpdateAvaLightButton()
    if not avaLightBtn or not avaLightBtn.Parent then return end

    avaLightBtn.Text = AvaLightActive and "Ava Light: ON" or "Ava Light: OFF"
    avaLightBtn.BackgroundColor3 = AvaLightActive
        and Color3.fromRGB(255, 255, 255)
        or Color3.fromRGB(40, 40, 40)
    avaLightBtn.TextColor3 = AvaLightActive
        and Color3.fromRGB(0, 0, 0)
        or Color3.fromRGB(255, 255, 255)
end

local function RemoveAvaLightFromCharacter(character)
    for _, object in ipairs(LightParts) do
        if object and object.Parent then
            object:Destroy()
        end
    end
    LightParts = {}

    if character then
        for _, object in ipairs(character:GetDescendants()) do
            if object.Name == "DvisualAvaPointLight" or object.Name == "DvisualAvaGlow" then
                object:Destroy()
            end
        end
    end
end

ApplyAvaLightToCharacter = function(character)
    if not character then return false end

    RemoveAvaLightFromCharacter(character)

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    local pointLight = Instance.new("PointLight")
    pointLight.Name = "DvisualAvaPointLight"
    pointLight.Brightness = 1.5
    pointLight.Range = 40
    pointLight.Color = Color3.fromRGB(255, 255, 255)
    pointLight.Shadows = false
    pointLight.Parent = root
    table.insert(LightParts, pointLight)

    local highlight = Instance.new("Highlight")
    highlight.Name = "DvisualAvaGlow"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    table.insert(LightParts, highlight)

    return true
end

SetAvaLight = function(enabled, silent)
    enabled = enabled == true

    if enabled then
        local char = player.Character
        if not char or not ApplyAvaLightToCharacter(char) then
            AvaLightActive = false
            UpdateAvaLightButton()
            if not silent then
                ShowNotification("Karakter belum siap untuk Ava Light")
            end
            return false
        end

        AvaLightActive = true
    else
        AvaLightActive = false
        RemoveAvaLightFromCharacter(player.Character)
    end

    UpdateAvaLightButton()
    if not silent then
        ShowNotification(AvaLightActive and "Avatar Light: ON" or "Avatar Light: OFF")
    end
    return true
end

if movementTabFrame then
    avaLightBtn = AddScriptButton("Ava Light: OFF", function()
        SetAvaLight(not AvaLightActive, false)
    end, movementTabFrame)
    UpdateAvaLightButton()
end

ResetMovement = function()
    -- Fly harus dimatikan terlebih dahulu agar PlatformStand dan physics kembali normal.
    if StopFlying then
        StopFlying(true)
    end

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum then
        if not MovementDefaults.Captured then
            CaptureMovementDefaults(char, true)
        end

        hum.WalkSpeed = MovementDefaults.WalkSpeed
        hum.UseJumpPower = MovementDefaults.UseJumpPower
        hum.JumpPower = MovementDefaults.JumpPower
        hum.JumpHeight = MovementDefaults.JumpHeight
    end

    FlySpeed = MovementDefaults.FlySpeed
    _G.FlySpeed = MovementDefaults.FlySpeed

    UpdateMovementControl("Walk Speed", MovementDefaults.WalkSpeed)
    UpdateMovementControl("Jump Power", MovementDefaults.JumpPower)
    UpdateMovementControl("Fly Speed", MovementDefaults.FlySpeed)

    ShowNotification("Movement dikembalikan ke nilai sebelumnya")
end

CleanupMovementFeatures = function()
    if StopFlying then
        StopFlying(true)
    end

    if SetAvaLight then
        SetAvaLight(false, true)
    end

    if FlyShortcutConnection then
        FlyShortcutConnection:Disconnect()
        FlyShortcutConnection = nil
    end
end


--- --- 🔹 SINGLE RESPOND SYSTEM (REPLACER) 🔹 --- ---
-- Hapus semua Player.CharacterAdded yang lain, cukup pakai yang ini:

local function CleanReapply(char)
    -- Fly lama tidak boleh membawa BodyMover/PlatformStand ke karakter baru.
    if StopFlying then
        StopFlying(true)
    end

    -- 1. Tunggu Humanoid & Animate benar-benar masuk ke Workspace
    local hum = char:WaitForChild("Humanoid", 10)
    local animScript = char:WaitForChild("Animate", 10)
    
    if hum and animScript then
        -- Simpan nilai asli dari karakter baru untuk Reset Movement.
        CaptureMovementDefaults(char, true)
        UpdateMovementControl("Walk Speed", MovementDefaults.WalkSpeed)
        UpdateMovementControl("Jump Power", MovementDefaults.JumpPower)
        UpdateMovementControl("Fly Speed", MovementDefaults.FlySpeed)
        -- 2. Jeda yang lebih aman (Roblox butuh waktu untuk inisialisasi internal)
        task.wait(1.5) 
        
        -- 3. Pasang ulang seluruh animasi dalam satu batch agar tidak terjadi race condition.
        local hasSavedAnimation = false
        for _, data in pairs(SavedAnimations) do
            if data ~= nil then
                hasSavedAnimation = true
                break
            end
        end

        if hasSavedAnimation then
            ApplyAnimationBatch(SavedAnimations)
        end

        -- Jika Ava Light sebelumnya ON, pasang kembali satu kali pada karakter baru.
        if AvaLightActive and ApplyAvaLightToCharacter then
            ApplyAvaLightToCharacter(char)
            UpdateAvaLightButton()
        end
    end
end

-- Hanya satu koneksi agar tidak bentrok
player.CharacterAdded:Connect(CleanReapply)

-- Jalankan untuk karakter pertama kali load
if player.Character then
    task.spawn(function()
        CleanReapply(player.Character)
    end)
end
