local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GunSystemClient = require(StarterPlayerScripts.ClientModules.GunSystemClient)

GunSystemClient:Init(game.Players.LocalPlayer:GetMouse())