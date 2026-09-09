local Slide = {}

Slide.__index = Slide

function Slide.new(MovementClass)
	local self = setmetatable({}, Slide)
	self.MovementClass = MovementClass
	self.Humanoid = MovementClass.Humanoid
	self.Root = MovementClass.Root
	self.Settings = MovementClass.MovementSettings.SLIDE
	return self
end

function Slide:StopSlide()
	if not self.Root then
		return
	end

	self.Root:SetAttribute("SlideTimeRemaining", 0)
end

function Slide:CanSlide()
	local Humanoid = self.Humanoid
	local Root = self.Root
	local Settings = self.Settings

	local Velocity = Root.AssemblyLinearVelocity
	local HorizontalSpeed = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude

	return (Root:GetAttribute("SlideTimeRemaining") or 0) <= 0
		and Humanoid.FloorMaterial ~= Enum.Material.Air
		and Humanoid.Health > 0
		and HorizontalSpeed >= Settings.MIN_START_SPEED
		and self.MovementClass.StateManager:TryAction("Movement", "Slide")
end

function Slide:Step(dt)
	local Humanoid = self.Humanoid
	local Root = self.Root
	local Settings = self.Settings

	local SlideHeld = self.MovementClass.SlideAction:GetState() == true
	local WasSlideHeld = Root:GetAttribute("SlideHeld") == true
	local SlidePressed = SlideHeld and not WasSlideHeld

	local IsSliding = (Root:GetAttribute("SlideTimeRemaining") or 0) > 0
	local Grounded = Humanoid.FloorMaterial ~= Enum.Material.Air

	local Velocity = Root.AssemblyLinearVelocity
	local HorizontalVelocity = Vector3.new(Velocity.X, 0, Velocity.Z)
	local HorizontalSpeed = HorizontalVelocity.Magnitude

	if SlidePressed and self:CanSlide() then
		local StartSpeed = math.max(HorizontalSpeed, Settings.SLIDE_START_SPEED)

		Root:SetAttribute("SlideDirection", HorizontalVelocity.Unit)
		Root:SetAttribute("SlideStartSpeed", StartSpeed)
		Root:SetAttribute("SlideTimeRemaining", Settings.SLIDE_DURATION)
		IsSliding = true
	end

	if IsSliding then
		local Remaining = Root:GetAttribute("SlideTimeRemaining") or 0

		if Humanoid.Health <= 0 or not Grounded or Remaining <= 0 then
			self:StopSlide()
		else
			Remaining = math.max(0, Remaining - dt)

			local Direction = Root:GetAttribute("SlideDirection")
			local StartSpeed = Root:GetAttribute("SlideStartSpeed") or Settings.SLIDE_START_SPEED
			local Progress = 1 - Remaining / Settings.SLIDE_DURATION
			local Speed = StartSpeed + (Settings.SLIDE_END_SPEED - StartSpeed) * Progress

			Root:SetAttribute("SlideTimeRemaining", Remaining)
			Humanoid.WalkSpeed = 0
			Root.AssemblyLinearVelocity = Vector3.new(Direction.X * Speed, Velocity.Y, Direction.Z * Speed)

			if Remaining <= 0 then
				self:StopSlide()
			end
		end
	end

	Root:SetAttribute("SlideHeld", SlideHeld)
end

function Slide:Destroy()
	self:StopSlide()
	if self.Root then
		self.Root:SetAttribute("SlideHeld", nil)
		self.Root:SetAttribute("SlideDirection", nil)
		self.Root:SetAttribute("SlideStartSpeed", nil)
	end

	self.MovementClass = nil
	self.Humanoid = nil
	self.Root = nil
	self.Settings = nil
end

return Slide
