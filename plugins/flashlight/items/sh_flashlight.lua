ITEM.name = "Flashlight"
ITEM.uniqueID = "flashlight"
ITEM.model = Model("models/maxofs2d/lamp_flashlight.mdl")
ITEM.desc = "A regular flashlight with batteries included."

if (SERVER) then
	ITEM:Hook("Drop", function(itemTable, client)
		if (client:FlashlightIsOn()) then
			client:Flashlight(false)
		end
	end)
end