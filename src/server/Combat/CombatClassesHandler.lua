local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = Shared:WaitForChild("Combat")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local CombatClassesModule = require(Combat:WaitForChild("CombatClasses"))

local PlayerCombatClasses = {}

local CombatClassesHandler = {}

function CombatClassesHandler:GetCombatClasses(player)
	return PlayerCombatClasses[player.UserId]
end

local function SendPlayerData(player)
	local Loadout = PlayerCombatClasses[player.UserId]

	if not Loadout then
		return
	end

	local Weapons = {}
	for SlotName, WeaponClass in pairs(Loadout.WeaponClasses) do
		table.insert(Weapons, {
			WeaponName = WeaponClass.WeaponName,
			SlotName = SlotName,
		})
	end

	PacketSettings.Creation.PlayerData.sendTo({
		Weapons = Weapons,
		Abilities = {
			Grenade = "SolarGrenade",
		},
	}, player)
end

local function CreatePlayerData(player)
	if PlayerCombatClasses[player.UserId] then
		return
	end

	PlayerCombatClasses[player.UserId] = CombatClassesModule.new(player)
end

local function DestroyPlayerData(player)
	local data = PlayerCombatClasses[player.UserId]

	if not data then
		return
	end

	PlayerCombatClasses[player.UserId]:Destroy()
	PlayerCombatClasses[player.UserId] = nil
end

function CombatClassesHandler:Init()
	PacketSettings.Creation.RequestPlayerData.listen(function(_, player)
		CreatePlayerData(player)
		SendPlayerData(player)
	end)

	Players.PlayerAdded:Connect(CreatePlayerData)
	Players.PlayerRemoving:Connect(DestroyPlayerData)

	for _, player in ipairs(Players:GetPlayers()) do
		CreatePlayerData(player)
	end
end

return CombatClassesHandler
