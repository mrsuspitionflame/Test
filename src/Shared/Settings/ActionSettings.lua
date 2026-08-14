local ActionSettings = {}

ActionSettings.Weapon = {
	Fire = {
		BlockedStates = {
			WeaponState = { "EQUIPPING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {"RELOADING"},
			AbilityState = {},
			MovementState = {"SPRINTING"},
		}
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
			MovementState = {"SPRINTING"},
		}
	},

	Equip = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = {},
		}
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
		}
	},

	Aim = {
		BlockedStates = {
			WeaponState = { "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = {},
		},
		CancelStates = {
			WeaponState = {"RELOADING"},
			AbilityState = {},
			MovementState = {"SPRINTING"},
		}
	},
}

ActionSettings.Movement = {
	Slide = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = { "USING_ABILITY" },
			MovementState = { "SLIDING", "CROUCHING", "JUMPING", "FALLING" },
		},
	},

	Sprint = {
		BlockedStates = {
			WeaponState = { "FIRING", "EQUIPPING", "RELOADING" },
			AbilityState = {},
			MovementState = { "SLIDING", "JUMPING", "FALLING" },
		},
	},

	Crouch = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "SLIDING", "JUMPING", "FALLING" },
		},
	},

	Jump = {
		BlockedStates = {
			WeaponState = {},
			AbilityState = {},
			MovementState = { "SLIDING"},
		},
	},
}

return ActionSettings
