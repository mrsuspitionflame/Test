local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Gun = {}

Gun.__index = Gun

function Gun.new(WeaponHandler)
	local self = setmetatable({}, Gun)

	self.WeaponHandler = WeaponHandler

	return self
end

function Gun:OnEquip()
	local WeaponHandler = self.WeaponHandler
	local CombatHandler = WeaponHandler.CombatHandler
	-- Apply the server's decision; local combat restrictions may differ.
	if CombatHandler.EquippedSlot == WeaponHandler.SlotName then
		return
	end
	local PreviousWeapon = CombatHandler:GetEquippedWeapon()
	if PreviousWeapon then
		PreviousWeapon.Equipping:OnUnequip()
	end

	WeaponHandler.CombatHandler:CancelStates("Weapon", "Equip")
	WeaponHandler.StateManager:SetState("WeaponState", "EQUIPPING")

	UIS.MouseIconEnabled = false

	WeaponHandler.CombatHandler.EquippedSlot = WeaponHandler.SlotName

	WeaponHandler.GUIController:EquippedSlotChanged(WeaponHandler.SlotName)
	WeaponHandler.ViewModelController:OnEquip(WeaponHandler.WeaponInfo)
	WeaponHandler:GetAnimations()
	local Animations = WeaponHandler.Animations

	Animations.IDLE.VIEWMODEL.Looped = true
	Animations.IDLE.CHARACTER.Looped = true

	Animations.IDLE.VIEWMODEL:Play(0.15, 1, 0.1)
	Animations.IDLE.CHARACTER:Play(0.15, 1, 0.1)

	local EquipSpeed = 1 + (WeaponHandler.WeaponInfo.HANDLING - 50) / 100
	Animations.EQUIP.VIEWMODEL:Play(0, 1, EquipSpeed)
	Animations.EQUIP.CHARACTER:Play(0, 1, EquipSpeed)

	WeaponHandler.EquippedTrove:Add(task.delay(WeaponHandler.WeaponInfo.EQUIP_DURATION / EquipSpeed, function()
		WeaponHandler.EquipTask = nil
		if WeaponHandler.StateManager:GetState("WeaponState") ~= "EQUIPPING" then
			return
		end

		WeaponHandler.StateManager:SetState("WeaponState", "IDLE")
	end))

	WeaponHandler.Firing:OnEquip()
	WeaponHandler.Aiming:OnEquip()
	WeaponHandler.Reloading:OnEquip()
	WeaponHandler:BindWeaponInputs()
end

function Gun:OnUnequip()
	local WeaponHandler = self.WeaponHandler
	-- Ignore duplicate/stale results without rechecking action restrictions.
	if WeaponHandler.CombatHandler.EquippedSlot ~= WeaponHandler.SlotName then
		return
	end

	WeaponHandler.CombatHandler:CancelStates("Weapon", "UnEquip")
	WeaponHandler.StateManager:SetState("WeaponState", "UNEQUIPPED")

	UIS.MouseIconEnabled = true

	WeaponHandler.CombatHandler.EquippedSlot = nil

	local Animations = WeaponHandler.Animations
	Animations.IDLE.VIEWMODEL:Stop(0.15)
	Animations.IDLE.CHARACTER:Stop(0.15)

	WeaponHandler.Firing:OnUnequip()
	WeaponHandler.Reloading:OnUnequip()
	WeaponHandler.Aiming:OnUnequip()

	WeaponHandler:UnbindWeaponInputs()
	WeaponHandler.EquippedTrove:Clean()
	WeaponHandler.ViewModelController:OnUnequip()
	WeaponHandler.GUIController:OnUnequip()
end

function Gun:CanEquip()
	local WeaponHandler = self.WeaponHandler
	return WeaponHandler.CombatHandler.EquippedSlot == nil
		and WeaponHandler.StateManager:TryAction("Weapon", "Equip")
end

function Gun:CanUnequip()
	local WeaponHandler = self.WeaponHandler
	return WeaponHandler.CombatHandler.EquippedSlot == WeaponHandler.SlotName
		and WeaponHandler.StateManager:TryAction("Weapon", "UnEquip")
end

-- Input requests a change; OnEquip/OnUnequip apply the server's response.
function Gun:Pressed()
	local WeaponHandler = self.WeaponHandler
	local isEquipped = WeaponHandler.CombatHandler.EquippedSlot == WeaponHandler.SlotName
	PacketSettings.Combat.Weapon.EquipRequest.send({
		SlotName = WeaponHandler.SlotName,
		Action = if isEquipped then "UnEquip" else "Equip",
	})
end

return Gun
