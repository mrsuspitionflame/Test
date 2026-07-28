local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local CreateGunRequest = Remotes:WaitForChild("CreateGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("CreateGunRequest")

local GunNetwork = {}

function GunNetwork.OnFireRequest(callback)
	return FireGunRequest.OnServerEvent:Connect(callback)
end

function GunNetwork.OnCreateGunRequest(callback)
	return CreateGunRequest.OnServerEvent:Connect(callback)
end

function GunNetwork.OnReloadRequest(callback)
	return ReloadGunRequest.OnServerEvent:Connect(callback)
end

return GunNetwork
