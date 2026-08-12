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
		local slotName = data.SlotName
		local origin = data.CFrame
		local seed = data.Seed

		if
			typeof(slotName) ~= "string"
			or typeof(origin) ~= "CFrame"
			or typeof(seed) ~= "number"
		then
			return
		end

		local gunClass = LoadoutService.GetGunClass(player, data.SlotName)

		if not gunClass or not gunClass.Equipped then
			return
		end
		gunClass:Shoot(origin, seed)
	end)

	PacketManager.Combat.ReloadRequest.listen(function(data, player)
		local slotName = data.SlotName

		local gunClass = LoadoutService.GetGunClass(player, slotName)

		if not gunClass or not gunClass.Equipped then
			return
		end

		gunClass:Reload()
	end)

	PacketManager.Combat.EquipRequest.listen(function(data, player)
		local slotName = data.SlotName
		local action = data.Action

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end


		local gunClass = LoadoutService.GetGunClass(player, slotName)

		if not gunClass then
			return
		end

		if action == "Equip" then
			local equippedGunClass = LoadoutService.GetEquippedGunClass(player)

			if equippedGunClass and equippedGunClass ~= gunClass then
				if not equippedGunClass:OnUnequip() then
					return
				end
			end

			gunClass:OnEquip()
		elseif action == "UnEquip" then
			gunClass:OnUnequip()
		end
	end)

	PacketManager.Combat.AimEvent.listen(function(data, player)
		local slotName = data.SlotName
		local aiming = data.Aiming

		local gunClass = LoadoutService.GetGunClass(player, slotName)

		if not gunClass or not gunClass.Equipped then
			return
		end

		gunClass:SetAiming(aiming)
	end)
end

return GunService
