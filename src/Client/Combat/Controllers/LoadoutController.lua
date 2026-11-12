local Combat = script:FindFirstAncestor("Combat")
local Controllers = Combat:WaitForChild("Controllers")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local CombatControllerModule = require(Controllers:WaitForChild("CombatController"))

local CombatController = CombatControllerModule.new()

local LoadoutController = {}

function LoadoutController:Init()
	PacketSettings.Creation.PlayerData.listen(function(data)
		for _, weaponData in ipairs(data.Weapons) do
			CombatController:CreateWeaponController(weaponData)
		end
		CombatController:CreateAbilityController(data.Abilities)
	end)

	PacketSettings.Creation.RequestPlayerData.send()
end

return LoadoutController
