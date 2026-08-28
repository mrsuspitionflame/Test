local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Models = ReplicatedStorage:WaitForChild("Models")
local ViewModels = Models:WaitForChild("ViewModels")
local ServerViewModels = ViewModels:WaitForChild("ServerViewModels")
local WeaponViewModels = ServerViewModels:WaitForChild("WeaponViewModels")
local WeaponModels = Models:WaitForChild("WeaponModels")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))

local Trove = require(Packages:WaitForChild("Trove"))

local ViewModelAnimation = {}
ViewModelAnimation.__index = ViewModelAnimation

-- Lifecycle

function ViewModelAnimation.new(AnimationClass)
	local self = setmetatable({}, ViewModelAnimation)

	self.AnimationClass = AnimationClass
	self.Player = AnimationClass.Player

	self.Trove = Trove.new()
	self.WeaponTrove = self.Trove:Extend()
	self.AbilityTrove = self.Trove:Extend()

	self.WeaponAnimations = AnimationClass.ViewModelAnimations.WeaponAnimations
	self.AbilityAnimations = AnimationClass.ViewModelAnimations.AbilityAnimations

	return self
end

-- Weapon ViewModels functions

function ViewModelAnimation:OnEquip(WeaponInfo)
	self.WeaponInfo = WeaponInfo
	self:Init()
end

function ViewModelAnimation:OnUnequip()
	self.WeaponTrove:Clean()
	self.WeaponMotor = nil
end

function ViewModelAnimation:Init()
	self:CreateWeaponViewModel()

	self:SetArmsTransparency(1)
	self.WeaponTrove:Add(function()
		self:SetArmsTransparency(0)
	end)

	self:EquipWeaponViewModel()
end

function ViewModelAnimation:CreateWeaponViewModel()
	self.WeaponViewModel = self.WeaponTrove:Add(WeaponViewModels:WaitForChild("HandCannonViewModel"):Clone())
	self.WeaponViewModel.Name = self.WeaponInfo.WEAPON_NAME .. "ViewModel"
	self.WeaponViewModel.Parent = self.Player.Character

	local humanoid = self.WeaponViewModel:FindFirstChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for actionName, animationID in pairs(self.WeaponInfo.ANIMATION_IDS.Character) do
		if animationID == nil then
			continue
		end
		local animation = Instance.new("Animation")
		animation.Name = actionName .. "Animation"
		animation.AnimationId = animationID

		local loadedAnimation = animator:LoadAnimation(animation)

		self.WeaponAnimations[actionName] = self.WeaponTrove:Add(loadedAnimation)
	end

	local WeaponModel = WeaponModels:WaitForChild(self.WeaponInfo.WEAPON_TYPE):WaitForChild("HandCannonModel"):Clone()

	self:AttachWeaponModel(self.WeaponViewModel, WeaponModel)
	self:ApplyViewModelAppearance(self.WeaponViewModel)
end

function ViewModelAnimation:AttachWeaponModel(ViewModel, WeaponModel)
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

	self.RayOrigin = Default:WaitForChild("RayOrigin")
	self.Muzzle = Default:WaitForChild("MuzzleAttachment")
end

function ViewModelAnimation:EquipWeaponViewModel()
	local character = self.Player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	if not self.WeaponViewModel then
		return
	end

	local primaryPart = self.WeaponViewModel.PrimaryPart
	if not primaryPart then
		return
	end

	self.WeaponViewModel:PivotTo(head.CFrame)

	local motor = Instance.new("Motor6D")
	motor.Name = "ServerViewModelMotor"
	motor.Part0 = head
	motor.Part1 = primaryPart
	motor.C0 = CFrame.new(0, 0.25, -0.5)
	motor.C1 = CFrame.identity
	motor.Parent = head

	self.WeaponMotor = self.WeaponTrove:Add(motor)
end

-- Ability ViewModels functions

function ViewModelAnimation:CreateAbilityViewModel(data)
	self.AbilityViewModel = self.AbilityTrove:Add(ServerViewModels:WaitForChild("AbilityViewModel"):Clone())
	self.AbilityViewModel.Name = "AbilityViewModel"
	self.AbilityViewModel.Parent = workspace

	local humanoid = self.AbilityViewModel:FindFirstChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for abilityType, abilityName in pairs(data) do
		if not AbilitySettings[abilityType] or not AbilitySettings[abilityType][abilityName] then
			continue
		end
		local abilityInfo = AbilitySettings[abilityType][abilityName]
		if abilityInfo.ANIMATION_TYPE == "ViewModel" then
			for actionName, animationID in pairs(abilityInfo.ANIMATION_IDS) do
				if animationID == nil then
					continue
				end
				local animation = Instance.new("Animation")
				animation.Name = actionName .. "Animation"
				animation.AnimationId = animationID

				local loadedAnimation = animator:LoadAnimation(animation)

				if not self.AbilityAnimations[abilityType] then
					self.AbilityAnimations[abilityType] = {}
				end

				self.AbilityAnimations[abilityType][actionName] = self.AbilityTrove:Add(loadedAnimation)
			end
		end

		self:ApplyViewModelAppearance(self.AbilityViewModel)
		self.AbilityViewModel.Parent = nil
	end
end

function ViewModelAnimation:ShowAbilityViewModel()
	local character = self.Player.Character
	self.AbilityViewModel.Parent = character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	if not self.AbilityViewModel then
		return
	end

	local primaryPart = self.AbilityViewModel.PrimaryPart
	if not primaryPart then
		return
	end

	self.AbilityViewModel:PivotTo(head.CFrame)

	local motor = Instance.new("Motor6D")
	motor.Name = "ServerViewModelMotor"
	motor.Part0 = head
	motor.Part1 = primaryPart
	motor.C0 = CFrame.new(0, 0.25, -0.5)
	motor.C1 = CFrame.identity
	motor.Parent = head

	self.AbilityMotor = self.AbilityTrove:Add(motor)
end

function ViewModelAnimation:HideAbilityViewModel()
	if self.AbilityMotor then
		self.AbilityMotor:Destroy()
		self.AbilityMotor = nil
	end

	if self.AbilityViewModel then
		self.AbilityViewModel.Parent = nil
	end
end

-- Shared functions

function ViewModelAnimation:ApplyViewModelAppearance(ViewModel)
	if not self.Player:HasAppearanceLoaded() then
		self.Player.CharacterAppearanceLoaded:Wait()
	end

	local character = self.Player.Character or self.Player.CharacterAdded:Wait()

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

function ViewModelAnimation:SetArmsTransparency(transparency)
	local char = self.Player.Character or self.Player.CharacterAdded:Wait()
	if not char then
		return
	end

	local rightArm = char:WaitForChild("Right Arm")
	local leftArm = char:WaitForChild("Left Arm")

	rightArm.Transparency = transparency
	leftArm.Transparency = transparency
end

function ViewModelAnimation:HideArms(LeftArm, RightArm)
	if LeftArm then
		LeftArm.Transparency = 1
	end

	if RightArm then
		RightArm.Transparency = 1
	end
end

function ViewModelAnimation:GetRayOrigin()
	return self.RayOrigin.WorldPosition
end

return ViewModelAnimation
