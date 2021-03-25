
local PLUGIN = PLUGIN

PLUGIN.name = "3D Panels"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds web panels that can be placed on the map."

-- List of available panel dislays.
PLUGIN.list = PLUGIN.list or {}

if (SERVER) then
	util.AddNetworkString("ixPanelList")
	util.AddNetworkString("ixPanelAdd")
	util.AddNetworkString("ixPanelRemove")

	-- Called when the player is sending client info.
	function PLUGIN:PlayerInitialSpawn(client)
		-- Send the list of panel displays.
		timer.Simple(1, function()
			if (IsValid(client)) then
				local json = util.TableToJSON(self.list)
				local compressed = util.Compress(json)
				local length = compressed:len()

				net.Start("ixPanelList")
					net.WriteUInt(length, 32)
					net.WriteData(compressed, length)
				net.Send(client)
			end
		end)
	end

	-- Adds a panel to the list, sends it to the players, and saves data.
	function PLUGIN:AddPanel(position, angles, url, scale, brightness)
		scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)
		brightness = math.Clamp(math.Round((brightness or 100) * 2.55), 1, 255)

		-- Find an ID for this panel within the list.
		local index = #self.list + 1

		-- Add the panel to the list so it can be sent and saved.
		self.list[index] = {position, angles, nil, nil, scale, url, nil, brightness}

		-- Send the panel information to the players.
		net.Start("ixPanelAdd")
			net.WriteUInt(index, 32)
			net.WriteVector(position)
			net.WriteAngle(angles)
			net.WriteFloat(scale)
			net.WriteString(url)
			net.WriteUInt(brightness, 8)
		net.Broadcast()

		-- Save the plugin data.
		self:SavePanels()
	end

	-- Removes a panel that are within the radius of a position.
	function PLUGIN:RemovePanel(position, radius)
		-- Default the radius to 100.
		radius = radius or 100

		local panelsDeleted = {}

		-- Loop through all of the panels.
		for k, v in pairs(self.list) do
			if (k == 0) then
				continue
			end

			-- Check if the distance from our specified position to the panel is less than the radius.
			if (v[1]:Distance(position) <= radius) then
				panelsDeleted[#panelsDeleted + 1] = k
			end
		end

		-- Save the plugin data if we actually changed anything.
		if (#panelsDeleted > 0) then
			-- Invert index table to delete from highest -> lowest
			panelsDeleted = table.Reverse(panelsDeleted)

			for _, v in ipairs(panelsDeleted) do
				-- Remove the panel from the list of panels.
				table.remove(self.list, v)

				-- Tell the players to stop showing the panel.
				net.Start("ixPanelRemove")
					net.WriteUInt(v, 32)
				net.Broadcast()
			end

			self:SavePanels()
		end

		-- Return the number of deleted panels.
		return #panelsDeleted
	end

	-- Called after entities have been loaded on the map.
	function PLUGIN:LoadData()
		self.list = self:GetData() or {}

		-- Formats table to sequential to support legacy panels.
		self.list = table.ClearKeys(self.list)
	end

	-- Called when the plugin needs to save information.
	function PLUGIN:SavePanels()
		self:SetData(self.list)
	end
else
	-- Pre-define the zero index in client before the net receives
	PLUGIN.list[0] = PLUGIN.list[0] or 0

	-- Holds the current cached material and filename.
	local cachedPreview = {}

	local function CacheMaterial(index)
		if (index < 1) then
			return
		end

		local info = PLUGIN.list[index]
		local exploded = string.Explode("/", info[6])
		local filename = exploded[#exploded]
		local path = "helix/"..Schema.folder.."/"..PLUGIN.uniqueID.."/"

		if (file.Exists(path..filename, "DATA")) then
			local material = Material("../data/"..path..filename, "noclamp smooth")

			if (!material:IsError()) then
				info[7] = material
			end
		else
			file.CreateDir(path)

			http.Fetch(info[6], function(body)
				file.Write(path..filename, body)

				local material = Material("../data/"..path..filename, "noclamp smooth")

				if (!material:IsError()) then
					info[7] = material
				end
			end)
		end
	end

	-- Receives new panel objects that need to be drawn.
	net.Receive("ixPanelAdd", function()
		local index = net.ReadUInt(32)
		local position = net.ReadVector()
		local angles = net.ReadAngle()
		local scale = net.ReadFloat()
		local url = net.ReadString()
		local brightness = net.ReadUInt(8)

		if (url != "") then
			PLUGIN.list[index] = {position, angles, nil, nil, scale, url, nil, brightness}

			CacheMaterial(index)

			PLUGIN.list[0] = #PLUGIN.list
		end
	end)

	net.Receive("ixPanelRemove", function()
		local index = net.ReadUInt(32)

		table.remove(PLUGIN.list, index)

		PLUGIN.list[0] = #PLUGIN.list
	end)

	-- Receives a full update on ALL panels.
	net.Receive("ixPanelList", function()
		local length = net.ReadUInt(32)
		local data = net.ReadData(length)
		local uncompressed = util.Decompress(data)

		if (!uncompressed) then
			ErrorNoHalt("[Helix] Unable to decompress panel data!\n")
			return
		end

		-- Set the list of panels to the ones provided by the server.
		PLUGIN.list = util.JSONToTable(uncompressed)

		-- Will be saved, but refresh just to make sure.
		PLUGIN.list[0] = #PLUGIN.list

		local CacheQueue  = {}

		-- Loop through the list of panels.
		for k, _ in pairs(PLUGIN.list) do
			if (k == 0) then
				continue
			end

			CacheQueue[#CacheQueue + 1] = k
		end

		if (#CacheQueue == 0) then
			return
		end

		timer.Create("ixCache3DPanels", 1, #CacheQueue, function()
			if (#CacheQueue > 0) then
				CacheMaterial(CacheQueue[1])

				table.remove(CacheQueue, 1)
			else
				timer.Remove("ixCache3DPanels")
			end
		end)
	end)

	-- Called after all translucent objects are drawn.
	function PLUGIN:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
		if (bDrawingDepth or bDrawingSkybox) then
			return
		end

		-- Panel preview
		if (ix.chat.currentCommand == "paneladd") then
			self:PreviewPanel()
		end

		-- Store the position of the player to be more optimized.
		local ourPosition = LocalPlayer():GetPos()

		local panel = self.list

		for i = 1, panel[0] do
			local position = panel[i][1]
			local image = panel[i][7]

			-- Older panels do not have a brightness index
			local brightness = panel[i][8] or 255

			if (panel[i][7] and ourPosition:DistToSqr(position) <= 4194304) then
				cam.Start3D2D(position, panel[i][2], panel[i][5] or 0.1)
					render.PushFilterMin(TEXFILTER.ANISOTROPIC)
					render.PushFilterMag(TEXFILTER.ANISOTROPIC)
						surface.SetDrawColor(brightness, brightness, brightness)
						surface.SetMaterial(image)
						surface.DrawTexturedRect(0, 0, image:Width(), image:Height())
					render.PopFilterMag()
					render.PopFilterMin()
				cam.End3D2D()
			end
		end
	end

	function PLUGIN:PreviewPanel()
		local arguments = ix.chat.currentArguments

		local path = "helix/"..Schema.folder.."/"..PLUGIN.uniqueID.."/"
		local panelURL = tostring(arguments[1] or "")

		-- if there's no URL, then no preview.
		if (!arguments[1]) then
			return
		end

		-- Text has been updated since the last frame, re-cache material
		if (arguments[1] != cachedPreview[1]) then
			-- Gets the file name
			local exploded = string.Explode("/", panelURL)
			local filename = exploded[#exploded]

			if (file.Exists(path..filename, "DATA")) then
				cachedPreview[2] = Material("../data/"..path..filename, "noclamp smooth")
			else
				file.CreateDir(path)

				http.Fetch(panelURL, function(body)
					file.Write(path..filename, body)

					cachedPreview[2] = Material("../data/"..path..filename, "noclamp smooth")
				end)
			end

			-- After caching material, update the current text.
			cachedPreview[1] = arguments[1]
		end

		-- If the material is valid, preview the panel
		if (cachedPreview[2] and !cachedPreview[2]:IsError()) then
			local trace = LocalPlayer():GetEyeTrace()
			local angles = trace.HitNormal:Angle()
			angles:RotateAroundAxis(angles:Up(), 90)
			angles:RotateAroundAxis(angles:Forward(), 90)
			local position = (trace.HitPos + angles:Up() * 0.1)
			local ourPosition = LocalPlayer():GetPos()

			-- validate argument types
			local scale = math.Clamp((tonumber(arguments[2]) or 1) * 0.1, 0.001, 5)
			local brightness = math.Clamp(math.Round((tonumber(arguments[3]) or 100) * 2.55), 1, 255)

			if (ourPosition:DistToSqr(position) <= 4194304) then
				cam.Start3D2D(position, angles, scale or 0.1)
					render.PushFilterMin(TEXFILTER.ANISOTROPIC)
					render.PushFilterMag(TEXFILTER.ANISOTROPIC)
						surface.SetDrawColor(brightness, brightness, brightness)
						surface.SetMaterial(cachedPreview[2])
						surface.DrawTexturedRect(0, 0, cachedPreview[2]:Width(), cachedPreview[2]:Height())
					render.PopFilterMag()
					render.PopFilterMin()
				cam.End3D2D()
			end
		end
	end
end

ix.command.Add("PanelAdd", {
	description = "@cmdPanelAdd",
	privilege = "Manage Panels",
	adminOnly = true,
	arguments = {
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, url, scale, brightness)
		-- Get the position and angles of the panel.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		local angles = trace.HitNormal:Angle()
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 90)

		-- Add the panel.
		PLUGIN:AddPanel(position + angles:Up() * 0.1, angles, url, scale, brightness)
		return "@panelAdded"
	end
})

ix.command.Add("PanelRemove", {
	description = "@cmdPanelRemove",
	privilege = "Manage Panels",
	adminOnly = true,
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, radius)
		-- Get the origin to remove panel.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		-- Remove the panel(s) and get the amount removed.
		local amount = PLUGIN:RemovePanel(position, radius)

		return "@panelRemoved", amount
	end
})
