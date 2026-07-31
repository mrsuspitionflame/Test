local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Client = StarterPlayerScripts:WaitForChild("Client")
local Controllers = Client:WaitForChild("Controllers")
local GunController = require(Controllers:WaitForChild("GunController"))

local LoadoutHandler = {}

function LoadoutHandler.Init()
	local Player = game.Players.LocalPlayer
	local character = Player.Character or Player.CharacterAdded:Wait()
	if character then
		local backpack = Player:WaitForChild("Backpack")
		GunController.new(backpack:WaitForChild("KineticSlot"))
	end
end

return LoadoutHandler
