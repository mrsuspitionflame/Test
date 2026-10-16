local Movement = script.Parent:WaitForChild("Components")
local Jump = require(Movement:WaitForChild("Jump"))
local Sprint = require(Movement:WaitForChild("Sprint"))
local Slide = require(Movement:WaitForChild("Slide"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local MovementSettings = require(Settings:WaitForChild("MovementSettings"))

local MovementStates = table.freeze({
	Idle = "IDLE",
	Walking = "WALKING",
	Sprinting = "SPRINTING",
	Sliding = "SLIDING",
	Jumping = "JUMPING",
	Falling = "FALLING",
})

local StateToAnimation = table.freeze({
	WALKING = "WALK",
	SPRINTING = "SPRINT",
	JUMPING = "JUMP",
	FALLING = "FALL",
	SLIDING = "SLIDE",
})

local MovementClass = {}

MovementClass.__index = MovementClass

function MovementClass.new(Player, StateManager, CombatClasses)
	local self = setmetatable({}, MovementClass)
	self.Trove = Trove.new()
	self.AnimationTrove = self.Trove:Extend()

	self.CombatClasses = CombatClasses
	self.Player = Player
	self.StateManager = StateManager
	self.MovementSettings = table.clone(MovementSettings)

	self.Animations = {}

	self:InputSetup()
	return self
end

function MovementClass:InputSetup()
	self.Inputs = self.Player:WaitForChild("Inputs")
	local MovementContext = self.Inputs:WaitForChild("MovementContext")
	self.SprintAction = MovementContext:WaitForChild("SprintAction")
	self.SlideAction = MovementContext:WaitForChild("SlideAction")
	self.JumpAction = MovementContext:WaitForChild("JumpAction")
	return true
end

function MovementClass:OnCharacterAdded()
	local character = self.CombatClasses.Character
	local humanoid = self.CombatClasses.Humanoid
	-- CharacterAdded can race with a previous character's asynchronous setup.
	-- Dispose any existing components before binding the new character.
	self:OnCharacterRemoving()

	self.Jump = Jump.new(self)
	self.Sprint = Sprint.new(self)
	self.Slide = Slide.new(self)

	self:LoadMovementAnimations()
	if self.CombatClasses.Character ~= character then
		return
	end

	self.StateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			self.StateManager:SetState("MovementState", "JUMPING")
		elseif newState == Enum.HumanoidStateType.Freefall then
			self.StateManager:SetState("MovementState", "FALLING")
		end
	end)
end

function MovementClass:OnCharacterRemoving()
	if self.Jump then
		self.Jump:Destroy()
	end
	if self.Sprint then
		self.Sprint:Destroy()
	end
	if self.Slide then
		self.Slide:Destroy()
	end

	self.Jump = nil
	self.Sprint = nil
	self.Slide = nil

	if self.StateConnection then
		self.StateConnection:Disconnect()
		self.StateConnection = nil
	end

	if self.Animator then
		for _, Animation in pairs(self.Animations) do
			local Track = self.Animator:GetTrackByAnimationId(Animation.AnimationId)
			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end
		end
	end
	self.Animator = nil
	self.AnimationTrove:Clean()
	table.clear(self.Animations)
end

function MovementClass:Step(dt)
	if
		not self.CombatClasses.Character
		or not self.CombatClasses.Humanoid
		or not self.CombatClasses.Root
		or not self.Jump
	then
		return
	end

	self.Sprint:Step(dt)
	self.Slide:Step(dt)
	self.Jump:Step(dt)

	self:UpdateMovementState()
	self:UpdateMovementAnimation()
end

function MovementClass:UpdateMovementState()
	local Root = self.CombatClasses.Root
	local Humanoid = self.CombatClasses.Humanoid

	local HumanoidState = Humanoid:GetState()
	local IsSliding = (Root:GetAttribute("SlideTimeRemaining") or 0) > 0
	local IsGrounded = Humanoid.FloorMaterial ~= Enum.Material.Air
		and HumanoidState ~= Enum.HumanoidStateType.Jumping
		and HumanoidState ~= Enum.HumanoidStateType.Freefall
	local State = nil

	-- if not IsGrounded then
	-- 	if HumanoidState == Enum.HumanoidStateType.Jumping then
	-- 		State = "JUMPING"
	-- 	else
	-- 		State = "FALLING"
	-- 	end
	-- else
	-- 	if IsSliding then
	-- 		State = "SLIDING"
	-- 	elseif Root:GetAttribute("SprintActive") == true then
	-- 		State = "SPRINTING"
	-- 	elseif Humanoid.MoveDirection.Magnitude > 0.1 then
	-- 		State = "WALKING"
	-- 	else
	-- 		State = "IDLE"
	-- 	end
	-- end

	if not IsGrounded then
		return
	else
		if IsSliding then
			State = "SLIDING"
		elseif Root:GetAttribute("SprintActive") == true then
			State = "SPRINTING"
		elseif Humanoid.MoveDirection.Magnitude > 0.1 then
			State = "WALKING"
		else
			State = "IDLE"
		end
	end

	self.StateManager:SetState("MovementState", State)
end

function MovementClass:UpdateMovementAnimation()
	local Animator = self.Animator
	if not Animator then
		return
	end

	local Root = self.CombatClasses.Root
	local State = self.StateManager:GetState("MovementState")
	local AnimationName = StateToAnimation[State]
	local PreviousState = Root:GetAttribute("MovementAnimationState")

	-- Resolve live tracks each simulation frame; rollback can replace track handles.
	for ActionName, Animation in pairs(self.Animations) do
		if ActionName ~= AnimationName then
			local Track = Animator:GetTrackByAnimationId(Animation.AnimationId)
			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end
		end
	end

	Root:SetAttribute("MovementAnimationState", State)
	local Animation = AnimationName and self.Animations[AnimationName]
	if not Animation then
		return
	end

	local Track = Animator:GetTrackByAnimationId(Animation.AnimationId)
	local Looped = State ~= "JUMPING"
	-- Jump plays once per state entry; the marker is an attribute so it rolls back.
	if not Looped and PreviousState == State then
		return
	end
	if not Track then
		Track = Animator:LoadAnimation(Animation)
	end
	Track.Priority = Enum.AnimationPriority.Movement
	Track.Looped = Looped
	if not Track.IsPlaying or PreviousState ~= State then
		Track:Play(0.15)
	end
end

function MovementClass:LoadMovementAnimations()
	self.AnimationTrove:Clean()
	table.clear(self.Animations)

	local Character = self.CombatClasses.Character
	local Humanoid = self.CombatClasses.Humanoid
	if not Character or not Humanoid then
		return
	end
	local Animator = Humanoid:WaitForChild("Animator")
	if self.CombatClasses.Character ~= Character or self.CombatClasses.Humanoid ~= Humanoid then
		return
	end
	self.Animator = Animator
	self.CombatClasses.Root:SetAttribute("MovementAnimationState", nil)

	for ActionName, AnimationId in pairs(MovementSettings.ANIMATION_IDS) do
		local Animation = self.AnimationTrove:Add(Instance.new("Animation"))
		Animation.Name = ActionName .. "Animation"
		Animation.AnimationId = AnimationId

		-- Cache animation definitions only; tracks are loaded inside the simulation.
		self.Animations[ActionName] = Animation
	end
end

function MovementClass:Destroy()
	self:OnCharacterRemoving()
	self.Trove:Destroy()

	self.SprintAction = nil
	self.JumpAction = nil
	self.SlideAction = nil
	self.Player = nil
end

return MovementClass
