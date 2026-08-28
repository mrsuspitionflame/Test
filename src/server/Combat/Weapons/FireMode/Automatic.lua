local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local RS = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utility = Shared:WaitForChild("Utility")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))
local Validation = require(Utility:WaitForChild("Validation"))

local Automatic = {}

Automatic.__index = Automatic

local MAX_JITTER_TOLERANCE = 0.02
local JITTER_TOLERANCE_RATIO = 0.3

function Automatic.new(WeaponClass)
	local self = setmetatable({}, Automatic)

	self.WeaponClass = WeaponClass
	self.WeaponInfo = WeaponClass.WeaponInfo

	self.Trove = Trove.new()

	self.NextFireTime = 0

	return self
end

function Automatic:Cancelled() end

function Automatic:OnUnequip()
	self.NextFireTime = 0
end

function Automatic:Held() end

function Automatic:Released() end

function Automatic:CanFire(data)
	if typeof(data.Origin) ~= "CFrame" or typeof(data.Seed) ~= "number" then
		return false
	end

	local character = self.WeaponClass.Player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local validOrigin = Validation:ValidateVector3(data.Origin.Position)
		and Validation:ValidateVector3(data.Origin.LookVector)

	local validSeed = data.Seed % 1 == 0 and data.Seed >= 0 and data.Seed <= 2 ^ 31 - 1

	local Now = workspace:GetServerTimeNow()
	local FireInterval = 60 / self.WeaponInfo.FIRE_RATE
	local JitterTolerance = math.min(MAX_JITTER_TOLERANCE, FireInterval * JITTER_TOLERANCE_RATIO)
	local FireTimingValid = self.NextFireTime == 0 or Now + JitterTolerance >= self.NextFireTime

	local CanFire = self.WeaponClass.Equipped
		and head ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and self.WeaponInfo.AMMO > 0
		and validOrigin
		and validSeed
		and (data.Origin.Position - head.Position).Magnitude <= 15
		and FireTimingValid
		and self.WeaponClass.StateManager:TryAction("Weapon", "Fire")

	return CanFire, Now, FireInterval
end

function Automatic:AdvanceFireSchedule(Now, FireInterval)
	if self.NextFireTime == 0 or Now > self.NextFireTime + FireInterval then
		self.NextFireTime = Now + FireInterval
	else
		self.NextFireTime += FireInterval
	end
end

function Automatic:Fire(data)
	local CanFire, Now, FireInterval = self:CanFire(data)

	if not CanFire then
		return
	end

	self:AdvanceFireSchedule(Now, FireInterval)

	self.WeaponClass.StateManager:PerformAction("Weapon", "Fire")
	self.WeaponClass.StateManager:SetState("WeaponState", "FIRING")

	self.WeaponInfo.AMMO -= 1

	PacketSettings.Combat.Weapon.AmmoUpdate.sendTo({
		SlotName = self.WeaponClass.SlotName,
		Ammo = self.WeaponInfo.AMMO,
	}, self.WeaponClass.Player)

	local Animations = self.WeaponClass.Animations

	Animations.Fire:Play(0)

	self.WeaponClass.ShotType:Fire(data)
end

return Automatic
