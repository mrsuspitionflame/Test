local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local Handlers = script:FindFirstAncestor("Handlers")

local WeaponHandler = require(Handlers:WaitForChild("WeaponHandler"))
local AbilityHandler = require(Handlers:WaitForChild("AbilityHandler"))
local MovementHandler = require(Handlers:WaitForChild("MovementHandler"))

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

	self:Init(data)
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

function CombatHandler:CreateHandlers(data)
	self.WeaponHandlers = {}

	for _, SlotName in ipairs(Slots) do
		self.WeaponHandlers[SlotName] =
			self.Trove:Add(WeaponHandler.new(self.Player, "HandCannon", SlotName, self.StateManager, self))
	end

	self.AbilityHandler = self.Trove:Add(AbilityHandler.new(data))
	self.MovementHandler = self.Trove:Add(MovementHandler.new())
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
	for _, weaponHandler in pairs(self.WeaponHandlers) do
		if weaponHandler then
			weaponHandler:OnCharacterRemoving()
		end
	end
	self.AbilityHandler:OnCharacterRemoving()
	self.MovementHandler:OnCharacterRemoving()
	self.StateManager:OnCharacterRemoving()
	self.Humanoid = nil
	self.Root = nil
end

function CombatHandler:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true

	self:OnCharacterRemoving()

	self.Trove:Destroy()

	for _, weaponHandler in pairs(self.WeaponHandlers) do
		if weaponHandler then
			weaponHandler = nil
		end
	end
	self.WeaponHandlers = nil
	self.AbilityHandler = nil
	self.MovementHandler = nil
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

	self.Trove:Add(RS.RenderStepped:Connect(function(dt)
		self:Step(dt)
	end))
end

return CombatHandler
