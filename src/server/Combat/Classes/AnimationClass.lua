local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Combat = Server:WaitForChild("Combat")
local Classes = Combat:WaitForChild("Classes")
local Animations = Classes.Parent:WaitForChild("Animations")

local ViewModelAnimation = require(Animations:WaitForChild("ViewModelAnimation"))

local AnimationClass = {}

AnimationClass.__index = AnimationClass

function AnimationClass.new(player)
	local self = setmetatable({}, AnimationClass)
	self.Player = player

	self.ViewModelAnimations = {
		AbilityAnimations = {},
		WeaponAnimations = {},
		MovementAnimations = {},
	}

	self.CharacterAnimations = {
		AbilityAnimations = {},
		CharacterAnimations = {},
		MovementAnimations = {},
	}

	self.ViewModelAnimation = ViewModelAnimation.new(self)
	--self.CharacterAnimation = CharacterAnimation.new(self)

	return self
end

function AnimationClass:GetClass(className)
	if className == "ViewModel" then
		return self.ViewModelAnimation
	end
	return
end

function AnimationClass:OnEquip(WeaponInfo)
	self.ViewModelAnimation:OnEquip(WeaponInfo)
	--Other animations will be added later
end

function AnimationClass:OnUnequip()
	self.ViewModelAnimation:OnUnequip()
end

function AnimationClass:GetAnimation(data)
	if data.AnimationType == "ViewModel" then
		if data.AnimationLocation == "AbilityAnimations" then
			return self.ViewModelAnimations.AbilityAnimations[data.AbilityName][string.upper(data.AnimationName)]
		elseif data.AnimationLocation == "WeaponAnimations" then
			return self.ViewModelAnimations.WeaponAnimations[string.upper(data.AnimationName)]
		end
	end
	return
end

function AnimationClass:CreateAbilityViewModel(data)
	self.ViewModelAnimation:CreateAbilityViewModel(data)
end

-- ViewModelAnimation functions

function AnimationClass:Recoil()
	return
end

function AnimationClass:GetRayOrigin()
	return self.ViewModelAnimation:GetRayOrigin()
end
return AnimationClass
