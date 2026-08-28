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
		RELOAD_DURATION = 0.5,

		EQUIP_DURATION = 0.5,

		BULLETS_PER_SHOT = 1,
		BULLET_RADIUS = 1,
		SPREAD = 2,

		ANIMATION_IDS = {
			FIRE = {
				VIEWMODEL = "rbxassetid://88702775679148",
				CHARACTER = "rbxassetid://89904110536643",
			},
			RELOAD = {
				VIEWMODEL = "rbxassetid://132550775897445",
				CHARACTER = "rbxassetid://130289391434673",
			},
			EQUIP = {
				VIEWMODEL = "rbxassetid://120968739308160",
				CHARACTER = "rbxassetid://116711246131231",
			},
			IDLE = {
				VIEWMODEL = "rbxassetid://122677278312794",
				CHARACTER = "rbxassetid://135394958155506",
			},
			JUMP = {
				VIEWMODEL = "rbxassetid://137370128498588",
			},
			WALK = {
				VIEWMODEL = "rbxassetid://130082404602417",
			},
			SPRINT = {
				VIEWMODEL = "rbxassetid://84670668880316",
			},
			SLIDE = {
				VIEWMODEL = "rbxassetid://135607630494819",
			},
		},
	},
}

return WeaponSettings
