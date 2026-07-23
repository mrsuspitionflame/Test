local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local CreateGunRequest = Remotes:WaitForChild("CreateGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")

local GunNetwork = {}

function GunNetwork.FireRequest()
    FireGunRequest:FireServer()
end

function GunNetwork.CreateGunRequest()
    CreateGunRequest:FireServer("Rifle")
end

function GunNetwork.ReloadRequest()
    ReloadGunRequest:FireServer()
end

return GunNetwork