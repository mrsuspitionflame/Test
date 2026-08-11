local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Client = script.Parent
local Controllers = Client:WaitForChild("Controllers")
local Player = game.Players.LocalPlayer

local RaycastController = require(Utility:WaitForChild("RaycastController"))
local LoadoutController = require(Controllers:WaitForChild("LoadoutController"))

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera
camera.FieldOfView = 80

Player.CameraMode = Enum.CameraMode.Classic
Player.CameraMinZoomDistance = 0
Player.CameraMaxZoomDistance = 17

RaycastController.Init()

LoadoutController.Init()
