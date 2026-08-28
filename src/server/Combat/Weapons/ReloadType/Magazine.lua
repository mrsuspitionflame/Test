local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local Trove = require(Packages:WaitForChild("Trove"))

local Magazine = {}

Magazine.__index = Magazine

function Magazine.new(WeaponClass)
	local self = setmetatable({}, Magazine)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo
	self.ReloadTrove = Trove.new()

	return self
end

function Magazine:Held()
	if not self:CanReload() then
		return
	end

	self.WeaponClass.StateManager:PerformAction("Weapon", "Reload")
	self.WeaponClass.StateManager:SetState("WeaponState", "RELOADING")

	local ReloadSpeed = 1 + (self.WeaponInfo.RELOAD_SPEED - 50) / 100
	self.ReloadTrove:Clean()
	self.ReloadTrove:Add(task.delay(self.WeaponInfo.RELOAD_DURATION / ReloadSpeed, function()
		if self.WeaponClass.StateManager:GetState("WeaponState") ~= "RELOADING" then
			return
		end
		self.WeaponClass.StateManager:SetState("WeaponState", "IDLE")

		local MissingAmmo = self.WeaponInfo.MAGAZINE_SIZE - self.WeaponInfo.AMMO
		local AmmoToLoad = math.min(MissingAmmo, self.WeaponInfo.RESERVE_AMMO)
		self.WeaponInfo.AMMO += AmmoToLoad
		self.WeaponInfo.RESERVE_AMMO -= AmmoToLoad

		PacketSettings.Combat.Weapon.AmmoUpdate.sendTo({
			SlotName = self.WeaponClass.SlotName,
			Ammo = self.WeaponInfo.AMMO,
			ReserveAmmo = self.WeaponInfo.RESERVE_AMMO,
		}, self.WeaponClass.Player)
	end))
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
	self.ReloadTrove:Clean()

	if self.WeaponClass.StateManager:GetState("WeaponState") == "RELOADING" then
		self.WeaponClass.StateManager:SetState("WeaponState", "IDLE")
	end
end

function Magazine:OnUnequip()
	self.ReloadTrove:Clean()
end

function Magazine:Destroy()
	self.ReloadTrove:Destroy()
end

return Magazine
