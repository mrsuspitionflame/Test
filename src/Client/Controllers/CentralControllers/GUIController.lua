

local GUIController = {}

GUIController.__index = GUIController

function GUIController.new()
    local self = setmetatable({}, GUIController)
    
    return self
end


return GUIController