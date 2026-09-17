local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponHandler)
	local self = setmetatable({}, ADS)
	self.WeaponHandler = WeaponHandler
	return self
end

function ADS:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Aim.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponHandler.CombatClasses:CancelState(stateType, state)
		end
	end
end

function ADS:Held()
	if not self:CanAim() then
		return
	end

	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Held",
	})

	self:CancelStates()
	self.WeaponHandler.StateManager:SetState("AimState", "AIMING")

	self.WeaponHandler.AnimationHandler.CameraHandler:StartAim()
end

function ADS:Released()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Released",
	})

	self.WeaponHandler.StateManager:SetState("AimState", "IDLE")
	self.WeaponHandler.AnimationHandler.CameraHandler:StopAim()
end

function ADS:Cancelled()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Cancelled",
	})

	if self.WeaponHandler.StateManager:GetState("AimState") == "AIMING" then
		self.WeaponHandler.StateManager:SetState("AimState", "IDLE")
	end

	self.WeaponHandler.AnimationHandler.CameraHandler:StopAim()
end

function ADS:OnUnequip()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Released",
	})

	self.WeaponHandler.StateManager:SetState("AimState", "IDLE")
	self.WeaponHandler.AnimationHandler.CameraHandler:StopAim()
end

function ADS:CanAim()
	return self.WeaponHandler.StateManager:TryAction("Weapon", "Aim")
end

return ADS
