local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RS = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local MovementSettings = require(Settings:WaitForChild("MovementSettings"))
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Combat = script:FindFirstAncestor("Combat")
local Movement = Combat:WaitForChild("Movement")

local MovementHandler = {}

MovementHandler.__index = MovementHandler

function MovementHandler.new(StateManager, AnimationController)
	local self = setmetatable({}, MovementHandler)
	self.Trove = Trove.new()

	self.StateManager = StateManager
	self.AnimationController = AnimationController

	self.Character = nil
	self.Humanoid = nil
	self.HumanoidRootPart = nil
	self.Animate = nil

	self.CharacterAnimations = nil
	self.ViewModelAnimations = nil

	self.MovementInfo = table.clone(MovementSettings)
	self.Sprint = require(Movement:WaitForChild("Sprint")).new(self)
	self.Slide = require(Movement:WaitForChild("Slide")).new(self)
	self.Jump = require(Movement:WaitForChild("Jump")).new(self)
	self.WalkAndIdle = require(Movement:WaitForChild("WalkAndIdle")).new(self)
	return self
end

function MovementHandler:GetCharacterAnimations()
	self.CharacterAnimations = self.AnimationController:GetAnimation("Movement")
end

function MovementHandler:GetViewModelAnimations()
	self.ViewModelAnimations = self.AnimationController:GetAnimation("Weapon")
end

function MovementHandler:OnCharacterAdded(character)
	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid")
	self.HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
	self.Animate = character:WaitForChild("Animate")

	self.AnimationController.AnimationLoader:LoadMovementAnimations()
	self:GetCharacterAnimations()

	self.Jump:OnCharacterAdded()
	self.Sprint:OnCharacterAdded()
	self.Slide:OnCharacterAdded()
	self.WalkAndIdle:OnCharacterAdded()
	self:Init()
end

function MovementHandler:OnCharacterRemoved()
	self.Jump:OnCharacterRemoved()
	self.Sprint:OnCharacterRemoved()
	self.Slide:OnCharacterRemoved()
	self.WalkAndIdle:OnCharacterRemoved()
	self.Trove:Clean()

	self.Character = nil
	self.Humanoid = nil
	self.HumanoidRootPart = nil
	self.Animate = nil
end

function MovementHandler:OnWeaponEquip()
	self:GetViewModelAnimations()
	self.Jump:OnWeaponEquip()
	self.Sprint:OnWeaponEquip()
	self.Slide:OnWeaponEquip()
	self.WalkAndIdle:OnWeaponEquip()
end

function MovementHandler:OnWeaponUnequip()
	self.WalkAndIdle:OnWeaponUnequip()
	self.Jump:OnWeaponUnequip()
	self.Sprint:OnWeaponUnequip()
	self.Slide:OnWeaponUnequip()
end

function MovementHandler:BindAction(actionName, inputType, callback)
	CAS:BindAction(actionName, callback, false, inputType)

	self.Trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function MovementHandler:Init()
	self.Trove:Add(self.Humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			self.Jump:StopAnimation()
			self.Jump.DoubleJumpReady = true
			self.Jump.JumpInputReleased = false

			if self.Sprint.IsSprinting then
				self.StateManager:SetState("MovementState", "SPRINTING")
				self.Sprint:PlayAnimation()
			else
				self.StateManager:SetState("MovementState", "IDLE")
			end

			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			task.delay(self.MovementInfo.JUMP.JUMP_DELAY, function()
				if self.Humanoid and self.Humanoid.Parent then
					self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				end
			end)
		elseif newState == Enum.HumanoidStateType.Jumping then
			self.StateManager:SetState("MovementState", "JUMPING")
			self.Jump:PlayAnimation()
		elseif newState == Enum.HumanoidStateType.Freefall then
			self.StateManager:SetState("MovementState", "FALLING")
		end
	end))

	self:BindAction("DoubleJump", Enum.KeyCode.Space, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
				self.Jump.JumpInputReleased = false
			elseif self.Jump:CanDoubleJump() then
				self.Jump:DoubleJump()
			end
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.Jump.JumpInputReleased = true
		end

		return Enum.ContextActionResult.Pass
	end)

	self:BindAction("Sprint", Enum.KeyCode.LeftShift, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.Sprint:StartSprint()
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.Sprint:StopSprint()
		end
		return Enum.ContextActionResult.Sink
	end)

	self:BindAction("Slide", Enum.KeyCode.LeftControl, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.Slide:StartSlide()
		end
		return Enum.ContextActionResult.Sink
	end)
end

return MovementHandler
