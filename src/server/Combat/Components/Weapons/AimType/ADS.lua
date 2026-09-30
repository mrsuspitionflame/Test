local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local StateSettings = require(Settings:WaitForChild("StateSettings"))
local Trove = require(Packages:WaitForChild("Trove"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponClass)
	local self = setmetatable({}, ADS)
	self.WeaponClass = WeaponClass
	self.AimTrove = Trove.new()
	return self
end

function ADS:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Aim.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponClass.CombatClasses:CancelState(stateType, state)
		end
	end
end

function ADS:Pressed()
	if not self:CanAim() then
		return
	end

	self:CancelStates()
	self.WeaponClass.StateManager:SetState("AimState", "AIMING")
end

function ADS:CanAim()
	return self.WeaponClass.StateManager:TryAction("Weapon", "Aim")
end

function ADS:Released()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:Cancelled()
	self.AimTrove:Clean()

	if self.WeaponClass.StateManager:GetState("AimState") == "AIMING" then
		self.WeaponClass.StateManager:SetState("AimState", "IDLE")
	end
end

function ADS:OnUnequip()
	self.AimTrove:Clean()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:Destroy()
	self.AimTrove:Destroy()
end

return ADS
