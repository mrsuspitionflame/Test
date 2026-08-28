local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Client = script:FindFirstAncestor("Client")
local Combat = Client:WaitForChild("Combat")
local Abilities = Combat:WaitForChild("Abilities")

local ReplicateAbility = {}

function ReplicateAbility:Init()
	PacketSettings.Combat.Replicate.ReplicateAbilityEvent.listen(function(data)
		local abilityFolder = Abilities:FindFirstChild(data.AbilityType)
		if not abilityFolder then
			return
		end

		local abilityScript = abilityFolder:FindFirstChild(data.AbilityName)
		if not abilityScript or not abilityScript:IsA("ModuleScript") then
			return
		end

		local methodName = data.ActionType
		if not methodName then
			return
		end

		local ability = require(abilityScript)
		local method = ability[methodName]

		if type(method) == "function" then
			method(ability, data, true)
		end
	end)
end

return ReplicateAbility
