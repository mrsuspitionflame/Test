local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Client = StarterPlayerScripts:WaitForChild("Client")
local Controllers = Client:WaitForChild("Controllers")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")

local Trove = require(Packages:WaitForChild("Trove"))
local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))

local PacketManager = require(Utility:WaitForChild("PacketManager"))

local seedGenerator = Random.new()

local GunController = {}

GunController.__index = GunController

function GunController.new(LoadoutSlot)
	local self = setmetatable({
		Gun = LoadoutSlot,

		GunName = LoadoutSlot:GetAttribute("GunName"),
		Ammo = LoadoutSlot:GetAttribute("MagazineSize"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		MagazineSize = LoadoutSlot:GetAttribute("MagazineSize"),
		ReloadSpeed = LoadoutSlot:GetAttribute("ReloadSpeed"),
		BulletsPerShot = LoadoutSlot:GetAttribute("BulletsPerShot"),
		Spread = LoadoutSlot:GetAttribute("Spread"),
		Range = LoadoutSlot:GetAttribute("Range"),

		IsReloading = false,
		Equipped = false,
		IsFiring = false,
		CanAim = true,
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

	if self.IsReloading then
		self.IsReloading = false
		self.ReloadTrack:Stop(0)
	end

	self.Ammo -= 1
	self.IsFiring = true
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
	local muzzlePosition = self.ViewModelController:GetMuzzlePosition()
	RaycastController.DrawRayResults(muzzlePosition, rayResults)

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

	return self.Equipped and not self.IsFiring and self.Ammo > 0 and now - self.LastTimeShot >= delayBetweenShots
end

function GunController:ReloadEvent()
	--Perform checks to see if the gun can reload
	if not self:CanReload() then
		return
	end

	self.IsReloading = true

	self.ReloadTrack:Play(0)
	self.ReloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)

	PacketManager.Combat.ReloadRequest.send({
		Gun = self.Gun,
	})
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped and not self.IsFiring and self.Ammo < self.MagazineSize and not self.IsReloading
end

function GunController:OnEquip()
	UIS.MouseIconEnabled = false
	PacketManager.Combat.EquipRequest.send({
		Gun = self.Gun,
		Action = "Equip",
	})
	self.Equipped = true
	self.ViewModelController = self.EquippedConnections:Add(ViewModelController.new(self.Gun))
	self.ReloadTrack = self.EquippedConnections:Add(self.ViewModelController:GetReloadAnimation())
	self.RecoilTrack = self.EquippedConnections:Add(self.ViewModelController:GetRecoilAnimation())
	self:EquippedInit()
end

function GunController:OnUnequip()
	UIS.MouseIconEnabled = Enum.MouseBehavior.Default
	PacketManager.Combat.EquipRequest.send({
		Gun = self.Gun,
		Action = "UnEquip",
	})
	self.Equipped = false
	self.EquippedConnections:Clean()
	self.ViewModelController = nil
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
		self.IsFiring = false
	end)

	self.EquippedConnections:Connect(self.ReloadTrack.Stopped, function()
		self.IsReloading = false
	end)

	self.EquippedConnections:Connect(self.ReloadTrack:GetMarkerReachedSignal("ReloadComplete"), function()
		if self.IsReloading then
			self.Ammo = self.MagazineSize
		end
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
			if self.CanAim then
				self.ViewModelController:OnAim()
			end
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.ViewModelController:AfterAim()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)
end

return GunController
