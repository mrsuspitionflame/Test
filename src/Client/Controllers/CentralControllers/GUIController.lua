local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUIStorage = ReplicatedStorage:WaitForChild("GUIStorage")
local CombatUI = GUIStorage:WaitForChild("CombatUI")
local CombatUIsources = require(CombatUI:WaitForChild("CombatUIsources"))
local Player = game:GetService("Players").LocalPlayer
local App = require(CombatUI:WaitForChild("App"))
local Vide = require(ReplicatedStorage.Packages.Vide)
local mount = Vide.mount

local GUIController = {}

GUIController.__index = GUIController

function GUIController.new(LoadoutSlotTools)
	local self = setmetatable({}, GUIController)
	print("Creating GUIController")
	self.LoadoutSlotTools = LoadoutSlotTools
	self.destroy = mount(function()
		return App(LoadoutSlotTools)
	end, Player:WaitForChild("PlayerGui"))

	self:Init()
	return self
end

function GUIController:Init()
	if CombatUIsources then
		print("CombatUIsources found")
	end
	CombatUIsources.KineticSlot.Ammo(self.LoadoutSlotTools.KineticSlot:GetAttribute("MagazineSize"))
	CombatUIsources.KineticSlot.ReserveAmmo(self.LoadoutSlotTools.KineticSlot:GetAttribute("ReserveAmmo"))
	CombatUIsources.EnergySlot.Ammo(self.LoadoutSlotTools.EnergySlot:GetAttribute("MagazineSize"))
	CombatUIsources.EnergySlot.ReserveAmmo(self.LoadoutSlotTools.EnergySlot:GetAttribute("ReserveAmmo"))
	CombatUIsources.HeavySlot.Ammo(self.LoadoutSlotTools.HeavySlot:GetAttribute("MagazineSize"))
	CombatUIsources.HeavySlot.ReserveAmmo(self.LoadoutSlotTools.HeavySlot:GetAttribute("ReserveAmmo"))
end

function GUIController:EquippedSlotChanged(newSlot)
	CombatUIsources.EquippedSlot(newSlot)
end

function GUIController:UnequipWeapon()
	CombatUIsources.EquippedSlot(nil)
end

function GUIController:UpdateAmmo(slotName, newAmmo, newReserveAmmo)
	if CombatUIsources[slotName] then
		CombatUIsources[slotName].Ammo(newAmmo)
		CombatUIsources[slotName].ReserveAmmo(newReserveAmmo)
	else
		warn("Invalid slot name: " .. slotName)
	end
end

return GUIController
