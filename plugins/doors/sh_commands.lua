local PLUGIN = PLUGIN

nut.command.add("doorbuy", {
	onRun = function(client, arguments)
		-- Get the entity 96 units infront of the player.
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		-- Check if the entity is a valid door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			if (entity:getNetVar("noSell") or IsValid(entity:getNetVar("owner")) or entity:getNetVar("faction")) then
				return client:notifyLocalized("dNotAllowedToOwn")
			end

			-- Get the price that the door is bought for.
			local price = entity:getNetVar("price", nut.config.get("doorCost"))

			-- Check if the player can actually afford it.
			if (client:getChar():hasMoney(price)) then
				-- Set the door to be owned by this player.
				entity:setNetVar("owner", client)
				entity.nutAccess = {
					[client] = DOOR_OWNER
				}
				
				PLUGIN:callOnDoorChildren(entity, function(child)
					child:setNetVar("owner", client)
				end)

				-- Take their money and notify them.
				client:getChar():takeMoney(price)
				client:notifyLocalized("dPurchased", nut.currency.get(price))
			else
				-- Otherwise tell them they can not.
				client:notifyLocalized("canNotAfford")
			end
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end
	end
})

nut.command.add("doorsell", {
	onRun = function(client, arguments)
		-- Get the entity 96 units infront of the player.
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		-- Check if the entity is a valid door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			-- Check if the player owners the door.
			if (client == entity:getNetVar("owner")) then
				-- Get the price that the door is sold for.
				local price = math.Round(entity:getNetVar("price", nut.config.get("doorCost")) * nut.config.get("doorSellRatio"))

				-- Remove old door information.
				entity:removeDoorAccessData()

				-- Remove door information on child doors
				PLUGIN:callOnDoorChildren(entity, function(child)
					print(child)
					child:removeDoorAccessData()
				end)

				-- Take their money and notify them.
				client:getChar():giveMoney(price)
				client:notifyLocalized("dSold", nut.currency.get(price))
			else
				-- Otherwise tell them they can not.
				client:notifyLocalized("notOwner")
			end
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end		
	end
})

nut.command.add("doorsetunownable", {
	adminOnly = true,
	syntax = "[string name]",
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity
		local name = table.concat(arguments, " ")

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			-- Set it so it is unownable.
			entity:setNetVar("noSell", true)

			-- Change the name of the door if needed.
			if (arguments[1] and name:find("%S")) then
				entity:setNetVar("name", name)
			end

			PLUGIN:callOnDoorChildren(entity, function(child)
				child:setNetVar("noSell", true)

				if (arguments[1] and name:find("%S")) then
					child:setNetVar("name", name)
				end
			end)

			-- Tell the player they have made the door unownable.
			client:notifyLocalized("dMadeUnownable")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end
	end
})

nut.command.add("doorsetownable", {
	adminOnly = true,
	syntax = "[string name]",
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity
		local name = table.concat(arguments, " ")

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			-- Set it so it is ownable.
			entity:setNetVar("noSell", nil)

			-- Update the name.
			if (arguments[1] and name:find("%S")) then
				entity:setNetVar("name", name)
			end

			PLUGIN:callOnDoorChildren(entity, function(child)
				child:setNetVar("noSell", nil)

				if (arguments[1] and name:find("%S")) then
					child:setNetVar("name", name)
				end
			end)

			-- Tell the player they have made the door ownable.
			client:notifyLocalized("dMadeOwnable")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end
	end
})

nut.command.add("doorsetfaction", {
	adminOnly = true,
	syntax = "[string faction]",
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			local faction

			-- Check if the player supplied a faction name.
			if (arguments[1]) then
				-- Get all of the arguments as one string.
				local name = table.concat(arguments, " ")

				-- Loop through each faction, checking the uniqueID and name.
				for k, v in pairs(nut.faction.teams) do
					if (nut.util.stringMatches(k, name) or nut.util.stringMatches(L(v.name, client), name)) then
						-- This faction matches the provided string.
						faction = v

						-- Escape the loop.
						break
					end
				end
			end

			-- Check if a faction was found.
			if (faction) then
				entity.nutFactionID = faction.uniqueID
				entity:setNetVar("faction", faction.index)

				PLUGIN:callOnDoorChildren(entity, function()
					entity.nutFactionID = faction.uniqueID
					entity:setNetVar("faction", faction.index)
				end)

				client:notifyLocalized("dSetFaction", L(faction.name, client))
			-- The faction was not found.
			elseif (arguments[1]) then
				client:notifyLocalized("invalidFaction")
			-- The player didn't provide a faction.
			else
				entity:setNetVar("faction", nil)

				PLUGIN:callOnDoorChildren(entity, function()
					entity:setNetVar("faction", nil)
				end)

				client:notifyLocalized("dRemoveFaction")
			end

			-- Save the door information.
			PLUGIN:SaveDoorData()
		end
	end
})

