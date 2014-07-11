local PLUGIN = PLUGIN
PLUGIN.name = "Area Display"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Shows which location you are at."

if (SERVER) then
	PLUGIN.areas = PLUGIN.areas or {}

	timer.Create("nut_AreaManager", 1, 0, function()
		local areas = PLUGIN.areas

		if (#areas > 0) then
			for k = 1, #areas do
				local v = areas[k]
				local entities = ents.FindInBox(v.min, v.max)

				for k2, v2 in pairs(entities) do
					if (IsValid(v2) and v2:IsPlayer() and v2.character and v2:GetNetVar("area", "") != v.name) then
						v2:SetNetVar("area", v.name)

						hook.Run("PlayerEnterArea", v2, v, entities)
						netstream.Start(nil, "nut_PlayerEnterArea", v2)
					end
				end
			end
		end
	end)

	function PLUGIN:PlayerEnterArea(client, area)
		local text = area.name

		if (area.showTime) then
			text = text..", "..os.date("!%X", nut.util.GetTime()).."."
		end

		nut.scroll.Send(text, client)
	end

	function PLUGIN:LoadData()
		self.areas = nut.util.ReadTable("areas")
	end

	function PLUGIN:SaveData()
		nut.util.WriteTable("areas", self.areas)
	end
else
	netstream.Hook("nut_PlayerEnterArea", function(data)
		hook.Run("PlayerEnterArea", data)
	end)
end

nut.command.Register({
	adminOnly = true,
	syntax = "<string name> [bool showTime]",
	onRun = function(client, arguments)
		local name = arguments[1] or "Area"
		local showTime = util.tobool(arguments[2] or "true")

		if (!client:GetNutVar("areaMin")) then
			if (!name) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			client:SetNutVar("areaMin", client:GetPos())
			client:SetNutVar("areaName", name)
			client:SetNutVar("areaShowTime", showTime)

			nut.util.Notify("Run the command again at a different position to set a maximum point.", client)
		else
			local data = {}
			data.min = client:GetNutVar("areaMin")
			data.max = client:GetPos()
			data.name = client:GetNutVar("areaName")
			data.showTime = client:GetNutVar("areaShowTime")

			client:SetNutVar("areaMin", nil)
			client:SetNutVar("areaName", nil)
			client:SetNutVar("areaShowTime", nil)

			table.insert(PLUGIN.areas, data)

			nut.util.WriteTable("areas", PLUGIN.areas)
			nut.util.Notify("You've added a new area.", client)
		end
	end
}, "areaadd")

nut.command.Register({
	adminOnly = true,
	onRun = function(client, arguments)
		local count = 0

		for k, v in pairs(PLUGIN.areas) do
			if (table.HasValue(ents.FindInBox(v.min, v.max), client)) then
				table.remove(PLUGIN.areas, k)

				count = count + 1
			end
		end

		nut.util.WriteTable("areas", PLUGIN.areas)
		nut.util.Notify("You've removed "..count.." areas.", client)
	end
}, "arearemove")