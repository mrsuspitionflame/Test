local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Combat = Server:WaitForChild("Combat")
local Handlers = Combat:WaitForChild("Handlers")
local LoadoutHandler = require(Combat:WaitForChild("LoadoutHandler"))
local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local AbilityHandler = {}

function AbilityHandler:Init()
	PacketSettings.Combat.Ability.Grenade.GrenadeHeld.listen(function(data, player)
		local AbilityClass = LoadoutHandler:GetAbilityClass(player)
		if not AbilityClass then
			return
		end
		AbilityClass:GrenadeHeld(data)
	end)

	PacketSettings.Combat.Ability.Grenade.GrenadeReleased.listen(function(data, player)
		local AbilityClass = LoadoutHandler:GetAbilityClass(player)
		if not AbilityClass then
			return
		end
		AbilityClass:GrenadeReleased(data)
	end)
end

return AbilityHandler
