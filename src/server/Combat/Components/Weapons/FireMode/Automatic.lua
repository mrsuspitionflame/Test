local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local RS = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local StateSettings = require(Settings:WaitForChild("StateSettings"))
local Validation = require(Utility:WaitForChild("Validation"))

local Automatic = {}

Automatic.__index = Automatic

local MAX_JITTER_TOLERANCE = 0.02
local JITTER_TOLERANCE_RATIO = 0.3

function Automatic.new(WeaponClass)
	local self = setmetatable({}, Automatic)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo

	self.StateManager = WeaponClass.StateManager

	self.Trove = Trove.new()

	self.NextFireTime = 0

	return self
end

function Automatic:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Fire.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponClass.CombatClasses:CancelState(stateType, state)
		end
	end
end

function Automatic:Cancelled()
	self.Trove:Clean()

	if self.StateManager:GetState("WeaponState") == "FIRING" then
		self.StateManager:SetState("WeaponState", "IDLE")
	end
end

function Automatic:OnUnequip()
	self.Trove:Clean()
	self.NextFireTime = 0
end

function Automatic:Destroy()
	self.Trove:Destroy()
end

function Automatic:Pressed(data)
	if not self:CanFire(data) then
		return
	end
	self:CancelStates()
	self.StateManager:SetState("WeaponState", "FIRING")
end

function Automatic:Released()
	self.StateManager:SetState("WeaponState", "IDLE")
end

function Automatic:CanFire(data)
	local character = self.WeaponClass.Player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local validOrigin = Validation.ValidateCFrame(data.Origin)

	local validSeed = Validation.ValidateInteger(data.Seed) and data.Seed >= 0 and data.Seed <= 2 ^ 31 - 1

	local Now = workspace:GetServerTimeNow()
	local FireInterval = 60 / self.WeaponInfo.FIRE_RATE
	local JitterTolerance = math.min(MAX_JITTER_TOLERANCE, FireInterval * JITTER_TOLERANCE_RATIO)
	local FireTimingValid = self.NextFireTime == 0 or Now + JitterTolerance >= self.NextFireTime

	local CanFire = self.WeaponClass.CombatClasses.EquippedSlot == self.WeaponClass.SlotName
		and head ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and self.WeaponClass.Ammo > 0
		and validOrigin
		and validSeed
		and (data.Origin.Position - head.Position).Magnitude <= 15
		and FireTimingValid
		and self.StateManager:TryAction("Weapon", "Fire")

	return CanFire, Now, FireInterval
end

function Automatic:AdvanceFireSchedule(Now, FireInterval)
	if self.NextFireTime == 0 or Now > self.NextFireTime + FireInterval then
		self.NextFireTime = Now + FireInterval
	else
		self.NextFireTime += FireInterval
	end
end

function Automatic:Fire(data)
	local CanFire, Now, FireInterval = self:CanFire(data)

	if not CanFire then
		return
	end

	self:AdvanceFireSchedule(Now, FireInterval)
	self.WeaponClass.Ammo -= 1

	PacketSettings.Combat.Weapon.AmmoUpdate.sendTo({
		SlotName = self.WeaponClass.SlotName,
		Ammo = self.WeaponClass.Ammo,
	}, self.WeaponClass.Player)

	local Muzzle = self.WeaponClass.Muzzle
	if Muzzle then
		Muzzle.FlashEmitter:Emit(1)
		Muzzle.CircleEmitter:Emit(1)
	end

	self.WeaponClass.ShotType:Fire(data)
end

return Automatic
