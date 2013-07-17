BASE.name = "Base Weapon"
BASE.uniqueID = "base_wep"
BASE.category = "Weapons"
BASE.class = "weapon_crowbar"
BASE.functions = {}
BASE.functions.Use = {
	run = function(itemTable, client, data)
		if (SERVER) then
			if (nut.config.noMultipleWepSlots and IsValid(client:GetNutVar(itemTable.type))) then
				nut.util.Notify("You already have a weapon in the "..itemTable.type.." slot.", client)

				return false
			end

			local weapon = client:Give(itemTable.class)

			if (IsValid(weapon)) then
				client:SetNutVar(itemTable.type, weapon)
			end
		else
			return false
		end
	end
}