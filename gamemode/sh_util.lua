--[[
	Purpose: Provides utility functions used by libraries and core
	framework files.
--]]

include("libs/sh_netstream.lua")

nut.util = {}

hook.Add("EntityKeyValue", "nut_StoreKeyValues", function(entity, key, value)
	entity.nut_KeyValues = entity.nut_KeyValues or {}
	entity.nut_KeyValues[key] = value
end)

--[[
	Purpose: Since Entity:GetKeyValues() is unreliable, use the key values
	retrieved from the EntityKeyValue hook to return the value for the key
	passed.
--]]
function nut.util.GetEntityKeyValues(entity)
	return entity.nut_KeyValues
end

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
	Purpose: Gets the appropriate alpha value for colors using two vectors.
--]]
function nut.util.GetAlphaFromDist(position, goal, maxDistance, maxAlpha)
	maxAlpha = maxAlpha or 255
	local distance = goal:Distance(position)

	return (1 - distance / maxDistance) * maxAlpha
end

--[[
	Purpose: Creates a string of random numbers by added random numbers to a string
	x times, where x is the number of digits specified.
--]]
function nut.util.GetRandomNum(digits)
	if (digits <= 1) then
		error("Number of digits must be greater than 1.")
	end

	math.randomseed(CurTime())

	local output = ""

	for i = 1, digits do
		output = output..math.Clamp(math.Round(math.random(0, 999) / 100), 0, 9)
	end

	return output
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
		file.CreateDir("nutscript")
		file.CreateDir("nutscript/data")
		file.CreateDir("nutscript/"..SCHEMA.uniqueID)
	end)

	-- Table to cache tables that are to be saved/loaded.
	nut.util.cachedTable = nut.util.cachedTable or {}

	--[[
		Purpose: Encodes a table using vON and saves it to data/nutscript/<schema> if global
		is not true, or data/nutscript/data if it is. The table is also stored in a cache for
		later retrieval without needing to read the file each time.
	--]]
	function nut.util.WriteTable(uniqueID, value, ignoreMap, global)
		if (type(value) != "table") then
			value = {value}
		end

		local encoded = von.serialize(value)
		local map = !ignoreMap and game.GetMap() or ""

		if (!global) then
			file.Write("nutscript/"..SCHEMA.uniqueID.."/"..map..uniqueID..".txt", encoded)
		else
			file.Write("nutscript/data/"..map..uniqueID..".txt", encoded)
		end

		nut.util.cachedTable[uniqueID] = value
	end

	--[[
		Purpose: If the data has not been cached or forceRefresh is true, read the file from either
		the global data if it exists, otherwise the current schema's data folder, then decode the vON
		encoded data and cache it. If it does exist, then the cached copy will be returned.
	--]]
	function nut.util.ReadTable(uniqueID, ignoreMap, forceRefresh)
		local map = !ignoreMap and game.GetMap() or ""

		if (!forceRefresh and nut.util.cachedTable[uniqueID]) then
			return nut.util.cachedTable[uniqueID]
		end

		local contents = file.Read("nutscript/data/"..map..uniqueID..".txt", "DATA")

		if (!contents or contents == "") then
			contents = file.Read("nutscript/"..SCHEMA.uniqueID.."/"..map..uniqueID..".txt", "DATA")
		end

		if (contents) then
			local decoded = von.deserialize(contents)

			if (decoded) then
				nut.util.cachedTable[uniqueID] = decoded
			end

			return decoded
		end

		return {}
	end

	function nut.util.Notify(message, ...)
		local receivers = {...}

		if (#receivers == 0) then
			MsgN(message)
			receivers = nil
		end

		netstream.Start(receivers, "nut_Notice", message)
	end

	function nut.util.SendIntroFade(client)
		if (nut.schema.Call("PlayerShouldSeeIntro", client) == false) then
			return
		end

		netstream.Start(client, "nut_FadeIntro")
	end

	function nut.util.BlastDoor(door, direction, time, noCheck)
		if (!door:IsDoor()) then
			return
		end

		if (IsValid(door.dummy)) then
			door.dummy:Remove()
		end

		if (!noCheck) then
			for k, v in pairs(ents.FindInSphere(door:GetPos(), 128)) do
				if (parent != v and v != door and string.find(v:GetClass(), "door")) then
					nut.util.BlastDoor(v, direction, time, true)
				end
			end
		end

		direction = direction or Vector(0, 0, 0)
		time = time or 180
		
		local position = door:GetPos()
		local angles = door:GetAngles()
		local model = door:GetModel()
		local skin = door:GetSkin()

		local dummy = ents.Create("prop_physics")
		dummy:SetPos(position)
		dummy:SetAngles(angles)
		dummy:SetModel(model)
		dummy:SetSkin(skin or 0)
		dummy:Spawn()
		dummy:Activate()

		timer.Simple(1.5, function()
			if (IsValid(dummy)) then
				dummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			end
		end)
		
		local physObj = dummy:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:Wake()
			physObj:SetVelocity(direction)
		end

		door.dummy = dummy
		door:Fire("unlock", "", 0)
		door:Fire("open", "", 0)

		timer.Simple(0, function()
			door:SetNoDraw(true)
			door:SetNotSolid(true)
			door:DrawShadow(false)
			door.NoUse = true
			door:DeleteOnRemove(dummy)

			timer.Create("nut_DoorRestore"..door:EntIndex(), time, 1, function()
				if (IsValid(door)) then
					if (IsValid(dummy)) then
						local uniqueID = "nut_DoorDummyFade"..dummy:EntIndex()
						local alpha = 255

						timer.Create(uniqueID, 0.1, 255, function()
							if (IsValid(dummy)) then
								alpha = alpha - 1

								dummy:SetRenderMode(RENDERMODE_TRANSALPHA)
								dummy:SetColor(Color(255, 255, 255, alpha))

								if (alpha <= 0) then
									if (IsValid(door) and door.dummy and door.dummy == dummy) then
										door.dummy = nil
									end

									dummy:Remove()
								end
							else
								timer.Remove(uniqueID)
							end
						end)
					end

					door:SetNotSolid(false)
					door:SetNoDraw(false)
					door:DrawShadow(true)
					door.NoUse = false
				end
			end)
		end)
	end
else
	netstream.Hook("nut_Notice", function(data)
		nut.util.Notify(data)
	end)

	nut.notices = nut.notices or {}

	function nut.util.Notify(message)
		if (nut.schema.Call("NoticeShouldAppear") == false) then
			return
		end

		local notice = vgui.Create("nut_Notification")
		notice:SetText(message)
		notice:SetPos(ScrW() * 0.3, -24)
		notice:SetWide(ScrW() * 0.4)
		notice:LerpPositions(1.5, true)
		notice:SetPos(ScrW() * 0.3, ScrH() - ((#nut.notices + 1) * 28))

		notice:CallOnRemove(function()
			for k, v in pairs(nut.notices) do
				if (v == notice) then
					table.remove(nut.notices, k)
				end
			end

			for k, v in pairs(nut.notices) do
				v:SetPos(ScrW() * 0.3, ScrH() - (k * 28))
			end

			nut.schema.Call("NoticeRemoved", notice)
		end)

		table.insert(nut.notices, notice)

		MsgC(Color(92, 232, 250), message.."\n")

		nut.schema.Call("NoticeCreated", notice)
	end

	--[[
		Purpose: Automatically creates a structure for drawing text with a shadow. By default the
		font is the target font, color is white, and the text alignment is centered on both axes.
	--]]
	function nut.util.DrawText(x, y, text, color, font, xalign, yalign)
		color = color or Color(255, 255, 255)

		draw.SimpleTextOutlined(tostring(text), font or "nut_TargetFont", x, y, color, xalign or 1, yalign or 1, 1, Color(0, 0, 0, color.a * 0.7))
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
		if (lines) then
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

	hook.Add("InitPostEntity", "nut_TimeInitialize", function()
		nut.connectTime = RealTime()
	end)

	function nut.util.TimeConnected()
		local realTime = RealTime()

		-- Subtract five since we have the 5 second delay for loading.
		return realTime - (nut.connectTime or realTime) - 5
	end
end

--[[
	Purpose: Gathers up all the differences between the 'delta' table
	and a source table and returns them as a table of changes. This function
	is also used for nut.util.IsSimilarTable to return a boolean of whether
	there is any change or not.
--]]
function nut.util.GetTableDelta(a, b)
	local output = {}

	for k, v in pairs(a) do
		if (type(v) == "table" and type(b[k]) == "table") then
			local output2 = nut.util.GetTableDelta(v, b[k])

			for k2, v2 in pairs(output2) do
				output[k] = output[k] or {}
				output[k][k2] = v2
			end
		elseif (b[k] == nil or b[k] != v) then
			output[k] = v or "__nil"
		end
	end

	for k, v in pairs(b) do
		if (type(v) == "table" and type(a[k]) == "table") then
			local output2 = nut.util.GetTableDelta(a[k], v)

			for k2, v2 in pairs(output2) do
				output[k] = output[k] or {}
				output[k][k2] = v2
			end
		elseif (a[k] == nil) then
			output[k] = "__nil"
		end
	end

	return output
end

--[[
	Purpose: Checks whether two tables have the same keys with the
	same values by checking their delta. If there are any differences,
	the function will return false.
--]]
function nut.util.IsSimiarTable(a, b)
	return table.Count(nut.util.GetTableDelta(a, b)) == 0
end

function nut.util.StackInv(inventory, class, quantity, data)
	local stack, index
	quantity = quantity or 1

	inventory[class] = inventory[class] or {}
	
	for k, v in pairs(inventory[class]) do
		if (data and v.data and nut.util.IsSimiarTable(v.data, data)) then
			stack = v
			index = k

			break
		elseif (!data and !v.data) then
			stack = v
			index = k

			break
		end
	end

	-- Here we see if the item should be added or removed.
	if (!stack and quantity > 0) then
		table.insert(inventory[class], {quantity = quantity, data = data})
	else
		stack = stack or {}
		index = index or table.GetFirstKey(inventory[class])
		-- A stack already exists, so add or take from it.
		stack.quantity = (stack.quantity or 0) + quantity
		
		-- If the quantity is negative, meaning we take from the stack, remove
		-- the stack from the inventory.
		if (stack.quantity <= 0 and inventory[class][index]) then
			inventory[class][index] = nil
		end

		-- If there is nothing completely in the class, remove it from the inventory
		-- completely to reduce data that is saved.
		if (table.Count(inventory[class]) <= 0) then
			inventory[class] = nil
		end
	end

	return inventory
end

--[[
	Purpose: Finds the closest player to a given position by looping through
	each player and determining if their distance is lower than the
	last. This function will return the closest player and the distance for
	that player.
--]]
function nut.util.FindClosestPlayer(position)
	local distance = 32768 -- maximum map size.
	local client

	for k, v in pairs(player.GetAll()) do
		local theirDistance = v:GetPos():Distance(position)

		if (theirDistance < distance) then
			distance = theirDistance
			client = v
		end
	end

	return client, distance
end

if (SERVER) then
	hook.Add("InitPostEntity", "nut_StartTime", function()
		nut.initTime = RealTime()
	end)
end

function nut.util.GetTime()
	local curTime = nut.curTime or 0
	local length = nut.config.dateMinuteLength
	local multiplier = 60 / length

	if (SERVER) then
		local realTime = RealTime() - (nut.initTime or 0)

		return (curTime + realTime) * multiplier
	else
		return (curTime + nut.util.TimeConnected()) * multiplier
	end

	return 0
end

local date = os.date
local time = os.time

function nut.util.GetUTCTime()
	return time(date("!*t"))
end

if (SERVER) then
	local playerMeta = FindMetaTable("Player")

	function playerMeta:StringRequest(title, text, onConfirm, onCancel, default)
		self:SetNutVar("reqConfirm", onConfirm)
		self:SetNutVar("reqCancel", onCancel)

		title = title or "String Request"
		text = text or "No message"
		
		if (!onConfirm) then
			error("Attempt to create string request without confirm callback.")
		end

		netstream.Start(self, "nut_StringRequest", {title, text, default})
	end

	function playerMeta:ScreenFadeIn(time, color)
		time = time or 5
		color = color or Color(25, 25, 25)

		netstream.Start(self, "nut_FadeIn", {color, time})
	end

	function playerMeta:ScreenFadeOut(time, color)
		netstream.Start(self, "nut_FadeOut", {time or 5, color})
	end

	netstream.Hook("nut_StringRequest", function(client, data)
		local responseCode = data[1]
		local text = data[2]

		if (responseCode and text) then
			if (responseCode == 0) then
				local onConfirm = client:GetNutVar("reqConfirm")

				if (onConfirm) then
					onConfirm(text)
				end

				client:SetNutVar("reqConfirm", nil)
				client:SetNutVar("reqCancel", nil)
			elseif (responseCode == 1) then
				local onCancel = client:GetNutVar("reqCancel")

				if (onCancel) then
					onCancel(text)
				end

				client:SetNutVar("reqConfirm", nil)
				client:SetNutVar("reqCancel", nil)
			end
		end
	end)
else
	netstream.Hook("nut_StringRequest", function(data)
		local function confirm(text)
			netstream.Start("nut_StringRequest", {0, text})
		end

		local function cancel(text)
			netstream.Start("nut_StringRequest", {1, text})
		end

		Derma_StringRequest(data[1], data[2], data[3], confirm, cancel)
	end)

	netstream.Hook("nut_FadeIn", function(data)
		local color = data[1]
		local r, g, b, a = color.r, color.g, color.b, color.a or 255
		local time = data[2]
		local start = CurTime()
		local finish = start + time

		nut.fadeColor = color

		hook.Add("HUDPaint", "nut_FadeIn", function()
			local fraction = math.TimeFraction(start, finish, CurTime())

			surface.SetDrawColor(r, g, b, fraction * a)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		end)
	end)

	netstream.Hook("nut_FadeOut", function(data)
		local color = data[2] or nut.fadeColor

		if (color) then
			local r, g, b, a = color.r, color.g, color.b, color.a or 255
			local time = data[1]
			local start = CurTime()
			local finish = start + time

			hook.Add("HUDPaint", "nut_FadeIn", function()
				local fraction = 1 - math.TimeFraction(start, finish, CurTime())

				if (fraction < 0) then
					return hook.Remove("HUDPaint", "nut_FadeIn")
				end

				surface.SetDrawColor(r, g, b, fraction * a)
				surface.DrawRect(0, 0, ScrW(), ScrH())		
			end)
		end
	end)
end

function nut.util.SplitString(text, size)
	local output = {}

	while (#text > size) do
		output[#output + 1] = string.sub(text, 1, size)
		text = string.sub(text, size)
	end

	output[#output + 1] = text

	return output
end

if (SERVER) then
	function nut.util.PlaySound(source, receiver, volume, pitch)
		netstream.Start(receiver, "nut_PlaySound", {source, volume, pitch})
	end
else
	netstream.Hook("nut_PlaySound", function(data)
		LocalPlayer():EmitSound(data[1], data[2], data[3])
	end)
end


local entityMeta = FindMetaTable("Entity")

function entityMeta:IsDoor()
	return string.find(self:GetClass(), "door")
end

function entityMeta:GetDoorPartner()
	if (!self:IsDoor()) then
		error("Attempt to get partner of a non-door entity.")
	end

	local partners = {}

	for k, v in pairs(ents.FindInSphere(self:GetPos(), 128)) do
		if (v != self and v:IsDoor()) then
			partners[#partners + 1] = v
		end
	end

	return partners
end