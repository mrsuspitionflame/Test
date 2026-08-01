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
		Firing = false,
		LastTimeShot = workspace:GetServerTimeNow(),
	}, GunController)

	self.LifetimeConnections = Trove.new()
	self.EquippedConnections = Trove.new()

	print("GunController created")
	self:Init()
	return self
end

function GunController:ShootEvent()
	--Perform checks to see if the gun can shoot, like ammo, fire rate, etc
	if not self:CanShoot() then
		return
	end
	--updateUI

	local Camera = workspace.CurrentCamera

	FireGunRequest:FireServer(self.Gun, Camera.CFrame.LookVector)
	--other stuff like animations, recoil, etc
end

function GunController:CanShoot()
	local now = workspace:GetServerTimeNow()
    local delayBetweenShots = 60 / self.FireRate

	return self.Equipped
		and not self.IsReloading
		and not self.Firing
		and self.Ammo > 0
		and now - self.LastTimeShot >= delayBetweenShots
end

function GunController:ReloadEvent()
	--Perform checks to see if the gun can reload
	if not self:CanReload() then
		return
	end
	ReloadGunRequest:FireServer(self.Gun)
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped
		and not self.Gun:GetAttribute("isReloading")
		and not self.Firing
		and self.Gun:GetAttribute("Ammo") < self.MagazineSize
end

function GunController:OnEquip()
	self.Equipped = true
	self.ViewModelController = self.EquippedConnections:Add(ViewModelController.new(self.Gun))
	self:EquippedInit()
	--other stuff like animations, etc
end

function GunController:OnUnequip()
	self.Equipped = false
	self.EquippedConnections:Clean()
	self.ViewModelController = nil
	--other stuff like animations, etc
end

function GunController:Destroy()
	self.LifetimeConnections:Destroy()
	if self.EquippedConnections then
		self.EquippedConnections:Destroy()
	end
end

function GunController:bindAction(trove, actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function GunController:Init()
	-- Lifetime Connections

	self.LifetimeConnections:Connect(self.Gun.Activated, function()
		--self:ShootEvent()
		self.ViewModelController:Recoil()
	end)

	self.LifetimeConnections:Connect(self.Gun.Equipped, function()
		self:OnEquip()
	end)

	self.LifetimeConnections:Connect(self.Gun.Unequipped, function()
		self:OnUnequip()
	end)
end

function GunController:EquippedInit()
	-- Equipped Connections

	self:bindAction(self.EquippedConnections, "ReloadEvent", function(_, inputState)
		if inputState == Enum.UserInputState.End then
			--self:ReloadEvent()
			print("Reload event triggered")
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	self:bindAction(self.EquippedConnections, "AimEvent", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			print("Pre Aim event triggered")
			self.ViewModelController:OnAim()
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			print("Post Aim event triggered")
			self.ViewModelController:AfterAim()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)
end

return GunController
