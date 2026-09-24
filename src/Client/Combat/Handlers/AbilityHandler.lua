local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = script:FindFirstAncestor("Client")
local Combat = Client:WaitForChild("Combat")
local Abilities = Combat:WaitForChild("Abilities")
local Grenades = Abilities:WaitForChild("Grenades")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Player = game.Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))

local AbilityHandler = {}

AbilityHandler.__index = AbilityHandler

function AbilityHandler.new(AbilityInfo, animationController, stateManager, guiController)
	local self = setmetatable({
		Trove = Trove.new(),

		AnimationController = animationController,
		StateManager = stateManager,
		GUIController = guiController,

		Animations = nil,
	}, AbilityHandler)

	self.AbilityInfo = {
		GrenadeInfo = table.clone(AbilitySettings.Grenade[AbilityInfo.Grenade]),
	}

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	self:Init(AbilityInfo)
	return self
end

function AbilityHandler:Init(AbilityInfo)
	self.AnimationController:CreateAbilityViewModel(AbilityInfo)
	self:GetAnimations()
	self:BindActions()
end

function AbilityHandler:GetAnimations()
	self.Animations = self.AnimationController:GetAnimation("Ability")
end

function AbilityHandler:IsFirstPerson()
	local camera = workspace.CurrentCamera

	if not camera then
		return false
	end

	if Player.CameraMode == Enum.CameraMode.LockFirstPerson then
		return true
	end

	local cameraDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude

	return cameraDistance <= 1
end

function AbilityHandler:Destroy()
	self.Trove:Destroy()
end

function AbilityHandler:BindAction(actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	self.Trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function AbilityHandler:BindActions()
	self:BindAction("GrenadeAbility", function(_, inputState)
		if not self:IsFirstPerson() then
			return
		end
		if inputState == Enum.UserInputState.Begin then
			self.Grenade:Held()
		elseif inputState == Enum.UserInputState.End then
			self.Grenade:Released()
		elseif inputState == Enum.UserInputState.Cancel then
			self.Grenade:Cancelled()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Q)

	self:BindAction("MeleeAbility", function(_, inputState)
		if not self:IsFirstPerson() then
			return
		end
		if inputState == Enum.UserInputState.Begin then
			--thing
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.C)

	self:BindAction("ClassAbility", function(_, inputState)
		if not self:IsFirstPerson() then
			return
		end
		if inputState == Enum.UserInputState.Begin then
			--thing
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.V)
end

return AbilityHandler
