local Combat = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local CombatClassesModule = require(Combat:WaitForChild("CombatClasses"))

local CombatClasses = CombatClassesModule.new()

local LoadoutController = {}

function LoadoutController:Init()
	PacketSettings.Creation.PlayerData.listen(function(data)
		for _, weaponData in ipairs(data.Weapons) do
			CombatClasses:CreateWeaponController(weaponData)
		end
		CombatClasses:CreateAbilityController(data.Abilities)
	end)

	PacketSettings.Creation.RequestPlayerData.send()

	local function OnCharacterRemoved()
		CombatClasses:OnCharacterRemoved()
	end

	local function OnCharacterAdded(character)
		CombatClasses:OnCharacterAdded(character)
	end

	Player.CharacterRemoving:Connect(OnCharacterRemoved)
	Player.CharacterAdded:Connect(OnCharacterAdded)

	if Player.Character then
		task.spawn(OnCharacterAdded, Player.Character)
	end
end

return LoadoutController
