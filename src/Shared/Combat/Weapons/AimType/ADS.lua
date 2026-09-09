local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local StateSettings = require(Settings:WaitForChild("StateSettings"))

local RS = game:GetService("RunService")

local ADS = {}

ADS.__index = ADS

function ADS.new(WeaponClass)
	local self = setmetatable({}, ADS)
	self.WeaponClass = WeaponClass
	return self
end

function ADS:Step()
	local Root = self.Root

	local AimHeld = self.WeaponClass.AimAction:GetState()
	local Aiming = Root:GetAttribute("AimState") == "AIMING"
	local ShouldAim = AimHeld and not Aiming

	if RS:IsServer() then
		print("Nothing for now")
	end

	if ShouldAim then
		self:Held()
	elseif Aiming and not AimHeld then
		self:Released()
	end
end

function ADS:CancelStates()
	for stateType, states in pairs(StateSettings.Weapon.Aim.CancelStates) do
		for _, state in ipairs(states) do
			self.WeaponClass.CombatClasses:CancelState(stateType, state)
		end
	end
end

function ADS:Held()
	if not self:CanAim() then
		return
	end

	self:CancelStates()
	
	self.WeaponClass.StateManager:SetState("AimState", "AIMING")

	self.WeaponClass.AnimationController.CameraController:StartAim()
end

function ADS:Released()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
	self.WeaponClass.AnimationController.CameraController:StopAim()
end

function ADS:Cancelled()
	if self.WeaponClass.StateManager:GetState("AimState") == "AIMING" then
		self.WeaponClass.StateManager:SetState("AimState", "IDLE")
	end

	self.WeaponClass.AnimationController.CameraController:StopAim()
end

function ADS:OnUnequip()
	self.WeaponClass.StateManager:SetState("AimState", "IDLE")
	self.WeaponClass.AnimationController.CameraController:StopAim()
end

function ADS:CanAim()
	return self.WeaponClass.StateManager:TryAction("Weapon", "Aim") and self.WeaponClass.Equipped == true
end

return ADS
