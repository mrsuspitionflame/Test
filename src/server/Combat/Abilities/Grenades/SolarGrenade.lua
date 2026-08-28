local Combat = script:FindFirstAncestor("Combat")
local Handlers = Combat:WaitForChild("Handlers")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local SolarGrenade = Grenade:WaitForChild("SolarGrenade")

local SolarGrenadeEffect = SolarGrenade:WaitForChild("SolarGrenadeAttachment")

local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))

local SolarGrenade = {}

SolarGrenade.__index = SolarGrenade

function SolarGrenade.new(AbilityClass)
	local self = setmetatable({}, SolarGrenade)

	self.AbilityClass = AbilityClass
	self.StateManager = AbilityClass.StateManager
	self.GrenadeInfo = AbilityClass.AbilityInfo.GrenadeInfo
	self.Player = AbilityClass.Player

	self.CanCast = false
	self.CastTrove = self.AbilityClass.Trove:Extend()

	return self
end

function SolarGrenade:Held()
	if not self.StateManager:TryAction("Ability", "Grenade") then
		return
	end

	self.StateManager:PerformAction("Ability", "Grenade")
	self.StateManager:SetState("AbilityState", "USING_GRENADE")

	self.CanCast = true

	self:AttachSolarGrenade()
end

function SolarGrenade:Cast(data)
	if self.CanCast == false then
		return
	end
	self.CanCast = false

	self.CastTrove:Clean()
	self.CastTrove:Add(task.delay(self.GrenadeInfo.CAST_DURATION, function()
		self:DetachSolarGrenade()
		self.StateManager:SetState("AbilityState", "IDLE")
		self.StateManager:ReEquipWeapon()
	end))

	SimulateProjectileServer:CreateProjectile({
		Id = data.ProjectileId,
		Origin = data.Origin,
		Direction = data.Direction,
		Speed = self.GrenadeInfo.SPEED,
		Gravity = Vector3.new(0, self.GrenadeInfo.GRAVITY, 0),
		Radius = self.GrenadeInfo.RADIUS,
		MaxDistance = self.GrenadeInfo.MAX_DISTANCE,
		OnHit = function(result)
			self:OnHit(result)
		end,
		IgnoreList = { self.Player.Character },
	})
end

function SolarGrenade:Released() end

function SolarGrenade:Cancelled()
	self.CanCast = false
	self.StateManager:SetState("AbilityState", "IDLE")
	self.StateManager:ReEquipWeapon()
end

function SolarGrenade:OnHit(result) end

function SolarGrenade:AttachSolarGrenade()
	local LeftArm = self.Player.Character:FindFirstChild("Left Arm", true)

	local AbilityGripAttachment = LeftArm:WaitForChild("AbilityGripAttachment")
	self.SolarGrenadeAttachment = SolarGrenadeEffect:Clone()

	self.SolarGrenadeAttachment.Parent = LeftArm
	self.SolarGrenadeAttachment.WorldCFrame = AbilityGripAttachment.WorldCFrame

	for _, v in pairs(self.SolarGrenadeAttachment:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end
end

function SolarGrenade:DetachSolarGrenade()
	for _, v in pairs(self.SolarGrenadeAttachment:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end
	end
	if self.SolarGrenadeAttachment then
		self.SolarGrenadeAttachment:Destroy()
		self.SolarGrenadeAttachment = nil
	end
end

return SolarGrenade
