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
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Trove = require(Packages:WaitForChild("Trove"))
local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")
local EquipGunRequest = Remotes:WaitForChild("EquipGunRequest")

local seedGenerator = Random.new()

local GunController = {}

GunController.__index = GunController

function GunController.new(LoadoutSlot)
	local self = setmetatable({
		Gun = LoadoutSlot,

		GunName = LoadoutSlot:GetAttribute("GunName"),
		Ammo = LoadoutSlot:GetAttribute("Ammo"),
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

	print("GunController created")
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
		self.ReloadTrack:Stop()
	end

	self.Ammo -= 1
	self.IsFiring = true
	self.LastTimeShot = workspace:GetServerTimeNow()

	local recoilTrack = self.ViewModelController:Recoil()
	self.FiringTrack = recoilTrack
	recoilTrack.Stopped:Connect(function()
		self.IsFiring = false
		if self.FiringTrack == recoilTrack then
			self.FiringTrack = nil
		end
		recoilTrack:Destroy()
	end)
	recoilTrack:Play()

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

	FireGunRequest:FireServer(self.Gun, Camera.CFrame, seed)
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

	local reloadTrack = self.ViewModelController:Reload()
	self.ReloadTrack = reloadTrack
	self.IsReloading = true

	reloadTrack:GetMarkerReachedSignal("ReloadComplete"):Once(function()
		if not self.IsReloading then
			return
		end

		self.Ammo = self.MagazineSize
	end)

	reloadTrack.Stopped:Once(function()
		self.IsReloading = false

		if self.ReloadTrack == reloadTrack then
			self.ReloadTrack = nil
		end

		reloadTrack:Destroy()
	end)

	reloadTrack:Play()
	reloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)

	ReloadGunRequest:FireServer(self.Gun)
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped and not self.IsFiring and self.Ammo < self.MagazineSize and not self.IsReloading
end

function GunController:OnEquip()
	UIS.MouseIconEnabled = false
	EquipGunRequest:FireServer(self.Gun, "Equip")
	self.Equipped = true
	self.ViewModelController = self.EquippedConnections:Add(ViewModelController.new(self.Gun))
	self:EquippedInit()
	--other stuff like animations, etc
end

function GunController:OnUnequip()
	UIS.MouseIconEnabled = Enum.MouseBehavior.Default
	EquipGunRequest:FireServer(self.Gun, "UnEquip")
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
	self.EquippedConnections:Connect(self.Gun.Activated, function()
		self:ShootEvent()
	end)

	self:bindAction(self.EquippedConnections, "ReloadEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:ReloadEvent()
			print("Reload event triggered")
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	self:bindAction(self.EquippedConnections, "AimEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			if self.CanAim then
				print("Pre Aim event triggered")
				self.ViewModelController:OnAim()
			end
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			print("Post Aim event triggered")
			self.ViewModelController:AfterAim()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)
end

return GunController
