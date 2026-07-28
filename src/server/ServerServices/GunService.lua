local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local Server = SSS:WaitForChild("Server")

local ServerNetworks = Server:WaitForChild("ServerNetworks")
local GunNetworkServer = require(ServerNetworks:WaitForChild("GunNetwork(Server)"))

local Classes = Server:WaitForChild("Classes")
local GunClass = require(Classes:WaitForChild("GunClass"))

local Guns = {} -- Table to hold all gun instances, indexed by player.UserId

local GunServiceServer = {}

function GunServiceServer:Init()
	GunNetworkServer.OnCreateGunRequest(function(a0: Player, ...) end)
end

return GunServiceServer
