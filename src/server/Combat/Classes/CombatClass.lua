local Combat = script:FindFirstAncestor("Combat")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Movement = Shared:WaitForChild("Movement")
local MovementClass = require(Movement:WaitForChild("MovementClass"))

local Utility = Shared:WaitForChild("Utility")

local Classes = Combat:WaitForChild("Classes")

local WeaponClass = require(Classes:WaitForChild("WeaponClass"))
local AbilityClass = require(Classes:WaitForChild("AbilityClass"))
local StateManager = require(Utility:WaitForChild("StateManager"))

local Simulations = Shared:WaitForChild("Simulations")
local MovementSimulation = require(Simulations:WaitForChild("MovementSimulation"))

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local CombatClass = {}

CombatClass.__index = CombatClass

function CombatClass.new(player)
	local self = setmetatable({}, CombatClass)
	self.Trove = Trove.new()

	self.EquippedSlot = nil
	self.WeaponClasses = {}

	self.Player = player

	self.StateManager = StateManager.new()

	self.StoredSlot = nil
	self.Character = nil
	self.Destroyed = false

	self:Init()
	return self
end

function CombatClass:GetEquippedWeaponClass()
	return self.WeaponClasses[self.EquippedSlot]
end

function CombatClass:CancelState(stateType, state)
	if self.StateManager:GetState(stateType) ~= state then
		return false
	end

	local weaponClass = self:GetEquippedWeaponClass()
	if not weaponClass then
		return false
	end

	if stateType == "WeaponState" then
		if state == "RELOADING" then
			weaponClass.Reloading:Cancelled()
		elseif state == "FIRING" then
			weaponClass.Firing:Cancelled()
		else
			return false
		end
	elseif stateType == "AimState" and state == "AIMING" then
		weaponClass.Aiming:Cancelled()
	else
		return false
	end

	return true
end

function CombatClass:CreateWeaponClasses()
	for _, SlotName in ipairs(Slots) do
		self.WeaponClasses[SlotName] =
			self.Trove:Add(WeaponClass.new(self.Player, "HandCannon", SlotName, self.StateManager, self))
	end
end

function CombatClass:CreateAbilityClass()
	local AbilityInfo = { Grenade = "SolarGrenade" }
	self.AbilityClass = self.Trove:Add(AbilityClass.new(self.Player, AbilityInfo, self.StateManager, self))
end

function CombatClass:CreateMovementClass()
	self.MovementClass = MovementClass.new(self.Player, self.StateManager, self)
end

function CombatClass:CanStep()
	return not self.Destroyed and self.Character ~= nil
end

function CombatClass:Step(dt)
	if not self:CanStep() then
		return
	end

	-- Only movement participates in Roblox's simulation.
	if self.MovementClass then
		self.MovementClass:Step(dt)
	end
end

function CombatClass:OnCharacterAdded(character)
	if self.Destroyed or self.Player.Character ~= character or self.Character == character then
		return
	end

	if self.Character then
		self:OnCharacterRemoving(self.Character)
	end

	self.CharacterTrove:Clean()
	self.Character = character

	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not humanoid or self.Destroyed or self.Character ~= character then
		return
	end

	if humanoid.Health <= 0 then
		self:OnCharacterRemoving(character)
		return
	end
	self.Humanoid = humanoid
	self.Root = root
	self.StateManager:BindRoot(root)

	self.CharacterTrove:Connect(humanoid.Died, function()
		self:OnCharacterRemoving(character)
	end)
	self.MovementClass:OnCharacterAdded()
	if self.Character == character then
		self:SetupCharacter(character)
	end
end

function CombatClass:OnCharacterRemoving(character)
	if not self.Character or (character and self.Character ~= character) then
		return
	end

	self.Character = nil
	self.StoredSlot = nil
	self.CharacterTrove:Clean()
	self.AbilityClass:OnCharacterRemoving()
	self:UnequipWeapons()
	self.MovementClass:OnCharacterRemoving()
	self.StateManager:UnbindRoot()
	self.Humanoid = nil
	self.Root = nil
end

function CombatClass:UnequipWeapons()
	self.StateManager:SetState("WeaponState", "IDLE")

	local EquippedWeaponClass = self:GetEquippedWeaponClass()
	if EquippedWeaponClass then
		EquippedWeaponClass.Equipping:OnUnequip()
	end
end

function CombatClass:AddAttachment(parent, name, position, orientation)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = position or Vector3.zero
	attachment.Orientation = orientation or Vector3.zero
	attachment.Parent = parent

	return attachment
end

function CombatClass:SetupCharacter(character)
	local RightHand = character:FindFirstChild("RightHand") or character:WaitForChild("Right Arm")

	local LeftHand = character:FindFirstChild("LeftHand") or character:WaitForChild("Left Arm")

	self:AddAttachment(RightHand, "WeaponGripAttachment", Vector3.new(0, -0.65, -0.5), Vector3.new(0, 0, 0))

	self:AddAttachment(LeftHand, "AbilityGripAttachment", Vector3.new(0, -1.2, 0), Vector3.new(0, 0, 0))
end

function CombatClass:TemporarilyUnequipWeapon()
	if self.Destroyed or not self.Character then
		return false
	end

	local weaponClass = self:GetEquippedWeaponClass()
	if not weaponClass then
		return false
	end

	if weaponClass.Equipping:OnUnequip() then
		self.StoredSlot = weaponClass.SlotName
		return true
	end

	return false
end

function CombatClass:ReEquipStoredWeapon()
	local character = self.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if self.Destroyed or character ~= self.Player.Character or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local slotName = self.StoredSlot
	if not slotName then
		return false
	end

	local weaponClass = self.WeaponClasses[slotName]
	if not weaponClass or self.EquippedSlot == slotName then
		return false
	end

	self.StoredSlot = nil
	weaponClass.Equipping:OnEquip()
	return true
end

function CombatClass:Init()
	self:CreateMovementClass()
	self:CreateWeaponClasses()
	self:CreateAbilityClass()

	MovementSimulation:BindPlayerMovementClass(self.Player, self.MovementClass)

	self.CharacterTrove = self.Trove:Extend()

	self.Trove:Connect(self.Player.CharacterAdded, function(character)
		self:OnCharacterAdded(character)
	end)

	self.Trove:Connect(self.Player.CharacterRemoving, function(character)
		self:OnCharacterRemoving(character)
	end)

	local character = self.Player.Character

	if character then
		self.Trove:Add(task.spawn(function()
			self:OnCharacterAdded(character)
		end))
	end
end

function CombatClass:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:OnCharacterRemoving()

	MovementSimulation:UnbindPlayerMovementClass(self.Player)

	self.Trove:Destroy()

	-- Components may use StateManager during destruction, so clean it last.
	self.StateManager:Destroy()

	table.clear(self.WeaponClasses)
	self.AbilityClass = nil
	self.MovementClass = nil
end

return CombatClass
