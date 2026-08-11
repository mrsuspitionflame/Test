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
		local SlotName = data.SlotName
		local Origin = data.CFrame
		local Seed = data.Seed

		if
			typeof(SlotName) ~= "string"
			or typeof(Origin) ~= "CFrame"
			or typeof(Seed) ~= "number"
		then
			return
		end

		local gunClass = LoadoutService.GetGunClass(player, data.SlotName)

		if not gunClass or not gunClass.Equipped then
			return
		end
		gunClass:Shoot(Origin, Seed)
	end)

	PacketManager.Combat.ReloadRequest.listen(function(data, player)
		local SlotName = data.SlotName

		local GunClass = LoadoutService.GetGunClass(player, SlotName)

		if not GunClass or not GunClass.Equipped then
			return
		end

		GunClass:Reload()
	end)

	PacketManager.Combat.EquipRequest.listen(function(data, player)
		local SlotName = data.SlotName
		local Action = data.Action

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end


		local GunClass = LoadoutService.GetGunClass(player, SlotName)

		if not GunClass then
			return
		end

		if Action == "Equip" then
			local equippedGunClass = LoadoutService.GetEquippedGunClass(player)

			if equippedGunClass and equippedGunClass ~= GunClass then
				if not equippedGunClass:OnUnequip() then
					return
				end
			end

			GunClass:OnEquip()
		elseif Action == "UnEquip" then
			GunClass:OnUnequip()
		end
	end)

	PacketManager.Combat.AimEvent.listen(function(data, player)
		local SlotName = data.SlotName
		local Aiming = data.Aiming

		local GunClass = LoadoutService.GetGunClass(player, SlotName)

		if not GunClass or not GunClass.Equipped then
			return
		end

		GunClass:SetAiming(Aiming)
	end)
end

return GunService
