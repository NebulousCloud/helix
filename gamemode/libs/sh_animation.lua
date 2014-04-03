--[[
	Purpose: A library to specify which animations should be used by which models and
	contains tables that provide the appropriate act or sequence that is to be used.
--]]

nut.anim = nut.anim or {}
nut.anim.classes = nut.anim.classes or {}

--[[
	Purpose: Adds a new model to a class. If the class does not exist, a table will be created
	automatically.
--]]
function nut.anim.SetModelClass(class, model)
	model = string.lower(model)

	nut.anim.classes[model] = class
end

--[[
	Purpose: Translates the model and returns the animation class.
--]]
function nut.anim.GetClass(model)
	return nut.anim.classes[model] or (string.find(model, "female") and "citizen_female" or "citizen_male")
end

--[[
	Purpose: Quick utility function that automatically includes the groups of citizens
	based off the gender provided.
--]]
local function defineCitizenClass(prefix)
	for k, v in pairs(file.Find("models/humans/group01/"..prefix.."_*.mdl", "GAME")) do
		nut.anim.SetModelClass("citizen_"..prefix, "models/humans/group01/"..v)
	end

	for k, v in pairs(file.Find("models/humans/group02/"..prefix.."_*.mdl", "GAME")) do
		nut.anim.SetModelClass("citizen_"..prefix, "models/humans/group02/"..v)
	end

	for k, v in pairs(file.Find("models/humans/group03/"..prefix.."_*.mdl", "GAME")) do
		nut.anim.SetModelClass("citizen_"..prefix, "models/humans/group03/"..v)
	end

	for k, v in pairs(file.Find("models/humans/group03m/"..prefix.."_*.mdl", "GAME")) do
		nut.anim.SetModelClass("citizen_"..prefix, "models/humans/group03m/"..v)
	end
end

defineCitizenClass("male")
defineCitizenClass("female")

nut.anim.SetModelClass("citizen_female", "models/mossman.mdl")
nut.anim.SetModelClass("citizen_female", "models/alyx.mdl")

nut.anim.SetModelClass("metrocop", "models/police.mdl")

nut.anim.SetModelClass("overwatch", "models/combine_super_soldier.mdl")
nut.anim.SetModelClass("overwatch", "models/combine_soldier_prisonguard.mdl")
nut.anim.SetModelClass("overwatch", "models/combine_soldier.mdl")

nut.anim.SetModelClass("vort", "models/vortigaunt.mdl")
nut.anim.SetModelClass("vort", "models/vortigaunt_slave.mdl")

nut.anim.SetModelClass("metrocop", "models/dpfilms/metropolice/playermodels/pm_skull_police.mdl")

-- Male citizen animation tree.
nut.anim.citizen_male = {
	normal = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED}
	},
	pistol = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		idle = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		idle = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		idle = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		idle = {ACT_IDLE_SUITCASE, ACT_IDLE_ANGRY_MELEE},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN, ACT_RUN},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE
}

-- Female citizen animation tree.
nut.anim.citizen_female = {
	normal = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED}
	},
	pistol = {
		idle = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_PISTOL},
		run = {ACT_RUN, ACT_RUN_AIM_PISTOL},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		idle = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		idle = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		run = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		idle = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		idle_crouch = {ACT_COVER_LOW, ACT_COVER_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN, ACT_RUN},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE
}

-- Metropolice animation tree.
nut.anim.metrocop = {
	normal = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
		walk = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN, ACT_RUN}
	},
	pistol = {
		idle = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		idle_crouch = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		walk = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
		attack = ACT_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		idle = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		walk = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE}
	},
	shotgun = {
		idle = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		walk = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE_STIMULATED}
	},
	grenade = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		idle_crouch = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		walk = {ACT_WALK, ACT_WALK_ANGRY},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN, ACT_RUN},
		attack = ACT_COMBINE_THROW_GRENADE
	},
	melee = {
		idle = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		idle_crouch = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		walk = {ACT_WALK, ACT_WALK_ANGRY},
		walk_crouch = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		run = {ACT_RUN, ACT_RUN},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE
}

