local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))
local GrenadeInfo = AbilitySettings.Grenade.SolarGrenade

local Combat = script:FindFirstAncestor("Combat")
local Handlers = Combat:WaitForChild("Handlers")

local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))

local SolarGrenade = {}

function SolarGrenade:Held(data, player)
	print("Held (Server)")

	PacketSettings.Combat.Replicate.ReplicateAbilityEvent.sendToAllExcept({
		AbilityType = "Grenades",
		AbilityName = "SolarGrenade",
		ActionType = "Held",
	}, player)
	return
end

function SolarGrenade:Released(data, player)
	print("Released (Server)")

	local ProjectileID = data.ProjectileID
	local Direction = data.Direction
	local Origin = data.Origin

	print("Simulating projectile")
	SimulateProjectileServer:CreateProjectile({
		Id = ProjectileID,
		Origin = Origin,
		Direction = Direction,
		Speed = GrenadeInfo.SPEED,
		Gravity = Vector3.new(0, GrenadeInfo.GRAVITY, 0),
		Radius = GrenadeInfo.RADIUS,
		MaxDistance = GrenadeInfo.MAX_DISTANCE,
		OnHit = function(result)
			self:OnHit(result)
		end,
		IgnoreList = { player.Character },
		Owner = player,
	})

	PacketSettings.Combat.Replicate.ReplicateAbilityEvent.sendToAllExcept({
		AbilityType = "Grenades",
		AbilityName = "SolarGrenade",
		ActionType = "Released",
		Player = player,
		ProjectileID = ProjectileID,
		Origin = Origin,
		Direction = Direction,
	}, player)
end

function SolarGrenade:Cancelled()
	print("Cancelled")
end

function SolarGrenade:OnHit(result)
	print("Hit on server")
end

return SolarGrenade
