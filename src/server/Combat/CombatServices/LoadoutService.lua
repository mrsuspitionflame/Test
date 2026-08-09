local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Combat = Server:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local Utility = Shared:WaitForChild("Utility")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))

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

function LoadoutService.CreatePlayerGun(player, gunName, slotName, animationClass, actionManager)
	local tool = LoadoutService.CreatePlayerTools(player, gunName, slotName)
	return GunClass.new(player, tool, animationClass, actionManager)
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

function LoadoutService.GetGunClass(player, slotName)
	if PlayerGunClasses[player.UserId] then
		return PlayerGunClasses[player.UserId][slotName]
	end
	return nil
end

function LoadoutService:Init()
	Players.PlayerAdded:Connect(function(player)
		PlayerAnimationClasses[player.UserId] = AnimationClass.new(player)
		PlayerActionManagers[player.UserId] = ActionManager.new()
		player.CharacterAdded:Connect(function()
			if not PlayerGunClasses[player.UserId] then
				PlayerGunClasses[player.UserId] = {}
			end

			for _, slotName in ipairs(Slots) do
				print("Creating gun class for player:", player.Name, "slot:", slotName)
				PlayerGunClasses[player.UserId][slotName] = LoadoutService.CreatePlayerGun(player, "Rifle", slotName, PlayerAnimationClasses[player.UserId], PlayerActionManagers[player.UserId])
			end
		end)

		player.CharacterRemoving:Connect(function()
			if PlayerGunClasses[player.UserId] then
				for _, gunClass in pairs(PlayerGunClasses[player.UserId]) do
					gunClass:Destroy()
				end
				PlayerGunClasses[player.UserId] = nil
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if PlayerGunClasses[player.UserId] then
			for _, gunClass in pairs(PlayerGunClasses[player.UserId]) do
				gunClass:Destroy()
			end
			PlayerGunClasses[player.UserId] = nil
		end
	end)
end

return LoadoutService
