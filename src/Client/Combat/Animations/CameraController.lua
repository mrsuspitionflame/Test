local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local TS = game:GetService("TweenService")

local CameraController = {}

CameraController.__index = CameraController

function CameraController.new(AnimationController)
	local self = setmetatable({}, CameraController)
	self.AnimationController = AnimationController

	self.WeaponTrove = AnimationController.WeaponTrove
	self.AbilityTrove = AnimationController.AbilityTrove
	self.MovementTrove = AnimationController.MovementTrove
	return self
end

-- Weapon ViewModels functions

function CameraController:OnEquip(ViewModel, WeaponInfo)
	self.WeaponViewModel = ViewModel
	self.WeaponInfo = WeaponInfo

	local head = self.WeaponViewModel:WaitForChild("Head")
	if head:FindFirstChild("AimPartAttachment") then
		self.WeaponAimPart = head:FindFirstChild("AimPartAttachment")
	end

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

	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	self.WeaponTrove:Add(function()
		Player.CameraMode = Enum.CameraMode.Classic
	end)
	self.WeaponTrove:Add(function()
		workspace.CurrentCamera.FieldOfView = 80
	end)

	self.WeaponBindingName = "Update" .. self.WeaponInfo.WEAPON_NAME .. "WeaponViewModel"
	self.WeaponTrove:BindToRenderStep(self.WeaponBindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		self:UpdateWeaponViewModel(deltaTime)
		self:UpdateRecoil(deltaTime)
	end)
end

function CameraController:OnAbilityCast(ViewModel, AbilityViewModelTrove)
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

function CameraController:UpdateRecoil(deltaTime: number)
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

function CameraController:UpdateWeaponViewModel(deltaTime: number)
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

	if self.Aiming and self.WeaponAimPart then
		targetAimCF = self.WeaponAimPart.WorldCFrame:ToObjectSpace(self.WeaponViewModel:GetPivot())
	end

	self.AimCF = self.AimCF:Lerp(targetAimCF, aimAlpha)

	self.WeaponViewModel:PivotTo(cameraCF * self.SwayCF * self.AimCF)
end

function CameraController:UpdateAbilityViewModel(deltaTime: number)
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

function CameraController:Recoil()
	local RecoilAmount = math.max(0, self.WeaponInfo.BASE_RECOIL - self.WeaponInfo.STABILITY)
	self.RecoilVelocity += RecoilAmount
end

function CameraController:ZoomCamera(targetFOV)
	self.ZoomTrove:Clean()
	self.Zooming = true

	local AimSpeed = if self.WeaponInfo.HANDLING >= 95 then 0.1 else (100 - self.WeaponInfo.HANDLING) / 100

	local tween = TS:Create(
		workspace.CurrentCamera,
		TweenInfo.new(AimSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
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

-- Make aiming more customizable in the future, for now just zoom in and out

function CameraController:StartAim()
	self.Aiming = true
	self:ZoomCamera(55)
end

function CameraController:StopAim()
	self.Aiming = false
	self:ZoomCamera(80)
end

return CameraController
