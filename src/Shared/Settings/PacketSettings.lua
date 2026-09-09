local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local ByteNet = require(Packages:WaitForChild("Bytenet"))

local PacketSettings = {}

PacketSettings.Character = ByteNet.defineNamespace("Character", function()
	return {
		UpperBodyAim = ByteNet.definePacket({
			reliabilityType = "unreliable",
			value = ByteNet.struct({
				Pitch = ByteNet.float32,
				Yaw = ByteNet.float32,
			}),
		}),

		ApplyUpperBodyAim = ByteNet.definePacket({
			reliabilityType = "unreliable",
			value = ByteNet.struct({
				Player = ByteNet.inst,
				Pitch = ByteNet.float32,
				Yaw = ByteNet.float32,
			}),
		}),
	}
end)

PacketSettings.Creation = ByteNet.defineNamespace("Creation", function()
	return {
		PlayerData = ByteNet.definePacket({
			value = ByteNet.struct({
				Weapons = ByteNet.array(ByteNet.struct({
					WeaponName = ByteNet.string,
					SlotName = ByteNet.string,
				})),
				Abilities = ByteNet.struct({
					Grenade = ByteNet.string,
				}),
			}),
		}),

		RequestPlayerData = ByteNet.definePacket({
			value = ByteNet.nothing,
		}),
	}
end)

PacketSettings.Combat = {}

PacketSettings.Combat.Replicate = ByteNet.defineNamespace("CombatReplicate", function()
	return {
		ReplicateShotEvent = ByteNet.definePacket({
			reliabilityType = "unreliable",
			value = ByteNet.struct({
				RayOrigin = ByteNet.vec3,

				RayResults = ByteNet.array(ByteNet.struct({
					Position = ByteNet.vec3,
					Normal = ByteNet.vec3,
					Instance = ByteNet.optional(ByteNet.inst),
					Distance = ByteNet.optional(ByteNet.float32),
				})),
			}),
		}),

		ReplicateAbilityEvent = ByteNet.definePacket({
			reliabilityType = "unreliable",
			value = ByteNet.struct({
				AbilityType = ByteNet.string,
				AbilityName = ByteNet.string,
				ActionType = ByteNet.string,
				Player = ByteNet.optional(ByteNet.inst),
				ProjectileID = ByteNet.optional(ByteNet.string),
				Origin = ByteNet.optional(ByteNet.vec3),
				Direction = ByteNet.optional(ByteNet.vec3),
			}),
		}),
	}
end)

PacketSettings.Combat.Weapon = ByteNet.defineNamespace("Weapon", function()
	return {
		FireRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Action = ByteNet.string, -- "Held", "Released", "Cancelled", "Fire"
				SlotName = ByteNet.string,
				Origin = ByteNet.optional(ByteNet.cframe),
				Seed = ByteNet.optional(ByteNet.int32),
			}),
		}),

		ShotRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
				CFrame = ByteNet.cframe,
				Seed = ByteNet.int32,
			}),
		}),

		ReloadRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Action = ByteNet.string,
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

		AimRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				SlotName = ByteNet.string,
				Action = ByteNet.string,
			}),
		}),
	}
end)

PacketSettings.Combat.Ability = ByteNet.defineNamespace("Ability", function()
	return {
		GrenadeRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				Action = ByteNet.string,
				Origin = ByteNet.optional(ByteNet.vec3),
				Direction = ByteNet.optional(ByteNet.vec3),
				ProjectileId = ByteNet.optional(ByteNet.string),
			}),
		}),
	}
end)

return PacketSettings
