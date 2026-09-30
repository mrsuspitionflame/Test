local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local AbilitySettings = require(Settings:WaitForChild("AbilitySettings"))

local AnimationLoader = {}

local function GetAnimator(Model)
	local Humanoid = Model:WaitForChild("Humanoid")
	return Humanoid:WaitForChild("Animator")
end

function AnimationLoader.LoadWeaponAnimations(Player: Player, Trove, ViewModel, WeaponInfo)
	local WeaponAnimations = {}
	local ViewModelAnimator = GetAnimator(ViewModel)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local CharacterAnimator = GetAnimator(Character)

	for ActionName, AnimationIDs in pairs(WeaponInfo.ANIMATION_IDS) do
		for AnimationType, AnimationId in pairs(AnimationIDs) do
			if AnimationId == nil then
				continue
			end

			local Animation = Trove:Add(Instance.new("Animation"))
			Animation.Name = ActionName .. AnimationType .. "Animation"
			Animation.AnimationId = AnimationId

			local Animator = if AnimationType == "CHARACTER" then CharacterAnimator else ViewModelAnimator
			local LoadedAnimation = Animator:LoadAnimation(Animation)

			if not WeaponAnimations[ActionName] then
				WeaponAnimations[ActionName] = {}
			end
			WeaponAnimations[ActionName][AnimationType] = Trove:Add(LoadedAnimation)
		end
	end

	return WeaponAnimations
end

function AnimationLoader.LoadAbilityAnimations(Player: Player, Trove, ViewModel, AbilityInfo)
	local AbilityAnimations = {}
	local ViewModelAnimator = GetAnimator(ViewModel)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local CharacterAnimator = GetAnimator(Character)

	for AbilityType, AbilityName in pairs(AbilityInfo) do
		if not AbilitySettings[AbilityType] or not AbilitySettings[AbilityType][AbilityName] then
			continue
		end
		local AbilityData = AbilitySettings[AbilityType][AbilityName]
		for ActionName, AnimationIDs in pairs(AbilityData.ANIMATION_IDS) do
			for AnimationType, AnimationId in pairs(AnimationIDs) do
				if AnimationId == nil then
					continue
				end

				local Animation = Trove:Add(Instance.new("Animation"))
				Animation.Name = ActionName .. AnimationType .. "Animation"
				Animation.AnimationId = AnimationId

				local Animator = if AnimationType == "CHARACTER" then CharacterAnimator else ViewModelAnimator
				local LoadedAnimation = Animator:LoadAnimation(Animation)

				if not AbilityAnimations[AbilityType] then
					AbilityAnimations[AbilityType] = {}
				end
				if not AbilityAnimations[AbilityType][ActionName] then
					AbilityAnimations[AbilityType][ActionName] = {}
				end
				AbilityAnimations[AbilityType][ActionName][AnimationType] = Trove:Add(LoadedAnimation)
			end
		end
	end

	return AbilityAnimations
end

return AnimationLoader
