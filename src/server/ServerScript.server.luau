local Server = script.Parent
local Combat = Server:WaitForChild("Combat")
local Handlers = Combat:WaitForChild("Handlers")

local GunHandler = require(Handlers:WaitForChild("GunHandler"))
local LoadoutHandler = require(Combat:WaitForChild("LoadoutHandler"))
local SimulateProjectileServer = require(Handlers:WaitForChild("SimulateProjectile(Server)"))
local AbilityHandler = require(Handlers:WaitForChild("AbilityHandler"))

AbilityHandler:Init()
GunHandler:Init()
LoadoutHandler:Init()
SimulateProjectileServer:Init()
