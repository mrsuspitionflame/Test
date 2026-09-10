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

function WeaponClass.new(Player, WeaponName, SlotName, StateManager, CombatClasses, data)
	local WeaponInfo = WeaponSettings[WeaponName]

	local Trove = Trove.new()

	local self = {
		Trove = Trove,
		WeaponInfo = WeaponInfo,

		Player = Player,
		WeaponName = WeaponName,
		SlotName = SlotName,

		StateManager = StateManager,
		CombatClasses = CombatClasses,
	}

	self.ShotType = Trove:Add(require(ShotType:WaitForChild(self.WeaponInfo.SHOT_TYPE)).new(self))
	self.Firing = Trove:Add(require(FireMode:WaitForChild(self.WeaponInfo.FIRE_MODE)).new(self))
	self.Aiming = Trove:Add(require(AimType:WaitForChild(self.WeaponInfo.AIM_TYPE)).new(self))
	self.Reloading = Trove:Add(require(ReloadType:WaitForChild(self.WeaponInfo.RELOAD_TYPE)).new(self))

	setmetatable(self, WeaponClass)
	return self
end

function WeaponClass:OnCharacterAdded(character)
	self.Character = character
	self.Humanoid = character:FindFirstChildOfClass("Humanoid")
	self.Root = character:FindFirstChild("HumanoidRootPart")

	self:SetupInput()
end

function WeaponClass:OnCharacterRemoving()
	if self.ShotType then
		self.ShotType:Destroy()
	end
	if self.Firing then
		self.Firing:Destroy()
	end
	if self.Aiming then
		self.Aiming:Destroy()
	end
	if self.Reloading then
		self.Reloading:Destroy()
	end

	self.ShotType = nil
	self.Firing = nil
	self.Aiming = nil
	self.Reloading = nil

	self.Character = nil
	self.Humanoid = nil
	self.Root = nil
end

function WeaponClass:InputSetup()
	local Inputs = self.Player:WaitForChild("Inputs")
	local WeaponContext = Inputs:WaitForChild("WeaponContext")
	self.AimAction = WeaponContext:WaitForChild("Aim")
	self.FireAction = WeaponContext:WaitForChild("Fire")
	self.ReloadAction = WeaponContext:WaitForChild("Reload")
end

function WeaponClass:Step(dt)
	self.Firing:Step(dt)
	self.Reloading:Step(dt)
	self.Aiming:Step(dt)
end

function WeaponClass:OnUnequip()
	if self.CombatClasses.EquippedWeaponClass ~= self or not self.StateManager:TryAction("Weapon", "UnEquip") then
		return
	end

	self.CombatClasses.EquippedWeaponClass = nil

	self.StateManager:SetState("WeaponState", "UNEQUIPPED")

	self.Firing:OnUnequip()
	self.Reloading:OnUnequip()
	self.Aiming:OnUnequip()

	self.Trove:Clean()
	return true
end

function WeaponClass:OnEquip()
	if self.CombatClasses.EquippedWeaponClass ~= nil or not self.StateManager:TryAction("Weapon", "Equip") then
		return
	end

	PacketSettings.Combat.Weapon.EquipResult.sendTo({
		Action = "Equip",
		SlotName = self.SlotName,
		Accepted = true,
	}, self.Player)

	self.CombatClasses.EquippedWeaponClass = self

	self:AttachWeaponModel()

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
	if self.CombatClasses.EquippedWeaponClass == self then
		self.CombatClasses.EquippedWeaponClass = nil
	end

	self.Trove:Destroy()
end

return WeaponClass
