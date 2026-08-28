local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

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

	self.AnimationLoader = AnimationController.AnimationLoader
	self.CameraController = AnimationController.CameraController

	self.WeaponTrove = AnimationController.WeaponTrove
	self.AbilityTrove = AnimationController.AbilityTrove
	self.MovementTrove = AnimationController.MovementTrove
	return self
end

-- Weapon ViewModels functions

function ViewModelController:OnEquip(WeaponInfo)
	self.WeaponInfo = WeaponInfo

	self:CreateWeaponViewModel()
	self.CameraController:OnEquip(self.WeaponViewModel, self.WeaponInfo)
end

function ViewModelController:OnUnequip()
	self.WeaponTrove:Clean()
end

-- Viewmodel setup and appearance

function ViewModelController:CreateWeaponViewModel()
	self.WeaponViewModel = self.WeaponTrove:Add(WeaponViewModels:WaitForChild("HandCannonViewModel"):Clone())
	self.WeaponViewModel.Name = self.WeaponInfo.WEAPON_NAME
	self.WeaponViewModel.Parent = workspace.CurrentCamera

	self.AnimationLoader:LoadWeaponAnimations(self.WeaponViewModel, self.WeaponInfo)

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

	local weaponMotor = Instance.new("Motor6D")
	weaponMotor.Name = "WeaponMotor"
	weaponMotor.Part0 = RightArm
	weaponMotor.Part1 = Default
	weaponMotor.C0 = ArmGrip.CFrame
	weaponMotor.C1 = GunGrip.CFrame
	weaponMotor.Parent = RightArm

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

	self.AnimationLoader:LoadAbilityAnimations(self.AbilityViewModel, AbilityInfo)

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
