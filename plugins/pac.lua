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

function charMeta:getParts()
	if (!pac) then return end
	
	return self:getVar("parts", {})
end

if (SERVER) then
	function charMeta:addPart(uid)
		if (!pac) then return end
		
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

		-- and restore all shits, mate.
		if (curChar) then
			local inv = curChar:getInv()
			for k, v in pairs(inv:getItems()) do
				if (v:getData("equip") == true and v.pacData) then
					curChar:addPart(v.uniqueID)
				end
			end
		end
	end
else
	netstream.Hook("partWear", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			print(outfitID)
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
		if (infoPanel.model) then
			local mdl = infoPanel.model
			local ent = mdl.Entity

			if (ent and IsValid(ent)) then
				pac.SetupENT(ent)

				local char = LocalPlayer():getChar()
				local parts = char:getParts()

				for k, v in pairs(parts) do
					if (nut.pac.list[k]) then
						ent:AttachPACPart(nut.pac.list[k])
					end
				end
			end
			
			function mdl:DrawModel()
				local curparent = self
				local rightx = self:GetWide()
				local leftx = 0
				local topy = 0
				local bottomy = self:GetTall()
				local previous = curparent

				while(curparent:GetParent() != nil) do
					curparent = curparent:GetParent()
					local x,y = previous:GetPos()
					topy = math.Max(y, topy+y)
					leftx = math.Max(x, leftx+x)
					bottomy = math.Min(y+previous:GetTall(), bottomy + y)
					rightx = math.Min(x+previous:GetWide(), rightx + x)
					previous = curparent
				end

				render.SetScissorRect(leftx,topy,rightx, bottomy, true)
					ent.forceDraw = true
					pac.RenderOverride(ent, "opaque")
					pac.RenderOverride(ent, "translucent", true)
					self.Entity:DrawModel()
				render.SetScissorRect(0,0,0,0, false)
			end
		end
	end
end

function PLUGIN:InitializedPlugins()
	local items = nut.item.list

	for k, v in pairs(items) do
		if (v.pacData) then
			nut.pac.list[v.uniqueID] = v.pacData
			print("Registered .. " .. v.uniqueID)
		end
	end
end