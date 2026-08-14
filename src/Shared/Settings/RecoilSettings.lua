local RecoilSettings = {
	AutoRifle = {
		STIFFNESS = 120,
		DAMPING = 18,
	},

	HandCannon = {
		STIFFNESS = 90,
		DAMPING = 15,
	},

	SMG = {
		STIFFNESS = 150,
		DAMPING = 22,
	},

	Sniper = {
		STIFFNESS = 70,
		DAMPING = 14,
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
