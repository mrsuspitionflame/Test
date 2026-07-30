local UIP = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Controllers = Shared:WaitForChild("Controllers")

local Trove = require(Packages:WaitForChild("Trove"))
local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")

local Camera = workspace.CurrentCamera

local GunController = {}

GunController.__index = GunController

function GunController.new(LoadoutSlot)

	local self = {
		Gun = LoadoutSlot,
		Equipped = false,
		Firing = false
	}

	self.LifetimeConnections = Trove.new()
	self.EquippedConnections = Trove.new()

	setmetatable(self, GunController)
	self:Init()

	return self
end


function GunController:ShootEvent()
	--Perform checks to see if the gun can shoot, like ammo, fire rate, etc
	if not self:CanShoot() then
		return
	end

	FireGunRequest:FireServer(self.Gun, Camera.CFrame.LookVector)
	--other stuff like animations, recoil, etc
end

function GunController:CanShoot()
	return self.Equipped
			and not self.Gun:GetAttribute("isReloading")
			and not self.Firing
			and self.Gun:GetAttribute("Ammo") > 0
end

function GunController:ReloadEvent()
	--Perform checks to see if the gun can reload
	if not self:CanReload() then
		return
	end
	ReloadGunRequest:FireServer(self.Gun)
	--other stuff like animations, etc
end

function GunController:CanReload()
	return self.Equipped
		and not self.Gun:GetAttribute("isReloading")
		and not self.Firing
		and self.Gun:GetAttribute("Ammo") < self.magazineSize
end

function GunController:Equip()
	self.Equipped = true
	--other stuff like animations, etc
end

function GunController:Unequip()
	self.Equipped = false
	self.EquippedConnections:Destroy()
	--other stuff like animations, etc
end

function GunController:Destroy()
	self.LifetimeConnections:Destroy()
	if self.EquippedConnections then
		self.EquippedConnections:Destroy()
	end
end

function GunController:bindAction(trove, actionName, callback, createTouchButton, ...)
    CAS:BindAction(
        actionName,
        callback,
        createTouchButton,
        ...
    )

    trove:Add(function()
        CAS:UnbindAction(actionName)
    end)
end

function GunController:Init()
	-- Equipped Connections
	
	self:bindAction(self.EquippedConnections, "ReloadEvent",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				self:ReloadEvent()
			end

			return Enum.ContextActionResult.Sink
		end,
		false,Enum.KeyCode.R
	)

	
	-- Lifetime Connections

	self.LifetimeConnections:Connect(self.Gun.Activated, function()
		self:ShootEvent()
	end)

	self.LifetimeConnections:Connect(self.Gun.Equipped, function()
		self:Equip()
	end)

	self.LifetimeConnections:Connect(self.Gun.Unequipped, function()
		self:Unequip()
	end)
end

return GunController
