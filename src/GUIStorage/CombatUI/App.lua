local CombatUI = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatUIsources = require(CombatUI:WaitForChild("CombatUIsources"))
local Vide = require(ReplicatedStorage.Packages.Vide)

local AbilityUI = require(CombatUI.AbilityUI)
local WeaponUI = require(CombatUI.WeaponUI)

local create = Vide.create

local function App()
	local targetTransparency = Vide.derive(function()
		return if CombatUIsources.UIEnabled() then 0 else 1
	end)

	local animatedTransparency = Vide.spring(targetTransparency, 2, 0.85)
	return create("ScreenGui")({
		Name = "CombatUI",
		ResetOnSpawn = false,
		Enabled = function()
			return CombatUIsources.UIEnabled()
		end,

		create("CanvasGroup")({
			Name = "CombatUI",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			GroupTransparency = function()
				return animatedTransparency()
			end,

			create("Frame")({
				AnchorPoint = Vector2.new(0, 0),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,

				create("Frame")({
					Name = "AbilityFrame",
					Size = UDim2.fromScale(0.17, 1),
					Position = UDim2.fromScale(0.01, 0.75),
					BackgroundTransparency = 1,
					Rotation = -2,

					create("UIAspectRatioConstraint")({
						AspectRatio = 1.5,
						DominantAxis = Enum.DominantAxis.Width,
					}),

					AbilityUI(),
				}),

				create("Frame")({
					Name = "WeaponFrame",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.23, 1),
					Position = UDim2.fromScale(0.76, 0.72),
					Rotation = 2,
					create("UIAspectRatioConstraint")({
						AspectRatio = 2,
						DominantAxis = Enum.DominantAxis.Width,
					}),

					WeaponUI(),
				}),
			}),
		}),
	})
end

return App
