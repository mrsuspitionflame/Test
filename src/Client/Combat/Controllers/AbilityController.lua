local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = script:FindFirstAncestor("Client")
local Combat = Client:WaitForChild("Combat")
local Abilities = Combat:WaitForChild("Abilities")
local Grenades = Abilities:WaitForChild("Grenades")
local HTTPService = game:GetService("HttpService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local AbilityController = {}

AbilityController.__index = AbilityController

function AbilityController.new(AbilityInfo, animationController, stateManager, guiController)
	local self = setmetatable({}, AbilityController)
	self.Trove = Trove.new()

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade))

	self.AnimationController = animationController
	self.StateManager = stateManager
	self.GUIController = guiController
	self:Init()
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
			local data = {
				ProjectileID = HTTPService:GenerateGUID(false),
				Direction = workspace.CurrentCamera.CFrame.LookVector,
				Origin = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * -3,
				Player = game.Players.LocalPlayer,
			}
			self.Grenade:Held(data, false)
		elseif inputState == Enum.UserInputState.End then
			local data = {
				ProjectileID = HTTPService:GenerateGUID(false),
				Direction = workspace.CurrentCamera.CFrame.LookVector,
				Origin = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * -3,
				Player = game.Players.LocalPlayer,
			}
			self.Grenade:Released(data, false)
		elseif inputState == Enum.UserInputState.Cancel then
			self.Grenade:Cancelled()
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
