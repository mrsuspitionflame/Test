local MovementSettings = {}

MovementSettings.Jump = {
	JUMP_DELAY = 0.1,
	JUMP_POWER = 48,
	DOUBLE_JUMP_POWER = 52,
}

MovementSettings.Sprint = {
	DEFAULT_WALK_SPEED = 18,
	SPRINT_WALK_SPEED = 28,
}

MovementSettings.Slide = {
	MIN_START_SPEED = 20,
	SLIDE_START_SPEED = 34,
	SLIDE_END_SPEED = 20,
	SLIDE_DURATION = 1,
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
