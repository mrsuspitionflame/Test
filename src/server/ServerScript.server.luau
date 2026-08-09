local Server = script.Parent
local Combat = Server:WaitForChild("Combat")
local CombatServices = Combat:WaitForChild("CombatServices")

local GunService = require(CombatServices:WaitForChild("GunService"))
local LoadoutService = require(CombatServices:WaitForChild("LoadoutService"))

print("Initializing CombatService and LoadoutService...")
GunService:Init()
LoadoutService:Init()
