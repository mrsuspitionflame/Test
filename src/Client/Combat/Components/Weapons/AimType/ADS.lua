local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponHandler)
	local self = setmetatable({}, ADS)


	self.WeaponHandler = WeaponHandler

	return self
end

function ADS:Pressed()
	if not self:CanAim() then
		return
	end

	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Pressed",
	})

	self.WeaponHandler.CombatHandler:CancelStates("Weapon", "Aim")
	self.WeaponHandler.StateManager:SetState("AimState", "AIMING")

	self.WeaponHandler.CameraController:ZoomCamera(55)
end

function ADS:Released()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Released",
	})

	self.WeaponHandler.StateManager:SetState("AimState", "IDLE")
	self.WeaponHandler.CameraController:ZoomCamera(80)
end

function ADS:Cancelled()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Cancelled",
	})

	if self.WeaponHandler.StateManager:GetState("AimState") == "AIMING" then
		self.WeaponHandler.StateManager:SetState("AimState", "IDLE")
	end

	self.WeaponHandler.CameraController:ZoomCamera(80)
end

function ADS:OnUnequip()
	PacketSettings.Combat.Weapon.AimRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Released",
	})

	self.WeaponHandler.StateManager:SetState("AimState", "IDLE")
	self.WeaponHandler.CameraController:ZoomCamera(80)
end

function ADS:CanAim()
	return self.WeaponHandler.StateManager:TryAction("Weapon", "Aim")
end

function ADS:OnEquip()
end

return ADS
