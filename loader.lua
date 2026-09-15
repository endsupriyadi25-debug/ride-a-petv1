local HttpService = game:GetService("HttpService")
local RbxAnalytics = game:GetService("RbxAnalyticsService")

-- CONFIGURATION
local KEY_LIST_URL = "https://raw.githubusercontent.com/endsupriyadi25-debug/ride-a-petv1/refs/heads/main/keys.json"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/endsupriyadi25-debug/ride-a-petv1/refs/heads/main/Main.lua"
local SAVE_FILE = "MD_EggFarm_SavedKey.txt"

-- MASUKKAN LINK TEMPAT PEMAIN AMBIL KEY (Misal: Link Discord / Pastebin Anda)
local GET_KEY_LINK = "https://link-center.net/9347872/iYyFL35U077Q" 

local HWID = RbxAnalytics:GetClientId()

-- Fungsi Validasi Key
local function checkKey(userKey)
    local success, response = pcall(function()
        return game:HttpGet(KEY_LIST_URL)
    end)
    
    if not success or not response then
        return false, "Gagal terhubung ke database key!"
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeSuccess or not data or not data.KEYS then
        return false, "Format database key salah!"
    end

    local keyData = data.KEYS[userKey]
    if keyData then
        if keyData.hwid == "" or keyData.hwid == HWID then
            if writefile then writefile(SAVE_FILE, userKey) end
            return true, "Valid"
        else
            return false, "Key sudah digunakan di device lain (HWID Lock)!"
        end
    end

    return false, "Key tidak terdaftar / kadaluarsa!"
end

local function executeMainScript()
    print("[MD HUB] Key Valid! Memuat Script Utama...")
    loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
end

-- 1. CEK AUTO-LOGIN
if isfile and isfile(SAVE_FILE) then
    local savedKey = readfile(SAVE_FILE)
    local isValid, _ = checkKey(savedKey)
    if isValid then
        executeMainScript()
        return
    else
        if delfile then delfile(SAVE_FILE) end
    end
end

-- 2. GUI MASUKKAN KEY
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MD_KeySystemUI"
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 180) -- Diperbesar sedikit untuk tombol tambahan
Frame.Position = UDim2.new(0.5, -150, 0.4, -90)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "MD EGG FARM - KEY SYSTEM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local InputBox = Instance.new("TextBox", Frame)
InputBox.Size = UDim2.new(0.9, 0, 0, 35)
InputBox.Position = UDim2.new(0.05, 0, 0.28, 0)
InputBox.PlaceholderText = "Masukkan Key..."
InputBox.Text = ""
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.Font = Enum.Font.SourceSans
InputBox.TextSize = 13
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 5)

-- TOMBOL LOGIN
local SubmitBtn = Instance.new("TextButton", Frame)
SubmitBtn.Size = UDim2.new(0.43, 0, 0, 35)
SubmitBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
SubmitBtn.Text = "LOGIN"
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.Font = Enum.Font.SourceSansBold
SubmitBtn.TextSize = 14
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 5)

-- TOMBOL GET KEY
local GetKeyBtn = Instance.new("TextButton", Frame)
GetKeyBtn.Size = UDim2.new(0.43, 0, 0, 35)
GetKeyBtn.Position = UDim2.new(0.52, 0, 0.55, 0)
GetKeyBtn.Text = "GET KEY"
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 200)
GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyBtn.Font = Enum.Font.SourceSansBold
GetKeyBtn.TextSize = 14
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 5)

-- LOGIKA KLIK BUTTON
SubmitBtn.MouseButton1Click:Connect(function()
    local userKey = InputBox.Text
    SubmitBtn.Text = "Memeriksa..."
    
    local success, msg = checkKey(userKey)
    if success then
        SubmitBtn.Text = "BERHASIL!"
        task.wait(0.5)
        ScreenGui:Destroy()
        executeMainScript()
    else
        SubmitBtn.Text = "LOGIN"
        InputBox.Text = ""
        InputBox.PlaceholderText = msg
    end
end)

GetKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(GET_KEY_LINK)
        GetKeyBtn.Text = "COPIED!"
        task.wait(1.5)
        GetKeyBtn.Text = "GET KEY"
    else
        GetKeyBtn.Text = "FAILED"
    end
end)
