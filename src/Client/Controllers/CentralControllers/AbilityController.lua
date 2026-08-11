local AbilityController = {}

AbilityController.__index = AbilityController

function AbilityController.new()
	local self = setmetatable({}, AbilityController)
	return self
end

return AbilityController
