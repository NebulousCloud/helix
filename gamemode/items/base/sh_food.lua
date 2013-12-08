BASE.name = "Food Base"
BASE.restore = 25
BASE.restoreDelay = 0.5
BASE.category = "Consumables"
BASE.functions = {}
BASE.functions.Consume = {
	run = function(itemTable, client, data)
		if (SERVER) then
			local uniqueID = "nut_Restore"..client:UniqueID()..tostring(itemTable)
			local character = client.character

			if (client:Health() >= 100) then
				nut.util.Notify("You do not need to consume this right now.", client)

				return false
			end

			timer.Create(uniqueID, itemTable.restoreDelay, itemTable.restore, function()
				if (!IsValid(client) or client.character != character or !client:Alive()) then
					return timer.Remove(uniqueID)
				end

				client:SetHealth(math.Clamp(client:Health() + 1, 0, 100))

				if (client:Health() <= 0) then
					client:Kill()
				end
			end)

			client:EmitSound("items/battery_pickup.wav")
			client:ScreenFadeOut(1, Color(255, 255, 255, 175))
		end
	end
}