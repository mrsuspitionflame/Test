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

		if typeof(gun) ~= "Instance" or not gun:IsA("Tool") then
			return
		end

		local character = player.Character
		local backpack = player:FindFirstChildOfClass("Backpack")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not character or not backpack or not humanoid or humanoid.Health <= 0 then
			return
		end

		if gun.Parent ~= backpack and gun.Parent ~= character then
			return
		end

		local gunClass = LoadoutService.GetGunClass(player, gun.Name)

		if not gunClass or gunClass.Gun ~= gun then
			return
		end

		if action == "Equip" then
			local equippedGunClass = LoadoutService.GetEquippedGunClass(player)

			if equippedGunClass and equippedGunClass ~= gunClass then
				if not equippedGunClass:OnUnequip() then
					return
				end
			end

			if gunClass:OnEquip() then
				humanoid:EquipTool(gun)
			end
		elseif action == "UnEquip" and gunClass:OnUnequip() then
			humanoid:UnequipTools()
		end
	end)

	PacketManager.Combat.AimEvent.listen(function(data, player)
		local gun = data.Gun
		local aiming = data.Aiming

		if typeof(gun) ~= "Instance" or not gun:IsA("Tool") then
			return
		end

		if gun.Parent ~= player.Character then
			return
		end

		local gunClass = LoadoutService.GetGunClass(player, gun.Name)

		if not gunClass or gunClass.Gun ~= gun then
			return
		end

		gunClass:SetAiming(aiming)
	end)
end

return GunService
