local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create

local function GunUI()
	return create("Frame")({
		Name = "GunFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

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
	})
end

return GunUI
