local CombatUI = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local AbilityUI = require(CombatUI.AbilityUI)
local GunUI = require(CombatUI.GunUI)

local create = Vide.create

local function App()
	return create("ScreenGui")({
		Name = "CombatUI",
		ResetOnSpawn = false,

		create("Frame")({
			AnchorPoint = Vector2.new(0, 0),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			create("Frame")({
				Name = "AbilityandGunFrame",
				Size = UDim2.fromScale(0.35, 1),
				Position = UDim2.fromScale(0.02, 0.67),
				BackgroundTransparency = 1,
				Rotation = -2,

				create("UIAspectRatioConstraint")({
					AspectRatio = 2,
					DominantAxis = Enum.DominantAxis.Width,
				}),

				AbilityUI(),
				GunUI(),
			}),
		}),
	})
end

return App
