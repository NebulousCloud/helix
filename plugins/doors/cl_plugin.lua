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

		nut.util.drawText(name, x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1)

		if (IsValid(owner)) then
			nut.util.drawText(L("dOwnedBy", owner:Name()), x, y + 16, ColorAlpha(color_white, alpha), 1, 1)
		else
			nut.util.drawText(entity:getNetVar("noSell") and L"dIsNotOwnable" or L"dIsOwnable", x, y + 16, ColorAlpha(color_white, alpha), 1, 1)
		end
	end
end