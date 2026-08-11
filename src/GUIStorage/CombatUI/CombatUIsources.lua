local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local CombatUIsources = {
	EquippedSlot = Vide.source(),

	KineticSlot = {
		Ammo = Vide.source(0),
		ReserveAmmo = Vide.source(0),
		AmmoType = Vide.source()
	},

	EnergySlot = {
		Ammo = Vide.source(0),
		ReserveAmmo = Vide.source(0),
		AmmoType = Vide.source()
	},

	HeavySlot = {
		Ammo = Vide.source(0),
		ReserveAmmo = Vide.source(0),
		AmmoType = Vide.source()
	},
}

return CombatUIsources
