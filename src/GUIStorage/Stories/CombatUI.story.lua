local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUIStorage = ReplicatedStorage:WaitForChild("GUIStorage")
local CombatUI = GUIStorage:WaitForChild("CombatUI")

local AbilityUI = require(CombatUI:WaitForChild("AbilityUI"))
local GunUI = require(CombatUI:WaitForChild("GunUI"))

local Vide = require(game.ReplicatedStorage.Packages.Vide)
local create = Vide.create

local story = {
	vide = Vide,

	story = function()
		return create("Frame")({
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

					GunUI(),
				}),
			}),
		})
	end,
}

return story
