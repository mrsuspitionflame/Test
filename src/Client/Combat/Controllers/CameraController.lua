local CameraController = {}

function CameraController:IsFirstPerson()
	local camera = workspace.CurrentCamera
	local cameraPosition = camera.CFrame.Position
	local character = game.Players.LocalPlayer.Character

	if character then
		local head = character:FindFirstChild("Head")
		if head then
			local headPosition = head.Position
			local distance = (cameraPosition - headPosition).Magnitude
			return distance < 1 -- Adjust the threshold as needed
		end
	end

	return false
end

return CameraController
