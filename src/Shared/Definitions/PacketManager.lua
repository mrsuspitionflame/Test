local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local ByteNet = require(Packages:WaitForChild("Bytenet"))

local PacketManager = {}

PacketManager.Combat = ByteNet.defineNamespace("Combat", function()
	return {
		ShootRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Gun = ByteNet.inst,
				CFrame = ByteNet.cframe,
				Seed = ByteNet.int32,
			}),
		}),

		ReloadRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Gun = ByteNet.inst,
			}),
		}),

		AmmoUpdate = ByteNet.definePacket({
			value = ByteNet.struct({
				Gun = ByteNet.inst,
				Ammo = ByteNet.int32,
			}),
		}),

		EquipRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Gun = ByteNet.inst,
				Action = ByteNet.string,
			}),
		}),

		ReplicateShotEvent = ByteNet.definePacket({
			value = ByteNet.struct({
				MuzzlePosition = ByteNet.vec3,

				RayResults = ByteNet.array(ByteNet.struct({
					Position = ByteNet.vec3,
					Normal = ByteNet.vec3,
					Instance = ByteNet.optional(ByteNet.inst),
					Distance = ByteNet.optional(ByteNet.float32),
				})),
			}),
		}),
	}
end)

return PacketManager
