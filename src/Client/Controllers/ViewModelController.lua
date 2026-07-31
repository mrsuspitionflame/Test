local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")

local ViewModels = ReplicatedStorage:WaitForChild("ViewModels")
local ClientViewModels = ViewModels:WaitForChild("ClientViewModels")

local Trove = require(Packages:WaitForChild("Trove"))

local ViewModelController = {}
ViewModelController.__index = ViewModelController

function ViewModelController.new(LoadoutSlot: Tool)
    local self = setmetatable({
        Gun = LoadoutSlot,
        ViewModelName = LoadoutSlot:GetAttribute("ViewModelName"),
        BindingName = "Update" .. LoadoutSlot.Name .. "ViewModel",
        Handling = LoadoutSlot:GetAttribute("Handling"),

        Aiming = false,
        SwayCF = CFrame.new(),
        AimCF = CFrame.new(),
        LastCameraCF = workspace.CurrentCamera.CFrame,

        Trove = Trove.new()
    }, ViewModelController)

    self:Init()
    return self
end

function ViewModelController:Recoil()
    
end

function ViewModelController:UpdateViewModelAndSway(deltaTime)
    local cameraCF = workspace.CurrentCamera.CFrame
    local rotation = cameraCF:ToObjectSpace(self.LastCameraCF)
    local x, y = rotation:ToOrientation()
    local SwayAmount
    if self.Handling >= 95 then
        SwayAmount = 0.10
    else
        SwayAmount = (100-self.Handling)/20
    end

    local targetSway = CFrame.Angles(
        math.sin(x) * SwayAmount,
        math.sin(y) * SwayAmount,
        0
    )

    local aimAlpha = 1 - math.exp(-(self.Handling/4) * deltaTime)
    local swayAlpha = 1 - math.exp(-(self.Handling/5) * deltaTime)

    self.SwayCF = self.SwayCF:Lerp(targetSway, swayAlpha)
    self.LastCameraCF = cameraCF

    if self.Aiming and self.AimPart then
        local aimOffset = self.AimPart.CFrame:ToObjectSpace(self.ViewModel:GetPivot())
        self.AimCF = self.AimCF:Lerp(aimOffset, aimAlpha)
    else
        self.AimCF = self.AimCF:Lerp(CFrame.new(), aimAlpha)
    end

    self.ViewModel:PivotTo(cameraCF * self.SwayCF * self.AimCF)
end

function ViewModelController:CreateViewModel()
    self.ViewModel = self.Trove:Add(ClientViewModels:WaitForChild(self.ViewModelName):Clone())
    self.ViewModel.Name = self.ViewModelName
    local Camera = workspace.CurrentCamera
    self.ViewModel.Parent = Camera
    self.AimPart = self.ViewModel:FindFirstChild("AimPart", true)
end

function ViewModelController:Init()
    self:CreateViewModel()
    local previousCameraMode = Player.CameraMode
    Player.CameraMode = Enum.CameraMode.LockFirstPerson

    self.Trove:Add(function()
        Player.CameraMode = previousCameraMode
    end)
    self.Trove:BindToRenderStep(self.BindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
        self:UpdateViewModelAndSway(deltaTime)
    end)
end

function ViewModelController:Destroy()
    self.Trove:Destroy()
end

return ViewModelController
