local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local ProjectileService = require(Utility:WaitForChild("ProjectileService"))
local Debris = game:GetService("Debris")

local SimulateProjectileClient = {}

local ActiveProjectiles = {}
local renderConnection

function SimulateProjectileClient:CreateProjectile(config)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = config.IgnoreList or {}
	config.Params = params

	local projectile = ProjectileService:Create(config)

	projectile.Projectile = config.Projectile
	projectile.OnHit = config.OnHit

	ActiveProjectiles[projectile.Id] = projectile
	return projectile
end

function SimulateProjectileClient:RemoveProjectile(id, result)
	local projectile = ActiveProjectiles[id]

	if not projectile then
		return
	end

	ActiveProjectiles[id] = nil
	projectile.Destroyed = true

	if projectile.Projectile then
		Debris:AddItem(projectile.Projectile, 0.1)
	end

	if result and projectile.OnHit then
		task.spawn(projectile.OnHit, result)
	end
end

function SimulateProjectileClient:Init()
	if renderConnection then
		return
	end

	renderConnection = RunService.RenderStepped:Connect(function(dt)
		for id, projectile in pairs(ActiveProjectiles) do
			local nextVelocity, displacement = ProjectileService:GetStep(projectile, dt)

			if displacement.Magnitude <= 0 then
				print("Projectile has no displacement. Removing.")
				self:RemoveProjectile(id, nil)
				continue
			end

			local result = workspace:Spherecast(projectile.Position, projectile.Radius, displacement, projectile.Params)

			if result then
				projectile.Position += displacement.Unit * result.Distance

				if projectile.Projectile then
					projectile.Projectile.Position = projectile.Position
				end

				self:RemoveProjectile(id, { Position = result.Position, Normal = result.Normal })
				continue
			end

			ProjectileService:Advance(projectile, nextVelocity, displacement)

			if projectile.Projectile then
				projectile.Projectile.CFrame = CFrame.lookAlong(projectile.Position, projectile.Velocity)
			end

			if projectile.Destroyed then
				self:RemoveProjectile(id, { Position = projectile.Position, Normal = -displacement.Unit })
			end
		end
	end)
end

return SimulateProjectileClient
