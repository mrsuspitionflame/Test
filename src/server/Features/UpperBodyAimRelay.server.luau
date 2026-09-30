local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local UPPER_BODY_UPDATE_INTERVAL = 1 / 20
local MAX_AIM_PITCH = math.rad(70)
local MAX_AIM_YAW = math.rad(55)

local LastUpperBodyUpdate = {}

local function IsFiniteNumber(value)
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function HasLiveCharacter(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local torso = character and character:FindFirstChild("Torso")

	return humanoid ~= nil and humanoid.Health > 0 and torso ~= nil
end

PacketSettings.Character.UpperBodyAim.listen(function(data, player)
	if not IsFiniteNumber(data.Pitch) or not IsFiniteNumber(data.Yaw) then
		return
	end

	local now = os.clock()
	local lastUpdate = LastUpperBodyUpdate[player]

	if lastUpdate and now - lastUpdate < UPPER_BODY_UPDATE_INTERVAL then
		return
	end

	LastUpperBodyUpdate[player] = now

	if not HasLiveCharacter(player) then
		return
	end

	PacketSettings.Character.ApplyUpperBodyAim.sendToAllExcept({
		Player = player,
		Pitch = math.clamp(data.Pitch, -MAX_AIM_PITCH, MAX_AIM_PITCH),
		Yaw = math.clamp(data.Yaw, -MAX_AIM_YAW, MAX_AIM_YAW),
	}, player)
end)

Players.PlayerRemoving:Connect(function(player)
	LastUpperBodyUpdate[player] = nil
end)
