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

local WeaponHandler = {}

WeaponHandler.__index = WeaponHandler

function WeaponHandler.new(WeaponName, SlotName, ViewModelController, StateManager, GUIController, CombatHandler)
	local WeaponInfo = WeaponSettings[WeaponName]

	local self = setmetatable({
		Trove = CombatHandler.Trove:Extend(),
		WeaponInfo = WeaponInfo,
		Ammo = WeaponInfo.AMMO,
		ReserveAmmo = WeaponInfo.RESERVE_AMMO,
		WeaponName = WeaponName,
		SlotName = SlotName, --Change later to weaponInfo.SlotName if we add that to the settings
		ViewModelController = ViewModelController,
		CameraController = CombatHandler.CameraController,
		StateManager = StateManager,
		GUIController = GUIController,
		CombatHandler = CombatHandler,
	}, WeaponHandler)

	self.EquippedTrove = self.Trove:Extend()
	self:Init()
	return self
end

function WeaponHandler:SetAmmo(ammo, reserveAmmo)
	self.Ammo = ammo

	if reserveAmmo ~= nil then
		self.ReserveAmmo = reserveAmmo
	end

	self.GUIController:UpdateAmmo(self.SlotName, self.Ammo, self.ReserveAmmo)
end

function WeaponHandler:GetAnimations()
	self.Animations = self.ViewModelController.WeaponAnimations
end

function WeaponHandler:InputSetup()
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

function WeaponHandler:BindWeaponInputs()
	if self.EquipTrove then
		return
	end
	local EquipTrove = self.Trove:Extend()
	self.EquipTrove = EquipTrove
	EquipTrove:Connect(self.FireAction.Pressed, function()
		self.Firing:Pressed()
	end)
	EquipTrove:Connect(self.FireAction.Released, function()
		self.Firing:Released()
	end)
	EquipTrove:Connect(self.AimAction.Pressed, function()
		self.Aiming:Pressed()
	end)
	EquipTrove:Connect(self.AimAction.Released, function()
		self.Aiming:Released()
	end)
	EquipTrove:Connect(self.ReloadAction.Pressed, function()
		self.Reloading:Pressed()
	end)
end

function WeaponHandler:UnbindWeaponInputs()
	if self.EquipTrove then
		self.Trove:Remove(self.EquipTrove)
		self.EquipTrove = nil
	end
end

function WeaponHandler:Init()
	if self.Initialized then
		return
	end
	self.Initialized = true

	if not self:InputSetup() then
		return
	end

	self.GUIController:InitializeSlot(self.WeaponName, self.SlotName, self.Ammo, self.ReserveAmmo)

	self.Trove:Add(PacketSettings.Combat.Weapon.AmmoUpdate.listen(function(data)
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

	self.Trove:Add(PacketSettings.Combat.Weapon.EquipResult.listen(function(data)
		if data.SlotName ~= self.SlotName then
			return
		end

		if not data.Accepted then
			warn("Equip/Unequip action was not accepted for slot:", data.SlotName)
			return
		else
			print("Equip/Unequip action was accepted for slot:", data.SlotName)
		end

		if data.Action == "Equip" then
			self.Equipping:OnEquip()
		elseif data.Action == "UnEquip" then
			self.Equipping:OnUnequip()
		end
	end))

	if self.EquipAction then
		self.Trove:Connect(self.EquipAction.Pressed, function()
			self.Equipping:Pressed()
		end)
	else
		warn("Equip action not found for slot: " .. self.SlotName)
	end
end

function WeaponHandler:Destroy()
	self.Trove:Destroy()
end

return WeaponHandler
