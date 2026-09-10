local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local StateSettings = require(Settings:WaitForChild("StateSettings"))

local SeedGenerator = Random.new()

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
end

function Automatic:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Fire.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponClass.CombatClasses:CancelState(stateType, state)
		end
	end
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

function Automatic:Released()
	self.WeaponClass.StateManager:SetState("WeaponState", "IDLE")
end

function Automatic:Held()
	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	if not self:CanFire() then
		return
	end

	self:CancelStates()
	self.WeaponClass.StateManager:SetState("WeaponState", "FIRING")
end

function Automatic:CanFire(dt)
	local Now = workspace:GetServerTimeNow()
	local DelayBetweenShots = 60 / self.WeaponInfo.FIRE_RATE

	return self.WeaponClass.CombatClasses.EquippedWeaponClass == self.WeaponClass
		and self.WeaponClass.StateManager:TryAction("Weapon", "Fire")
		and self.WeaponInfo.AMMO > 0
		and Now - self.LastTimeFired >= DelayBetweenShots
end

function Automatic:TestFunction() end

function Automatic:Fire()
	if not self:CanFire() then
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

return Automatic
