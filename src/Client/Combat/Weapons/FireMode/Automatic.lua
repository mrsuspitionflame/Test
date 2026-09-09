local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local SeedGenerator = Random.new()

local RS = game:GetService("RunService")

local Automatic = {}

Automatic.__index = Automatic

function Automatic.new(WeaponController)
	local self = setmetatable({}, Automatic)

	self.WeaponController = WeaponController
	self.WeaponInfo = WeaponController.WeaponInfo

	self.StateManager = WeaponController.StateManager

	self.Trove = WeaponController.Trove:Extend()

	self.LastTimeFired = workspace:GetServerTimeNow()

	return self
end

function Automatic:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Fire.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponController.CombatClasses:CancelState(stateType, state)
		end
	end
end

function Automatic:Cancelled()
	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Cancelled",
	})

	if self.StateManager:GetState("WeaponState") == "FIRING" then
		self.StateManager:SetState("WeaponState", "IDLE")
	end

	self.Trove:Clean()
end

function Automatic:OnUnequip()
	self.Trove:Clean()
end

function Automatic:Released()
	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Released",
	})

	self.WeaponController.StateManager:SetState("WeaponState", "IDLE")

	self.Trove:Clean()
end

function Automatic:Held()
	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Held",
		Origin = Origin,
		Seed = Seed,
	})

	if not self:CanFire() then
		return
	end

	self:CancelStates()
	self.WeaponController.StateManager:SetState("WeaponState", "FIRING")

	self.Trove:Clean()
	self.Trove:Connect(RS.Heartbeat, function()
		self:Fire()
	end)
end

function Automatic:CanFire()
	local Now = workspace:GetServerTimeNow()
	local DelayBetweenShots = 60 / self.WeaponInfo.FIRE_RATE

	return self.WeaponController.Equipped
		and self.WeaponController.StateManager:TryAction("Weapon", "Fire")
		and self.WeaponInfo.AMMO > 0
		and Now - self.LastTimeFired >= DelayBetweenShots
end

function Automatic:Fire()
	if not self:CanFire() then
		return
	end

	local ShotType = self.WeaponController.ShotType

	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Fire",
		Origin = Origin,
		Seed = Seed,
	})

	self.LastTimeFired = workspace:GetServerTimeNow()

	self.WeaponController.Animations.FIRE.VIEWMODEL:Play(0)
	self.WeaponController.Animations.FIRE.CHARACTER:Play(0)
	self.WeaponController.AnimationController.CameraController:Recoil()

	local Muzzle = self.WeaponController.AnimationController.ViewModelController:GetMuzzle()
	if Muzzle then
		local FlashEmitter = Muzzle:FindFirstChild("FlashEmitter")
		local CircleEmitter = Muzzle:FindFirstChild("CircleEmitter")

		if FlashEmitter then
			FlashEmitter:Emit(1)
		end
		if CircleEmitter then
			CircleEmitter:Emit(1)
		end
	end

	ShotType:Fire({
		Origin = Origin,
		Seed = Seed,
	})
end

return Automatic
