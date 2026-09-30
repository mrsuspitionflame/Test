local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Simulation = {}

local Initialized = false

local RegisteredPlayers = {}

local PlayerCombatClasses = {}

function Simulation:RegisterPlayer(player, combatClass)
	if RegisteredPlayers[player] then
		return
	end

	local Record = {
		Connections = Trove.new(),
		Generation = 0,
	}

	RegisteredPlayers[player] = Record
	PlayerCombatClasses[player] = combatClass
end

function Simulation:UnregisterPlayer(player)
	local Record = RegisteredPlayers[player]
	if not Record then
		return
	end

	RegisteredPlayers[player] = nil

	local combatClass = PlayerCombatClasses[player]
	PlayerCombatClasses[player] = nil
	if combatClass then
		combatClass:Destroy()
	end

	Record.Generation += 1

	Record.Connections:Destroy()
end

function Simulation:Init()
	if Initialized then
		return 
	end

	Initialized = true

	RunService:BindToSimulation(function(dt)
		for _, combatClass in pairs(PlayerCombatClasses) do
			combatClass:Step(dt)
		end
	end)
end

return Simulation
