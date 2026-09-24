local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputsTemplate = ReplicatedStorage:WaitForChild("Inputs")

local function SetupPlayerInputs(player)
	if player:FindFirstChild("Inputs") then
		return
	end

	local inputs = InputsTemplate:Clone()
	inputs.Name = "Inputs"
	inputs.Parent = player
end

Players.PlayerAdded:Connect(SetupPlayerInputs)

for _, player in Players:GetPlayers() do
	task.spawn(SetupPlayerInputs, player)
end
