local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("Finding gui storage")
local GUIStorage = ReplicatedStorage:WaitForChild("GUIStorage")
print("Found gui storage")
local CombatUI = GUIStorage:WaitForChild("CombatUI")
local Player = game:GetService("Players").LocalPlayer
local App = require(CombatUI:WaitForChild("App"))
local Vide = require(ReplicatedStorage.Packages.Vide)
local mount = Vide.mount

local GUIController = {}

GUIController.__index = GUIController

function GUIController.new()
	print("GUIController.new() called")
	local self = setmetatable({}, GUIController)
	self.destroy = mount(App, Player:WaitForChild("PlayerGui"))
	return self
end

return GUIController
