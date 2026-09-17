local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local weaponSettings = require(Settings:WaitForChild("WeaponSettings"))
local GUIStorage = ReplicatedStorage:WaitForChild("GUIStorage")
local CombatUI = GUIStorage:WaitForChild("CombatUI")
local CombatUIsources = require(CombatUI:WaitForChild("CombatUIsources"))
local Player = game:GetService("Players").LocalPlayer
local App = require(CombatUI:WaitForChild("App"))
local Vide = require(ReplicatedStorage.Packages.Vide)
local mount = Vide.mount

local GUIHandler = {}

GUIHandler.__index = GUIHandler

function GUIHandler.new()
	local self = setmetatable({}, GUIHandler)
	self.destroy = mount(App, Player:WaitForChild("PlayerGui"))

	return self
end

function GUIHandler:SetCombatUIEnabled(visible)
	CombatUIsources.UIEnabled(visible)
end

function GUIHandler:InitializeSlot(weaponName, slotName)
	local weaponInfo = weaponSettings[weaponName]
	CombatUIsources[slotName].Ammo(weaponInfo.MAGAZINE_SIZE)
	CombatUIsources[slotName].ReserveAmmo(weaponInfo.RESERVE_AMMO)
	CombatUIsources[slotName].AmmoType(weaponInfo.AMMO_TYPE)
end

function GUIHandler:EquippedSlotChanged(newSlot)
	CombatUIsources.EquippedSlot(newSlot)
end

function GUIHandler:OnUnequip()
	CombatUIsources.EquippedSlot(nil)
end

function GUIHandler:UpdateAmmo(slotName, newAmmo, newReserveAmmo)
	if CombatUIsources[slotName] then
		CombatUIsources[slotName].Ammo(newAmmo)
		CombatUIsources[slotName].ReserveAmmo(newReserveAmmo)
	else
		warn("Invalid slot name: " .. slotName)
	end
end

function GUIHandler:Destroy()
	if self.destroy then
		self.destroy()
		self.destroy = nil
	end
end

return GUIHandler
