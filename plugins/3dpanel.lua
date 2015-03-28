PLUGIN.name = "3D Panels"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds web panels that can be placed on the map."

-- List of available panel dislays.
PLUGIN.list = PLUGIN.list or {}

local PLUGIN = PLUGIN

if (SERVER) then
	-- Called when the player is sending client info.
	function PLUGIN:PlayerInitialSpawn(client)
		-- Send the list of panel displays.
		timer.Simple(1, function()
			if (IsValid(client)) then
				netstream.Start(client, "panelList", self.list)
			end
		end)
	end

	-- Adds a panel to the list, sends it to the players, and saves data.
	function PLUGIN:addPanel(position, angles, url, w, h, scale)
		w = w or 1024
		h = h or 768
		scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)

		-- Find an ID for this panel within the list.
		local index = #self.list + 1

		-- Add the panel to the list so it can be sent and saved.
		self.list[index] = {position, angles, w, h, scale, url}
		-- Send the panel information to the players.
		netstream.Start(nil, "panel", index, position, angles, w, h, scale, url)

		-- Save the plugin data.
		self:SavePanels()
	end

	-- Removes a panel that are within the radius of a position.
	function PLUGIN:removePanel(position, radius)
		-- Store how many panels are removed.
		local i = 0
		-- Default the radius to 100.
		radius = radius or 100

		-- Loop through all of the panels.
		for k, v in pairs(self.list) do
			-- Check if the distance from our specified position to the panel is less than the radius.
			if (v[1]:Distance(position) <= radius) then
				-- Remove the panel from the list of panels.
				self.list[k] = nil
				-- Tell the players to stop showing the panel.
				netstream.Start(nil, "panel", k)

				-- Increase the number of deleted panels by one.
				i = i + 1
			end
		end

		-- Save the plugin data if we actually changed anything.
		if (i > 0) then
			self:SavePanels()
		end

		-- Return the number of deleted panels.
		return i
	end

	-- Called after entities have been loaded on the map.
	function PLUGIN:LoadData()
		self.list = self:getData() or {}
	end

	-- Called when the plugin needs to save information.
	function PLUGIN:SavePanels()
		self:setData(self.list)
	end
else
	-- Receives new panel objects that need to be drawn.
	netstream.Hook("panel", function(index, position, angles, w, h, scale, url)
		-- Check if we are adding or deleting the panel.
		if (position) then
			-- Create a VGUI object to display the URL.
			local object = vgui.Create("DHTML")
			object:OpenURL(url)
			object:SetSize(w, h)
			object:SetKeyboardInputEnabled(false)
			object:SetMouseInputEnabled(false)
			object:SetPaintedManually(true)

			-- Add the panel to a list of drawn panel objects.
			PLUGIN.list[index] = {position, angles, w, h, scale, object}
		else
			-- Delete the panel object if we are deleting stuff.
			PLUGIN.list[index] = nil
		end
	end)

	-- Receives a full update on ALL panels.
	netstream.Hook("panelList", function(values)
		-- Set the list of panels to the ones provided by the server.
		PLUGIN.list = values

		-- Loop through the list of panels.
		for k, v in pairs(PLUGIN.list) do
			-- Create a VGUI object to display the URL.
			local object = vgui.Create("DHTML")
			object:OpenURL(v[6])
			object:SetSize(v[3], v[4])
			object:SetKeyboardInputEnabled(false)
			object:SetMouseInputEnabled(false)
			object:SetPaintedManually(true)

			-- Set the panel to have a markup object to draw.
			v[6] = object
		end
	end)

	-- Called after all translucent objects are drawn.
	function PLUGIN:PostDrawTranslucentRenderables(drawingDepth, drawingSkyBox)
		if (!drawingDepth and !drawingSkyBox) then
			-- Store the position of the player to be more optimized.
			local ourPosition = LocalPlayer():GetPos()

			-- Loop through all of the panel.
			for k, v in pairs(self.list) do
				local position = v[1]

				if (ourPosition:DistToSqr(position) <= 4194304) then
					local panel = v[6]

					-- Start a 3D2D camera at the panel's position and angles.
					cam.Start3D2D(position, v[2], v[5] or 0.1)
						panel:SetPaintedManually(false)
							panel:PaintManual()
						panel:SetPaintedManually(true)
					cam.End3D2D()
				end
			end
		end
	end
end

nut.command.add("paneladd", {
	adminOnly = true,
	syntax = "<string url> [number w] [number h] [number scale]",
	onRun = function(client, arguments)
		if (!arguments[1]) then
			return L("invalidArg", 1)
		end

		-- Get the position and angles of the panel.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		local angles = trace.HitNormal:Angle()
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 90)
		
		-- Add the panel.
		PLUGIN:addPanel(position + angles:Up()*0.1, angles, arguments[1], tonumber(arguments[2]), tonumber(arguments[3]), tonumber(arguments[4]))

		-- Tell the player the panel was added.
		return L("panelAdded", client)
	end
})

nut.command.add("panelremove", {
	adminOnly = true,
	syntax = "[number radius]",
	onRun = function(client, arguments)
		-- Get the origin to remove panel.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		-- Remove the panel(s) and get the amount removed.
		local amount = PLUGIN:removePanel(position, tonumber(arguments[1]))

		-- Tell the player how many panels got removed.
		return L("panelRemoved", client, amount)
	end
})