-- Overwatch soldier animation tree.
nut.anim.overwatch = {
	normal = {
		idle = {"idle_unarmed", "man_gun"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {"walkunarmed_all", ACT_WALK_RIFLE},
		walk_crouch = {"crouch_walkall", "crouch_walkall"},
		run = {"runall", ACT_RUN_AIM_RIFLE}
	},
	pistol = {
		idle = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {"walkunarmed_all", ACT_WALK_RIFLE},
		walk_crouch = {"crouch_walkall", "crouch_walkall"},
		run = {"runall", ACT_RUN_AIM_RIFLE}
	},
	smg = {
		idle = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		walk_crouch = {"crouch_walkall", "crouch_walkall"},
		run = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE}
	},
	shotgun = {
		idle = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
		walk_crouch = {"crouch_walkall", "crouch_walkall"},
		run = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN}
	},
	grenade = {
		idle = {"idle_unarmed", "man_gun"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {"walkunarmed_all", ACT_WALK_RIFLE},
		walk_crouch = {"crouch_walkall", "crouch_walkall"},
		run = {"runall", ACT_RUN_AIM_RIFLE}
	},
	melee = {
		idle = {"idle_unarmed", "man_gun"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {"walkunarmed_all", ACT_WALK_RIFLE},
		walk_crouch = {"crouch_walkall", "crouch_walkall"},
		run = {"runall", ACT_RUN_AIM_RIFLE},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE
}

-- Half-assed vortigaunt soldier animation tree.
nut.anim.vort = {
	normal = {
		idle = {ACT_IDLE, "actionidle"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK, "walk_all_holdgun"},
		walk_crouch = {ACT_WALK, "walk_all_holdgun"},
		run = {ACT_RUN, ACT_RUN}
	},
	pistol = {
		idle = {ACT_IDLE, "tcidle"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK, "walk_all_holdgun"},
		walk_crouch = {ACT_WALK, "walk_all_holdgun"},
		run = {ACT_RUN, "run_all_tc"}
	},
	smg = {
		idle = {ACT_IDLE, "tcidle"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK, "walk_all_holdgun"},
		walk_crouch = {ACT_WALK, "walk_all_holdgun"},
		run = {ACT_RUN, "run_all_tc"}
	},
	shotgun = {
		idle = {ACT_IDLE, "tcidle"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK, "walk_all_holdgun"},
		walk_crouch = {ACT_WALK, "walk_all_holdgun"},
		run = {ACT_RUN, "run_all_tc"}
	},
	grenade = {
		idle = {ACT_IDLE, "tcidle"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK, "walk_all_holdgun"},
		walk_crouch = {ACT_WALK, "walk_all_holdgun"},
		run = {ACT_RUN, "run_all_tc"}
	},
	melee = {
		idle = {ACT_IDLE, "tcidle"},
		idle_crouch = {"crouchidle", "crouchidle"},
		walk = {ACT_WALK, "walk_all_holdgun"},
		walk_crouch = {ACT_WALK, "walk_all_holdgun"},
		run = {ACT_RUN, "run_all_tc"}
	},
	glide = ACT_GLIDE
}

local playerMeta = FindMetaTable("Player")

if (SERVER) then
	function playerMeta:SetOverrideSeq(sequence, time, startCallback, finishCallback)
		local realSeq, duration = self:LookupSequence(sequence)
		time = time or duration

		if (!realSeq or realSeq == -1) then
			return
		end
		
		self:SetNetVar("seq", sequence)

		if (startCallback) then
			startCallback()
		end

		if (time > 0) then
			timer.Create("nut_Seq"..self:UniqueID(), time, 1, function()
				if (IsValid(self)) then
					self:ResetOverrideSeq()

					if (finishCallback) then
						finishCallback()
					end
				end
			end)
		end

		return time, realSeq
	end

	function playerMeta:ResetOverrideSeq()
		self:SetNetVar("seq", false)
	end
end

function playerMeta:GetOverrideSeq()
	return self:GetNetVar("seq", false)
end

function playerMeta:GetGender()
	local model = string.lower(self:GetModel())
	local gender = "male"

	if (string.find(model, "female") or nut.anim.GetClass(model) == "citizen_female") then
		gender = "female"
	end

	return gender
end