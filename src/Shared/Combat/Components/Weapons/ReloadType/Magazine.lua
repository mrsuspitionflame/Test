local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Magazine = {}

Magazine.__index = Magazine

function Magazine.new(WeaponHandler)
	local self = setmetatable({}, Magazine)

	self.WeaponHandler = WeaponHandler
	self.WeaponInfo = WeaponHandler.WeaponInfo

	return self
end

function Magazine:Held()
	if not self:CanReload() then
		return
	end

	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Held",
	})

	self.WeaponHandler.StateManager:SetState("WeaponState", "RELOADING")

	local Animations = self.WeaponHandler.Animations

	local ReloadSpeed = 1 + (self.WeaponInfo.RELOAD_SPEED - 50) / 100

	self.WeaponHandler.Trove:Connect(Animations.RELOAD.CHARACTER.Stopped, function()
		self.WeaponHandler.StateManager:SetState("WeaponState", "IDLE")
	end)

	Animations.RELOAD.CHARACTER:Play(0, 1, ReloadSpeed)
end

function Magazine:Released() end

function Magazine:CanReload()
	return self.WeaponHandler.CombatClasses.EquippedWeaponClass == self.WeaponHandler
		and self.WeaponHandler.StateManager:TryAction("Weapon", "Reload")
		and self.WeaponInfo.AMMO < self.WeaponInfo.MAGAZINE_SIZE
		and self.WeaponInfo.RESERVE_AMMO > 0
end

function Magazine:Cancelled()
	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Cancelled",
	})

	if self.WeaponHandler.StateManager:GetState("WeaponState") == "RELOADING" then
		self.WeaponHandler.StateManager:SetState("WeaponState", "IDLE")
	end

	local Animations = self.WeaponHandler.Animations
	Animations.RELOAD.CHARACTER:Stop(0)
end

function Magazine:OnUnequip()
	local Animations = self.WeaponHandler.Animations
	Animations.RELOAD.CHARACTER:Stop(0)
end

return Magazine
