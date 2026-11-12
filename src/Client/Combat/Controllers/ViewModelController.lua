local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Utility = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility")
local AnimationLoader = require(Utility:WaitForChild("AnimationLoader"))

local RS = game:GetService("RunService")

local Models = ReplicatedStorage:WaitForChild("Models")
local ViewModels = Models:WaitForChild("ViewModels")
local WeaponViewModels = ViewModels:WaitForChild("WeaponViewModels")
local WeaponModels = Models:WaitForChild("WeaponModels")

local MovementAnimations = {
	WALKING = "WALK",
	SPRINTING = "SPRINT",
	JUMPING = "JUMP",
	SLIDING = "SLIDE",
}

local ViewModelController = {}
ViewModelController.__index = ViewModelController

-- Lifecycle

function ViewModelController.new(CombatController)
	local self = setmetatable({}, ViewModelController)

	self.CombatController = CombatController
	self.StateManager = CombatController.StateManager
	self.CameraController = CombatController.CameraController
	self.WeaponTrove = CombatController.WeaponTrove
	self.AbilityTrove = CombatController.AbilityTrove

	return self
end
-- Weapon ViewModels functions

function ViewModelController:OnEquip(WeaponInfo)
	self.WeaponInfo = WeaponInfo

	self:CreateWeaponViewModel()
	self.CameraController:OnEquip(self.WeaponInfo)

	local head = self.WeaponViewModel:WaitForChild("Head")
	self.WeaponAimPart = head:FindFirstChild("AimPartAttachment")
	self.SwayCF = CFrame.new()
	self.AimCF = CFrame.new()
	self.LastCameraCF = workspace.CurrentCamera.CFrame
	self.LastMovementState = nil
	self.ActiveMovementAnimation = nil

	self.WeaponBindingName = "Update" .. self.WeaponInfo.WEAPON_NAME .. "WeaponViewModel"
	self.WeaponTrove:BindToRenderStep(self.WeaponBindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		self:UpdateWeaponViewModel(deltaTime)
		self:UpdateWeaponViewModelMovementAnimation()
	end)
end

function ViewModelController:OnUnequip()
	self.WeaponTrove:Clean()
	self.LastMovementState = nil
	self.ActiveMovementAnimation = nil
end

-- Viewmodel setup and appearance

function ViewModelController:CreateWeaponViewModel()
	self.WeaponViewModel = self.WeaponTrove:Add(WeaponViewModels:WaitForChild("HandCannonViewModel"):Clone())
	self.WeaponViewModel.Name = self.WeaponInfo.WEAPON_NAME
	self.WeaponViewModel.Parent = workspace.CurrentCamera

	self.WeaponAnimations =
		AnimationLoader.LoadWeaponAnimations(Player, self.WeaponTrove, self.WeaponViewModel, self.WeaponInfo)

	local WeaponModel = WeaponModels:WaitForChild(self.WeaponInfo.WEAPON_TYPE):WaitForChild("HandCannonModel"):Clone()

	self:AttachWeaponModel(self.WeaponViewModel, WeaponModel)
	self:ApplyViewModelAppearance(self.WeaponViewModel)
end

function ViewModelController:AttachWeaponModel(ViewModel, WeaponModel)
	local RightArm = ViewModel:FindFirstChild("Right Arm", true)
	local Default = WeaponModel:WaitForChild("Default")

	local ArmGrip = RightArm:WaitForChild("WeaponGripAttachment")
	local GunGrip = Default:WaitForChild("WeaponGripAttachment")

	WeaponModel.Parent = ViewModel

	local weaponMotor = self.WeaponTrove:Add(Instance.new("Motor6D"))
	weaponMotor.Name = "WeaponMotor"
	weaponMotor.Part0 = RightArm
	weaponMotor.Part1 = Default
	weaponMotor.C0 = ArmGrip.CFrame
	weaponMotor.C1 = GunGrip.CFrame
	weaponMotor.Parent = RightArm

	self.WeaponMotor = weaponMotor

	local Head = ViewModel:WaitForChild("Head", true)
	local WeaponAimPartReference = Default:WaitForChild("AimPartReference")
	local WeaponAimPart = Head:WaitForChild("AimPartAttachment")
	WeaponAimPart.WorldCFrame = WeaponAimPartReference.WorldCFrame

	self.WeaponAimPart = WeaponAimPart
	self.RayOrigin = Default:WaitForChild("RayOrigin")
	self.Muzzle = Default:WaitForChild("MuzzleAttachment")
end

-- Ability ViewModels functions

function ViewModelController:CreateAbilityViewModel(AbilityInfo)
	self.AbilityViewModel = self.AbilityTrove:Add(ViewModels:WaitForChild("AbilityViewModel"):Clone())
	self.AbilityViewModel.Name = "AbilityViewModel"
	self.AbilityViewModel.Parent = workspace

	self.AbilityAnimations =
		AnimationLoader.LoadAbilityAnimations(Player, self.AbilityTrove, self.AbilityViewModel, AbilityInfo)

	self:ApplyViewModelAppearance(self.AbilityViewModel)
	self.AbilityViewModel.Parent = nil
end

function ViewModelController:ShowAbilityViewModel()
	self.AbilityViewModelTrove = self.AbilityTrove:Extend()

	local camera = workspace.CurrentCamera

	self.AbilityViewModel.Parent = camera

	self:OnAbilityCast(self.AbilityViewModel, self.AbilityViewModelTrove)
end

function ViewModelController:HideAbilityViewModel()
	self.AbilityViewModelTrove:Clean()
	self.AbilityViewModel.Parent = nil
end

--Shared functions

