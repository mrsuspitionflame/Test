local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponClass)
	local self = setmetatable({}, ADS)
	self.WeaponClass = WeaponClass
	return self
end

function ADS:Step()
	local Root = self.MovementClass.CombatClasses.Root

	local AimHeld = self.WeaponClass.AimAction:GetState()
	local Aiming = Root:GetAttribute("AimState") == "AIMING"

	if AimHeld and not Aiming then
		self:Held()
	elseif Aiming and not AimHeld then
		self:Released()
	end
end

function ADS:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Aim.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponClass.CombatClasses:CancelState(stateType, state)
		end
	end
end

function ADS:Held()
	if not self:CanAim() then
		return
	end
	self:CancelStates()
	self.WeaponClass.StateManager:SetState("AimState", "AIMING")
end

function ADS:Released()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:Cancelled()
	if self.WeaponClass.StateManager:GetState("AimState") == "AIMING" then
		self.WeaponClass.StateManager:SetState("AimState", "IDLE")
	end
end

function ADS:OnUnequip()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:CanAim()
	return self.WeaponClass.StateManager:TryAction("Weapon", "Aim")
		and self.WeaponClass.CombatClasses.EquippedWeaponClass == self.WeaponClass
	-- Additional conditions for aiming can be added here if needed
end

return ADS
