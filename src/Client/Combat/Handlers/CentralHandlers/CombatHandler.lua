local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local CentralHandlers = script:FindFirstAncestor("CentralHandlers")

local WeaponHandler = require(CentralHandlers:WaitForChild("WeaponHandler"))
local AbilityHandler = require(CentralHandlers:WaitForChild("AbilityHandler"))
local MovementHandler = require(CentralHandlers:WaitForChild("MovementHandler"))


local Slots = table.freeze({
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
})

local CombatHandler = {}

CombatHandler.__index = CombatHandler

function CombatHandler.new(player, data)
	local self = setmetatable({}, CombatHandler)

	self.EquippedWeaponHandler = nil

	self.Player = player

	self.Trove = Trove.new()

	self:Init()
	return self
end

function CombatHandler:CanStep()
	return not self.Destroyed and self.Character ~= nil
end

function CombatHandler:Step(dt)
	if not self:CanStep() then
		return
	end

	for _, weaponHandler in pairs(self.WeaponHandlers) do
		if weaponHandler then
			weaponHandler:Step(dt)
		end
	end
	if self.AbilityHandler then
		self.AbilityHandler:Step(dt)
	end

	if self.MovementHandler then
		self.MovementHandler:Step(dt)
	end
end

function CombatHandler:GetEquippedWeaponHandler()
	return self.EquippedWeaponHandler
end

function CombatHandler:UnequipWeapons()
	self.StateManager:SetState("WeaponState", "IDLE")

	local EquippedWeaponHandler = self:GetEquippedWeaponHandler()
	if EquippedWeaponHandler then
		EquippedWeaponHandler:OnUnequip()
	end
end

function CombatHandler:Init(data)
	self:CreateHandlers(data)

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

function CombatHandler:CreateHandlers(data)
	self.WeaponHandlers = {}

	self:CreateWeaponClasses(data)
	self:CreateAbilityClass(data)
	self:CreateMovementClass()
end

function CombatHandler:CreateWeaponClasses(data)
	for _, SlotName in ipairs(Slots) do
		self.WeaponHandlers[SlotName] =
			self.Trove:Add(WeaponHandler.new(self.Player, "HandCannon", SlotName, self.StateManager, self))
	end
end

function CombatHandler:CreateAbilityClass(data)
	local AbilityInfo = { Grenade = "SolarGrenade" }
	self.AbilityHandler = self.Trove:Add(AbilityHandler.new(data))
end

function CombatHandler:CreateMovementClass()
	self.MovementHandler = self.Trove:Add(MovementHandler.new(self.Player, self.StateManager, self))
end

function CombatHandler:OnCharacterAdded(character)
	if self.Destroyed or self.Player.Character ~= character or self.Character == character then
		return
	end

	if self.Character then
		self:OnCharacterRemoving(character)
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

	self.CharacterTrove:Connect(humanoid.Died, function()
		self:OnCharacterRemoving(character)
	end)
	self.MovementHandler:OnCharacterAdded()
end

function CombatHandler:OnCharacterRemoving(character)
	if not self.Character or (character and self.Character ~= character) then
		return
	end

	self.Character = nil
	self.StoredSlot = nil
	self.CharacterTrove:Clean()
	self.AbilityHandler:OnCharacterRemoving()
	self:UnequipWeapons()
	self.MovementHandler:OnCharacterRemoving()
	self.StateManager:OnCharacterRemoving()
	self.Humanoid = nil
	self.Root = nil
end


function CombatHandler:SetupInput()
	self:GetEquippedWeaponHandler():SetupInput()
	-- Add other setups later
end

function CombatHandler:TemporarilyUnequipWeapon()
	if self.Destroyed or not self.Character then
		return false
	end

	local weaponHandler = self:GetEquippedWeaponHandler()
	if not weaponHandler then
		return false
	end

	if weaponHandler:OnUnequip() then
		self.StoredSlot = weaponHandler.SlotName
		return true
	end

	return false
end

function CombatHandler:ReEquipStoredWeapon()
	local character = self.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if self.Destroyed or character ~= self.Player.Character or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local slotName = self.StoredSlot
	if not slotName then
		return false
	end

	local weaponHandler = self.WeaponHandlers[slotName]
	if not weaponHandler or self.EquippedWeaponHandler == weaponHandler then
		return false
	end

	self.StoredSlot = nil
	weaponHandler:OnEquip()
	return true
end

function CombatHandler:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:OnCharacterRemoving()

	self.Trove:Destroy()

	-- Components may use StateManager during destruction, so clean it last.
	self.StateManager:Destroy()

	table.clear(self.WeaponClasses)
	self.AbilityHandler = nil
	self.MovementHandler = nil
end

return CombatHandler
