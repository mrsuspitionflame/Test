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

function ViewModelController.new(LoadoutSlot: Tool)
	local self = setmetatable({
		Gun = LoadoutSlot,
		GunType = LoadoutSlot:GetAttribute("GunType"),
		ViewModelName = LoadoutSlot:GetAttribute("GunName"),
		BindingName = "Update" .. LoadoutSlot.Name .. "ViewModel",
		Handling = LoadoutSlot:GetAttribute("Handling"),
		Stability = LoadoutSlot:GetAttribute("Stability"),

		Aiming = false,
		Zooming = false,
		ZoomTween = nil,
		SwayCF = CFrame.new(),
		AimCF = CFrame.new(),
		LastCameraCF = workspace.CurrentCamera.CFrame,

		Trove = Trove.new(),

		RecoilAngle = 0,
		RecoilVelocity = 0,
		PreviousRecoilAngle = 0,
	}, ViewModelController)

	self.Stiffness = RecoilSettings[self.GunType].Stiffness
	self.Damping = RecoilSettings[self.GunType].Damping
	self.RecoilAmount = RecoilSettings.GetRecoilAmount(self.GunType, self.Stability)

	self:Init()
	return self
end

function ViewModelController:Recoil()
	self.RecoilVelocity += self.RecoilAmount
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

function ViewModelController:ZoomCamera(targetFOV)
	if self.ZoomTween then
		self.ZoomTween:Cancel()
	end

	self.Zooming = true
	local aimSpeed
	if self.Handling >= 95 then
		aimSpeed = 0.1
	else
		aimSpeed = (100 - self.Handling) / 100
	end

	local tweenInfo = TweenInfo.new(aimSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local zoomGoal = {
		FieldOfView = targetFOV,
	}

	local Camera = workspace.CurrentCamera
	self.ZoomTween = TS:Create(Camera, tweenInfo, zoomGoal)

	self.ZoomTween:Play()

	self.ZoomTween.Completed:Connect(function()
		self.Zooming = false
	end)
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
	self.ViewModel = self.Trove:Add(ClientViewModels:WaitForChild(self.ViewModelName):Clone())
	self.ViewModel.Name = self.ViewModelName
	local Camera = workspace.CurrentCamera
	self.ViewModel.Parent = Camera
	self.AimPart = self.ViewModel:FindFirstChild("AimPart", true)
end

function ViewModelController:Init()
	self:CreateViewModel()
	--local previousCameraMode = Player.CameraMode
	Player.CameraMode = Enum.CameraMode.LockFirstPerson

	self.Trove:Add(function()
		--Player.CameraMode = previousCameraMode
		Player.CameraMode = Enum.CameraMode.Classic
		Player.CameraMinZoomDistance = 15
		Player.CameraMaxZoomDistance = 15
		task.spawn(function()
			task.wait(0.1)
			Player.CameraMinZoomDistance = 0
		end)
	end)
	self.Trove:BindToRenderStep(self.BindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		self:UpdateViewModelAndSway(deltaTime)
		self:UpdateRecoil(deltaTime)
	end)
end

function ViewModelController:Destroy()
	self.Trove:Destroy()
end

return ViewModelController
