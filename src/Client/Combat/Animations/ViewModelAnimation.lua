local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local TS = game:GetService("TweenService")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Models = ReplicatedStorage:WaitForChild("Models")
local ViewModels = Models:WaitForChild("ViewModels")
local ClientViewModels = ViewModels:WaitForChild("ClientViewModels")
local WeaponViewModels = ClientViewModels:WaitForChild("WeaponViewModels")
local WeaponModels = Models:WaitForChild("WeaponModels")

local Trove = require(Packages:WaitForChild("Trove"))

local ViewModelAnimation = {}
ViewModelAnimation.__index = ViewModelAnimation

-- Lifecycle

function ViewModelAnimation.new(AnimationController)
	local self = setmetatable({}, ViewModelAnimation)
	self.AnimationController = AnimationController

	self.Trove = Trove.new()
	self.WeaponTrove = self.Trove:Extend()
	self.AbilityTrove = self.Trove:Extend()
	self.AbilityViewModelTrove = self.AbilityTrove:Extend()

	self.WeaponAnimations = AnimationController.ViewModelAnimations.WeaponAnimations
	self.AbilityAnimations = AnimationController.ViewModelAnimations.AbilityAnimations

	return self
end

-- Weapon ViewModels functions

function ViewModelAnimation:OnEquip(WeaponInfo)
	self.WeaponInfo = WeaponInfo

	self.Aiming = false
	self.Zooming = false

	self.ZoomTween = nil
	self.SwayCF = CFrame.new()
	self.AimCF = CFrame.new()
	self.LastCameraCF = workspace.CurrentCamera.CFrame

	self.RecoilAngle = 0
	self.RecoilVelocity = 0
	self.PreviousRecoilAngle = 0

	self.ZoomTrove = self.WeaponTrove:Extend()
	self:Init()
end

function ViewModelAnimation:OnUnequip()
	self.WeaponTrove:Clean()
	table.clear(self.WeaponAnimations)
end

function ViewModelAnimation:Init()
	self:CreateWeaponViewModel()
	Player.CameraMode = Enum.CameraMode.LockFirstPerson

	self.WeaponTrove:Add(function()
		Player.CameraMode = Enum.CameraMode.Classic
	end)

	self.WeaponTrove:Add(function()
		workspace.CurrentCamera.FieldOfView = 80
	end)

	self:HideServerWeaponViewModel()

	self.WeaponBindingName = "Update" .. self.WeaponInfo.WEAPON_NAME .. "WeaponViewModel"

	self.WeaponTrove:BindToRenderStep(self.WeaponBindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		self:UpdateWeaponViewModelAndSway(deltaTime)
		self:UpdateRecoil(deltaTime)
	end)
end

function ViewModelAnimation:UpdateRecoil(deltaTime: number)
	local Stiffness = self.WeaponInfo.STIFFNESS
	local Damping = self.WeaponInfo.DAMPING

	deltaTime = math.min(deltaTime, 0.1)

	local oldAngle = self.RecoilAngle
	local remainingTime = deltaTime
	local maximumStep = 1 / 120

	while remainingTime > 0 do
		local step = math.min(remainingTime, maximumStep)

		local acceleration = -self.RecoilAngle * Stiffness - self.RecoilVelocity * Damping

		self.RecoilVelocity += acceleration * step
		self.RecoilAngle += self.RecoilVelocity * step

		remainingTime -= step
	end

	local angleChange = self.RecoilAngle - oldAngle

	workspace.CurrentCamera.CFrame *= CFrame.Angles(math.rad(angleChange), 0, 0)

	if math.abs(angleChange) > 5 then
		warn("Large camera recoil jump:", angleChange, self.RecoilAngle, self.RecoilVelocity)
	end
end

function ViewModelAnimation:UpdateWeaponViewModelAndSway(deltaTime: number)
	-- Prevent unusually large jumps after lag spikes
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

	if self.Aiming and self.AimPart then
		targetAimCF = self.AimPart.WorldCFrame:ToObjectSpace(self.WeaponViewModel:GetPivot())
	end

	self.AimCF = self.AimCF:Lerp(targetAimCF, aimAlpha)

	self.WeaponViewModel:PivotTo(cameraCF * self.SwayCF * self.AimCF)
end

-- Viewmodel setup and appearance

function ViewModelAnimation:CreateWeaponViewModel()
	self.WeaponViewModel = self.WeaponTrove:Add(WeaponViewModels:WaitForChild("HandCannonViewModel"):Clone())
	self.WeaponViewModel.Name = self.WeaponInfo.WEAPON_NAME
	self.WeaponViewModel.Parent = workspace.CurrentCamera

	local humanoid = self.WeaponViewModel:FindFirstChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for actionName, animationID in pairs(self.WeaponInfo.ANIMATION_IDS.ViewModel) do
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

	local Head = ViewModel:WaitForChild("Head", true)
	local AimPartReference = Default:WaitForChild("AimPartReference")
	local AimPart = Head:WaitForChild("AimPartAttachment")
	AimPart.WorldCFrame = AimPartReference.WorldCFrame
	self.AimPart = AimPart

	self.RayOrigin = Default:WaitForChild("RayOrigin")
	self.Muzzle = Default:WaitForChild("MuzzleAttachment")
