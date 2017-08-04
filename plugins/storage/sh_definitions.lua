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
	name = "Crate",
	desc = "A simple wooden crate.",
	width = 4,
	height = 4,
}

PLUGIN.definitions["models/props_c17/lockers001a.mdl"] = {
	name = "Locker",
	desc = "A white locker.",
	width = 3,
	height = 5,
}

PLUGIN.definitions["models/props_wasteland/controlroom_storagecloset001a.mdl"] = {
	name = "Metal Cabinet",
	desc = "A green metal cabinet.",
	width = 4,
	height = 5,
}

PLUGIN.definitions["models/props_wasteland/controlroom_filecabinet002a.mdl"] = {
	name = "File Cabinet",
	desc = "A metal filing cabinet.",
	width = 2,
	height = 4,
}
PLUGIN.definitions["models/props_c17/furniturefridge001a.mdl"] = {
	name = "Refrigerator",
	desc = "A metal box for keeping food in.",
	width = 2,
	height = 3,
}

PLUGIN.definitions["models/props_wasteland/kitchen_fridge001a.mdl"] = {
	name = "Large Refrigerator",
	desc = "A large metal box for storing even more food in.",
	width = 4,
	height = 5,
}
PLUGIN.definitions["models/props_junk/trashbin01a.mdl"] = {
	name = "Trash Bin",
	desc = "What do you expect to find in here?",
	width = 1,
	height = 2,
}
PLUGIN.definitions["models/items/ammocrate_smg1.mdl"] = {
	name = "Ammo Crate",
	desc = "A heavy crate that stores ammo",
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
