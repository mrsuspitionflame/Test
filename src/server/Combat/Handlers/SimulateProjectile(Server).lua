local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectileService = require(ReplicatedStorage.Shared.Utility.ProjectileService)

local SimulateProjectileServer = {}

local ActiveProjectiles = {}

local heartbeatConnection

function SimulateProjectileServer:CreateProjectile(config)
	if type(config.Id) ~= "string" or config.Id == "" or ActiveProjectiles[config.Id] then
		print(1)
		return nil
	end

	if config.Direction.Magnitude <= 0 then
		print(2)
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = config.IgnoreList or {}

	local projectile = ProjectileService:Create({
		Id = config.Id,
		Origin = config.Origin,
		Direction = config.Direction,
		Speed = config.Speed,
		Gravity = config.Gravity,
		Radius = config.Radius,
		MaxDistance = config.MaxDistance,
		Params = params,
	})

	projectile.Owner = config.Owner
	projectile.OnHit = config.OnHit

	ActiveProjectiles[projectile.Id] = projectile
	return projectile
end

local function removeProjectile(id, result)
	local projectile = ActiveProjectiles[id]

	if not projectile then
		return
	end

	ActiveProjectiles[id] = nil
	projectile.Destroyed = true

	if result and projectile.OnHit then
		task.spawn(projectile.OnHit, result)
	end
end

function SimulateProjectileServer:Init()
	if heartbeatConnection then
		return
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		for id, projectile in pairs(ActiveProjectiles) do
			local nextVelocity, displacement = ProjectileService:GetStep(projectile, dt)

			if displacement.Magnitude <= 0 then
				removeProjectile(id, nil)
				continue
			end

			local result = workspace:Spherecast(projectile.Position, projectile.Radius, displacement, projectile.Params)

			if result then
				projectile.Position += displacement.Unit * result.Distance

				removeProjectile(id, { Position = result.Position, Normal = result.Normal })
				continue
			end

			ProjectileService:Advance(projectile, nextVelocity, displacement)

			if projectile.Destroyed then
				removeProjectile(id, { Position = projectile.Position, Normal = -displacement.Unit })
			end
		end
	end)
end

return SimulateProjectileServer
