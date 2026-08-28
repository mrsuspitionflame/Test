local Jump = {}

Jump.__index = Jump

function Jump.new(MovementController)
	local self = setmetatable({}, Jump)

	self.MovementController = MovementController
	self.MovementInfo = MovementController.MovementInfo
	self.Humanoid = nil
	self.HumanoidRootPart = nil

	self.DoubleJumpReady = true
	self.JumpInputReleased = false

	self.JumpViewModelAnimation = nil

	self.Sprint = MovementController.Sprint
	return self
end

function Jump:PlayAnimation()
	if self.Sprint.IsSprinting then
		self.Sprint:StopAnimation()
	end
	if self.JumpViewModelAnimation then
		self.JumpViewModelAnimation:Play(0.15)
	end
end
function Jump:StopAnimation()
	if self.JumpViewModelAnimation then
		self.JumpViewModelAnimation:Stop(0.15)
	end
end
function Jump:CanDoubleJump()
	return self.Humanoid
		and self.Humanoid.Health > 0
		and self.DoubleJumpReady
		and self.JumpInputReleased
		and self.Humanoid.FloorMaterial == Enum.Material.Air
		and self.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
end

function Jump:DoubleJump()
	print("Double jump initiated")
	self.DoubleJumpReady = false
	self.JumpInputReleased = false
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local Velocity = self.HumanoidRootPart.AssemblyLinearVelocity

	self.HumanoidRootPart.AssemblyLinearVelocity =
		Vector3.new(Velocity.X, self.MovementInfo.JUMP.DOUBLE_JUMP_POWER, Velocity.Z)
end

function Jump:OnCharacterAdded()
	self.Humanoid = self.MovementController.Humanoid
	self.HumanoidRootPart = self.MovementController.HumanoidRootPart
	self.DoubleJumpReady = true
	self.JumpInputReleased = false

	self.Humanoid.UseJumpPower = true
	self.Humanoid.JumpPower = self.MovementInfo.JUMP.JUMP_POWER
end

function Jump:OnCharacterRemoved()
	self.Humanoid = nil
	self.HumanoidRootPart = nil
	self.DoubleJumpReady = true
	self.JumpInputReleased = false

	self.JumpViewModelAnimation = nil
end

function Jump:OnWeaponEquip()
	self.JumpViewModelAnimation = self.MovementController.ViewModelAnimations.JUMP.VIEWMODEL
end

function Jump:OnWeaponUnequip()
	self.JumpViewModelAnimation = nil
end

return Jump
