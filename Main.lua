-- ====================================================================
-- MASENSDEV RIDE A PET V2 (CLEAN VALUE & FILTERED OVERHEAD)
-- Modern Custom GUI (Red & Black Theme | Sidebar Layout)
-- ====================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- State Variables
local autoFarmActive = false
local autoUpgradeHatchActive = false
local espActive = false
local infiniteJumpActive = false
local noClipActive = false
local antiAfkActive = false

local minValueFilter = 0
local baseCFrame = nil

local farmSpeed = 300
local walkSpeedVal = 16
local jumpPowerVal = 50

-- ESP Tracking Data
local activeESPList = {}

-- Notification System
local function sendNotification(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 3
		})
	end)
end

-- Safe Text Parser (Parsing 'k', 'm', 'b', 't')
local function parseValueText(text)
	if type(text) ~= "string" or text == "" then return 0 end
	local cleanText = text:lower():gsub("%s+", "")
	local numStr, unit = cleanText:match("([%d%.]+)([kmbt]?)")
	local num = tonumber(numStr)
	if not num then return 0 end
	if unit == "k" then return num * 1000
	elseif unit == "m" then return num * 1000000
	elseif unit == "b" then return num * 1000000000
	elseif unit == "t" then return num * 1000000000000 end
	return num
end

-- Formatter Angka Singkat (Mengubah 1000000000 menjadi 1B, dst)
local function formatShortNumber(num)
	if not num or num == 0 then return "0" end
	if num >= 1e12 then
		return string.format("%.1fT", num / 1e12):gsub("%.0T", "T")
	elseif num >= 1e9 then
		return string.format("%.1fB", num / 1e9):gsub("%.0B", "B")
	elseif num >= 1e6 then
		return string.format("%.1fM", num / 1e6):gsub("%.0M", "M")
	elseif num >= 1e3 then
		return string.format("%.1fK", num / 1e3):gsub("%.0K", "K")
	else
		return tostring(num)
	end
end

-- Safeguard Remote Path
local function getUpgradeRemote()
	local success, result = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes", 5)
			:WaitForChild("Game", 5)
			:WaitForChild("Plot", 5)
			:WaitForChild("Upgrades", 5)
	end)
	return success and result or nil
end
local upgradeRemote = getUpgradeRemote()

-- ====================================================================
-- GUI CREATION (RED & BLACK THEME)
-- ====================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasensDev_RideAPetV2"
screenGui.ResetOnSpawn = false

local mounted = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not mounted or not screenGui.Parent then screenGui.Parent = player:WaitForChild("PlayerGui") end

-- Floating Open/Close Button
local toggleMDBtn = Instance.new("TextButton")
toggleMDBtn.Size = UDim2.new(0, 50, 0, 50)
toggleMDBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
toggleMDBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
toggleMDBtn.BackgroundTransparency = 0.2
toggleMDBtn.Text = "MD"
toggleMDBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleMDBtn.TextSize = 18
toggleMDBtn.Font = Enum.Font.SourceSansBold
toggleMDBtn.Parent = screenGui

local mdCorner = Instance.new("UICorner")
mdCorner.CornerRadius = UDim.new(1, 0)
mdCorner.Parent = toggleMDBtn

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 360)
mainFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.4
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(200, 0, 0)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- Top Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
titleBar.BackgroundTransparency = 0.4
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -15, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MasensDev Ride A Pet V2"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.Parent = titleBar

-- Dragging Functionality
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

toggleMDBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

-- Sidebar Frame
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -45)
sidebar.Position = UDim2.new(0, 5, 0, 42)
sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
sidebar.BackgroundTransparency = 0.4
sidebar.Parent = mainFrame

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 8)
sidebarCorner.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 8)
sidebarPadding.PaddingLeft = UDim.new(0, 6)
sidebarPadding.PaddingRight = UDim.new(0, 6)
sidebarPadding.Parent = sidebar

-- Content Container
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -150, 1, -45)
contentArea.Position = UDim2.new(0, 142, 0, 42)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

-- Tabs Management
local tabButtons = {}
local tabPages = {}

