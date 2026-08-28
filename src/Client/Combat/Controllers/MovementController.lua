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

function MovementController.new(StateManager, AnimationController)
	local self = setmetatable({}, MovementController)
	self.Trove = Trove.new()
	self.SprintTrove = self.Trove:Extend()
	self.SlideTrove = self.Trove:Extend()
	self.StateManager = StateManager
	self.AnimationController = AnimationController
	self.ViewModelAnimation = AnimationController:GetController("ViewModel")
	self.Character = nil
	self.Humanoid = nil
	self.HumanoidRootPart = nil

	self.IsSprinting = false
	self.IsSliding = false
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
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local Velocity = self.HumanoidRootPart.AssemblyLinearVelocity

	self.HumanoidRootPart.AssemblyLinearVelocity =
		Vector3.new(Velocity.X, MovementSettings.Jump.DOUBLE_JUMP_POWER, Velocity.Z)
end

function MovementController:Crouch() end

function MovementController:CanSlide()
	if not self.Humanoid or not self.HumanoidRootPart then
		return false
	end

	return self.IsSprinting
		and self.StateManager:GetState("MovementState") == "SPRINTING"
		and self.Humanoid.Health > 0
		and self.Humanoid.FloorMaterial ~= Enum.Material.Air
		and self.Humanoid.MoveDirection.Magnitude > 0.1
		and self.StateManager:TryAction("Movement", "Slide")
end

function MovementController:StartSlide()
	if not self:CanSlide() then
		return
	end

	self.SlideTrove:Clean()

	local Direction = self.Humanoid.MoveDirection.Unit
	local SlideDirection = Vector3.new(Direction.X, 0, Direction.Z).Unit
	local CurrentVelocity = self.HumanoidRootPart.AssemblyLinearVelocity
	local HorizontalSpeed = Vector3.new(CurrentVelocity.X, 0, CurrentVelocity.Z).Magnitude

	local StartSpeed = math.max(HorizontalSpeed, MovementSettings.Slide.SLIDE_START_SPEED)
	print("Starting slide with speed:", StartSpeed)

	-- Change state immediately so StartSlide cannot run twice.
	self.StateManager:PerformAction("Movement", "Slide")
	self.StateManager:SetState("MovementState", "SLIDING")
	self.IsSliding = true

	self.Humanoid.AutoRotate = false
	self.Humanoid.WalkSpeed = 0
	self.Humanoid:Move(Vector3.zero, false)

	local Attachment = Instance.new("Attachment")
	Attachment.Name = "SlideAttachment"
	Attachment.Parent = self.HumanoidRootPart
	self.SlideTrove:Add(Attachment)

	local LinearVelocity = Instance.new("LinearVelocity")
	LinearVelocity.Name = "SlideVelocity"
	LinearVelocity.Attachment0 = Attachment
	LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	LinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane

	LinearVelocity.PrimaryTangentAxis = Vector3.xAxis
	LinearVelocity.SecondaryTangentAxis = Vector3.zAxis

	LinearVelocity.ForceLimitsEnabled = false

	LinearVelocity.PlaneVelocity = Vector2.new(SlideDirection.X * StartSpeed, SlideDirection.Z * StartSpeed)

	LinearVelocity.Parent = self.HumanoidRootPart

	self.SlideTrove:Add(LinearVelocity)

	-- Play your slide animation here.

	local elapsed = 0

	self.SlideTrove:Add(RunService.Heartbeat:Connect(function(dt)
		if not self.IsSliding then
			return
		end

		elapsed += dt

		if
			self.Humanoid.Health <= 0
			or self.Humanoid.FloorMaterial == Enum.Material.Air
			or elapsed >= MovementSettings.Slide.SLIDE_DURATION
		then
			self:StopSlide()
			return
		end

		local alpha = math.clamp(elapsed / MovementSettings.Slide.SLIDE_DURATION, 0, 1)

		local speed = StartSpeed + (MovementSettings.Slide.SLIDE_END_SPEED - StartSpeed) * alpha
		LinearVelocity.PlaneVelocity = Vector2.new(SlideDirection.X * speed, SlideDirection.Z * speed)
	end))
