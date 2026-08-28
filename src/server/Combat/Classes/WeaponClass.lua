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

local Models = ReplicatedStorage:WaitForChild("Models")
local WeaponModels = Models:WaitForChild("WeaponModels")

local WeaponClass = {}
WeaponClass.__index = WeaponClass

function WeaponClass.new(Player, WeaponName, SlotName, StateManager)
	local WeaponInfo = table.clone(WeaponSettings[WeaponName])

	local self = {
		Trove = Trove.new(),
		WeaponInfo = WeaponInfo,

		Player = Player,
		WeaponName = WeaponName,
		SlotName = SlotName,

		StateManager = StateManager,

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
	self.Reloading:OnUnequip()
	self.Aiming:OnUnequip()

	self.Trove:Clean()
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

	self:AttachWeaponModel()

	self.StateManager:PerformAction("Weapon", "Equip")
	self.StateManager:SetState("WeaponState", "EQUIPPING")
	self.StateManager:SetState("EquippedState", "EQUIPPED")

	local EquipSpeed = 1 + (self.WeaponInfo.HANDLING - 50) / 100

	self.Trove:Add(task.delay(self.WeaponInfo.EQUIP_DURATION / EquipSpeed, function()
		self.EquipTask = nil
		if self.StateManager:GetState("WeaponState") ~= "EQUIPPING" then
			return
		end

		self.StateManager:SetState("WeaponState", "IDLE")
	end))

	self:Init()
end

function WeaponClass:AttachWeaponModel()
	local WeaponModel =
		self.Trove:Add(WeaponModels:WaitForChild(self.WeaponInfo.WEAPON_TYPE):WaitForChild("HandCannonModel"):Clone())

	local RightArm = self.Player.Character:FindFirstChild("Right Arm", true)
	local Default = WeaponModel:WaitForChild("Default")

	local ArmGrip = RightArm:WaitForChild("WeaponGripAttachment")
	local GunGrip = Default:WaitForChild("WeaponGripAttachment")

	WeaponModel.Parent = self.Player.Character

	local weaponMotor = Instance.new("Motor6D")
	weaponMotor.Name = "WeaponMotor"
	weaponMotor.Part0 = RightArm
	weaponMotor.Part1 = Default
	weaponMotor.C0 = ArmGrip.CFrame
	weaponMotor.C1 = GunGrip.CFrame
	weaponMotor.Parent = RightArm

	self.RayOrigin = Default:WaitForChild("RayOrigin")
	self.Muzzle = Default:WaitForChild("MuzzleAttachment")
end

function WeaponClass:Init()
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
	self.Firing:Destroy()
	self.Reloading:Destroy()
	self.Aiming:Destroy()
	self.Trove:Destroy()
end

return WeaponClass
