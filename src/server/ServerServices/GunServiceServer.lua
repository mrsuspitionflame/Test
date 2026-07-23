local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local Server = SSS:WaitForChild("Server")
local Classes = Server:WaitForChild("Classes")
local GunClass = require(Classes:WaitForChild("GunClass"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local CreateGunRequest = Remotes:WaitForChild("CreateGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")

local Guns = {} -- Table to hold all gun instances, indexed by player.UserId

local GunServiceServer = {}

function GunServiceServer:Init()
    CreateGunRequest.OnServerEvent:Connect(function(player, gunType)
        local gun = GunClass.CreateGun(player, gunType)
        Guns[player.UserId] = gun
    end)

    FireGunRequest.OnServerEvent:Connect(function(player)
        local gun = Guns[player.UserId]
        if gun then
            gun:Fire()
        end
    end)

    ReloadGunRequest.OnServerEvent:Connect(function(player)
        local gun = Guns[player.UserId]
        if gun then
            gun:Reload()
        end
    end)
end

return GunServiceServer