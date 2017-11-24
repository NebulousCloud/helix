local PLUGIN = PLUGIN
ix.command.Add("DoorSell", {
	description = "@cmdDoorSell",
	OnRun = function(self, client, arguments)
		-- Get the entity 96 units infront of the player.
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		-- Check if the entity is a valid door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			-- Check if the player owners the door.
			if (client == entity:GetDTEntity(0)) then
				-- Get the price that the door is sold for.
				local price = math.Round(entity:GetNetVar("price", ix.config.Get("doorCost")) * ix.config.Get("doorSellRatio"))

				-- Remove old door information.
				entity:RemoveDoorAccessData()

				-- Remove door information on child doors
				PLUGIN:CallOnDoorChildren(entity, function(child)
					child:RemoveDoorAccessData()
				end)

				-- Take their money and notify them.
				client:GetChar():GiveMoney(price)
				client:NotifyLocalized("dSold", ix.currency.Get(price))
				hook.Run("OnPlayerPurchaseDoor", client, entity, false, PLUGIN.CallOnDoorChildren) -- i fucking hate this life
				ix.log.Add(client, "selldoor")
			else
				-- Otherwise tell them they can not.
				client:NotifyLocalized("notOwner")
			end
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end		
	end
})

ix.command.Add("DoorBuy", {
	description = "@cmdDoorBuy",
	OnRun = function(self, client, arguments)
		-- Get the entity 96 units infront of the player.
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		-- Check if the entity is a valid door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			if (entity:GetNetVar("noSell") or entity:GetNetVar("faction") or entity:GetNetVar("class")) then
				return client:NotifyLocalized("dNotAllowedToOwn")
			end

			if (IsValid(entity:GetDTEntity(0))) then
				client:NotifyLocalized("dOwnedBy", entity:GetDTEntity(0):Name())
				return false
			end
			-- Get the price that the door is bought for.
			local price = entity:GetNetVar("price", ix.config.Get("doorCost"))

			-- Check if the player can actually afford it.
			if (client:GetChar():HasMoney(price)) then
				-- Set the door to be owned by this player.
				entity:SetDTEntity(0, client)
				entity.ixAccess = {
					[client] = DOOR_OWNER
				}
				
				PLUGIN:CallOnDoorChildren(entity, function(child)
					child:SetDTEntity(0, client)
				end)

				-- Take their money and notify them.
				client:GetChar():TakeMoney(price)
				client:NotifyLocalized("dPurchased", ix.currency.Get(price))

				hook.Run("OnPlayerPurchaseDoor", client, entity, true, PLUGIN.CallOnDoorChildren) -- i fucking hate this life
				ix.log.Add(client, "buydoor")
			else
				-- Otherwise tell them they can not.
				client:NotifyLocalized("canNotAfford")
			end
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end
	end
})

ix.command.Add("DoorSetUnownable", {
	description = "@cmdDoorSetUnownable",
	adminOnly = true,
	syntax = "[string name]",
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity
		local name = table.concat(arguments, " ")

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			-- Set it so it is unownable.
			entity:SetNetVar("noSell", true)

			-- Change the name of the door if needed.
			if (arguments[1] and name:find("%S")) then
				entity:SetNetVar("name", name)
			end

			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("noSell", true)

				if (arguments[1] and name:find("%S")) then
					child:SetNetVar("name", name)
				end
			end)

			-- Tell the player they have made the door unownable.
			client:NotifyLocalized("dMadeUnownable")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end
	end
})

ix.command.Add("DoorSetOwnable", {
	description = "@cmdDoorSetOwnable",
	adminOnly = true,
	syntax = "[string name]",
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity
		local name = table.concat(arguments, " ")

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			-- Set it so it is ownable.
			entity:SetNetVar("noSell", nil)

			-- Update the name.
			if (arguments[1] and name:find("%S")) then
				entity:SetNetVar("name", name)
			end

			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("noSell", nil)

				if (arguments[1] and name:find("%S")) then
					child:SetNetVar("name", name)
				end
			end)

			-- Tell the player they have made the door ownable.
			client:NotifyLocalized("dMadeOwnable")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end
	end
})

ix.command.Add("DoorSetFaction", {
	description = "@cmdDoorSetFaction",
	adminOnly = true,
	syntax = "[string faction]",
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			local faction

			-- Check if the player supplied a faction name.
			if (arguments[1]) then
				-- Get all of the arguments as one string.
				local name = table.concat(arguments, " ")

				-- Loop through each faction, checking the uniqueID and name.
				for k, v in pairs(ix.faction.teams) do
					if (ix.util.StringMatches(k, name) or ix.util.StringMatches(L(v.name, client), name)) then
						-- This faction matches the provided string.
						faction = v

						-- Escape the loop.
						break
					end
				end
			end

			-- Check if a faction was found.
			if (faction) then
				entity.ixFactionID = faction.uniqueID
				entity:SetNetVar("faction", faction.index)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity.ixFactionID = faction.uniqueID
					entity:SetNetVar("faction", faction.index)
				end)

				client:NotifyLocalized("dSetFaction", L(faction.name, client))
			-- The faction was not found.
			elseif (arguments[1]) then
				client:NotifyLocalized("invalidFaction")
			-- The player didn't provide a faction.
			else
				entity:SetNetVar("faction", nil)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity:SetNetVar("faction", nil)
				end)

				client:NotifyLocalized("dRemoveFaction")
			end

			-- Save the door information.
			PLUGIN:SaveDoorData()
		end
	end
})

