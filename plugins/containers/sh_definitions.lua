--[[
	PLUGIN.definitions[model's name(lowercase)] = {
		name = "Crate",
		description = "A simple wooden create.",
		width = 4,
		height = 4,
		locksound = "",
		opensound = "",
	}
--]]

PLUGIN.definitions["models/props_junk/wood_crate001a.mdl"] = {
	name = "Crate",
	description = "A simple wooden crate.",
	width = 4,
	height = 4,
}

PLUGIN.definitions["models/props_c17/lockers001a.mdl"] = {
	name = "Locker",
	description = "A white locker.",
	width = 3,
	height = 5,
}

PLUGIN.definitions["models/props_wasteland/controlroom_storagecloset001a.mdl"] = {
	name = "Metal Cabinet",
	description = "A green metal cabinet.",
	width = 4,
	height = 5,
}

PLUGIN.definitions["models/props_wasteland/controlroom_filecabinet002a.mdl"] = {
	name = "File Cabinet",
	description = "A metal filing cabinet.",
	width = 2,
	height = 4,
}

PLUGIN.definitions["models/props_c17/furniturefridge001a.mdl"] = {
	name = "Refrigerator",
	description = "A metal box for keeping food in.",
	width = 2,
	height = 3,
}

PLUGIN.definitions["models/props_wasteland/kitchen_fridge001a.mdl"] = {
	name = "Large Refrigerator",
	description = "A large metal box for storing even more food in.",
	width = 4,
	height = 5,
}

PLUGIN.definitions["models/props_junk/trashbin01a.mdl"] = {
	name = "Trash Bin",
	description = "What do you expect to find in here?",
	width = 1,
	height = 2,
}

PLUGIN.definitions["models/items/ammocrate_smg1.mdl"] = {
	name = "Ammo Crate",
	description = "A heavy crate that stores ammo",
	width = 5,
	height = 3,
	OnOpen = function(entity, activator)
		local closeSeq = entity:LookupSequence("Close")
		entity:ResetSequence(closeSeq)

		timer.Simple(2, function()
			if (entity and IsValid(entity)) then
				local openSeq = entity:LookupSequence("Open")
				entity:ResetSequence(openSeq)
			end
		end)
	end,
}
