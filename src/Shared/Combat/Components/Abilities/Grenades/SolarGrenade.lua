local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HTTPService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local Client = script:FindFirstAncestor("Client")
local Visuals = Client:WaitForChild("Visuals")

local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local SolarGrenadeEffects = Grenade:WaitForChild("SolarGrenade")
local Hit = SolarGrenadeEffects:WaitForChild("Hit")
local Projectile = SolarGrenadeEffects:WaitForChild("Projectile")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local SimulateProjectileClient = require(Visuals:WaitForChild("SimulateProjectile(Client)"))

local SolarGrenade = {}

SolarGrenade.__index = SolarGrenade

function SolarGrenade.new(AbilityHandler)
	local self = setmetatable({}, SolarGrenade)

	self.AbilityHandler = AbilityHandler
	self.StateManager = AbilityHandler.StateManager
	self.GrenadeInfo = self.AbilityHandler.AbilityInfo.GrenadeInfo

	self.Trove = self.AbilityHandler.Trove:Extend()

	return self
end

function SolarGrenade:Held()
	if not self.AbilityHandler.StateManager:TryAction("Ability", "Grenade") then
		return
	end

	PacketSettings.Combat.Ability.GrenadeRequest.send({
		Action = "Held",
	})

	self.StateManager:SetState("AbilityState", "USING_GRENADE")

	local Animations = self.AbilityHandler.Animations
	local GrenadeCharacterAnimation = Animations.Grenade.HELD.CHARACTER

	self.Trove:Add(GrenadeCharacterAnimation:GetMarkerReachedSignal("CastSolarGrenade"):Connect(function()
		self:Cast()
	end))

	self.Trove:Add(GrenadeCharacterAnimation.Stopped:Connect(function()
		self.StateManager:SetState("AbilityState", "IDLE")
		self.Trove:Clean()
	end))

	GrenadeCharacterAnimation:Play(0)
end

function SolarGrenade:Cast()
	local ProjectileID = HTTPService:GenerateGUID(false)
	local Direction = workspace.CurrentCamera.CFrame.LookVector
	local Origin = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * -1

	PacketSettings.Combat.Ability.GrenadeRequest.send({
		Action = "Cast",
		Origin = Origin,
		Direction = Direction,
		ProjectileId = ProjectileID,
	})

	local projectile = Projectile:Clone()
	projectile.Parent = workspace

	SimulateProjectileClient:CreateProjectile({
		Id = ProjectileID,
		Origin = Origin,
		Direction = Direction,
		Speed = self.GrenadeInfo.SPEED,
		Gravity = Vector3.new(0, self.GrenadeInfo.GRAVITY, 0),
		Radius = self.GrenadeInfo.RADIUS,
		MaxDistance = self.GrenadeInfo.MAX_DISTANCE,
		Projectile = projectile,
		OnHit = function(result)
			self:OnHit(result)
		end,
		IgnoreList = { Player.Character, workspace.CurrentCamera },
	})
end

function SolarGrenade:Released() end

function SolarGrenade:Cancelled() end

function SolarGrenade:SetEmitterTransparency(part)
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end
end

function SolarGrenade:OnHit(result)
	local hit = Hit:Clone()
	hit.CFrame = CFrame.lookAlong(result.Position, result.Normal)
	hit.Position = result.Position
	hit.Parent = workspace

	task.delay(self.GrenadeInfo.LAST_DURATION, function()
		self:SetEmitterTransparency(hit)
		Debris:AddItem(hit, 1)
	end)
end

return SolarGrenade
