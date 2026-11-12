local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Gun = {}

Gun.__index = Gun

function Gun.new(WeaponController)
	local self = setmetatable({}, Gun)

	self.WeaponController = WeaponController

	return self
end

function Gun:OnEquip()
	local WeaponController = self.WeaponController
	local CombatController = WeaponController.CombatController
	-- Apply the server's decision; local combat restrictions may differ.
	if CombatController.EquippedSlot == WeaponController.SlotName then
		return
	end
	local PreviousWeapon = CombatController:GetEquippedWeapon()
	if PreviousWeapon then
		PreviousWeapon.Equipping:OnUnequip()
	end

	WeaponController.CombatController:CancelStates("Weapon", "Equip")
	WeaponController.StateManager:SetState("WeaponState", "EQUIPPING")

	UIS.MouseIconEnabled = false

	WeaponController.CombatController.EquippedSlot = WeaponController.SlotName

	WeaponController.GUIController:EquippedSlotChanged(WeaponController.SlotName)
	WeaponController.ViewModelController:OnEquip(WeaponController.WeaponInfo)
	WeaponController:GetAnimations()
	local Animations = WeaponController.Animations

	Animations.IDLE.VIEWMODEL.Looped = true
	Animations.IDLE.CHARACTER.Looped = true

	Animations.IDLE.VIEWMODEL:Play(0.15, 1, 0.1)
	Animations.IDLE.CHARACTER:Play(0.15, 1, 0.1)

	local EquipSpeed = 1 + (WeaponController.WeaponInfo.HANDLING - 50) / 100
	Animations.EQUIP.VIEWMODEL:Play(0, 1, EquipSpeed)
	Animations.EQUIP.CHARACTER:Play(0, 1, EquipSpeed)

	WeaponController.EquippedTrove:Add(task.delay(WeaponController.WeaponInfo.EQUIP_DURATION / EquipSpeed, function()
		WeaponController.EquipTask = nil
		if WeaponController.StateManager:GetState("WeaponState") ~= "EQUIPPING" then
			return
		end

		WeaponController.StateManager:SetState("WeaponState", "IDLE")
	end))

	WeaponController.Firing:OnEquip()
	WeaponController.Aiming:OnEquip()
	WeaponController.Reloading:OnEquip()
	WeaponController:BindWeaponInputs()
end

function Gun:OnUnequip()
	local WeaponController = self.WeaponController
	-- Ignore duplicate/stale results without rechecking action restrictions.
	if WeaponController.CombatController.EquippedSlot ~= WeaponController.SlotName then
		return
	end

	WeaponController.CombatController:CancelStates("Weapon", "UnEquip")
	WeaponController.StateManager:SetState("WeaponState", "UNEQUIPPED")

	UIS.MouseIconEnabled = true

	WeaponController.CombatController.EquippedSlot = nil

	local Animations = WeaponController.Animations
	Animations.IDLE.VIEWMODEL:Stop(0.15)
	Animations.IDLE.CHARACTER:Stop(0.15)

	WeaponController.Firing:OnUnequip()
	WeaponController.Reloading:OnUnequip()
	WeaponController.Aiming:OnUnequip()

	WeaponController:UnbindWeaponInputs()
	WeaponController.EquippedTrove:Clean()
	WeaponController.ViewModelController:OnUnequip()
	WeaponController.GUIController:OnUnequip()
end

function Gun:CanEquip()
	local WeaponController = self.WeaponController
	return WeaponController.CombatController.EquippedSlot == nil
		and WeaponController.StateManager:TryAction("Weapon", "Equip")
end

function Gun:CanUnequip()
	local WeaponController = self.WeaponController
	return WeaponController.CombatController.EquippedSlot == WeaponController.SlotName
		and WeaponController.StateManager:TryAction("Weapon", "UnEquip")
end

-- Input requests a change; OnEquip/OnUnequip apply the server's response.
function Gun:Pressed()
	local WeaponController = self.WeaponController
	local isEquipped = WeaponController.CombatController.EquippedSlot == WeaponController.SlotName
	PacketSettings.Combat.Weapon.EquipRequest.send({
		SlotName = WeaponController.SlotName,
		Action = if isEquipped then "UnEquip" else "Equip",
	})
end

return Gun
