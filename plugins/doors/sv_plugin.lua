-- Variables for door data.
local variables = {
	-- Whether or not the door will be disabled.
	"disabled",
	-- The name of the door.
	"name",
	-- Price of the door.
	"price",
	-- If the door is unownable.
	"noSell",
	-- The faction that owns a door.
	"faction",
	-- Whether or not the door will be hidden.
	"hidden"
}

function PLUGIN:callOnDoorChildren(entity, callback)
	local parent

	if (entity.nutChildren) then
		parent = entity
	elseif (entity.nutParent) then
		parent = entity.nutParent
	end

	if (IsValid(parent)) then
		callback(parent)
		
		for k, v in pairs(parent.nutChildren) do
			local child = ents.GetMapCreatedEntity(k)

			if (IsValid(child)) then
				callback(child)
			end
		end
	end
end

function PLUGIN:copyParentDoor(child)
	local parent = child.nutParent

	if (IsValid(parent)) then
		for k, v in ipairs(variables) do
			local value = parent:getNetVar(v)

			if (child:getNetVar(v) != value) then
				child:setNetVar(v, value)
			end
		end
	end
end

-- Called after the entities have loaded.
function PLUGIN:LoadData()
	-- Restore the saved door information.
	local data = self:getData()

	if (!data) then
		return
	end

	-- Loop through all of the saved doors.
	for k, v in pairs(data) do
		-- Get the door entity from the saved ID.
		local entity = ents.GetMapCreatedEntity(k)

		-- Check it is a valid door in-case something went wrong.
		if (IsValid(entity) and entity:isDoor()) then
			-- Loop through all of our door variables.
			for k2, v2 in pairs(v) do
				if (k2 == "children") then
					entity.nutChildren = v2

					for index, _ in pairs(v2) do
						local door = ents.GetMapCreatedEntity(index)

						if (IsValid(door)) then
							door.nutParent = entity
						end
					end
				elseif (k2 == "faction") then
					for k3, v3 in pairs(nut.faction.teams) do
						if (k3 == v2) then
							entity.nutFactionID = k3
							entity:setNetVar("faction", v3.index)

							break
						end
					end
				else
					entity:setNetVar(k2, v2)
				end
			end
		end
	end
end

-- Called before the gamemode shuts down.
function PLUGIN:SaveDoorData()
	-- Create an empty table to save information in.
	local data = {}
		local doors = {}

		for k, v in ipairs(ents.GetAll()) do
			if (v:isDoor()) then
				doors[v:MapCreationID()] = v
			end
		end

		local doorData

		-- Loop through doors with information.
		for k, v in pairs(doors) do
			-- Another empty table for actual information regarding the door.
			doorData = {}

			-- Save all of the needed variables to the doorData table.
			for k2, v2 in ipairs(variables) do
				local value = v:getNetVar(v2)

				if (value) then
					doorData[v2] = v:getNetVar(v2)
				end
			end

			if (v.nutChildren) then
				doorData.children = v.nutChildren
			end

			if (v.nutFactionID) then
				doorData.faction = v.nutFactionID
			end

			-- Add the door to the door information.
			if (table.Count(doorData) > 0) then
				data[k] = doorData
			end
		end
	-- Save all of the door information.
	self:setData(data)	
end

function PLUGIN:CanPlayerUseDoor(client, entity)
	if (entity:getNetVar("disabled")) then
		return false
	end
end

-- Whether or not a player a player has any abilities over the door, such as locking.
function PLUGIN:CanPlayerAccessDoor(client, door, access)
	local faction = door:getNetVar("faction")

	-- If the door has a faction set which the client is a member of, allow access.
	if (faction and client:Team() == faction) then
		return true
	end
end

function PLUGIN:PostPlayerLoadout(client)
	client:Give("nut_keys")
end

function PLUGIN:ShowTeam(client)
	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector()*96
		data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("faction")) then
		if (entity:checkDoorAccess(client, DOOR_TENANT)) then
			local door = entity

			if (IsValid(door.nutParent)) then
				door = door.nutParent
			end

			netstream.Start(client, "doorMenu", door, door.nutAccess, entity)
		elseif (!IsValid(entity:getNetVar("owner"))) then
			nut.command.run(client, "doorbuy")
		else
			client:notifyLocalized("notAllowed")
		end

		return true
	end
end

function PLUGIN:PlayerDisconnected(client)
	for k, v in ipairs(ents.GetAll()) do
		if (v == client) then
			return
		end
		
		if (v.isDoor and v:isDoor() and v:getNetVar("owner") == client) then
			v:removeDoorAccessData()
		end
	end
end

netstream.Hook("doorPerm", function(client, door, target, access)
	if (IsValid(target) and target:getChar() and door.nutAccess and door:getNetVar("owner") == client and target != client) then
		access = math.Clamp(access or 0, DOOR_NONE, DOOR_TENANT)

		if (access == door.nutAccess[target]) then
			return
		end

		door.nutAccess[target] = access

		local recipient = {}

		for k, v in pairs(door.nutAccess) do
			if (v > DOOR_GUEST) then
				recipient[#recipient + 1] = k
			end
		end

		if (#recipient > 0) then
			netstream.Start(recipient, "doorPerm", door, target, access)
		end
	end
end)