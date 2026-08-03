local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Players = game:GetService("Players")

local Classes = Server:WaitForChild("Classes")
local ServerServices = Server:WaitForChild("ServerServices")

local LoadoutService = require(ServerServices:WaitForChild("LoadoutService"))
local GunClass = require(Classes:WaitForChild("GunClass"))

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")
local EquipGunRequest = Remotes:WaitForChild("EquipGunRequest")

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local PlayerGunClasses = {}

local GunService = {}

function GunService.CreateGunClass(player, LoadoutSlot)
	if not PlayerGunClasses[player.UserId] then
		PlayerGunClasses[player.UserId] = {}
	end
	PlayerGunClasses[player.UserId][LoadoutSlot.Name] = GunClass.new(player, LoadoutSlot)
end

function GunService.GetGunClass(player, slotName)
	if PlayerGunClasses[player.UserId] then
		return PlayerGunClasses[player.UserId][slotName]
	end
	return nil
end

function GunService:Init()
	Players.PlayerAdded:Connect(function(player)
		local character = player.Character or player.CharacterAdded:Wait()
		if character then
			local tool = LoadoutService.CreatePlayerTools(player, "Rifle", "KineticSlot")
			GunService.CreateGunClass(player, tool)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if PlayerGunClasses[player.UserId] then
			for _, gunClass in pairs(PlayerGunClasses[player.UserId]) do
				gunClass:Destroy()
			end
			PlayerGunClasses[player.UserId] = nil
		end
	end)

	FireGunRequest.OnServerEvent:Connect(function(player, gun, origin, seed)
		if
			typeof(gun) ~= "Instance"
			or not gun:IsA("Tool")
			or typeof(origin) ~= "CFrame"
			or typeof(seed) ~= "number"
		then
			return
		end

		if gun.Parent ~= player.Character then
			return
		end

		local playerGuns = PlayerGunClasses[player.UserId]
		local gunClass = playerGuns and playerGuns[gun.Name]

		if not gunClass or gunClass.Gun ~= gun then
			return
		end
		gunClass:Shoot(origin, seed)
	end)

	ReloadGunRequest.OnServerEvent:Connect(function(player, gun)
		if typeof(gun) ~= "Instance" or not gun:IsA("Tool") then
			return
		end

		-- Validate ownership and equipped state
		if gun.Parent ~= player.Character then
			return
		end

		local playerGuns = PlayerGunClasses[player.UserId]
		local gunClass = playerGuns and playerGuns[gun.Name]

		if not gunClass or gunClass.Gun ~= gun then
			return
		end

		gunClass:Reload()
	end)

	EquipGunRequest.OnServerEvent:Connect(function(player, gun, action)
		if action == "Equip" then
			print("EquipGunRequest received from player:", player.Name, "for gun:", gun and gun.Name, "action:", action)
			if typeof(gun) ~= "Instance" or not gun:IsA("Tool") then
				return
			end

			-- Validate ownership and equipped state
			if gun.Parent ~= player.Character then
				return
			end

			local playerGuns = PlayerGunClasses[player.UserId]
			local gunClass = playerGuns and playerGuns[gun.Name]

			if not gunClass or gunClass.Gun ~= gun then
				return
			end
			gunClass:OnEquip()
		elseif action == "UnEquip" then
			local playerGuns = PlayerGunClasses[player.UserId]
			local gunClass = playerGuns and playerGuns[gun.Name]

			if not gunClass or gunClass.Gun ~= gun then
				return
			end
			gunClass:OnUnequip()
		end
	end)
end

return GunService
