local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = script:FindFirstAncestor("Combat")
local Abilities = Combat:WaitForChild("Components"):WaitForChild("Abilities")
local Grenades = Abilities:WaitForChild("Grenades")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Player = game.Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))

local AbilityController = {}

AbilityController.__index = AbilityController

function AbilityController.new(AbilityInfo, animationController, stateManager, guiController, combatController)
	local self = setmetatable({
		Trove = Trove.new(),

		AnimationController = animationController,
		StateManager = stateManager,
		GUIController = guiController,
		CombatController = combatController,

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

	if not camera then
		return false
	end

	if Player.CameraMode == Enum.CameraMode.LockFirstPerson then
		return true
	end

	local cameraDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude

	return cameraDistance <= 1
end

function AbilityController:Destroy()
	self.Trove:Destroy()
end

function AbilityController:InputSetup()
	self.Inputs = Player:WaitForChild("Inputs")
	if not self.Inputs then
		return false
	end
	local AbilityContext = self.Inputs:WaitForChild("AbilityContext")
	self.GrenadeAction = AbilityContext:WaitForChild("GrenadeAction")

	self:BindAbilityInputs()
	return true
end

function AbilityController:BindAbilityInputs()
	if self.InputTrove then
		return
	end
	local InputTrove = self.Trove:Extend()
	self.InputTrove = InputTrove

	if type(self.Grenade.Pressed) == "function" then
		InputTrove:Connect(self.GrenadeAction.Pressed, function(...)
			self.Grenade:Pressed(...)
		end)
	end

	if type(self.Grenade.Released) == "function" then
		InputTrove:Connect(self.GrenadeAction.Released, function(...)
			self.Grenade:Released(...)
		end)
	end
end

function AbilityController:UnbindAbilityInputs()
	if self.InputTrove then
		self.Trove:Remove(self.InputTrove)
		self.InputTrove = nil
	end
end

function AbilityController:Init(AbilityInfo)
	self.AnimationController:CreateAbilityViewModel(AbilityInfo)
	self:GetAnimations()

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	if not self:InputSetup() then
		warn("Inputs not found for Player")
		return
	end
end

return AbilityController
