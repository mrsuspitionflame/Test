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

local function CreateGunSlot(Guninfo)
	local isEquipped = function()
		return CombatUIsources.EquippedSlot() == Guninfo.SlotName
	end

	local targetSize = function()
		if isEquipped() then
			return UDim2.fromScale(0.9, 0.4)
		else
			return UDim2.fromScale(0.9, 0.25)
		end
	end

	local animatedSize = spring(targetSize, 0.25, 0.85)

	return create("Frame")({
		Name = `{Guninfo.SlotName}Slot`,
		Size = animatedSize,

		LayoutOrder = function()
			return if isEquipped() then 0 else Guninfo.DefaultOrder
		end,

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
			BackgroundColor3 = Guninfo.AmmoColor,
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
				return tostring(Guninfo.Ammo())
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
				return tostring(Guninfo.ReserveAmmo())
			end,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
	})
end

local function GunUI(LoadoutSlotTools)
	return create("Frame")({
		Name = "GunFrame",
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

		CreateGunSlot({
			SlotName = "KineticSlot",
			Ammo = CombatUIsources.KineticSlot.Ammo,
			ReserveAmmo = CombatUIsources.KineticSlot.ReserveAmmo,
			AmmoColor = GetAmmoColor(LoadoutSlotTools.KineticSlot:GetAttribute("AmmoType")),
			DefaultOrder = 1,
		}),

		CreateGunSlot({
			SlotName = "EnergySlot",
			Ammo = CombatUIsources.EnergySlot.Ammo,
			ReserveAmmo = CombatUIsources.EnergySlot.ReserveAmmo,
			AmmoColor = GetAmmoColor(LoadoutSlotTools.EnergySlot:GetAttribute("AmmoType")),
			DefaultOrder = 2,
		}),

		CreateGunSlot({
			SlotName = "HeavySlot",
			Ammo = CombatUIsources.HeavySlot.Ammo,
			ReserveAmmo = CombatUIsources.HeavySlot.ReserveAmmo,
			AmmoColor = GetAmmoColor(LoadoutSlotTools.HeavySlot:GetAttribute("AmmoType")),
			DefaultOrder = 3,
		}),
	})
end

return GunUI
