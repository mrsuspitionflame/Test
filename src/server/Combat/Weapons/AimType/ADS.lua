local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponClass)
	local self = setmetatable({}, ADS)
	self.WeaponClass = WeaponClass
	return self
end

function ADS:Held()
	if not self:CanAim() then
		return
	end

	self.WeaponClass.StateManager:PerformAction("Weapon", "Aim")
	self.WeaponClass.StateManager:SetState("AimState", "AIMING")
end

function ADS:Released()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:CanAim()
	return self.WeaponClass.StateManager:TryAction("Weapon", "Aim")
end

function ADS:OnUnequip()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

return ADS