nut.command.add("doorsetdisabled", {
	adminOnly = true,
	syntax = "<bool disabled>",
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor()) then
			local disabled = util.tobool(arguments[1] or true)

			-- Set it so it is ownable.
			entity:setNetVar("disabled", disabled)

			PLUGIN:callOnDoorChildren(entity, function(child)
				child:setNetVar("disabled", disabled)
			end)

			-- Tell the player they have made the door (un)disabled.
			client:notifyLocalized("dSet"..(disabled and "" or "Not").."Disabled")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end
	end
})

nut.command.add("doorsettitle", {
	syntax = "<string title>",
	onRun = function(client, arguments)
		-- Get the door infront of the player.
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		-- Validate the door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			-- Get the supplied name.
			local name = table.concat(arguments, " ")

			-- Make sure the name contains actual characters.
			if (!name:find("%S")) then
				return client:notifyLocalized("invalidArg", 1)
			end

			--[[
				NOTE: Here, we are setting two different networked names.
				The title is a temporary name, while the other name is the
				default name for the door. The reason for this is so when the
				server closes while someone owns the door, it doesn't save THEIR
				title, which could lead to unwanted things.
			--]]

			-- Check if they are allowed to change the door's name.
			if (entity:checkDoorAccess(client, DOOR_TENANT)) then
				entity:setNetVar("title", name)
			elseif (client:IsAdmin()) then
				entity:setNetVar("name", name)

				PLUGIN:callOnDoorChildren(entity, function(child)
					child:setNetVar("name", name)
				end)
			else
				-- Otherwise notify the player he/she can't.
				client:notifyLocalized("notOwner")
			end
		else
			-- Notification of the door not being valid.
			client:notifyLocalized("dNotValid")
		end
	end
})

nut.command.add("doorsetparent", {
	adminOnly = true,
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			client.nutDoorParent = entity
			client:notifyLocalized("dSetParentDoor")
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end		
	end
})

nut.command.add("doorsetchild", {
	adminOnly = true,
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			if (client.nutDoorParent == entity) then
				return client:notifyLocalized("dCanNotSetAsChild")
			end

			-- Check if the player has set a door as a parent.
			if (IsValid(client.nutDoorParent)) then
				-- Add the door to the parent's list of children.
				client.nutDoorParent.nutChildren = client.nutDoorParent.nutChildren or {}
				client.nutDoorParent.nutChildren[entity:MapCreationID()] = true

				-- Set the door's parent to the parent.
				entity.nutParent = client.nutDoorParent

				client:notifyLocalized("dAddChildDoor")

				-- Save the door information.
				PLUGIN:SaveDoorData()
				PLUGIN:copyParentDoor(entity)
			else
				-- Tell the player they do not have a door parent.
				client:notifyLocalized("dNoParentDoor")
			end
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end		
	end
})

nut.command.add("doorremovechild", {
	adminOnly = true,
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
			if (client.nutDoorParent == entity) then
				PLUGIN:callOnDoorChildren(entity, function(child)
					child.nutParent = nil
				end)

				entity.nutChildren = nil

				return client:notifyLocalized("dRemoveChildren")
			end

			-- Check if the player has set a door as a parent.
			if (IsValid(entity.nutParent) and entity.nutParent.nutChildren) then
				-- Remove the door from the list of children.
				entity.nutParent.nutChildren[entity:MapCreationID()] = nil
				-- Remove the variable for the parent.
				entity.nutParent = nil

				client:notifyLocalized("dRemoveChildDoor")

				-- Save the door information.
				PLUGIN:SaveDoorData()
			end
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end		
	end
})

nut.command.add("doorsethidden", {
	adminOnly = true,
	syntax = "<bool hidden>",
	onRun = function(client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:isDoor()) then
			local hidden = util.tobool(arguments[1] or true)

			entity:setNetVar("hidden", hidden)
			
			PLUGIN:callOnDoorChildren(entity, function(child)
				child:setNetVar("hidden", hidden)
			end)

			-- Tell the player they have made the door (un)hidden.
			client:notifyLocalized("dSet"..(hidden and "" or "Not").."Hidden")

			-- Save the door information.
			PLUGIN:SaveDoorData()
		else
			-- Tell the player the door isn't valid.
			client:notifyLocalized("dNotValid")
		end
	end
})