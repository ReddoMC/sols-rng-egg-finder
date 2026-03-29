--// SERVICES
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local plr = Players.LocalPlayer

--// STATE
local lastMoveTime = tick()
local lastEggTime = tick()
local badEggs = {}

--// SOUNDS
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://131390520971848"
sound.Parent = workspace

local sound2 = Instance.new("Sound")
sound2.SoundId = "rbxassetid://137448770594263"
sound2.Parent = workspace

local sound3 = Instance.new("Sound")
sound3.SoundId = "rbxassetid://135692388807719"
sound3.Parent = workspace


--// SPECIAL EGGS
local specialeggs = {
	["Sky Festival (1 in 2b)"] = "dreamer_egg",
	["Eggsistance (1 in 307m)"] = "andromeda_egg",
	["REVIVE (1 in 645m)"] = "angelic_egg",
	["Eggore (1 in 700m)"] = "blooming_egg",
	["Y.O.L.K (1 in 1.79b)"] = "egg_v2",
	["Eggis (1 in 1.15b)"] = "the_egg_of_the_sky",
	["Eastre (1 in 1b)"] = "forest_egg",
	["Hatchwarden (1 in 40m)"] = "hatch_egg",
	["Emperor (1 in 80m)"] = "royal_egg"
}

local function isSpecialEgg(name)
	return specialeggs[name] ~= nil
end


--// PLAYER HELPERS
local function getCharacter()
	return plr.Character or plr.CharacterAdded:Wait()
end

local function getRoot()
	return getCharacter():WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
	return getCharacter():WaitForChild("Humanoid")
end


--// VALID EGG CHECK
local function isValidEgg(egg)
	return egg
		and egg:IsA("BasePart")
		and (egg:GetAttribute("Point")
		or string.find(egg.Name, "random_potion_egg")
		or isSpecialEgg(egg.Name))
end


--// UI + HIGHLIGHT SYSTEM (RESTORED)
local function decorateEgg(egg)
	if egg:FindFirstChild("Highlight") then return end

	local highlight = Instance.new("Highlight")
	highlight.Parent = egg

	local pointlight = Instance.new("PointLight")
	pointlight.Parent = egg
	pointlight.Brightness = 1.5
	pointlight.Range = 25

	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1000
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.Parent = egg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard

	local points = egg:GetAttribute("Point")

	if points then
		label.Text = points .. " Points"
		label.TextColor3 = egg:GetAttribute("TextColor") or Color3.new(1,1,1)
		sound:Play()
	else
		if isSpecialEgg(egg.Name) then
			label.Text = isSpecialEgg(egg.Name)
			sound3:Play()
		else
			label.Text = "Special egg (" .. egg.Name .. ")"
			sound2:Play()
		end
		label.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
end


--// CLOSEST EGG (FAST)
local function getClosestEgg()
	local root = getRoot()
	local closest, shortest = nil, math.huge

	for _, egg in pairs(workspace:GetChildren()) do
		if isValidEgg(egg) and not badEggs[egg] then
			decorateEgg(egg)

			local dist = (root.Position - egg.Position).Magnitude
			if dist < shortest then
				shortest = dist
				closest = egg
			end
		end
	end

	return closest
end


--// PATH SAFETY CHECK
local function isPathSafe(waypoints)
	for i = 2, #waypoints do
		local drop = waypoints[i-1].Position.Y - waypoints[i].Position.Y
		if drop > 6 then
			return false
		end
	end
	return true
end


--// MOVE SYSTEM
local function moveTo(target)
	if not target then return false end

	local humanoid = getHumanoid()
	local root = getRoot()

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 8,
		AgentMaxSlope = 35
	})

	path:ComputeAsync(root.Position, target.Position)

	if path.Status ~= Enum.PathStatus.Success then
		return false
	end

	local waypoints = path:GetWaypoints()

	if not isPathSafe(waypoints) then
		return false
	end

	for _, wp in ipairs(waypoints) do
		lastMoveTime = tick()

		humanoid:MoveTo(wp.Position)

		if wp.Action == Enum.PathWaypointAction.Jump then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		local reached = humanoid.MoveToFinished:Wait(2)
		if not reached then return false end

		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			return false
		end
	end

	return true
end


--// PROMPTS
task.spawn(function()
	while true do
		task.wait(0.2)

		local root = getRoot()

		for _, egg in pairs(workspace:GetChildren()) do
			if isValidEgg(egg) then
				for _, obj in pairs(egg:GetDescendants()) do
					if obj:IsA("ProximityPrompt") then
						if (root.Position - egg.Position).Magnitude < 12 then
							fireproximityprompt(obj)
						end
					end
				end
			end
		end
	end
end)


--// STUCK DETECTOR
task.spawn(function()
	local lastPos = nil

	while true do
		task.wait(2)

		local root = getRoot()

		if lastPos then
			local moved = (root.Position - lastPos).Magnitude

			if moved < 2 and (tick() - lastMoveTime) > 10 then
				getCharacter():BreakJoints()
			end
		end

		lastPos = root.Position
	end
end)


--// CLEAN BAD EGGS
task.spawn(function()
	while true do
		task.wait(10)
		table.clear(badEggs)
	end
end)


--// MAIN LOOP
while true do
	local target = getClosestEgg()

	if target then
		lastEggTime = tick()

		local success = moveTo(target)

		local tries = 0
		while not success and tries < 2 do
			task.wait(0.2)
			success = moveTo(target)
			tries += 1
		end
	else
		if tick() - lastEggTime > 15 then
			getCharacter():BreakJoints()
			task.wait(3)
			lastEggTime = tick()
		end
	end

	task.wait(0.1)
end
