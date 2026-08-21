local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Client = script:FindFirstAncestor("Client")
local Visuals = Client:WaitForChild("Visuals")

local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local Hit = Grenade:WaitForChild("Hit")
local Projectile = Grenade:WaitForChild("Projectile")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))
local GrenadeInfo = AbilitySettings.Grenade.SolarGrenade

local SimulateProjectileClient = require(Visuals:WaitForChild("SimulateProjectile(Client)"))

local SolarGrenade = {}

function SolarGrenade:Held(data, replicate)
	print("Held")
	if not replicate then
		PacketSettings.Combat.Ability.Grenade.GrenadeHeld.send({})
	end
	return
end

function SolarGrenade:Released(data, replicate)
	print("Released")
	local projectile = Projectile:Clone()
	projectile.Parent = workspace

	SimulateProjectileClient:CreateProjectile({
		Id = data.ProjectileID,
		Origin = data.Origin,
		Direction = data.Direction,
		Speed = GrenadeInfo.SPEED,
		Gravity = Vector3.new(0, GrenadeInfo.GRAVITY, 0),
		Radius = GrenadeInfo.RADIUS,
		MaxDistance = GrenadeInfo.MAX_DISTANCE,
		Projectile = projectile,
		OnHit = function(result)
			self:OnHit(result)
		end,
		IgnoreList = { data.Player.Character, workspace.CurrentCamera },
	})

	if not replicate then
		PacketSettings.Combat.Ability.Grenade.GrenadeReleased.send({
			Origin = data.Origin,
			Direction = data.Direction,
			ProjectileID = data.ProjectileID,
		})
	end
end

function SolarGrenade:Cancelled()
	print("Cancelled")
end

function SolarGrenade:OnHit(result)
	local hit = Hit:Clone()
	hit.CFrame = CFrame.lookAlong(result.Position, result.Normal)
	hit.Position = result.Position
	hit.Parent = workspace

	Debris:AddItem(hit, GrenadeInfo.LAST_DURATION)
end

return SolarGrenade
