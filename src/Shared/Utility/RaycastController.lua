local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local Effects = ReplicatedStorage:WaitForChild("Effects")
local laserBeamEffect = Effects:WaitForChild("LaserBeamEffect")

local EnvironmentImpactEffect = Effects:WaitForChild("EnvironmentImpactEffect")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local RayCastController = {}

export type RayResult = {
	Position: Vector3,
	Normal: Vector3,
	Instance: Instance?,
	Distance: number?,
}

function RayCastController.GetRayDirections(
	origin: CFrame,
	numberOfRays: number,
	spreadAngle: number,
	seed: number,
	range: number
)
	local random = Random.new(seed * 100_000)
	local rays = table.create(numberOfRays)

	for index = 1, numberOfRays do
		local roll = random:NextNumber(0, math.pi * 2)
		local pitch = math.sqrt(random:NextNumber()) * spreadAngle
		local rayCFrame = origin * CFrame.Angles(0, 0, roll) * CFrame.Angles(pitch, 0, 0)
		rays[index] = rayCFrame.LookVector * range
	end
	return rays
end

function RayCastController.CastRays(origin: Vector3, directions: { Vector3 }, ignoreList: { Instance }, radius: number)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = ignoreList

	local rayResults = {}
	if radius > 0 then
		for _, direction in directions do
			local raycastResult = workspace:Spherecast(origin, direction, radius, params)
			local rayResult: RayResult = {
				Position = origin + direction,
				Normal = direction.Unit,
			}

			if raycastResult then
				rayResult.Position = raycastResult.Position
				rayResult.Normal = raycastResult.Normal
				rayResult.Distance = raycastResult.Distance
				rayResult.Instance = raycastResult.Instance
			end

			table.insert(rayResults, rayResult)
		end
	else
		for _, direction in directions do
			local raycastResult = workspace:Raycast(origin, direction, params)

			local rayResult = {
				Position = origin + direction,
				Normal = direction.Unit,
			}

			if raycastResult then
				rayResult.Position = raycastResult.Position
				rayResult.Normal = raycastResult.Normal
				rayResult.Distance = raycastResult.Distance
				rayResult.Instance = raycastResult.Instance
			end

			table.insert(rayResults, rayResult)
		end
	end
	return rayResults
end

function RayCastController.DrawRayResults(origin: Vector3, rayResults: { any })
	for _, rayResult in rayResults do
		local distance = (origin - rayResult.Position).Magnitude
		local tweenTime = distance / 200
		local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local laser = laserBeamEffect:Clone()
		laser.CFrame = CFrame.lookAt(origin, rayResult.Position)
		laser.StartAttachment.Position = Vector3.zero
		laser.EndAttachment.Position = Vector3.new(0, 0, -distance)
		laser.Parent = Workspace
		local tween = TweenService:Create(laser.StartAttachment, tweenInfo, { Position = laser.EndAttachment.Position })
		tween:Play()
		tween.Completed:Once(function()
			laser:Destroy()
		end)

		if rayResult.Instance then
			local impact = EnvironmentImpactEffect:Clone()
			impact.CFrame = CFrame.lookAlong(rayResult.Position, rayResult.Normal)
			impact.Parent = Workspace

			impact.CircleEmitter:Emit(2)

			task.delay(0.5, function()
				impact:Destroy()
			end)
		end
	end
end

function RayCastController.ValidateVector3(value)
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < math.huge
		and math.abs(value.Y) < math.huge
		and math.abs(value.Z) < math.huge
end

function RayCastController.Init()
	PacketSettings.Combat.ReplicateShotEvent.listen(function(data)
		RayCastController.DrawRayResults(data.MuzzlePosition, data.RayResults)
	end)
end
return RayCastController
