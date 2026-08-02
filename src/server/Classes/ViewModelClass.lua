local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local ViewModels = ReplicatedStorage:WaitForChild("ViewModels")
local ServerViewModels = ViewModels:WaitForChild("ServerViewModels")

local Trove = require(Packages:WaitForChild("Trove"))

local ViewModelClass = {}
ViewModelClass.__index = ViewModelClass

function ViewModelClass.new(LoadoutSlot: Tool, player)
	local self = setmetatable({
		Gun = LoadoutSlot,
		Player = player,
		GunName = LoadoutSlot:GetAttribute("GunName"),

		Trove = Trove.new(),
	}, ViewModelClass)

	self:Init()
	return self
end

function ViewModelClass:Recoil()
	self.RecoilAnimation:Play()
	return self.RecoilAnimation
end

function ViewModelClass:Reload()
	self.ReloadAnimation:Play()
	self.ReloadAnimation:AdjustSpeed(0.25)
	return self.ReloadAnimation
end

function ViewModelClass:CreateViewModel()
	self.ViewModel = self.Trove:Add(ServerViewModels:WaitForChild(self.GunName .. "ServerViewModel"):Clone())
	self.ViewModel.Name = self.GunName .. "ServerViewModel"
	self.ViewModel.Parent = self.Player.Character
	local Humanoid = self.ViewModel:FindFirstChild("Humanoid")
	local Animator = Humanoid:WaitForChild("Animator")
	local Animations = self.ViewModel:FindFirstChild("Animations")
	self.RecoilAnimation = Animator:LoadAnimation(Animations:FindFirstChild("RecoilAnimation" .. self.GunName))
	self.ReloadAnimation = Animator:LoadAnimation(Animations:FindFirstChild("ReloadAnimation" .. self.GunName))
end

function ViewModelClass:EquipServerViewModel()
	local character = self.Player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	if not self.ViewModel then
		return
	end

	local primaryPart = self.ViewModel.PrimaryPart
	if not primaryPart then
		return
	end

	self.ViewModel:PivotTo(head.CFrame)

	local motor = Instance.new("Motor6D")
	motor.Name = "ServerViewModelMotor"
	motor.Part0 = head
	motor.Part1 = primaryPart
	motor.C0 = CFrame.new(0, 0.25, -0.5)
	motor.C1 = CFrame.identity
	motor.Parent = head

	self.Motor = self.Trove:Add(motor)
end

function ViewModelClass:SetArmsTransparency(transparency)
	print("Setting arms transparency to:", transparency)
	local char = self.Player.Character or self.Player.CharacterAdded:Wait()
	if not char then
		return
	end

	local rightArm = char:WaitForChild("Right Arm")
	local leftArm = char:WaitForChild("Left Arm")

	rightArm.Transparency = transparency
	leftArm.Transparency = transparency
end

function ViewModelClass:Init()
	self:CreateViewModel()
	self:SetArmsTransparency(1)
	self.Trove:Add(function()
		self:SetArmsTransparency(0)
	end)
	self:EquipServerViewModel()
end

function ViewModelClass:Destroy()
	self.Trove:Destroy()
end

return ViewModelClass
