local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local WeaponSettings = require(Settings:WaitForChild("WeaponSettings"))

local Combat = script:FindFirstAncestor("Combat")
local Weapons = Combat:WaitForChild("Weapons")

local FireMode = Weapons:WaitForChild("FireMode")
local AimType = Weapons:WaitForChild("AimType")
local ReloadType = Weapons:WaitForChild("ReloadType")
local ShotType = Weapons:WaitForChild("ShotType")

local Trove = require(Packages:WaitForChild("Trove"))

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local WeaponController = {}

WeaponController.__index = WeaponController

function WeaponController.new(WeaponName, SlotName, AnimationController, StateManager, GUIController)
	-- Clones the weapon info from WeaponSettings to avoid modifying the original table
	local WeaponInfo = table.clone(WeaponSettings[WeaponName])

	local self = setmetatable({
		Trove = Trove.new(),
		WeaponInfo = WeaponInfo,
		WeaponName = WeaponName,
		SlotName = SlotName, --Change later to weaponInfo.SlotName if we add that to the settings
		AnimationController = AnimationController,
		StateManager = StateManager,
		GUIController = GUIController,

		-- Naming of these stats might change later
		Equipped = false,

		Animations = {},
	}, WeaponController)

	self.ShotType = require(ShotType:WaitForChild(self.WeaponInfo.SHOT_TYPE)).new(self)
	self.Firing = require(FireMode:WaitForChild(self.WeaponInfo.FIRE_MODE)).new(self)
	self.Aiming = require(AimType:WaitForChild(self.WeaponInfo.AIM_TYPE)).new(self)
	self.Reloading = require(ReloadType:WaitForChild(self.WeaponInfo.RELOAD_TYPE)).new(self)

	return self
end

function WeaponController:SetAmmo(ammo, reserveAmmo)
	self.WeaponInfo.AMMO = ammo

	if reserveAmmo ~= nil then
		self.WeaponInfo.RESERVE_AMMO = reserveAmmo
	end

	self.GUIController:UpdateAmmo(self.SlotName, self.WeaponInfo.AMMO, self.WeaponInfo.RESERVE_AMMO)
end

function WeaponController:GetAnimations()
	self.Animations = self.AnimationController:GetAnimation("Weapon")
end

function WeaponController:OnEquip()
	if not self.StateManager:TryAction("Weapon", "Equip") then
		return
	end

	self.StateManager:PerformAction("Weapon", "Equip")
	self.StateManager:SetState("WeaponState", "EQUIPPING")
	self.StateManager:SetState("EquippedState", "EQUIPPED")

	UIS.MouseIconEnabled = false

	self.Equipped = true

	self.GUIController:EquippedSlotChanged(self.SlotName)
	self.AnimationController:OnEquip(self.WeaponInfo)
	self:GetAnimations()

	self.Animations.IDLE.VIEWMODEL.Looped = true
	self.Animations.IDLE.CHARACTER.Looped = true

	self.Animations.IDLE.VIEWMODEL:Play(0.15, 1, 0.1)
	self.Animations.IDLE.CHARACTER:Play(0.15, 1, 0.1)

	local EquipSpeed = 1 + (self.WeaponInfo.HANDLING - 50) / 100
	self.Animations.EQUIP.VIEWMODEL:Play(0, 1, EquipSpeed)
	self.Animations.EQUIP.CHARACTER:Play(0, 1, EquipSpeed)

	self:Init()
end

function WeaponController:OnUnequip()
	if not self.StateManager:TryAction("Weapon", "UnEquip") then
		return
	end

	self.StateManager:PerformAction("Weapon", "UnEquip")
	self.StateManager:SetState("WeaponState", "UNEQUIPPED")
	self.StateManager:SetState("EquippedState", "UNEQUIPPED")

	UIS.MouseIconEnabled = true

	self.Equipped = false

	self.Animations.IDLE.VIEWMODEL:Stop(0.15)
	self.Animations.IDLE.CHARACTER:Stop(0.15)

	self.Firing:OnUnequip()
	self.Reloading:OnUnequip()
	self.Aiming:OnUnequip()

	self.Trove:Clean()
	self.AnimationController:OnUnequip()
	self.GUIController:OnUnequip()
end

function WeaponController:EquipOrUnequip()
	if self.Equipped then
		PacketSettings.Combat.Weapon.EquipRequest.send({
			SlotName = self.SlotName,
			Action = "UnEquip",
		})
	else
		PacketSettings.Combat.Weapon.EquipRequest.send({
			SlotName = self.SlotName,
			Action = "Equip",
		})
	end

	return
end

function WeaponController:BindAction(actionName, callback, createTouchButton, ...)
	CAS:BindAction(actionName, callback, createTouchButton, ...)

	self.Trove:Add(function()
		CAS:UnbindAction(actionName)
	end)
end

function WeaponController:Init()
	self.Trove:Connect(self.Animations.EQUIP.VIEWMODEL.Stopped, function()
		self.StateManager:SetState("WeaponState", "IDLE")
	end)

	self:BindAction("Firing", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.Firing:Held()
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.Firing:Released()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton1)

	self:BindAction("Reloading", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.Reloading:Held()
		end

		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.Reloading:Released()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	self:BindAction("Aiming", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.Aiming:Held()
		end
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			self.Aiming:Released()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2)

	-- State Change Connections
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

return WeaponController
