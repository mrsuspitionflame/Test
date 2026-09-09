local Players = game:GetService("Players")

local WALK_ID = "rbxassetid://92911553202111"
local JUMP_ID = "rbxassetid://104064553178165"
local FALL_ID = "rbxassetid://76180328658621"

local function onCharacterAdded(character)
	local animate = character:WaitForChild("Animate")

	animate.walk.WalkAnim.AnimationId = WALK_ID
	animate.jump.JumpAnim.AnimationId = JUMP_ID
	animate.fall.FallAnim.AnimationId = FALL_ID
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end)
