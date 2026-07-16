local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GunEvent = RemoteEvents:WaitForChild("GunEvent")

local GunSystemServer = {}

function GunSystemServer:CalculateDamange(buffList)
end

function GunSystemServer:Init()
    GunEvent.OnServerEvent:Connect(function(buffList)
        self:CalculateDamange(buffList)
    end)
end


return GunSystemServer