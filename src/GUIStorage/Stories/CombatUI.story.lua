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
				Name = "GunFrame",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.23, 1),
				Position = UDim2.fromScale(0.76, 0.72),
				Rotation = 2,
				create("UIAspectRatioConstraint")({
					AspectRatio = 2,
					DominantAxis = Enum.DominantAxis.Width,
				}),

				GunUI(),
			}),

			create("Frame")({
				Name = "GunReticalFrame",
				Size = UDim2.fromScale(0.03, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 0.5,
				AnchorPoint = Vector2.new(0.5, 0.5),

				create("UIAspectRatioConstraint")({
					AspectRatio = 1,
					DominantAxis = Enum.DominantAxis.Width,
				}),
			}),
		})
	end,
}

return story
