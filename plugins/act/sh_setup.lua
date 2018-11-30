
local function facingWall(client)
	local data = {}
	data.start = client:GetPos()
	data.endpos = data.start + client:GetForward() * 20
	data.filter = client

	if (!util.TraceLine(data).HitWorld) then
		return "@faceWall"
	end
end

local function facingWallBack(client)
	local data = {}
	data.start = client:GetPos()
	data.endpos = data.start - client:GetForward() * 20
	data.filter = client

	if (!util.TraceLine(data).HitWorld) then
		return "@faceWallBack"
	end
end

ix.act.stored["Sit"] = {
	["citizen_male"] = {
		sequence = {"Idle_to_Sit_Ground", "Idle_to_Sit_Chair"},
		untimed = true
	},
	["citizen_female"] = {
		sequence = {"Idle_to_Sit_Ground", "Idle_to_Sit_Chair"},
		untimed = true
	},
	["vortigaunt"] = {
		sequence = "chess_wait",
		untimed = true
	}
}

ix.act.stored["Lean"] = {
	["citizen_male"] = {
		sequence = "idle_to_lean_back",
		untimed = true
	},
	["citizen_female"] = {
		sequence = "idle_to_lean_back",
		untimed = true
	},
	["metrocop"] = {
		sequence = {"busyidle2", "idle_baton"},
		untimed = true
	}
}

ix.act.stored["Injured"] = {
	["citizen_male"] = {
		sequence = {"d1_town05_wounded_idle_1", "d1_town05_wounded_idle_2", "d1_town05_winston_down"},
		untimed = true
	},
	["citizen_female"] = {
		sequence = "d1_town05_wounded_idle_1",
		untimed = true
	}
}

ix.act.stored["ArrestWall"] = {
	["citizen_male"] = {
		sequence = "apcarrestidle",
		untimed = true,
		onCheck = facingWall,
		offset = function(client)
			return -client:GetForward() * 23
		end
	}
}

ix.act.stored["Arrest"] = {
	["citizen_male"] = {
		sequence = "arrestidle",
		untimed = true
	}
}

ix.act.stored["Threat"] = {
	["metrocop"] = {
		sequence = {"plazathreat1", "plazathreat2"}
	}
}

ix.act.stored["Cheer"] = {
	["citizen_male"] = {
		sequence = {"cheer1", "cheer2", "wave_smg1"}
	},
	["citizen_female"] = {
		sequence = {"cheer1", "wave_smg1"}
	}
}

ix.act.stored["Here"] = {
	["citizen_male"] = {
		sequence = {"wave_close", "wave"}
	},
	["citizen_female"] = {
		sequence = {"wave_close", "wave"}
	}
}

ix.act.stored["SitWall"] = {
	["citizen_male"] = {
		sequence = {"plazaidle4", "injured1"},
		untimed = true,
		onCheck = facingWallBack
	},
	["citizen_female"] = {
		sequence = {"plazaidle4", "injured1", "injured2"},
		untimed = true,
		onCheck = facingWallBack
	}
}

ix.act.stored["Stand"] = {
	["citizen_male"] = {
		sequence = {"lineidle01", "lineidle02", "lineidle03", "lineidle04"},
		untimed = true
	},
	["citizen_female"] = {
		sequence = {"lineidle01", "lineidle02", "lineidle03"},
		untimed = true
	},
	["metrocop"] = {
		sequence = "plazathreat2",
		untimed = true
	}
}
