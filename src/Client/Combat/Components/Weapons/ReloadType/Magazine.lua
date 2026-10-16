local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Magazine = {}

Magazine.__index = Magazine

function Magazine.new(WeaponHandler)
	local self = setmetatable({}, Magazine)

	self.WeaponHandler = WeaponHandler
	return self
end

function Magazine:Pressed()
	if not self:CanReload() then
		return
	end

	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Pressed",
	})

	self.WeaponHandler.CombatHandler:CancelStates("Weapon", "Reload")
	self.Trove:Clean()
	self.WeaponHandler.StateManager:SetState("WeaponState", "RELOADING")

	local Animations = self.WeaponHandler.Animations

	local ReloadSpeed = 1 + (self.WeaponHandler.WeaponInfo.RELOAD_SPEED - 50) / 100

	self.Trove:Connect(self.WeaponHandler.Animations.RELOAD.VIEWMODEL.Stopped, function()
		self.Trove:Clean()
		if self.WeaponHandler.StateManager:GetState("WeaponState") == "RELOADING" then
			self.WeaponHandler.StateManager:SetState("WeaponState", "IDLE")
		end
	end)

	Animations.RELOAD.VIEWMODEL:Play(0, 1, ReloadSpeed)
	Animations.RELOAD.CHARACTER:Play(0, 1, ReloadSpeed)

	-- May use task.delay to handle reload timing if needed with a reload time
end

function Magazine:CanReload()
	return self.WeaponHandler.CombatHandler.EquippedSlot == self.WeaponHandler.SlotName
		and self.WeaponHandler.StateManager:TryAction("Weapon", "Reload")
		and self.WeaponHandler.Ammo < self.WeaponHandler.WeaponInfo.MAGAZINE_SIZE
		and self.WeaponHandler.ReserveAmmo > 0
end

function Magazine:Cancelled()
	self.Trove:Clean()
	PacketSettings.Combat.Weapon.ReloadRequest.send({
		SlotName = self.WeaponHandler.SlotName,
		Action = "Cancelled",
	})

	if self.WeaponHandler.StateManager:GetState("WeaponState") == "RELOADING" then
		self.WeaponHandler.StateManager:SetState("WeaponState", "IDLE")
	end

	local Animations = self.WeaponHandler.Animations
	Animations.RELOAD.VIEWMODEL:Stop(0)
	Animations.RELOAD.CHARACTER:Stop(0)
end

function Magazine:OnUnequip()
	self.Trove:Clean()
	local Animations = self.WeaponHandler.Animations
	Animations.RELOAD.VIEWMODEL:Stop(0)
	Animations.RELOAD.CHARACTER:Stop(0)
end


function Magazine:OnEquip()
	self.Trove = self.WeaponHandler.EquippedTrove:Extend()
end

return Magazine
