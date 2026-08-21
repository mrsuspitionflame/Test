local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Combat = Server:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local Utility = Shared:WaitForChild("Utility")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local GunClass = require(Classes:WaitForChild("GunClass"))
local AbilityClass = require(Classes:WaitForChild("AbilityClass"))
local AnimationClass = require(Classes:WaitForChild("AnimationClass"))
local StateManager = require(Utility:WaitForChild("StateManager"))
local Trove = require(Packages:WaitForChild("Trove"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local PlayerData = {}

local LoadoutHandler = {}

function LoadoutHandler:GetAbilityClass(player)
	local data = PlayerData[player.UserId]
	return data and data.Ability or nil
end

function LoadoutHandler:GetGunClass(player, slotName)
	local data = PlayerData[player.UserId]
	return data and data.Guns[slotName] or nil
end

function LoadoutHandler:GetEquippedGunClass(player)
	local data = PlayerData[player.UserId]

	if not data then
		return nil
	end

	for _, gunClass in pairs(data.Guns) do
		if gunClass.Equipped then
			return gunClass
		end
	end

	return nil
end

local function UnequipPlayerGuns(player, data)
	data.StateManager:SetState("WeaponState", "IDLE")

	local gunClass = LoadoutHandler:GetEquippedGunClass(player)
	if gunClass then
		gunClass:OnUnequip()
	end
end

local function SendGunController(player)
	local data = PlayerData[player.UserId]

	if not data then
		return
	end

	for slotName, gunClass in pairs(data.Guns) do
		PacketSettings.Creation.CreateGunController.sendTo({
			GunName = gunClass.GunName,
			SlotName = slotName,
		}, player)
	end
end

local function SendAbilityController(player)
	local data = PlayerData[player.UserId]

	if not data then
		return
	end

	PacketSettings.Creation.CreateAbilityController.sendTo({
		Grenade = "SolarGrenade",
	}, player)
end

local function CreateGunController(player, data)
	for _, slotName in ipairs(Slots) do
		print("Creating gun class for player:", player.Name, "slot:", slotName)
		data.Guns[slotName] = GunClass.new(player, "Rifle", slotName, data.Animation, data.StateManager)
	end
end

local function CreateAbilityController(player, data)
	print("Creating ability class for player:", player.Name)
	data.Ability = AbilityClass.new(player, { Grenade = "SolarGrenade" }, data.StateManager, data.Animation)
end

local function CleanupCharacter(player, character)
	local data = PlayerData[player.UserId]

	if not data or (character and data.Character ~= character) then
		return
	end

	data.Character = nil
	data.CharacterTrove:Clean()
	UnequipPlayerGuns(player, data)
end

local function OnCharacterAdded(player, character)
	local data = PlayerData[player.UserId]
	if not data then
		return
	end

	data.CharacterTrove:Clean()
	data.Character = character

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or PlayerData[player.UserId] ~= data or data.Character ~= character then
		return
	end

	data.CharacterTrove:Connect(humanoid.Died, function()
		CleanupCharacter(player, character)
	end)
end

local function CreatePlayerData(player)
	local userId = player.UserId
	local data = PlayerData[userId]

	if data then
		return data
	end

	data = {
		Guns = {},
		Ability = nil,
		Animation = AnimationClass.new(player),
		StateManager = StateManager.new(),
		Trove = Trove.new(),
		Character = nil,
	}
	data.CharacterTrove = data.Trove:Extend()
	PlayerData[userId] = data

	CreateGunController(player, data)
	CreateAbilityController(player, data)

	data.Trove:Connect(player.CharacterAdded, function(character)
		OnCharacterAdded(player, character)
	end)

	data.Trove:Connect(player.CharacterRemoving, function(character)
		CleanupCharacter(player, character)
	end)

	if player.Character then
		data.Trove:Add(task.spawn(OnCharacterAdded, player, player.Character))
	end

	return data
end

local function DestroyPlayerData(player)
	local userId = player.UserId
	local data = PlayerData[userId]

	if not data then
		return
	end

	CleanupCharacter(player, data.Character)
	data.Trove:Destroy()
	data.Animation:OnUnequip()

	for _, gunClass in pairs(data.Guns) do
		gunClass:Destroy()
	end

	PlayerData[userId] = nil
end

function LoadoutHandler:Init()
	PacketSettings.Creation.RequestPlayerData.listen(function(_, player)
		CreatePlayerData(player)
		SendGunController(player)
		SendAbilityController(player)
	end)

	Players.PlayerAdded:Connect(CreatePlayerData)
	Players.PlayerRemoving:Connect(DestroyPlayerData)

	for _, player in ipairs(Players:GetPlayers()) do
		CreatePlayerData(player)
	end
end

return LoadoutHandler
