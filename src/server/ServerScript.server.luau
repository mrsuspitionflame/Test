local Server = script.Parent
local ServerServices = Server:WaitForChild("ServerServices")
local GunService = require(ServerServices:WaitForChild("GunService"))

GunService.Init()
