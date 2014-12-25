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

nut.lang = nut.lang or {}
nut.lang.stored = nut.lang.stored or {}
nut.lang.names = nut.lang.names or {}

function nut.lang.loadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/sh_*.lua", "LUA")) do
		local niceName = v:sub(4, -5):lower()

		nut.util.include(directory.."/"..v, "shared")

		if (LANGUAGE) then
			if (NAME) then
				nut.lang.names[niceName] = NAME
				NAME = nil
			end
			
			nut.lang.stored[niceName] = table.Merge(nut.lang.stored[niceName] or {}, LANGUAGE)
			LANGUAGE = nil
		end
	end
end

local FormatString = string.format

if (SERVER) then
	local ClientGetInfo = FindMetaTable("Player").GetInfo

	function L(key, client, ...)
		local languages = nut.lang.stored
		local langKey = ClientGetInfo(client, "nut_language")
		local info = languages[langKey] or languages.english
		
		return FormatString(info and info[key] or key, ...)
	end

	function L2(key, client, ...)
		local languages = nut.lang.stored
		local langKey = ClientGetInfo(client, "nut_language")
		local info = languages[langKey] or languages.english
		
		if (info and info[key]) then
			return FormatString(info[key], ...)
		end
	end
else
	NUT_CVAR_LANG = CreateClientConVar("nut_language", "english", true, true)

	function L(key, ...)
		local languages = nut.lang.stored
		local langKey = NUT_CVAR_LANG:GetString()
		local info = languages[langKey] or languages.english
		
		return FormatString(info and info[key] or key, ...)
	end

	function L2(key, ...)
		local langKey = NUT_CVAR_LANG:GetString()
		local info = nut.lang.stored[langKey]

		if (info and info[key]) then
			return FormatString(info[key], ...)
		end
	end
end