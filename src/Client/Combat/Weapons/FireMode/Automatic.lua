local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")

local Trove = require(Packages:WaitForChild("Trove"))
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local RS = game:GetService("RunService")

local Automatic = {}

Automatic.__index = Automatic

function Automatic.new(WeaponController)
	local self = setmetatable({}, Automatic)

	self.WeaponController = WeaponController
	self.WeaponInfo = WeaponController.WeaponInfo

	self.Trove = Trove.new()

	self.LastTimeFired = workspace:GetServerTimeNow()

	return self
end

function Automatic:OnUnequip()
	self.Trove:Clean()
end

function Automatic:Cancelled()
	self.Trove:Clean()
end

function Automatic:Released()
	self.Trove:Clean()
end

function Automatic:Held()
	self.Trove:Clean()

	self.Trove:Connect(RS.Heartbeat, function()
		self:Fire()
	end)
end

function Automatic:CanFire()
	local Now = workspace:GetServerTimeNow()
	local DelayBetweenShots = 60 / self.WeaponInfo.FIRE_RATE

	return self.WeaponController.Equipped
		and self.WeaponController.StateManager:TryAction("Weapon", "Fire")
		and self.WeaponInfo.AMMO > 0
		and Now - self.LastTimeFired >= DelayBetweenShots
end

function Automatic:Fire()
	if not self:CanFire() then
		return
	end

	print(workspace:GetServerTimeNow())

	local ShotType = self.WeaponController.ShotType
	local ShotData = ShotType:GetShotData()

	PacketSettings.Combat.Weapon.FireRequest.send({
		SlotName = self.WeaponController.SlotName,
		Action = "Fire",
		Origin = ShotData.Origin,
		Seed = ShotData.Seed,
	})

	self.LastTimeFired = workspace:GetServerTimeNow()

	self.WeaponController.StateManager:PerformAction("Weapon", "Fire")
	self.WeaponController.StateManager:SetState("WeaponState", "FIRING")

	self.WeaponController.Animations.Fire:Play(0)
	self.WeaponController.AnimationController.ViewModelAnimation:Recoil()

	ShotType:Fire(ShotData)
end

return Automatic
