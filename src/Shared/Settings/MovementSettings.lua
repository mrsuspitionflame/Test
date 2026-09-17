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
		SLIDE_DURATION = 0.7,
	},

}

return MovementSettings
