
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = Shared:WaitForChild("Combat")
local Settings = Shared:WaitForChild("Settings")

local CentralHandlers = script:FindFirstAncestor("CentralHandlers")
local CombatHandlerModule = CentralHandlers:WaitForChild("CombatHandler")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local CombatClassesModule = require(Combat:WaitForChild("CombatClasses"))

local CombatClass, CombatHandler

local LoadoutHandler = {}

function LoadoutHandler:Init()
	PacketSettings.Creation.PlayerData.listen(function(data)
		CombatClass = CombatClassesModule.new(data)
		CombatHandler = CombatHandlerModule.new(data)
	end)

	PacketSettings.Creation.RequestPlayerData.send()

	self:CharacterLifecycleSetup()
end

function LoadoutHandler:CharacterLifecycleSetup()
	Player.CharacterRemoving:Connect(function(character)
		CombatClass:OnCharacterRemoving(character)
		CombatHandler:OnCharacterRemoving(character)
	end)
	Player.CharacterAdded:Connect(function(character)
		CombatClass:OnCharacterAdded(character)
		CombatHandler:OnCharacterAdded(character)
	end)

	if Player.Character then
		task.spawn(function()
			CombatClass:OnCharacterAdded(Player.Character)
			CombatHandler:OnCharacterAdded(Player.Character)
		end)
	end
end

return LoadoutHandler