end

function MovementController:StopSlide()
	if not self.IsSliding then
		return
	end

	self.SlideTrove:Clean()
	self.IsSliding = false

	if not self.Humanoid or not self.HumanoidRootPart then
		return
	end

	self.Humanoid.AutoRotate = true
	self.Humanoid.WalkSpeed = MovementSettings.Sprint.DEFAULT_WALK_SPEED

	if self.Humanoid.FloorMaterial == Enum.Material.Air then
		self.StateManager:SetState("MovementState", "FALLING")
	else
		self.StateManager:SetState("MovementState", "IDLE")
	end
end

function MovementController:CanSprint()
	local MoveDirection = self.Humanoid.MoveDirection
	local LookVector = self.HumanoidRootPart.CFrame.LookVector
	local dot

	MoveDirection = Vector3.new(MoveDirection.X, 0, MoveDirection.Z)
	LookVector = Vector3.new(LookVector.X, 0, LookVector.Z)

	if self.IsSprinting then
		dot = 0.3
	elseif self.IsSprinting == false then
		dot = 0.7
	end
	return self.Humanoid.Health > 0
		and MoveDirection.Magnitude > 0
		and MoveDirection.Unit:Dot(LookVector.Unit) > dot
		and self.StateManager:TryAction("Movement", "Sprint")
end

function MovementController:StartSprint()
	if not self:CanSprint() then
		return
	end
	self.IsSprinting = true
	self.StateManager:PerformAction("Movement", "Sprint")
	self.StateManager:SetState("MovementState", "SPRINTING")
	self.Humanoid.WalkSpeed = MovementSettings.Sprint.SPRINT_WALK_SPEED

	self.SprintTrove:Add(self.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if
			self.StateManager:GetState("MovementState") == "JUMPING"
			or self.StateManager:GetState("MovementState") == "FALLING"
		then
			return
		end
		if not self:CanSprint() then
			print("Stopping sprint due to movement direction change")
			self:StopSprint()
		end
	end))
end

function MovementController:StopSprint()
	print("Stopping sprint")
	self.IsSprinting = false
	self.Humanoid.WalkSpeed = MovementSettings.Sprint.DEFAULT_WALK_SPEED
	self.SprintTrove:Clean()

	if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
		self.StateManager:SetState("MovementState", "IDLE")
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
				print("Landed while sprinting, setting movement state to SPRINTING")
				self.StateManager:SetState("MovementState", "SPRINTING")
			else
				self.StateManager:SetState("MovementState", "IDLE")
			end

			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			task.delay(MovementSettings.Jump.JUMP_DELAY, function()
				-- Ensure this still belongs to the current character.
				if self.Humanoid and self.Humanoid.Parent then
					self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				end
			end)
		elseif newState == Enum.HumanoidStateType.Jumping then
			self.StateManager:SetState("MovementState", "JUMPING")
		elseif newState == Enum.HumanoidStateType.Freefall then
			self.StateManager:SetState("MovementState", "FALLING")
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
			if self.IsSprinting and self.StateManager:GetState("MovementState") == "SPRINTING" then
				self:StopSprint()
			else
				self:StartSprint()
			end
		end
		return Enum.ContextActionResult.Sink
	end)

	self:BindAction("Slide", Enum.KeyCode.LeftControl, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:StartSlide()
		end
		return Enum.ContextActionResult.Sink
	end)

	self.Trove:Add(self.StateManager.CancelStateSignal:Connect(function(stateType, cancelledState)
		if stateType == "MovementState" then
			if cancelledState == "SPRINTING" then
				print("Sprint cancelled, stopping sprint")
				self:StopSprint()
			elseif cancelledState == "SLIDING" then
				print("Slide cancelled, stopping slide")
				self:StopSlide()
			end
		end
	end))
end

return MovementController
