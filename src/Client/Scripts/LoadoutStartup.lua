local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Controllers = Shared:WaitForChild("Controllers")
local GunController = require(Controllers:WaitForChild("GunController"))
local player = game.Players.LocalPlayer



local LoadoutStartup = {}

function LoadoutStartup.Init()
    player.CharacterAdded:Connect(function()
        local backpack = player:WaitForChild("Backpack")
        GunController.new(backpack:WaitForChild("KineticSlot")) 
    end)
end

return LoadoutStartup