local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Client = script.Parent
local Visuals = Client:WaitForChild("Visuals")
local Combat = Client:WaitForChild("Combat")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local ReplicateRayCast = require(Visuals:WaitForChild("ReplicateRayCast"))
local ReplicateAbility = require(Visuals:WaitForChild("ReplicateAbility"))
local CombatClassHandler = require(Combat:WaitForChild("Handlers"):WaitForChild("CombatClassHandler"))
local SimulateProjectileClient = require(Visuals:WaitForChild("SimulateProjectile(Client)"))
local SimulationFolder = Shared:WaitForChild("Simulation")
local Simulation = require(SimulationFolder:WaitForChild("Simulation"))

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera
camera.FieldOfView = 80

Player.CameraMode = Enum.CameraMode.Classic
Player.CameraMinZoomDistance = 0
Player.CameraMaxZoomDistance = 17

ReplicateRayCast:Init()
ReplicateAbility:Init()
CombatClassHandler:Init()
SimulateProjectileClient:Init()
Simulation:Init()
