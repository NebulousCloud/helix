local PLUGIN = PLUGIN

nut.command.add("vendoradd", {
	adminOnly = true,
	onRun = function(client, arguments)
		local position = client:GetEyeTrace().HitPos
		local angles = (client:GetPos() - position):Angle()
		angles.p = 0
		angles.r = 0

		local entity = ents.Create("nut_vendor")
		entity:SetPos(position)
		entity:SetAngles(angles)
		entity:Spawn()

		PLUGIN:saveVendors()

		return "@vendorMade"
	end
})

nut.command.add("vendorremove", {
	adminOnly = true,
	onRun = function(client, arguments)
		local entity = client:GetEyeTrace().Entity

		if (IsValid(entity) and entity:GetClass() == "nut_vendor") then
			entity:Remove()

			return "@vendorDeleted"
		else
			return "@vendorNotValid"
		end
	end
})