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

function ADS:Pressed()
	if not self:CanAim() then
		return
	end

	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Pressed",
	})

	self.WeaponController.CombatController:CancelStates("Weapon", "Aim")
	self.WeaponController.StateManager:SetState("AimState", "AIMING")

	self.WeaponController.CameraController:ZoomCamera(55)
end

function ADS:Released()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Released",
	})

	self.WeaponController.StateManager:SetState("AimState", "IDLE")
	self.WeaponController.CameraController:ZoomCamera(80)
end

function ADS:Cancelled()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Cancelled",
	})

	if self.WeaponController.StateManager:GetState("AimState") == "AIMING" then
		self.WeaponController.StateManager:SetState("AimState", "IDLE")
	end

	self.WeaponController.CameraController:ZoomCamera(80)
end

function ADS:OnUnequip()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Released",
	})

	self.WeaponController.StateManager:SetState("AimState", "IDLE")
	self.WeaponController.CameraController:ZoomCamera(80)
end

function ADS:CanAim()
	return self.WeaponController.StateManager:TryAction("Weapon", "Aim")
end

function ADS:OnEquip()
end

return ADS
