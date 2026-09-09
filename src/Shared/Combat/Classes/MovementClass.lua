local Movement = script.Parent.Parent:WaitForChild("Movement")
local Jump = require(Movement:WaitForChild("Jump"))
local Sprint = require(Movement:WaitForChild("Sprint"))
local Slide = require(Movement:WaitForChild("Slide"))

local RunService = game:GetService("RunService")

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
	--WALKING = "WALK",
	SPRINTING = "SPRINT",
	--JUMPING = "JUMP",
	--FALLING = "FALL",
	SLIDING = "SLIDE",
})

local MovementClass = {}

MovementClass.__index = MovementClass

function MovementClass.new(Player, StateManager)
	local self = setmetatable({}, MovementClass)
	self.Trove = Trove.new()
	self.AnimationTrove = self.Trove:Extend()

	self.Player = Player
	self.StateManager = StateManager
	self.MovementSettings = table.clone(MovementSettings)

	self.Animations = {}
	self.ActiveAnimation = nil

	self:Init()
	return self
end

function MovementClass:OnCharacterAdded(character, humanoid, root)
	-- CharacterAdded can race with a previous character's asynchronous setup.
	-- Dispose any existing components before binding the new character.
	self:OnCharacterRemoving()

	self.Character = character
	self.Humanoid = humanoid
	self.Root = root

	self.Jump = Jump.new(self)
	self.Sprint = Sprint.new(self)
	self.Slide = Slide.new(self)

	self.StateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			self.StateManager:SetState("MovementState", "JUMPING")
		elseif newState == Enum.HumanoidStateType.Freefall then
			self.StateManager:SetState("MovementState", "FALLING")
		end
	end)

	self:LoadMovementAnimations()
	self:UpdateMovementAnimation(self.StateManager:GetState("MovementState"))
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

	self.Character = nil
	self.Humanoid = nil
	if self.StateConnection then
		self.StateConnection:Disconnect()
		self.StateConnection = nil
	end

	self.Root = nil
	if self.ActiveAnimation then
		self.ActiveAnimation:Stop(0.15)
		self.ActiveAnimation = nil
	end
end

function MovementClass:Step(dt)
	if not self.Character or not self.Humanoid or not self.Root then
		return
	end

	self.Sprint:Step(dt)
	self.Slide:Step(dt)
	self.Jump:Step(dt)

	self:UpdateMovementState()
end

function MovementClass:UpdateMovementState()
	local Root = self.Root
	local Humanoid = self.Humanoid

	local HumanoidState = Humanoid:GetState()
	local IsSliding = (Root:GetAttribute("SlideTimeRemaining") or 0) > 0
	local IsGrounded = Humanoid.FloorMaterial ~= Enum.Material.Air

	if IsSliding then
		self.StateManager:SetState("MovementState", "SLIDING")
	elseif HumanoidState == Enum.HumanoidStateType.Jumping then
		self.StateManager:SetState("MovementState", "JUMPING")
	elseif not IsGrounded then
		self.StateManager:SetState("MovementState", "FALLING")
	elseif self.Sprint:CanSprint() then
		self.StateManager:SetState("MovementState", "SPRINTING")
	elseif Humanoid.MoveDirection.Magnitude > 0.1 then
		self.StateManager:SetState("MovementState", "WALKING")
	else
		self.StateManager:SetState("MovementState", "IDLE")
	end
end

function MovementClass:UpdateMovementAnimation(newState)
	local AnimationName = StateToAnimation[newState]
	local NextAnimation = AnimationName and self.Animations[AnimationName] or nil

	if self.ActiveAnimation == NextAnimation then
		return
	end

	if self.ActiveAnimation then
		self.ActiveAnimation:Stop(0.15)
	end

	self.ActiveAnimation = NextAnimation

	if not NextAnimation then
		return
	end

	-- Keep custom movement tracks above Roblox's default Animate tracks.
	NextAnimation.Priority = Enum.AnimationPriority.Movement
	NextAnimation.Looped = newState == "SPRINTING"
	NextAnimation:Play(0.15)
end

function MovementClass:LoadMovementAnimations()
	self.AnimationTrove:Clean()
	table.clear(self.Animations)

	local Character = self.Character or self.Player.Character or self.Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:WaitForChild("Animator")

	for ActionName, AnimationId in pairs(MovementSettings.ANIMATION_IDS) do
		local Animation = Instance.new("Animation")
		Animation.Name = ActionName .. "Animation"
		Animation.AnimationId = AnimationId

		local LoadedAnimation = Animator:LoadAnimation(Animation)
		self.Animations[ActionName] = self.AnimationTrove:Add(LoadedAnimation)
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

function MovementClass:Init()
	if RunService:IsServer() then
		self.Trove:Add(self.StateManager.StateChangedSignal:Connect(function(stateType, newState)
			if stateType == "MovementState" then
				self:UpdateMovementAnimation(newState)
			end
		end))
	end
end

return MovementClass
