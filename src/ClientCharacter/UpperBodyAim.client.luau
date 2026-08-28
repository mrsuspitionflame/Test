local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = script.Parent

local SEND_INTERVAL = 0.1
local MAX_AIM_PITCH = math.rad(70)
local MAX_AIM_YAW = math.rad(55)
local ARM_PITCH_SCALE = 0.85
local ARM_YAW_SCALE = 0.35
local SMOOTHING_SPEED = 18

local Poses = {}
local SendElapsed = 0

local function IsFiniteNumber(value)
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function RestorePose(pose)
	if pose.Neck and pose.Neck.Parent then
		pose.Neck.C0 = pose.NeckBaseC0
	end

	if pose.RightShoulder and pose.RightShoulder.Parent then
		pose.RightShoulder.C0 = pose.RightShoulderBaseC0
	end

	if pose.LeftShoulder and pose.LeftShoulder.Parent then
		pose.LeftShoulder.C0 = pose.LeftShoulderBaseC0
	end
end

local function CreatePose(character)
	local torso = character and character:FindFirstChild("Torso")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local rightArm = character and character:FindFirstChild("Right Arm")
	local leftArm = character and character:FindFirstChild("Left Arm")
	local neck = torso and torso:FindFirstChild("Neck")
	local rightShoulder = torso and torso:FindFirstChild("Right Shoulder")
	local leftShoulder = torso and torso:FindFirstChild("Left Shoulder")

	if
		not torso
		or not root
		or not rightArm
		or not leftArm
		or not neck
		or not neck:IsA("Motor6D")
		or not rightShoulder
		or not rightShoulder:IsA("Motor6D")
		or not leftShoulder
		or not leftShoulder:IsA("Motor6D")
	then
		return nil
	end

	return {
		Character = character,
		Root = root,
		RightArm = rightArm,
		LeftArm = leftArm,
		Neck = neck,
		RightShoulder = rightShoulder,
		LeftShoulder = leftShoulder,
		NeckBaseC0 = neck.C0,
		RightShoulderBaseC0 = rightShoulder.C0,
		LeftShoulderBaseC0 = leftShoulder.C0,
		TargetPitch = 0,
		TargetYaw = 0,
		CurrentPitch = 0,
		CurrentYaw = 0,
		CurrentArmPitch = 0,
		CurrentArmYaw = 0,
		CameraSide = "behind",
	}
end

local function GetPose(player)
	local character = if player == LocalPlayer then LocalCharacter else player.Character
	local pose = Poses[player]

	if
		pose
		and pose.Character == character
		and pose.Neck.Parent
		and pose.RightShoulder.Parent
		and pose.LeftShoulder.Parent
	then
		return pose
	end

	if pose then
		RestorePose(pose)
	end

	pose = CreatePose(character)
	Poses[player] = pose
	return pose
end

local function HasEquippedWeapon(pose)
	return pose.RightArm:FindFirstChild("WeaponMotor") ~= nil or pose.LeftArm:FindFirstChild("WeaponMotor") ~= nil
end

local function GetLocalAim(pose)
	local camera = workspace.CurrentCamera
	if not camera then
		return 0, 0
	end

	local cameraOffset = camera.CFrame.Position - pose.Root.Position
	if cameraOffset.Magnitude > 0.1 then
		local cameraSideDot = pose.Root.CFrame.LookVector:Dot(cameraOffset.Unit)
		if cameraSideDot > 0.1 then
			pose.CameraSide = "front"
		elseif cameraSideDot < -0.1 then
			pose.CameraSide = "behind"
		end
	end

	local lookVector = camera.CFrame.LookVector
	if pose.CameraSide == "front" then
		lookVector = -lookVector
	end

	local localLook = pose.Root.CFrame:VectorToObjectSpace(lookVector)
	local pitch = math.asin(math.clamp(localLook.Y, -1, 1))
	local yaw = math.atan2(-localLook.X, -localLook.Z)

	return math.clamp(pitch, -MAX_AIM_PITCH, MAX_AIM_PITCH), math.clamp(yaw, -MAX_AIM_YAW, MAX_AIM_YAW)
