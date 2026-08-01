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
		Ammo = LoadoutSlot:GetAttribute("Ammo"),

        IsReloading = false,
        IsFiring = false,
        Equipped = false,
        lastShotTime = workspace:GetServerTimeNow(),
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

    if self.IsReloading then
        return false
    end

    if self.Ammo >= self.MagazineSize then
        return false
    end

    return true
end

function GunClass:Reload()
    if not self:CanReload() then
        return
    end

    self.IsReloading = true

    -- Simulate reload time (you can adjust this as needed)
    local reloadTime = 2 -- seconds
    task.delay(reloadTime, function()
        self.Ammo = self.MagazineSize
        self.Gun:SetAttribute("Ammo", self.Ammo)
        self.IsReloading = false
    end)
end

function GunClass:CanShoot()
    local character = self.player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if self.Gun.Parent ~= character then
        return false
    end

    if self.IsReloading then
        return false
    end

    if self.Ammo <= 0 then
        return false
    end

    local now = workspace:GetServerTimeNow()
    local delayBetweenShots = 60 / self.FireRate

    if now - self.lastShotTime < delayBetweenShots then
        return false
    end

    return true
end

function GunClass:Shoot(aimDirection)
    if typeof(aimDirection) ~= "Vector3"
        or aimDirection.Magnitude < 0.99
        or aimDirection.Magnitude > 1.01 then
        return
    end

    if not self:CanShoot() then
        return
    end

    self.lastShotTime = workspace:GetServerTimeNow()
    self.Ammo -= 1

    self.Gun:SetAttribute("Ammo", self.Ammo)

    if self:CanReload() then
        self:Reload()
    end

    -- Perform the authoritative server raycast here.
end

function GunClass:Destroy()
    self.LifetimeConnections:Destroy()
    if self.EquippedConnections then
        self.EquippedConnections:Destroy()
    end
end

return GunClass
