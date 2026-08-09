local Client = script.Parent.Parent

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

local AnimController = AnimationController.new()
local Action = ActionManager.new()
local Gui = GUIController.new()

function LoadoutController.Init()
	PacketManager.Combat.AmmoUpdate.listen(function(data)
		if typeof(data.Gun) ~= "Instance" then
			return
		end

		local controller = Loadout[data.Gun.Name]

		if controller and controller.Gun == data.Gun then
			controller:SetAmmo(data.Ammo)
		end
	end)

	if Player.Character then
		local backpack = Player:WaitForChild("Backpack")
		Loadout.KineticSlot = GunController.new(backpack:WaitForChild("KineticSlot"), AnimController, Action, Gui)
		Loadout.EnergySlot = GunController.new(backpack:WaitForChild("EnergySlot"), AnimController, Action, Gui)
		Loadout.HeavySlot = GunController.new(backpack:WaitForChild("HeavySlot"), AnimController, Action, Gui)
	end

	Player.CharacterAdded:Connect(function(character)
		print("Character added")
		if character then
			local backpack = Player:WaitForChild("Backpack")
			if Loadout.KineticSlot == nil then
				Loadout.KineticSlot = GunController.new(backpack:WaitForChild("KineticSlot"), AnimController, Action, Gui)
			end
			if Loadout.EnergySlot == nil then
				Loadout.EnergySlot = GunController.new(backpack:WaitForChild("EnergySlot"), AnimController, Action, Gui)
			end
			if Loadout.HeavySlot == nil then
				Loadout.HeavySlot = GunController.new(backpack:WaitForChild("HeavySlot"), AnimController, Action, Gui)
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
end

return LoadoutController
