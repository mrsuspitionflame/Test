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

local function SendLoadout(player)
	local playerGunClasses = PlayerGunClasses[player.UserId]

	if not playerGunClasses then
		return
	end

	for slotName, gunClass in pairs(playerGunClasses) do
		PacketManager.Creation.CreateGunController.sendTo({
			GunName = gunClass.GunName,
			SlotName = slotName,
		}, player)
	end
end

local function CreateCharacterLoadout(player)
	local animationClass = PlayerAnimationClasses[player.UserId]
	local actionManager = PlayerActionManagers[player.UserId]

	if not animationClass or not actionManager then
		warn(`Loadout dependencies missing for {player.Name}`)
		return
	end

	PlayerGunClasses[player.UserId] = {}

	for _, slotName in ipairs(Slots) do
		print("Creating gun class for player:", player.Name, "slot:", slotName)
		PlayerGunClasses[player.UserId][slotName] =
			GunClass.new(player, "Rifle", slotName, animationClass, actionManager)
	end

	SendLoadout(player)
end

local function OnPlayerAdded(player)
	if PlayerAnimationClasses[player.UserId] then
		return
	end

	PlayerAnimationClasses[player.UserId] = AnimationClass.new(player)
	PlayerActionManagers[player.UserId] = ActionManager.new()

	local function OnCharacterAdded(character)
		if PlayerGunClasses[player.UserId] == nil then
			CreateCharacterLoadout(player)
			print("Created loadout for player:", player.Name)
		end

		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			PlayerActionManagers[player.UserId]:SetState("WeaponState", "Idle")
			local gunClass = LoadoutService.GetEquippedGunClass(player)
			if gunClass then
				gunClass:OnUnequip()
			end
		end)
	end

	player.CharacterAdded:Connect(OnCharacterAdded)

	if player.Character then
		task.spawn(OnCharacterAdded, player.Character)
	end

	player.CharacterRemoving:Connect(function()
		PlayerActionManagers[player.UserId]:SetState("WeaponState", "Idle")
		local gunClass = LoadoutService.GetEquippedGunClass(player)
		if gunClass then
			gunClass:OnUnequip()
		end
	end)
end

local function OnPlayerRemoving(player)
	DestroyPlayerGunClasses(player)
	PlayerAnimationClasses[player.UserId] = nil
	PlayerActionManagers[player.UserId] = nil
end

function LoadoutService:Init()
	PacketManager.Creation.RequestLoadout.listen(function(_, player)
		OnPlayerAdded(player)

		if not PlayerGunClasses[player.UserId] and player.Character then
			CreateCharacterLoadout(player)
		else
			SendLoadout(player)
		end
	end)

	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(OnPlayerAdded, player)
	end
end

return LoadoutService
