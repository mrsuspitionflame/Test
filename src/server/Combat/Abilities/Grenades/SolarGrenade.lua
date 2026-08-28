local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))
local GrenadeInfo = AbilitySettings.Grenade.SolarGrenade

local Combat = script:FindFirstAncestor("Combat")
local Handlers = Combat:WaitForChild("Handlers")

local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local SolarGrenadeEffects = Grenade:WaitForChild("SolarGrenade")
local SolarGrenadeAttachment = SolarGrenadeEffects:WaitForChild("SolarGrenadeAttachment")

local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))

local Debris = game:GetService("Debris")

local SolarGrenade = {}

SolarGrenade.__index = SolarGrenade

function SolarGrenade.new(AbilityClass)
	local self = setmetatable({}, SolarGrenade)

	self.AbilityClass = AbilityClass
	self.StateManager = AbilityClass.StateManager
	self.ViewModelAnimation = AbilityClass.AnimationController.ViewModelAnimation
	self.GrenadeInfo = AbilityClass.AbilityInfo.GrenadeInfo
	self.Player = AbilityClass.Player

	self.Trove = AbilityClass.Trove:Extend()

	self.CanCast = false

	return self
end

function SolarGrenade:Held()
	if not self.StateManager:TryAction("Ability", "Grenade") then
		return
	end

	self.StateManager:PerformAction("Ability", "Grenade")
	self.StateManager:SetState("AbilityState", "USING_GRENADE")

	self:SetRightArmTransparency(1)

	local Animations = self.AbilityClass.Animations
	local GrenadeHeldAnimation = Animations.Grenade.Held

	self.ViewModelAnimation:HideArms(self.ViewModelAnimation.AbilityViewModel:FindFirstChild("Left Arm"), nil)
	self.ViewModelAnimation:ShowAbilityViewModel()
	self.CanCast = true
	self:AttachSolarGrenade()

	self.Trove:Add(GrenadeHeldAnimation:GetMarkerReachedSignal("CastSolarGrenade"):Connect(function()
		self:DetachSolarGrenade()
	end))

	self.Trove:Add(GrenadeHeldAnimation.Stopped:Connect(function()
		self.StateManager:SetState("AbilityState", "IDLE")
		self:SetRightArmTransparency(0)
		self:DetachSolarGrenade()
		self.ViewModelAnimation:SetArmsTransparency(0)
		self.ViewModelAnimation:HideAbilityViewModel()
		self.StateManager:ReEquipWeapon()
		self.Trove:Clean()
	end))

	GrenadeHeldAnimation:Play(0)
end

function SolarGrenade:SetRightArmTransparency(transparency)
	local RightArm = self.ViewModelAnimation.AbilityViewModel:FindFirstChild("Right Arm")

	if RightArm then
		RightArm.Transparency = transparency
	end
end

function SolarGrenade:AttachSolarGrenade()
	local LeftArm = self.ViewModelAnimation.AbilityViewModel:FindFirstChild("Left Arm")
	local LeftGripAttachment = LeftArm:FindFirstChild("LeftGripAttachment")

	if LeftGripAttachment then
		local solarGrenade = SolarGrenadeAttachment:Clone()
		solarGrenade.Parent = LeftArm
		solarGrenade.WorldCFrame = LeftGripAttachment.WorldCFrame

		for _, descendant in solarGrenade:GetDescendants() do
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = true
			end
		end
	end
end

function SolarGrenade:DetachSolarGrenade()
	local LeftArm = self.ViewModelAnimation.AbilityViewModel:FindFirstChild("Left Arm")

	if LeftArm:FindFirstChild("SolarGrenadeAttachment") then
		local solarGrenade = LeftArm:FindFirstChild("SolarGrenadeAttachment")
		for _, descendant in solarGrenade:GetDescendants() do
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
		Debris:AddItem(solarGrenade, 1)
	end
end

function SolarGrenade:Cast(data)
	if self.CanCast == false then
		print("Cant cast")
		return
	end
	self.CanCast = false

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

function SolarGrenade:Cancelled() end

function SolarGrenade:OnHit(result) end

return SolarGrenade
