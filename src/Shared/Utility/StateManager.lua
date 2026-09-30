local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local RS = game:GetService("RunService")

local StateManager = {}

local States = table.freeze({ -- State types and their default states for each state type
	WeaponState = "UNEQUIPPED",
	AbilityState = "IDLE",
	MovementState = "IDLE",
	AimState = "NOT_AIMING",
})

StateManager.__index = StateManager

function StateManager.new()
	local self = setmetatable({}, StateManager)
	self.Trove = Trove.new()
	return self
end

function StateManager:Destroy()
	self:UnbindRoot()
	self.Trove:Destroy()
end

function StateManager:UnbindRoot()
	self.Root = nil
end

function StateManager:BindRoot(root)
	self:UnbindRoot()
	self.Root = root

	for stateType, defaultState in pairs(States) do
		self.Root:SetAttribute(stateType, defaultState)
	end
end

function StateManager:SetState(stateType, newState)
	local OldState = self:GetState(stateType)

	if not self.Root or OldState == newState then
		return
	end

	for validStateType, _ in pairs(States) do
		if stateType == validStateType then
			self.Root:SetAttribute(stateType, newState)
			--print("State changed: " .. stateType .. " -> " .. newState)
			return
		end
	end

	error("Invalid state type: " .. tostring(stateType))
end

function StateManager:GetState(stateType)
	for validStateType, _ in pairs(States) do
		if stateType == validStateType then
			if self.Root then
				return self.Root:GetAttribute(stateType)
			end
			return States[stateType]
		end
	end
	error("Invalid state type: " .. tostring(stateType))
end

function StateManager:TryAction(actionType, action)
	if not self.Root then
		return false
	end
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

return StateManager
