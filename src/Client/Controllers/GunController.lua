local UIP = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Client = StarterPlayerScripts:WaitForChild("Client")
local Controllers = Client:WaitForChild("Controllers")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Trove = require(Packages:WaitForChild("Trove"))
local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")
local EquipGunRequest = Remotes:WaitForChild("EquipGunRequest")

local GunController = {}

GunController.__index = GunController

function GunController.new(LoadoutSlot)
	local self = setmetatable({
		Gun = LoadoutSlot,

		GunName = LoadoutSlot:GetAttribute("GunName"),
		Ammo = LoadoutSlot:GetAttribute("Ammo"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		MagazineSize = LoadoutSlot:GetAttribute("MagazineSize"),

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
	FireGunRequest:FireServer(self.Gun, Camera.CFrame.LookVector)

	if self.IsReloading then
		self.ReloadTrack:Stop()
	end

	self.Ammo -= 1
	self.IsFiring = true
	self.LastTimeShot = workspace:GetServerTimeNow()
	self.FiringTrack = self.ViewModelController:Recoil()
	self.FiringTrack.Stopped:Connect(function()
		self.IsFiring = false
		self.FiringTrack:Destroy()
	end)

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
	self.ReloadTrack = self.ViewModelController:Reload()
	self.CanAim = false
	self.ReloadTrack.Stopped:Connect(function()
		if not self.IsFiring then
			self.Ammo = self.MagazineSize
		end
		self.IsReloading = false
		self.CanAim = true
		self.ReloadTrack:Destroy()
		print("Ammo after reload: " .. self.Ammo)
	end)

	ReloadGunRequest:FireServer(self.Gun)
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped and not self.IsFiring and self.Ammo < self.MagazineSize and not self.IsReloading
end

function GunController:OnEquip()
	EquipGunRequest:FireServer(self.Gun, "Equip")
	self.Equipped = true
	self.ViewModelController = self.EquippedConnections:Add(ViewModelController.new(self.Gun))
	self:EquippedInit()
	--other stuff like animations, etc
end

function GunController:OnUnequip()
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
