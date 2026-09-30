local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local WeaponSettings = require(Settings:WaitForChild("WeaponSettings"))

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))

local Combat = script:FindFirstAncestor("Combat")
local Weapons = Combat:WaitForChild("Components"):WaitForChild("Weapons")

local EquipType = Weapons:WaitForChild("EquipType")
local FireMode = Weapons:WaitForChild("FireMode")
local AimType = Weapons:WaitForChild("AimType")
local ReloadType = Weapons:WaitForChild("ReloadType")
local ShotType = Weapons:WaitForChild("ShotType")

local Models = ReplicatedStorage:WaitForChild("Models")
local WeaponModels = Models:WaitForChild("WeaponModels")

local WeaponClass = {}
WeaponClass.__index = WeaponClass

function WeaponClass.new(Player, WeaponName, SlotName, StateManager, CombatClasses)
	local WeaponInfo = WeaponSettings[WeaponName]

	local self = {
		Trove = Trove.new(),
		WeaponInfo = WeaponInfo,
		Ammo = WeaponInfo.AMMO,
		ReserveAmmo = WeaponInfo.RESERVE_AMMO,

		Player = Player,
		WeaponName = WeaponName,
		SlotName = SlotName,

		StateManager = StateManager,
		CombatClasses = CombatClasses,

	}

	self.Equipping = require(EquipType:WaitForChild(self.WeaponInfo.EQUIP_TYPE)).new(self)
	self.ShotType = require(ShotType:WaitForChild(self.WeaponInfo.SHOT_TYPE)).new(self)
	self.Firing = require(FireMode:WaitForChild(self.WeaponInfo.FIRE_MODE)).new(self)
	self.Aiming = require(AimType:WaitForChild(self.WeaponInfo.AIM_TYPE)).new(self)
	self.Reloading = require(ReloadType:WaitForChild(self.WeaponInfo.RELOAD_TYPE)).new(self)

	setmetatable(self, WeaponClass)
	return self
end

function WeaponClass:OnUnequip()
	return self.Equipping:OnUnequip()
end

function WeaponClass:OnEquip()
	return self.Equipping:OnEquip()
end

function WeaponClass:AttachWeaponModel()
	local WeaponModel =
		self.Trove:Add(WeaponModels:WaitForChild(self.WeaponInfo.WEAPON_TYPE):WaitForChild("HandCannonModel"):Clone())

	local RightArm = self.Player.Character:FindFirstChild("Right Arm", true)
	local Default = WeaponModel:WaitForChild("Default")

	local ArmGrip = RightArm:WaitForChild("WeaponGripAttachment")
	local GunGrip = Default:WaitForChild("WeaponGripAttachment")

	WeaponModel.Parent = self.Player.Character

	local weaponMotor = self.Trove:Add(Instance.new("Motor6D"))
	weaponMotor.Name = "WeaponMotor"
	weaponMotor.Part0 = RightArm
	weaponMotor.Part1 = Default
	weaponMotor.C0 = ArmGrip.CFrame
	weaponMotor.C1 = GunGrip.CFrame
	weaponMotor.Parent = RightArm

	self.RayOrigin = Default:WaitForChild("RayOrigin")
	self.Muzzle = Default:WaitForChild("MuzzleAttachment")
end

function WeaponClass:Init() end

function WeaponClass:Destroy()
	if self.CombatClasses.EquippedSlot == self.SlotName then
		self.CombatClasses.EquippedSlot = nil
	end
	self.Firing:Destroy()
	self.Reloading:Destroy()
	self.Aiming:Destroy()
	self.Trove:Destroy()
end

return WeaponClass
