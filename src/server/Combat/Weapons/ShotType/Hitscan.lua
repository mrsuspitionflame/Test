local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Utility = Shared:WaitForChild("Utility")
local RaycastService = require(Utility:WaitForChild("RaycastService"))

local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Hitscan = {}

Hitscan.__index = Hitscan

function Hitscan.new(WeaponClass)
	local self = setmetatable({}, Hitscan)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo

	return self
end

function Hitscan:Fire(data)
	local Origin = data.Origin
	local Seed = data.Seed

	local rayDirections
	if self.WeaponClass.StateManager:GetState("AimState") == "AIMING" then
		rayDirections = RaycastService:GetRayDirections(
			Origin,
			self.WeaponInfo.BULLETS_PER_SHOT,
			0,
			Seed,
			self.WeaponInfo.RANGE * 10
		)
	else
		rayDirections = RaycastService:GetRayDirections(
			Origin,
			self.WeaponInfo.BULLETS_PER_SHOT,
			math.rad(self.WeaponInfo.SPREAD),
			Seed,
			self.WeaponInfo.RANGE * 10
		)
	end

	local ignoreList = {
		self.WeaponClass.Player.Character,
	}

	local rayResults =
		RaycastService:CastRays(Origin.Position, rayDirections, ignoreList, self.WeaponInfo.BULLET_RADIUS)

	for _, rayResult in rayResults do
		local hitInstance = rayResult.Instance

		if not hitInstance then
			continue
		end

		local character = hitInstance:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		humanoid:TakeDamage(self.WeaponInfo.DAMAGE)
	end

	local RayOrigin = self.WeaponClass.RayOrigin.WorldPosition

	PacketSettings.Combat.Replicate.ReplicateShotEvent.sendToAllExcept({
		RayOrigin = RayOrigin,
		RayResults = rayResults,
	}, self.WeaponClass.Player)
end

return Hitscan
