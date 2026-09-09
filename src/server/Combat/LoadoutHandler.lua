local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local SharedCombat = Shared:WaitForChild("Combat")
local CombatClasses = require(SharedCombat:WaitForChild("CombatClasses"))

local CombatClassesByUserId = {}

local LoadoutHandler = {}

function LoadoutHandler:GetCombatClasses(player)
	return CombatClassesByUserId[player.UserId]
end

local function SendPlayerData(player)
	local Loadout = CombatClassesByUserId[player.UserId]

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
	if CombatClassesByUserId[player.UserId] then
		return
	end

	CombatClassesByUserId[player.UserId] = CombatClasses.new(player)
end

local function DestroyPlayerData(player)
	local data = CombatClassesByUserId[player.UserId]

	if not data then
		return
	end

	CombatClassesByUserId[player.UserId]:DestroyCombatClasses()
	CombatClassesByUserId[player.UserId] = nil
end

function LoadoutHandler:Init()
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

return LoadoutHandler
