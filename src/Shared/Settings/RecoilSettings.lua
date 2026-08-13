local RecoilSettings = {
	AutoRifle = {
		Stiffness = 120,
		Damping = 18,
	},

	HandCannon = {
		Stiffness = 90,
		Damping = 15,
	},

	SMG = {
		Stiffness = 150,
		Damping = 22,
	},

	Sniper = {
		Stiffness = 70,
		Damping = 14,
	},
}

function RecoilSettings.GetRecoilAmount(gunType, stability)
	if gunType == "HandCannon" then
		return 200 - stability
	elseif gunType == "AutoRifle" then
		return 130 - stability
	else
		return 100
	end
end
return RecoilSettings
