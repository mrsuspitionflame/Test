local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local RaycastService = require(Utility:WaitForChild("RaycastService"))

local ReplicateRayCast = {}

function ReplicateRayCast:Init()
	PacketSettings.Combat.Replicate.ReplicateShotEvent.listen(function(data)
		RaycastService:DrawRayResults(data.RayOrigin, data.RayResults)
	end)
end

return ReplicateRayCast
