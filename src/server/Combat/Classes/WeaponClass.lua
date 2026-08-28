local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local WeaponSettings = require(Settings:WaitForChild("WeaponSettings"))

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Combat = script:FindFirstAncestor("Combat")
local Weapons = Combat:WaitForChild("Weapons")

local FireMode = Weapons:WaitForChild("FireMode")
local AimType = Weapons:WaitForChild("AimType")
local ReloadType = Weapons:WaitForChild("ReloadType")
local ShotType = Weapons:WaitForChild("ShotType")

local WeaponClass = {}
WeaponClass.__index = WeaponClass

function WeaponClass.new(Player, WeaponName, SlotName, AnimationClass, StateManager)
	local WeaponInfo = table.clone(WeaponSettings[WeaponName])

	local self = {
		Trove = Trove.new(),
		WeaponInfo = WeaponInfo,

		Player = Player,
		WeaponName = WeaponName,
		SlotName = SlotName,

		AnimationClass = AnimationClass,
		StateManager = StateManager,

		Animations = nil,

		Equipped = false,
	}

	self.ShotType = require(ShotType:WaitForChild(self.WeaponInfo.SHOT_TYPE)).new(self)
	self.Firing = require(FireMode:WaitForChild(self.WeaponInfo.FIRE_MODE)).new(self)
	self.Aiming = require(AimType:WaitForChild(self.WeaponInfo.AIM_TYPE)).new(self)
	self.Reloading = require(ReloadType:WaitForChild(self.WeaponInfo.RELOAD_TYPE)).new(self)

	setmetatable(self, WeaponClass)
	return self
end

function WeaponClass:OnUnequip()
	if not self.Equipped or not self.StateManager:TryAction("Weapon", "UnEquip") then
		PacketSettings.Combat.Weapon.EquipResult.sendTo({
			Action = "UnEquip",
			SlotName = self.SlotName,
			Accepted = false,
		}, self.Player)
		return false
	end

	PacketSettings.Combat.Weapon.EquipResult.sendTo({
		Action = "UnEquip",
		SlotName = self.SlotName,
		Accepted = true,
	}, self.Player)

	self.Equipped = false

	self.StateManager:PerformAction("Weapon", "UnEquip")
	self.StateManager:SetState("WeaponState", "UNEQUIPPED")
	self.StateManager:SetState("EquippedState", "UNEQUIPPED")

	self.Firing:OnUnequip()
	self.Aiming:OnUnequip()
	self.Reloading:OnUnequip()
	self.Trove:Clean()
	self.AnimationClass:OnUnequip()
	return true
end

function WeaponClass:OnEquip()
	if self.Equipped or not self.StateManager:TryAction("Weapon", "Equip") then
		PacketSettings.Combat.Weapon.EquipResult.sendTo({
			Action = "Equip",
			SlotName = self.SlotName,
			Accepted = false,
		}, self.Player)
		return
	end

	PacketSettings.Combat.Weapon.EquipResult.sendTo({
		Action = "Equip",
		SlotName = self.SlotName,
		Accepted = true,
	}, self.Player)

	self.Equipped = true

	self.AnimationClass:OnEquip(self.WeaponInfo)

	self:GetAnimations()

	self.StateManager:PerformAction("Weapon", "Equip")
	self.StateManager:SetState("WeaponState", "EQUIPPING")
	self.StateManager:SetState("EquippedState", "EQUIPPED")

	self:Init()
end

function WeaponClass:GetAnimations()
	self.Animations = {
		Reload = self.AnimationClass:GetAnimation({
			AnimationType = "ViewModel",
			AnimationLocation = "WeaponAnimations",
			AnimationName = "Reload",
		}),
		Fire = self.AnimationClass:GetAnimation({
			AnimationType = "ViewModel",
			AnimationLocation = "WeaponAnimations",
			AnimationName = "Fire",
		}),
		Equip = self.AnimationClass:GetAnimation({
			AnimationType = "ViewModel",
			AnimationLocation = "WeaponAnimations",
			AnimationName = "Equip",
		}),
	}
end

function WeaponClass:Init()
	self.Trove:Connect(self.Animations.Equip.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Animations.Equip:Play(0)

	self.Trove:Connect(self.Animations.Fire.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.Animations.Reload.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self.Trove:Connect(self.Animations.Reload:GetMarkerReachedSignal("ReloadCompleted"), function()
		if self.StateManager:GetState("WeaponState") == "RELOADING" then
			local MissingAmmo = self.WeaponInfo.MAGAZINE_SIZE - self.WeaponInfo.AMMO
			local AmmoToLoad = math.min(MissingAmmo, self.WeaponInfo.RESERVE_AMMO)

			self.WeaponInfo.AMMO += AmmoToLoad
			self.WeaponInfo.RESERVE_AMMO -= AmmoToLoad
			PacketSettings.Combat.Weapon.AmmoUpdate.sendTo({
				SlotName = self.SlotName,
				Ammo = self.WeaponInfo.AMMO,
				ReserveAmmo = self.WeaponInfo.RESERVE_AMMO,
			}, self.Player)
		end
	end)

	self.Trove:Add(self.StateManager.CancelStateSignal:Connect(function(stateType, cancelledState)
		if stateType == "WeaponState" then
			if cancelledState == "RELOADING" then
				self.Reloading:Cancelled()
			end
		elseif stateType == "AimState" then
			if cancelledState == "AIMING" then
				self.Aiming:Released()
			end
		end
	end))
end

function WeaponClass:Destroy()
	self.Trove:Destroy()
end

return WeaponClass
