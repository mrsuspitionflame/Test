local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Networks = Shared:WaitForChild("Networks")
local Definitions = Shared:WaitForChild("Definitions")

local GunNetwork = require(Networks:WaitForChild("GunNetwork"))

local GunState = {
    IsFiring = false,
    IsReloading = false,
    IsEquipped = false,
}

local GunServiceClient = {}

local function FireGunAction()
    GunNetwork.FireRequest()
    --Other stuff like animations, sounds, etc. would go here
end

local function CreateGunAction()
    GunNetwork.CreateGunRequest()
    --Other stuff like animations, sounds, etc. would go here
end

local function ReloadGunAction()
    GunNetwork.ReloadRequest()
    --Other stuff like animations, sounds, etc. would go here
end



function GunServiceClient:Init()
    CAS:BindAction("FireGun", FireGunAction, false, Enum.UserInputType.MouseButton1)
    CAS:BindAction("CreateGun", CreateGunAction, false, Enum.KeyCode.One)
    CAS:BindAction("ReloadGun", ReloadGunAction, false, Enum.KeyCode.R)
end

return GunServiceClient