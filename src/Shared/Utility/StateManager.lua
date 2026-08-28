local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages:WaitForChild("Signal"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local StateManager = {}

StateManager.__index = StateManager

function StateManager.new()
	local self = setmetatable({}, StateManager)

	self.WeaponState = "UNEQUIPPED"
	self.EquippedState = "UNEQUIPPED"
	self.AbilityState = "IDLE"
	self.MovementState = "IDLE"
	self.AimState = "IDLE"

	self.CancelStateSignal = Signal.new()
	self.ReEquipWeaponSignal = Signal.new()
	return self
end

function StateManager:SetState(stateType, newState)
	if stateType == "WeaponState" then
		self.WeaponState = newState
	elseif stateType == "AbilityState" then
		self.AbilityState = newState
	elseif stateType == "MovementState" then
		self.MovementState = newState
	elseif stateType == "AimState" then
		self.AimState = newState
	elseif stateType == "EquippedState" then
		self.EquippedState = newState
	else
		error("Invalid state type: " .. tostring(stateType))
	end
	print("State changed: " .. stateType .. " -> " .. newState)
end

function StateManager:GetState(stateType)
	if stateType == "WeaponState" then
		return self.WeaponState
	elseif stateType == "AbilityState" then
		return self.AbilityState
	elseif stateType == "MovementState" then
		return self.MovementState
	elseif stateType == "AimState" then
		return self.AimState
	elseif stateType == "EquippedState" then
		return self.EquippedState
	else
		error("Invalid state type: " .. tostring(stateType))
	end
end

function StateManager:TryAction(actionType, action)
	local stateSettings = StateSettings[actionType][action]

	for stateType, blockedStates in pairs(stateSettings.BlockedStates) do
		local currentState = self:GetState(stateType)

		for _, blockedState in ipairs(blockedStates) do
			if currentState == blockedState then
				return false
			end
		end
	end

	return true
end

function StateManager:PerformAction(actionType, action)
	local stateSettings = StateSettings[actionType][action]

	for stateType, cancelStates in pairs(stateSettings.CancelStates) do
		local currentState = self:GetState(stateType)

		for _, cancelledState in ipairs(cancelStates) do
			if currentState == cancelledState then
				self:CancelState(stateType, cancelledState)
			end
		end
	end
end

function StateManager:CancelState(stateType, cancelledState)
	self.CancelStateSignal:Fire(stateType, cancelledState)
end

function StateManager:ReEquipWeapon()
	self.ReEquipWeaponSignal:Fire()
end

return StateManager
