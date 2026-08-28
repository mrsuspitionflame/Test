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

local WeaponClass = require(Classes:WaitForChild("WeaponClass"))
local AbilityClass = require(Classes:WaitForChild("AbilityClass"))
local StateManager = require(Utility:WaitForChild("StateManager"))
local Trove = require(Packages:WaitForChild("Trove"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local PlayerData = {}

local LoadoutHandler = {}

local function addAttachment(parent, name, position, orientation)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = position or Vector3.zero
	attachment.Orientation = orientation or Vector3.zero
	attachment.Parent = parent

	return attachment
end

local function setupCharacter(character)
	local rightHand = character:FindFirstChild("RightHand") or character:WaitForChild("Right Arm")

	local leftHand = character:FindFirstChild("LeftHand") or character:WaitForChild("Left Arm")

	addAttachment(rightHand, "WeaponGripAttachment", Vector3.new(0, -0.65, -0.5), Vector3.new(0, 0, 0))

	addAttachment(leftHand, "AbilityGripAttachment", Vector3.new(0, -1.2, 0), Vector3.new(0, 0, 0))
end

function LoadoutHandler:GetAbilityClass(player)
	local data = PlayerData[player.UserId]
	return data and data.Ability or nil
end

function LoadoutHandler:GetWeaponClass(player, slotName)
	local data = PlayerData[player.UserId]
	return data and data.Weapons[slotName] or nil
end

function LoadoutHandler:GetEquippedWeaponClass(player)
	local data = PlayerData[player.UserId]

	if not data then
		return nil
	end

	for _, weaponClass in pairs(data.Weapons) do
		if weaponClass.Equipped then
			return weaponClass
		end
	end

	return nil
end

local function UnequipPlayerWeapons(player, data)
	data.StateManager:SetState("WeaponState", "IDLE")

	local weaponClass = LoadoutHandler:GetEquippedWeaponClass(player)
	if weaponClass then
		weaponClass:OnUnequip()
	end
end

local function SendWeaponControllers(player)
	local data = PlayerData[player.UserId]

	if not data then
		return
	end

	for slotName, weaponClass in pairs(data.Weapons) do
		PacketSettings.Creation.CreateWeaponController.sendTo({
			WeaponName = weaponClass.WeaponName,
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

local function CreateWeaponClasses(player, data)
	for _, slotName in ipairs(Slots) do
		print("Creating weapon class for player:", player.Name, "slot:", slotName)
		data.Weapons[slotName] = WeaponClass.new(player, "HandCannon", slotName, data.StateManager)
	end
end

local function CreateAbilityController(player, data)
	print("Creating ability class for player:", player.Name)
	local AbilityInfo = { Grenade = "SolarGrenade" }
	data.Ability = AbilityClass.new(player, AbilityInfo, data.StateManager)
end

local function CleanupCharacter(player, character)
	local data = PlayerData[player.UserId]

	if not data or (character and data.Character ~= character) then
		return
	end

	data.Character = nil
	data.CharacterTrove:Clean()
	UnequipPlayerWeapons(player, data)
end

local function OnCharacterAdded(player, character)
	local data = PlayerData[player.UserId]
	if not data then
		return
	end

	data.CharacterTrove:Clean()
	data.Character = character

	setupCharacter(character)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or PlayerData[player.UserId] ~= data or data.Character ~= character then
		return
	end

	data.CharacterTrove:Connect(humanoid.Died, function()
		CleanupCharacter(player, character)
	end)
end

local function ConnectLoadoutSignals(player, data)
	data.Trove:Connect(data.StateManager.CancelStateSignal, function(stateType, cancelledState)
		if stateType ~= "EquippedState" or cancelledState ~= "EQUIPPED" then
			return
		end

		local weaponClass = LoadoutHandler:GetEquippedWeaponClass(player)

		if not weaponClass then
			return
		end

		data.StoredSlot = weaponClass.SlotName
		weaponClass:OnUnequip()
	end)

	data.Trove:Connect(data.StateManager.ReEquipWeaponSignal, function()
		local slotName = data.StoredSlot

		if not slotName then
			return
		end

		local weaponClass = data.Weapons[slotName]

		if not weaponClass or weaponClass.Equipped then
			return
		end

		data.StoredSlot = nil
		weaponClass:OnEquip()
	end)
end

local function CreatePlayerData(player)
	local userId = player.UserId
	local data = PlayerData[userId]

	if data then
		return data
	end

	data = {
		Weapons = {},
		Ability = nil,
		StateManager = StateManager.new(),
		Trove = Trove.new(),
		Character = nil,
	}
	data.CharacterTrove = data.Trove:Extend()
	PlayerData[userId] = data

	CreateWeaponClasses(player, data)
	ConnectLoadoutSignals(player, data)
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
<<<<<<< HEAD
	data.Animation:OnUnequip()

=======
>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669
	for _, weaponClass in pairs(data.Weapons) do
		weaponClass:Destroy()
	end
	PlayerData[userId] = nil
end

function LoadoutHandler:Init()
	PacketSettings.Creation.RequestPlayerData.listen(function(_, player)
		CreatePlayerData(player)
		SendWeaponControllers(player)
		SendAbilityController(player)
	end)

	Players.PlayerAdded:Connect(CreatePlayerData)
	Players.PlayerRemoving:Connect(DestroyPlayerData)

	for _, player in ipairs(Players:GetPlayers()) do
		CreatePlayerData(player)
	end
end

return LoadoutHandler
