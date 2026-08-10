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
				Name = "CombatFrame",
				Size = UDim2.fromScale(0.35, 1),
				Position = UDim2.fromScale(0.02, 0.67),
				BackgroundTransparency = 1,
				Rotation = -2,

				create("UIAspectRatioConstraint")({
					AspectRatio = 2,
					DominantAxis = Enum.DominantAxis.Width,
				}),

				create("Frame")({
					Name = "SuperBarFrame",
					Size = UDim2.fromScale(0.9, 0.12),
					Position = UDim2.fromScale(0.05, 0.15),
					BackgroundTransparency = 0.8,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.8,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),

					create("Frame")({
						Name = "SuperBar",
						Size = UDim2.fromScale(0.75, 1),
						BackgroundColor3 = Color3.fromRGB(238, 235, 85),
					}),
				}),

				create("Frame")({
					Name = "GrenadeBarFrame",
					Size = UDim2.fromScale(0.13, 0.13),
					Position = UDim2.fromScale(0.05, 0.3),
					BackgroundTransparency = 0.8,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.8,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
				create("Frame")({
					Name = "MeleeBarFrame",
					Size = UDim2.fromScale(0.13, 0.13),
					Position = UDim2.fromScale(0.20, 0.3),
					BackgroundTransparency = 0.8,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.8,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
				create("Frame")({
					Name = "ClassAbilityBarFrame",
					Size = UDim2.fromScale(0.13, 0.13),
					Position = UDim2.fromScale(0.35, 0.3),
					BackgroundTransparency = 0.8,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.8,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
				create("Frame")({
					Name = "KineticGunFrame",
					Size = UDim2.fromScale(0.45, 0.26),
					Position = UDim2.fromScale(0.50, 0.3),
					BackgroundTransparency = 1,

					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.7,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),

					create("Frame")({
						Name = "AmmoTypeFrame",
						Size = UDim2.fromScale(0.01, 1),
						Position = UDim2.fromScale(0.99, 0),
					}),
				}),

				create("Frame")({
					Name = "EnergyGunFrame",
					Size = UDim2.fromScale(0.45, 0.13),
					Position = UDim2.fromScale(0.50, 0.56),
					BackgroundTransparency = 1,

					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.7,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),

					create("Frame")({
						Name = "AmmoTypeFrame",
						Size = UDim2.fromScale(0.01, 1),
						Position = UDim2.fromScale(0.99, 0),
						BackgroundColor3 = Color3.fromRGB(68, 255, 0),
					}),
				}),

				create("Frame")({
					Name = "HeavyGunFrame",
					Size = UDim2.fromScale(0.45, 0.13),
					Position = UDim2.fromScale(0.50, 0.69),
					BackgroundTransparency = 1,

					create("UIStroke")({
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Transparency = 0.7,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),

					create("Frame")({
						Name = "AmmoTypeFrame",
						Size = UDim2.fromScale(0.01, 1),
						Position = UDim2.fromScale(0.99, 0),
						BackgroundColor3 = Color3.fromRGB(230, 0, 255),
					}),
				}),
			}),
		})
	end,
}

return story
