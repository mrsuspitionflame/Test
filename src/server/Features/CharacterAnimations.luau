local Players = game:GetService("Players")

ANIMATION_IDS = table.freeze({
		JUMP = "rbxassetid://104064553178165",
		WALK = "rbxassetid://92911553202111",
		FALL = "rbxassetid://76180328658621",
		SPRINT = "rbxassetid://122472086522812",
		SLIDE = "rbxassetid://87397276095774",
	})

local function onCharacterAdded(character)
	local animate = character:WaitForChild("Animate")

	animate.walk.WalkAnim.AnimationId = ANIMATION_IDS.WALK
	animate.jump.JumpAnim.AnimationId = ANIMATION_IDS.JUMP
	animate.fall.FallAnim.AnimationId = ANIMATION_IDS.FALL
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end)
