local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GunEvent = RemoteEvents:WaitForChild("GunEvent")

local GunSystemClient = {}

function GunSystemClient:Init(mouse)
	mouse.Button1Down:Connect(function()
		GunEvent:FireServer()
	end)
end

return GunSystemClient