function ViewModelController:ApplyViewModelAppearance(ViewModel)
	if not Player:HasAppearanceLoaded() then
		Player.CharacterAppearanceLoaded:Wait()
	end

	local character = Player.Character or Player.CharacterAdded:Wait()

	for _, armName in { "Right Arm", "Left Arm" } do
		local characterArm = character:FindFirstChild(armName)
		local weaponViewModelArm = ViewModel:FindFirstChild(armName, true)

		if characterArm and weaponViewModelArm then
			weaponViewModelArm.Color = characterArm.Color
		end
	end

	local characterShirt = character:FindFirstChildOfClass("Shirt")

	if characterShirt then
		local weaponViewModelShirt = ViewModel:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")

		weaponViewModelShirt.ShirtTemplate = characterShirt.ShirtTemplate
		weaponViewModelShirt.Parent = ViewModel
	end
end

-- Helper functions

function ViewModelController:GetRayOrigin()
	return self.RayOrigin.WorldPosition
end

function ViewModelController:GetMuzzle()
	return self.Muzzle
end

function ViewModelController:OnAbilityCast(ViewModel, AbilityViewModelTrove)
	self.AbilityViewModel = ViewModel

	local head = self.AbilityViewModel:WaitForChild("Head")

	if head:FindFirstChild("AimPartAttachment") then
		self.AbilityAimPart = head:FindFirstChild("AimPartAttachment")
	end

	self.AbilityBindingName = "UpdateAbilityViewModel"

	self.AbilitySwayCF = CFrame.new()
	self.AbilityAimCF = CFrame.new()
	self.AbilityLastCameraCF = workspace.CurrentCamera.CFrame

	AbilityViewModelTrove:BindToRenderStep(
		self.AbilityBindingName,
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime)
			self:UpdateAbilityViewModel(deltaTime)
		end
	)
end

function ViewModelController:UpdateWeaponViewModel(deltaTime: number)
	deltaTime = math.min(deltaTime, 1 / 30)

	local camera = workspace.CurrentCamera
	local cameraCF = camera.CFrame

	local rotation = cameraCF:ToObjectSpace(self.LastCameraCF)
	local x, y = rotation:ToOrientation()

	local swayAmount
	if self.WeaponInfo.HANDLING >= 95 then
		swayAmount = 0.1
	else
		swayAmount = (100 - self.WeaponInfo.HANDLING) / 20
	end
	local targetSway = CFrame.Angles(math.sin(x) * swayAmount, math.sin(y) * swayAmount, 0)

	-- Speeds are measured approximately per second
	local swaySpeed = 12
	local handlingPercent = math.clamp(self.WeaponInfo.HANDLING / 100, 0, 1)
	local aimSpeed = 10 + handlingPercent * 15

	local swayAlpha = 1 - math.exp(-swaySpeed * deltaTime)

	local aimAlpha = 1 - math.exp(-aimSpeed * deltaTime)

	self.SwayCF = self.SwayCF:Lerp(targetSway, swayAlpha)

	self.LastCameraCF = cameraCF

	local targetAimCF = CFrame.new()

	if self.StateManager:GetState("AimState") == "AIMING" and self.WeaponAimPart then
		targetAimCF = self.WeaponAimPart.WorldCFrame:ToObjectSpace(self.WeaponViewModel:GetPivot())
	end

	self.AimCF = self.AimCF:Lerp(targetAimCF, aimAlpha)

	self.WeaponViewModel:PivotTo(cameraCF * self.SwayCF * self.AimCF)
end

function ViewModelController:UpdateAbilityViewModel(deltaTime: number)
	-- Prevent unusually large jumps after lag spikes
	deltaTime = math.min(deltaTime, 1 / 30)

	local camera = workspace.CurrentCamera
	local cameraCF = camera.CFrame

	local rotation = cameraCF:ToObjectSpace(self.AbilityLastCameraCF)
	local x, y = rotation:ToOrientation()

	local swayAmount = 0.2

	local targetSway = CFrame.Angles(math.sin(x) * swayAmount, math.sin(y) * swayAmount, 0)

	-- Speeds are measured approximately per second
	local swaySpeed = 12
	local handlingPercent = 0.8
	local aimSpeed = 10 + handlingPercent * 15

	local swayAlpha = 1 - math.exp(-swaySpeed * deltaTime)

	local aimAlpha = 1 - math.exp(-aimSpeed * deltaTime)

	self.AbilitySwayCF = self.AbilitySwayCF:Lerp(targetSway, swayAlpha)

	self.AbilityLastCameraCF = cameraCF

	local targetAimCF = CFrame.new()

	if self.StateManager:GetState("AimState") == "AIMING" and self.AbilityAimPart then
		targetAimCF = self.AbilityAimPart.WorldCFrame:ToObjectSpace(self.AbilityViewModel:GetPivot())
	end

	self.AbilityAimCF = self.AbilityAimCF:Lerp(targetAimCF, aimAlpha)

	self.AbilityViewModel:PivotTo(cameraCF * self.AbilitySwayCF * self.AbilityAimCF)
end

function ViewModelController:UpdateWeaponViewModelMovementAnimation()
	local movementState = self.StateManager.Root and self.StateManager:GetState("MovementState")
	if movementState == self.LastMovementState then
		return
	end
	self.LastMovementState = movementState

	local animationName = MovementAnimations[movementState]
	local animations = animationName and self.WeaponAnimations and self.WeaponAnimations[animationName]
	local nextAnimation = animations and animations.VIEWMODEL

	if self.ActiveMovementAnimation then
		self.ActiveMovementAnimation:Stop(0.15)
	end
	self.ActiveMovementAnimation = nextAnimation

	if nextAnimation then
		nextAnimation.Priority = Enum.AnimationPriority.Movement
		nextAnimation.Looped = movementState == "WALKING" or movementState == "SPRINTING"
		nextAnimation:Play(0.15)
	end
end

return ViewModelController
