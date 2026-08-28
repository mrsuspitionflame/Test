local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Sprint = {}

Sprint.__index = Sprint

function Sprint.new(MovementController)
	local self = setmetatable({}, Sprint)

	self.MovementController = MovementController
	self.MovementInfo = MovementController.MovementInfo
	self.StateManager = MovementController.StateManager
	self.Humanoid = nil
	self.HumanoidRootPart = nil
	self.Animate = nil

	self.SprintTrove = Trove.new()
	self.DecelerationTrove = Trove.new()
	self.AccelerationTrove = Trove.new()
	self.IsSprinting = false

	self.SprintCharacterAnimation = nil
	self.SprintViewModelAnimation = nil

	return self
end

function Sprint:CanSprint()
	if not self.Humanoid or not self.HumanoidRootPart then
		return false
	end

	local MoveDirection = self.Humanoid.MoveDirection
	local LookVector = self.HumanoidRootPart.CFrame.LookVector
	local dot

	MoveDirection = Vector3.new(MoveDirection.X, 0, MoveDirection.Z)
	LookVector = Vector3.new(LookVector.X, 0, LookVector.Z)

	if self.IsSprinting then
		dot = 0.3
	else
		dot = 0.5
	end
	return self.Humanoid.Health > 0
		and MoveDirection.Magnitude > 0
		and MoveDirection.Unit:Dot(LookVector.Unit) > dot
		and self.StateManager:TryAction("Movement", "Sprint")
end

function Sprint:StartSprint()
	if not self:CanSprint() then
		return
	end

	self.SprintTrove:Clean()
	self.DecelerationTrove:Clean()
	self.AccelerationTrove:Clean()

	self.IsSprinting = true
	self.StateManager:PerformAction("Movement", "Sprint")
	self.StateManager:SetState("MovementState", "SPRINTING")

	local SprintWalkSpeed = self.MovementInfo.SPRINT.SPRINT_WALK_SPEED

	local Humanoid = self.Humanoid
	local Speed = self.Humanoid.WalkSpeed
	local Connection

	Connection = RunService.Heartbeat:Connect(function(dt)
		if self.Humanoid ~= Humanoid or not Humanoid.Parent then
			Connection:Disconnect()
			return
		end

		Speed = math.min(SprintWalkSpeed, Speed + self.MovementInfo.SPRINT.ACCELERATION_RATE * dt)

		Humanoid.WalkSpeed = Speed
		if Speed >= SprintWalkSpeed then
			Connection:Disconnect()
		end
	end)

	self.AccelerationTrove:Add(Connection)

	if self.SprintCharacterAnimation then
		self.SprintCharacterAnimation:Play(0.15)
	end

	if self.SprintViewModelAnimation then
		self.SprintViewModelAnimation:Play(0.15)
	end

	self.SprintTrove:Add(self.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if
			self.StateManager:GetState("MovementState") == "JUMPING"
			or self.StateManager:GetState("MovementState") == "FALLING"
		then
			return
		end
		if not self:CanSprint() then
			print("Stopping sprint due to movement direction change")
			self:StopSprint(true)
		end
	end))
end

function Sprint:StopSprint()
	self.IsSprinting = false
	self.SprintTrove:Clean()
	self.DecelerationTrove:Clean()
	self.AccelerationTrove:Clean()

	local Humanoid = self.Humanoid
	if not Humanoid then
		return
	end

	local DefaultWalkSpeed = self.MovementInfo.SPRINT.DEFAULT_WALK_SPEED

	if self.StateManager:GetState("MovementState") == "SPRINTING" then
		self.StateManager:SetState("MovementState", "IDLE")
	end

	local Speed = Humanoid.WalkSpeed
	local Connection

	Connection = RunService.Heartbeat:Connect(function(dt)
		if self.Humanoid ~= Humanoid or not Humanoid.Parent then
			Connection:Disconnect()
			return
		end

		Speed = math.max(DefaultWalkSpeed, Speed - self.MovementInfo.SPRINT.DECELERATION_RATE * dt)
		Humanoid.WalkSpeed = Speed

		if Speed <= DefaultWalkSpeed then
			Connection:Disconnect()
		end
	end)

	self.DecelerationTrove:Add(Connection)

	if self.SprintCharacterAnimation then
		self.SprintCharacterAnimation:Stop(0.15)
	end
	if self.SprintViewModelAnimation then
		self.SprintViewModelAnimation:Stop(0.15)
	end
end

function Sprint:OnCharacterAdded()
	self.SprintTrove:Clean()
	self.DecelerationTrove:Clean()
	self.AccelerationTrove:Clean()
	self.Humanoid = self.MovementController.Humanoid
	self.HumanoidRootPart = self.MovementController.HumanoidRootPart
	self.Animate = self.MovementController.Animate
	self.IsSprinting = false

	self.Humanoid.WalkSpeed = self.MovementInfo.SPRINT.DEFAULT_WALK_SPEED
	self.SprintCharacterAnimation = self.MovementController.CharacterAnimations.SPRINT
end

function Sprint:OnCharacterRemoved()
	self.Animate.walk.WalkAnim.AnimationId = self.MovementInfo.ANIMATION_IDS.WALK
	self.SprintTrove:Clean()
	self.DecelerationTrove:Clean()
	self.AccelerationTrove:Clean()
	self.IsSprinting = false
	self.Humanoid = nil
	self.HumanoidRootPart = nil
	self.Animate = nil
end

function Sprint:OnWeaponEquip()
	self.SprintViewModelAnimation = self.MovementController.ViewModelAnimations.SPRINT.VIEWMODEL
end

function Sprint:OnWeaponUnequip()
	self.SprintViewModelAnimation = nil
end

function Sprint:PlayAnimation()
	if self.SprintViewModelAnimation then
		self.SprintViewModelAnimation:Play(0.15)
	end
	if self.SprintCharacterAnimation then
		self.SprintCharacterAnimation:Play(0.15)
	end
end

function Sprint:StopAnimation()
	if self.SprintViewModelAnimation then
		self.SprintViewModelAnimation:Stop(0.15)
	end
	if self.SprintCharacterAnimation then
		self.SprintCharacterAnimation:Stop(0.15)
	end
end

return Sprint
