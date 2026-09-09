local StateSettings = {}

-- Components apply these cancellation rules after an action is accepted.

StateSettings.Ability = {
	Grenade = {
		BlockedStates = {
			WeaponState = { "EQUIPPING", "FIRING", "RELOADING" },
			AbilityState = { "USING_GRENADE" },
			MovementState = {},
		},
		CancelStates = {
			MovementState = { "SPRINTING" },
			EquippedState = { "EQUIPPED" },
			AimState = { "AIMING" },
		},
	},
}

StateSettings.Weapon = {
	Fire = {
		BlockedStates = {
			WeaponState = { "EQUIPPING" },
			AbilityState = { "USING_GRENADE" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = { "RELOADING" },
			MovementState = { "SPRINTING" },
		},
	},

	Reload = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_GRENADE" },
			MovementState = {},
		},
		CancelStates = {
			MovementState = { "SPRINTING" },
		},
	},

	Equip = {
		BlockedStates = {
			WeaponState = { "EQUIPPING" },
			AbilityState = { "USING_GRENADE" },
			MovementState = {},
		},
		CancelStates = {},
	},

	UnEquip = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = {},
			MovementState = {},
		},
		CancelStates = {},
	},

	Aim = {
		BlockedStates = {
			WeaponState = { "EQUIPPING" },
			AbilityState = { "USING_GRENADE" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = { "RELOADING" },
			MovementState = { "SPRINTING" },
		},
	},
}

StateSettings.Movement = {
	Slide = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_GRENADE" },
			MovementState = { "SLIDING", "CROUCHING", "JUMPING", "FALLING" },
		},
		CancelStates = {
			MovementState = { "SPRINTING" },
		},
	},

	Sprint = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = {},
			MovementState = {},
		},
		CancelStates = {
			AimState = { "AIMING" },
		},
	},

	Crouch = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "SLIDING", "JUMPING", "FALLING" },
		},
		CancelStates = {},
	},

	Jump = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		},
		CancelStates = {},
	},

	DoubleJump = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "JUMPING" },
		},
		CancelStates = {},
	},
}

return StateSettings
