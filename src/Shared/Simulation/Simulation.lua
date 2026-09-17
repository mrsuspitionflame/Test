local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inputs = ReplicatedStorage:WaitForChild("Inputs")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Simulation = {}

local IsServer = RunService:IsServer()
local Running = true
local Initialized = false
local CleanupSimulation = nil

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

	if IsServer then
		local inputClone = Inputs:Clone()
		inputClone.Parent = player
		inputClone.Name = "Inputs"
	end

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
		return CleanupSimulation
	end

	Initialized = true

	local SimulationConnection = RunService:BindToSimulation(function(dt)
		for _, combatClass in pairs(PlayerCombatClasses) do
			combatClass:Step(dt)
		end
	end)

	-- Return a cleanup function to the loader.
	CleanupSimulation = function()
		if not Running then
			return
		end

		Running = false
		SimulationConnection:Disconnect()

		local playersToRemove = {}
		for player in pairs(RegisteredPlayers) do
			table.insert(playersToRemove, player)
		end

		for _, player in ipairs(playersToRemove) do
			self:UnregisterPlayer(player)
		end
	end

	return CleanupSimulation
end

return Simulation
