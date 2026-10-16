local Combat = script:FindFirstAncestor("Combat")
local Handlers = Combat:WaitForChild("Handlers")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local CombatHandlerModule = require(Handlers:WaitForChild("CombatHandler"))

local CombatHandler = CombatHandlerModule.new()

local LoadoutHandler = {}

function LoadoutHandler:Init()
	PacketSettings.Creation.PlayerData.listen(function(data)
		for _, weaponData in ipairs(data.Weapons) do
			CombatHandler:CreateWeaponHandler(weaponData)
		end
		CombatHandler:CreateAbilityHandler(data.Abilities)
	end)

	PacketSettings.Creation.RequestPlayerData.send()
end

return LoadoutHandler
