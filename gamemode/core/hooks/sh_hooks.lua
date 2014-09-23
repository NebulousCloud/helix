function GM:PlayerNoClip(client)
	return client:IsAdmin()
end

local HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"

function GM:TranslateActivity(client, act)
	local class = nut.anim.getModelClass(client:GetModel())
	local tree = nut.anim[class]

	if (tree) then
		local weapon = client:GetActiveWeapon()
		local subClass = "normal"

		if (client:OnGround()) then
			if (IsValid(weapon)) then
				subClass = weapon:GetHoldType()
				subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass
			end

			if (tree[subClass] and tree[subClass][act]) then
				return tree[subClass][act][client:isWepRaised() and 2 or 1]
			end
		else
			return tree.glide
		end
	end
end

function GM:CalcMainActivity(client, velocity)
	local eyeAngles = client:EyeAngles()
	local yaw = velocity:Angle().yaw
	local normalized = math.NormalizeAngle(yaw - eyeAngles.y)

	client:SetPoseParameter("move_yaw", normalized)

	if (CLIENT) then
		client:SetIK(false)
	end

	return self.BaseClass:CalcMainActivity(client, velocity)
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

function GM:StartCommand(client, command)
	local weapon = client:GetActiveWeapon()

	if (!client:isWepRaised()) then
		if (IsValid(weapon) and weapon.FireWhenLowered) then
			return
		end

		command:RemoveKey(KEY_BLACKLIST)
	end
end