local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local WalkAndIdle = {}

WalkAndIdle.__index = WalkAndIdle

function WalkAndIdle.new(MovementController)
	local self = setmetatable({}, WalkAndIdle)

	self.MovementController = MovementController
	self.StateManager = MovementController.StateManager
	self.Humanoid = nil

	self.Trove = Trove.new()
	self.WalkViewModelAnimation = nil

	return self
end

function WalkAndIdle:PlayAnimation()
	if self.WalkViewModelAnimation and not self.WalkViewModelAnimation.IsPlaying then
		self.WalkViewModelAnimation:Play(0.15)
	end
end

function WalkAndIdle:StopAnimation()
	if self.WalkViewModelAnimation and self.WalkViewModelAnimation.IsPlaying then
		self.WalkViewModelAnimation:Stop(0.15)
	end
end

function WalkAndIdle:OnRunning(speed)
	local movementState = self.StateManager:GetState("MovementState")

	if
		self.MovementController.Sprint.IsSprinting
		or movementState == "SLIDING"
		or movementState == "JUMPING"
		or movementState == "FALLING"
	then
		return
	end

	if speed > 0.1 then
		if movementState ~= "WALKING" then
			self.StateManager:SetState("MovementState", "WALKING")
		end
	else
		if movementState ~= "IDLE" then
			self.StateManager:SetState("MovementState", "IDLE")
		end
	end
end

function WalkAndIdle:OnStateChanged(stateType, newState, oldState)
	if stateType ~= "MovementState" then
		return
	end

	if newState == "WALKING" then
		self:PlayAnimation()
	elseif oldState == "WALKING" then
		self:StopAnimation()
	end
end

function WalkAndIdle:OnCharacterAdded()
	self.Trove:Clean()
	self.Humanoid = self.MovementController.Humanoid

	self.Trove:Add(self.Humanoid.Running:Connect(function(speed)
		self:OnRunning(speed)
	end))

	self.Trove:Add(self.StateManager.StateChangedSignal:Connect(function(stateType, newState, oldState)
		self:OnStateChanged(stateType, newState, oldState)
	end))
end

function WalkAndIdle:OnCharacterRemoved()
	self:StopAnimation()
	self.Trove:Clean()
	self.Humanoid = nil
end

function WalkAndIdle:OnWeaponEquip()
	local walkAnimations = self.MovementController.ViewModelAnimations
		and self.MovementController.ViewModelAnimations.WALK

	self.WalkViewModelAnimation = walkAnimations and walkAnimations.VIEWMODEL

	if self.StateManager:GetState("MovementState") == "WALKING" then
		self:PlayAnimation()
	end
end

function WalkAndIdle:OnWeaponUnequip()
	self:StopAnimation()
	self.WalkViewModelAnimation = nil
end

return WalkAndIdle
