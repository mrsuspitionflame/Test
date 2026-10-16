-- Run in Studio after syncing the project, using this file's contents in the Command Bar.
local Validation = require(game:GetService("ReplicatedStorage").Shared.Utility.Validation)

local nan = 0 / 0
local folder = Instance.new("Folder")
local player = Instance.new("Player")
local cases = {
	{ "Number", 0, true },
	{ "Number", -1.5, true },
	{ "Number", nan, false },
	{ "Number", math.huge, false },
	{ "Number", -math.huge, false },
	{ "Number", "1", false },
	{ "Integer", -2, true },
	{ "Integer", 1.5, false },
	{ "Integer", math.huge, false },
	{ "String", "", true },
	{ "String", 1, false },
	{ "Boolean", false, true },
	{ "Boolean", 0, false },
	{ "Table", {}, true },
	{ "Table", "table", false },
	{ "Vector2", Vector2.new(1, 2), true },
	{ "Vector2", Vector2.new(math.huge, 0), false },
	{ "Vector3", Vector3.new(1, 2, 3), true },
	{ "Vector3", Vector3.new(0, nan, 0), false },
	{ "Vector3", Vector3.new(0, 0, math.huge), false },
	{ "CFrame", CFrame.new(1, 2, 3), true },
	{ "CFrame", CFrame.new(math.huge, 0, 0), false },
	{ "CFrame", CFrame.new(0, 0, 0, nan, 0, 0, 0, 1, 0, 0, 0, 1), false },
	{ "CFrame", Vector3.zero, false },
	{ "Color3", Color3.new(0.2, 0.5, 1), true },
	{ "Color3", Color3.new(0, math.huge, 0), false },
	{ "Instance", folder, true },
	{ "Instance", {}, false },
	{ "Player", player, true },
	{ "Player", folder, false },
}

local success, failure = pcall(function()
	for index, case in ipairs(cases) do
		assert(Validation["Validate" .. case[1]](case[2]) == case[3], "Validator case " .. index)
		assert(Validation.ValidateList({ [case[1]] = case[2] }) == case[3], "List case " .. index)
		assert(Validation["Validate" .. case[1]](nil) == false, "Nil case " .. index)
	end

	assert(Validation.ValidateList({}))
	assert(Validation.ValidateList({ Number = 12, String = "hello", Boolean = false }))
	assert(not Validation.ValidateList({ Number = 12, Integer = 1.5 }))
	assert(not Validation.ValidateList({ Unknown = 12 }))
	assert(not Validation.ValidateList({ [1] = 12 }))
	assert(not Validation.ValidateList(nil))
	assert(not Validation.ValidateList(false))
	assert(not Validation.ValidateList("invalid"))
	local recursive = {}
	recursive.List = recursive
	assert(not Validation.ValidateList(recursive))
end)

folder:Destroy()
player:Destroy()
assert(success, failure)
print("Validation checks passed")
