local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

PacketSettings.Character.HeadMovement.OnServerEvent:Connect(function(player, data)
    local character = player.Character
    if character then
        local torso = character:FindFirstChild("Torso")
        if torso then
            local neck = torso:FindFirstChild("Neck")
            if neck then
                neck.C0 = data.NeckC0
            end
        end
    end
end)