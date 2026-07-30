local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Trove = require(Packages:WaitForChild("Trove"))
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GunClass = {}
GunClass.__index = GunClass

function GunClass.new(player, LoadoutSlot)
	--self contains stats that don't change
	local self = {
		player = player,
		Gun = LoadoutSlot,
		SlotName = LoadoutSlot.Name,
		MagazineSize = LoadoutSlot:GetAttribute("MagazineSize"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		lastShotTime = workspace:GetServerTimeNow(),
		currentAmmo = LoadoutSlot:GetAttribute("CurrentAmmo"),
        isReloading = false,
        Equipped = true
	}

    self.LifetimeConnections = Trove.new()
	self.EquippedConnections = Trove.new()

	setmetatable(self, GunClass)
	return self
end

function GunClass:CanReload()
    local character = self.player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not self.Equipped then
        return false
    end

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if self.Gun.Parent ~= character then
        return false
    end

    if self.isReloading then
        return false
    end

    if self.currentAmmo >= self.MagazineSize then
        return false
    end

    return true
end

function GunClass:Reload()
    if not self:CanReload() then
        return
    end

    self.isReloading = true

    -- Simulate reload time (you can adjust this as needed)
    local reloadTime = 2 -- seconds
    task.delay(reloadTime, function()
        self.currentAmmo = self.MagazineSize
        self.Gun:SetAttribute("CurrentAmmo", self.currentAmmo)
        self.isReloading = false
    end)
end

function GunClass:CanFire()
    local character = self.player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if self.Gun.Parent ~= character then
        return false
    end

    if self.isReloading then
        return false
    end

    if self.currentAmmo <= 0 then
        return false
    end

    local now = workspace:GetServerTimeNow()
    local delayBetweenShots = 60 / self.FireRate

    if now - self.lastShotTime < delayBetweenShots then
        return false
    end

    return true
end

function GunClass:Fire(aimDirection)
    if typeof(aimDirection) ~= "Vector3"
        or aimDirection.Magnitude < 0.99
        or aimDirection.Magnitude > 1.01 then
        return
    end

    if not self:CanFire() then
        return
    end

    self.lastShotTime = workspace:GetServerTimeNow()
    self.currentAmmo -= 1

    self.Gun:SetAttribute("CurrentAmmo", self.currentAmmo)

    if self:CanReload() then
        self:Reload()
    end

    -- Perform the authoritative server raycast here.
end

function GunClass:Destroy()
	-- Cleanup code for the gun instance
end

return GunClass
