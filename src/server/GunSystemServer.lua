local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuffStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BuffStats"))
--local GunStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GunStats"):WaitForChild("TestGun"))
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GunEvent = RemoteEvents:WaitForChild("GunEvent")

local GunSystemServer = {}

function GunSystemServer:CalculateDamange(buffList)
	local totalDamage = 0
	local BDamage = 0
	local PDamage = 1
	for _, buff in ipairs(buffList) do
		if BuffStats[buff] then
			if BuffStats[buff].BaseDamage then
				BDamage = BDamage + BuffStats[buff].BaseDamage
			end
			if BuffStats[buff].PureDamage then
				PDamage = PDamage * (1 + BuffStats[buff].PureDamage)
			end
		end
	end
	totalDamage = (totalDamage + BDamage) * PDamage
	print("Total Damage: " .. totalDamage)
end

function GunSystemServer:Init()
	GunEvent.OnServerEvent:Connect(function(buffList)
		print("Received Buff List: ")
	end)
end

return GunSystemServer
