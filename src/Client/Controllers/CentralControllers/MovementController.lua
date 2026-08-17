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
	self.SprintTrove = self.Trove:Extend()
	self.ActionManager = ActionManager
	self.AnimationController = AnimationController
	self.ViewModelController = AnimationController:GetController("ViewModel")
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
	self.Humanoid.WalkSpeed = MovementSettings.Sprint.DEFAULT_WALK_SPEED
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
	print("X: " .. Velocity.X .. ", Y: " .. Velocity.Y .. ", Z: " .. Velocity.Z)

	self.HumanoidRootPart.AssemblyLinearVelocity =
		Vector3.new(Velocity.X, MovementSettings.Jump.DOUBLE_JUMP_POWER, Velocity.Z)
end

function MovementController:Crouch() end

function MovementController:Slide() end

function MovementController:CanSprint()
	local MoveDirection = self.Humanoid.MoveDirection
	local LookVector = self.HumanoidRootPart.CFrame.LookVector
	local dot

	MoveDirection = Vector3.new(MoveDirection.X, 0, MoveDirection.Z)
	LookVector = Vector3.new(LookVector.X, 0, LookVector.Z)

	if self.IsSprinting then
		dot = 0
	elseif self.IsSprinting == false then
		dot = 0.7
	end
	return self.Humanoid.Health > 0
		and MoveDirection.Magnitude > 0
		and MoveDirection.Unit:Dot(LookVector.Unit) > dot
		and self.ActionManager:TryAction("Movement", "Sprint")
end

function MovementController:StartSprint()
	if not self:CanSprint() then
		return
	end
	self.IsSprinting = true
	self.ActionManager:PerformAction("Movement", "Sprint")
	self.ActionManager:SetState("MovementState", "SPRINTING")
	self.Humanoid.WalkSpeed = MovementSettings.Sprint.SPRINT_WALK_SPEED

	self.SprintTrove:Add(self.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if not self:CanSprint() then
			print("Stopping sprint due to movement direction change")
			self:CancelSprint()
		end
	end))
end

function MovementController:CancelSprint()
	print("Stopping sprint, resetting walk speed to default")
	self.IsSprinting = false
	self.Humanoid.WalkSpeed = MovementSettings.Sprint.DEFAULT_WALK_SPEED
	self.SprintTrove:Clean()

	if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
		self.ActionManager:SetState("MovementState", "IDLE")
	end
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
			self.DoubleJumpReady = true
			if self.IsSprinting then
				self.ActionManager:SetState("MovementState", "SPRINTING")
			else
				self.ActionManager:SetState("MovementState", "IDLE")
			end

			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			task.delay(MovementSettings.Jump.JUMP_DELAY, function()
				-- Ensure this still belongs to the current character.
				if self.Humanoid and self.Humanoid.Parent then
					self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				end
			end)
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

	self:BindAction("Sprint", Enum.KeyCode.LeftShift, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:StartSprint()
		elseif inputState == Enum.UserInputState.End then
			self:CancelSprint()
		end
	end)

	self.Trove:Add(self.ActionManager.CancelStateSignal:Connect(function(stateType, cancelledState)
		if stateType == "MovementState" then
			if cancelledState == "SPRINTING" then
				print("Sprint cancelled, stopping sprint")
				self:CancelSprint()
			end
		end
	end))
end

return MovementController
