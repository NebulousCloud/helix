if (!nut.char) then include("sh_character.lua") end

nut.attribs = nut.attribs or {}
nut.attribs.list = nut.attribs.list or {}

function nut.attribs.loadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		ATTRIBUTE = nut.attribs.list[niceName] or {}
			if (PLUGIN) then
				ATTRIBUTE.plugin = PLUGIN.uniqueID
			end

			nut.util.include(directory.."/"..v)

			ATTRIBUTE.name = ATTRIBUTE.name or "Unknown"
			ATTRIBUTE.desc = ATTRIBUTE.desc or "No description availalble."

			nut.attribs.list[niceName] = ATTRIBUTE
		ATTRIBUTE = nil
	end
end

function nut.attribs.setup(client)
	local character = client:getChar()

	if (character) then
		for k, v in pairs(nut.attribs.list) do
			if (v.onSetup) then
				v:onSetup(client, character:getAttrib(k, 0))
			end
		end
	end
end

-- Add updating of attributes to the character metatable.
do
	local charMeta = FindMetaTable("Character")
	
	if (SERVER) then
		function charMeta:updateAttrib(key, value)
			local attribute = nut.attribs.list[key]

			if (attribute) then
				local attrib = self:getAttribs()
				local client = self:getPlayer()

				attrib[key] = (attrib[key] or 0) + value

				if (IsValid(client)) then
					netstream.Start(client, "attrib", self:getID(), key, attrib[key])

					if (attribute.setup) then
						attribute.setup(attrib[key])
					end
				end
			end
		end
	else
		netstream.Hook("attrib", function(id, key, value)
			local character = nut.char.loaded[id]

			if (character) then
				character:getAttribs()[key] = value
			end
		end)
	end

	function charMeta:getAttrib(key, default)
		return self:getAttribs()[key] or default
	end
end