end

-- Ability ViewModels functions

function ViewModelAnimation:CreateAbilityViewModel(data)
	self.AbilityViewModel = self.AbilityTrove:Add(ClientViewModels:WaitForChild("AbilityViewModel"):Clone())
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
	end

	self:ApplyViewModelAppearance(self.AbilityViewModel)
	self.AbilityViewModel.Parent = nil
end

function ViewModelAnimation:ShowAbilityViewModel()
	self.AbilityViewModelTrove:Clean()

	local camera = workspace.CurrentCamera

	self.AbilitySwayCF = CFrame.new()
	self.AbilityAimCF = CFrame.new()
	self.AbilityLastCameraCF = camera.CFrame

	self.AbilityViewModel.Parent = camera
	self.AbilityViewModel:PivotTo(camera.CFrame)

	self.AbilityBindingName = "UpdateAbilityViewModel"

	self.AbilityViewModelTrove:BindToRenderStep(
		self.AbilityBindingName,
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime)
			self:UpdateAbilityViewModelAndSway(deltaTime)
		end
	)
end

function ViewModelAnimation:HideAbilityViewModel()
	self.AbilityViewModelTrove:Clean()
	self.AbilityViewModel.Parent = nil
end

function ViewModelAnimation:UpdateAbilityViewModelAndSway(deltaTime: number)
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

	if self.Aiming and self.AbilityAimPart then
		targetAimCF = self.AbilityAimPart.WorldCFrame:ToObjectSpace(self.AbilityViewModel:GetPivot())
	end

	self.AbilityAimCF = self.AbilityAimCF:Lerp(targetAimCF, aimAlpha)

	self.AbilityViewModel:PivotTo(cameraCF * self.AbilitySwayCF * self.AbilityAimCF)
end

--Shared functions

function ViewModelAnimation:ApplyViewModelAppearance(ViewModel)
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

function ViewModelAnimation:HideServerWeaponViewModel()
	local char = Player.Character or Player.CharacterAdded:Wait()
	local serverViewModel

	if not char:FindFirstChild(self.WeaponInfo.WEAPON_NAME .. "ViewModel") then
		return
	else
		serverViewModel = char:FindFirstChild(self.WeaponInfo.WEAPON_NAME .. "ViewModel")
	end

	if serverViewModel then
		serverViewModel:Destroy()
	end
end

function ViewModelAnimation:HideServerAbilityViewModel()
	local char = Player.Character or Player.CharacterAdded:Wait()
	local serverViewModel

	if not char:FindFirstChild("AbilityViewModel") then
		return
	else
		serverViewModel = char:FindFirstChild("AbilityViewModel")
	end

	if serverViewModel then
		serverViewModel:Destroy()
	end
end

function ViewModelAnimation:GetRayOrigin()
	return self.RayOrigin.WorldPosition
end

-- Animation access and actions
function ViewModelAnimation:Recoil()
	local RecoilAmount = math.max(0, self.WeaponInfo.BASE_RECOIL - self.WeaponInfo.STABILITY)
	self.RecoilVelocity += RecoilAmount
	self.Muzzle.FlashEmitter:Emit(1)
	self.Muzzle.CircleEmitter:Emit(1)
	return
end

-- Camera state transitions

function ViewModelAnimation:ZoomCamera(targetFOV)
	self.ZoomTrove:Clean()
	self.Zooming = true

	local aimSpeed = if self.WeaponInfo.HANDLING >= 95 then 0.1 else (100 - self.WeaponInfo.HANDLING) / 100

	local tween = TS:Create(
		workspace.CurrentCamera,
		TweenInfo.new(aimSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ FieldOfView = targetFOV }
	)

	self.ZoomTween = tween
	self.ZoomTrove:Add(tween)

	self.ZoomTrove:Connect(tween.Completed, function()
		if self.ZoomTween == tween then
			self.Zooming = false
			self.ZoomTween = nil
		end
	end)

	tween:Play()
end

function ViewModelAnimation:StartAim()
	self.Aiming = true
	self:ZoomCamera(55)
end

function ViewModelAnimation:StopAim()
	self.Aiming = false
	self:ZoomCamera(80)
end

function ViewModelAnimation:StartSprint()
	self:ZoomCamera(90)
end

function ViewModelAnimation:StopSprint()
	self:ZoomCamera(80)
end

return ViewModelAnimation
