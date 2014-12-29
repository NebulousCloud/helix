--[[
	NutScript is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	NutScript is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

/*
	PLUGIN.definitions[model's name(lowercase)] = {
		name = "Crate",
		desc = "A simple wooden create.",
		width = 4,
		height = 4,
		locksound = "",
		opensound = "",
	}
*/

PLUGIN.definitions["models/props_junk/wood_crate001a.mdl"] = {
	name = "Crate",
	desc = "A simple wooden crate.",
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