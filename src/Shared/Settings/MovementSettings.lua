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

return MovementSettings
