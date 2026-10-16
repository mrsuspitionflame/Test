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
local Handlers = Combat:WaitForChild("Handlers")

local AbilityHandler = require(Handlers:WaitForChild("AbilityHandler"))
local WeaponHandler = require(Handlers:WaitForChild("WeaponHandler"))
local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))
local CameraController = require(Controllers:WaitForChild("CameraController"))
local GUIController = require(Controllers:WaitForChild("GUIController"))
local StateManager = require(Utility:WaitForChild("StateManager"))

local Simulations = Shared:WaitForChild("Simulations")
local MovementSimulation = require(Simulations:WaitForChild("MovementSimulation"))

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))

local CombatHandler = {}

CombatHandler.__index = CombatHandler

function CombatHandler.new()
	local self = setmetatable({}, CombatHandler)
	-- Tracks character event connections, weapon handler troves, the ability handler, and child troves.
	self.Trove = Trove.new()

	self.EquippedSlot = nil
	self.WeaponHandlers = {}

	self.StateManager = StateManager.new()

	-- Tracks the equipped weapon's viewmodel, animations, motor, render loops, zoom, and camera resets.
	self.WeaponTrove = self.Trove:Extend()
	-- Tracks the ability viewmodel and animations; its child trove manages the render loop while visible.
	self.AbilityTrove = self.Trove:Extend()

	self.GUIController = GUIController.new()
	self.CameraController = CameraController.new(self)
	self.ViewModelController = ViewModelController.new(self)

	self:Init()
	return self
end

function CombatHandler:GetEquippedWeapon()
	return self.WeaponHandlers[self.EquippedSlot]
end

function CombatHandler:CancelState(stateType, state)
	if self.StateManager:GetState(stateType) ~= state then
		return false
	end

	if stateType == "MovementState" then
		if state == "SPRINTING" then
			self.MovementClass.Sprint:StopSprint()
		elseif state == "SLIDING" then
			self.MovementClass.Slide:StopSlide()
		else
			return false
		end
		return true
	end

	local weaponHandler = self:GetEquippedWeapon()
	if not weaponHandler then
		return false
	end

	if stateType == "WeaponState" then
		if state == "RELOADING" then
			weaponHandler.Reloading:Cancelled()
		elseif state == "FIRING" then
			weaponHandler.Firing:Cancelled()
		else
			return false
		end
	elseif stateType == "AimState" and state == "AIMING" then
		weaponHandler.Aiming:Cancelled()
	else
		return false
	end

	return true
end

function CombatHandler:CancelStates(actionType, action)
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

function CombatHandler:CreateWeaponHandler(data)
	if not self.WeaponHandlers then
		self.WeaponHandlers = {}
	end

	if self.WeaponHandlers[data.SlotName] == nil then
		self.WeaponHandlers[data.SlotName] = WeaponHandler.new(
			data.WeaponName,
			data.SlotName,
			self.ViewModelController,
			self.StateManager,
			self.GUIController,
			self
		)
	end
end

function CombatHandler:CreateAbilityHandler(data)
	if self.Ability then
		return
	end
	self.Ability = self.Trove:Add(
		AbilityHandler.new(data, self.ViewModelController, self.StateManager, self.GUIController, self)
	)
end

function CombatHandler:CreateMovementClass()
	if self.MovementClass then
		return
	end
	self.MovementClass = MovementClass.new(Player, self.StateManager, self)
	MovementSimulation:BindPlayerMovementClass(Player, self.MovementClass)
end

function CombatHandler:OnCharacterAdded(character)
	if Player.Character ~= character or self.Character == character then
		return
	end
	self:OnCharacterRemoving()
	self.Character = character
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or self.Character ~= character or Player.Character ~= character then
		return
	end
	if humanoid.Health <= 0 then
		self:OnCharacterRemoving(character)
		return
	end
	self.Humanoid = humanoid
	self.Root = root
	self.StateManager:BindRoot(root)
	local runService = game:GetService("RunService")
	runService:SetPredictionMode(root, Enum.PredictionMode.On)
	runService:SetPredictionMode(humanoid, Enum.PredictionMode.On)
	self.DeathConnection = humanoid.Died:Connect(function()
		self:OnCharacterRemoving(character)
	end)
	self.GUIController:SetCombatUIEnabled(true)
	self.MovementClass:OnCharacterAdded()
end

function CombatHandler:OnCharacterRemoving(character)
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
	for _, handler in pairs(self.WeaponHandlers) do
		if self.EquippedSlot == handler.SlotName then
			handler.Equipping:OnUnequip()
		end
	end
	self.MovementClass:OnCharacterRemoving()
	self.StateManager:UnbindRoot()
	self.Humanoid = nil
	self.Root = nil
	self.GUIController:SetCombatUIEnabled(false)
end

function CombatHandler:Init()
	if self.Initialized then
		return
	end
	self.Initialized = true

	self:CreateMovementClass()

	self.Trove:Connect(Player.CharacterRemoving, function(character)
		self:OnCharacterRemoving(character)
	end)
	self.Trove:Connect(Player.CharacterAdded, function(character)
		self:OnCharacterAdded(character)
	end)

	if Player.Character then
		task.spawn(self.OnCharacterAdded, self, Player.Character)
	end
end

return CombatHandler
