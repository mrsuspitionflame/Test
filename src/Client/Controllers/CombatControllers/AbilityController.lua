local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local AbilityController = {}

AbilityController.__index = AbilityController

function AbilityController.new()
	local self = setmetatable({}, AbilityController)
	self.Trove = Trove.new()
	return self
end

function AbilityController:BindAction(actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	self.Trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function AbilityController:Init()
	self:BindAction("GrenadeAbility", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			--thing
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Q)

	self:BindAction("MeleeAbility", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			--thing
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.C)

	self:BindAction("ClassAbility", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			--thing
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.V)
end

return AbilityController
