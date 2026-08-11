local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Client = StarterPlayerScripts:WaitForChild("Client")
local Controllers = Client:WaitForChild("Controllers")
local OtherControllers = Controllers:WaitForChild("OtherControllers")

local ViewModelController = require(OtherControllers:WaitForChild("ViewModelController"))

local AnimationController = {}

function AnimationController.new()
    local self = setmetatable({}, { __index = AnimationController })

    self.ViewModelController = ViewModelController.new()

    return self
end

function AnimationController:GetController(ControllerName)
    if ControllerName == "ViewModel" then
        return self.ViewModelController
    end
    return
end

function AnimationController:OnEquip(WeaponName: string)
    self.ViewModelController:OnEquip(WeaponName)
    --Other animations will be added later
end

function AnimationController:OnUnequip()
    self.ViewModelController:OnUnequip()
end

function AnimationController:GetAnimation(AnimationType: string, AnimationName: string)
    if AnimationType == "ViewModel" then
        return self.ViewModelController:GetAnimation(AnimationName)
    end
    return
end

return AnimationController