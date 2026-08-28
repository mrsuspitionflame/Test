local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Combat = Server:WaitForChild("Combat")
local LoadoutHandler = require(Combat:WaitForChild("LoadoutHandler"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local AbilityHandler = {}

function AbilityHandler:Init()
	PacketSettings.Combat.Ability.GrenadeRequest.listen(function(data, player)
		local Action = data.Action

		local AbilityClass = LoadoutHandler:GetAbilityClass(player)
		if not AbilityClass then
			return
		end

		if Action == "Held" then
			AbilityClass.Grenade:Held(data)
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
