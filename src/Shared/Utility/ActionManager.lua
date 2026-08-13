local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local ActionSettings = require(Settings:WaitForChild("ActionSettings"))


local ActionController = {}

ActionController.__index = ActionController

function ActionController.new()
    local self = setmetatable({}, ActionController)

    self.WeaponState = "Idle"
    self.AbilityState = "Idle"
    self.MovementState = "Idle"

    return self
end

function ActionController:SetState(stateType, newState)
    if stateType == "WeaponState" then
        self.WeaponState = newState
    elseif stateType == "AbilityState" then
        self.AbilityState = newState
    elseif stateType == "MovementState" then
        self.MovementState = newState
    else
        error("Invalid state type: " .. tostring(stateType))
    end
    print("State changed: " .. stateType .. " -> " .. newState)
end

function ActionController:GetState(stateType)
    if stateType == "WeaponState" then
        return self.WeaponState
    elseif stateType == "AbilityState" then
        return self.AbilityState
    elseif stateType == "MovementState" then
        return self.MovementState
    else
        error("Invalid state type: " .. tostring(stateType))
    end
end

function ActionController:TryAction(actionType, action)
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

function ActionController:CancelAction(stateType, newState)
    
end

return ActionController
