
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

			ix.lang.AddTable(niceName, LANGUAGE)
			LANGUAGE = nil
		end
	end
end

function ix.lang.AddTable(language, data)
	language = tostring(language):lower()
	ix.lang.stored[language] = table.Merge(ix.lang.stored[language] or {}, data)
end

local FormatString = string.format

if (SERVER) then
	-- luacheck: globals L
	function L(key, client, ...)
		local languages = ix.lang.stored
		local langKey = ix.option.Get(client, "language", "english")
		local info = languages[langKey] or languages.english

		return FormatString(info and info[key] or key, ...)
	end

	-- luacheck: globals L2
	function L2(key, client, ...)
		local languages = ix.lang.stored
		local langKey = ix.option.Get(client, "language", "english")
		local info = languages[langKey] or languages.english

		if (info and info[key]) then
			return FormatString(info[key], ...)
		end
	end
else
	function L(key, ...)
		local languages = ix.lang.stored
		local langKey = ix.option.Get("language", "english")
		local info = languages[langKey] or languages.english

		return FormatString(info and info[key] or key, ...)
	end

	function L2(key, ...)
		local langKey = ix.option.Get("language", "english")
		local info = ix.lang.stored[langKey]

		if (info and info[key]) then
			return FormatString(info[key], ...)
		end
	end
end
