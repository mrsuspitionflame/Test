local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local Combat = Server:WaitForChild("Combat")
local CombatServices = Combat:WaitForChild("CombatServices")
local LoadoutService = require(CombatServices:WaitForChild("LoadoutService"))
local PacketManager = require(Definitions:WaitForChild("PacketManager"))

local GunService = {}

function GunService:Init()
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

		local gunClass = LoadoutService.GetGunClass(player, gun.Name)

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

		local gunClass = LoadoutService.GetGunClass(player, gun.Name)

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

			local gunClass = LoadoutService.GetGunClass(player, gun.Name)

			if not gunClass or gunClass.Gun ~= gun then
				return
			end
			gunClass:OnEquip()
		elseif action == "UnEquip" then
			local gunClass = LoadoutService.GetGunClass(player, gun.Name)

			if not gunClass or gunClass.Gun ~= gun then
				return
			end
			gunClass:OnUnequip()
		end
	end)
end

return GunService