local function createTabPage(tabName)
	local scrollPage = Instance.new("ScrollingFrame")
	scrollPage.Size = UDim2.new(1, 0, 1, 0)
	scrollPage.BackgroundTransparency = 1
	scrollPage.ScrollBarThickness = 4
	scrollPage.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 0)
	scrollPage.Visible = false
	scrollPage.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollPage.Parent = contentArea
	
	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Padding = UDim.new(0, 8)
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Parent = scrollPage
	
	pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 15)
	end)
	
	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(1, 0, 0, 32)
	tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabBtn.BackgroundTransparency = 0.4
	tabBtn.Text = tabName
	tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	tabBtn.Font = Enum.Font.SourceSansBold
	tabBtn.TextSize = 13
	tabBtn.Parent = sidebar
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = tabBtn
	
	tabButtons[tabName] = tabBtn
	tabPages[tabName] = scrollPage
	
	tabBtn.MouseButton1Click:Connect(function()
		for name, page in pairs(tabPages) do
			page.Visible = (name == tabName)
		end
		for name, btn in pairs(tabButtons) do
			if name == tabName then
				btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end)
	
	return scrollPage
end

local mainPage = createTabPage("Main")
local miscPage = createTabPage("Misc")
local settingPage = createTabPage("Setting")

tabButtons["Main"].BackgroundColor3 = Color3.fromRGB(180, 0, 0)
tabButtons["Main"].TextColor3 = Color3.fromRGB(255, 255, 255)
tabPages["Main"].Visible = true

-- ====================================================================
-- COMPONENT BUILDERS
-- ====================================================================

local function buildButton(parent, text, initialActive, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -5, 0, 35)
	btn.BackgroundColor3 = initialActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
	btn.BackgroundTransparency = 0.4
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 13
	btn.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	
	local active = initialActive or false
	btn.MouseButton1Click:Connect(function()
		active = not active
		if callback then callback(active, btn) end
	end)
	return btn
end

local function buildInput(parent, placeholder, callback)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -5, 0, 35)
	box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	box.BackgroundTransparency = 0.4
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.SourceSans
	box.TextSize = 13
	box.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = box
	
	box.FocusLost:Connect(function()
		if callback then callback(box.Text, box) end
	end)
	return box
end

local function buildStepper(parent, titleText, defaultVal, minVal, maxVal, step, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -5, 0, 38)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.4
	frame.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 1, 0)
	lbl.Position = UDim2.new(0.04, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText .. ": " .. tostring(defaultVal)
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 12
	lbl.Parent = frame
	
	local minus = Instance.new("TextButton")
	minus.Size = UDim2.new(0, 30, 0, 26)
	minus.Position = UDim2.new(0.60, 0, 0.15, 0)
	minus.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	minus.BackgroundTransparency = 0.4
	minus.Text = "-"
	minus.TextColor3 = Color3.fromRGB(255, 255, 255)
	minus.Font = Enum.Font.SourceSansBold
	minus.Parent = frame
	Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 4)
	
	local plus = Instance.new("TextButton")
	plus.Size = UDim2.new(0, 30, 0, 26)
	plus.Position = UDim2.new(0.80, 0, 0.15, 0)
	plus.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	plus.BackgroundTransparency = 0.4
	plus.Text = "+"
	plus.TextColor3 = Color3.fromRGB(255, 255, 255)
	plus.Font = Enum.Font.SourceSansBold
	plus.Parent = frame
	Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 4)
	
	local current = defaultVal
	local function updateVal(newVal)
		current = math.clamp(newVal, minVal, maxVal)
		lbl.Text = titleText .. ": " .. tostring(current)
		if callback then callback(current) end
	end
	
	minus.MouseButton1Click:Connect(function() updateVal(current - step) end)
	plus.MouseButton1Click:Connect(function() updateVal(current + step) end)
end

-- ====================================================================
-- TAB 1: MAIN
-- ====================================================================

