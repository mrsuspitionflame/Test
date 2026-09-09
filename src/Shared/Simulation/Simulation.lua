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

function Simulation:RegisterPlayer(player, movementClass)
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
	PlayerCombatClasses[player] = movementClass

	local function OnCharacterAdded(character)
		Record.Generation += 1
		local generation = Record.Generation
		if PlayerCombatClasses[player] then
			PlayerCombatClasses[player]:OnCharacterRemoving()
		end

		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 30)
			local root = character:WaitForChild("HumanoidRootPart", 30)

			if not humanoid or not root then
				warn("Failed to attach movement simulation: missing an input action or character part")
				return
			end

			-- Ignore setup that finished after a respawn or removal.
			if
				not Running
				or RegisteredPlayers[player] ~= Record
				or Record.Generation ~= generation
				or player.Character ~= character
			then
				return
			end

			if not IsServer then
				-- Track the local character's sprint attributes
				-- and humanoid properties for prediction.
				RunService:SetPredictionMode(root, Enum.PredictionMode.On)
				RunService:SetPredictionMode(humanoid, Enum.PredictionMode.On)
			end

			if PlayerCombatClasses[player] then
				PlayerCombatClasses[player]:OnCharacterAdded(character, humanoid, root)
			end
		end)
	end

	Record.Connections:Add(player.CharacterAdded:Connect(OnCharacterAdded))

	Record.Connections:Add(player.CharacterRemoving:Connect(function()
		Record.Generation += 1
		if PlayerCombatClasses[player] then
			PlayerCombatClasses[player]:OnCharacterRemoving()
		end
	end))

	if player.Character then
		OnCharacterAdded(player.Character)
	end
end
function Simulation:UnregisterPlayer(player)
	local Record = RegisteredPlayers[player]
	if not Record then
		return
	end

	RegisteredPlayers[player] = nil

	if PlayerCombatClasses[player] then
		PlayerCombatClasses[player]:Destroy()
	end
	PlayerCombatClasses[player] = nil

	Record.Generation += 1

	Record.Connections:Destroy()
end

function Simulation:Init()
	if Initialized then
		return CleanupSimulation
	end

	Initialized = true

	local SimulationConnection = RunService:BindToSimulation(function(dt)
		for _, movementClass in pairs(PlayerCombatClasses) do
			movementClass:Step(dt)
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
