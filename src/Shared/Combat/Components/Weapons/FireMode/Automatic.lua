local SeedGenerator = Random.new()

local Automatic = {}

Automatic.__index = Automatic

function Automatic.new(WeaponClass)
	local self = setmetatable({}, Automatic)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo
	self.StateManager = WeaponClass.StateManager

	return self
end

function Automatic:Step(dt)
	-- Reset the time between firing when necessary
	-- Detect the type of input here

	if self:CanFire(dt) then
		self:Fire()
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

function Automatic:Fire()
	local ShotType = self.WeaponClass.ShotType

	local Camera = workspace.CurrentCamera

	local Origin = Camera.CFrame
	local Seed = SeedGenerator:NextInteger(0, 2 ^ 31 - 1)

	ShotType:Fire({
		Origin = Origin,
		Seed = Seed,
	})
end

return Automatic
