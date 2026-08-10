local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUIStorage = ReplicatedStorage:WaitForChild("GUIStorage")
local CombatUI = GUIStorage:WaitForChild("CombatUI")
local Player = game:GetService("Players").LocalPlayer
local App = require(CombatUI:WaitForChild("App"))
local Vide = require(ReplicatedStorage.Packages.Vide)
local mount = Vide.mount

local GUIController = {}

GUIController.__index = GUIController

function GUIController.new(LoadoutSlotTools)
	local self = setmetatable({}, GUIController)
	print("Creating GUIController")
	self.destroy = mount(function()
		return App(LoadoutSlotTools)
	end, Player:WaitForChild("PlayerGui"))
	return self
end

return GUIController
