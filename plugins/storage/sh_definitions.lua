--[[
	PLUGIN.definitions[model's name(lowercase)] = {
		name = "Crate",
		desc = "A simple wooden create.",
		width = 4,
		height = 4,
		locksound = "",
		opensound = "",
	}
--]]

PLUGIN.definitions["models/props_junk/wood_crate001a.mdl"] = {
	name = "나무 상자",
	desc = "4x4의 공간을 가지고 있는 나무 상자입니다.",
	width = 4,
	height = 4,
}

PLUGIN.definitions["models/props_c17/Lockers001a.mdl"] = {
	name = "Locker",
	desc = "A White Locker.",
	width = 3,
	height = 5,
}

PLUGIN.definitions["models/props_wasteland/controlroom_storagecloset001a.mdl"] = {
	name = "Metal Cabinet",
	desc = "A Metal Cabinet",
	width = 4,
	height = 5,
}

PLUGIN.definitions["models/props_wasteland/controlroom_filecabinet002a.mdl"] = {
	name = "File Cabinet",
	desc = "A Metal File Cabinet",
	width = 2,
	height = 4,
}

PLUGIN.definitions["models/items/ammocrate_smg1.mdl"] = {
	name = "Ammo Crate",
	desc = "A Heavy Crate that stores ammo",
	width = 5,
	height = 3,
	onOpen = function(entity, activator)
		local seq = entity:LookupSequence("Close")
		entity:ResetSequence(seq)

		timer.Simple(2, function()
			if (entity and IsValid(entity)) then
				local seq = entity:LookupSequence("Open")
				entity:ResetSequence(seq)
			end
		end)
	end,
}