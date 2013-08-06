PLUGIN.name = "Storage"
PLUGIN.author = "Chessnut"
-- Black Tea added few lines.
PLUGIN.desc = "Adds storage items that can store items."

nut.util.Include("cl_storage.lua")

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.FindByClass("nut_container")) do
			if v.generated then continue end
			if (v.itemID) then
				local inventory = v:GetNetVar("inv")
				data[#data + 1] = {
					position = v:GetPos(),
					angles = v:GetAngles(),
					inv = inventory,
					world = (v.world or false),
					lock = (v.lock or nil),
					uniqueID = v.itemID,
					type = v.type
				}
			end
		end

		nut.util.WriteTable("storage", data)
	end

	function PLUGIN:LoadData()
		local storage = nut.util.ReadTable("storage")

		if (storage) then
			for k, v in pairs(storage) do
				local inventory = v.inv
				local position = v.position
				local angles = v.angles
				local itemTable = nut.item.Get(v.uniqueID)
				
				local amt = 0
				for _, __ in pairs( inventory ) do
					amt = amt + 1
				end
				
				if ( amt == 0 && !v.world && !v.lock ) then continue end
				if (itemTable) then
					local entity = ents.Create("nut_container")
					entity:SetPos(position)
					entity:SetAngles(angles)
					entity:Spawn()
					entity:Activate()
					entity:SetNetVar("inv", inventory)
					entity:SetNetVar("name", itemTable.name)
					entity.itemID = v.uniqueID
					entity.lock = (v.lock or nil)
					entity.world = (v.world or false)
					entity.type = v.type

					if (itemTable.maxWeight) then
						entity:SetNetVar("max", itemTable.maxWeight)
					end

					entity:SetModel(itemTable.model)
					entity:PhysicsInit(SOLID_VPHYSICS)
				end
			end
		end
	end
end


nut.command.Register({
	adminOnly = true,
	syntax = "[bool isWorldContainer]",
	onRun = function(client, arguments)

		local dat = {}
		dat.start = client:GetShootPos()
		dat.endpos = dat.start + client:GetAimVector() * 96
		dat.filter = client
		local trace = util.TraceLine(dat)
		local entity = trace.Entity
		
		if entity && entity:IsValid() then
			if entity:GetClass() == "nut_container" then
				if arguments[1] then
					if arguments[1] == "true" || arguments[1] == "false" then
						if arguments[1] == "true" then
							entity.world = true
						else
							entity.world = false
						end
					else
						nut.util.Notify("Must enter valid argument. ( true | false )", client)	
						return
					end
				else
					entity.world = !entity.world
				end
				nut.util.Notify("Container's status updated: isworldcontainer = " .. tostring( entity.world ) , client)			
			else
				nut.util.Notify("You have to face an container to use this command!", client)			
			end
		else
			nut.util.Notify("You have to face an entity to use this command!", client)
		end
		
	end
}, "setworldcontainer")


nut.command.Register({
	adminOnly = true,
	syntax = "[bool showTime]",
	onRun = function(client, arguments)

		local dat = {}
		dat.start = client:GetShootPos()
		dat.endpos = dat.start + client:GetAimVector() * 96
		dat.filter = client
		local trace = util.TraceLine(dat)
		local entity = trace.Entity
		
		if entity && entity:IsValid() then
			if entity:GetClass() == "nut_container" then
				if arguments[1] then
					entity.type = arguments[1]
					nut.util.Notify("Flag Set: ".. entity.type, client)		
				else
					nut.util.Notify("You have to enter valid type", client)		
				end
			else
				nut.util.Notify("You have to face an container to use this command!", client)			
			end
		else
			nut.util.Notify("You have to face an entity to use this command!", client)
		end
		
	end
}, "setcontainertype")


nut.command.Register({
	adminOnly = true,
	syntax = "",
	onRun = function(client, arguments)

		local dat = {}
		dat.start = client:GetShootPos()
		dat.endpos = dat.start + client:GetAimVector() * 96
		dat.filter = client
		local trace = util.TraceLine(dat)
		local entity = trace.Entity
		
		if entity && entity:IsValid() then
			if entity:GetClass() == "nut_container" then
				nut.util.Notify("Container's status: isworldcontainer = " .. tostring( entity.world ) , client)			
			else
				nut.util.Notify("You have to face an container to use this command!", client)			
			end
		else
			nut.util.Notify("You have to face an entity to use this command!", client)
		end
		
	end
}, "isworldcontainer")