local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Utility = Shared:WaitForChild("Utility")
local RaycastService = require(Utility:WaitForChild("RaycastService"))

local Hitscan = {}

Hitscan.__index = Hitscan

function Hitscan.new(WeaponHandler)
	local self = setmetatable({}, Hitscan)

	self.WeaponHandler = WeaponHandler
	self.WeaponInfo = WeaponHandler.WeaponInfo

	return self
end

function Hitscan:Fire(ShotData)
	local Origin = ShotData.Origin
	local Seed = ShotData.Seed

	local rayDirections

	local BulletsPerShot = self.WeaponInfo.BULLETS_PER_SHOT
	local Range = self.WeaponInfo.RANGE
	local Spread = self.WeaponInfo.SPREAD

	if self.WeaponHandler.StateManager:GetState("AimState") == "AIMING" then
		rayDirections = RaycastService:GetRayDirections(Origin, BulletsPerShot, 0, Seed, Range * 10)
	else
		rayDirections = RaycastService:GetRayDirections(Origin, BulletsPerShot, math.rad(Spread), Seed, Range * 10)
	end

	local ignoreList = {
		workspace.CurrentCamera,
		game.Players.LocalPlayer.Character,
	}

	local rayResults =
		RaycastService:CastRays(Origin.Position, rayDirections, ignoreList, self.WeaponInfo.BULLET_RADIUS)
	local rayOrigin = self.WeaponHandler.AnimationController.ViewModelController:GetRayOrigin()

	RaycastService:DrawRayResults(rayOrigin, rayResults)
end

return Hitscan
