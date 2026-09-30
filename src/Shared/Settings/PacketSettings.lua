local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local ByteNetMax = require(Packages:WaitForChild("ByteNetMax"))

-- Keep the existing packet paths while using Max's packets/queries namespaces.
local function DefinePackets(name, define)
	return ByteNetMax.defineNamespace(name, function()
		return { packets = define() }
	end).packets
end

local PacketSettings = {}

PacketSettings.Character = DefinePackets("Character", function()
	return {
		UpperBodyAim = ByteNetMax.definePacket({
			reliabilityType = "unreliable",
			value = ByteNetMax.struct({
				Pitch = ByteNetMax.float32,
				Yaw = ByteNetMax.float32,
			}),
		}),

		ApplyUpperBodyAim = ByteNetMax.definePacket({
			reliabilityType = "unreliable",
			value = ByteNetMax.struct({
				Player = ByteNetMax.inst,
				Pitch = ByteNetMax.float32,
				Yaw = ByteNetMax.float32,
			}),
		}),
	}
end)

PacketSettings.Creation = DefinePackets("Creation", function()
	return {
		PlayerData = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				Weapons = ByteNetMax.array(ByteNetMax.struct({
					WeaponName = ByteNetMax.string,
					SlotName = ByteNetMax.string,
				})),
				Abilities = ByteNetMax.struct({
					Grenade = ByteNetMax.string,
				}),
			}),
		}),

		RequestPlayerData = ByteNetMax.definePacket({
			value = ByteNetMax.nothing,
		}),
	}
end)

PacketSettings.Combat = {}

PacketSettings.Combat.Replicate = DefinePackets("CombatReplicate", function()
	return {
		ReplicateShotEvent = ByteNetMax.definePacket({
			reliabilityType = "unreliable",
			value = ByteNetMax.struct({
				RayOrigin = ByteNetMax.vec3,

				RayResults = ByteNetMax.array(ByteNetMax.struct({
					Position = ByteNetMax.vec3,
					Normal = ByteNetMax.vec3,
					Instance = ByteNetMax.optional(ByteNetMax.inst),
					Distance = ByteNetMax.optional(ByteNetMax.float32),
				})),
			}),
		}),

		ReplicateAbilityEvent = ByteNetMax.definePacket({
			reliabilityType = "unreliable",
			value = ByteNetMax.struct({
				AbilityType = ByteNetMax.string,
				AbilityName = ByteNetMax.string,
				ActionType = ByteNetMax.string,
				Player = ByteNetMax.optional(ByteNetMax.inst),
				ProjectileID = ByteNetMax.optional(ByteNetMax.string),
				Origin = ByteNetMax.optional(ByteNetMax.vec3),
				Direction = ByteNetMax.optional(ByteNetMax.vec3),
			}),
		}),
	}
end)

PacketSettings.Combat.Weapon = DefinePackets("Weapon", function()
	return {
		FireRequest = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				Action = ByteNetMax.string, -- "Held", "Released", "Cancelled", "Fire"
				SlotName = ByteNetMax.string,
				Origin = ByteNetMax.optional(ByteNetMax.cframe),
				Seed = ByteNetMax.optional(ByteNetMax.int32),
			}),
		}),

		ShotRequest = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				SlotName = ByteNetMax.string,
				CFrame = ByteNetMax.cframe,
				Seed = ByteNetMax.int32,
			}),
		}),

		ReloadRequest = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				Action = ByteNetMax.string,
				SlotName = ByteNetMax.string,
			}),
		}),

		AmmoUpdate = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				SlotName = ByteNetMax.string,
				Ammo = ByteNetMax.int32,
				ReserveAmmo = ByteNetMax.optional(ByteNetMax.int32),
			}),
		}),

		EquipRequest = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				SlotName = ByteNetMax.string,
				Action = ByteNetMax.string,
			}),
		}),

		EquipResult = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				Action = ByteNetMax.string,
				SlotName = ByteNetMax.string,
				Accepted = ByteNetMax.bool,
			}),
		}),

		EquipRequest2 = ByteNetMax.defineQuery({
			request = ByteNetMax.struct({
				SlotName = ByteNetMax.string,
				Action = ByteNetMax.string
			}),
			response = ByteNetMax.struct({
				Action = ByteNetMax.string,
				SlotName = ByteNetMax.string,
				Accepted = ByteNetMax.bool,
			}),
		}),

		AimRequest = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				SlotName = ByteNetMax.string,
				Action = ByteNetMax.string,
			}),
		}),
	}
end)

PacketSettings.Combat.Ability = DefinePackets("Ability", function()
	return {
		GrenadeRequest = ByteNetMax.definePacket({
			value = ByteNetMax.struct({
				Action = ByteNetMax.string,
				Origin = ByteNetMax.optional(ByteNetMax.vec3),
				Direction = ByteNetMax.optional(ByteNetMax.vec3),
				ProjectileId = ByteNetMax.optional(ByteNetMax.string),
			}),
		}),
	}
end)

return PacketSettings
