-- Includes a file from the prefix.
function nut.util.include(fileName, state)
	-- Only include server-side if we're on the server.
	if ((state == "server" or fileName:find("sv_")) and SERVER) then
		include(fileName)
	-- Shared is included by both server and client.
	elseif (state == "shared" or fileName:find("sh_")) then
		if (SERVER) then
			-- Send the file to the client if shared so they can run it.
			AddCSLuaFile(fileName)
		end

		include(fileName)
	-- File is sent to client, included on client.
	elseif (state == "client" or fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	end
end

-- Include files based off the prefix within a directory.
function nut.util.includeDir(directory)
	-- By default, we include relatively to NutScript.
	local baseDir = "nutscript"

	-- If we're in a schema, include relative to the schema.
	if (SCHEMA and SCHEMA.folder and GM and GM.FolderName != "nutscript") then
		baseDir = SCHEMA.folder
	end

	-- Find all of the files within the directory.
	for k, v in ipairs(file.Find(baseDir.."/gamemode/"..directory.."/*.lua", "LUA")) do
		-- Include the file from the prefix.
		nut.util.include(directory.."/"..v)
	end
end

-- Returns a single cached copy of a material or creates it if it doesn't exist.
function nut.util.getMaterial(materialPath)
	-- Cache the material.
	nut.util.cachedMaterials = nut.util.cachedMaterials or {}
	nut.util.cachedMaterials[materialPath] = nut.util.cachedMaterials[materialPath] or Material(materialPath)

	return nut.util.cachedMaterials[materialPath]
end

-- Finds a player by matching their names.
function nut.util.findPlayer(name)
	for k, v in ipairs(player.GetAll()) do
		if (nut.util.stringMatches(v:Name(), name)) then
			return v
		end
	end
end

-- Returns whether or a not a string matches.
function nut.util.stringMatches(a, b)
	local a2, b2 = a:lower(), b:lower()

	-- Check if the actual letters match.
	if (a == b) then return true end
	if (a2 == b2) then return true end

	-- Be less strict and search.
	if (a:find(b)) then return true end
	if (a2:find(b2)) then return true end

	return false
end

if (CLIENT) then
	local blur = nut.util.getMaterial("pp/blurscreen")

	-- Draws a blurred material over the screen, to blur things.
	function nut.util.drawBlur(panel, amount)
		-- Intensity of the blur.
		amount = amount or 5

		surface.SetMaterial(blur)
		surface.SetDrawColor(255, 255, 255)

		local x, y = panel:LocalToScreen(0, 0)
		
		for i = 0.2, 1, 0.2 do
			-- Do things to the blur material to make it blurry.
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			-- Draw the blur material over the screen.
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	-- Draw a text with a shadow.
	function nut.util.drawText(text, x, y, color, alignX, alignY, font, alpha)
		color = color or color_white

		draw.TextShadow({
			text = text,
			font = font or "nutGenericFont",
			pos = {x, y},
			color = color,
			xalign = alignX or 0,
			yalign = alignY or 0
		}, 1, alpha or (color.a * 0.575))
	end
end

-- Utility entity extensions.
do
	local entityMeta = FindMetaTable("Entity")

	function entityMeta:isDoor()
		return self:GetClass():find("door")
	end
end

-- Misc. player stuff.
do
	local playerMeta = FindMetaTable("Player")
	local ALWAYS_RAISED = {}
	ALWAYS_RAISED["weapon_physgun"] = true
	ALWAYS_RAISED["gmod_tool"] = true

	function playerMeta:isWepRaised()
		local weapon = self:GetActiveWeapon()

		if (IsValid(weapon) and ALWAYS_RAISED[weapon:GetClass()]) then
			return true
		end

		return self:getNetVar("raised", false)
	end

	if (SERVER) then
		function playerMeta:setWepRaised(state)
			self:setNetVar("raised", state)

			local weapon = self:GetActiveWeapon()

			if (IsValid(weapon)) then
				weapon:SetNextPrimaryFire(CurTime() + 1)
				weapon:SetNextSecondaryFire(CurTime() + 1)
			end
		end

		function playerMeta:toggleWepRaised()
			self:setWepRaised(!self:isWepRaised())
		end
	end
end