local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Client = script.Parent
local Scripts = Client:WaitForChild("Scripts")
local Player = game.Players.LocalPlayer

local LoadoutHandler = require(Scripts:WaitForChild("LoadoutHandler"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))

Player.CameraMode = Enum.CameraMode.Classic
Player.CameraMinZoomDistance = 15
Player.CameraMaxZoomDistance = 15
task.spawn(function()
	task.wait(0.1)
	Player.CameraMinZoomDistance = 0
end)

LoadoutHandler.Init()
RaycastController.Init()