-- Function Menghapus ESP Saat Di-Reset/Filter Diubah
local function clearAllESP()
	for _, data in ipairs(activeESPList) do
		if data.Gui and data.Gui.Parent then
			data.Gui:Destroy()
		end
	end
	activeESPList = {}
end

buildInput(mainPage, "Min Value Egg (misal: 10k, 1m, 100b)", function(text)
	minValueFilter = parseValueText(text)
	clearAllESP() -- Bersihkan ESP agar overhead telur di bawah nilai filter hilang
	sendNotification("Filter Min Value", "Menampilkan telur >= " .. formatShortNumber(minValueFilter))
end)

buildButton(mainPage, "Set Lokasi Markas (Posisi Sekarang)", false, function(_, btn)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		baseCFrame = hrp.CFrame
		btn.Text = "Markas Terpasang!"
		sendNotification("Markas", "Lokasi markas berhasil disimpan.")
		task.wait(1.5)
		btn.Text = "Set Lokasi Markas (Posisi Sekarang)"
	end
end)

buildButton(mainPage, "AUTO FARMING: OFF", false, function(active, btn)
	autoFarmActive = active
	btn.Text = autoFarmActive and "AUTO FARMING: ON" or "AUTO FARMING: OFF"
	btn.BackgroundColor3 = autoFarmActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
end)

buildButton(mainPage, "AUTO UPGRADE HATCH: OFF", false, function(active, btn)
	autoUpgradeHatchActive = active
	btn.Text = autoUpgradeHatchActive and "AUTO UPGRADE HATCH: ON" or "AUTO UPGRADE HATCH: OFF"
	btn.BackgroundColor3 = autoUpgradeHatchActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
end)

buildButton(mainPage, "ESP EGG: OFF", false, function(active, btn)
	espActive = active
	btn.Text = espActive and "ESP EGG: ON" or "ESP EGG: OFF"
	btn.BackgroundColor3 = espActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
	if not espActive then
		clearAllESP()
	end
end)

buildInput(mainPage, "Speed Menuju (Max: 300)", function(text, box)
	local num = parseValueText(text)
	if num > 300 then
		sendNotification("Peringatan Speed!", "JANGAN LEBIH DARI 300!", 4)
		farmSpeed = 300
		box.Text = "300"
	else
		farmSpeed = num > 0 and num or 16
	end
end)

-- ====================================================================
-- TAB 2: MISC
-- ====================================================================

buildButton(miscPage, "NO CLIP: OFF", false, function(active, btn)
	noClipActive = active
	btn.Text = noClipActive and "NO CLIP: ON" or "NO CLIP: OFF"
	btn.BackgroundColor3 = noClipActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
end)

buildButton(miscPage, "INFINITE JUMP: OFF", false, function(active, btn)
	infiniteJumpActive = active
	btn.Text = infiniteJumpActive and "INFINITE JUMP: ON" or "INFINITE JUMP: OFF"
	btn.BackgroundColor3 = infiniteJumpActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
end)

buildStepper(miscPage, "Kecepatan Lari", walkSpeedVal, 16, 300, 10, function(val)
	walkSpeedVal = val
	local char = player.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		char:FindFirstChildOfClass("Humanoid").WalkSpeed = val
	end
end)

buildStepper(miscPage, "Tinggi Lompat", jumpPowerVal, 50, 300, 10, function(val)
	jumpPowerVal = val
	local char = player.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		local hum = char:FindFirstChildOfClass("Humanoid")
		hum.UseJumpPower = true
		hum.JumpPower = val
	end
end)

-- ====================================================================
-- TAB 3: SETTINGS
-- ====================================================================

buildButton(settingPage, "Anti AFK: OFF", false, function(active, btn)
	antiAfkActive = active
	btn.Text = antiAfkActive and "Anti AFK: ON" or "Anti AFK: OFF"
	btn.BackgroundColor3 = antiAfkActive and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
	if antiAfkActive then
		sendNotification("Anti AFK", "Fitur Anti AFK Aktif!")
	end
end)

