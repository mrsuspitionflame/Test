local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Magazine = {}

Magazine.__index = Magazine

function Magazine.new(WeaponController)
	local self = setmetatable({}, Magazine)

	self.WeaponController = WeaponController
	return self
end

function Magazine:Pressed()
	if not self:CanReload() then
		return
	end

	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Pressed",
	})

	self.WeaponController.StateManager:SetState("WeaponState", "RELOADING")

	local Animations = self.WeaponController.Animations

	local ReloadSpeed = 1 + (self.WeaponController.WeaponInfo.RELOAD_SPEED - 50) / 100

	self.WeaponController.Trove:Connect(self.WeaponController.Animations.RELOAD.VIEWMODEL.Stopped, function()
		self.WeaponController.StateManager:SetState("WeaponState", "IDLE")
	end)

	Animations.RELOAD.VIEWMODEL:Play(0, 1, ReloadSpeed)
	Animations.RELOAD.CHARACTER:Play(0, 1, ReloadSpeed)

	-- May use task.delay to handle reload timing if needed with a reload time
end

function Magazine:CanReload()
	return self.WeaponController.CombatController.EquippedSlot == self.WeaponController.SlotName
		and self.WeaponController.StateManager:TryAction("Weapon", "Reload")
		and self.WeaponController.Ammo < self.WeaponController.WeaponInfo.MAGAZINE_SIZE
		and self.WeaponController.ReserveAmmo > 0
end

function Magazine:Cancelled()
	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Cancelled",
	})

	if self.WeaponController.StateManager:GetState("WeaponState") == "RELOADING" then
		self.WeaponController.StateManager:SetState("WeaponState", "IDLE")
	end

	local Animations = self.WeaponController.Animations
	Animations.RELOAD.VIEWMODEL:Stop(0)
	Animations.RELOAD.CHARACTER:Stop(0)
end

function Magazine:OnUnequip()
	local Animations = self.WeaponController.Animations
	Animations.RELOAD.VIEWMODEL:Stop(0)
	Animations.RELOAD.CHARACTER:Stop(0)
end


return Magazine
