local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local SeedGenerator = Random.new()

local RS = game:GetService("RunService")

local Automatic = {}

Automatic.__index = Automatic

function Automatic.new(WeaponHandler)
	local self = setmetatable({}, Automatic)

	self.WeaponHandler = WeaponHandler
	self.WeaponInfo = WeaponHandler.WeaponInfo

	self.StateManager = WeaponHandler.StateManager

	self.Trove = WeaponHandler.Trove:Extend()

	self.LastTimeFired = workspace:GetServerTimeNow()

	return self
end

function Automatic:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Fire.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponHandler.CombatClasses:CancelState(stateType, state)
		end
	end
end

function Automatic:Cancelled()
	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponHandler.SlotName,
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
		SlotName = self.WeaponHandler.SlotName,
		Action = "Released",
	})

	self.WeaponHandler.StateManager:SetState("WeaponState", "IDLE")

	self.Trove:Clean()
end

function Automatic:Held()
	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Held",
		Origin = Origin,
		Seed = Seed,
	})

	if not self:CanFire() then
		return
	end

	self:CancelStates()
	self.WeaponHandler.StateManager:SetState("WeaponState", "FIRING")

	self.Trove:Clean()
	self.Trove:Connect(RS.Heartbeat, function()
		self:Fire()
	end)
end

function Automatic:CanFire()
	local Now = workspace:GetServerTimeNow()
	local DelayBetweenShots = 60 / self.WeaponInfo.FIRE_RATE

	return self.WeaponHandler.CombatClasses.EquippedWeaponClass == self.WeaponHandler
		and self.WeaponHandler.StateManager:TryAction("Weapon", "Fire")
		and self.WeaponInfo.AMMO > 0
		and Now - self.LastTimeFired >= DelayBetweenShots
end

function Automatic:Fire()
	if not self:CanFire() then
		return
	end

	local ShotType = self.WeaponHandler.ShotType

	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Fire",
		Origin = Origin,
		Seed = Seed,
	})

	self.LastTimeFired = workspace:GetServerTimeNow()

	self.WeaponHandler.Animations.FIRE.VIEWMODEL:Play(0)
	self.WeaponHandler.Animations.FIRE.CHARACTER:Play(0)
	self.WeaponHandler.AnimationController.CameraController:Recoil()

	local Muzzle = self.WeaponHandler.AnimationController.ViewModelController:GetMuzzle()
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
