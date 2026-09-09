local Combat = script.Parent
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local SharedCombat = Shared:WaitForChild("Combat")
local MovementClass = require(SharedCombat:WaitForChild("Classes"):WaitForChild("MovementClass"))

local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Controllers = Combat:WaitForChild("Controllers")

local AbilityController = require(Controllers:WaitForChild("AbilityController"))
local WeaponController = require(Controllers:WaitForChild("WeaponController"))
local AnimationController = require(Controllers:WaitForChild("AnimationController"))
local GUIController = require(Controllers:WaitForChild("GUIController"))
local StateManager = require(Utility:WaitForChild("StateManager"))

local SimulationFolder = Shared:WaitForChild("Simulation")
local Simulation = require(SimulationFolder:WaitForChild("Simulation"))

local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local CombatClasses = {}

CombatClasses.__index = CombatClasses

function CombatClasses.new()
	local self = setmetatable({}, CombatClasses)

	self.WeaponLoadout = {
		KineticSlot = nil,
		EnergySlot = nil,
		HeavySlot = nil,
	}

	self.GUI = GUIController.new()
	self.StateManager = StateManager.new()
	self.AnimationController = AnimationController.new(self.StateManager)

	self:Init()
	return self
end

function CombatClasses:CreateWeaponController(data)
	if self.WeaponLoadout[data.SlotName] == nil then
		self.WeaponLoadout[data.SlotName] = WeaponController.new(
			data.WeaponName,
			data.SlotName,
			self.AnimationController,
			self.StateManager,
			self.GUI,
			self
		)
	end
end

function CombatClasses:GetEquippedWeapon()
	for _, weaponController in pairs(self.WeaponLoadout) do
		if weaponController.Equipped then
			return weaponController
		end
	end

	return nil
end

function CombatClasses:CancelState(stateType, state)
	if self.StateManager:GetState(stateType) ~= state then
		return false
	end

	local weaponController = self:GetEquippedWeapon()
	if not weaponController then
		return false
	end

	if stateType == "WeaponState" then
		if state == "RELOADING" then
			weaponController.Reloading:Cancelled()
		elseif state == "FIRING" then
			weaponController.Firing:Cancelled()
		else
			return false
		end
	elseif stateType == "AimState" and state == "AIMING" then
		weaponController.Aiming:Cancelled()
	else
		return false
	end

	return true
end

function CombatClasses:CreateAbilityController(data)
	if self.Ability then
		return
	end
	self.Ability = AbilityController.new(data, self.AnimationController, self.StateManager, self.GUI)
end

function CombatClasses:CreateMovementClass()
	if self.MovementClass then
		return
	end
	self.MovementClass = MovementClass.new(Player, self.StateManager)
	Simulation:RegisterPlayer(Player, self.MovementClass)
end

function CombatClasses:OnCharacterAdded(character)
	self.GUI:SetCombatUIEnabled(true)

	local Humanoid = character:WaitForChild("Humanoid")
	Humanoid.Died:Connect(function()
		self:OnCharacterRemoved()
	end)
end

function CombatClasses:OnCharacterRemoved()
	-- Character cleanup must not be blocked by the current combat action.
	self.StateManager:SetState("WeaponState", "IDLE")

	for _, controller in pairs(self.WeaponLoadout) do
		if controller.Equipped then
			controller:OnUnequip()
		end
	end

	self.GUI:SetCombatUIEnabled(false)
end

function CombatClasses:Init()
	self:CreateMovementClass()

	PacketSettings.Combat.Weapon.AmmoUpdate.listen(function(data)
		local controller = self.WeaponLoadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			controller:SetAmmo(data.Ammo, data.ReserveAmmo)
		end
	end)

	PacketSettings.Combat.Weapon.EquipResult.listen(function(data)
		local controller = self.WeaponLoadout[data.SlotName]

		if controller and controller.SlotName == data.SlotName then
			if data.Accepted then
				if data.Action == "Equip" then
					controller:OnEquip()
				elseif data.Action == "UnEquip" then
					controller:OnUnequip()
				end
			else
				warn("Equip/Unequip action was not accepted for slot:", data.SlotName)
			end
		end
	end)

	CAS:BindAction("EquipOrUnequipKinetic", function(_, state)
		if state == Enum.UserInputState.Begin then
			if self.WeaponLoadout.KineticSlot then
				self.WeaponLoadout.KineticSlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.One)

	CAS:BindAction("EquipOrUnequipEnergy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if self.WeaponLoadout.EnergySlot then
				self.WeaponLoadout.EnergySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Two)

	CAS:BindAction("EquipOrUnequipHeavy", function(_, state)
		if state == Enum.UserInputState.Begin then
			if self.WeaponLoadout.HeavySlot then
				self.WeaponLoadout.HeavySlot:EquipOrUnequip()
			end
		end
	end, false, Enum.KeyCode.Three)
end

return CombatClasses
