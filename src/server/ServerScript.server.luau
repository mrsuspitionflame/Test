local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Simulations = Shared:WaitForChild("Simulations")

local Server = script.Parent
local Combat = Server:WaitForChild("Combat")

local Handlers = Combat:WaitForChild("Handlers")
local Features = Server:WaitForChild("Features")

local WeaponHandler = require(Handlers:WaitForChild("WeaponHandler"))
local LoadoutHandler = require(Handlers:WaitForChild("LoadoutHandler"))
local SimulateProjectileServer = require(Features:WaitForChild("SimulateProjectile(Server)"))
local AbilityHandler = require(Handlers:WaitForChild("AbilityHandler"))
local MovementSimulation = require(Simulations:WaitForChild("MovementSimulation"))

MovementSimulation:Init()
AbilityHandler:Init()
WeaponHandler:Init()
LoadoutHandler:Init()
SimulateProjectileServer:Init()
