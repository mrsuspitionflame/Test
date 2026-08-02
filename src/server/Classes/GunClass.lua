local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Classes = Server:WaitForChild("Classes")

local ViewModelClass = require(Classes:WaitForChild("ViewModelClass"))
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))

local GunClass = {}
GunClass.__index = GunClass

function GunClass.new(player, LoadoutSlot)
	--self contains stats that don't change
	local self = {
		Player = player,
		Gun = LoadoutSlot,
		SlotName = LoadoutSlot.Name,

		MagazineSize = LoadoutSlot:GetAttribute("MagazineSize"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		Ammo = LoadoutSlot:GetAttribute("Ammo"),
		Handling = LoadoutSlot:GetAttribute("Handling"),
		Stability = LoadoutSlot:GetAttribute("Stability"),

		IsReloading = false,
		IsFiring = false,
		Equipped = false,
		Aiming = false,
		lastShotTime = workspace:GetServerTimeNow(),
	}

	self.LifetimeConnections = Trove.new()
	self.EquippedConnections = Trove.new()

	setmetatable(self, GunClass)
	return self
end

function GunClass:OnEquip()
	if self.Equipped then
		return
	end
	self.Equipped = true
	self.ViewModelClass = self.EquippedConnections:Add(ViewModelClass.new(self.Gun, self.Player))
	-- Additional logic for equipping the gun can be added here
end

function GunClass:OnUnequip()
	print("Unequipping gun for player:", self.Player.Name)
	if not self.Equipped then
		return
	end
	self.Equipped = false
	self.EquippedConnections:Destroy()
	self.ViewModelClass = nil
	-- Additional logic for unequipping the gun can be added here
end

function GunClass:CanReload()
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not self.Equipped then
		return false
	end

	if self.IsFiring then
		return false
	end

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if self.Gun.Parent ~= character then
		return false
	end

	if self.IsReloading then
		return false
	end

	if self.Ammo >= self.MagazineSize then
		return false
	end

	return true
end

function GunClass:Reload()
	if not self:CanReload() then
		return
	end
	self.IsReloading = true
	self.ReloadTrack = self.ViewModelClass:Reload()
	self.ReloadTrack.Stopped:Connect(function()
		if not self.IsFiring then
			self.Ammo = self.MagazineSize
		end
		self.IsReloading = false
		self.ReloadTrack:Destroy()
		print("Ammo after reload: " .. self.Ammo)
	end)
end

function GunClass:CanShoot()
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if self.Ammo <= 0 then
		return false
	end

	local now = workspace:GetServerTimeNow()
	local delayBetweenShots = 60 / self.FireRate

	if now - self.lastShotTime <= delayBetweenShots then
		return false
	end

	return true
end

function GunClass:Shoot(aimDirection)
	if typeof(aimDirection) ~= "Vector3" or aimDirection.Magnitude < 0.99 or aimDirection.Magnitude > 1.01 then
		return
	end

	if not self:CanShoot() then
		return
	end

	if self.IsReloading then
		self.ReloadTrack:Stop()
	end

	self.Ammo -= 1
	self.IsFiring = true
	self.Gun:SetAttribute("Ammo", self.Ammo)
	self.lastShotTime = workspace:GetServerTimeNow()
	self.FiringTrack = self.ViewModelClass:Recoil()
	self.FiringTrack.Stopped:Connect(function()
		self.IsFiring = false
		self.FiringTrack:Destroy()
	end)
	-- Perform the authoritative server raycast here.
end

function GunClass:Destroy()
	self.LifetimeConnections:Destroy()
	if self.EquippedConnections then
		self.EquippedConnections:Destroy()
	end
end

return GunClass
