BASE.name = "Base Storage"
BASE.uniqueID = "base_storage"
BASE.category = "Storage"
BASE.functions = {}
BASE.functions.Use = {
	tip = "Drops the container on the ground..",
	icon = "icon16/weather_sun.png",
	menuOnly = true,
	run = function(itemTable, client, data)
		if (SERVER) then
			local data2 = {
				start = client:GetShootPos(),
				endpos = client:GetShootPos() + client:GetAimVector() * 72,
				filter = client
			}
			local trace = util.TraceLine(data2)
			local position = trace.HitPos + Vector(0, 0, 16)

			local entity = ents.Create("nut_container")
			entity:SetPos(position)
			entity:Spawn()
			entity:Activate()
			entity:SetNetVar("inv", {})
			entity:SetNetVar("name", itemTable.name)
			entity.itemID = itemTable.uniqueID

			if (itemTable.maxWeight) then
				entity:SetNetVar("max", itemTable.maxWeight)
			end

			entity:SetModel(itemTable.model)
			entity:PhysicsInit(SOLID_VPHYSICS)

			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:Wake()
			end
		end
	end
}