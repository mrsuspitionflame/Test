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
	self.CombatClasses = AbilityClass.CombatClasses
	self.GrenadeInfo = AbilityClass.AbilityInfo.GrenadeInfo
	self.Player = AbilityClass.Player

	self.CanCast = false
	self.CastTrove = self.AbilityClass.Trove:Extend()

	return self
end

function SolarGrenade:Held()
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if not self.StateManager:TryAction("Ability", "Grenade") then
		return
	end

	self.CombatClasses:TemporarilyUnequipWeapon()
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
		self.CombatClasses:ReEquipStoredWeapon()
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

-- Lifecycle cleanup must not request a weapon equip on a dead character.
function SolarGrenade:Reset()
	self.CanCast = false
	self.CastTrove:Clean()
	self:DetachSolarGrenade()
	self.StateManager:SetState("AbilityState", "IDLE")
end

function SolarGrenade:Cancelled()
	self:Reset()
	self.CombatClasses:ReEquipStoredWeapon()
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
	local attachment = self.SolarGrenadeAttachment
	if not attachment then
		return
	end
	self.SolarGrenadeAttachment = nil

	for _, v in pairs(attachment:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end
	end
	attachment:Destroy()
end

return SolarGrenade
