ITEM.name = "Cooking Stove"
ITEM.uniqueID = "stove"
ITEM.category = "Cooking"
ITEM.model = Model("models/props_c17/furnitureStove001a.mdl")
ITEM.desc = "A cooking stove that can be placed."
ITEM.functions = {}
ITEM.functions.Use = {
	tip = "Drops the radio on the ground.",
	icon = "icon16/weather_sun.png",
	run = function(itemTable, client, data, entity)
		if (SERVER) then
			local position

			if (IsValid(entity)) then
				position = entity:GetPos() + Vector(0, 0, 4)
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
			local entity = ents.Create("nut_stove")
			entity:SetPos(position)

			if (IsValid(entity2)) then
				entity:SetAngles(entity2:GetAngles())
			end
			
			entity:Spawn()
			entity:Activate()
		end
	end
}