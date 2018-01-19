
ix.lang = ix.lang or {}
ix.lang.stored = ix.lang.stored or {}
ix.lang.names = ix.lang.names or {}

function ix.lang.LoadFromDir(directory)
	for _, v in ipairs(file.Find(directory.."/sh_*.lua", "LUA")) do
		local niceName = v:sub(4, -5):lower()

		ix.util.Include(directory.."/"..v, "shared")

		if (LANGUAGE) then
			if (NAME) then
				ix.lang.names[niceName] = NAME
				NAME = nil
			end

			ix.lang.stored[niceName] = table.Merge(ix.lang.stored[niceName] or {}, LANGUAGE)
			LANGUAGE = nil
		end
	end
end

local FormatString = string.format

if (SERVER) then
	local ClientGetInfo = FindMetaTable("Player").GetInfo

	-- luacheck: globals L
	function L(key, client, ...)
		local languages = ix.lang.stored
		local langKey = ClientGetInfo(client, "ix_language")
		local info = languages[langKey] or languages.english

		return FormatString(info and info[key] or key, ...)
	end

	-- luacheck: globals L2
	function L2(key, client, ...)
		local languages = ix.lang.stored
		local langKey = ClientGetInfo(client, "ix_language")
		local info = languages[langKey] or languages.english

		if (info and info[key]) then
			return FormatString(info[key], ...)
		end
	end
else
	-- luacheck: globals IX_CVAR_LANG
	IX_CVAR_LANG = CreateClientConVar("ix_language", ix.config.language or "english", true, true)

	function L(key, ...)
		local languages = ix.lang.stored
		local langKey = IX_CVAR_LANG:GetString()
		local info = languages[langKey] or languages.english

		return FormatString(info and info[key] or key, ...)
	end

	function L2(key, ...)
		local langKey = IX_CVAR_LANG:GetString()
		local info = ix.lang.stored[langKey]

		if (info and info[key]) then
			return FormatString(info[key], ...)
		end
	end
end