player.Idled:Connect(function()
	if antiAfkActive then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

buildButton(settingPage, "Rejoin Server", false, function(_, btn)
	sendNotification("Rejoin", "Menghubungkan ulang ke server...", 3)
	TeleportService:Teleport(game.PlaceId, player)
end)

buildButton(settingPage, "Hop Server (Server Sepi)", false, function(_, btn)
	sendNotification("Hop Server", "Mencari server sepi...", 3)
	local placeId = game.PlaceId
	local success, result = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
	end)
	
	if success and result and result.data then
		for _, server in ipairs(result.data) do
			if server.playing < server.maxPlayers and server.id ~= game.JobId then
				TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
				return
			end
		end
	end
	sendNotification("Hop Server", "Gagal menemukan server sepi lain.")
end)

-- ====================================================================
-- EGG HELPER & OPTIMIZED OVERHEAD ESP SYSTEM
-- ====================================================================

local function getEggFolder()
	return workspace:FindFirstChild("RenderedEggs") 
		or workspace:FindFirstChild("Eggs") 
		or workspace:FindFirstChild("EggFolder") 
		or workspace:FindFirstChild("SpawnedEggs") 
		or workspace
end

local function getEggValue(eggModel)
	local highestValue = 0
	for _, desc in ipairs(eggModel:GetDescendants()) do
		if desc:IsA("TextLabel") and desc.Text ~= "" then
			local val = parseValueText(desc.Text)
			if val > highestValue then highestValue = val end
		elseif desc:IsA("IntValue") or desc:IsA("NumberValue") then
			if desc.Value > highestValue then highestValue = desc.Value end
		end
	end
	
	local attrVal = eggModel:GetAttribute("Value")
	if attrVal and tonumber(attrVal) then
		if tonumber(attrVal) > highestValue then highestValue = tonumber(attrVal) end
	end
	
	return highestValue > 0 and highestValue or 1
end

local function getAllEggs()
	local eggList = {}
	local targetFolder = getEggFolder()
	local searchPool = (targetFolder == workspace) and workspace:GetChildren() or targetFolder:GetChildren()
	
	for _, item in ipairs(searchPool) do
		local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
		local isEgg = item.Name:lower():find("egg") ~= nil
		if prompt or isEgg then
			local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
			if part then
				local val = getEggValue(item)
				table.insert(eggList, {Model = item, Part = part, Prompt = prompt, Value = val})
			end
		end
	end
	return eggList
end

local function createEggESP(targetPart, eggName, val)
	if targetPart:FindFirstChild("EggOverheadESP") then return end

	local bgui = Instance.new("BillboardGui")
	bgui.Name = "EggOverheadESP"
	bgui.Adornee = targetPart
	bgui.Size = UDim2.new(0, 180, 0, 55)
	bgui.StudsOffset = Vector3.new(0, 3.5, 0)
	bgui.AlwaysOnTop = true
	bgui.MaxDistance = math.huge
	bgui.Parent = targetPart

	local frame = Instance.new("Frame", bgui)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.BackgroundTransparency = 0.25

	local fCorner = Instance.new("UICorner", frame)
	fCorner.CornerRadius = UDim.new(0, 8)

	local fStroke = Instance.new("UIStroke", frame)
	fStroke.Color = Color3.fromRGB(255, 30, 30)
	fStroke.Thickness = 1.5

	local txt = Instance.new("TextLabel", frame)
	txt.Name = "LabelInfo"
	txt.Size = UDim2.new(1, -8, 1, -4)
	txt.Position = UDim2.new(0, 4, 0, 2)
	txt.BackgroundTransparency = 1
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextStrokeTransparency = 0
	txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	txt.Font = Enum.Font.SourceSansBold
	txt.TextSize = 13
	txt.Text = string.format("🥚 %s\n💰 Nilai: %s\n📏 Jarak: Calculating...", eggName, formatShortNumber(val))

	table.insert(activeESPList, {
		Part = targetPart,
		Name = eggName,
		Value = val,
		Gui = bgui,
		Label = txt
	})
end

