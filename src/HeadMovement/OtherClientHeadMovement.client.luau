local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

PacketSettings.Character.ApplyHeadMovement.listen(function(data)
	local character = data.Player.Character
	local torso = character and character:FindFirstChild("Torso")
	local neck = torso and torso:FindFirstChild("Neck")

	if neck then
		neck.C0 = data.NeckC0
	end
end)
