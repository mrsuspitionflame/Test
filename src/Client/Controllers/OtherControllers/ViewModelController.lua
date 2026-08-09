local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local RecoilSettings = require(Definitions:WaitForChild("RecoilSettings"))
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local TS = game:GetService("TweenService")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local ViewModels = ReplicatedStorage:WaitForChild("ViewModels")
local ClientViewModels = ViewModels:WaitForChild("ClientViewModels")

local Trove = require(Packages:WaitForChild("Trove"))

local ViewModelController = {}
ViewModelController.__index = ViewModelController

function ViewModelController.new()
	local self = setmetatable({
		Trove = Trove.new(),
	}, ViewModelController)

	return self
end

function ViewModelController:OnEquip(Gun: Tool)
	self.Gun = Gun
	self.GunName = Gun:GetAttribute("GunName")
	self.GunType = Gun:GetAttribute("GunType")
	self.BindingName = "Update" .. Gun.Name .. "ViewModel"
	self.Handling = Gun:GetAttribute("Handling")
	self.Stability = Gun:GetAttribute("Stability")
	self.Aiming = false
	self.Zooming = false
	self.ZoomTween = nil
	self.SwayCF = CFrame.new()
	self.AimCF = CFrame.new()
	self.LastCameraCF = workspace.CurrentCamera.CFrame
	self.RecoilAngle = 0
	self.RecoilVelocity = 0
	self.PreviousRecoilAngle = 0
	self.ZoomTrove = self.Trove:Extend()
	self.Stiffness = RecoilSettings[self.GunType].Stiffness
	self.Damping = RecoilSettings[self.GunType].Damping
	self.RecoilAmount = RecoilSettings.GetRecoilAmount(self.GunType, self.Stability)

	self:Init()
end

function ViewModelController:OnUnequip()
	self.Trove:Clean()
end

function ViewModelController:GetRayOrigin()
	return self.RayOrigin.Position
end

function ViewModelController:Recoil()
	self.RecoilVelocity += self.RecoilAmount
	self.Muzzle.FlashEmitter:Emit(1)
	self.Muzzle.CircleEmitter:Emit(1)
	return
end

function ViewModelController:GetAnimation(AnimationName: string)
	if AnimationName == "Recoil" then
		return self.RecoilAnimation
	elseif AnimationName == "Reload" then
		return self.ReloadAnimation
	elseif AnimationName == "Equip" then
		print("Equip animation returned")
		return self.EquipAnimation
	end
	return nil
end
function ViewModelController:Reload()
	self.Aiming = false
	self:ZoomCamera(70)
	return
end

function ViewModelController:UpdateRecoil(deltaTime: number)
	local stiffness = self.Stiffness
	local damping = self.Damping

	deltaTime = math.min(deltaTime, 0.1)

	local oldAngle = self.RecoilAngle
	local remainingTime = deltaTime
	local maximumStep = 1 / 120

	while remainingTime > 0 do
		local step = math.min(remainingTime, maximumStep)

		local acceleration = -self.RecoilAngle * stiffness - self.RecoilVelocity * damping

		self.RecoilVelocity += acceleration * step
		self.RecoilAngle += self.RecoilVelocity * step

		remainingTime -= step
	end

	local angleChange = self.RecoilAngle - oldAngle

	workspace.CurrentCamera.CFrame *= CFrame.Angles(math.rad(angleChange), 0, 0)
end

function ViewModelController:SetArmsTransparency(transparency)
	local char = Player.Character or Player.CharacterAdded:Wait()
	local rightArm = char:WaitForChild("Right Arm")
	local leftArm = char:WaitForChild("Left Arm")

	rightArm.LocalTransparencyModifier = transparency
	leftArm.LocalTransparencyModifier = transparency
end

function ViewModelController:ZoomCamera(targetFOV)
	self.ZoomTrove:Clean()
	self.Zooming = true

	local aimSpeed = if self.Handling >= 95 then 0.1 else (100 - self.Handling) / 100

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

