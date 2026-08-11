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

local LoadoutSlotTools = nil
local Gui = nil

local AnimController = AnimationController.new()
local Action = ActionManager.new()

local function FindSlotTool(slotName)
	print(`Searching for {slotName} tool for player: {Player.Name}`)
	local backpack = Player:FindFirstChildOfClass("Backpack")
	local character = Player.Character

	return (backpack and backpack:FindFirstChild(slotName)) or (character and character:FindFirstChild(slotName))
end

local function WaitForSlotTool(slotName)
	while Player.Parent do
		local tool = FindSlotTool(slotName)

		if tool then
			return tool
		end

		task.wait()
	end

	error(`Player was removed before {slotName} appeared`)
end

function LoadoutController.Init()
	LoadoutSlotTools = {
		KineticSlot = WaitForSlotTool("KineticSlot"),
		EnergySlot = WaitForSlotTool("EnergySlot"),
		HeavySlot = WaitForSlotTool("HeavySlot"),
	}

	Gui = GUIController.new(LoadoutSlotTools)

	if Player.Character then
		Loadout.KineticSlot = GunController.new(LoadoutSlotTools.KineticSlot, AnimController, Action, Gui)
		Loadout.EnergySlot = GunController.new(LoadoutSlotTools.EnergySlot, AnimController, Action, Gui)
		Loadout.HeavySlot = GunController.new(LoadoutSlotTools.HeavySlot, AnimController, Action, Gui)
	end

	Player.CharacterAdded:Connect(function(character)
		print("Character added")
		if character then
			if Loadout.KineticSlot == nil then
				Loadout.KineticSlot = GunController.new(LoadoutSlotTools.KineticSlot, AnimController, Action, Gui)
			end
			if Loadout.EnergySlot == nil then
				Loadout.EnergySlot = GunController.new(LoadoutSlotTools.EnergySlot, AnimController, Action, Gui)
			end
			if Loadout.HeavySlot == nil then
				Loadout.HeavySlot = GunController.new(LoadoutSlotTools.HeavySlot, AnimController, Action, Gui)
			end
		end
	end)

	Player.CharacterRemoving:Connect(function()
		if Loadout.KineticSlot ~= nil then
			Loadout.KineticSlot:Destroy()
			Loadout.KineticSlot = nil
		end
		if Loadout.EnergySlot ~= nil then
			Loadout.EnergySlot:Destroy()
			Loadout.EnergySlot = nil
		end
		if Loadout.HeavySlot then
			Loadout.HeavySlot:Destroy()
			Loadout.HeavySlot = nil
		end
	end)

	LoadoutController.GunInits()
end

function LoadoutController.GunInits()
	PacketManager.Combat.AmmoUpdate.listen(function(data)
		if typeof(data.Gun) ~= "Instance" then
			return
		end

		local controller = Loadout[data.Gun.Name]

		if controller and controller.Gun == data.Gun then
			controller:SetAmmoState(data.Ammo, data.ReserveAmmo)
		end
	end)

	PacketManager.Combat.EquipResult.listen(function(data)
		if typeof(data.Gun) ~= "Instance" then
			return
		end

		local controller = Loadout[data.Gun.Name]

		if controller and controller.Gun == data.Gun then
			if not data.Accepted then
				print(`Equip/Unequip action {data.Action} for gun {data.Gun.Name} was rejected by the server.`)
			end
		end
	end)

	CAS:BindAction("EquipKinetic", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.KineticSlot then
				Loadout.KineticSlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.One)

	CAS:BindAction("EquipEnergy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.EnergySlot then
				Loadout.EnergySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Two)

	CAS:BindAction("EquipHeavy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if Loadout.HeavySlot then
				Loadout.HeavySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Three)
end

return LoadoutController
