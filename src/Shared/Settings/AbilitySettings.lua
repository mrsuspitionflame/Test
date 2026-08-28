local AbilitySettings = {
	Grenade = {
		SolarGrenade = {
			ABILITY_TYPE = "Grenade",
			SPEED = 100,
			GRAVITY = -33,
			RADIUS = 1,
			CAST_DURATION = 0.3,
			MAX_DISTANCE = 200,
			LAST_DURATION = 5,

			ANIMATION_IDS = {
				HELD = {
					VIEWMODEL = "rbxassetid://117611768523259",
					CHARACTER = "rbxassetid://76705917824184",
				},
				RELEASED = {
					VIEWMODEL = nil,
					CHARACTER = nil,
				},
			},
		},
	},
}
return AbilitySettings
