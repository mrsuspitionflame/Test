local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local ByteNet = require(Packages:WaitForChild("Bytenet"))

local PacketSettings = {}

PacketSettings.Character = ByteNet.defineNamespace("Character", function()
	return {
		HeadMovement = ByteNet.definePacket({
			value = ByteNet.struct({
				NeckC0 = ByteNet.cframe,
			}),
		}),
	}
end)

PacketSettings.Creation = ByteNet.defineNamespace("Creation", function()
	return {
		CreateGunController = ByteNet.definePacket({
			value = ByteNet.struct({
				GunName = ByteNet.string,
				SlotName = ByteNet.string,
			}),
		}),

		RequestLoadout = ByteNet.definePacket({
			value = ByteNet.nothing,
		}),
	}
end)


PacketSettings.Combat = ByteNet.defineNamespace("Combat", function()
	return {
		ShootRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
				CFrame = ByteNet.cframe,
				Seed = ByteNet.int32,
			}),
		}),

		ReloadRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
			}),
		}),

		AmmoUpdate = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
				Ammo = ByteNet.int32,
				ReserveAmmo = ByteNet.optional(ByteNet.int32),
			}),
		}),

		EquipRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
				Action = ByteNet.string,
			}),
		}),

		EquipResult = ByteNet.definePacket({
			value = ByteNet.struct({
				Action = ByteNet.string,
				SlotName = ByteNet.string,
				Accepted = ByteNet.bool,
			}),
		}),

		AimEvent = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
				Aiming = ByteNet.bool,
			}),
		}),

		ReplicateShotEvent = ByteNet.definePacket({
			reliabilityType = "unreliable",
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

return PacketSettings
