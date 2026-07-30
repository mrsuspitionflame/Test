local UIP = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Controllers = Shared:WaitForChild("Controllers")

local ViewModelController = require(Controllers:WaitForChild("ViewModelController"))

local CreateGunRequest = Remotes:WaitForChild("CreateGunRequest")

local Definitions = Shared:WaitForChild("Definitions")
local GunDefinitions = require(Definitions:WaitForChild("GunDefinitions"))

local slot: Tool

local GunController = {}

GunController.__index = GunController

function GunController.new(LoadoutSlot)
	local self = {
		slot = LoadoutSlot,
		Damage = LoadoutSlot:GetAttribute("Damage"),
		Range = LoadoutSlot:GetAttribute("Range"),
		FireRate = LoadoutSlot:GetAttribute("FireRate"),
		Ammo = LoadoutSlot:GetAttribute("Ammo"),
		Perks = LoadoutSlot:GetAttribute("Perks"),
		equipped = false,

	}
	setmetatable(self, GunController)
	return self
end


function GunController:ShootEvent()

end



function GunController:Init()

end

return GunController
