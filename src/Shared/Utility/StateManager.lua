local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages:WaitForChild("Signal"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local StateManager = {}

local States = table.freeze({
	"WeaponState",
	"AbilityState",
	"MovementState",
	"EquippedState",
	"AimState"
})

StateManager.__index = StateManager

function StateManager.new(root)
	local self = setmetatable({}, StateManager)
	self.Root = root

	self.WeaponState = root:SetAttribute("WeaponState", "UNEQUIPPED")
	self.EquippedState = root:SetAttribute("EquippedState", "UNEQUIPPED")
	self.AbilityState = root:SetAttribute("AbilityState", "IDLE")
	self.MovementState = root:SetAttribute("MovementState", "IDLE")
	self.AimState = root:SetAttribute("AimState", "IDLE")

	return self
end

function StateManager:SetState(StateType, NewState)
	local OldState = self:GetState(StateType)

	if OldState == NewState then
		return
	end

	for _, stateType in ipairs(States) do
		if StateType == stateType then
			self.Root:SetAttribute(StateType, NewState)
			--print("State changed: " .. StateType .. " -> " .. NewState)
			return
		end
	end

	error("Invalid state type: " .. tostring(StateType))
end

function StateManager:GetState(StateType)
	for _, stateType in ipairs(States) do
		if StateType == stateType then
			return self.Root:GetAttribute(stateType)
		end
	end
	error("Invalid state type: " .. tostring(StateType))
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

return StateManager
