local Client = script.Parent
local ClientServices = Client:WaitForChild("ClientServices")
local GunServiceClient = require(ClientServices:WaitForChild("GunServiceClient"))

GunServiceClient:Init()