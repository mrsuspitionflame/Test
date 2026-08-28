local Combat = script.Parent
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local humanoid

local Controllers = Combat:WaitForChild("Controllers")

local AbilityController = require(Controllers:WaitForChild("AbilityController"))
local WeaponController = require(Controllers:WaitForChild("WeaponController"))
local AnimationController = require(Controllers:WaitForChild("AnimationController"))
local MovementController = require(Controllers:WaitForChild("MovementController"))
local GUIController = require(Controllers:WaitForChild("GUIController"))
local StateManager = require(Utility:WaitForChild("StateManager"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local LoadoutController = {}

local Loadout = {
	KineticSlot = nil,
	EnergySlot = nil,
	HeavySlot = nil,
}

local Ability = nil

local gui = GUIController.new()
local animation = AnimationController.new()
local stateManager = StateManager.new()
local movement = MovementController.new(stateManager, animation)

function LoadoutController:Init()
	PacketSettings.Creation.CreateWeaponController.listen(function(data)
		if data.WeaponName and data.SlotName then
			if Loadout[data.SlotName] == nil then
				gui:InitializeSlot(data.WeaponName, data.SlotName)
				Loadout[data.SlotName] =
					WeaponController.new(data.WeaponName, data.SlotName, animation, stateManager, gui)
			end
		end
	end)

	PacketSettings.Creation.CreateAbilityController.listen(function(data)
		if data then
			animation:CreateAbilityViewModel(data)
			Ability = AbilityController.new(data, animation, stateManager, gui)
		end
	end)

	PacketSettings.Creation.RequestPlayerData.send()

	local function OnCharacterRemoved()
		stateManager:SetState("WeaponState", "IDLE")
		for _, controller in pairs(Loadout) do
			if controller.Equipped then
				controller:OnUnequip()
			end
		end
		gui:SetCombatUIEnabled(false)
	end

	local function OnCharacterAdded(character)
		gui:SetCombatUIEnabled(true)
		movement:OnCharacterAdded(character)

		humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(OnCharacterRemoved)
	end

	Player.CharacterRemoving:Connect(OnCharacterRemoved)
	Player.CharacterAdded:Connect(OnCharacterAdded)

	if Player.Character then
		task.spawn(OnCharacterAdded, Player.Character)
	end

	self:InitializeWeapons()
end

function LoadoutController:InitializeWeapons()
	PacketSettings.Combat.Weapon.AmmoUpdate.listen(function(data)
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			controller:SetAmmo(data.Ammo, data.ReserveAmmo)
		end
	end)

	PacketSettings.Combat.Weapon.EquipResult.listen(function(data)
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			if data.Accepted then
				if data.Action == "Equip" then
					controller:OnEquip()
					movement:OnWeaponEquip()
				elseif data.Action == "UnEquip" then
					controller:OnUnequip()
					movement:OnWeaponUnequip()
				end
			else
				warn("Equip/Unequip action was not accepted for slot:", data.SlotName)
			end
		end
	end)

	CAS:BindAction("EquipOrUnequipKinetic", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.KineticSlot then
				Loadout.KineticSlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.One)

	CAS:BindAction("EquipOrUnequipEnergy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.EnergySlot then
				Loadout.EnergySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Two)

	CAS:BindAction("EquipOrUnequipHeavy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.HeavySlot then
				Loadout.HeavySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Three)
end

return LoadoutController
