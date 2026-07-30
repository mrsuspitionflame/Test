local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ViewModels = ReplicatedStorage:WaitForChild("ViewModels")
local ClientViewModels = ViewModels:WaitForChild("ClientViewModels")

local ViewModelController = {}

function ViewModelController.new(LoadoutSlot) 
    local self = {
        ViewModel = ClientViewModels:WaitForChild(LoadoutSlot.Name):Clone(),
    }
    setmetatable(self, ViewModelController)
    return self
end

return ViewModelController
