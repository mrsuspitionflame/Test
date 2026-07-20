local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GunEvent = RemoteEvents:WaitForChild("GunEvent")
local CreateGun = RemoteEvents:WaitForChild("CreateGun")
local WeaponRuntime = require(ServerScriptService:WaitForChild("Classes"):WaitForChild("WeaponRuntime"))

local GunSystemServer = {}

function GunSystemServer:Init()
	GunEvent.OnServerEvent:Connect(function()
		print("something")
	end)
end

function GunSystemServer:CreateRuntimeInit()
	CreateGun.OnServerEvent:Connect(function(player, weapon)
		print("Creating gun for player:", player.Name, "with weapon:", weapon)
		-- Here you can add logic to create the gun runtime for the player
	end)
end

return GunSystemServer
