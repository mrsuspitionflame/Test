local RunService = game:GetService("RunService")

local MovementSimulation = {}

local Initialized = false

local PlayerMovementClasses = {}

function MovementSimulation:BindPlayerMovementClass(player, movementClass)
	PlayerMovementClasses[player] = movementClass
end

function MovementSimulation:UnbindPlayerMovementClass(player)
	local movementClass = PlayerMovementClasses[player]
	PlayerMovementClasses[player] = nil
	if movementClass then
		movementClass:Destroy()
	end
end

function MovementSimulation:Init()
	if Initialized then
		return
	end

	Initialized = true

	RunService:BindToSimulation(function(dt)
		for _, movementClass in pairs(PlayerMovementClasses) do
			movementClass:Step(dt)
		end
	end)
end

return MovementSimulation
