local Client = script.Parent.Parent
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Definitions = Shared:WaitForChild("Definitions")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local humanoid

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

local gui = GUIController.new()

local animation = AnimationController.new()
local action = ActionManager.new()

function LoadoutController.Init()
	PacketManager.Creation.CreateGunController.listen(function(data)
		if data.GunName and data.SlotName then
			print("Received CreateGunController packet for gun:", data.GunName, "slot:", data.SlotName)
			if Loadout[data.SlotName] == nil then
				print("Creating GunController for gun:", data.GunName, "slot:", data.SlotName)
				gui:InitializeSlot(data.GunName, data.SlotName)
				Loadout[data.SlotName] = GunController.new(data.GunName, data.SlotName, animation, action, gui)
			end
		end
	end)

	LoadoutController.GunInits()
	PacketManager.Creation.RequestLoadout.send()

	Player.CharacterRemoving:Connect(function()
		action:SetState("WeaponState", "Idle")
		for _, controller in pairs(Loadout) do
			if controller.Equipped then
				controller:OnUnequip()
			end
		end

		gui:SetCombatUIEnabled(false)
	end)

	local function OnCharacterAdded(character)
		gui:SetCombatUIEnabled(true)

		humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			action:SetState("WeaponState", "Idle")
			for _, controller in pairs(Loadout) do
				if controller.Equipped then
					controller:OnUnequip()
				end
			end
			gui:SetCombatUIEnabled(false)
		end)
	end

	Player.CharacterAdded:Connect(OnCharacterAdded)

	if Player.Character then
		task.spawn(OnCharacterAdded, Player.Character)
	end
end

function LoadoutController.GunInits()
	PacketManager.Combat.AmmoUpdate.listen(function(data)
		local controller = Loadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			controller:SetAmmo(data.Ammo, data.ReserveAmmo)
		end
	end)

	PacketManager.Combat.EquipResult.listen(function(data)
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
