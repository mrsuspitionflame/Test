local StateSettings = {}

StateSettings.Weapon = {
	Fire = {
		BlockedStates = {
			WeaponState = { "EQUIPPING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = { "RELOADING" },
			AbilityState = {},
			MovementState = { "SPRINTING" },
		},
	},

	Reload = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "SPRINTING" },
		},
	},

	Equip = {
		BlockedStates = {
			WeaponState = { "EQUIPPING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		},
	},

	UnEquip = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		},
	},

	Aim = {
		BlockedStates = {
			WeaponState = { "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = { "RELOADING" },
			AbilityState = {},
			MovementState = { "SPRINTING" },
		},
	},
}

StateSettings.Movement = {
	Slide = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = { "SLIDING", "CROUCHING", "JUMPING", "FALLING" },
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "SPRINTING" },
		},
	},

	Sprint = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = {},
			MovementState = { "SLIDING" },
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
			AimState = { "AIMING" },
		},
	},

	Crouch = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "SLIDING", "JUMPING", "FALLING" },
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		},
	},

	Jump = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		},
	},
}

return StateSettings
