local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Definitions = Shared:WaitForChild("Definitions")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))
local RunService = game:GetService("RunService")

local Trove = require(Packages:WaitForChild("Trove"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))

local PacketManager = require(Definitions:WaitForChild("PacketManager"))

local seedGenerator = Random.new()

local GunController = {}

GunController.__index = GunController

function GunController.new(GunName, SlotName, AnimationController, ActionManager, GUIController)
	local GunInfo = GunDefinitions[GunName]

	local self = setmetatable({
		AnimationController = AnimationController,
		ViewModelController = AnimationController:GetController("ViewModel"),
		ActionManager = ActionManager,
		GUIController = GUIController,

		GunName = GunName,
		SlotName = SlotName,

		Ammo = GunInfo.MagazineSize,
		FireRate = GunInfo.FireRate,
		MagazineSize = GunInfo.MagazineSize,
		ReserveAmmo = GunInfo.ReserveAmmo,
		ReloadSpeed = GunInfo.ReloadSpeed,
		BulletsPerShot = GunInfo.BulletsPerShot,
		Spread = GunInfo.Spread,
		Range = GunInfo.Range,
		FireMode = GunInfo.FireMode,

		Equipped = false,
		TriggerHeld = false,
		LastTimeShot = workspace:GetServerTimeNow(),
	}, GunController)

	self.Trove = Trove.new()
	return self
end

function GunController:ShootEvent()
	if not self:CanShoot() then
		return
	end

	local Camera = workspace.CurrentCamera
	local origin = Camera.CFrame

	if self.ActionManager:GetState("WeaponState") == "Reloading" then
		self.ReloadTrack:Stop(0)
	end

	self.ActionManager:SetState("WeaponState", "Firing")
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

	PacketManager.Combat.ShootRequest.send({
		SlotName = self.SlotName,
		CFrame = Camera.CFrame,
		Seed = seed,
	})
	--other stuff like animations, recoil, etc
end

function GunController:CanShoot()
	local now = workspace:GetServerTimeNow()
	local delayBetweenShots = 60 / self.FireRate

	return self.Equipped
		and self.ActionManager:TryAction("Weapon", "Fire")
		and self.Ammo > 0
		and now - self.LastTimeShot >= delayBetweenShots
end

function GunController:ReloadEvent()
	--Perform checks to see if the gun can reload
	if not self:CanReload() then
		return
	end

	self.ActionManager:SetState("WeaponState", "Reloading")

	self.ReloadTrack:Play(0)
	self.ReloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)

	PacketManager.Combat.ReloadRequest.send({
		SlotName = self.SlotName,
	})
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped
		and self.ActionManager:TryAction("Weapon", "Reload")
		and self.Ammo < self.MagazineSize
		and self.ReserveAmmo > 0
end

function GunController:SetAmmo(ammo, reserveAmmo)
	self.Ammo = ammo

	if reserveAmmo ~= nil then
		self.ReserveAmmo = reserveAmmo
	end

	self.GUIController:UpdateAmmo(self.SlotName, self.Ammo, self.ReserveAmmo)
end

function GunController:EquipOrUnequip()
	if self.Equipped then
		PacketManager.Combat.EquipRequest.send({
			SlotName = self.SlotName,
			Action = "UnEquip",
		})
	else
		PacketManager.Combat.EquipRequest.send({
			SlotName = self.SlotName,
			Action = "Equip",
		})
	end

	return
end

function GunController:OnEquip()
	self:Init()
	UIS.MouseIconEnabled = false
	self.GUIController:EquippedSlotChanged(self.SlotName)
	self.Equipped = true
	self.AnimationController:OnEquip(self.GunName)
	self.ReloadTrack = self.Trove:Add(self.AnimationController:GetAnimation("ViewModel", "Reload"))
	self.RecoilTrack = self.Trove:Add(self.AnimationController:GetAnimation("ViewModel", "Recoil"))
	self.EquipTrack = self.Trove:Add(self.AnimationController:GetAnimation("ViewModel", "Equip"))

	self.ActionManager:SetState("WeaponState", "Equipping")
	self.EquipTrack:Play(0)

	self:Init()
end

function GunController:OnUnequip()
	UIS.MouseIconEnabled = true
	self.GUIController:UnequipWeapon()
	self.Equipped = false
	self.Trove:Clean()
	self.AnimationController:OnUnequip()

	--other stuff like animations, etc
end

function GunController:Destroy()
	self.AnimationController:OnUnequip()
	self.GUIController:UnequipWeapon()
	self.Trove:Destroy()
end

function GunController:bindAction(trove, actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end


function GunController:Init()
	-- Equipped Connections
	self.Trove:Connect(self.RecoilTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.Trove:Connect(self.ReloadTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.Trove:Connect(self.EquipTrack.Stopped, function()
		print("Equip animation finished")
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.Trove:Connect(RunService.Heartbeat, function()
		if not self.TriggerHeld then
			return
		end
		self:ShootEvent()
	end)

	self.Trove:Add(function()
		self.TriggerHeld = false
	end)

	self:bindAction(self.Trove, "GunActivatedOrDeactivated", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			if self.FireMode == "Semi" then
				self:ShootEvent()
				return
			end

			if self.TriggerHeld then
				return
			end

			self.TriggerHeld = true
			self:ShootEvent()
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.TriggerHeld = false
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton1)

	self:bindAction(self.Trove, "ReloadEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:ReloadEvent()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	self:bindAction(self.Trove, "AimEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.ViewModelController:OnAim("Start")
			PacketManager.Combat.AimEvent.send({
				SlotName = self.SlotName,
				Aiming = true,
			})
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.ViewModelController:AfterAim()
			PacketManager.Combat.AimEvent.send({
				SlotName = self.SlotName,
				Aiming = false,
			})
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)
end

return GunController