function ViewModelController:OnAim()
	self.Aiming = true
	self:ZoomCamera(55)
end

function ViewModelController:AfterAim()
	self.Aiming = false
	self:ZoomCamera(70)
end

function ViewModelController:UpdateViewModelAndSway(deltaTime: number)
	-- Prevent unusually large jumps after lag spikes
	deltaTime = math.min(deltaTime, 1 / 30)

	local camera = workspace.CurrentCamera
	local cameraCF = camera.CFrame

	local rotation = cameraCF:ToObjectSpace(self.LastCameraCF)
	local x, y = rotation:ToOrientation()

	local swayAmount
	if self.Handling >= 95 then
		swayAmount = 0.1
	else
		swayAmount = (100 - self.Handling) / 20
	end

	local targetSway = CFrame.Angles(math.sin(x) * swayAmount, math.sin(y) * swayAmount, 0)

	-- Speeds are measured approximately per second
	local swaySpeed = 12
	local handlingPercent = math.clamp(self.Handling / 100, 0, 1)
	local aimSpeed = 10 + handlingPercent * 15

	local swayAlpha = 1 - math.exp(-swaySpeed * deltaTime)

	local aimAlpha = 1 - math.exp(-aimSpeed * deltaTime)

	self.SwayCF = self.SwayCF:Lerp(targetSway, swayAlpha)

	self.LastCameraCF = cameraCF

	local targetAimCF = CFrame.new()

	if self.Aiming and self.AimPart then
		targetAimCF = self.AimPart.CFrame:ToObjectSpace(self.ViewModel:GetPivot())
	end

	self.AimCF = self.AimCF:Lerp(targetAimCF, aimAlpha)

	self.ViewModel:PivotTo(cameraCF * self.SwayCF * self.AimCF)
end

function ViewModelController:CreateViewModel()
	self.ViewModel = self.Trove:Add(ClientViewModels:WaitForChild(self.GunName):Clone())
	self.ViewModel.Name = self.GunName
	local Camera = workspace.CurrentCamera
	self.ViewModel.Parent = Camera

	local Humanoid = self.ViewModel:FindFirstChild("Humanoid")
	local Animator = Humanoid:WaitForChild("Animator")
	self.AimPart = self.ViewModel:FindFirstChild("AimPart")
	local Animations = self.ViewModel:FindFirstChild("Animations")
	self.RecoilAnimation =
		self.Trove:Add(Animator:LoadAnimation(Animations:FindFirstChild("RecoilAnimation" .. self.GunName)))
	self.ReloadAnimation =
		self.Trove:Add(Animator:LoadAnimation(Animations:FindFirstChild("ReloadAnimation" .. self.GunName)))
	self.EquipAnimation =
		self.Trove:Add(Animator:LoadAnimation(Animations:FindFirstChild("EquipAnimation" .. self.GunName)))
	self.RayOrigin = self.ViewModel:FindFirstChild("RayOrigin")
	self.Muzzle = self.RayOrigin:FindFirstChild("MuzzleAttachment")
end

function ViewModelController:HideServerViewModel()
	local char = Player.Character or Player.CharacterAdded:Wait()
	local ServerViewModel = char:WaitForChild(self.GunName .. "ServerViewModel")

	for _, part in ServerViewModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = 1
		end
	end
end

function ViewModelController:Init()
	self:CreateViewModel()
	Player.CameraMode = Enum.CameraMode.LockFirstPerson

	self.Trove:Add(function()
		Player.CameraMode = Enum.CameraMode.Classic
		Player.CameraMinZoomDistance = 15
		Player.CameraMaxZoomDistance = 15
		task.delay(0.1, function()
			Player.CameraMinZoomDistance = 0
		end)
	end)

	self.Trove:Add(task.spawn(function()
		task.wait(0.1)
		self:HideServerViewModel()
	end))

	self.Trove:BindToRenderStep(self.BindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		self:UpdateViewModelAndSway(deltaTime)
		self:UpdateRecoil(deltaTime)
	end)
end

return ViewModelController
