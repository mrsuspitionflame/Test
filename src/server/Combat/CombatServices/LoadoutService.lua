local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Combat = Server:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local PacketManager = require(Definitions:WaitForChild("PacketManager"))
local Utility = Shared:WaitForChild("Utility")

local GunClass = require(Classes:WaitForChild("GunClass"))
local AnimationClass = require(Classes:WaitForChild("AnimationClass"))
local ActionManager = require(Utility:WaitForChild("ActionManager"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local PlayerGunClasses = {}

local PlayerAnimationClasses = {}

local PlayerActionManagers = {}

local LoadedCharacters = {}

local LoadoutService = {}


function LoadoutService.GetGunClass(player, slotName)
	if PlayerGunClasses[player.UserId] then
		return PlayerGunClasses[player.UserId][slotName]
	end
	return nil
end

function LoadoutService.GetEquippedGunClass(player)
	local playerGunClasses = PlayerGunClasses[player.UserId]

	if not playerGunClasses then
		return nil
	end

	for _, gunClass in pairs(playerGunClasses) do
		if gunClass.Equipped then
			return gunClass
		end
	end

	return nil
end

local function DestroyPlayerGunClasses(player)
	local playerGunClasses = PlayerGunClasses[player.UserId]

	if not playerGunClasses then
		return
	end

	for _, gunClass in pairs(playerGunClasses) do
		gunClass:Destroy()
	end

	PlayerGunClasses[player.UserId] = nil
end

local function CreateCharacterLoadout(player, character)
	if LoadedCharacters[player.UserId] == character then
		return
	end

	LoadedCharacters[player.UserId] = character
	DestroyPlayerGunClasses(player)

	local animationClass = PlayerAnimationClasses[player.UserId]
	local actionManager = PlayerActionManagers[player.UserId]

	if not animationClass or not actionManager then
		warn(`Loadout dependencies missing for {player.Name}`)
		return
	end

	PlayerGunClasses[player.UserId] = {}

	for _, SlotName in ipairs(Slots) do
		print("Creating gun class for player:", player.Name, "slot:", SlotName)
		PlayerGunClasses[player.UserId][SlotName] =
			GunClass.new(player, "Rifle", SlotName, animationClass, actionManager)
		PacketManager.Creation.CreateGunController.sendTo({
			GunName = "Rifle",
			SlotName = SlotName,
		}, player)
	end
end

local function OnPlayerAdded(player)
	if PlayerAnimationClasses[player.UserId] then
		return
	end

	PlayerAnimationClasses[player.UserId] = AnimationClass.new(player)
	PlayerActionManagers[player.UserId] = ActionManager.new()

	player.CharacterAdded:Connect(function(character)
		CreateCharacterLoadout(player, character)
	end)

	player.CharacterRemoving:Connect(function(character)
		if LoadedCharacters[player.UserId] == character then
			LoadedCharacters[player.UserId] = nil
			DestroyPlayerGunClasses(player)
		end
	end)

	if player.Character then
		task.spawn(CreateCharacterLoadout, player, player.Character)
	end
end

local function OnPlayerRemoving(player)
	DestroyPlayerGunClasses(player)
	LoadedCharacters[player.UserId] = nil
	PlayerAnimationClasses[player.UserId] = nil
	PlayerActionManagers[player.UserId] = nil
end

function LoadoutService:Init()
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(OnPlayerAdded, player)
	end
end

return LoadoutService
