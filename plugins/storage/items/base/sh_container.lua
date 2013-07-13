BASE.name = "Base Storage"
BASE.uniqueID = "base_storage"
BASE.category = "Storage"
BASE.functions = {}
BASE.functions.Use = {
	tip = "Drops the container on the ground..",
	icon = "icon16/weather_sun.png",
	run = function(itemTable, client, data, entity)
		if (SERVER) then
			local position

			if (IsValid(entity)) then
				position = entity:GetPos()
			else
				local data2 = {
					start = client:GetShootPos(),
					endpos = client:GetShootPos() + client:GetAimVector() * 72,
					filter = client
				}
				local trace = util.TraceLine(data2)
				position = trace.HitPos + Vector(0, 0, 16)
			end

			local entity2 = entity
			local entity = ents.Create("nut_container")

			if (IsValid(entity2)) then
				entity:SetAngles(entity2:GetAngles())
			end
			
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