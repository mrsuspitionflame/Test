local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Definitions = Shared:WaitForChild("Definitions")
local gunSettings = require(Definitions:WaitForChild("GunSettings"))
local RaycastController = require(Utility:WaitForChild("RaycastController"))
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))
local PacketManager = require(Definitions:WaitForChild("PacketManager"))

local GunClass = {}
GunClass.__index = GunClass

function GunClass.new(player, gunName, slotName, animationClass, actionManager)
	local gunInfo = gunSettings[gunName]
	local self = {
		AnimationClass = animationClass,
		ViewModelClass = animationClass:GetClass("ViewModel"),
		ActionManager = actionManager,
		Player = player,
		GunName = gunName,
		SlotName = slotName,

		Damage = gunInfo.Damage,
		MagazineSize = gunInfo.MagazineSize,
		ReserveAmmo = gunInfo.ReserveAmmo,
		FireRate = gunInfo.FireRate,
		Ammo = gunInfo.MagazineSize,
		Handling = gunInfo.Handling,
		Stability = gunInfo.Stability,
		ReloadSpeed = gunInfo.ReloadSpeed,
		BulletsPerShot = gunInfo.BulletsPerShot,
		Spread = gunInfo.Spread,
		Range = gunInfo.Range,

		Equipped = false,
		Aiming = false,
		lastShotTime = workspace:GetServerTimeNow(),
	}

	self.Trove = Trove.new()

	setmetatable(self, GunClass)
	return self
end

function GunClass:SetAiming(isAiming)
	self.Aiming = isAiming
end

function GunClass:CanEquip()
	return self.ActionManager:TryAction("Weapon", "Equip")
end

function GunClass:OnEquip()
	if not self:CanEquip() or self.Equipped then
		PacketManager.Combat.EquipResult.sendTo({
			Action = "Equip",
			SlotName = self.SlotName,
			Accepted = false,
		}, self.Player)
		return false
	end

	PacketManager.Combat.EquipResult.sendTo({
		Action = "Equip",
		SlotName = self.SlotName,
		Accepted = true,
	}, self.Player)

	self.Equipped = true
	self.AnimationClass:OnEquip(self.GunName, self.Player)
	self.ReloadTrack = self.AnimationClass:GetAnimation("ViewModel", "Reload")
	self.RecoilTrack = self.AnimationClass:GetAnimation("ViewModel", "Recoil")
	self.EquipTrack = self.AnimationClass:GetAnimation("ViewModel", "Equip")

	self.ActionManager:SetState("WeaponState", "Equipping")
	self.EquipTrack:Play(0)

	self.Trove:Connect(self.EquipTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.Trove:Connect(self.RecoilTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.Trove:Connect(self.ReloadTrack.Stopped, function()
		self.ActionManager:SetState("WeaponState", "Idle")
	end)

	self.Trove:Connect(self.ReloadTrack:GetMarkerReachedSignal("ReloadComplete"), function()
		if self.ActionManager:GetState("WeaponState") == "Reloading" then
			local MissingAmmo = self.MagazineSize - self.Ammo
			local AmmoToLoad = math.min(MissingAmmo, self.ReserveAmmo)

			self.Ammo += AmmoToLoad
			self.ReserveAmmo -= AmmoToLoad
			PacketManager.Combat.AmmoUpdate.sendTo({
				SlotName = self.SlotName,
				Ammo = self.Ammo,
				ReserveAmmo = self.ReserveAmmo,
			}, self.Player)
		end
	end)
	-- Additional logic for equipping the gun can be added here
	return true
end

function GunClass:CanUnequip()
	return self.ActionManager:TryAction("Weapon", "UnEquip")
end

function GunClass:OnUnequip()
	if not self.Equipped or not self:CanUnequip() then
		PacketManager.Combat.EquipResult.sendTo({
			Action = "UnEquip",
			SlotName = self.SlotName,
			Accepted = false,
		}, self.Player)
		return false
	end

	PacketManager.Combat.EquipResult.sendTo({
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

function GunClass:CanReload()
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return self.Equipped
		and self.ActionManager:TryAction("Weapon", "Reload")
		and humanoid ~= nil
		and humanoid.Health > 0
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

	if not self.Equipped or not character then
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
		SlotName = self.SlotName,
		Ammo = self.Ammo,
	}, self.Player)
	self.ActionManager:SetState("WeaponState", "Firing")
	self.lastShotTime = workspace:GetServerTimeNow()

	self.RecoilTrack:Play(0)

	local rayDirections
	if self.Aiming then
		print("Aiming, no spread")
		rayDirections = RaycastController.GetRayDirections(origin, self.BulletsPerShot, 0, seed, self.Range * 10)
	else
		rayDirections = RaycastController.GetRayDirections(
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
	self.Trove:Destroy()
end

return GunClass
