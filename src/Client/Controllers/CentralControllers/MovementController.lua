local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local char
local hum

local MovementController = {}

MovementController.__index = MovementController

function MovementController.new(ActionManager, AnimationController)
	local self = setmetatable({}, MovementController)
	self.Trove = Trove.new()
	self.ActionManager = ActionManager
	self.AnimationController = AnimationController
	return self
end

function MovementController:OnCharacterAdded(character)
	char = character
	hum = char:WaitForChild("Humanoid")
end

function MovementController:Init() end

function MovementController:OnCharacterRemoved()
	self.Trove:Clean()
end

return MovementController
