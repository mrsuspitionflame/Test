local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = script:FindFirstAncestor("Combat")
local Abilities = Combat:WaitForChild("Components"):WaitForChild("Abilities")
local Grenades = Abilities:WaitForChild("Grenades")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))

local AbilityController = {}

AbilityController.__index = AbilityController

function AbilityController.new(AbilityInfo, animationController, stateManager, guiController)
	local self = setmetatable({
		Trove = Trove.new(),

		AnimationController = animationController,
		StateManager = stateManager,
		GUIController = guiController,

		Animations = nil,
	}, AbilityController)

	self.AbilityInfo = {
		GrenadeInfo = AbilitySettings.Grenade[AbilityInfo.Grenade],
	}

	self:Init(AbilityInfo)
	return self
end

function AbilityController:GetAnimations()
	self.Animations = self.AnimationController:GetAnimation("Ability")
end

function AbilityController:IsFirstPerson()
	local camera = workspace.CurrentCamera
	local Player = game:GetService("Players").LocalPlayer

	if not camera then
		return false
	end

	if Player.CameraMode == Enum.CameraMode.LockFirstPerson then
		return true
	end

	local cameraDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude

	return cameraDistance <= 1
end

function AbilityController:InputSetup()
	local Player = game:GetService("Players").LocalPlayer
	self.Inputs = Player:WaitForChild("Inputs")

	if not self.Inputs then
		warn("Inputs not found for Player")
		return false
	end
	return true
end

function AbilityController:Destroy()
	self.Trove:Destroy()
end

function AbilityController:Init(AbilityInfo)
	self.AnimationController:CreateAbilityViewModel(AbilityInfo)
	self:GetAnimations()

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	if not self:InputSetup() then
		return
	end
end

return AbilityController
