local CombatUI = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local AbilityUI = require(CombatUI.AbilityUI)
local GunUI = require(CombatUI.GunUI)

local create = Vide.create

local function App(LoadoutSlotTools)
	return create("ScreenGui")({
		Name = "CombatUI",
		ResetOnSpawn = false,

		create("Frame")({
			AnchorPoint = Vector2.new(0, 0),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			create("Frame")({
				Name = "AbilityFrame",
				Size = UDim2.fromScale(0.2, 1),
				Position = UDim2.fromScale(0.02, 0.75),
				BackgroundTransparency = 1,
				Rotation = -2,

				create("UIAspectRatioConstraint")({
					AspectRatio = 2,
					DominantAxis = Enum.DominantAxis.Width,
				}),

				create("CanvasGroup")({
					Name = "CombatHUD",
					Size = UDim2.fromScale(1, 1),

					GroupTransparency = 0,
					BackgroundTransparency = 1,

					AbilityUI(),
				}),
			}),

			create("Frame")({
				Name = "GunFrame",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.2, 1),
				Position = UDim2.fromScale(0.78, 0.71),
				Rotation = 2,
				create("UIAspectRatioConstraint")({
					AspectRatio = 1.5,
					DominantAxis = Enum.DominantAxis.Width,
				}),
				create("CanvasGroup")({
					Name = "CombatHUD",
					Size = UDim2.fromScale(1, 1),

					GroupTransparency = 0,
					BackgroundTransparency = 1,

					GunUI(LoadoutSlotTools),
				}),
			}),
		}),
	})
end

return App
