local MovementSettings = {
	JUMP = {
		JUMP_DELAY = 0.1,
		COYOTE_TIME = 0.12,
		JUMP_POWER = 48,
		DOUBLE_JUMP_POWER = 52,
	},

	SPRINT = {
		DEFAULT_WALK_SPEED = 18,
		SPRINT_WALK_SPEED = 30,
		DECELERATION_RATE = 48,
		ACCELERATION_RATE = 48,
	},

	SLIDE = {
		MIN_START_SPEED = 20,
		SLIDE_START_SPEED = 50,
		SLIDE_END_SPEED = 30,
		SLIDE_DURATION = 1,
	},

	ANIMATION_IDS = {
		JUMP = "rbxassetid://104064553178165",
		WALK = "rbxassetid://92911553202111",
		FALL = "rbxassetid://76180328658621",
		SPRINT = "rbxassetid://122472086522812",
		SLIDE = "rbxassetid://87397276095774",
	},
}

return MovementSettings
