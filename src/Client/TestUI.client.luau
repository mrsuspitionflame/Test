local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)

local create = Vide.create
local mount = Vide.mount

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function App()
	return create("ScreenGui")({
		Name = "MainUI",
		ResetOnSpawn = false,

		create("TextLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "Hello from Vide",
			TextScaled = true,
		}),
	})
end

--local destroy = mount(App, playerGui)
