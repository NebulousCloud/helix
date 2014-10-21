function PLUGIN:ShouldDrawEntityInfo(entity)
	if (entity:isDoor() and !entity:getNetVar("disabled")) then
		return true
	end
end

function PLUGIN:DrawEntityInfo(entity, alpha)
	if (entity:isDoor()) then
		local position = entity:LocalToWorld(entity:OBBCenter()):ToScreen()
		local x, y = position.x, position.y
		local owner = entity:getNetVar("owner")
		local name = entity:getNetVar("title", entity:getNetVar("name", IsValid(owner) and L"dTitleOwned" or L"dTitle"))
		local faction = entity:getNetVar("faction")
		local color

		if (faction) then
			color = team.GetColor(faction)
		else
			color = nut.config.get("color")
		end

		nut.util.drawText(name, x, y, ColorAlpha(color, alpha), 1, 1)

		if (IsValid(owner)) then
			nut.util.drawText(L("dOwnedBy", owner:Name()), x, y + 16, ColorAlpha(color_white, alpha), 1, 1)
		elseif (faction) then
			local info = nut.faction.indices[faction]

			if (info) then
				nut.util.drawText(L("dOwnedBy", L2(info.name) or info.name), x, y + 16, ColorAlpha(color_white, alpha), 1, 1)
			end
		else
			nut.util.drawText(entity:getNetVar("noSell") and L"dIsNotOwnable" or L"dIsOwnable", x, y + 16, ColorAlpha(color_white, alpha), 1, 1)
		end
	end
end