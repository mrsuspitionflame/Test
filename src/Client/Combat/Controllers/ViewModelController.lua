local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Utility = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility")
local AnimationLoader = require(Utility:WaitForChild("AnimationLoader"))

local Models = ReplicatedStorage:WaitForChild("Models")
local ViewModels = Models:WaitForChild("ViewModels")
local WeaponViewModels = ViewModels:WaitForChild("WeaponViewModels")
local WeaponModels = Models:WaitForChild("WeaponModels")

local ViewModelController = {}
ViewModelController.__index = ViewModelController

-- Lifecycle

function ViewModelController.new(AnimationController)
	local self = setmetatable({}, ViewModelController)

	self.AnimationController = AnimationController
	self.StateManager = AnimationController.StateManager
	self.CameraController = AnimationController.CameraController
	self.WeaponTrove = AnimationController.WeaponTrove
	self.AbilityTrove = AnimationController.AbilityTrove

	AnimationController.Trove:Add(self.StateManager.StateChangedSignal:Connect(function(stateType, newState)
		if stateType == "MovementState" then
			self:UpdateMovementAnimations(newState)
		end
	end))
	return self
end

function ViewModelController:UpdateMovementAnimations(newState)
	local animations = self.AnimationController.WeaponAnimations
	local 

	walk:Stop(0.15)
	sprint:Stop(0.15)
	jump:Stop(0.15)
	idle:Stop(0.15)
	slide:Stop(0.15)

	if newState == "WALKING" then
		walk.Looped = true
		walk:Play(0.15)
	elseif newState == "JUMPING" then
		jump.Looped = false
		jump:Play(0.15)
	elseif newState == "IDLE" then
		idle.Looped = true
		idle:Play(0.15)
	elseif newState == "SPRINTING" then
		sprint.Looped = true
		sprint:Play(0.15)
	elseif newState == "SLIDING" then
		slide.Looped = true
		slide:Play(0.15)
	end
end

-- Weapon ViewModels functions

function ViewModelController:OnEquip(WeaponInfo)
	self.WeaponInfo = WeaponInfo

	self:CreateWeaponViewModel()
	self.CameraController:OnEquip(self.WeaponViewModel, self.WeaponInfo)
	self:UpdateMovementAnimations(self.StateManager:GetState("MovementState"))
end

function ViewModelController:OnUnequip()
	self.WeaponTrove:Clean()
end

-- Viewmodel setup and appearance

function ViewModelController:CreateWeaponViewModel()
	self.WeaponViewModel = self.WeaponTrove:Add(WeaponViewModels:WaitForChild("HandCannonViewModel"):Clone())
	self.WeaponViewModel.Name = self.WeaponInfo.WEAPON_NAME
	self.WeaponViewModel.Parent = workspace.CurrentCamera

	self.AnimationController.WeaponAnimations = AnimationLoader.LoadWeaponAnimations(
		Player, self.WeaponTrove, self.WeaponViewModel, self.WeaponInfo
	)

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

	self.AnimationController.AbilityAnimations = AnimationLoader.LoadAbilityAnimations(
		Player, self.AbilityTrove, self.AbilityViewModel, AbilityInfo
	)

	self:ApplyViewModelAppearance(self.AbilityViewModel)
	self.AbilityViewModel.Parent = nil
end

function ViewModelController:ShowAbilityViewModel()
	self.AbilityViewModelTrove = self.AbilityTrove:Extend()

	local camera = workspace.CurrentCamera

	self.AbilityViewModel.Parent = camera

	self.CameraController:OnAbilityCast(self.AbilityViewModel, self.AbilityViewModelTrove)
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

function ViewModelController:GetRayOrigin()
	return self.RayOrigin.WorldPosition
end

function ViewModelController:GetMuzzle()
	return self.Muzzle
end

return ViewModelController
