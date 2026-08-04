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
local PacketManager = require(Utility:WaitForChild("PacketManager"))

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
	self.ReloadTrack = self.ViewModelClass:GetReloadAnimation()
	self.RecoilTrack = self.ViewModelClass:GetRecoilAnimation()
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
	-- Additional logic for equipping the gun can be added here
end

function GunClass:OnUnequip()
	print("Unequipping gun for player:", self.Player.Name)
	if not self.Equipped then
		return
	end
	self.Equipped = false
	self.EquippedConnections:Clean()
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

	self.IsReloading = true

	self.ReloadTrack:Play(0)
	self.ReloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)
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
		self.ReloadTrack:Stop(0)
	end

	self.Ammo -= 1
	self.IsFiring = true
	self.lastShotTime = workspace:GetServerTimeNow()

	self.RecoilTrack:Play(0)

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

	PacketManager.Combat.ReplicateShotEvent.sendToAllExcept({
		MuzzlePosition = muzzlePosition,
		RayResults = rayResults,
	}, self.Player)
end

function GunClass:Destroy()
	self.LifetimeConnections:Destroy()
	if self.EquippedConnections then
		self.EquippedConnections:Destroy()
	end
end

return GunClass
