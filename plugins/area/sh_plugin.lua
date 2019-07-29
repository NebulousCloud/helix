
local PLUGIN = PLUGIN

PLUGIN.name = "Areas"
PLUGIN.author = "`impulse"
PLUGIN.description = "Provides customizable area definitions."

ix.area = ix.area or {}
ix.area.types = ix.area.types or {}
ix.area.properties = ix.area.properties or {}
ix.area.stored = ix.area.stored or {}

ix.config.Add("areaTickTime", 1, "How many seconds between each time a character's current area is calculated.",
	function(oldValue, newValue)
		if (SERVER) then
			timer.Remove("ixAreaThink")
			timer.Create("ixAreaThink", newValue, 0, function()
				PLUGIN:AreaThink()
			end)
		end
	end,
	{
		data = {min = 0.1, max = 4},
		category = "areas"
	}
)

function ix.area.AddProperty(name, type, default, data)
	ix.area.properties[name] = {
		type = type,
		default = default
	}
end

function ix.area.AddType(type, name)
	name = name or type

	-- only store localized strings on the client
	ix.area.types[type] = CLIENT and name or true
end

function PLUGIN:SetupAreaProperties()
	ix.area.AddType("area")

	ix.area.AddProperty("color", ix.type.color, ix.config.Get("color"))
	ix.area.AddProperty("display", ix.type.bool, true)
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

-- return world center, local min, and local max from world start/end positions
function PLUGIN:GetLocalAreaPosition(startPosition, endPosition)
	local center = LerpVector(0.5, startPosition, endPosition)
	local min = WorldToLocal(startPosition, angle_zero, center, angle_zero)
	local max = WorldToLocal(endPosition, angle_zero, center, angle_zero)

	return center, min, max
end

do
	local COMMAND = {}
	COMMAND.description = "@cmdAreaEdit"
	COMMAND.adminOnly = true

	function COMMAND:OnRun(client)
		client:SetWepRaised(false)

		net.Start("ixAreaEditStart")
		net.Send(client)
	end

	ix.command.Add("AreaEdit", COMMAND)
end

do
	local PLAYER = FindMetaTable("Player")

	-- returns the current area the player is in, or the last valid one if the player is not in an area
	function PLAYER:GetArea()
		return self.ixArea
	end

	-- returns true if the player is in any area, this does not use the last valid area like GetArea does
	function PLAYER:IsInArea()
		return self.ixInArea
	end
end
