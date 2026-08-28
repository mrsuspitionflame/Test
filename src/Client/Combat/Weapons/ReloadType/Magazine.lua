local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Magazine = {}

Magazine.__index = Magazine

function Magazine.new(WeaponController)
	local self = setmetatable({}, Magazine)

	self.WeaponController = WeaponController
	self.WeaponInfo = WeaponController.WeaponInfo

	return self
end

function Magazine:Held()
	if not self:CanReload() then
		return
	end

	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Held",
	})

	self.WeaponController.StateManager:SetState("WeaponState", "RELOADING")

	local Animations = self.WeaponController.Animations

	Animations.Reload:Play(0)
	Animations.Reload:AdjustSpeed(1 + (self.WeaponInfo.RELOAD_SPEED - 50) / 100)
end

function Magazine:Released() end

function Magazine:CanReload()
	return self.WeaponController.Equipped
		and self.WeaponController.StateManager:TryAction("Weapon", "Reload")
		and self.WeaponInfo.AMMO < self.WeaponInfo.MAGAZINE_SIZE
		and self.WeaponInfo.RESERVE_AMMO > 0
end

function Magazine:Cancelled()
	local Animations = self.WeaponController.Animations
	Animations.Reload:Stop(0)
end

function Magazine:OnUnequip()
	local Animations = self.WeaponController.Animations
	Animations.Reload:Stop(0)
end

return Magazine
