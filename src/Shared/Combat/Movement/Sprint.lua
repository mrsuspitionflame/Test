local Sprint = {}

Sprint.__index = Sprint

function Sprint.new(MovementClass)
	local self = setmetatable({}, Sprint)
	self.MovementClass = MovementClass
	self.Humanoid = MovementClass.Humanoid
	self.Root = MovementClass.Root
	self.Settings = MovementClass.MovementSettings.SPRINT
	return self
end

function Sprint:CanSprint()
	local Humanoid = self.Humanoid
	local Root = self.Root

	local SprintHeld = self.MovementClass.SprintAction:GetState() == true
	local Grounded = Humanoid.FloorMaterial ~= Enum.Material.Air
	local WasSprinting = Root:GetAttribute("SprintActive") == true
	local MoveDirection = Humanoid.MoveDirection
	local LookVector = Root.CFrame.LookVector

	return SprintHeld
		and MoveDirection.Magnitude > 0.01
		and Humanoid.Health > 0
		and not Humanoid.Sit
		and (Grounded or WasSprinting)
		and MoveDirection:Dot(LookVector) > 0.3
		and (Root:GetAttribute("SlideTimeRemaining") or 0) <= 0
		and self.MovementClass.StateManager:TryAction("Movement", "Sprint")
end

function Sprint:StopSprint()
	if self.Root then
		self.Root:SetAttribute("SprintActive", false)
		self.Root:SetAttribute("SprintSpeed", 0)
	end
end

function Sprint:Step(dt)
	local Humanoid = self.Humanoidz
	local Root = self.Root
	local Settings = self.Settings

	local CanSprint = self:CanSprint()
	local TargetSpeed = CanSprint and Settings.SPRINT_WALK_SPEED or Settings.DEFAULT_WALK_SPEED

	-- Read tracked state each tick. Don't keep speed in a closure.
	local Speed = Root:GetAttribute("SprintSpeed")
	if Speed == nil then
		Speed = Settings.DEFAULT_WALK_SPEED
	end

	if Speed < TargetSpeed then
		Speed = math.min(TargetSpeed, Speed + Settings.ACCELERATION_RATE * dt)
	elseif Speed > TargetSpeed then
		Speed = math.max(TargetSpeed, Speed - Settings.DECELERATION_RATE * dt)
	end

	Root:SetAttribute("SprintActive", CanSprint)
	Root:SetAttribute("SprintSpeed", Speed)

	Humanoid.WalkSpeed = Speed
end

function Sprint:Destroy()
	if self.Root then
		self.Root:SetAttribute("SprintSpeed", nil)
		self.Root:SetAttribute("SprintActive", nil)
	end

	self.MovementClass = nil
	self.Humanoid = nil
	self.Root = nil
	self.Settings = nil
end

return Sprint
