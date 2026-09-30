local Combat = script:FindFirstAncestor("Combat")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Movement = Shared:WaitForChild("Movement")
local MovementClass = require(Movement:WaitForChild("MovementClass"))

local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Controllers = Combat:WaitForChild("Controllers")

local AbilityController = require(Controllers:WaitForChild("AbilityController"))
local WeaponController = require(Controllers:WaitForChild("WeaponController"))
local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))
local GUIController = require(Controllers:WaitForChild("GUIController"))
local StateManager = require(Utility:WaitForChild("StateManager"))

local Simulations = Shared:WaitForChild("Simulations")
local Simulation = require(Simulations:WaitForChild("Simulation"))


local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local CombatController = {}

CombatController.__index = CombatController

function CombatController.new()
	local self = setmetatable({}, CombatController)
	self.Trove = Trove.new()

	self.EquippedSlot = nil

	self.WeaponLoadout = {
		KineticSlot = nil,
		EnergySlot = nil,
		HeavySlot = nil,
	}

	self.GUIController = GUIController.new()
	self.StateManager = StateManager.new()
	self.ViewModelController = ViewModelController.new()

	self:Init()
	return self
end

function CombatController:GetEquippedWeapon()
	return self.WeaponLoadout[self.EquippedSlot]
end

function CombatController:CancelState(stateType, state)
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

function CombatController:CancelStates(actionType, action)
	local category = StateSettings[actionType]
	local actionSettings = category and category[action]
	if not actionSettings then
		return false
	end
	for stateType, states in pairs(actionSettings.CancelStates) do
		for _, state in ipairs(states) do
			self:CancelState(stateType, state)
		end
	end
	return true
end

function CombatController:CreateWeaponController(data)
	if self.WeaponLoadout[data.SlotName] == nil then
		self.WeaponLoadout[data.SlotName] = WeaponController.new(
			data.WeaponName,
			data.SlotName,
			self.ViewModelController,
			self.StateManager,
			self.GUIController,
			self
		)
	end
end

function CombatController:CreateAbilityController(data)
	if self.Ability then
		return
	end
	self.Ability = self.Trove:Add(AbilityController.new(data, self.AnimationController, self.StateManager, self.GUIController, self))
end

function CombatController:CreateMovementClass()
	if self.MovementClass then
		return
	end
	self.MovementClass = MovementClass.new(Player, self.StateManager, self)
	Simulation:RegisterPlayer(Player, self.MovementClass)
end

function CombatController:OnCharacterAdded(character)
	if Player.Character ~= character or self.Character == character then
		return
	end
	self:OnCharacterRemoved()
	self.Character = character
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or self.Character ~= character or Player.Character ~= character then
		return
	end
	if humanoid.Health <= 0 then
		self:OnCharacterRemoved(character)
		return
	end
	self.Humanoid = humanoid
	self.Root = root
	self.StateManager:BindRoot(root)
	local runService = game:GetService("RunService")
	runService:SetPredictionMode(root, Enum.PredictionMode.On)
	runService:SetPredictionMode(humanoid, Enum.PredictionMode.On)
	self.DeathConnection = humanoid.Died:Connect(function()
		self:OnCharacterRemoved(character)
	end)
	self.GUI:SetCombatUIEnabled(true)
	self.MovementClass:OnCharacterAdded()
end

function CombatController:OnCharacterRemoved(character)
	if not self.Character or (character and self.Character ~= character) then
		return
	end
	self.Character = nil
	if self.DeathConnection then
		self.DeathConnection:Disconnect()
		self.DeathConnection = nil
	end
	-- Character cleanup must not be blocked by the current combat action.
	self.StateManager:SetState("WeaponState", "IDLE")
	for _, controller in pairs(self.WeaponLoadout) do
		if self.EquippedSlot == controller.SlotName then
			controller.Equipping:OnUnequip()
		end
	end
	self.MovementClass:OnCharacterRemoving()
	self.StateManager:UnbindRoot()
	self.Humanoid = nil
	self.Root = nil
	self.GUI:SetCombatUIEnabled(false)
end

function CombatController:Init()
	if self.Initialized then
		return
	end
	self.Initialized = true

	self:CreateMovementClass()

	self.Trove:Connect(Player.CharacterRemoving, function(character)
		self:OnCharacterRemoved(character)
	end)
	self.Trove:Connect(Player.CharacterAdded, function(character)
		self:OnCharacterAdded(character)
	end)

	if Player.Character then
		task.spawn(self.OnCharacterAdded, self, Player.Character)
	end
end

return CombatController
