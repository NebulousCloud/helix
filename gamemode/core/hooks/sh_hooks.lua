function GM:PlayerNoClip(client)
	return client:IsAdmin()
end

local anims = {}
anims[ACT_MP_STAND_IDLE] = ACT_IDLE
anims[ACT_MP_WALK] = ACT_WALK
anims[ACT_MP_RUN] = ACT_RUN
anims[ACT_MP_CROUCH_IDLE] = ACT_COVER_LOW
anims[ACT_MP_CROUCHWALK] = ACT_WALK_CROUCH
anims[ACT_MP_JUMP] = ACT_GLIDE

function GM:TranslateActivity(client, act)
	if (anims[act]) then
		return anims[act]
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