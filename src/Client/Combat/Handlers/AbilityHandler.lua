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

local AbilityHandler = {}

AbilityHandler.__index = AbilityHandler

function AbilityHandler.new(AbilityInfo, viewModelController, stateManager, guiController, combatHandler)
	local self = setmetatable({
		Trove = Trove.new(),

		ViewModelController = viewModelController,
		StateManager = stateManager,
		GUIController = guiController,
		CombatHandler = combatHandler,

		Animations = nil,
	}, AbilityHandler)

	self.AbilityInfo = {
		GrenadeInfo = AbilitySettings.Grenade[AbilityInfo.Grenade],
	}

	self:Init(AbilityInfo)
	return self
end

function AbilityHandler:GetAnimations()
	self.Animations = self.ViewModelController.AbilityAnimations
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

function AbilityHandler:InputSetup()
	self.Inputs = Player:WaitForChild("Inputs")
	if not self.Inputs then
		return false
	end
	local AbilityContext = self.Inputs:WaitForChild("AbilityContext")
	self.GrenadeAction = AbilityContext:WaitForChild("GrenadeAction")

	self:BindAbilityInputs()
	return true
end

function AbilityHandler:BindAbilityInputs()
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

function AbilityHandler:UnbindAbilityInputs()
	if self.InputTrove then
		self.Trove:Remove(self.InputTrove)
		self.InputTrove = nil
	end
end

function AbilityHandler:Init(AbilityInfo)
	self.ViewModelController:CreateAbilityViewModel(AbilityInfo)
	self:GetAnimations()

	self.Grenade = require(Grenades:WaitForChild(AbilityInfo.Grenade)).new(self)

	if not self:InputSetup() then
		warn("Inputs not found for Player")
		return
	end
end

return AbilityHandler
