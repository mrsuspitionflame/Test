local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")
local gunSettings = require(Settings:WaitForChild("GunSettings"))
local RunService = game:GetService("RunService")

local Trove = require(Packages:WaitForChild("Trove"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local seedGenerator = Random.new()

local GunController = {}

GunController.__index = GunController

function GunController.new(gunName, slotName, animationController, stateManager, guiController)
	local gunInfo = gunSettings[gunName]

	local self = setmetatable({
		AnimationController = animationController,
		ViewModelController = animationController:GetController("ViewModel"),
		StateManager = stateManager,
		GUIController = guiController,

		GunName = gunName,
		SlotName = slotName,

		Ammo = gunInfo.MAGAZINE_SIZE,
		FireRate = gunInfo.FIRE_RATE,
		MagazineSize = gunInfo.MAGAZINE_SIZE,
		ReserveAmmo = gunInfo.RESERVE_AMMO,
		ReloadSpeed = gunInfo.RELOAD_SPEED,
		BulletsPerShot = gunInfo.BULLETS_PER_SHOT,
		Spread = gunInfo.SPREAD,
		Range = gunInfo.RANGE,
		FireMode = gunInfo.FIRE_MODE,

		Aiming = false,
		Equipped = false,
		TriggerHeld = false,
	}, GunController)

	self.Trove = Trove.new()
	return self
end

-- Shooting logic

function GunController:ShootEvent()
	if not self:CanShoot() then
		return
	end

	local camera = workspace.CurrentCamera
	local origin = camera.CFrame

	self.StateManager:PerformAction("Weapon", "Fire")
	self.StateManager:SetState("WeaponState", "FIRING")
	self.LastTimeShot = workspace:GetServerTimeNow()

	self.ViewModelController:Recoil()

	self.RecoilTrack:Play(0)

	local seed = seedGenerator:NextInteger(0, 2 ^ 31 - 1)

	local rayDirections

	if self.Aiming then
		rayDirections = RaycastController.GetRayDirections(origin, self.BulletsPerShot, 0, seed, self.Range * 10)
	else
		rayDirections = RaycastController.GetRayDirections(
			origin,
			self.BulletsPerShot,
			math.rad(self.Spread),
			seed,
			self.Range * 10
		)
	end

	local ignoreList = {
		workspace.CurrentCamera,
		game.Players.LocalPlayer.Character,
	}

	local rayResults = RaycastController.CastRays(origin.Position, rayDirections, ignoreList, 0)
	local rayOrigin = self.ViewModelController:GetRayOrigin()
	RaycastController.DrawRayResults(rayOrigin, rayResults)

	PacketSettings.Combat.ShootRequest.send({
		SlotName = self.SlotName,
		CFrame = camera.CFrame,
		Seed = seed,
	})
	--other stuff like animations, recoil, etc
end

function GunController:CanShoot()
	local now = workspace:GetServerTimeNow()
	local delayBetweenShots = 60 / self.FireRate

	return self.Equipped
		and self.StateManager:TryAction("Weapon", "Fire")
		and self.Ammo > 0
		and now - self.LastTimeShot >= delayBetweenShots
end

-- Reloading logic

function GunController:ReloadEvent()
	--Perform checks to see if the gun can reload
	if not self:CanReload() then
		return
	end

	self.StateManager:SetState("WeaponState", "RELOADING")

	self.ReloadTrack:Play(0)
	self.ReloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)

	PacketSettings.Combat.ReloadRequest.send({
		SlotName = self.SlotName,
	})
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped
		and self.StateManager:TryAction("Weapon", "Reload")
		and self.Ammo < self.MagazineSize
		and self.ReserveAmmo > 0
end

function GunController:CancelReload()
	print("Reload canceled for gun:", self.GunName, "slot:", self.SlotName)
	self.ReloadTrack:Stop(0)
end

-- Ammo management logic

function GunController:SetAmmo(ammo, reserveAmmo)
	self.Ammo = ammo

	if reserveAmmo ~= nil then
		self.ReserveAmmo = reserveAmmo
	end

	self.GUIController:UpdateAmmo(self.SlotName, self.Ammo, self.ReserveAmmo)
end

-- Equip/Unequip logic

function GunController:EquipOrUnequip()
	if self.Equipped then
		print(self.SlotName)
		PacketSettings.Combat.EquipRequest.send({
			SlotName = self.SlotName,
			Action = "UnEquip",
		})
	else
		PacketSettings.Combat.EquipRequest.send({
			SlotName = self.SlotName,
			Action = "Equip",
		})
	end

	return
end

function GunController:OnEquip()
	UIS.MouseIconEnabled = false
	print("Mouse icon set to: " .. tostring(UIS.MouseIconEnabled))
	self.GUIController:EquippedSlotChanged(self.SlotName)
	self.Equipped = true
	self.AnimationController:OnEquip(self.GunName)
	self.ReloadTrack = self.Trove:Add(self.AnimationController:GetAnimation("ViewModel", "Reload"))
	self.RecoilTrack = self.Trove:Add(self.AnimationController:GetAnimation("ViewModel", "Recoil"))
	self.EquipTrack = self.Trove:Add(self.AnimationController:GetAnimation("ViewModel", "Equip"))

	self.StateManager:SetState("WeaponState", "EQUIPPING")
	self.EquipTrack:Play(0)

	self.LastTimeShot = workspace:GetServerTimeNow()

	self:Init()
end

function GunController:OnUnequip()
	UIS.MouseIconEnabled = true

	self.Equipped = false
	self.Aiming = false
	self.TriggerHeld = false

	self.ViewModelController:OnUnequip()
	self.GUIController:OnUnequip()
	self.AnimationController:OnUnequip()
	--self.StateManager:SetState("WeaponState", "IDLE")
	self.Trove:Clean()
end

-- Aiming logic

function GunController:StartAiming()
	if not self.StateManager:TryAction("Weapon", "Aim") then
		return
	end
	self.StateManager:PerformAction("Weapon", "Aim")
	self.StateManager:SetState("AimState", "AIMING")
	self.Aiming = true
	self.ViewModelController:OnAim("Start")
	PacketSettings.Combat.AimEvent.send({
		SlotName = self.SlotName,
		Aiming = true,
	})
end

function GunController:CancelAiming()
	self.Aiming = false
	self.ViewModelController:AfterAim()
	PacketSettings.Combat.AimEvent.send({
		SlotName = self.SlotName,
		Aiming = false,
	})
end

-- Utility function

function GunController:BindAction(actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	self.Trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function GunController:Init()
	-- Equipped Connections
	self.Trove:Connect(self.RecoilTrack.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.ReloadTrack.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.EquipTrack.Stopped, function()
		print("Equip animation finished")
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	-- Input Connections
	self.Trove:Connect(RunService.Heartbeat, function()
		if not self.TriggerHeld then
			return
		end
		self:ShootEvent()
	end)

	self.Trove:Add(function()
		self.TriggerHeld = false
	end)

	self:BindAction("GunActivatedOrDeactivated", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			if self.FireMode == "Semi" then
				self:ShootEvent()
				return
			end

			if self.TriggerHeld then
				return
			end

			self.TriggerHeld = true
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.TriggerHeld = false
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton1)

	self:BindAction("ReloadEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:ReloadEvent()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	self:BindAction("AimEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:StartAiming()
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self:CancelAiming()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)

	-- State Change Connections
	self.Trove:Add(self.StateManager.CancelStateSignal:Connect(function(stateType, cancelledState)
		if stateType == "WeaponState" then
			if cancelledState == "RELOADING" then
				self:CancelReload()
			end
		elseif stateType == "AimState" then
			if cancelledState == "AIMING" then
				self:CancelAiming()
			end
		end
	end))
end

return GunController
