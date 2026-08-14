local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local MovementSettings = require(Settings:WaitForChild("MovementSettings"))
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")

local MovementController = {}

MovementController.__index = MovementController

function MovementController.new(ActionManager, AnimationController)
	local self = setmetatable({}, MovementController)
	self.Trove = Trove.new()
	self.ActionManager = ActionManager
	self.AnimationController = AnimationController
	self.Character = nil
	self.Humanoid = nil
	self.HumanoidRootPart = nil

	self.IsSprinting = false
	return self
end

function MovementController:OnCharacterAdded(character)
	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid")
	self.HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

	self.DoubleJumpReady = true

	self.Humanoid.UseJumpPower = true
	self.Humanoid.JumpPower = MovementSettings.Jump.JUMP_POWER
	self:Init()
end

function MovementController:OnCharacterRemoved()
	self.Trove:Clean()
end

function MovementController:CanDoubleJump()
	return self.Humanoid 
	and self.Humanoid.Health > 0 
	and self.DoubleJumpReady 
	and self.Humanoid.FloorMaterial == Enum.Material.Air
	and self.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
end

function MovementController:DoubleJump()
	self.DoubleJumpReady = false
	local Velocity = self.HumanoidRootPart.AssemblyLinearVelocity

	self.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(Velocity.X, MovementSettings.Jump.DOUBLE_JUMP_POWER, Velocity.Z)
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

function MovementController:Crouch()
end

function MovementController:Slide()
end

function MovementController:CanSprint()
end

function MovementController:Sprint()
end

function MovementController:BindAction(actionName, inputType, callback)
	CAS:BindAction(actionName, callback, false, inputType)

	self.Trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function MovementController:Init() 
	self.Trove:Add(self.Humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			self.ActionManager:SetState("MovementState", "IDLE")
			self.DoubleJumpReady = true
		elseif newState == Enum.HumanoidStateType.Jumping then
			self.ActionManager:SetState("MovementState", "JUMPING")
		elseif newState == Enum.HumanoidStateType.Freefall then
			self.ActionManager:SetState("MovementState", "FALLING")
		end
	end))

	self.Trove:Add(UIS.JumpRequest:Connect(function()
		if not self:CanDoubleJump() then
			return
		end
		self:DoubleJump()
	end))
	
end

return MovementController
