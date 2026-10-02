local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Gun = {}
Gun.__index = Gun

function Gun.new(WeaponClass)
	return setmetatable({
		WeaponClass = WeaponClass,
	}, Gun)
end

function Gun:CanEquip()
	local WeaponClass = self.WeaponClass
	return WeaponClass.CombatClasses.EquippedSlot == nil and WeaponClass.StateManager:TryAction("Weapon", "Equip")
end

function Gun:CanUnequip()
	local WeaponClass = self.WeaponClass
	return WeaponClass.CombatClasses.EquippedSlot == WeaponClass.SlotName
		and WeaponClass.StateManager:TryAction("Weapon", "UnEquip")
end

function Gun:OnUnequip()
	local WeaponClass = self.WeaponClass
	if not self:CanUnequip() then
		PacketSettings.Combat.Weapon.EquipResult.sendTo({
			Action = "UnEquip",
			SlotName = WeaponClass.SlotName,
			Accepted = false,
		}, WeaponClass.Player)
		return false
	end

	WeaponClass.CombatClasses.EquippedSlot = nil

	WeaponClass.StateManager:SetState("WeaponState", "UNEQUIPPED")

	WeaponClass.Firing:OnUnequip()
	WeaponClass.Reloading:OnUnequip()
	WeaponClass.Aiming:OnUnequip()

	WeaponClass.Trove:Clean()
	PacketSettings.Combat.Weapon.EquipResult.sendTo({
		Action = "UnEquip",
		SlotName = WeaponClass.SlotName,
		Accepted = true,
	}, WeaponClass.Player)
	return true
end

function Gun:OnEquip()
	local WeaponClass = self.WeaponClass
	if not self:CanEquip() then
		PacketSettings.Combat.Weapon.EquipResult.sendTo({
			Action = "Equip",
			SlotName = WeaponClass.SlotName,
			Accepted = false,
		}, WeaponClass.Player)
		return
	end

	WeaponClass.CombatClasses.EquippedSlot = WeaponClass.SlotName
	WeaponClass.StateManager:SetState("WeaponState", "EQUIPPING")

	local Attached, AttachError = pcall(function()
		WeaponClass:AttachWeaponModel()
	end)
	if not Attached then
		WeaponClass.Trove:Clean()
		WeaponClass.CombatClasses.EquippedSlot = nil
		WeaponClass.StateManager:SetState("WeaponState", "UNEQUIPPED")
		warn("Weapon equip setup failed:", AttachError)
		PacketSettings.Combat.Weapon.EquipResult.sendTo({
			Action = "Equip",
			SlotName = WeaponClass.SlotName,
			Accepted = false,
		}, WeaponClass.Player)
		return false
	end

	local EquipSpeed = 1 + (WeaponClass.WeaponInfo.HANDLING - 50) / 100

	WeaponClass.Trove:Add(task.delay(WeaponClass.WeaponInfo.EQUIP_DURATION / EquipSpeed, function()
		if WeaponClass.StateManager:GetState("WeaponState") ~= "EQUIPPING" then
			return
		end

		WeaponClass.StateManager:SetState("WeaponState", "IDLE")
	end))
	-- Confirm only after the model and equip timing have been initialized.
	PacketSettings.Combat.Weapon.EquipResult.sendTo({
		Action = "Equip",
		SlotName = WeaponClass.SlotName,
		Accepted = true,
	}, WeaponClass.Player)
	return true
end

return Gun
