local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Players = game:GetService("Players")

local Classes = Server:WaitForChild("Classes")
local ServerServices = Server:WaitForChild("ServerServices")

local LoadoutService = require(ServerServices:WaitForChild("LoadoutService"))
local GunClass = require(Classes:WaitForChild("GunClass"))

local FireGunRequest = Remotes:WaitForChild("FireGunRequest")
local ReloadGunRequest = Remotes:WaitForChild("ReloadGunRequest")

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
	PlayerGunClasses[player.UserId][LoadoutSlot.Name] = GunClass.new(player, LoadoutSlot)
end

function GunService.GetGunClass(player, slotName)
	if PlayerGunClasses[player.UserId] then
		return PlayerGunClasses[player.UserId][slotName]
	end
	return nil
end

function GunService:Init()
	Players.PlayerAdded:Connect(function(player)
		local character = player.Character or player.CharacterAdded:Wait()
		if character then
			local tool = LoadoutService.CreatePlayerTools(player, "Rifle", "KineticSlot")
			GunService.CreateGunClass(player, tool)
		end
	end)

	FireGunRequest.OnServerEvent:Connect(function(player, gun, aimDirection)
		if typeof(gun) ~= "Instance"
            or not gun:IsA("Tool")
            or typeof(aimDirection) ~= "Vector3" then
            return
        end

        -- Validate ownership and equipped state
        if gun.Parent ~= player.Character then
            return
        end

        local playerGuns = PlayerGunClasses[player.UserId]
        local gunClass = playerGuns and playerGuns[gun.Name]

        if not gunClass or gunClass.Gun ~= gun then
            return
        end

		gunClass:Fire(aimDirection)
	end)

	ReloadGunRequest.OnServerEvent:Connect(function(player, gun)
		if typeof(gun) ~= "Instance"
            or not gun:IsA("Tool") then
            return
        end

        -- Validate ownership and equipped state
        if gun.Parent ~= player.Character then
            return
        end

        local playerGuns = PlayerGunClasses[player.UserId]
        local gunClass = playerGuns and playerGuns[gun.Name]

        if not gunClass or gunClass.Gun ~= gun then
            return
        end

		gunClass:Reload()
	end)
end

return GunService
