local Client = script.Parent.Parent
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Definitions = Shared:WaitForChild("Definitions")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Controllers = Client:WaitForChild("Controllers")
local WeaponControllers = Controllers:WaitForChild("WeaponControllers")
local CentralControllers = Controllers:WaitForChild("CentralControllers")

local GunController = require(WeaponControllers:WaitForChild("GunController"))
local AnimationController = require(CentralControllers:WaitForChild("AnimationController"))
local GUIController = require(CentralControllers:WaitForChild("GUIController"))
local ActionManager = require(Utility:WaitForChild("ActionManager"))
local PacketManager = require(Definitions:WaitForChild("PacketManager"))

local LoadoutController = {}

local Loadout = {
	KineticSlot = nil,
	EnergySlot = nil,
	HeavySlot = nil,
}

local Gui = GUIController.new()
local Gui = GUIController.new()

local Anim = AnimationController.new()
local Anim = AnimationController.new()
local Action = ActionManager.new()


function LoadoutController.Init()
	PacketManager.Creation.CreateGunController.listen(function(data)
		if data.GunName and data.SlotName then
			print("Received CreateGunController packet for gun:", data.GunName, "slot:", data.SlotName)
			if Loadout[data.SlotName] == nil then
				Loadout[data.SlotName] = GunController.new(data.GunName, data.SlotName, Anim, Action, Gui)
	PacketManager.Creation.CreateGunController.listen(function(data)
		if data.GunName and data.SlotName then
			print("Received CreateGunController packet for gun:", data.GunName, "slot:", data.SlotName)
			if Loadout[data.SlotName] == nil then
				Loadout[data.SlotName] = GunController.new(data.GunName, data.SlotName, Anim, Action, Gui)
			end
		end
		Gui:InitializeSlot(data.GunName, data.SlotName)
		Gui:InitializeSlot(data.GunName, data.SlotName)
	end)

	LoadoutController.GunInits()
	PacketManager.Creation.RequestLoadout.send()
end

function LoadoutController.GunInits()
	PacketManager.Combat.AmmoUpdate.listen(function(data)
		local controller = Loadout[data.SlotName]
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			controller:SetAmmo(data.Ammo, data.ReserveAmmo)
		if controller and controller.SlotName == data.SlotName then
			controller:SetAmmo(data.Ammo, data.ReserveAmmo)
		end
	end)

	PacketManager.Combat.EquipResult.listen(function(data)
		local controller = Loadout[data.SlotName]
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			if data.Accepted then
				if data.Action == "Equip" then
					controller:OnEquip()
				elseif data.Action == "UnEquip" then
					controller:OnUnequip()
				end
			else
				warn("Equip/Unequip action was not accepted for slot:", data.SlotName)
		if controller and controller.SlotName == data.SlotName then
			if data.Accepted then
				if data.Action == "Equip" then
					controller:OnEquip()
				elseif data.Action == "UnEquip" then
					controller:OnUnequip()
				end
			else
				warn("Equip/Unequip action was not accepted for slot:", data.SlotName)
			end
		end
	end)

	CAS:BindAction("EquipOrUnequipKinetic", function(_, state)
	CAS:BindAction("EquipOrUnequipKinetic", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.KineticSlot then
				Loadout.KineticSlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.One)

	CAS:BindAction("EquipOrUnequipEnergy", function(_, state)
	CAS:BindAction("EquipOrUnequipEnergy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.EnergySlot then
				Loadout.EnergySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Two)

	CAS:BindAction("EquipOrUnequipHeavy", function(_, state)
	CAS:BindAction("EquipOrUnequipHeavy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.HeavySlot then
				Loadout.HeavySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Three)
end

return LoadoutController