ix.command.Add("DoorSetDisabled", {
	description = "@cmdDoorSetDisabled",
	adminOnly = true,
	syntax = "<bool disabled>",
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor()) then
			local disabled = util.tobool(arguments[1] or true)

			-- Set it so it is ownable.
			entity:SetNetVar("disabled", disabled)

			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("disabled", disabled)
			end)

			-- Tell the player they have made the door (un)disabled.
			client:NotifyLocalized("dSet"..(disabled and "" or "Not").."Disabled")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end
	end
})

ix.command.Add("DoorSetTitle", {
	description = "@cmdDoorSetTitle",
	syntax = "<string title>",
	OnRun = function(self, client, arguments)
		-- Get the door infront of the player.
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		-- Validate the door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			-- Get the supplied name.
			local name = table.concat(arguments, " ")

			-- Make sure the name contains actual characters.
			if (!name:find("%S")) then
				return client:NotifyLocalized("invalidArg", 1)
			end

			--[[
				NOTE: Here, we are setting two different networked names.
				The title is a temporary name, while the other name is the
				default name for the door. The reason for this is so when the
				server closes while someone owns the door, it doesn't save THEIR
				title, which could lead to unwanted things.
			--]]

			-- Check if they are allowed to change the door's name.
			if (entity:CheckDoorAccess(client, DOOR_TENANT)) then
				entity:SetNetVar("title", name)
			elseif (client:IsAdmin()) then
				entity:SetNetVar("name", name)

				PLUGIN:CallOnDoorChildren(entity, function(child)
					child:SetNetVar("name", name)
				end)
			else
				-- Otherwise notify the player he/she can't.
				client:NotifyLocalized("notOwner")
			end
		else
			-- Notification of the door not being valid.
			client:NotifyLocalized("dNotValid")
		end
	end
})

ix.command.Add("DoorSetParent", {
	description = "@cmdDoorSetParent",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			client.ixDoorParent = entity
			client:NotifyLocalized("dSetParentDoor")
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end		
	end
})

ix.command.Add("DoorSetChild", {
	description = "@cmdDoorSetChild",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			if (client.ixDoorParent == entity) then
				return client:NotifyLocalized("dCanNotSetAsChild")
			end

			-- Check if the player has set a door as a parent.
			if (IsValid(client.ixDoorParent)) then
				-- Add the door to the parent's list of children.
				client.ixDoorParent.ixChildren = client.ixDoorParent.ixChildren or {}
				client.ixDoorParent.ixChildren[entity:MapCreationID()] = true

				-- Set the door's parent to the parent.
				entity.ixParent = client.ixDoorParent

				client:NotifyLocalized("dAddChildDoor")

				-- Save the door information.
				PLUGIN:SaveDoorData()
				PLUGIN:CopyParentDoor(entity)
			else
				-- Tell the player they do not have a door parent.
				client:NotifyLocalized("dNoParentDoor")
			end
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end		
	end
})

ix.command.Add("DoorRemoveChild", {
	description = "@cmdDoorRemoveChild",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			if (client.ixDoorParent == entity) then
				PLUGIN:CallOnDoorChildren(entity, function(child)
					child.ixParent = nil
				end)

				entity.ixChildren = nil

				return client:NotifyLocalized("dRemoveChildren")
			end

			-- Check if the player has set a door as a parent.
			if (IsValid(entity.ixParent) and entity.ixParent.ixChildren) then
				-- Remove the door from the list of children.
				entity.ixParent.ixChildren[entity:MapCreationID()] = nil
				-- Remove the variable for the parent.
				entity.ixParent = nil

				client:NotifyLocalized("dRemoveChildDoor")

				-- Save the door information.
				PLUGIN:SaveDoorData()
			end
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end		
	end
})

ix.command.Add("DoorSetHidden", {
	description = "@cmdDoorSetHidden",
	adminOnly = true,
	syntax = "<bool hidden>",
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor()) then
			local hidden = util.tobool(arguments[1] or true)

			entity:SetNetVar("hidden", hidden)
			
			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("hidden", hidden)
			end)

			-- Tell the player they have made the door (un)hidden.
			client:NotifyLocalized("dSet"..(hidden and "" or "Not").."Hidden")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:NotifyLocalized("dNotValid")
		end
	end
})

ix.command.Add("DoorSetClass", {
	description = "@cmdDoorSetClass",
	adminOnly = true,
	syntax = "[string faction]",
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and !entity:GetNetVar("disabled")) then
			local class, classData

			if (arguments[1]) then
				local name = table.concat(arguments, " ")

				for k, v in pairs(ix.class.list) do
					if (ix.util.StringMatches(v.name, name) or ix.util.StringMatches(L(v.name, client), name)) then
						class, classData = k, v

						break
					end
				end
			end

			-- Check if a faction was found.
			if (class) then
				entity.ixClassID = class
				entity:SetNetVar("class", class)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity.ixClassID = class
					entity:SetNetVar("class", class)
				end)

				client:NotifyLocalized("dSetClass", L(classData.name, client))
			elseif (arguments[1]) then
				client:NotifyLocalized("invalidClass")
			else
				entity:SetNetVar("class", nil)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity:SetNetVar("class", nil)
				end)

				client:NotifyLocalized("dRemoveClass")
			end

			PLUGIN:SaveDoorData()
		end
	end,
	alias = {"jobdoor"}
})
