-- MD EGG FARM HUB (Obfuscation-Safe Version)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- State Variables
local autoFarmActive = false
local autoUpgradeHatchActive = false
local espActive = false
local infiniteJumpActive = false
local noClipActive = false

local minValueFilter = 0
local baseCFrame = nil

local farmSpeed = 300
local walkSpeedVal = 16
local jumpPowerVal = 50

-- Remote Path Safeguard (Literal string protection)
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

-- Safe Text Parser
local function parseValueText(text)
	if type(text) ~= "string" or text == "" then return 0 end
	local cleanText = text:lower():gsub("%s+", "")
	local numStr, unit = cleanText:match("([%d%.]+)([kmb]?)")
	local num = tonumber(numStr)
	if not num then return 0 end
	if unit == "k" then return num * 1000
	elseif unit == "m" then return num * 1000000
	elseif unit == "b" then return num * 1000000000 end
	return num
end

-- Secure CoreGui/PlayerGui Mounting
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MD_EggFarmHub"
screenGui.ResetOnSpawn = false

local mounted = pcall(function() 
	screenGui.Parent = game:GetService("CoreGui") 
end)
if not mounted or not screenGui.Parent then 
	screenGui.Parent = player:WaitForChild("PlayerGui") 
end

-- Floating Toggle Button
local toggleMDBtn = Instance.new("TextButton")
toggleMDBtn.Size = UDim2.new(0, 50, 0, 50)
toggleMDBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
toggleMDBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
toggleMDBtn.BackgroundTransparency = 0.2
toggleMDBtn.Text = "MD"
toggleMDBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleMDBtn.TextSize = 18
toggleMDBtn.Font = Enum.Font.SourceSans
toggleMDBtn.Parent = screenGui

local mdCorner = Instance.new("UICorner")
mdCorner.CornerRadius = UDim.new(1, 0)
mdCorner.Parent = toggleMDBtn

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 520)
mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 40, 70)
mainFrame.BackgroundTransparency = 0.6
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
title.BackgroundTransparency = 0.4
title.Text = "  MD EGG FARM HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = title

-- Scroll Container
local container = Instance.new("ScrollingFrame")
container.Size = UDim2.new(1, -20, 1, -45)
container.Position = UDim2.new(0, 10, 0, 40)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 750)
container.ScrollBarThickness = 4
container.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- Helper UI Constructors
local function createButton(text, color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = color or Color3.fromRGB(0, 120, 180)
	btn.BackgroundTransparency = 0.3
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 13
	btn.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	return btn
end

local function createStepper(titleText, defaultVal, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 35)
	frame.BackgroundColor3 = Color3.fromRGB(5, 60, 95)
	frame.BackgroundTransparency = 0.4
	frame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 1, 0)
	lbl.Position = UDim2.new(0.05, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText .. ": " .. tostring(defaultVal)
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 12
	lbl.Parent = frame
	
	local minus = Instance.new("TextButton")
	minus.Size = UDim2.new(0, 30, 0, 25)
	minus.Position = UDim2.new(0.62, 0, 0.15, 0)
	minus.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	minus.BackgroundTransparency = 0.3
	minus.Text = "-"
	minus.TextColor3 = Color3.fromRGB(255, 255, 255)
	minus.Font = Enum.Font.SourceSansBold
	minus.Parent = frame
	Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)
	
	local plus = Instance.new("TextButton")
	plus.Size = UDim2.new(0, 30, 0, 25)
	plus.Position = UDim2.new(0.82, 0, 0.15, 0)
	plus.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	plus.BackgroundTransparency = 0.3
	plus.Text = "+"
	plus.TextColor3 = Color3.fromRGB(255, 255, 255)
	plus.Font = Enum.Font.SourceSansBold
	plus.Parent = frame
	Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)
	
	local current = defaultVal
	minus.MouseButton1Click:Connect(function()
		current = math.max(0, current - 25)
		lbl.Text = titleText .. ": " .. tostring(current)
		callback(current)
	end)
	plus.MouseButton1Click:Connect(function()
		current = current + 25
		lbl.Text = titleText .. ": " .. tostring(current)
		callback(current)
	end)
end

-- Inputs & Toggle Elements
local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, 0, 0, 32)
filterBox.BackgroundColor3 = Color3.fromRGB(5, 50, 80)
filterBox.BackgroundTransparency = 0.4
filterBox.PlaceholderText = "Min Value Egg (misal: 500, 10k, 1m)"
filterBox.Text = ""
filterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
filterBox.Font = Enum.Font.SourceSans
filterBox.TextSize = 12
filterBox.Parent = container
Instance.new("UICorner", filterBox).CornerRadius = UDim.new(0, 8)

