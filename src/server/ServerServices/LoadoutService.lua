local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Classes = Server:WaitForChild("Classes")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))

local GunClass = require(Classes:WaitForChild("GunClass"))

local LoadoutService = {}

function LoadoutService.CreatePlayerGun(player, gunName, slotName)
	local tool = LoadoutService.CreatePlayerTools(player, gunName, slotName)
	return GunClass.new(player, tool)
end

function LoadoutService.CreatePlayerTools(player, gunName, slotName)
	local tool = Instance.new("Tool")
	tool.Name = slotName
	tool.CanBeDropped = false
	tool.RequiresHandle = false
	LoadoutService.SetAttributes(tool, gunName)
	tool.Parent = player:WaitForChild("Backpack")
	print("Created tool for player:", player.Name, "with gun:", gunName, "and slot name:", slotName)
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
