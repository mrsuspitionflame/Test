local Character = script.Parent
local Animate = Character:WaitForChild("Animate")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = Shared:WaitForChild("Settings")
local MovementSettings = require(Settings:WaitForChild("MovementSettings"))
local ANIMATION_IDS = MovementSettings.ANIMATION_IDS

Animate.walk.WalkAnim.AnimationId = ANIMATION_IDS.WALK
Animate.jump.JumpAnim.AnimationId = ANIMATION_IDS.JUMP
Animate.fall.FallAnim.AnimationId = ANIMATION_IDS.FALL
