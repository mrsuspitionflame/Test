local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))
local GUIStorage = ReplicatedStorage:WaitForChild("GUIStorage")
local CombatUI = GUIStorage:WaitForChild("CombatUI")
local CombatUIsources = require(CombatUI:WaitForChild("CombatUIsources"))
local Player = game:GetService("Players").LocalPlayer
local App = require(CombatUI:WaitForChild("App"))
local Vide = require(ReplicatedStorage.Packages.Vide)
local mount = Vide.mount

local GUIController = {}

GUIController.__index = GUIController

function GUIController.new()
	local self = setmetatable({}, GUIController)
	self.destroy = mount(App, Player:WaitForChild("PlayerGui"))

	return self
end

function GUIController:InitializeSlot(GunName, SlotName)
	local GunInfo = GunDefinitions[GunName]
	CombatUIsources[SlotName].Ammo(GunInfo.MagazineSize)
	CombatUIsources[SlotName].ReserveAmmo(GunInfo.ReserveAmmo)
	CombatUIsources[SlotName].AmmoType(GunInfo.AmmoType)
end

function GUIController:EquippedSlotChanged(newSlot)
	CombatUIsources.EquippedSlot(newSlot)
end

function GUIController:UnequipWeapon()
	CombatUIsources.EquippedSlot(nil)
end

function GUIController:UpdateAmmo(SlotName, NewAmmo, NewReserveAmmo)
	if CombatUIsources[SlotName] then
		CombatUIsources[SlotName].Ammo(NewAmmo)
		CombatUIsources[SlotName].ReserveAmmo(NewReserveAmmo)
	else
		warn("Invalid slot name: " .. SlotName)
	end
end


return GUIController
