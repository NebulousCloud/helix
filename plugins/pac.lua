-- This Library is just for PAC3 Integration.
-- You must install PAC3 to make this library works.

PLUGIN.name = "PAC3 Integration"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "More Upgraded, More well organized PAC3 Integration made by Black Tea"

if (!pace) then return end

nut.pac = nut.pac or {}
nut.pac.list = nut.pac.list or {}

local meta = FindMetaTable("Player")

-- this stores pac3 part information to plugin's table'
function nut.pac.registerPart(id, outfit)
	nut.pac.list[id] = outfit
end

-- Fixing the PAC3's default stuffs to fit on Nutscript.
if (CLIENT) then
	-- fixpac command. you can fix the PAC3 errors with this.
	nut.command.add("fixpac", {
		onRun = function(client, arguments)
			RunConsoleCommand("pac_restart")
		end,
	})

	-- Disable few features of PAC3's feature.
	function PLUGIN:InitializedPlugins()
		-- remove useless PAC3 shits

		hook.Remove("HUDPaint", "pac_InPAC3Editor")
		hook.Remove("InitPostEntity", "pace_autoload_parts")
	end

	-- Remove PAC3 LoadParts
	function pace.LoadParts(name, clear, override_part)
		-- fuck your loading, pay me money bitch
	end

	-- Prohibits players from deleting their own PAC3 outfit.
	concommand.Add("pac_clear_parts", function()
		RunConsoleCommand("pac_restart")
		--STOP BREAKING STUFFS!
	end)

	-- You should be admin to access PAC3 editor.
	function PLUGIN:PrePACEditorOpen()
		local client = LocalPlayer()

		if (!client:IsSuperAdmin()) then
			return false
		end

		return true
	end
else
	-- Reject unauthorized PAC3 submits
	net.Receive("pac_submit", function(_, ply)
		if (!ply) then return end -- ???
		if (!ply:IsSuperAdmin()) then
			ply:notifyLocalized("illegalAccess")
		return end

		local data = pac.NetDeserializeTable()
		pace.HandleReceivedData(ply, data)
	end)
end

-- Get Player's PAC3 Parts.
function meta:getParts()
	if (!pac) then return end
	
	return self:getNetVar("parts", {})
end

if (SERVER) then
	function meta:addPart(uid, item)
		if (!pac) then
			ErrorNoHalt("NO PAC3!\n")
		return end
		
		local curParts = self:getParts()

		-- wear the parts.
		netstream.Start(player.GetAll(), "partWear", self, uid)
		curParts[uid] = true

		self:setNetVar("parts", curParts)
	end
	
	function meta:removePart(uid)
		if (!pac) then return end
		
		local curParts = self:getParts()

		-- remove the parts.
		netstream.Start(player.GetAll(), "partRemove", self, uid)
		curParts[uid] = nil

		self:setNetVar("parts", curParts)
	end

	function meta:resetParts()
		if (!pac) then return end
		
		netstream.Start(player.GetAll(), "partReset", self, self:getParts())
		self:setNetVar("parts", {})
	end

	function PLUGIN:PlayerLoadedChar(client, curChar, prevChar)
		-- If player is changing the char and the character ID is differs from the current char ID.
		if (prevChar and curChar:getID() != prevChar:getID()) then
			client:resetParts()
		end

		-- After resetting all PAC3 outfits, wear all equipped PAC3 outfits.
		if (curChar) then
			local inv = curChar:getInv()
			for k, v in pairs(inv:getItems()) do
				if (v:getData("equip") == true and v.pacData) then
					client:addPart(v.uniqueID, v)
				end
			end
		end
	end

	function PLUGIN:PlayerInitialSpawn(client)
		netstream.Start(client, "updatePAC")
	end
else
	netstream.Hook("updatePAC", function()
		if (!pac) then return end

		for k, v in ipairs(player.GetAll()) do
			local char = v:getChar()

			if (char) then
				local parts = client:getParts()

				for pacKey, pacValue in pairs(parts) do
					if (nut.pac.list[pacKey]) then
						v:AttachPACPart(nut.pac.list[pacKey])
					end
				end
			end
		end
	end)

	netstream.Hook("partWear", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end
		
		local itemTable = nut.item.list[outfitID]
		local newPac = nut.pac.list[outfitID]

		if (nut.pac.list[outfitID]) then
			if (itemTable and itemTable.pacAdjust) then
				newPac = table.Copy(nut.pac.list[outfitID])
				newPac = itemTable:pacAdjust(newPac, wearer)
			end

			if (wearer.AttachPACPart) then
				wearer:AttachPACPart(newPac)
			else
				pac.SetupENT(wearer)

				timer.Simple(0.1, function()
					if (IsValid(wearer) and wearer.AttachPACPart) then
						wearer:AttachPACPart(newPac)
					else
						print("alright, no more PAC3 for you. Go away.")
					end
				end)
			end
		end
	end)

	netstream.Hook("partRemove", function(wearer, outfitID)
		if (!pac) then return end
		
		if (!wearer.pac_owner) then
			pac.SetupENT(wearer)
		end

		if (nut.pac.list[outfitID]) then
			if (wearer.RemovePACPart) then
				wearer:RemovePACPart(nut.pac.list[outfitID])
			else
				pac.SetupENT(wearer)
			end
		end
	end)

	netstream.Hook("partReset", function(wearer, outfitList)
		for k, v in pairs(outfitList) do
			wearer:RemovePACPart(nut.pac.list[k])
		end
	end)

	function PLUGIN:DrawPlayerRagdoll(entity)
		local ply = entity.objCache
		
		if (IsValid(ply)) then
			if (!entity.overridePAC3) then
				if ply.pac_parts then
					for _, part in pairs(ply.pac_parts) do
						if part.last_owner and part.last_owner:IsValid() then
							hook.Run("OnPAC3PartTransfered", part)
							part:SetOwner(entity)
							part.last_owner = entity
						end
					end
				end
				ply.pac_playerspawn = pac.RealTime -- used for events
				
				entity.overridePAC3 = true
			end
		end
	end

	function PLUGIN:OnEntityCreated(entity)
		local class = entity:GetClass()
		
		-- For safe progress, I skip one frame.
		timer.Simple(0.01, function()
			if (class == "prop_ragdoll") then
				if (entity:getNetVar("player")) then
					entity.RenderOverride = function()
						entity.objCache = entity:getNetVar("player")
						entity:DrawModel()
						
						hook.Run("DrawPlayerRagdoll", entity)
					end
				end
			end

			if (class:find("HL2MPRagdoll")) then
				for k, v in ipairs(player.GetAll()) do
					if (v:GetRagdollEntity() == entity) then
						entity.objCache = v
					end
				end
				
				entity.RenderOverride = function()
					entity:DrawModel()
					
					hook.Run("DrawPlayerRagdoll", entity)
				end
			end
		end)
	end

	function PLUGIN:OnCharInfoSetup(infoPanel)
		if (pac and infoPanel.model) then
			-- Get the F1 ModelPanel.
			local mdl = infoPanel.model
			local ent = mdl.Entity

			-- If the ModelPanel's Entity is valid, setup PAC3 Function Table.
			if (ent and IsValid(ent)) then
				-- Setup function table.
				pac.SetupENT(ent)

				local parts = LocalPlayer():getParts()

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

	for k, v in pairs(items) do
		if (v.pacData) then
			nut.pac.list[v.uniqueID] = v.pacData
		end
	end
end