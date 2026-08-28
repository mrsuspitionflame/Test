local ReplicatedStorage = game:GetService("ReplicatedStorage")
<<<<<<< HEAD
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponClass)
	local self = setmetatable({}, ADS)
	self.WeaponClass = WeaponClass
	return self
end

function ADS:Held()
	if not self:CanAim() then
		return
	end

	self.WeaponClass.StateManager:PerformAction("Weapon", "Aim")
	self.WeaponClass.StateManager:SetState("AimState", "AIMING")
end

function ADS:Released()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:CanAim()
	return self.WeaponClass.StateManager:TryAction("Weapon", "Aim")
end

function ADS:OnUnequip()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

=======
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local Trove = require(Packages:WaitForChild("Trove"))

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponClass)
	local self = setmetatable({}, ADS)
	self.WeaponClass = WeaponClass
	self.AimTrove = Trove.new()
	return self
end

function ADS:Held()
	if not self:CanAim() then
		return
	end

	self.WeaponClass.StateManager:PerformAction("Weapon", "Aim")
	self.WeaponClass.StateManager:SetState("AimState", "AIMING")
end

function ADS:CanAim()
	return self.WeaponClass.StateManager:TryAction("Weapon", "Aim")
end

function ADS:Released()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:Cancelled()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:OnUnequip()
	self.AimTrove:Clean()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
end

function ADS:Destroy()
	self.AimTrove:Destroy()
end

>>>>>>> 5c8ad66679672e18c3d4fd2ac633e85f4a1ec669
return ADS
