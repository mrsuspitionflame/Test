local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Client = script.Parent
local Controllers = Client:WaitForChild("Controllers")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

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

LoadoutController:Init()

Humanoid.StateChanged:Connect(function(oldState, newState)
    print("Humanoid state changed from:", oldState, "to:", newState)
end)