local Client = script.Parent.Parent
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local humanoid

local Controllers = Client:WaitForChild("Controllers")
local WeaponControllers = Controllers:WaitForChild("WeaponControllers")
local CentralControllers = Controllers:WaitForChild("CentralControllers")

local GunController = require(WeaponControllers:WaitForChild("GunController"))
local AnimationController = require(CentralControllers:WaitForChild("AnimationController"))
local MovementController = require(CentralControllers:WaitForChild("MovementController"))
local GUIController = require(CentralControllers:WaitForChild("GUIController"))
local StateManager = require(Utility:WaitForChild("StateManager"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local LoadoutController = {}

local Loadout = {
	KineticSlot = nil,
	EnergySlot = nil,
	HeavySlot = nil,
}

local gui = GUIController.new()
local animation = AnimationController.new()
local stateManager = StateManager.new()
local movement = MovementController.new(stateManager, animation)

function LoadoutController:Init()
	PacketSettings.Creation.CreateGunController.listen(function(data)
		if data.GunName and data.SlotName then
			print("Received CreateGunController packet for gun:", data.GunName, "slot:", data.SlotName)
			if Loadout[data.SlotName] == nil then
				print("Creating GunController for gun:", data.GunName, "slot:", data.SlotName)
				gui:InitializeSlot(data.GunName, data.SlotName)
				Loadout[data.SlotName] = GunController.new(data.GunName, data.SlotName, animation, stateManager, gui)
			end
		end
	end)

	PacketSettings.Creation.RequestLoadout.send()

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

	self:GunInits()
end

function LoadoutController:GunInits()
	PacketSettings.Combat.AmmoUpdate.listen(function(data)
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			controller:SetAmmo(data.Ammo, data.ReserveAmmo)
		end
	end)

	PacketSettings.Combat.EquipResult.listen(function(data)
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			if data.Accepted then
				if data.Action == "Equip" then
					UIS.MouseIconEnabled = false
					controller:OnEquip()
				elseif data.Action == "UnEquip" then
					UIS.MouseIconEnabled = true
					controller:OnUnequip()
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
