local PLUGIN = PLUGIN
PLUGIN.name = "3D Panels"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds 3D panels that can display webpages."
PLUGIN.panels = PLUGIN.panels or {}

if (SERVER) then
	function PLUGIN:PlayerLoadedData(client)
		for k, v in pairs(self.panels) do
			netstream.Start(client, "nut_PanelData", {v.pos, v.angle, v.url, v.w, v.h, v.scale})
		end
	end

	function PLUGIN:AddPanel(client, url, w, h, scale)
		local trace = client:GetEyeTraceNoCursor()
		local data = {
			pos = trace.HitPos + trace.HitNormal,
			angle = trace.HitNormal:Angle(),
			url = url,
			w = w,
			h = h,
			scale = scale or 0.25
		}
		data.angle:RotateAroundAxis(data.angle:Up(), 90)
		data.angle:RotateAroundAxis(data.angle:Forward(), 90)

		self.panels[#self.panels + 1] = data
		self:SaveData()

		netstream.Start(nil, "nut_PanelData", {data.pos, data.angle, data.url, data.w, data.h, data.scale})
	end

	function PLUGIN:SaveData()
		self:WriteTable(self.panels)
	end

	function PLUGIN:LoadData()
		self.panels = self:ReadTable()
	end

	function PLUGIN:Remove(position, radius)
		local i = 0

		for k, v in pairs(self.panels) do
			if (v.pos:Distance(position) <= radius) then
				netstream.Start(nil, "nut_PanelRemove", k)

				self.panels[k] = nil
				i = i + 1
			end
		end

		return i
	end

	nut.command.Register({
		adminOnly = true,
		syntax = "<string URL> [number width] [number height] [number scale]",
		onRun = function(client, arguments)
			if (!arguments[1] or #arguments[1] < 1) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			PLUGIN:AddPanel(client, arguments[1], tonumber(arguments[2]) or 128, tonumber(arguments[3]) or 128, tonumber(arguments[4]))
			nut.util.Notify("You have added a 3D panel at where you are aiming.", client)
		end
	}, "paneladd")

	nut.command.Register({
		adminOnly = true,
		syntax = "[number radius]",
		onRun = function(client, arguments)
			local radius = tonumber(arguments[1]) or 256
			local count = PLUGIN:Remove(client:GetShootPos(), radius)

			nut.util.Notify("You have removed "..count.." 3D panel(s).", client)
		end
	}, "panelremove")
else
	netstream.Hook("nut_PanelRemove", function(index)
		PLUGIN.panels[index] = nil
	end)

	netstream.Hook("nut_PanelData", function(data)
		local position = data[1]
		local angle = data[2]
		local url = data[3]
		local w = data[4]
		local h = data[5]
		local scale = data[6]

		local panel = vgui.Create("DHTML")
		panel:SetSize(w, h)
		panel:SetMouseInputEnabled(false)
		panel:OpenURL(url)
		panel:SetPaintedManually(true)

		PLUGIN.panels[#PLUGIN.panels + 1] = {pos = position, angle = angle, panel = panel, scale = scale}
	end)

	function PLUGIN:PostDrawTranslucentRenderables()
		local position = LocalPlayer():GetPos()

		for i = 1, #self.panels do
			local data = self.panels[i]

			if (data and IsValid(data.panel)) then
				cam.Start3D2D(data.pos, data.angle, data.scale or 0.25)
					data.panel:SetPaintedManually(false)
						data.panel:PaintManual()
					data.panel:SetPaintedManually(true)
				cam.End3D2D()
			end
		end
	end
end