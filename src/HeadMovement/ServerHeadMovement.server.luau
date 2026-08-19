local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

PacketSettings.Character.HeadMovement.listen(function(data, player)
	if typeof(data.NeckC0) ~= "CFrame" then
		return
	end

	PacketSettings.Character.ApplyHeadMovement.sendToAllExcept({
		Player = player,
		NeckC0 = data.NeckC0,
	}, player)
end)
