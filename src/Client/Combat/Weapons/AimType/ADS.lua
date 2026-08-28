local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponController)
	local self = setmetatable({}, ADS)
	self.WeaponController = WeaponController
	return self
end

function ADS:Held()
	if not self:CanAim() then
		return
	end

	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Held",
	})

	self.WeaponController.StateManager:PerformAction("Weapon", "Aim")
	self.WeaponController.StateManager:SetState("AimState", "AIMING")

	self.WeaponController.AnimationController.CameraController:StartAim()
end

function ADS:Released()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Released",
	})

	self.WeaponController.StateManager:SetState("AimState", "IDLE")
	self.WeaponController.AnimationController.CameraController:StopAim()
end

function ADS:OnUnequip()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Released",
	})

	self.WeaponController.StateManager:SetState("AimState", "IDLE")
	self.WeaponController.AnimationController.CameraController:StopAim()
end

function ADS:CanAim()
	return self.WeaponController.StateManager:TryAction("Weapon", "Aim")
end

return ADS
