--[[
	Purpose: Provides utility functions used by libraries and core
	framework files.
--]]

nut.util = {}

--[[
	Purpose: Includes a file based of its prefix and will include it
	properly and send it to the client if needed.
--]]
function nut.util.Include(fileName, state)
	if (state == "shared" or string.find(fileName, "sh_")) then
		AddCSLuaFile(fileName)
		include(fileName)
	elseif ((state == "server" or string.find(fileName, "sv_")) and SERVER) then
		include(fileName)
	elseif (state == "client" or string.find(fileName, "cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	end
end

--[[
	Purpose: Will find all the files in the schema or framework,
	if isBase is true, and include them based of their prefixes. This is
	used for including stuff like directories with a lot of files in them like libs.
--]]
function nut.util.IncludeDir(directory, isBase)
	if (string.find(directory, "schema/") and !SCHEMA) then
		error("Too early to use the schema!")
	end

	local directory2 = (isBase and "nutscript" or SCHEMA.folderName).."/gamemode/"..directory.."/*.lua"

	for k, v in pairs(file.Find(directory2, "LUA")) do
		nut.util.Include(directory.."/"..v)
	end
end

-- C++ Weapons do not have their holdtypes accessible by Lua.
local holdTypes = {
	weapon_physgun = "smg",
	weapon_physcannon = "smg",
	weapon_stunstick = "melee",
	weapon_crowbar = "melee",
	weapon_stunstick = "melee",
	weapon_357 = "pistol",
	weapon_pistol = "pistol",
	weapon_smg1 = "smg",
	weapon_ar2 = "smg",
	weapon_crossbow = "smg",
	weapon_shotgun = "shotgun",
	weapon_frag = "grenade",
	weapon_slam = "grenade",
	weapon_rpg = "shotgun",
	weapon_bugbait = "melee",
	weapon_annabelle = "shotgun",
	gmod_tool = "pistol"
}

-- We don't want to make a table for all of the holdtypes, so just alias them.
local translateHoldType = {
	melee2 = "melee",
	fist = "melee",
	knife = "melee",
	ar2 = "smg",
	physgun = "smg",
	crossbow = "smg",
	slam = "grenade",
	passive = "normal",
	rpg = "shotgun"
}

--[[
	Purpose: Returns the weapon's holdtype for stuff like animation by either returning the holdtype
	from the table if it exists or if it is a SWEP return that one or fallback on normal.
--]]
function nut.util.GetHoldType(weapon)
	local holdType = holdTypes[weapon:GetClass()]

	if (holdType) then
		return holdType
	elseif (weapon.HoldType) then
		return translateHoldType[weapon.HoldType] or weapon.HoldType
	else
		return "normal"
	end
end

--[[
	Purpose: Checks two strings in multiple ways to see if they match.
	This is used for identifying players based off a given string.
--]]
function nut.util.StringMatches(a, b)
	if (a == b) then
		return true
	end

	if (string.lower(a) == string.lower(b)) then
		return true
	end

	if (string.find(a, b) or string.find(b, a)) then
		return true
	end

	a = string.lower(a)
	b = string.lower(b)

	if (string.find(a, b) or string.find(b, a)) then
		return true
	end

	return false
end

--[[
	Purpose: Retrieves a player if his/her name matches the given string
	using nut.util.StringMatches(a, b).
--]]
function nut.util.FindPlayer(name)
	for k, v in pairs(player.GetAll()) do
		if (nut.util.StringMatches(v:Name(), name)) then
			return v
		end
	end
end

if (SERVER) then
	-- Create needed directories here since using file.Write will no longer autocreate directories.
	hook.Add("SchemaInitialized", "nut_CreateFiles", function()
		if (!file.IsDir("nutscript", "DATA")) then
			file.CreateDir("nutscript")
		end

		if (!file.IsDir("nutscript/data", "DATA")) then
			file.CreateDir("nutscript/data")
		end
		
		if (!file.IsDir("nutscript/"..SCHEMA.folderName, "DATA")) then
			file.CreateDir("nutscript/"..SCHEMA.folderName)
		end
	end)

	-- Table to cache tables that are to be saved/loaded.
	nut.util.cachedTable = nut.util.cachedTable or {}

	--[[
		Purpose: Encodes a table using vON and saves it to data/nutscript/<schema> if global
		is not true, or data/nutscript/data if it is. The table is also stored in a cache for
		later retrieval without needing to read the file each time.
	--]]
	function nut.util.WriteTable(uniqueID, value, global)
		local encoded = von.serialize(value)

		if (!global) then
			file.Write("nutscript/"..SCHEMA.folderName.."/"..uniqueID..".txt", encoded)
		else
			file.Write("nutscript/data/"..uniqueID..".txt", encoded)
		end

		nut.util.cachedTable[uniqueID] = value
	end

	--[[
		Purpose: If the data has not been cached or forceRefresh is true, read the file from either
		the global data if it exists, otherwise the current schema's data folder, then decode the vON
		encoded data and cache it. If it does exist, then the cached copy will be returned.
	--]]
	function nut.util.ReadTable(uniqueID, forceRefresh)
		if (!forceRefresh and nut.util.cachedTable[uniqueID]) then
			return nut.util.cachedTable[uniqueID]
		end

		local contents = file.Read("nutscript/data/"..uniqueID..".txt", "DATA")

		if (!contents or contents == "") then
			contents = file.Read("nutscript/"..SCHEMA.uniqueID.."/"..uniqueID..".txt", "DATA")
		end

		if (contents) then
			local decoded = von.deserialize(contents)

			if (decoded) then
				nut.util.cachedTable[uniqueID] = decoded
			end

			return decoded
		end
	end

	function nut.util.Notify(message, ...)
		local receivers = {...}

		if (#receivers == 0) then
			receivers = player.GetAll()
		elseif (receivers[1] and type(receivers[1]) == "table") then
			receivers = receivers[1]
		end

		for k, v in pairs(receivers) do
			v:ChatPrint(message)
		end
	end
else
	--[[
		Purpose: Automatically creates a structure for drawing text with a shadow. By default the
		font is the target font, color is white, and the text alignment is centered on both axes.
	--]]
	function nut.util.DrawText(x, y, text, color, font, xalign, yalign)
		color = color or Color(255, 255, 255)

		--[[
		local data = {
			pos = {x, y},
			text = text,
			font = font or "nut_TargetFont",
			color = color,
			xalign = xalign or 1,
			yalign = yalign or 1
		}

		draw.TextShadow(data, 1, color.a or 255)
		--]]
		draw.SimpleTextOutlined(text, font or "nut_TargetFont", x, y, color, xalign or 1, yalign or 1, 1, Color(0, 0, 0, color.a * 0.7))
	end

	--[[
		Purpose: A function that returns lines in a form of tables. These lines are determined by
		whether or not the arguments provided pass a certain width, kind of like in a text editor.
		It can take colors or strings/numbers/booleans as the varargs.

		*This function isn't great since spaces are needed!
	--]]
	function nut.util.WrapText(font, width, ...)
		surface.SetFont(font or "DermaDefault")

		local lines = {}
		local currentText = ""
		local currentX = 0
		local line = {}
		local lastColor = Color(255, 255, 255)
		local x = 0
		local _, textHeight = surface.GetTextSize("W")

		for k, v in ipairs({...}) do
			if (type(v) == "table" and v.r and v.g and v.b) then
				line[#line + 1] = v
				lastColor = v
				currentText = ""
			else
				v = tostring(v)

				for k2, v2 in ipairs(string.Explode(" ", v)) do
					local textWidth = surface.GetTextSize(v2.." ")

					x = x + textWidth

					if (x > width) then
						line[#line + 1] = currentText
						lines[#lines + 1] = line

						x = textWidth
						currentText = v2.." "
						line = {}
					else
						currentText = currentText..v2.." "
					end
				end

			end

			line[#line + 1] = currentText
		end

		line = {}
		line[#line + 1] = currentText
		lines[#lines + 1] = line

		return lines, textHeight * #lines, textHeight
	end

	--[[
		Purpose: Takes the output of nut.util.WrapText and draws them on the screen.
	--]]
	function nut.util.DrawWrappedText(x, y, lines, lineHeight, font, xAlign, yAlign, alpha)
		alpha = alpha or 255

		local lastColor = Color(255, 255, 255, alpha)

		for k2, v2 in ipairs(lines) do
			local lastX = 0

			for k, v in pairs(v2) do
				if (type(v) == "table" and v.r and v.g and v.b) then
					lastColor = Color(v.r, v.g, v.b, alpha)
				else
					nut.util.DrawText(x + lastX, y + (k2 - 1) * lineHeight, v, lastColor, font, xAlign, yAlign)
					lastX = lastX + surface.GetTextSize(v)
				end
			end
		end
	end
end

function nut.util.CleanMarkup(data)
	if (type(data) == "string") then
		data = string.gsub(data, "<font(=?)", "")
		data = string.gsub(data, "<face(=?)", "")
		data = string.gsub(data, "<color(=?)", "")
		data = string.gsub(data, "<colour(=?)", "")
		data = string.gsub(data, "</color>", "")
		data = string.gsub(data, "</font>", "")
		data = string.gsub(data, "</face>", "")
		data = string.gsub(data, "</face>", "")
	end

	return data
end