local baseBtn = createButton("Set Lokasi Markas (Posisi Sekarang)")
local farmBtn = createButton("AUTO FARMING: OFF", Color3.fromRGB(180, 50, 50))
local upgradeBtn = createButton("AUTO UPGRADE HATCH: OFF", Color3.fromRGB(180, 50, 50))
local espBtn = createButton("ESP EGG: OFF", Color3.fromRGB(180, 50, 50))

createStepper("Speed Menuju", farmSpeed, function(val) farmSpeed = val end)

local noClipBtn = createButton("NO CLIP: OFF", Color3.fromRGB(180, 50, 50))
local infJumpBtn = createButton("INFINITE JUMP: OFF", Color3.fromRGB(180, 50, 50))

createStepper("Kecepatan Lari", walkSpeedVal, function(val)
	walkSpeedVal = val
	local char = player.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		char:FindFirstChildOfClass("Humanoid").WalkSpeed = val
	end
end)

createStepper("Tinggi Lompat", jumpPowerVal, function(val)
	jumpPowerVal = val
	local char = player.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		local hum = char:FindFirstChildOfClass("Humanoid")
		hum.UseJumpPower = true
		hum.JumpPower = val
	end
end)

-- UI Interactions
toggleMDBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

filterBox.FocusLost:Connect(function()
	minValueFilter = parseValueText(filterBox.Text)
end)

baseBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		baseCFrame = hrp.CFrame
		baseBtn.Text = "Markas Terpasang!"
		task.wait(1)
		baseBtn.Text = "Set Lokasi Markas (Posisi Sekarang)"
	end
end)

farmBtn.MouseButton1Click:Connect(function()
	autoFarmActive = not autoFarmActive
	farmBtn.Text = autoFarmActive and "AUTO FARMING: ON" or "AUTO FARMING: OFF"
	farmBtn.BackgroundColor3 = autoFarmActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

upgradeBtn.MouseButton1Click:Connect(function()
	autoUpgradeHatchActive = not autoUpgradeHatchActive
	upgradeBtn.Text = autoUpgradeHatchActive and "AUTO UPGRADE HATCH: ON" or "AUTO UPGRADE HATCH: OFF"
	upgradeBtn.BackgroundColor3 = autoUpgradeHatchActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

espBtn.MouseButton1Click:Connect(function()
	espActive = not espActive
	espBtn.Text = espActive and "ESP EGG: ON" or "ESP EGG: OFF"
	espBtn.BackgroundColor3 = espActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

noClipBtn.MouseButton1Click:Connect(function()
	noClipActive = not noClipActive
	noClipBtn.Text = noClipActive and "NO CLIP: ON" or "NO CLIP: OFF"
	noClipBtn.BackgroundColor3 = noClipActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

infJumpBtn.MouseButton1Click:Connect(function()
	infiniteJumpActive = not infiniteJumpActive
	infJumpBtn.Text = infiniteJumpActive and "INFINITE JUMP: ON" or "INFINITE JUMP: OFF"
	infJumpBtn.BackgroundColor3 = infiniteJumpActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

-- UI Dragging Engine
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
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
title.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

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

-- Universal Egg Finder Functions
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
		end
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

-- ESP Rendering System
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_Container"
espFolder.Parent = screenGui

RunService.RenderStepped:Connect(function()
	espFolder:ClearAllChildren()
	if not espActive then return end
	
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local hrpPos = hrp.Position
	local eggList = getAllEggs()
	
	for _, eggData in ipairs(eggList) do
		local part = eggData.Part
		if part then
			local dist = (part.Position - hrpPos).Magnitude
			local val = eggData.Value
			
			local bgui = Instance.new("BillboardGui")
			bgui.Adornee = part
			bgui.Size = UDim2.new(0, 200, 0, 60)
			bgui.AlwaysOnTop = true
			bgui.MaxDistance = math.huge
			bgui.Parent = espFolder
			
			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.TextColor3 = Color3.fromRGB(0, 230, 255)
			txt.TextStrokeTransparency = 0
			txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			txt.Font = Enum.Font.SourceSansBold
			txt.TextSize = 13
			txt.Text = string.format("Nama: %s\nNilai: %d\nJarak: %dm", eggData.Model.Name, val, math.floor(dist))
			txt.Parent = bgui
		end
	end
end)

-- 3D Flight Movement
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

-- ProximityPrompt Handler
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

-- Auto Farm Loop
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
