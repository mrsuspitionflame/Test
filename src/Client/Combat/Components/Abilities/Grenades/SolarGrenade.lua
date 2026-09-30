local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HTTPService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local Visuals = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Visuals")

local Effects = ReplicatedStorage:WaitForChild("Effects")
local Abilities = Effects:WaitForChild("Abilities")
local Grenade = Abilities:WaitForChild("Grenade")
local SolarGrenadeEffects = Grenade:WaitForChild("SolarGrenade")
local Hit = SolarGrenadeEffects:WaitForChild("Hit")
local Projectile = SolarGrenadeEffects:WaitForChild("Projectile")
local SolarGrenadeAttachment = SolarGrenadeEffects:WaitForChild("SolarGrenadeAttachment")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local SimulateProjectileClient = require(Visuals:WaitForChild("SimulateProjectile(Client)"))

local SolarGrenade = {}

SolarGrenade.__index = SolarGrenade

function SolarGrenade.new(AbilityController)
	local self = setmetatable({}, SolarGrenade)

	self.AbilityController = AbilityController
	self.StateManager = AbilityController.StateManager
	self.ViewModelController = AbilityController.AnimationController.ViewModelController
	self.GrenadeInfo = self.AbilityController.AbilityInfo.GrenadeInfo

	self.Trove = self.AbilityController.Trove:Extend()

	self:Init()
	return self
end

function SolarGrenade:Pressed()
	if not self.AbilityController.StateManager:TryAction("Ability", "Grenade") then
		return
	end

	PacketSettings.Combat.Ability.GrenadeRequest.send({
		Action = "Pressed",
	})

	self.StateManager:SetState("AbilityState", "USING_GRENADE")

	local Animations = self.AbilityController.Animations
	local GrenadeHeldAnimation = Animations.Grenade.HELD.VIEWMODEL
	local GrenadeCharacterAnimation = Animations.Grenade.HELD.CHARACTER

	self.ViewModelController:ShowAbilityViewModel()
	self:AttachSolarGrenade()

	self.Trove:Add(GrenadeHeldAnimation:GetMarkerReachedSignal("CastSolarGrenade"):Connect(function()
		self:Cast()
		self:DetachSolarGrenade()
	end))

	self.Trove:Add(GrenadeHeldAnimation.Stopped:Connect(function()
		self.StateManager:SetState("AbilityState", "IDLE")
		self:DetachSolarGrenade()
		self.ViewModelController:HideAbilityViewModel()
		self.Trove:Clean()
	end))

	GrenadeHeldAnimation:Play(0)
	GrenadeCharacterAnimation:Play(0)
end

function SolarGrenade:AttachSolarGrenade()
	local LeftArm = self.ViewModelController.AbilityViewModel:FindFirstChild("Left Arm")
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
	local LeftArm = self.ViewModelController.AbilityViewModel:FindFirstChild("Left Arm")

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

function SolarGrenade:Init()
	local Inputs = self.WeaponController.Inputs
	if not Inputs then
		warn("Inputs not found for WeaponController")
		return
	end

	local AbilityContext = Inputs:WaitForChild("AbilityContext")
	if not AbilityContext then
		warn("AbilityContext not found for Inputs")
		return
	end

	local GrenadeAction = AbilityContext:WaitForChild("GrenadeAction")

	if not GrenadeAction then
		warn("Grenade action not found for slot: " .. self.WeaponController.SlotName)
		return
	end

	self.Trove:Add(GrenadeAction.Pressed:Connect(function()
		self:Pressed()
	end))
end

return SolarGrenade
