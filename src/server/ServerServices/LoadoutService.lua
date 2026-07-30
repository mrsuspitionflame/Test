local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))

local LoadoutService = {}

function LoadoutService.CreatePlayerTools(player, gunName, toolName)
	-- Example implementation: give the player a default rifle
	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool.CanBeDropped = false
	tool.RequiresHandle = false
	LoadoutService.SetAttributes(tool, gunName)
	tool.Parent = player:WaitForChild("Backpack")
	print("Created tool for player:", player.Name, "with gun:", gunName, "and tool name:", toolName)
	return tool
end

function LoadoutService.SetAttributes(tool, gunName)
	local gunAttributes = GunDefinitions[gunName]
	if gunAttributes then
		for attributeName, attributeValue in pairs(gunAttributes) do
			tool:SetAttribute(attributeName, attributeValue)
		end
	else
		warn("Gun type '" .. gunName .. "' not found in GunDefinitions.")
	end
end

return LoadoutService
