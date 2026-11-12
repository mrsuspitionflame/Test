local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local TS = game:GetService("TweenService")

local CameraController = {}

CameraController.__index = CameraController

function CameraController.new(CombatController)
	local self = setmetatable({}, CameraController)
	self.CombatController = CombatController

	self.WeaponTrove = CombatController.WeaponTrove
	self.AbilityTrove = CombatController.AbilityTrove
	return self
end

-- Weapon camera setup

function CameraController:OnEquip(WeaponInfo)
	self.WeaponInfo = WeaponInfo

	self.Zooming = false

	self.ZoomTween = nil

	self.RecoilAngle = 0
	self.RecoilVelocity = 0
	self.PreviousRecoilAngle = 0

	self.RecoilBindingName = "Update" .. self.WeaponInfo.WEAPON_NAME .. "CameraRecoil"
	self.WeaponTrove:BindToRenderStep(self.RecoilBindingName, Enum.RenderPriority.Camera.Value + 2, function(deltaTime)
		self:UpdateRecoil(deltaTime)
	end)
	self.ZoomTrove = self.WeaponTrove:Extend()

	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	self.WeaponTrove:Add(function()
		Player.CameraMode = Enum.CameraMode.Classic
	end)
	self.WeaponTrove:Add(function()
		workspace.CurrentCamera.FieldOfView = 80
	end)
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

return CameraController
