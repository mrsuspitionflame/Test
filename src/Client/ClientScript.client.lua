local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Client = script.Parent
local Controllers = Client:WaitForChild("Controllers")
local Player = game.Players.LocalPlayer

local RaycastController = require(Utility:WaitForChild("RaycastController"))
local LoadoutController = require(Controllers:WaitForChild("LoadoutController"))

Player.CameraMode = Enum.CameraMode.Classic
Player.CameraMinZoomDistance = 15
Player.CameraMaxZoomDistance = 15
task.spawn(function()
	task.wait(0.1)
	Player.CameraMinZoomDistance = 0
end)

RaycastController.Init()

LoadoutController.Init()
