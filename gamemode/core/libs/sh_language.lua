nut.lang = nut.lang or {}
nut.lang.stored = nut.lang.stored or {}

function nut.lang.loadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/sh_*.lua", "LUA")) do
		local niceName = v:sub(4, -5):lower()

		LANGUAGE = nut.lang.stored[niceName] or {}
			nut.util.include(directory.."/"..v, "shared")
			nut.lang.stored[niceName] = LANGUAGE
		LANGUAGE = nil
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
else
	NUT_CVAR_LANG = CreateClientConVar("nut_language", "english", true, true)

	cvars.AddChangeCallback("nut_language", function()
		MsgN("You may need to rejoin the server to see changes apply.")
	end)

	function L(key, ...)
		local languages = nut.lang.stored
		local langKey = NUT_CVAR_LANG:GetString()
		local info = languages[langKey] or languages.english
		
		return FormatString(info and info[key] or key, ...)
	end
end