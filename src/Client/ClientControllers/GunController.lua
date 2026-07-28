local UIP = game:GetService("UserInputService")
local Client = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local KineticSlot = StarterPack:WaitForChild("KineticSlot")
local EnergySlot = StarterPack:WaitForChild("EnergySlot")
local HeavySlot = StarterPack:WaitForChild("HeavySlot")

local ClientNetworks = Client:WaitForChild("ClientNetworks")

local Definitions = Shared:WaitForChild("Definitions")

local GunNetwork = require(ClientNetworks:WaitForChild("GunNetwork"))

local equipped

local GunController = {}

function GunController:Init()
	KineticSlot.Equipped:Connect(function()
		GunNetwork.CreateGunRequest("Kinetic")
	end)

	EnergySlot.Equipped:Connect(function()
		GunNetwork.CreateGunRequest("Energy")
	end)

	HeavySlot.Equipped:Connect(function()
		GunNetwork.CreateGunRequest("Heavy")
	end)
end

return GunController
