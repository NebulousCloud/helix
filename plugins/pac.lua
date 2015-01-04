-- This Library is just for PAC3 Integration.
-- You must install PAC3 / PAC3_Lite to make this library works.
-- Currently, PAC3 Lite is more friendly to NutScript.
PLUGIN.name = "PAC3 Integration"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "It's PAC3 Integration for Nutscript.\nYou can get friendly version in here.\nPAC3 Lite(github link.)"

nut.pac = nut.pac or {}
nut.pac.list = nut.pac.list or {}

local charMeta = FindMetaTable("Character")

function nut.pac.registerPart(id, outfit)
	nut.pac.list[id] = outfit
end

if (SERVER) then
	function charMeta:addPart(uid)
		local curParts = self:getParts()

		-- wear the parts.
		netstream.Start(player.GetAll(), "partWear", self:getPlayer(), uid)
		curParts[uid] = true

		self:setVar("parts", curParts)
	end

	function charMeta:removePart(uid)
		local curParts = self:getParts()

		-- remove the parts.
		netstream.Start(player.GetAll(), "partRemove", self:getPlayer(), uid)
		curParts[uid] = nil

		self:setVar("parts", curParts)
	end

	function charMeta:getParts()
		return self:getVar("parts", {})
	end

	function charMeta:resetParts()
		netstream.Start(player.GetAll(), "partReset", self:getPlayer())

		self:setVar("parts", {})
	end

	-- If player changes the char, remove all the vehicles on the server.
	function PLUGIN:PlayerLoadedChar(client, curChar, prevChar)
		-- If player is changing the char and the character ID is differs from the current char ID.
		if (prevChar and curChar:getID() != prevChar:getID()) then
			curChar:resetParts()
		end
	end
else
	netstream.Hook("partWear", function(wearer, outfitID)
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			wearer:AttachPACPart(nut.pac.list[outfitID], wearer)
		end
	end)

	netstream.Hook("partRemove", function(wearer, outfitID)
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			wearer:RemovePACPart(nut.pac.list[outfitID], wearer)
		end
	end)
end