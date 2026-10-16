local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Combat = Server:WaitForChild("Combat")
local LoadoutHandler = require(Combat:WaitForChild("Handlers"):WaitForChild("LoadoutHandler"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local AbilityHandler = {}

function AbilityHandler:Init()
	PacketSettings.Combat.Ability.GrenadeRequest.listen(function(data, player)
		local Action = data.Action

		local CombatClasses = LoadoutHandler:GetCombatClasses(player)

		if not CombatClasses then
			return
		end

		local AbilityClass = CombatClasses.AbilityClass

		if not AbilityClass then
			return
		end

		if not AbilityClass.Grenade then
			return
		end

		if Action == "Pressed" then
			AbilityClass.Grenade:Pressed(data)
		elseif Action == "Released" then
			AbilityClass.Grenade:Released(data)
		elseif Action == "Cast" then
			AbilityClass.Grenade:Cast(data)
		elseif Action == "Cancelled" then
			AbilityClass.Grenade:Cancelled(data)
		end
	end)
end

return AbilityHandler
