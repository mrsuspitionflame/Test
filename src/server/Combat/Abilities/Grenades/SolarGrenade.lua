local Combat = script:FindFirstAncestor("Combat")
local Handlers = Combat:WaitForChild("Handlers")

<<<<<<< HEAD
local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local SolarGrenadeEffects = Grenade:WaitForChild("SolarGrenade")
local SolarGrenadeAttachment = SolarGrenadeEffects:WaitForChild("SolarGrenadeAttachment")
=======
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local SolarGrenade = Grenade:WaitForChild("SolarGrenade")

local SolarGrenadeEffect = SolarGrenade:WaitForChild("SolarGrenadeAttachment")
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669

local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))

local Debris = game:GetService("Debris")

local SolarGrenade = {}

SolarGrenade.__index = SolarGrenade

function SolarGrenade.new(AbilityClass)
	local self = setmetatable({}, SolarGrenade)

	self.AbilityClass = AbilityClass
	self.StateManager = AbilityClass.StateManager
<<<<<<< HEAD
	self.ViewModelAnimation = AbilityClass.AnimationController.ViewModelAnimation
	self.GrenadeInfo = AbilityClass.AbilityInfo.GrenadeInfo
	self.Player = AbilityClass.Player

	self.Trove = AbilityClass.Trove:Extend()

	self.CanCast = false
=======
	self.GrenadeInfo = AbilityClass.AbilityInfo.GrenadeInfo
	self.Player = AbilityClass.Player

	self.CanCast = false
	self.CastTrove = self.AbilityClass.Trove:Extend()
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669

	return self
end

function SolarGrenade:Held()
	if not self.StateManager:TryAction("Ability", "Grenade") then
		return
	end

	self.StateManager:PerformAction("Ability", "Grenade")
	self.StateManager:SetState("AbilityState", "USING_GRENADE")

<<<<<<< HEAD
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
=======
	self.CanCast = true

	self:AttachSolarGrenade()
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669
end

function SolarGrenade:Cast(data)
	if self.CanCast == false then
<<<<<<< HEAD
		print("Cant cast")
		return
	end
	self.CanCast = false
=======
		return
	end
	self.CanCast = false

	self.CastTrove:Clean()
	self.CastTrove:Add(task.delay(self.GrenadeInfo.CAST_DURATION, function()
		self:DetachSolarGrenade()
		self.StateManager:SetState("AbilityState", "IDLE")
		self.StateManager:ReEquipWeapon()
	end))
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669

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
<<<<<<< HEAD

function SolarGrenade:Cancelled() end

function SolarGrenade:OnHit(result) end
=======

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
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669

return SolarGrenade
