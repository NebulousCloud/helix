ACCESS_LABELS = {}
ACCESS_LABELS[DOOR_OWNER] = "owner"
ACCESS_LABELS[DOOR_TENANT] = "tenant"
ACCESS_LABELS[DOOR_GUEST] = "guest"
ACCESS_LABELS[DOOR_NONE] = "none"

function PLUGIN:ShouldDrawEntityInfo(entity)
	if (entity.isDoor(entity) and !entity.getNetVar(entity, "disabled")) then
		return true
	end
end

local toScreen = FindMetaTable("Vector").ToScreen
local colorAlpha = ColorAlpha
local drawText = nut.util.drawText
local configGet = nut.config.get
local teamGetColor = team.GetColor

function PLUGIN:DrawEntityInfo(entity, alpha)
	if (entity.isDoor(entity) and !entity:getNetVar("hidden")) then
		local position = toScreen(entity.LocalToWorld(entity, entity.OBBCenter(entity)))
		local x, y = position.x, position.y
		local owner = entity.getNetVar(entity, "owner")
		local name = entity.getNetVar(entity, "title", entity.getNetVar(entity, "name", IsValid(owner) and L"dTitleOwned" or L"dTitle"))
		local faction = entity.getNetVar(entity, "faction")
		local color

		if (faction) then
			color = teamGetColor(faction)
		else
			color = configGet("color")
		end

		drawText(name, x, y, colorAlpha(color, alpha), 1, 1)

		if (IsValid(owner)) then
			drawText(L("dOwnedBy", owner.Name(owner)), x, y + 16, colorAlpha(color_white, alpha), 1, 1)
		elseif (faction) then
			local info = nut.faction.indices[faction]

			if (info) then
				drawText(L("dOwnedBy", L2(info.name) or info.name), x, y + 16, colorAlpha(color_white, alpha), 1, 1)
			end
		else
			drawText(entity.getNetVar(entity, "noSell") and L"dIsNotOwnable" or L"dIsOwnable", x, y + 16, colorAlpha(color_white, alpha), 1, 1)
		end
	end
end

netstream.Hook("doorMenu", function(entity, access, door2)
	if (IsValid(nut.gui.door)) then
		return nut.gui.door:Remove()
	end

	if (IsValid(entity)) then
		nut.gui.door = vgui.Create("nutDoorMenu")
		nut.gui.door:setDoor(entity, access, door2)
	end
end)

netstream.Hook("doorPerm", function(door, client, access)
	local panel = door.nutPanel

	if (IsValid(panel) and IsValid(client)) then
		panel.access[client] = access

		for k, v in ipairs(panel.access:GetLines()) do
			if (v.player == client) then
				v:SetColumnText(2, L(ACCESS_LABELS[access or 0]))

				return
			end
		end
	end
end)