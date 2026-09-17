local Server = script.Parent
local Combat = Server:WaitForChild("Combat")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SimulationFolder = Shared:WaitForChild("Simulation")

local Simulation = require(SimulationFolder:WaitForChild("Simulation"))
local CombatClassesHandler = require(Combat:WaitForChild("CombatClassesHandler"))

CombatClassesHandler:Init()
Simulation:Init()