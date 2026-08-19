local Server = script.Parent
local Combat = Server:WaitForChild("Combat")
local InputHandlers = Combat:WaitForChild("InputHandlers")

local GunHandler = require(InputHandlers:WaitForChild("GunHandler"))
local LoadoutHandler = require(InputHandlers:WaitForChild("LoadoutHandler"))

GunHandler:Init()
LoadoutHandler:Init()
