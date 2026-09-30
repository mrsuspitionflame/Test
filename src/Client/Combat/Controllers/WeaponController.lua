local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local WeaponSettings = require(Settings:WaitForChild("WeaponSettings"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Combat = script:FindFirstAncestor("Combat")
local Weapons = Combat:WaitForChild("Components"):WaitForChild("Weapons")

local EquipType = Weapons:WaitForChild("EquipType")
local FireMode = Weapons:WaitForChild("FireMode")
local AimType = Weapons:WaitForChild("AimType")
local ReloadType = Weapons:WaitForChild("ReloadType")
local ShotType = Weapons:WaitForChild("ShotType")



local WeaponController = {}

WeaponController.__index = WeaponController

function WeaponController.new(WeaponName, SlotName, ViewModelController, StateManager, GUIController, CombatController)
	local WeaponInfo = WeaponSettings[WeaponName]

	local self = setmetatable({
		Trove = CombatController.Trove:Extend(),
		WeaponInfo = WeaponInfo,
		Ammo = WeaponInfo.AMMO,
		ReserveAmmo = WeaponInfo.RESERVE_AMMO,
		WeaponName = WeaponName,
		SlotName = SlotName, --Change later to weaponInfo.SlotName if we add that to the settings
		ViewModelController = ViewModelController,
		StateManager = StateManager,
		GUIController = GUIController,
		CombatController = CombatController,


	}, WeaponController)

	self:Init()
	return self
end

function WeaponController:SetAmmo(ammo, reserveAmmo)
	self.Ammo = ammo

	if reserveAmmo ~= nil then
		self.ReserveAmmo = reserveAmmo
	end

	self.GUIController:UpdateAmmo(self.SlotName, self.Ammo, self.ReserveAmmo)
end

function WeaponController:GetAnimations()
	self.Animations = self.AnimationController:GetAnimation("Weapon")
end

function WeaponController:InputSetup()
	local Player = game:GetService("Players").LocalPlayer
	self.Inputs = Player:WaitForChild("Inputs")

	if not self.Inputs then
		warn("Inputs not found for Player")
		return false
	end
	local WeaponContext = self.Inputs:WaitForChild("WeaponContext")
	self.FireAction = WeaponContext:WaitForChild("FireAction")
	self.AimAction = WeaponContext:WaitForChild("AimAction")
	self.ReloadAction = WeaponContext:WaitForChild("ReloadAction")
	self.EquipAction = WeaponContext:FindFirstChild("Equip" .. self.SlotName .. "Action")
	return true
end

function WeaponController:BindWeaponInputs()
	if self.InputTrove then
		return
	end
	local InputTrove = self.Trove:Extend()
	self.InputTrove = InputTrove
	InputTrove:Connect(self.FireAction.Pressed, function()
		self.Firing:Pressed()
	end)
	InputTrove:Connect(self.FireAction.Released, function()
		self.Firing:Released()
	end)
	InputTrove:Connect(self.AimAction.Pressed, function()
		self.Aiming:Pressed()
	end)
	InputTrove:Connect(self.AimAction.Released, function()
		self.Aiming:Released()
	end)
	InputTrove:Connect(self.ReloadAction.Pressed, function()
		self.Reloading:Pressed()
	end)
end

function WeaponController:UnbindWeaponInputs()
	if self.InputTrove then
		self.InputTrove:Clean()
		self.InputTrove = nil
	end
end

function WeaponController:Init()
	if self.Initialized then
		return
	end
	self.Initialized = true

	if not self:InputSetup() then
		return
	end

	self.GUIController:InitializeSlot(self.WeaponName, self.SlotName, self.Ammo, self.ReserveAmmo)

	self.CombatController.Trove:Add(PacketSettings.Combat.Weapon.AmmoUpdate.listen(function(data)
		if data.SlotName == self.SlotName then
			self:SetAmmo(data.Ammo, data.ReserveAmmo)
		end
	end))

	-- Sort out the troves later since the weapon could be replaced

	self.ShotType = require(ShotType:WaitForChild(self.WeaponInfo.SHOT_TYPE)).new(self)
	self.Firing = require(FireMode:WaitForChild(self.WeaponInfo.FIRE_MODE)).new(self)
	self.Aiming = require(AimType:WaitForChild(self.WeaponInfo.AIM_TYPE)).new(self)
	self.Reloading = require(ReloadType:WaitForChild(self.WeaponInfo.RELOAD_TYPE)).new(self)
	self.Equipping = require(EquipType:WaitForChild(self.WeaponInfo.EQUIP_TYPE)).new(self)
	
	if self.EquipAction then
		self.CombatController.Trove:Connect(self.EquipAction.Pressed, function()
			self.Equipping:Pressed()
		end)
	else
		warn("Equip action not found for slot: " .. self.SlotName)
	end
end


function WeaponController:Destroy()
	self.Trove:Destroy()
end

return WeaponController
