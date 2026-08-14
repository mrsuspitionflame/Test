local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages:WaitForChild("Signal"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local ActionSettings = require(Settings:WaitForChild("ActionSettings"))



local ActionManager = {}

ActionManager.__index = ActionManager

function ActionManager.new()
    local self = setmetatable({}, ActionManager)

    self.WeaponState = "IDLE"
    self.AbilityState = "IDLE"
    self.MovementState = "IDLE"
    self.AimState = "IDLE"

    self.CancelStateSignal = Signal.new()
    return self
end

function ActionManager:SetState(stateType, newState)
    if stateType == "WeaponState" then
        self.WeaponState = newState
    elseif stateType == "AbilityState" then
        self.AbilityState = newState
    elseif stateType == "MovementState" then
        self.MovementState = newState
    elseif stateType == "AimState" then
        self.AimState = newState
    else
        error("Invalid state type: " .. tostring(stateType))
    end
    print("State changed: " .. stateType .. " -> " .. newState)
end

function ActionManager:GetState(stateType)
    if stateType == "WeaponState" then
        return self.WeaponState
    elseif stateType == "AbilityState" then
        return self.AbilityState
    elseif stateType == "MovementState" then
        return self.MovementState
    elseif stateType == "AimState" then
        return self.AimState
    else
        error("Invalid state type: " .. tostring(stateType))
    end
end

function ActionManager:TryAction(actionType, action)
    local actionSettings = ActionSettings[actionType][action]

    for stateType, blockedStates in pairs(actionSettings.BlockedStates) do
        local currentState = self:GetState(stateType)

        for _, blockedState in ipairs(blockedStates) do
            if currentState == blockedState then
                return false
            end
        end
    end

    return true
end

function ActionManager:PerformAction(actionType, action)
    local actionSettings = ActionSettings[actionType][action]
    for stateType, cancelStates in pairs(actionSettings.CancelStates) do
        local currentState = self:GetState(stateType)

        for _, cancelledState in ipairs(cancelStates) do
            if currentState == cancelledState then
                self:CancelState(stateType, cancelledState)
            end
        end
    end
end

function ActionManager:CancelState(stateType, cancelledState)
    self.CancelStateSignal:Fire(stateType, cancelledState)
end

return ActionManager
