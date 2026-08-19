local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local gunSettings = require(Settings:WaitForChild("GunSettings"))
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

function GUIController:SetCombatUIEnabled(visible)
	CombatUIsources.UIEnabled(visible)
end

function GUIController:InitializeSlot(gunName, slotName)
	local gunInfo = gunSettings[gunName]
	CombatUIsources[slotName].Ammo(gunInfo.MAGAZINE_SIZE)
	CombatUIsources[slotName].ReserveAmmo(gunInfo.RESERVE_AMMO)
	CombatUIsources[slotName].AmmoType(gunInfo.AMMO_TYPE)
end

function GUIController:EquippedSlotChanged(newSlot)
	CombatUIsources.EquippedSlot(newSlot)
end

function GUIController:OnUnequip()
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

function GUIController:Destroy()
	if self.destroy then
		self.destroy()
		self.destroy = nil
	end
end

return GUIController
