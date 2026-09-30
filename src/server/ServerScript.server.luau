local Server = script.Parent
local Combat = Server:WaitForChild("Combat")

local Handlers = Combat:WaitForChild("Handlers")

local WeaponHandler = require(Handlers:WaitForChild("WeaponHandler"))
local LoadoutHandler = require(Combat:WaitForChild("LoadoutHandler"))
local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))
local AbilityHandler = require(Handlers:WaitForChild("AbilityHandler"))

AbilityHandler:Init()
WeaponHandler:Init()
LoadoutHandler:Init()
SimulateProjectileServer:Init()
