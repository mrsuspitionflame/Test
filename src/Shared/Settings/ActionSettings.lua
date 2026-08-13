<<<<<<< HEAD
local ActionSettings = {}

ActionSettings.Weapon = {
	Fire = {
		BlockedStates = {
			WeaponState = { "Equipping" },
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},

	Reload = {
		BlockedStates = {
			WeaponState = { "Firing", "Equipping", "Reloading" },
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},

	Equip = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},

	UnEquip = {
		BlockedStates = {
			WeaponState = { "Firing", "Equipping", "Reloading" },
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},
}

return ActionSettings
=======
local ActionSettings = {}

ActionSettings.Weapon = {
	Fire = {
		BlockedStates = {
			WeaponState = { "Equipping" },
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},

	Reload = {
		BlockedStates = {
			WeaponState = { "Firing", "Equipping", "Reloading" },
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},

	Equip = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},

	UnEquip = {
		BlockedStates = {
			WeaponState = { "Firing", "Equipping", "Reloading" },
			AbilityState = { "UsingAbility" },
			MovementState = {},
		},
	},
}

return ActionSettings
>>>>>>> b31ea3b85905e4cb6fe1151d9f125d9094901613
