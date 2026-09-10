local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Combat = Server:WaitForChild("Combat")
local LoadoutHandler = require(Combat:WaitForChild("LoadoutHandler"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local WeaponHandler = {}

function WeaponHandler:Init()
	PacketSettings.Combat.Weapon.FireRequest.listen(function(data, player)
		local SlotName = data.SlotName
		local Action = data.Action
		local Origin = data.Origin
		local Seed = data.Seed

		if
			typeof(SlotName) ~= "string"
			or typeof(Action) ~= "string"
			or (Origin ~= nil and typeof(Origin) ~= "CFrame")
			or (Seed ~= nil and typeof(Seed) ~= "number")
		then
			return
		end

		local CombatClasses = LoadoutHandler:GetCombatClasses(player)

		if not CombatClasses then
			return
		end

		local WeaponClass = CombatClasses.WeaponClasses[SlotName]

		if not WeaponClass or CombatClasses.EquippedWeaponClass ~= WeaponClass then
			return
		end

		if Action == "Held" then
			WeaponClass.Firing:Held(data)
		elseif Action == "Released" then
			WeaponClass.Firing:Released(data)
		elseif Action == "Fire" then
			WeaponClass.Firing:Fire(data)
		elseif Action == "Cancelled" then
			WeaponClass.Firing:Cancelled(data)
		end
	end)

	PacketSettings.Combat.Weapon.ReloadRequest.listen(function(data, player)
		local Action = data.Action
		local SlotName = data.SlotName

		local CombatClasses = LoadoutHandler:GetCombatClasses(player)
		local WeaponClass = CombatClasses and CombatClasses.WeaponClasses[SlotName]

		if not WeaponClass or CombatClasses.EquippedWeaponClass ~= WeaponClass then
			return
		end

		if Action == "Held" then
			WeaponClass.Reloading:Held()
		elseif Action == "Released" then
			WeaponClass.Reloading:Released()
		elseif Action == "Cancelled" then
			WeaponClass.Reloading:Cancelled()
		end
	end)

	PacketSettings.Combat.Weapon.AimRequest.listen(function(data, player)
		local SlotName = data.SlotName
		local Action = data.Action

		local CombatClasses = LoadoutHandler:GetCombatClasses(player)
		local WeaponClass = CombatClasses and CombatClasses.WeaponClasses[SlotName]

		if not WeaponClass or CombatClasses.EquippedWeaponClass ~= WeaponClass then
			return
		end

		if Action == "Held" then
			WeaponClass.Aiming:Held()
		elseif Action == "Released" then
			WeaponClass.Aiming:Released()
		elseif Action == "Cancelled" then
			WeaponClass.Aiming:Cancelled()
		end
	end)

	PacketSettings.Combat.Weapon.EquipRequest.listen(function(data, player)
		local slotName = data.SlotName
		local action = data.Action

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end

		local CombatClasses = LoadoutHandler:GetCombatClasses(player)
		local WeaponClass = CombatClasses and CombatClasses.WeaponClasses[slotName]

		if not WeaponClass then
			return
		end

		if action == "Equip" then
			local EquippedWeaponClass = CombatClasses:GetEquippedWeaponClass()

			if EquippedWeaponClass and EquippedWeaponClass ~= WeaponClass then
				if not EquippedWeaponClass:OnUnequip() then
					return
				end
			end

			WeaponClass:OnEquip()
		elseif action == "UnEquip" then
			WeaponClass:OnUnequip()
		end
	end)
end

return WeaponHandler
