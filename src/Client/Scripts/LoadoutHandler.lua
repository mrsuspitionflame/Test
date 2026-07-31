local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Controllers = Shared:WaitForChild("Controllers")
local GunController = require(Controllers:WaitForChild("GunController"))
local player = game.Players.LocalPlayer



local LoadoutHandler = {}

function LoadoutHandler.Init()
    
end

return LoadoutHandler