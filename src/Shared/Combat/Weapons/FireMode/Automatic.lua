local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local StateSettings = require(Settings:WaitForChild("StateSettings"))

local SeedGenerator = Random.new()

local TimeBetweenShots = 0

local Automatic = {}

Automatic.__index = Automatic

function Automatic.new(WeaponClass)
	local self = setmetatable({}, Automatic)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo
	self.StateManager = WeaponClass.StateManager

	self.LastTimeFired = workspace:GetServerTimeNow()

	return self
end

function Automatic:Step()
	local Root = self.MovementClass.CombatClasses.Root

	local FireHeld = self.WeaponClass.FireAction:GetState()
	local Firing = Root:GetAttribute("WeaponState") == "FIRING"

	if not FireHeld or not Firing then
		return
	end
end

function Automatic:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Fire.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponClass.CombatClasses:CancelState(stateType, state)
		end
	end
end

function Automatic:CanFire(dt)
	local Root = self.MovementClass.CombatClasses.Root

	local FireHeld = self.WeaponClass.FireAction:GetState()
	local Firing = Root:GetAttribute("WeaponState") == "FIRING"
	local TimeBetweenFiring = Root:GetAttribute("TimeBetweenFiring")

	TimeBetweenFiring = TimeBetweenFiring + dt
	Root:SetAttribute("TimeBetweenFiring", TimeBetweenFiring)

	return self.WeaponClass.CombatClasses.EquippedWeaponClass == self.WeaponClass
		and FireHeld
		and Firing
		and self.WeaponClass.StateManager:TryAction("Weapon", "Fire")
		and self.WeaponInfo.AMMO > 0
		and TimeBetweenFiring >= 60 / self.WeaponInfo.FIRE_RATE
end

function Automatic:Fire(dt)
	if not self:CanFire(dt) then
		return
	end

	local ShotType = self.WeaponClass.ShotType

	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	self.LastTimeFired = workspace:GetServerTimeNow()

	ShotType:Fire({
		Origin = Origin,
		Seed = Seed,
	})
end

function Automatic:Cancelled()
	if self.StateManager:GetState("WeaponState") == "FIRING" then
		self.StateManager:SetState("WeaponState", "IDLE")
	end
end

function Automatic:OnUnequip()
	if self.StateManager:GetState("WeaponState") == "FIRING" then
		self.StateManager:SetState("WeaponState", "IDLE")
	end
end

return Automatic
