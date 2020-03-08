
--[[--
Player model animation.

Helix comes with support for using NPC animations/models as regular player models by manually translating animations. There are
a few standard animation sets that are built-in that should cover most non-player models:
	citizen_male
	citizen_female
	metrocop
	overwatch
	vortigaunt
	player
	zombie
	fastZombie

If you find that your models are T-posing when they work elsewhere, you'll probably need to set the model class for your
model with `ix.anim.SetModelClass` in order for the correct animations to be used. If you'd like to add your own animation
class, simply add to the `ix.anim` table with a model class name and the required animation translation table.
]]
-- @module ix.anim

ix.anim = ix.anim or {}
ix.anim.citizen_male = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = {
		["prop_vehicle_prisoner_pod"] = {"podpose", Vector(-3, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_BUSY_SIT_CHAIR, Vector(14, 0, -14)},
		["prop_vehicle_airboat"] = {ACT_BUSY_SIT_CHAIR, Vector(8, 0, -20)},
		chair = {ACT_BUSY_SIT_CHAIR, Vector(1, 0, -23)}
	},
}

ix.anim.citizen_female = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = ix.anim.citizen_male.vehicle
}
ix.anim.metrocop = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_GESTURE_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_COMBINE_THROW_GRENADE
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE,
	vehicle = {
		chair = {ACT_COVER_PISTOL_LOW, Vector(5, 0, -5)},
		["prop_vehicle_airboat"] = {ACT_COVER_PISTOL_LOW, Vector(10, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_COVER_PISTOL_LOW, Vector(18, -2, 4)},
		["prop_vehicle_prisoner_pod"] = {ACT_IDLE, Vector(-4, -0.5, 0)}
	}
}
ix.anim.overwatch = {
	normal = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE
}
ix.anim.vortigaunt = {
	melee = {
		["attack"] = ACT_MELEE_ATTACK1,
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
	},
	grenade = {
		["attack"] = ACT_MELEE_ATTACK1,
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK}
	},
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
		["attack"] = ACT_MELEE_ATTACK1
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	beam = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
		["attack"] = ACT_GESTURE_RANGE_ATTACK1,
		["reload"] = ACT_IDLE,
		["glide"] = {ACT_RUN, ACT_RUN}
	},
	glide = "jump_holding_glide"
}
ix.anim.player = {
	normal = {
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE,
		[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
		[ACT_MP_WALK] = ACT_HL2MP_WALK,
		[ACT_MP_RUN] = ACT_HL2MP_RUN,
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	passive = {
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
		[ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
		[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
		[ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE,
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	}
}
ix.anim.zombie = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_ZOMBIE,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_02,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE,
	[ACT_LAND] = {ACT_RESET, ACT_RESET}
}
ix.anim.fastZombie = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_WALK_ZOMBIE,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_05,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_06,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE_FAST,
	[ACT_LAND] = {ACT_RESET, ACT_RESET}
}

local translations = {}

--- Sets a model's animation class.
-- @realm shared
-- @string model Model name to set the animation class for
-- @string class Animation class to assign to the model
-- @usage ix.anim.SetModelClass("models/police.mdl", "metrocop")
function ix.anim.SetModelClass(model, class)
	if (!ix.anim[class]) then
		error("'" .. tostring(class) .. "' is not a valid animation class!")
	end

	translations[model:lower()] = class
end

--- Gets a model's animation class.
-- @realm shared
-- @string model Model to get the animation class for
-- @treturn[1] string Animation class of the model
-- @treturn[2] nil If there was no animation associated with the given model
-- @usage ix.anim.GetModelClass("models/police.mdl")
-- > metrocop
function ix.anim.GetModelClass(model)
	model = string.lower(model)
	local class = translations[model]

	if (!class and string.find(model, "/player")) then
		return "player"
	end

	class = class or "citizen_male"

	if (class == "citizen_male" and (
		string.find(model, "female") or
		string.find(model, "alyx") or
		string.find(model, "mossman"))) then
		class = "citizen_female"
	end

	return class
end

ix.anim.SetModelClass("models/police.mdl", "metrocop")
ix.anim.SetModelClass("models/combine_super_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier_prisonGuard.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/vortigaunt.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_blue.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_doctor.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_slave.mdl", "vortigaunt")

if (SERVER) then
	util.AddNetworkString("ixSequenceSet")
	util.AddNetworkString("ixSequenceReset")

	local playerMeta = FindMetaTable("Player")

	--- Player anim methods
	-- @classmod Player

	--- Forces this player's model to play an animation sequence. It also prevents the player from firing their weapon while the
	-- animation is playing.
	-- @realm server
	-- @string sequence Name of the animation sequence to play
	-- @func[opt=nil] callback Function to call when the animation finishes. This is also called immediately if the animation
	-- fails to play
	-- @number[opt=nil] time How long to play the animation for. This defaults to the duration of the animation
	-- @bool[opt=false] bNoFreeze Whether or not to avoid freezing this player in place while the animation is playing
	-- @see LeaveSequence
	function playerMeta:ForceSequence(sequence, callback, time, bNoFreeze)
		hook.Run("PlayerEnterSequence", self, sequence, callback, time, bNoFreeze)

		if (!sequence) then
			net.Start("ixSequenceReset")
				net.WriteEntity(self)
			net.Broadcast()

			return
		end

		sequence = self:LookupSequence(tostring(sequence))

		if (sequence and sequence > 0) then
			time = time or self:SequenceDuration(sequence)

			self.ixCouldShoot = self:GetNetVar("canShoot", false)
			self.ixSeqCallback = callback
			self:SetCycle(0)
			self:SetPlaybackRate(1)
			self:SetNetVar("forcedSequence", sequence)
			self:SetNetVar("canShoot", false)

			if (!bNoFreeze) then
				self:SetMoveType(MOVETYPE_NONE)
			end

			if (time > 0) then
				timer.Create("ixSeq"..self:EntIndex(), time, 1, function()
					if (IsValid(self)) then
						self:LeaveSequence()
					end
				end)
			end

			net.Start("ixSequenceSet")
				net.WriteEntity(self)
			net.Broadcast()

			return time
		elseif (callback) then
			callback()
		end

		return false
	end

	--- Forcefully stops this player's model from playing an animation that was started by `ForceSequence`.
	-- @realm server
	function playerMeta:LeaveSequence()
		hook.Run("PlayerLeaveSequence", self)

		net.Start("ixSequenceReset")
			net.WriteEntity(self)
		net.Broadcast()

		self:SetNetVar("canShoot", self.ixCouldShoot)
		self:SetNetVar("forcedSequence", nil)
		self:SetMoveType(MOVETYPE_WALK)
		self.ixCouldShoot = nil

		if (self.ixSeqCallback) then
			self:ixSeqCallback()
		end
	end
else
	net.Receive("ixSequenceSet", function()
		local entity = net.ReadEntity()

		if (IsValid(entity)) then
			hook.Run("PlayerEnterSequence", entity)
		end
	end)

	net.Receive("ixSequenceReset", function()
		local entity = net.ReadEntity()

		if (IsValid(entity)) then
			hook.Run("PlayerLeaveSequence", entity)
		end
	end)
end
