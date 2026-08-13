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
