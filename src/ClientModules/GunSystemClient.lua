local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIP = game:GetService("UserInputService")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GunEvent = RemoteEvents:WaitForChild("GunEvent")
local CreateGun = RemoteEvents:WaitForChild("CreateGun")
local GunSystemClient = {}

function GunSystemClient:Init(mouse)
	mouse.Button1Down:Connect(function()
		GunEvent:FireServer()
	end)
end

function GunSystemClient:CreateRuntime(weapon)
	UIP.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			CreateGun:FireServer(weapon)
		end
	end)
end


return GunSystemClient
