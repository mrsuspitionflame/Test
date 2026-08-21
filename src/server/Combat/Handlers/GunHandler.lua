local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Combat = Server:WaitForChild("Combat")
local LoadoutHandler = require(Combat:WaitForChild("LoadoutHandler"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local GunHandler = {}

function GunHandler:Init()
	PacketSettings.Combat.Weapon.ShootRequest.listen(function(data, player)
		local slotName = data.SlotName
		local origin = data.CFrame
		local seed = data.Seed

		if typeof(slotName) ~= "string" or typeof(origin) ~= "CFrame" or typeof(seed) ~= "number" then
			return
		end

		local gunClass = LoadoutHandler:GetGunClass(player, data.SlotName)

		if not gunClass or not gunClass.Equipped then
			return
		end
		gunClass:Shoot(origin, seed)
	end)

	PacketSettings.Combat.Weapon.ReloadRequest.listen(function(data, player)
		local slotName = data.SlotName

		local gunClass = LoadoutHandler:GetGunClass(player, slotName)

		if not gunClass or not gunClass.Equipped then
			return
		end

		gunClass:Reload()
	end)

	PacketSettings.Combat.Weapon.EquipRequest.listen(function(data, player)
		local slotName = data.SlotName
		local action = data.Action

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end

		local gunClass = LoadoutHandler:GetGunClass(player, slotName)

		if not gunClass then
			return
		end

		if action == "Equip" then
			local equippedGunClass = LoadoutHandler:GetEquippedGunClass(player)

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

	PacketSettings.Combat.Weapon.AimEvent.listen(function(data, player)
		local slotName = data.SlotName
		local aiming = data.Aiming

		local gunClass = LoadoutHandler:GetGunClass(player, slotName)

		if not gunClass or not gunClass.Equipped then
			return
		end

		gunClass:SetAiming(aiming)
	end)
end

return GunHandler
