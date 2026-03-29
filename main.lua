local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://131390520971848"
sound.Parent = workspace
sound.Playing = false

local sound2 = Instance.new("Sound")
sound2.SoundId = "rbxassetid://137448770594263"
sound2.Parent = workspace
sound2.Playing = false

local sound3 = Instance.new("Sound")
sound3.SoundId = "rbxassetid://135692388807719"
sound3.Parent = workspace
sound3.Playing = false

local badEggs = {}

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

function isSpecialEgg(egg)
	for index, eggname in pairs(specialeggs) do
		if eggname == egg then
			return index
		end
	end
	return false
end

local Players = game:GetService("Players")

local plr = Players.LocalPlayer
if plr.Character then
	local light = Instance.new("PointLight")
	light.Parent = plr.Character.HumanoidRootPart
	light.Range = 22
end

local PathfindingService = game:GetService("PathfindingService")

local function getCharacter()
	return plr.Character or plr.CharacterAdded:Wait()
end

local function getRoot()
	local char = getCharacter()
	return char:WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
	local char = getCharacter()
	return char:WaitForChild("Humanoid")
end

-- Check if egg is valid (reuse your logic)
local function isValidEgg(egg)
	return egg:GetAttribute("Point")
		or string.find(egg.Name, "random_potion_egg")
		or isSpecialEgg(egg.Name) ~= false
end

local function isDangerousStep(fromPos, toPos)
	-- detect steep downward drops
	local drop = fromPos.Y - toPos.Y
	return drop > 6 -- tweak this (higher = more tolerant)
end

local function moveToTarget(target)
	if not target then return end

	local humanoid = getHumanoid()
	local root = getRoot()

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 8,
		AgentMaxSlope = 35 -- LOWER = avoids steep terrain
	})

	path:ComputeAsync(root.Position, target.Position)

	if path.Status ~= Enum.PathStatus.Success then
		return false
	end

	local waypoints = path:GetWaypoints()

	for i, waypoint in ipairs(waypoints) do
		-- 🚫 skip dangerous drops
		if i > 1 and isDangerousStep(waypoints[i-1].Position, waypoint.Position) then
			return false -- force recompute
		end

		humanoid:MoveTo(waypoint.Position)

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		local reached = humanoid.MoveToFinished:Wait(2)

		-- 🧍 stuck detection
		if not reached then
			return false
		end

		-- 💀 falling / water fail-safe
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			return false
		end
	end

	return true
end

local function isWater(part)
	return part and part.Name == "WaterBlock"
end

local function pathTouchesWater(waypoints)
	for _, waypoint in ipairs(waypoints) do
		local region = Region3.new(
			waypoint.Position - Vector3.new(2, 4, 2),
			waypoint.Position + Vector3.new(2, 4, 2)
		)

		local parts = workspace:FindPartsInRegion3(region, nil, 20)

		for _, part in pairs(parts) do
			if isWater(part) then
				return true
			end
		end
	end

	return false
end

local function isReachable(target)
	if badEggs[target] then return false end

	local root = getRoot()

	-- different configs to try
	local configs = {
		{AgentMaxSlope = 35},
		{AgentMaxSlope = 25}, -- stricter = avoids water edges
		{AgentMaxSlope = 45}
	}

	for _, config in ipairs(configs) do
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentJumpHeight = 8,
			AgentMaxSlope = config.AgentMaxSlope
		})

		-- 🎯 try slight offsets (forces new routes)
		local offsets = {
			Vector3.new(0,0,0),
			Vector3.new(6,0,0),
			Vector3.new(-6,0,0),
			Vector3.new(0,0,6),
			Vector3.new(0,0,-6)
		}

		for _, offset in ipairs(offsets) do
			local goal = target.Position + offset

			path:ComputeAsync(root.Position, goal)

			if path.Status == Enum.PathStatus.Success then
				local waypoints = path:GetWaypoints()

				-- 🚫 reject water paths
				if not pathTouchesWater(waypoints) then
					
					-- 🚫 reject big drops
					local safe = true
					for i = 2, #waypoints do
						local drop = waypoints[i-1].Position.Y - waypoints[i].Position.Y
						if drop > 6 then
							safe = false
							break
						end
					end

					if safe then
						return true -- ✅ FOUND A GOOD LAND PATH
					end
				end
			end
		end
	end

	-- ❌ after all attempts
	badEggs[target] = true
	return false
end

task.spawn(function()
	while true do
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
		
		task.wait(0.2)
	end
end)

task.spawn(function()
	while true do
		task.wait(10)
		table.clear(badEggs)
	end
end)

local function getClosestEgg()
	local root = getRoot()
	local closest = nil
	local shortest = math.huge

	for _, egg in pairs(workspace:GetChildren()) do
		if isValidEgg(egg) and egg:IsA("BasePart") then
			local dist = (root.Position - egg.Position).Magnitude

			if dist < shortest then
				if isReachable(egg) then -- 🧠 smart filtering
					shortest = dist
					closest = egg
				end
			end
		end
	end

	return closest
end

while true do
	local targetEgg = getClosestEgg()

	if targetEgg then
		local success = moveToTarget(targetEgg)

		-- retry a few times if path fails
		local attempts = 0
		while not success and attempts < 3 do
			task.wait(0.3)
			success = moveToTarget(targetEgg)
			attempts += 1
		end
	end
	
    for index, egg in pairs(game.Workspace:GetChildren()) do
        if egg:GetAttribute("Point") or string.find(egg.Name, "random_potion_egg") or isSpecialEgg(egg.Name) ~= false then
			local identifier
			if not egg:GetAttribute("Point") then
				identifier = "special"
			else
				identifier = "points"
			end
            if not egg:FindFirstChild("Highlight") then
				local points = egg:GetAttribute("Point")

                local highlight = Instance.new("Highlight")
				local pointlight = Instance.new("PointLight")
				pointlight.Parent = egg
				pointlight.Brightness = 1.5
				pointlight.Range = 25
                highlight.Parent = egg

				local billboard = Instance.new("BillboardGui")
				billboard.AlwaysOnTop = true
				billboard.MaxDistance = 1000
				billboard.Size = UDim2.new(0, 100, 0, 40)
				billboard.Parent = egg

				local label = Instance.new("TextLabel")
				label.TextScaled = true
				label.Size = UDim2.new(1, 0, 1, 0)
				label.Position = UDim2.new(0, 0, 0, 0)
				if identifier == "points" then
					label.Text = points.." Points"
					label.TextColor3 = egg:GetAttribute("TextColor")
				else
					if isSpecialEgg(egg.Name) ~= false then
						label.Text = isSpecialEgg(egg.Name)
					else
						label.Text = "Special egg ("..egg.Name..")"
					end
					label.TextColor3 = Color3.fromRGB(255, 0, 0)
				end
				label.BackgroundTransparency = 1
				label.TextStrokeTransparency = 0
				label.Font = Enum.Font.FredokaOne
				label.Parent = billboard

				if identifier == "points" then
					sound:Play()
				else
					if isSpecialEgg(egg.Name) ~= false then
						sound3:Play()
					else
						sound2:Play()
					end
				end
            end
        end
    end
    task.wait(1)
end
