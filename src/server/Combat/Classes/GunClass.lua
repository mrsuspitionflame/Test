local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = Shared:WaitForChild("Weapons")
local Settings = Shared:WaitForChild("Settings")
local gunSettings = require(Settings:WaitForChild("GunSettings"))
local Firing = Weapons:WaitForChild("Firing")
local Hitscan = require(Firing:WaitForChild("Hitscan"))
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local GunClass = {}
GunClass.__index = GunClass

function GunClass.new(player, gunName, slotName, animationClass, stateManager)
	local gunInfo = gunSettings[gunName]
	local self = {
		AnimationClass = animationClass,
		ViewModelClass = animationClass:GetClass("ViewModel"),
		StateManager = stateManager,
		Player = player,
		GunName = gunName,
		SlotName = slotName,

		Damage = gunInfo.DAMAGE,
		MagazineSize = gunInfo.MAGAZINE_SIZE,
		ReserveAmmo = gunInfo.RESERVE_AMMO,
		FireRate = gunInfo.FIRE_RATE,
		Ammo = gunInfo.MAGAZINE_SIZE,
		Handling = gunInfo.HANDLING,
		Stability = gunInfo.STABILITY,
		ReloadSpeed = gunInfo.RELOAD_SPEED,
		BulletsPerShot = gunInfo.BULLETS_PER_SHOT,
		Spread = gunInfo.SPREAD,
		Range = gunInfo.RANGE,

		Equipped = false,
		Aiming = false,
		lastShotTime = workspace:GetServerTimeNow(),
	}

	self.Trove = Trove.new()

	setmetatable(self, GunClass)

	return self
end

-- Aiming logic

function GunClass:SetAiming(isAiming)
	self.Aiming = isAiming
end

function GunClass:StopAiming()
	self.Aiming = false
end

-- Equipping and Unequipping logic

function GunClass:CanEquip()
	return self.StateManager:TryAction("Weapon", "Equip")
end

function GunClass:OnEquip()
	if not self:CanEquip() or self.Equipped then
		PacketSettings.Combat.EquipResult.sendTo({
			Action = "Equip",
			SlotName = self.SlotName,
			Accepted = false,
		}, self.Player)
		return false
	end

	PacketSettings.Combat.EquipResult.sendTo({
		Action = "Equip",
		SlotName = self.SlotName,
		Accepted = true,
	}, self.Player)

	self.Equipped = true
	self.AnimationClass:OnEquip(self.GunName, self.Player)
	self.ReloadTrack = self.AnimationClass:GetAnimation("ViewModel", "Reload")
	self.RecoilTrack = self.AnimationClass:GetAnimation("ViewModel", "Recoil")
	self.EquipTrack = self.AnimationClass:GetAnimation("ViewModel", "Equip")

	self.StateManager:SetState("WeaponState", "EQUIPPING")
	self.EquipTrack:Play(0)

	self:ConnectSignals()

	self.Trove:Connect(self.EquipTrack.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.RecoilTrack.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.ReloadTrack.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.ReloadTrack:GetMarkerReachedSignal("ReloadComplete"), function()
		if self.StateManager:GetState("WeaponState") == "RELOADING" then
			local MissingAmmo = self.MagazineSize - self.Ammo
			local AmmoToLoad = math.min(MissingAmmo, self.ReserveAmmo)

			self.Ammo += AmmoToLoad
			self.ReserveAmmo -= AmmoToLoad
			PacketSettings.Combat.AmmoUpdate.sendTo({
				SlotName = self.SlotName,
				Ammo = self.Ammo,
				ReserveAmmo = self.ReserveAmmo,
			}, self.Player)
		end
	end)

	return true
end

function GunClass:CanUnequip()
	return self.StateManager:TryAction("Weapon", "UnEquip")
end

function GunClass:OnUnequip()
	if not self.Equipped or not self:CanUnequip() then
		PacketSettings.Combat.EquipResult.sendTo({
			Action = "UnEquip",
			SlotName = self.SlotName,
			Accepted = false,
		}, self.Player)
		return false
	end

	PacketSettings.Combat.EquipResult.sendTo({
		Action = "UnEquip",
		SlotName = self.SlotName,
		Accepted = true,
	}, self.Player)

	self.Equipped = false
	self.Aiming = false
	self.AnimationClass:OnUnequip()
	self.Trove:Clean()
	return true
end

-- Reload logic

function GunClass:CanReload()
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return self.Equipped
		and self.StateManager:TryAction("Weapon", "Reload")
		and humanoid ~= nil
		and humanoid.Health > 0
		and self.Ammo < self.MagazineSize
		and self.ReserveAmmo > 0
end

function GunClass:CancelReload()
	self.ReloadTrack:Stop(0)
end

function GunClass:Reload()
	if not self:CanReload() then
		return
	end

	self.StateManager:SetState("WeaponState", "RELOADING")

	self.ReloadTrack:Play(0)
	self.ReloadTrack:AdjustSpeed(1 + (self.ReloadSpeed - 50) / 100)
end

-- Shooting logic

function GunClass:CanShoot(origin, seed)
	local character = self.Player.Character

	if not self.Equipped or not character then
		return false
	end

	if self.StateManager:TryAction("Weapon", "Fire") == false then
		return false
	end
	if
		not Hitscan.ValidateVector3(origin.Position)
		or not Hitscan.ValidateVector3(origin.LookVector)
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

	self.StateManager:PerformAction("Weapon", "Fire")
	self.StateManager:SetState("WeaponState", "FIRING")

	self.Ammo -= 1

	PacketSettings.Combat.AmmoUpdate.sendTo({
		SlotName = self.SlotName,
		Ammo = self.Ammo,
	}, self.Player)

	self.lastShotTime = workspace:GetServerTimeNow()

	self.RecoilTrack:Play(0)

	local rayDirections
	if self.Aiming then
		rayDirections = Hitscan.GetRayDirections(origin, self.BulletsPerShot, 0, seed, self.Range * 10)
	else
		rayDirections = Hitscan.GetRayDirections(
			origin,
			self.BulletsPerShot,
			math.rad(self.Spread),
			seed,
			self.Range * 10
		)
	end

	local ignoreList = {
		self.Player.Character,
	}

	local rayResults = Hitscan.CastRays(origin.Position, rayDirections, ignoreList, 0)

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

	PacketSettings.Combat.ReplicateShotEvent.sendToAllExcept({
		MuzzlePosition = rayOrigin,
		RayResults = rayResults,
	}, self.Player)
end

-- Signal Connections

function GunClass:ConnectSignals()
	self.Trove:Add(self.StateManager.CancelStateSignal:Connect(function(stateType, cancelledState)
		if stateType == "WeaponState" then
			if cancelledState == "RELOADING" then
				self:CancelReload()
			end
		elseif stateType == "AimState" then
			if cancelledState == "AIMING" then
				self:StopAiming()
			end
		end
	end))
end

function GunClass:Destroy()
	self.Trove:Destroy()
end

return GunClass
