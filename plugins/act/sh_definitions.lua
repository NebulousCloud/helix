
local function FacingWall(client)
	local data = {}
	data.start = client:EyePos()
	data.endpos = data.start + client:GetForward() * 20
	data.filter = client

	if (!util.TraceLine(data).Hit) then
		return "@faceWall"
	end
end

local function FacingWallBack(client)
	local data = {}
	data.start = client:LocalToWorld(client:OBBCenter())
	data.endpos = data.start - client:GetForward() * 20
	data.filter = client

	if (!util.TraceLine(data).Hit) then
		return "@faceWallBack"
	end
end

function PLUGIN:SetupActs()
	-- sit
	ix.act.Register("Sit", {"citizen_male", "citizen_female"}, {
		start = {"idle_to_sit_ground", "idle_to_sit_chair"},
		sequence = {"sit_ground", "sit_chair"},
		finish = {
			{"sit_ground_to_idle", duration = 2.1},
			""
		},
		untimed = true,
		idle = true
	})

	ix.act.Register("SitWall", {"citizen_male", "citizen_female"}, {
		sequence = {
			{"plazaidle4", check = FacingWallBack},
			{"injured1", check = FacingWallBack, offset = function(client)
				return client:GetForward() * 14
			end}
		},
		untimed = true,
		idle = true
	})

	ix.act.Register("Sit", "vortigaunt", {
		sequence = "chess_wait",
		untimed = true,
		idle = true
	})

	-- stand
	ix.act.Register("Stand", "citizen_male", {
		sequence = {"lineidle01", "lineidle02", "lineidle03", "lineidle04"},
		untimed = true,
		idle = true
	})

	ix.act.Register("Stand", "citizen_female", {
		sequence = {"lineidle01", "lineidle02", "lineidle03"},
		untimed = true,
		idle = true
	})

	ix.act.Register("Stand", "metrocop", {
		sequence = "plazathreat2",
		untimed = true,
		idle = true
	})

	-- cheer
	ix.act.Register("Cheer", "citizen_male", {
		sequence = {{"cheer1", duration = 1.6}, "cheer2", "wave_smg1"}
	})

	ix.act.Register("Cheer", "citizen_female", {
		sequence = {"cheer1", "wave_smg1"}
	})

	-- lean
	ix.act.Register("Lean", {"citizen_male", "citizen_female"}, {
		start = {"idle_to_lean_back", "", ""},
		sequence = {
			{"lean_back", check = FacingWallBack},
			{"plazaidle1", check = FacingWallBack},
			{"plazaidle2", check = FacingWallBack}
		},
		untimed = true,
		idle = true
	})

	ix.act.Register("Lean", {"metrocop"}, {
		sequence = {{"idle_baton", check = FacingWallBack}, "busyidle2"},
		untimed = true,
		idle = true
	})

	-- injured
	ix.act.Register("Injured", "citizen_male", {
		sequence = {"d1_town05_wounded_idle_1", "d1_town05_wounded_idle_2", "d1_town05_winston_down"},
		untimed = true,
		idle = true
	})

	ix.act.Register("Injured", "citizen_female", {
		sequence = "d1_town05_wounded_idle_1",
		untimed = true,
		idle = true
	})

	-- arrest
	ix.act.Register("ArrestWall", "citizen_male", {
		sequence = {
			{"apcarrestidle",
			check = FacingWall,
			offset = function(client)
				return -client:GetForward() * 23
			end},
			"spreadwallidle"
		},
		untimed = true
	})

	ix.act.Register("Arrest", "citizen_male", {
		sequence = "arrestidle",
		untimed = true
	})

	-- threat
	ix.act.Register("Threat", "metrocop", {
		sequence = "plazathreat1",
	})

	-- deny
	ix.act.Register("Deny", "metrocop", {
		sequence = "harassfront2",
	})

	-- motion
	ix.act.Register("Motion", "metrocop", {
		sequence = {"motionleft", "motionright", "luggage"}
	})

	-- wave
	ix.act.Register("Wave", {"citizen_male", "citizen_female"}, {
		sequence = {{"wave", duration = 2.75}, {"wave_close", duration = 1.75}}
	})

	-- pant
	ix.act.Register("Pant", {"citizen_male", "citizen_female"}, {
		start = {"d2_coast03_postbattle_idle02_entry", "d2_coast03_postbattle_idle01_entry"},
		sequence = {"d2_coast03_postbattle_idle02", {"d2_coast03_postbattle_idle01", check = FacingWall}},
		untimed = true
	})

	-- window
	ix.act.Register("Window", "citizen_male", {
		sequence = "d1_t03_tenements_look_out_window_idle",
		untimed = true
	})

	ix.act.Register("Window", "citizen_female", {
		sequence = "d1_t03_lookoutwindow",
		untimed = true
	})
end