-- Thread Scanner ESP (Hanya memproses telur yang lolos minValueFilter)
task.spawn(function()
	while true do
		task.wait(1)
		if espActive then
			local allEggs = getAllEggs()
			for _, eggData in ipairs(allEggs) do
				-- FILTER HANYA UNTUK TELUR YANG NILAINYA LEBIH DARI/SAMA DENGAN MIN VALUE
				if eggData.Value >= minValueFilter then
					createEggESP(eggData.Part, eggData.Model.Name, eggData.Value)
				end
			end
		end
	end
end)

-- Thread RenderStepped (Update Teks Jarak)
RunService.RenderStepped:Connect(function()
	if not espActive then return end
	
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local hrpPos = hrp.Position

	for i = #activeESPList, 1, -1 do
		local data = activeESPList[i]
		if data.Part and data.Part:IsDescendantOf(workspace) and data.Label and data.Label.Parent then
			local dist = (data.Part.Position - hrpPos).Magnitude
			data.Label.Text = string.format("🥚 %s\n💰 Nilai: %s\n📏 Jarak: %d Meter", data.Name, formatShortNumber(data.Value), math.floor(dist))
		else
			if data.Gui and data.Gui.Parent then data.Gui:Destroy() end
			table.remove(activeESPList, i)
		end
	end
end)

-- ====================================================================
-- CORE ENGINE LOOPS (FARMING & PLAYER MOVEMENTS)
-- ====================================================================

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
	if infiniteJumpActive then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- Noclip Execution Loop
RunService.Stepped:Connect(function()
	if noClipActive or autoFarmActive then
		local char = player.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end
end)

-- 3D Flight Movement Logic
local function moveTo3D(hrp, targetCFrame)
	local startCFrame = hrp.CFrame
	local distance = (startCFrame.Position - targetCFrame.Position).Magnitude
	local travelTime = distance / math.max(farmSpeed, 1)
	local elapsed = 0
	
	while elapsed < travelTime and autoFarmActive do
		elapsed = elapsed + RunService.Heartbeat:Wait()
		local alpha = math.min(elapsed / travelTime, 1)
		hrp.CFrame = startCFrame:Lerp(targetCFrame, alpha)
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
	
	if autoFarmActive then hrp.CFrame = targetCFrame end
end

-- Interact Proximity Prompt Function
local function interactPrompt(prompt)
	if not prompt then return end
	prompt.HoldDuration = 0
	local fireFunc = fireproximityprompt or (syn and syn.fireproximityprompt)
	if fireFunc then
		for _ = 1, 5 do
			fireFunc(prompt)
			task.wait(0.05)
		end
	end
end

-- Auto Farm Main Loop
task.spawn(function()
	while true do
		task.wait(0.1)
		if autoFarmActive then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			
			if hrp then
				if not baseCFrame then baseCFrame = hrp.CFrame end
				
				local allEggs = getAllEggs()
				local validEggs = {}
				
				for _, eggData in ipairs(allEggs) do
					if eggData.Value >= minValueFilter and eggData.Prompt then
						table.insert(validEggs, eggData)
					end
				end
				
				table.sort(validEggs, function(a, b) return a.Value > b.Value end)
				
				if #validEggs > 0 then
					local target = validEggs[1]
					local targetCFrame = target.Part.CFrame * CFrame.new(0, 1, 0)
					
					moveTo3D(hrp, targetCFrame)
					
					if autoFarmActive and (hrp.Position - target.Part.Position).Magnitude <= 12 then
						interactPrompt(target.Prompt)
						task.wait(0.2)
						
						if baseCFrame then 
							moveTo3D(hrp, baseCFrame)
							if autoFarmActive then
								task.wait(2)
							end
						end
					end
				end
			end
		end
	end
end)

-- Auto Upgrade Hatch Loop
task.spawn(function()
	while true do
		task.wait(0.3)
		if autoUpgradeHatchActive then
			local remote = upgradeRemote or getUpgradeRemote()
			if remote then
				pcall(function()
					remote:FireServer("HatchLuck")
					remote:FireServer("Hatch")
					remote:FireServer(1)
				end)
			end
		end
	end
end)
