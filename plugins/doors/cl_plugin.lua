
-- luacheck: globals ACCESS_LABELS
ACCESS_LABELS = {}
ACCESS_LABELS[DOOR_OWNER] = "owner"
ACCESS_LABELS[DOOR_TENANT] = "tenant"
ACCESS_LABELS[DOOR_GUEST] = "guest"
ACCESS_LABELS[DOOR_NONE] = "none"

function PLUGIN:ShouldDrawEntityInfo(entity)
	if (entity:IsDoor() and !entity:GetNetVar("disabled")) then
		return true
	end
end

local toScreen = FindMetaTable("Vector").ToScreen
local colorAlpha = ColorAlpha
local drawText = ix.util.DrawText
local configGet = ix.config.Get
local teamGetColor = team.GetColor

function PLUGIN:DrawEntityInfo(entity, alpha)
	if (entity:IsDoor() and !entity:GetNetVar("hidden") and hook.Run("CanDrawDoorInfo") != false) then
		local position = toScreen(entity:LocalToWorld(entity:OBBCenter()))
		local x, y = position.x, position.y
		local owner = entity:GetDTEntity(0)
		local name = entity:GetNetVar("title", entity:GetNetVar("name", IsValid(owner) and L"dTitleOwned" or L"dTitle"))
		local faction = entity:GetNetVar("faction")
		local class = entity:GetNetVar("class")
		local color = configGet("color")

		if (faction) then
			color = teamGetColor(faction)
		end

		local classData

		if (class) then
			classData = ix.class.list[class]

			if (classData and classData.color) then
				color = classData.color
			end
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
			drawText(entity:GetNetVar("noSell") and L"dIsNotOwnable" or L"dIsOwnable", x, y + 16, colorAlpha(color_white, alpha), 1, 1)
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

		for _, v in ipairs(panel.access:GetLines()) do
			if (v.player == client) then
				v:SetColumnText(2, L(ACCESS_LABELS[access or 0]))

				return
			end
		end
	end
end)
