local ViewModelController = require(script.Parent:WaitForChild("ViewModelController"))

local AnimationController = {}

function AnimationController.new()
	local self = setmetatable({}, { __index = AnimationController })

	self.ViewModelController = ViewModelController.new()

	return self
end

function AnimationController:GetController(controllerName)
	if controllerName == "ViewModel" then
		return self.ViewModelController
	end
	return
end

function AnimationController:OnEquip(weaponName: string)
	self.ViewModelController:OnEquip(weaponName)
	--Other animations will be added later
end

function AnimationController:OnUnequip()
	self.ViewModelController:OnUnequip()
end

function AnimationController:GetAnimation(animationType: string, animationName: string)
	if animationType == "ViewModel" then
		return self.ViewModelController:GetAnimation(animationName)
	end
	return
end

return AnimationController
