
local ActionSettings = {}

ActionSettings.Weapon = {
    Fire = {
        BlockedStates = {
            WeaponState = {"Equipping"},
            AbilityState = {"UsingAbility"},
            MovementState = {}
        }
    },

    Reload = {
        BlockedStates = {
            WeaponState = {"Firing", "Equipping"},
            AbilityState = {"UsingAbility"},
            MovementState = {}
        }
    },
}


return ActionSettings