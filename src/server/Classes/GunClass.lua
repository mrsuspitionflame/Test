local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Classes = Server:WaitForChild("Classes")
local Players = game:GetService("Players")

local ViewModelClass = require(Classes:WaitForChild("ViewModelClass"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))
local ReplicateShotEvent = Remotes:WaitForChild("ReplicateShotEvent")

local GunClass = {}
GunClass.__index = GunClass

function GunClass.new(player, LoadoutSlot)
	local self = {
		Player = player,
		Gun = LoadoutSlot,
		SlotName = LoadoutSlot.Name,

		Damage = LoadoutSlot:GetAttribute("Damage"),
		MagazineSize = LoadoutSlot:GetAttribute("MagazineSize"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		Ammo = LoadoutSlot:GetAttribute("Ammo"),
		Handling = LoadoutSlot:GetAttribute("Handling"),
		Stability = LoadoutSlot:GetAttribute("Stability"),
		ReloadSpeed = LoadoutSlot:GetAttribute("ReloadSpeed"),
		BulletsPerShot = LoadoutSlot:GetAttribute("BulletsPerShot"),
		Spread = LoadoutSlot:GetAttribute("Spread"),
		Range = LoadoutSlot:GetAttribute("Range"),

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

	return self.Equipped
		and not self.IsFiring
		and humanoid ~= nil
		and humanoid.Health > 0
		and self.Gun.Parent == character
		and not self.IsReloading
		and self.Ammo < self.MagazineSize
end

function GunClass:Reload()
	if not self:CanReload() then
		return
	end

	local reloadTrack = self.ViewModelClass:Reload()
	self.ReloadTrack = reloadTrack
	self.IsReloading = true

	reloadTrack:GetMarkerReachedSignal("ReloadComplete"):Once(function()
		if not self.IsReloading then
			return
		end

		self.Ammo = self.MagazineSize
		print("Ammo after reload: " .. self.Ammo)
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
end

function GunClass:CanShoot(origin, seed)
	if
		not RaycastController.ValidateVector3(origin.Position)
		or not RaycastController.ValidateVector3(origin.LookVector)
	then
		return false
	end

	if typeof(seed) ~= "number" or seed % 1 ~= 0 or seed < 0 or seed > 2 ^ 31 - 1 then
		return false
	end

	local character = self.Player.Character

	local head = character:FindFirstChild("Head")
	if not head then
		return false
	end

	if (origin.Position - head.Position).Magnitude > 15 then
		return false
	end

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

function GunClass:Shoot(origin, seed)
	if not self:CanShoot(origin, seed) then
		return
	end

	if self.IsReloading then
		self.IsReloading = false
		self.ReloadTrack:Stop()
	end

	self.Ammo -= 1
	self.IsFiring = true
	self.lastShotTime = workspace:GetServerTimeNow()

	local recoilTrack = self.ViewModelClass:Recoil()
	self.FiringTrack = recoilTrack
	recoilTrack.Stopped:Connect(function()
		self.IsFiring = false
		if self.FiringTrack == recoilTrack then
			self.FiringTrack = nil
		end
		recoilTrack:Destroy()
	end)
	recoilTrack:Play()

	local rayDirections =
		RaycastController.GetRayDirections(origin, self.BulletsPerShot, self.Spread, seed, self.Range * 10)

	local ignoreList = {
		self.Player.Character,
	}

	local rayResults = RaycastController.CastRays(origin.Position, rayDirections, ignoreList, 0)

	for _, rayResult in rayResults do
		local hitInstance = rayResult.Instance

		if not hitInstance then
			continue
		end

		local character = hitInstance:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		humanoid:TakeDamage(self.Damage)
	end

	local rayOrigin = self.ViewModelClass:GetRayOrigin()
	local muzzle = rayOrigin and rayOrigin:FindFirstChild("MuzzleAttachment", true)

	local muzzlePosition = origin.Position

	if muzzle and muzzle:IsA("Attachment") then
		muzzlePosition = muzzle.WorldPosition
	elseif rayOrigin and rayOrigin:IsA("BasePart") then
		muzzlePosition = rayOrigin.Position
	end

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer == self.Player then
			continue
		end

		ReplicateShotEvent:FireClient(otherPlayer, muzzlePosition, rayResults)
	end
end

function GunClass:Destroy()
	self.LifetimeConnections:Destroy()
	if self.EquippedConnections then
		self.EquippedConnections:Destroy()
	end
end

return GunClass
