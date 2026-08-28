local WeaponSettings = {
	HandCannon = {
		WEAPON_NAME = "HandCannon",
		WEAPON_TYPE = "HandCannon",

		AIM_TYPE = "ADS",
		FIRE_MODE = "Automatic",
		SHOT_TYPE = "Hitscan",
		RELOAD_TYPE = "Magazine",
		AMMO_TYPE = "Primary",

		AMMO = 32,
		MAGAZINE_SIZE = 32,
		RESERVE_AMMO = 360,
		DAMAGE = 15,
		RANGE = 100,
		FIRE_RATE = 900,
		HANDLING = 99,
		STABILITY = 99,
		BASE_RECOIL = 200,
		STIFFNESS = 90,
		DAMPING = 15,
		RELOAD_SPEED = 25,
		RELOAD_DURATION = 2.5,
		BULLETS_PER_SHOT = 1,
		BULLET_RADIUS = 1,
		SPREAD = 2,

		ANIMATION_IDS = {
			ViewModel = {
				FIRE = "rbxassetid://86681368059916",
				RELOAD = "rbxassetid://103958258470632",
				EQUIP = "rbxassetid://87420884077266",
			},
			Character = {
				FIRE = "rbxassetid://86681368059916",
				RELOAD = "rbxassetid://103958258470632",
				EQUIP = "rbxassetid://87420884077266",
			},
		},
	},
}

return WeaponSettings
