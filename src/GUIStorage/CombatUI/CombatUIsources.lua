local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local CombatUIsources = {
	EquippedSlot = Vide.source(),

	KineticSlot = {
		Ammo = Vide.source(0),
		ReserveAmmo = Vide.source(0),
	},

	EnergySlot = {
		Ammo = Vide.source(0),
		ReserveAmmo = Vide.source(0),
	},

	HeavySlot = {
		Ammo = Vide.source(0),
		ReserveAmmo = Vide.source(0),
	},
}

return CombatUIsources