end

local function ApplyPose(pose, deltaTime)
	local equipped = HasEquippedWeapon(pose)
	local armTargetPitch = if equipped then pose.TargetPitch else 0
	local armTargetYaw = if equipped then pose.TargetYaw else 0
	local alpha = 1 - math.exp(-SMOOTHING_SPEED * deltaTime)

	pose.CurrentPitch += (pose.TargetPitch - pose.CurrentPitch) * alpha
	pose.CurrentYaw += (pose.TargetYaw - pose.CurrentYaw) * alpha
	pose.CurrentArmPitch += (armTargetPitch - pose.CurrentArmPitch) * alpha
	pose.CurrentArmYaw += (armTargetYaw - pose.CurrentArmYaw) * alpha

	local headPitch = -math.sin(pose.CurrentPitch)
	local headYaw = math.sin(pose.CurrentYaw) * math.cos(pose.CurrentPitch)
	local pitchOffset = pose.CurrentArmPitch * ARM_PITCH_SCALE
	local yawOffset = pose.CurrentArmYaw * ARM_YAW_SCALE
	local shoulderOffset = CFrame.Angles(pitchOffset, yawOffset, 0)

	pose.Neck.C0 = CFrame.new(0, pose.NeckBaseC0.Y, 0)
		* CFrame.Angles(0, math.rad(180), 0)
		* CFrame.Angles(0, headYaw, 0)
		* CFrame.Angles(headPitch, 0, 0)
		* CFrame.Angles(math.rad(-90), 0, 0)

	pose.RightShoulder.C0 = CFrame.new(pose.RightShoulderBaseC0.Position)
		* shoulderOffset
		* pose.RightShoulderBaseC0.Rotation
	pose.LeftShoulder.C0 = CFrame.new(pose.LeftShoulderBaseC0.Position)
		* shoulderOffset
		* pose.LeftShoulderBaseC0.Rotation
end

local function OnUpperBodyAimReceived(data)
	local player = data.Player

	if
		not player
		or not player:IsA("Player")
		or player == LocalPlayer
		or not IsFiniteNumber(data.Pitch)
		or not IsFiniteNumber(data.Yaw)
	then
		return
	end

	local pose = GetPose(player)
	if not pose then
		return
	end

	pose.TargetPitch = math.clamp(data.Pitch, -MAX_AIM_PITCH, MAX_AIM_PITCH)
	pose.TargetYaw = math.clamp(data.Yaw, -MAX_AIM_YAW, MAX_AIM_YAW)
end

PacketSettings.Character.ApplyUpperBodyAim.listen(OnUpperBodyAimReceived)

local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
	local pose = Poses[player]
	if pose then
		RestorePose(pose)
		Poses[player] = nil
	end
end)

local PreSimulationConnection = RunService.PreSimulation:Connect(function(deltaTime)
	local localPose = GetPose(LocalPlayer)

	if localPose then
		local pitch, yaw = GetLocalAim(localPose)
		localPose.TargetPitch = pitch
		localPose.TargetYaw = yaw

		SendElapsed += deltaTime
		if SendElapsed >= SEND_INTERVAL then
			SendElapsed %= SEND_INTERVAL
			PacketSettings.Character.UpperBodyAim.send({
				Pitch = pitch,
				Yaw = yaw,
			})
		end
	end

	for player, pose in pairs(Poses) do
		local currentPose = GetPose(player)
		if currentPose then
			ApplyPose(currentPose, deltaTime)
		elseif pose then
			Poses[player] = nil
		end
	end
end)

script.Destroying:Connect(function()
	PlayerRemovingConnection:Disconnect()
	PreSimulationConnection:Disconnect()

	local listeners = PacketSettings.Character.ApplyUpperBodyAim.getListeners()
	local listenerIndex = table.find(listeners, OnUpperBodyAimReceived)
	if listenerIndex then
		table.remove(listeners, listenerIndex)
	end

	for _, pose in pairs(Poses) do
		RestorePose(pose)
	end

	table.clear(Poses)
end)
