local CharacterAnimation = {}

CharacterAnimation.__index = CharacterAnimation

function CharacterAnimation.new()
	local self = setmetatable({}, CharacterAnimation)

	return self
end

return CharacterAnimation
