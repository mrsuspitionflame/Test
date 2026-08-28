local MovementSettings = {
	JUMP = {
		JUMP_DELAY = 0.1,
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
		SLIDE_START_SPEED = 34,
		SLIDE_END_SPEED = 20,
		SLIDE_DURATION = 1,
	},

	ANIMATION_IDS = {
		JUMP = "rbxassetid://104064553178165",
		WALK = "rbxassetid://92911553202111",
		FALL = "rbxassetid://76180328658621",
	},

	LOAD_ANIMATION_IDS = {
		SPRINT = "rbxassetid://122472086522812",
		SLIDE = "rbxassetid://87397276095774",
	},
}

MovementSettings.Walk = {
	DEFAULT_WALK_SPEED = 18,
}

MovementSettings.AnimationIds = {
	JUMP = "rbxassetid://75048322796577",
	FALL = "rbxassetid://75162449762383",
	SPRINT = "rbxassetid://103808337174171",
	WALK = "rbxassetid://122597034453437",
	-- Add more later
}

return MovementSettings
