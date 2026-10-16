local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Simulations = Shared:WaitForChild("Simulations")
local Client = script:FindFirstAncestor("Client")
local Visuals = Utility:WaitForChild("Visuals")
local Combat = Client:WaitForChild("Combat")
local Handlers = Combat:WaitForChild("Handlers")
local Player = game.Players.LocalPlayer

local MovementSimulation = require(Simulations:WaitForChild("MovementSimulation"))
local ReplicateRayCast = require(Visuals:WaitForChild("ReplicateRayCast"))
local LoadoutHandler = require(Handlers:WaitForChild("LoadoutHandler"))
local SimulateProjectileClient = require(Visuals:WaitForChild("SimulateProjectile(Client)"))

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera
camera.FieldOfView = 80

Player.CameraMode = Enum.CameraMode.Classic
Player.CameraMinZoomDistance = 0
Player.CameraMaxZoomDistance = 17

MovementSimulation:Init()
ReplicateRayCast:Init()
LoadoutHandler:Init()
SimulateProjectileClient:Init()
