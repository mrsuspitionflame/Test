local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Magazine = {}

Magazine.__index = Magazine

function Magazine.new(WeaponClass)
	local self = setmetatable({}, Magazine)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo

	return self
end

function Magazine:Held()
	if not self:CanReload() then
		return
	end

	self.WeaponClass.StateManager:PerformAction("Weapon", "Reload")
	self.WeaponClass.StateManager:SetState("WeaponState", "RELOADING")

	local Animations = self.WeaponClass.Animations

	Animations.Reload:Play(0)
	Animations.Reload:AdjustSpeed(1 + (self.WeaponInfo.RELOAD_SPEED - 50) / 100)
end

function Magazine:Released() end

function Magazine:CanReload()
	local character = self.WeaponClass.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return self.WeaponClass.Equipped
		and self.WeaponClass.StateManager:TryAction("Weapon", "Reload")
		and humanoid ~= nil
		and humanoid.Health > 0
		and self.WeaponInfo.AMMO < self.WeaponInfo.MAGAZINE_SIZE
		and self.WeaponInfo.RESERVE_AMMO > 0
end

function Magazine:Cancelled()
	local Animations = self.WeaponClass.Animations
	Animations.Reload:Stop(0)
end

function Magazine:OnUnequip()
	local Animations = self.WeaponClass.Animations
	Animations.Reload:Stop(0)
end

return Magazine
