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
	light.Range = 15
end

while true do
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
