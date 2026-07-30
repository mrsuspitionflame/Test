local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local Player = game:GetService("Players")

local Classes = Server:WaitForChild("Classes")
local ServerServices = Server:WaitForChild("ServerServices")

local LoadoutService = require(ServerServices:WaitForChild("LoadoutService"))
local GunClass = require(Classes:WaitForChild("GunClass"))

local Slots = {
	"KineticSlot",
	"EnergySlot",
	"HeavySlot",
}

local PlayerGunClasses = {}

local GunService = {}

function GunService.CreateGunClass(player, LoadoutSlot)
	if not PlayerGunClasses[player.UserId] then
		PlayerGunClasses[player.UserId] = {}
	end
	PlayerGunClasses[player.UserId][LoadoutSlot.Name] = GunClass.CreateGun(player, LoadoutSlot)
end

function GunService:Init()
	Player.PlayerAdded:Connect(function(player)
		local character = player.Character or player.CharacterAdded:Wait()
		if character then
			local tool = LoadoutService.CreatePlayerTools(player, "Rifle", "KineticSlot")
			GunService.CreateGunClass(player, tool)
		end
	end)
end

return GunService
