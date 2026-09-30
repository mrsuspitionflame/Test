local Jump = {}

Jump.__index = Jump

function Jump.new(MovementClass)
	local self = setmetatable({}, Jump)
	self.MovementClass = MovementClass
	local Humanoid = self.MovementClass.CombatClasses.Humanoid
	self.Settings = MovementClass.MovementSettings.JUMP

	Humanoid.UseJumpPower = true
	Humanoid.JumpPower = self.Settings.JUMP_POWER
	return self
end

function Jump:ApplyJump(jumpPower)
	local Humanoid = self.MovementClass.CombatClasses.Humanoid
	local Root = self.MovementClass.CombatClasses.Root
	if self.MovementClass.Slide then
		self.MovementClass.Slide:StopSlide()
	end

	local velocity = Root.AssemblyLinearVelocity
	Root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpPower, velocity.Z)
	Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

function Jump:DoubleJump()
	self:ApplyJump(self.Settings.DOUBLE_JUMP_POWER)
end

function Jump:CanDoubleJump()
	local Humanoid = self.MovementClass.CombatClasses.Humanoid
	local Root = self.MovementClass.CombatClasses.Root
	local JumpHeld = self.MovementClass.JumpAction:GetState() == true
	local WasJumpHeld = Root:GetAttribute("DoubleJumpHeld") == true

	local JumpPressed = JumpHeld and not WasJumpHeld

	local Grounded = Humanoid.FloorMaterial ~= Enum.Material.Air
	return Humanoid
		and Humanoid.Health > 0
		and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
		and JumpPressed
		and not Grounded
		and Root:GetAttribute("DoubleJumpAvailable") == true
		and self.MovementClass.StateManager:TryAction("Movement", "DoubleJump")
end

function Jump:CancelStates() end -- Haven't finished movement cancellation yet, try not to get messed up

function Jump:Step(dt)
	local Humanoid = self.MovementClass.CombatClasses.Humanoid
	local Root = self.MovementClass.CombatClasses.Root

	local JumpHeld = self.MovementClass.JumpAction:GetState() == true
	local WasJumpHeld = Root:GetAttribute("DoubleJumpHeld") == true
	local JumpPressed = JumpHeld and not WasJumpHeld

	local Grounded = Humanoid.FloorMaterial ~= Enum.Material.Air
	local HumanoidState = Humanoid:GetState()

	if HumanoidState == Enum.HumanoidStateType.Jumping and self.MovementClass.Slide then
		self.MovementClass.Slide:StopSlide()
	end

	if Grounded then
		Root:SetAttribute("DoubleJumpAvailable", true)

		if JumpPressed then
			-- Record the grounded press even if the Humanoid changes state
			-- between two simulation callbacks.
			Root:SetAttribute("NormalJumpUsed", true)
			Root:SetAttribute("CoyoteTimeRemaining", 0)
		elseif not JumpHeld then
			Root:SetAttribute("NormalJumpUsed", false)
			Root:SetAttribute("CoyoteTimeRemaining", self.Settings.COYOTE_TIME)
		end
	elseif HumanoidState == Enum.HumanoidStateType.Jumping then
		-- Roblox created the normal grounded jump.
		Root:SetAttribute("NormalJumpUsed", true)
		Root:SetAttribute("CoyoteTimeRemaining", 0)
	else
		local coyoteTime = Root:GetAttribute("CoyoteTimeRemaining") or 0
		Root:SetAttribute("CoyoteTimeRemaining", math.max(0, coyoteTime - dt))
	end

	if JumpPressed and not Grounded and HumanoidState ~= Enum.HumanoidStateType.Jumping then
		local coyoteTime = Root:GetAttribute("CoyoteTimeRemaining") or 0
		local normalJumpUsed = Root:GetAttribute("NormalJumpUsed") == true

		if coyoteTime > 0 and not normalJumpUsed and self.MovementClass.StateManager:TryAction("Movement", "Jump") then
			-- A press just after leaving a ledge still counts as the first jump.
			Root:SetAttribute("NormalJumpUsed", true)
			Root:SetAttribute("CoyoteTimeRemaining", 0)
			self:ApplyJump(self.Settings.JUMP_POWER)
		elseif self:CanDoubleJump() then
			Root:SetAttribute("DoubleJumpAvailable", false)
			self:DoubleJump()
		end
	end

	-- This tracked value makes a press edge replay correctly during resimulation.
	Root:SetAttribute("DoubleJumpHeld", JumpHeld)
end

function Jump:Destroy()
	local Root = self.MovementClass.CombatClasses.Root
	if Root then
		Root:SetAttribute("DoubleJumpAvailable", nil)
		Root:SetAttribute("DoubleJumpHeld", nil)
		Root:SetAttribute("NormalJumpUsed", nil)
		Root:SetAttribute("CoyoteTimeRemaining", nil)
	end

	self.MovementClass = nil
	self.Settings = nil
end

return Jump
