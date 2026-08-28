local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Character = script.Parent
local Torso = Character:WaitForChild("Torso")

local root = Character:WaitForChild("HumanoidRootPart")
local RS = game:GetService("RunService")
local cam = workspace.CurrentCamera
local Neck = Torso:WaitForChild("Neck")
local delay = 0.25
local elapsed = 0
local cameraSide = "behind"

local y = Neck.C0.Y

RS.RenderStepped:Connect(function(dt)
	local offset = cam.CFrame.Position - root.Position

	if offset.Magnitude > 0.1 then
		local dot = root.CFrame.LookVector:Dot(offset.Unit)
		if dot > 0.1 then
			cameraSide = "front"
		elseif dot < -0.1 then
			cameraSide = "behind"
		end
	end

	local camDirection = root.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)

	local horizontalDirection, verticalDirection

	if cameraSide == "front" then
		horizontalDirection = camDirection.X
		verticalDirection = camDirection.Y
	else
		horizontalDirection = -camDirection.X
		verticalDirection = -camDirection.Y
	end

	Neck.C0 = CFrame.new(0, y, 0)
		* CFrame.Angles(0, math.rad(180), 0)
		* CFrame.Angles(0, horizontalDirection, 0)
		* CFrame.Angles(verticalDirection, 0, 0)
		* CFrame.Angles(math.rad(-90), 0, 0)

	elapsed += dt

	if elapsed >= delay then
		elapsed %= delay

		PacketSettings.Character.HeadMovement.send({
			NeckC0 = Neck.C0,
		})
	end
end)

PacketSettings.Character.ApplyHeadMovement.listen(function(data)
	local character = data.Player.Character
	local torso = character and character:FindFirstChild("Torso")
	local neck = torso and torso:FindFirstChild("Neck")

	if neck then
		neck.C0 = data.NeckC0
	end
end)
