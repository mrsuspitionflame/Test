local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Combat = Server:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")

local ViewModelClass = require(Classes:WaitForChild("ViewModelClass"))

local AnimationClass = {}

function AnimationClass.new(player)
    local self = setmetatable({}, { __index = AnimationClass })

    self.ViewModelClass = ViewModelClass.new(player)

    return self
end

function AnimationClass:GetClass(ClassName)
    if ClassName == "ViewModel" then
        return self.ViewModelClass
    end
    return
end

function AnimationClass:OnEquip(Weapon: Tool)
    self.ViewModelClass:OnEquip(Weapon)
    --Other animations will be added later
end

function AnimationClass:OnUnequip()
    self.ViewModelClass:OnUnequip()
end

function AnimationClass:GetAnimation(AnimationType: string, AnimationName: string)
    if AnimationType == "ViewModel" then
        return self.ViewModelClass:GetAnimation(AnimationName)
    end
    return
end


--ViewModelClass functions

function AnimationClass:Recoil()
    self.ViewModelClass:Recoil()
    return
end

function AnimationClass:GetRayOrigin()
    return self.ViewModelClass:GetRayOrigin()
end
return AnimationClass