local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Slide = {}

Slide.__index = Slide

function Slide.new(MovementController)
	local self = setmetatable({}, Slide)

	self.MovementController = MovementController
	self.MovementInfo = MovementController.MovementInfo
	self.StateManager = MovementController.StateManager
	self.Humanoid = nil
	self.HumanoidRootPart = nil

	self.SlideTrove = Trove.new()
	self.IsSliding = false

	self.SlideCharacterAnimation = nil
	self.SlideViewModelAnimation = nil

	return self
end

function Slide:CanSlide()
	if not self.Humanoid or not self.HumanoidRootPart then
		return false
	end

	local Velocity = self.HumanoidRootPart.AssemblyLinearVelocity
	local HorizontalSpeed = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude

	return self.Humanoid.Health > 0
		and self.Humanoid.FloorMaterial ~= Enum.Material.Air
		and HorizontalSpeed >= self.MovementInfo.SLIDE.MIN_START_SPEED
		and self.StateManager:TryAction("Movement", "Slide")
end

function Slide:StartSlide()
	if not self:CanSlide() then
		return
	end

	self.SlideTrove:Clean()

	local CurrentVelocity = self.HumanoidRootPart.AssemblyLinearVelocity
	local HorizontalVelocity = Vector3.new(CurrentVelocity.X, 0, CurrentVelocity.Z)
	local HorizontalSpeed = HorizontalVelocity.Magnitude
	local SlideDirection = HorizontalVelocity.Unit

	local StartSpeed = math.max(HorizontalSpeed, self.MovementInfo.SLIDE.SLIDE_START_SPEED)
	print("Starting slide with speed:", StartSpeed)

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

	if self.SlideViewModelAnimation then
		self.SlideViewModelAnimation:Play(0.15)
	end
	if self.SlideCharacterAnimation then
		self.SlideCharacterAnimation:Play(0.15)
	end

	local elapsed = 0

	self.SlideTrove:Add(RunService.Heartbeat:Connect(function(dt)
		if not self.IsSliding then
			return
		end

		elapsed += dt

		if
			self.Humanoid.Health <= 0
			or self.Humanoid.FloorMaterial == Enum.Material.Air
			or elapsed >= self.MovementInfo.SLIDE.SLIDE_DURATION
		then
			self:StopSlide()
			return
		end

		local alpha = math.clamp(elapsed / self.MovementInfo.SLIDE.SLIDE_DURATION, 0, 1)

		local speed = StartSpeed + (self.MovementInfo.SLIDE.SLIDE_END_SPEED - StartSpeed) * alpha
		LinearVelocity.PlaneVelocity = Vector2.new(SlideDirection.X * speed, SlideDirection.Z * speed)
	end))
end

function Slide:StopSlide()
	if not self.IsSliding then
		return
	end

	self.SlideTrove:Clean()
	self.IsSliding = false

	if not self.Humanoid or not self.HumanoidRootPart then
		return
	end

	self.Humanoid.AutoRotate = true
	self.Humanoid.WalkSpeed = self.MovementInfo.SPRINT.DEFAULT_WALK_SPEED

	self.SlideCharacterAnimation:Stop(0.15)

	if self.Humanoid.FloorMaterial == Enum.Material.Air then
		self.StateManager:SetState("MovementState", "FALLING")
	else
		self.StateManager:SetState("MovementState", "IDLE")
	end
end

function Slide:OnCharacterAdded()
	self.SlideTrove:Clean()
	self.Humanoid = self.MovementController.Humanoid
	self.HumanoidRootPart = self.MovementController.HumanoidRootPart
	self.IsSliding = false

	self.SlideCharacterAnimation = self.MovementController.CharacterAnimations.SLIDE
end

function Slide:OnCharacterRemoved()
	self.SlideTrove:Clean()
	self.IsSliding = false
	self.Humanoid = nil
	self.HumanoidRootPart = nil
end

function Slide:OnWeaponEquip()
	self.SlideViewModelAnimation = self.MovementController.ViewModelAnimations.SLIDE.VIEWMODEL
end

function Slide:OnWeaponUnequip()
	self.SlideViewModelAnimation = nil
end

return Slide
