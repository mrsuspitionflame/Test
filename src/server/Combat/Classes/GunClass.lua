local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Definitions = Shared:WaitForChild("Definitions")
local RaycastController = require(Utility:WaitForChild("RaycastController"))
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))
local PacketManager = require(Definitions:WaitForChild("PacketManager"))

local GunClass = {}
GunClass.__index = GunClass

function GunClass.new(player, LoadoutSlot, AnimationClass, ActionManager)
	local self = {
		AnimationClass = AnimationClass,
		ViewModelClass = AnimationClass:GetClass("ViewModel"),
		ActionManager = ActionManager,

		Player = player,
		Gun = LoadoutSlot,
		SlotName = LoadoutSlot.Name,

		Damage = LoadoutSlot:GetAttribute("Damage"),
		MagazineSize = LoadoutSlot:GetAttribute("MagazineSize"),
		ReserveAmmo = LoadoutSlot:GetAttribute("ReserveAmmo"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		Ammo = LoadoutSlot:GetAttribute("MagazineSize"),
		Handling = LoadoutSlot:GetAttribute("Handling"),
		Stability = LoadoutSlot:GetAttribute("Stability"),
		ReloadSpeed = LoadoutSlot:GetAttribute("ReloadSpeed"),
		BulletsPerShot = LoadoutSlot:GetAttribute("BulletsPerShot"),
		Spread = LoadoutSlot:GetAttribute("Spread"),
		Range = LoadoutSlot:GetAttribute("Range"),

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
	self.AnimationClass:OnEquip(self.Gun, self.Player)
	self.ReloadTrack = self.AnimationClass:GetAnimation("ViewModel", "Reload")
	self.RecoilTrack = self.AnimationClass:GetAnimation("ViewModel", "Recoil")
	self.EquipTrack = self.AnimationClass:GetAnimation("ViewModel", "Equip")

	self.ActionManager:SetState("WeaponState", "Equipping")
	self.EquipTrack:Play(0)

	self.EquippedConnections:Connect(self.EquipTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.EquippedConnections:Connect(self.RecoilTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.EquippedConnections:Connect(self.ReloadTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.EquippedConnections:Connect(self.ReloadTrack:GetMarkerReachedSignal("ReloadComplete"), function()
		if self.ActionManager:GetState("WeaponState") == "Reloading" then
			if self.ReserveAmmo >= self.MagazineSize then
				self.ReserveAmmo -= self.MagazineSize
				self.Ammo = self.MagazineSize
			else
				self.Ammo = self.ReserveAmmo
				self.ReserveAmmo = 0
			end
			PacketManager.Combat.AmmoUpdate.sendTo({
				Gun = self.Gun,
				Ammo = self.Ammo,
				ReserveAmmo = self.ReserveAmmo,
			}, self.Player)
		end
	end)
	-- Additional logic for equipping the gun can be added here
end

function GunClass:OnUnequip()
	if not self.Equipped then
		return
	end
	self.Equipped = false
	self.AnimationClass:OnUnequip()
	self.EquippedConnections:Clean()
end

function GunClass:CanReload()
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return self.Equipped
		and self.ActionManager:TryAction("Weapon", "Reload")
		and humanoid ~= nil
		and humanoid.Health > 0
		and self.Gun.Parent == character
		and self.Ammo < self.MagazineSize
		and self.ReserveAmmo > 0
end

function GunClass:Reload()
	if not self:CanReload() then
		return
	end

	self.ActionManager:SetState("WeaponState", "Reloading")

	self.ReloadTrack:Play(0)
	self.ReloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)
end

function GunClass:CanShoot(origin, seed)
	local character = self.Player.Character

	if not self.Equipped or not character or self.Gun.Parent ~= character then
		return false
	end

	if self.ActionManager:TryAction("Weapon", "Fire") == false then
		return false
	end
	if
		not RaycastController.ValidateVector3(origin.Position)
		or not RaycastController.ValidateVector3(origin.LookVector)
	then
		return false
	end

	if typeof(seed) ~= "number" or seed % 1 ~= 0 or seed < 0 or seed > 2 ^ 31 - 1 then
		return false
	end

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

	if now - self.lastShotTime < delayBetweenShots then
		return false
	end

	return true
end

function GunClass:Shoot(origin, seed)
	if not self:CanShoot(origin, seed) then
		return
	end

	if self.ActionManager:GetState("WeaponState") == "Reloading" then
		self.ReloadTrack:Stop(0)
	end

	self.Ammo -= 1
	PacketManager.Combat.AmmoUpdate.sendTo({
		Gun = self.Gun,
		Ammo = self.Ammo,
	}, self.Player)
	self.ActionManager:SetState("WeaponState", "Firing")
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
