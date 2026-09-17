local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local WeaponSettings = require(Settings:WaitForChild("WeaponSettings"))

local Player = game:GetService("Players").LocalPlayer

local Combat = script:FindFirstAncestor("Combat")
local Weapons = Combat:WaitForChild("Weapons")

local FireMode = Weapons:WaitForChild("FireMode")
local AimType = Weapons:WaitForChild("AimType")
local ReloadType = Weapons:WaitForChild("ReloadType")
local ShotType = Weapons:WaitForChild("ShotType")

local Trove = require(Packages:WaitForChild("Trove"))

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local WeaponHandler = {}

WeaponHandler.__index = WeaponHandler

function WeaponHandler.new(WeaponName, SlotName, AnimationHandler, StateManager, GUIHandler, CombatClasses)
	-- Clones the weapon info from WeaponSettings to avoid modifying the original table
	local WeaponInfo = table.clone(WeaponSettings[WeaponName])

	local self = setmetatable({
		Trove = Trove.new(),
		WeaponInfo = WeaponInfo,
		WeaponName = WeaponName,
		SlotName = SlotName, --Change later to weaponInfo.SlotName if we add that to the settings
		AnimationHandler = AnimationHandler,
		StateManager = StateManager,
		GUIHandler = GUIHandler,
		CombatClasses = CombatClasses,

		-- Naming of these stats might change later

		Animations = {},
	}, WeaponHandler)

	self.ShotType = require(ShotType:WaitForChild(self.WeaponInfo.SHOT_TYPE)).new(self)
	self.Firing = require(FireMode:WaitForChild(self.WeaponInfo.FIRE_MODE)).new(self)
	self.Aiming = require(AimType:WaitForChild(self.WeaponInfo.AIM_TYPE)).new(self)
	self.Reloading = require(ReloadType:WaitForChild(self.WeaponInfo.RELOAD_TYPE)).new(self)

	self.GUIHandler:InitializeSlot(self.WeaponName, self.SlotName)

	return self
end

function WeaponHandler:SetAmmo(ammo, reserveAmmo)
	self.WeaponInfo.AMMO = ammo

	if reserveAmmo ~= nil then
		self.WeaponInfo.RESERVE_AMMO = reserveAmmo
	end

	self.GUIHandler:UpdateAmmo(self.SlotName, self.WeaponInfo.AMMO, self.WeaponInfo.RESERVE_AMMO)
end

function WeaponHandler:GetAnimations()
	self.Animations = self.AnimationHandler:GetAnimation("Weapon")
end

function WeaponHandler:OnEquip()
	if self.CombatClasses.EquippedWeaponClass ~= nil or not self.StateManager:TryAction("Weapon", "Equip") then
		return
	end

	self.StateManager:SetState("WeaponState", "EQUIPPING")
	self.StateManager:SetState("EquippedState", "EQUIPPED")

	UIS.MouseIconEnabled = false

	self.CombatClasses.EquippedWeaponClass = self

	self.GUIHandler:EquippedSlotChanged(self.SlotName)
	self.AnimationHandler:OnEquip(self.WeaponInfo)
	self:GetAnimations()

	self.Animations.IDLE.VIEWMODEL.Looped = true
	self.Animations.IDLE.CHARACTER.Looped = true

	self.Animations.IDLE.VIEWMODEL:Play(0.15, 1, 0.1)
	self.Animations.IDLE.CHARACTER:Play(0.15, 1, 0.1)

	local EquipSpeed = 1 + (self.WeaponInfo.HANDLING - 50) / 100
	self.Animations.EQUIP.VIEWMODEL:Play(0, 1, EquipSpeed)
	self.Animations.EQUIP.CHARACTER:Play(0, 1, EquipSpeed)

	self.Trove:Add(task.delay(self.WeaponInfo.EQUIP_DURATION / EquipSpeed, function()
		self.EquipTask = nil
		if self.StateManager:GetState("WeaponState") ~= "EQUIPPING" then
			return
		end

		self.StateManager:SetState("WeaponState", "IDLE")
	end))

	self:Init()
end

function WeaponHandler:OnUnequip()
	if self.CombatClasses.EquippedWeaponClass ~= self or not self.StateManager:TryAction("Weapon", "UnEquip") then
		return
	end

	self.StateManager:SetState("WeaponState", "UNEQUIPPED")
	self.StateManager:SetState("EquippedState", "UNEQUIPPED")

	UIS.MouseIconEnabled = true

	self.CombatClasses.EquippedWeaponClass = nil

	self.Animations.IDLE.VIEWMODEL:Stop(0.15)
	self.Animations.IDLE.CHARACTER:Stop(0.15)

	self.Firing:OnUnequip()
	self.Reloading:OnUnequip()
	self.Aiming:OnUnequip()

	self.Trove:Clean()
	self.AnimationHandler:OnUnequip()
	self.GUIHandler:OnUnequip()
end

return WeaponHandler