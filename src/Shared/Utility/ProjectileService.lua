local ProjectileSimulation = {}

function ProjectileSimulation.Create(config)
	return {
		Id = config.Id,

		Position = config.Origin,
		Velocity = config.Direction.Unit * config.Speed,
		Gravity = config.Gravity,

		Radius = config.Radius,
		Params = config.Params,

		Distance = 0,
		MaxDistance = config.MaxDistance or 500,
		Destroyed = false,
	}
end

function ProjectileSimulation.GetStep(projectile, dt)
	local nextVelocity = projectile.Velocity + projectile.Gravity * dt

	local displacement = (projectile.Velocity + nextVelocity) * 0.5 * dt

	local remaining = projectile.MaxDistance - projectile.Distance

	if displacement.Magnitude > remaining then
		displacement = displacement.Unit * remaining
	end

	return nextVelocity, displacement
end

function ProjectileSimulation.Advance(projectile, nextVelocity, displacement)
	projectile.Velocity = nextVelocity
	projectile.Position += displacement
	projectile.Distance += displacement.Magnitude

	if projectile.Distance >= projectile.MaxDistance then
		projectile.Destroyed = true
	end
end

return ProjectileSimulation
