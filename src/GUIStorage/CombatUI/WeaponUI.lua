local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.Vide)
local CombatUI = script.Parent
local CombatUIsources = require(CombatUI:WaitForChild("CombatUIsources"))

local create = Vide.create
local spring = Vide.spring

local GetAmmoColor = function(AmmoType)
	if AmmoType == "Primary" then
		return Color3.fromRGB(255, 255, 255)
	elseif AmmoType == "Special" then
		return Color3.fromRGB(68, 255, 0)
	elseif AmmoType == "Heavy" then
		return Color3.fromRGB(255, 0, 195)
	else
		return Color3.fromRGB(255, 255, 255)
	end
end

local function CreateWeaponSlot(weaponInfo)
	local isEquipped = function()
		return CombatUIsources.EquippedSlot() == weaponInfo.SlotName
	end

	local targetSize = function()
		if isEquipped() then
			return UDim2.fromScale(0.9, 0.4)
		else
			return UDim2.fromScale(0.9, 0.25)
		end
	end

	local slotNumber = function()
		if weaponInfo.SlotName == "KineticSlot" then
			return "1"
		elseif weaponInfo.SlotName == "EnergySlot" then
			return "2"
		elseif weaponInfo.SlotName == "HeavySlot" then
			return "3"
		else
			return ""
		end
	end

	local animatedSize = spring(targetSize, 0.25, 0.85)

	return create("Frame")({
		Name = `{weaponInfo.SlotName}Slot`,
		Size = animatedSize,

		LayoutOrder = function()
			return if isEquipped() then 0 else weaponInfo.DefaultOrder
		end,

		BackgroundTransparency = 1,

		create("Frame")({
			Name = "WeaponInfoFrame",
			Size = UDim2.fromScale(0.75, 1),
			Position = UDim2.fromScale(0.25, 0),
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
				Position = UDim2.fromScale(0, 0),
				BackgroundColor3 = function()
					return GetAmmoColor(weaponInfo.AmmoColor())
				end,
			}),

			create("Frame")({
				Name = "SeparatorFrame",
				BackgroundTransparency = 0.7,
				Size = UDim2.fromScale(0.005, 1),
				Position = UDim2.fromScale(0.75, 0),
			}),

			create("TextLabel")({
				Name = "AmmoCount",
				Size = UDim2.fromScale(0.25, 0.9),
				Position = UDim2.fromScale(0.48, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = function()
					return tostring(weaponInfo.Ammo())
				end,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),

			create("TextLabel")({
				Name = "ReserveAmmoCount",
				Size = UDim2.fromScale(0.25, 0.6),
				Position = UDim2.fromScale(0.75, 0.15),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = function()
					return tostring(weaponInfo.ReserveAmmo())
				end,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),

		create("CanvasGroup")({
			Name = "SlotNumberCanvasGroup",
			Size = UDim2.fromScale(0.25, 1),
			Position = UDim2.fromScale(0.09, 0),
			BackgroundTransparency = 1,
			GroupTransparency = function()
				return if isEquipped() then 1 else 0
			end,

			create("Frame")({
				Name = "SlotNumberFrame",
				Size = UDim2.fromScale(1, 0.56),
				Position = UDim2.fromScale(0.12, 0.22),
				BackgroundTransparency = 0.7,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),

				create("UIAspectRatioConstraint")({
					AspectRatio = 1,
					DominantAxis = Enum.DominantAxis.Width,
				}),

				create("UIStroke")({
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 1,
					Transparency = 0.7,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),

				create("TextLabel")({
					Name = "SlotNumber",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.5,
					TextScaled = true,
					Text = function()
						return slotNumber()
					end,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			}),
		}),
	})
end

local function WeaponUI()
	return create("Frame")({
		Name = "WeaponFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		create("UIPadding")({
			PaddingTop = UDim.new(0.05, 0),
			PaddingBottom = UDim.new(0.05, 0),
			PaddingLeft = UDim.new(0.01, 0),
			PaddingRight = UDim.new(0.01, 0),
		}),

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0.05, 0),
		}),

		CreateWeaponSlot({
			SlotName = "KineticSlot",
			Ammo = CombatUIsources.KineticSlot.Ammo,
			ReserveAmmo = CombatUIsources.KineticSlot.ReserveAmmo,
			AmmoColor = CombatUIsources.KineticSlot.AmmoType,
			DefaultOrder = 1,
		}),

		CreateWeaponSlot({
			SlotName = "EnergySlot",
			Ammo = CombatUIsources.EnergySlot.Ammo,
			ReserveAmmo = CombatUIsources.EnergySlot.ReserveAmmo,
			AmmoColor = CombatUIsources.EnergySlot.AmmoType,
			DefaultOrder = 2,
		}),

		CreateWeaponSlot({
			SlotName = "HeavySlot",
			Ammo = CombatUIsources.HeavySlot.Ammo,
			ReserveAmmo = CombatUIsources.HeavySlot.ReserveAmmo,
			AmmoColor = CombatUIsources.HeavySlot.AmmoType,
			DefaultOrder = 3,
		}),
	})
end

return WeaponUI
