local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Client = StarterPlayerScripts:WaitForChild("Client")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Controllers = Client:WaitForChild("Controllers")
local GunController = require(Controllers:WaitForChild("GunController"))

local LoadoutHandler = {}

local Loadout = {
	KineticSlot = nil,
	EnergySlot = nil,
	HeavySlot = nil,
}

function LoadoutHandler.Init()
	if Player.Character then
		print("Character exists")
		local backpack = Player:WaitForChild("Backpack")
		Loadout.KineticSlot = GunController.new(backpack:WaitForChild("KineticSlot"))
		Loadout.EnergySlot = GunController.new(backpack:WaitForChild("EnergySlot"))
		Loadout.HeavySlot = GunController.new(backpack:WaitForChild("HeavySlot"))
	end

	Player.CharacterAdded:Connect(function(character)
		print("Character added")
		if character then
			local backpack = Player:WaitForChild("Backpack")
			if Loadout.KineticSlot == nil then
				Loadout.KineticSlot = GunController.new(backpack:WaitForChild("KineticSlot"))
			end
			if Loadout.EnergySlot == nil then
				Loadout.EnergySlot = GunController.new(backpack:WaitForChild("EnergySlot"))
			end
			if Loadout.HeavySlot == nil then
				Loadout.HeavySlot = GunController.new(backpack:WaitForChild("HeavySlot"))
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

return LoadoutHandler
