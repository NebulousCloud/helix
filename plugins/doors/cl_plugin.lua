ACCESS_LABELS = {}
ACCESS_LABELS[DOOR_OWNER] = "owner"
ACCESS_LABELS[DOOR_TENANT] = "tenant"
ACCESS_LABELS[DOOR_GUEST] = "guest"
ACCESS_LABELS[DOOR_NONE] = "none"

function PLUGIN:ShouldDrawEntityInfo(entity)
	if (entity.IsDoor(entity) and !entity.GetNetVar(entity, "disabled")) then
		return true
	end
end

local toScreen = FindMetaTable("Vector").ToScreen
local colorAlpha = ColorAlpha
local drawText = ix.util.DrawText
local configGet = ix.config.Get
local teamGetColor = team.GetColor

function PLUGIN:DrawEntityInfo(entity, alpha)
	if (entity.IsDoor(entity) and !entity:GetNetVar("hidden") and hook.Run("CanDrawDoorInfo") != false) then
		local position = toScreen(entity.LocalToWorld(entity, entity.OBBCenter(entity)))
		local x, y = position.x, position.y
		local owner = entity.GetDTEntity(entity, 0)
		local name = entity.GetNetVar(entity, "title", entity.GetNetVar(entity, "name", IsValid(owner) and L"dTitleOwned" or L"dTitle"))
		local faction = entity.GetNetVar(entity, "faction")
		local class = entity.GetNetVar(entity, "class")
		local color

		if (faction) then
			color = teamGetColor(faction)
		else
			color = configGet("color")
		end

		local classData
		if (class) then
			classData = ix.class.list[class]

			if (classData and classData.color) then
				color = classData.color
			else
				color = configGet("color")
			end
		else
			color = configGet("color")
		end

		drawText(name, x, y, colorAlpha(color, alpha), 1, 1)

		if (IsValid(owner)) then
			drawText(L("dOwnedBy", owner.Name(owner)), x, y + 16, colorAlpha(color_white, alpha), 1, 1)
		elseif (faction) then
			local info = ix.faction.indices[faction]

			if (info) then
				drawText(L("dOwnedBy", L2(info.name) or info.name), x, y + 16, colorAlpha(color_white, alpha), 1, 1)
			end
		elseif (class) then
			if (classData) then
				drawText(L("dOwnedBy", L2(classData.name) or classData.name), x, y + 16, colorAlpha(color_white, alpha), 1, 1)
			end
		else
			drawText(entity.GetNetVar(entity, "noSell") and L"dIsNotOwnable" or L"dIsOwnable", x, y + 16, colorAlpha(color_white, alpha), 1, 1)
		end
	end
end

netstream.Hook("doorMenu", function(entity, access, door2)
	if (IsValid(ix.gui.door)) then
		return ix.gui.door:Remove()
	end

	if (IsValid(entity)) then
		ix.gui.door = vgui.Create("ixDoorMenu")
		ix.gui.door:SetDoor(entity, access, door2)
	end
end)

netstream.Hook("doorPerm", function(door, client, access)
	local panel = door.ixPanel

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
