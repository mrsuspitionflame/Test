local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local PacketSettings = require(Settings:WaitForChild("PacketSettings"))

local Character = script.Parent
local Torso =  Character:WaitForChild("Torso")

local root = Character:WaitForChild("HumanoidRootPart")
local RS = game:GetService("RunService")
local cam = workspace.CurrentCamera
local Neck = Torso:WaitForChild("Neck")
local delay = 0.1
local elapsed = 0

local y = Neck.C0.Y
RS.RenderStepped:Connect(function(dt)
	local camdirec = root.CFrame:ToObjectSpace(cam.CFrame).LookVector
	Neck.C0 = CFrame.new(0,y,0) * CFrame.Angles(0,math.rad(180),0) * CFrame.Angles(0,-camdirec.X,0) * CFrame.Angles(-camdirec.Y,0,0)
	Neck.C0 = Neck.C0 * CFrame.Angles(math.rad(-90),0,0)
	
	elapsed = elapsed + dt
	if elapsed > delay then
		elapsed = 0
		PacketSettings.Character.HeadMovement.send({
			NeckC0 = Neck.C0,
		})
	end
end)