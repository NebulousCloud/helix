-- This Library is just for PAC3 Integration.
-- You must install PAC3 / PAC3_Lite to make this library works.
-- Currently, PAC3 Lite is more friendly to NutScript.
PLUGIN.name = "PAC3 Integration"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "It's PAC3 Integration for Nutscript.\nYou can get friendly version in here.\nPAC3 Lite(github link.)"

nut.pac = nut.pac or {}
nut.pac.list = nut.pac.list or {}

local charMeta = nut.meta.character

function nut.pac.registerPart(id, outfit)
	nut.pac.list[id] = outfit
end

function charMeta:getParts()
	if (!pac) then return end
	
	return self:getVar("parts", {})
end

if (SERVER) then
	function charMeta:addPart(uid)
		if (!pac) then
			nut.log.add("Got PAC3 Request. But, Server does not have PAC!", FLAG_DANGER, 100, true)
		return end
		
		local curParts = self:getParts()

		-- wear the parts.
		netstream.Start(player.GetAll(), "partWear", self:getPlayer(), uid)
		curParts[uid] = true

		self:setVar("parts", curParts)
	end

	function charMeta:removePart(uid)
		if (!pac) then return end
		
		local curParts = self:getParts()

		-- remove the parts.
		netstream.Start(player.GetAll(), "partRemove", self:getPlayer(), uid)
		curParts[uid] = nil

		self:setVar("parts", curParts)
	end

	function charMeta:resetParts()
		if (!pac) then return end
		
		netstream.Start(player.GetAll(), "partReset", self:getPlayer(), self:getParts())
		self:setVar("parts", {})
	end

	-- If player changes the char, remove all the vehicles on the server.
	function PLUGIN:PlayerLoadedChar(client, curChar, prevChar)
		-- If player is changing the char and the character ID is differs from the current char ID.
		if (prevChar and curChar:getID() != prevChar:getID()) then
			prevChar:resetParts()
		end

		-- After resetting all PAC3 outfits, wear all equipped PAC3 outfits.
		if (curChar) then
			local inv = curChar:getInv()
			for k, v in pairs(inv:getItems()) do
				if (v:getData("equip") == true and v.pacData) then
					curChar:addPart(v.uniqueID)
				end
			end
		end
	end

	function PLUGIN:PlayerInitialSpawn(client)
		netstream.Start(client, "updatePAC")
	end

	function PLUGIN:OnCharFallover(client, ragdoll, isFallen)
		if (client and ragdoll and client:IsValid() and ragdoll:IsValid() and client:getChar() and isFallen) then
			netstream.Start(player.GetAll(), "ragdollPAC", client, ragdoll, isFallen)
		end
	end
else
	netstream.Hook("updatePAC", function()
		if (!pac) then return end

		for k, v in ipairs(player.GetAll()) do
			local char = v:getChar()

			if (char) then
				local parts = char:getParts()

				for pacKey, pacValue in pairs(parts) do
					if (nut.pac.list[pacKey]) then
						v:AttachPACPart(nut.pac.list[pacKey])
					end
				end
			end
		end
	end)

	netstream.Hook("ragdollPAC", function(client, ragdoll, isFallen)
		if (!pac) then return end
		
		if (client and ragdoll) then
			local parts = client:getChar():getParts()

			pac.SetupENT(ragdoll)

			for pacKey, pacValue in pairs(parts) do
				if (nut.pac.list[pacKey]) then
					ragdoll:AttachPACPart(nut.pac.list[pacKey])
				end
			end
		end
	end)

	netstream.Hook("partWear", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			wearer:AttachPACPart(nut.pac.list[outfitID])
		end
	end)

	netstream.Hook("partRemove", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			wearer:RemovePACPart(nut.pac.list[outfitID])
		end
	end)

	netstream.Hook("partReset", function(wearer, outfitList)
		for k, v in pairs(outfitList) do
			wearer:RemovePACPart(nut.pac.list[k])
		end
	end)

	function PLUGIN:OnCharInfoSetup(infoPanel)
		if (pac and infoPanel.model) then
			-- Get the F1 ModelPanel.
			local mdl = infoPanel.model
			local ent = mdl.Entity

			-- If the ModelPanel's Entity is valid, setup PAC3 Function Table.
			if (ent and IsValid(ent)) then
				-- Setup function table.
				pac.SetupENT(ent)

				local char = LocalPlayer():getChar()
				local parts = char:getParts()

				-- Wear current player's PAC3 Outfits on the ModelPanel's Clientside Model Entity.
				for k, v in pairs(parts) do
					if (nut.pac.list[k]) then
						ent:AttachPACPart(nut.pac.list[k])
					end
				end
				
				-- Overrride Model Drawing function of ModelPanel. (Function revision: 2015/01/05)
				-- by setting ent.forcedraw true, The PAC3 outfit will drawn on the model even if it's NoDraw Status is true.
				ent.forceDraw = true
			end
		end
	end

	function PLUGIN:DrawNutModelView(panel, ent)
		if (LocalPlayer():getChar()) then
			if (pac) then
				pac.RenderOverride(ent, "opaque")
				pac.RenderOverride(ent, "translucent", true)
			end
		end
	end
end

function PLUGIN:InitializedPlugins()
	local items = nut.item.list

	-- Get all items and If pacData is exists, register new outfit.
	for k, v in pairs(items) do
		if (v.pacData) then
			nut.pac.list[v.uniqueID] = v.pacData
		end
	end
end