local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SimulationFolder = Shared:WaitForChild("Simulation")
local Simulation = require(SimulationFolder:WaitForChild("Simulation"))

Simulation:Init()
