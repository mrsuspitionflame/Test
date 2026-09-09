local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Combat = Server:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")

local SharedCombat = Shared:WaitForChild("Combat")
local MovementClass = require(SharedCombat:WaitForChild("Classes"):WaitForChild("MovementClass"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local SimulationFolder = Shared:WaitForChild("Simulation")

local WeaponClass = require(Classes:WaitForChild("WeaponClass"))
local AbilityClass = require(Classes:WaitForChild("AbilityClass"))
local StateManager = require(Utility:WaitForChild("StateManager"))
local Simulation = require(SimulationFolder:WaitForChild("Simulation"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local CombatClasses = {}

CombatClasses.__index = CombatClasses

function CombatClasses.new(Player)
	local self = setmetatable({}, CombatClasses)

	self.Trove = Trove.new()

	self.StateManager = StateManager.new()

	self.WeaponClasses = {}
	self.AbilityClass = nil

	self.StoredSlot = nil
	self.Character = nil
	self.Destroyed = false

	self.Player = Player

	self:Init()
	return self
end

function CombatClasses:Step(dt)
	for _, WeaponClass in pairs(self.WeaponClasses) do
		WeaponClass:Step(dt)
	end
	self.AbilityClass:Step(dt)
	self.MovementClass:Step(dt)
end

function CombatClasses:GetEquippedWeaponClass()
	for _, weaponClass in pairs(self.WeaponClasses) do
		if weaponClass.Equipped then
			return weaponClass
		end
	end

	return nil
end

function CombatClasses:CancelState(stateType, state)
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

function CombatClasses:CreateMovementClass()
	self.MovementClass = MovementClass.new(self.Player, self.StateManager)
	Simulation:RegisterPlayer(self.Player, self.MovementClass)
end

function CombatClasses:UnequipWeapons()
	self.StateManager:SetState("WeaponState", "IDLE")

	local EquippedWeaponClass = self:GetEquippedWeaponClass()
	if EquippedWeaponClass then
		EquippedWeaponClass:OnUnequip()
	end
end

function CombatClasses:Init()
	self:CreateMovementClass()
	self:CreateWeaponClasses()
	self:CreateAbilityClass()

	self.CharacterTrove = self.Trove:Extend()

	self.Trove:Connect(self.Player.CharacterAdded, function(character)
		self:OnCharacterAdded(character)
	end)

	self.Trove:Connect(self.Player.CharacterRemoving, function(character)
		self:OnCharacterRemoving(character)
	end)

	if self.Player.Character then
		local character = self.Player.Character
		self.Trove:Add(task.spawn(function()
			self:OnCharacterAdded(character)
		end))
	end
end

function CombatClasses:CreateWeaponClasses()
	for _, SlotName in ipairs(Slots) do
		self.WeaponClasses[SlotName] = WeaponClass.new(self.Player, "HandCannon", SlotName, self.StateManager, self)
	end
end

function CombatClasses:CreateAbilityClass()
	local AbilityInfo = { Grenade = "SolarGrenade" }
	self.AbilityClass = AbilityClass.new(self.Player, AbilityInfo, self.StateManager, self)
end

function CombatClasses:OnCharacterAdded(character)
	if self.Destroyed or self.Player.Character ~= character then
		return
	end

	if self.Character then
		self:OnCharacterRemoving(self.Character)
	end
	self.CharacterTrove:Clean()
	self.Character = character

	self:SetupCharacter(character)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or self.Destroyed or self.Character ~= character then
		return
	end

	self.CharacterTrove:Connect(humanoid.Died, function()
		self:OnCharacterRemoving(character)
	end)
	if humanoid.Health <= 0 then
		self:OnCharacterRemoving(character)
	end
end

function CombatClasses:AddAttachment(parent, name, position, orientation)
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

function CombatClasses:SetupCharacter(character)
	local RightHand = character:FindFirstChild("RightHand") or character:WaitForChild("Right Arm")

	local LeftHand = character:FindFirstChild("LeftHand") or character:WaitForChild("Left Arm")

	self:AddAttachment(RightHand, "WeaponGripAttachment", Vector3.new(0, -0.65, -0.5), Vector3.new(0, 0, 0))

	self:AddAttachment(LeftHand, "AbilityGripAttachment", Vector3.new(0, -1.2, 0), Vector3.new(0, 0, 0))
end

function CombatClasses:OnCharacterRemoving(character)
	if not self.Character or (character and self.Character ~= character) then
		return
	end

	self.Character = nil
	self.StoredSlot = nil
	self.CharacterTrove:Clean()
	self.AbilityClass:OnCharacterRemoved()
	self:UnequipWeapons()
end

function CombatClasses:TemporarilyUnequipWeapon()
	if self.Destroyed or not self.Character then
		return false
	end

	local weaponClass = self:GetEquippedWeaponClass()
	if not weaponClass then
		return false
	end

	if weaponClass:OnUnequip() then
		self.StoredSlot = weaponClass.SlotName
		return true
	end

	return false
end

function CombatClasses:ReEquipStoredWeapon()
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
	if not weaponClass or weaponClass.Equipped then
		return false
	end

	self.StoredSlot = nil
	weaponClass:OnEquip()
	return true
end

function CombatClasses:DestroyCombatClasses()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:OnCharacterRemoving()
	Simulation:UnregisterPlayer(self.Player)
	
	self.Trove:Destroy()
	for _, weaponClass in pairs(self.WeaponClasses) do
		weaponClass:Destroy()
	end
	self.AbilityClass:Destroy()
	self.MovementClass:Destroy()
end

return CombatClasses
