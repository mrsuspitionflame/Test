local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

local function Border()
	return create("UIStroke")({
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.8,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function AbilityUI()
	return create("Frame")({
		Name = "AbilityFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		create("Frame")({
			Name = "SuperBarFrame",
			Size = UDim2.fromScale(0.9, 0.2),
			Position = UDim2.fromScale(0.05, 0.01),
			BackgroundTransparency = 0.8,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),

			Border(),

			create("Frame")({
				Name = "SuperBar",
				Size = UDim2.fromScale(0.75, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromRGB(238, 235, 85),
			}),
		}),

		create("Frame")({
			Name = "GrenadeBarFrame",
			Size = UDim2.fromScale(0.26, 0.26),
			Position = UDim2.fromScale(0.05, 0.27),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 0.8,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),

			Border(),
		}),

		create("Frame")({
			Name = "MeleeBarFrame",
			Size = UDim2.fromScale(0.26, 0.26),
			Position = UDim2.fromScale(0.37, 0.27),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 0.8,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),

			Border(),
		}),

		create("Frame")({
			Name = "ClassAbilityBarFrame",
			Size = UDim2.fromScale(0.26, 0.26),
			Position = UDim2.fromScale(0.69, 0.27),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 0.8,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),

			Border(),
		}),
	})
end

return AbilityUI
