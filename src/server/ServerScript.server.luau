local Server = script.Parent
local ServerServices = Server:WaitForChild("ServerServices")
local GunServiceServer = require(ServerServices:WaitForChild("GunServiceServer"))

GunServiceServer:Init()