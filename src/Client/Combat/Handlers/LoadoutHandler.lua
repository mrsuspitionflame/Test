local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = Shared:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")
local Settings = Shared:WaitForChild("Settings")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local Handlers = script:FindFirstAncestor("Handlers")

local CombatHandlerModule = Handlers:WaitForChild("CombatHandler")
local CombatClassesModule = require(Classes:WaitForChild("CombatClasses"))

local CombatClass, CombatHandler

local LoadoutHandler = {}

function LoadoutHandler:Init()
	PacketSettings.Creation.PlayerData.listen(function(data)
		CombatClass = CombatClassesModule.new(Player, data)
		CombatHandler = CombatHandlerModule.new(Player, data)
	end)

	PacketSettings.Creation.RequestPlayerData.send()
end

return LoadoutHandler
