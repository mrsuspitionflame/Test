local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Players = game:GetService("Players")

local Classes = Server:WaitForChild("Classes")
local ServerServices = Server:WaitForChild("ServerServices")

local LoadoutService = require(ServerServices:WaitForChild("LoadoutService"))
local GunClass = require(Classes:WaitForChild("GunClass"))

local PacketManager = require(Utility:WaitForChild("PacketManager"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local PlayerGunClasses = {}

local GunService = {}

function GunService.GetGunClass(player, slotName)
	if PlayerGunClasses[player.UserId] then
		return PlayerGunClasses[player.UserId][slotName]
	end
	return nil
end

function GunService:Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			if not PlayerGunClasses[player.UserId] then
				PlayerGunClasses[player.UserId] = {}
			end

			for _, slotName in ipairs(Slots) do
				PlayerGunClasses[player.UserId][slotName] = LoadoutService.CreatePlayerGun(player, "Rifle", slotName)
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

	PacketManager.Combat.ShootRequest.listen(function(data, player)
		local gun = data.Gun
		local origin = data.CFrame
		local seed = data.Seed

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

	PacketManager.Combat.ReloadRequest.listen(function(data, player)
		local gun = data.Gun
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

	PacketManager.Combat.EquipRequest.listen(function(data, player)
		local gun = data.Gun
		local action = data.Action
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
