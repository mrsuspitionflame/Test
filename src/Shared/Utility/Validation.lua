local Validation = {}

function Validation.ValidateNumber(value)
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

function Validation.ValidateInteger(value)
	return Validation.ValidateNumber(value) and value % 1 == 0
end

function Validation.ValidateString(value)
	return typeof(value) == "string"
end

function Validation.ValidateBoolean(value)
	return typeof(value) == "boolean"
end

function Validation.ValidateTable(value)
	return typeof(value) == "table"
end

function Validation.ValidateVector2(value)
	return typeof(value) == "Vector2"
		and Validation.ValidateNumber(value.X)
		and Validation.ValidateNumber(value.Y)
end

function Validation.ValidateVector3(value)
	return typeof(value) == "Vector3"
		and Validation.ValidateNumber(value.X)
		and Validation.ValidateNumber(value.Y)
		and Validation.ValidateNumber(value.Z)
end

function Validation.ValidateCFrame(value)
	if typeof(value) ~= "CFrame" then
		return false
	end

	for _, component in ipairs({ value:GetComponents() }) do
		if not Validation.ValidateNumber(component) then
			return false
		end
	end

	return true
end

function Validation.ValidateColor3(value)
	return typeof(value) == "Color3"
		and Validation.ValidateNumber(value.R)
		and Validation.ValidateNumber(value.G)
		and Validation.ValidateNumber(value.B)
end

function Validation.ValidateInstance(value)
	return typeof(value) == "Instance"
end

function Validation.ValidatePlayer(value)
	return Validation.ValidateInstance(value) and value:IsA("Player")
end

-- Explicitly list supported types so List cannot recursively validate itself.
local Validators = {
	Number = Validation.ValidateNumber,
	Integer = Validation.ValidateInteger,
	String = Validation.ValidateString,
	Boolean = Validation.ValidateBoolean,
	Table = Validation.ValidateTable,
	Vector2 = Validation.ValidateVector2,
	Vector3 = Validation.ValidateVector3,
	CFrame = Validation.ValidateCFrame,
	Color3 = Validation.ValidateColor3,
	Instance = Validation.ValidateInstance,
	Player = Validation.ValidatePlayer,
}

-- Accepts a type-to-value map, e.g. { Vector3 = origin, Integer = seed }.
-- An empty map is valid. Repeated types must be checked in separate calls.
-- Nil values disappear from Lua tables; validate required values directly.
function Validation.ValidateList(data)
	if typeof(data) ~= "table" then
		return false
	end

	for dataType, value in pairs(data) do
		local validator = Validators[dataType]
		if not validator or not validator(value) then
			return false
		end
	end

	return true
end

return Validation
