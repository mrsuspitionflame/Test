local Players = game:GetService("Players")

local function AddAttachment(parent, name, position, orientation)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = position or Vector3.zero
	attachment.Orientation = orientation or Vector3.zero
	attachment.Parent = parent

	return attachment
end

local function SetupCharacter(character)
	local RightHand = character:FindFirstChild("RightHand") or character:WaitForChild("Right Arm")

	local LeftHand = character:FindFirstChild("LeftHand") or character:WaitForChild("Left Arm")

	AddAttachment(RightHand, "WeaponGripAttachment", Vector3.new(0, -0.65, -0.5), Vector3.new(0, 0, 0))

	AddAttachment(LeftHand, "AbilityGripAttachment", Vector3.new(0, -1.2, 0), Vector3.new(0, 0, 0))
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(SetupCharacter)

	if player.Character then
		task.spawn(SetupCharacter, player.Character)
	end
end)