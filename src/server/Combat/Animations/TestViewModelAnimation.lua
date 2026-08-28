local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local ViewModels = ReplicatedStorage:WaitForChild("ViewModels")
local ServerViewModels = ViewModels:WaitForChild("ServerViewModels")

local Trove = require(Packages:WaitForChild("Trove"))

local ViewModelAnimation = {}
ViewModelAnimation.__index = ViewModelAnimation

-- Lifecycle

function ViewModelAnimation.new(player)
	local self = setmetatable({
		Player = player,
	}, ViewModelAnimation)

	self.Trove = Trove.new()
	self.WeaponTrove = self.Trove:Extend()
	self.AbilityTrove = self.Trove:Extend()
	self.WeaponAnimations = {}
	self.AbilityAnimations = {}

	return self
end

function ViewModelAnimation:OnEquip(weaponName: string)
	self.WeaponName = weaponName
	self:Init()
end

function ViewModelAnimation:OnUnequip()
	self.Trove:Clean()
end

function ViewModelAnimation:Init()
	self:CreateViewModel()
	self:SetArmsTransparency(1)
	self:ApplyViewModelAppearance()
	self.Trove:Add(function()
		self:SetArmsTransparency(0)
	end)
	self:EquipServerViewModel()
end

-- Viewmodel setup

function ViewModelAnimation:CreateViewModel()
	self.WeaponViewModel = self.Trove:Add(ServerViewModels:WaitForChild(self.WeaponName .. "ServerViewModel"):Clone())
	self.WeaponViewModel.Name = self.WeaponName .. "ServerViewModel"
	self.WeaponViewModel.Parent = self.Player.Character
	local humanoid = self.WeaponViewModel:FindFirstChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	local animations = self.WeaponViewModel:FindFirstChild("Animations")
	self.RecoilAnimation =
		self.Trove:Add(animator:LoadAnimation(animations:FindFirstChild("RecoilAnimation" .. self.WeaponName)))
	self.ReloadAnimation =
		self.Trove:Add(animator:LoadAnimation(animations:FindFirstChild("ReloadAnimation" .. self.WeaponName)))
	self.EquipAnimation =
		self.Trove:Add(animator:LoadAnimation(animations:FindFirstChild("EquipAnimation" .. self.WeaponName)))
end

function ViewModelAnimation:EquipServerViewModel()
	local character = self.Player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	if not self.WeaponViewModel then
		return
	end

	local primaryPart = self.WeaponViewModel.PrimaryPart
	if not primaryPart then
		return
	end

	self.WeaponViewModel:PivotTo(head.CFrame)

	local motor = Instance.new("Motor6D")
	motor.Name = "ServerViewModelMotor"
	motor.Part0 = head
	motor.Part1 = primaryPart
	motor.C0 = CFrame.new(0, 0.25, -0.5)
	motor.C1 = CFrame.identity
	motor.Parent = head

	self.Motor = self.Trove:Add(motor)
end

-- Appearance

function ViewModelAnimation:ApplyViewModelAppearance()
	if not self.Player:HasAppearanceLoaded() then
		self.Player.CharacterAppearanceLoaded:Wait()
	end

	local character = self.Player.Character

	if character then
		print("Applying character appearance for player:", self.Player.Name)
	end

	for _, armName in { "Right Arm", "Left Arm" } do
		local characterArm = character:FindFirstChild(armName)
		local weaponViewModelArm = self.WeaponViewModel:FindFirstChild(armName, true)

		if characterArm and weaponViewModelArm then
			print("Applying character arm color:", characterArm.Color)
			weaponViewModelArm.Color = characterArm.Color
		end
	end

	-- Remove the previous viewmodel shirt.
	local oldShirt = self.WeaponViewModel:FindFirstChildOfClass("Shirt")
	if oldShirt then
		print("Destroying old shirt:", oldShirt:GetFullName())
		oldShirt:Destroy()
	end

	-- Copy the player's classic shirt.
	local characterShirt = character:FindFirstChildOfClass("Shirt")
	if characterShirt then
		characterShirt:Clone().Parent = self.WeaponViewModel
		print("Applied character shirt:", characterShirt:GetFullName())
	end
end

function ViewModelAnimation:SetArmsTransparency(transparency)
	local char = self.Player.Character or self.Player.CharacterAdded:Wait()
	if not char then
		return
	end

	local rightArm = char:WaitForChild("Right Arm")
	local leftArm = char:WaitForChild("Left Arm")

	rightArm.Transparency = transparency
	leftArm.Transparency = transparency
end

-- Animation and model access

function ViewModelAnimation:GetAnimation(animationName: string)
	if animationName == "Recoil" then
		return self.RecoilAnimation
	elseif animationName == "Reload" then
		return self.ReloadAnimation
	elseif animationName == "Equip" then
		return self.EquipAnimation
	end
	return
end

function ViewModelAnimation:GetRayOrigin()
	local RayOrigin = self.WeaponViewModel:FindFirstChild("RayOrigin")
	if RayOrigin then
		return RayOrigin.Position
	else
		return nil
	end
end

return ViewModelAnimation
