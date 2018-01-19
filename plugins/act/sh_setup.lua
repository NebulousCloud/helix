
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

-- luacheck: globals ACT_ENDSEQ ACT_STARTSEQ
ACT_ENDSEQ = 0
ACT_STARTSEQ = 1

PLUGIN.acts["Sit"] = {
	["citizen_male"] = {
		sequence = "sit_ground",
		untimed = true,
		transition = {
			[ACT_STARTSEQ] = "Idle_to_Sit_Ground",
			[ACT_ENDSEQ] = "Sit_Ground_to_Idle"
		}
	},
	["citizen_female"] = {
		sequence = "sit_ground",
		untimed = true
	}
}
PLUGIN.acts["Injured"] = {
	["citizen_male"] = {
		sequence = {"d1_town05_wounded_idle_1", "d1_town05_wounded_idle_2", "d1_town05_winston_down"},
		untimed = true
	},
	["citizen_female"] = {
		sequence = "d1_town05_wounded_idle_1",
		untimed = true
	}
}
PLUGIN.acts["Arrest"] = {
	["citizen_male"] = {
		sequence = "apcarrestidle",
		untimed = true,
		onCheck = facingWall,
		offset = function(client)
			return -client:GetForward() * 23
		end
	}
}
PLUGIN.acts["Cheer"] = {
	["citizen_male"] = {
		sequence = {"cheer1", "cheer2", "wave_smg1"}
	},
	["citizen_female"] = {
		sequence = {"cheer1", "wave_smg1"}
	}
}
PLUGIN.acts["Here"] = {
	["citizen_male"] = {
		sequence = {"wave_close", "wave"}
	},
	["citizen_female"] = {
		sequence = {"wave_close", "wave"}
	}
}
PLUGIN.acts["SitWall"] = {
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
PLUGIN.acts["Stand"] = {
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
