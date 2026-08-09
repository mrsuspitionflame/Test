local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Definitions = Shared:WaitForChild("Definitions")

local Trove = require(Packages:WaitForChild("Trove"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))

local PacketManager = require(Definitions:WaitForChild("PacketManager"))

local seedGenerator = Random.new()

local GunController = {}

GunController.__index = GunController

function GunController.new(Gun: Tool, AnimationController, ActionManager, GUIController)
	local self = setmetatable({
		AnimationController = AnimationController,
		ViewModelController = AnimationController:GetController("ViewModel"),
		ActionManager = ActionManager,
		GUIController = GUIController,
		Gun = Gun,
		GunName = Gun:GetAttribute("GunName"),
		Ammo = Gun:GetAttribute("MagazineSize"),
		FireRate = Gun:GetAttribute("FireRate"),
		MagazineSize = Gun:GetAttribute("MagazineSize"),
		ReloadSpeed = Gun:GetAttribute("ReloadSpeed"),
		BulletsPerShot = Gun:GetAttribute("BulletsPerShot"),
		Spread = Gun:GetAttribute("Spread"),
		Range = Gun:GetAttribute("Range"),

		Equipped = false,
		LastTimeShot = workspace:GetServerTimeNow(),
	}, GunController)

	self.LifetimeConnections = Trove.new()
	self.EquippedConnections = Trove.new()

	self:Init()
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

	self.Ammo -= 1
	self.ActionManager:SetState("WeaponState", "Firing")
	self.LastTimeShot = workspace:GetServerTimeNow()

	self.ViewModelController:Recoil()

	self.RecoilTrack:Play(0)

	local seed = seedGenerator:NextInteger(0, 2 ^ 31 - 1)

	local rayDirections =
		RaycastController.GetRayDirections(origin, self.BulletsPerShot, self.Spread, seed, self.Range * 10)

	local ignoreList = {
		workspace.CurrentCamera,
		game.Players.LocalPlayer.Character,
	}

	local rayResults = RaycastController.CastRays(origin.Position, rayDirections, ignoreList, 0)
	local rayOrigin = self.ViewModelController:GetRayOrigin()
	RaycastController.DrawRayResults(rayOrigin, rayResults)

	PacketManager.Combat.ShootRequest.send({
		Gun = self.Gun,
		CFrame = Camera.CFrame,
		Seed = seed,
	})
	--other stuff like animations, recoil, etc
end

function GunController:CanShoot()
	local now = workspace:GetServerTimeNow()
	local delayBetweenShots = 60 / self.FireRate

	return self.Equipped and self.ActionManager:TryAction("Weapon", "Fire") and self.Ammo > 0 and now - self.LastTimeShot >= delayBetweenShots
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
		Gun = self.Gun,
	})
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped and self.ActionManager:TryAction("Weapon", "Reload") and self.Ammo < self.MagazineSize
end

function GunController:SetAmmo(ammo: number)
	self.Ammo = ammo
end

function GunController:OnEquip()
	UIS.MouseIconEnabled = false
	PacketManager.Combat.EquipRequest.send({
		Gun = self.Gun,
		Action = "Equip",
	})
	self.Equipped = true
	self.AnimationController:OnEquip(self.Gun)
	self.ReloadTrack = self.EquippedConnections:Add(self.AnimationController:GetAnimation("ViewModel", "Reload"))
	self.RecoilTrack = self.EquippedConnections:Add(self.AnimationController:GetAnimation("ViewModel", "Recoil"))
	self.EquipTrack = self.EquippedConnections:Add(self.AnimationController:GetAnimation("ViewModel", "Equip"))

	self.ActionManager:SetState("WeaponState", "Equipping")
	self.EquipTrack:Play(0)

	self:EquippedInit()
end

function GunController:OnUnequip()
	UIS.MouseIconEnabled = true
	PacketManager.Combat.EquipRequest.send({
		Gun = self.Gun,
		Action = "UnEquip",
	})
	self.Equipped = false
	self.EquippedConnections:Clean()
	self.AnimationController:OnUnequip()

	--other stuff like animations, etc
end

function GunController:Destroy()
	self.LifetimeConnections:Destroy()
	self.EquippedConnections:Destroy()
end

function GunController:bindAction(trove, actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function GunController:Init()
	-- Lifetime Connections
	self.LifetimeConnections:Connect(self.Gun.Equipped, function()
		self:OnEquip()
	end)

	self.LifetimeConnections:Connect(self.Gun.Unequipped, function()
		self:OnUnequip()
	end)
end

function GunController:EquippedInit()
	-- Equipped Connections
	self.EquippedConnections:Connect(self.RecoilTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.EquippedConnections:Connect(self.ReloadTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.EquippedConnections:Connect(self.EquipTrack.Stopped, function()
		print("Equip animation finished")
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.EquippedConnections:Connect(self.Gun.Activated, function()
		self:ShootEvent()
	end)

	self:bindAction(self.EquippedConnections, "ReloadEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:ReloadEvent()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	self:bindAction(self.EquippedConnections, "AimEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.ViewModelController:OnAim("Start")
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.ViewModelController:AfterAim()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)
end

return GunController
