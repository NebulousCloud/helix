
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
	function PLUGIN:AddPanel(position, angles, url, w, h, scale)
		w = w or 1024
		h = h or 768
		scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)

		-- Find an ID for this panel within the list.
		local index = #self.list + 1

		-- Add the panel to the list so it can be sent and saved.
		self.list[index] = {position, angles, w, h, scale, url}

		-- Send the panel information to the players.
		net.Start("ixPanelAdd")
			net.WriteUInt(index, 32)
			net.WriteVector(position)
			net.WriteAngle(angles)
			net.WriteUInt(w, 16)
			net.WriteUInt(h, 16)
			net.WriteFloat(scale)
			net.WriteString(url)
		net.Broadcast()

		-- Save the plugin data.
		self:SavePanels()
	end

	-- Removes a panel that are within the radius of a position.
	function PLUGIN:RemovePanel(position, radius)
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
				net.Start("ixPanelRemove")
					net.WriteUInt(k, 32)
				net.Broadcast()

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
		self.list = self:GetData() or {}
	end

	-- Called when the plugin needs to save information.
	function PLUGIN:SavePanels()
		self:SetData(self.list)
	end
else
	local function CacheMaterial(index)
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
		local w, h = net.ReadUInt(16), net.ReadUInt(16)
		local scale = net.ReadFloat()
		local url = net.ReadString()

		if (url != "") then
			PLUGIN.list[index] = {position, angles, w, h, scale, url}

			CacheMaterial(index)
		end
	end)

	net.Receive("ixPanelRemove", function()
		local index = net.ReadUInt(32)

		table.remove(PLUGIN.list, index)
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

		local CacheQueue  = {}

		-- Loop through the list of panels.
		for k, _ in pairs(PLUGIN.list) do
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
	function PLUGIN:PostDrawTranslucentRenderables(drawingDepth, drawingSkyBox)
		if (!drawingDepth and !drawingSkyBox) then
			-- Store the position of the player to be more optimized.
			local ourPosition = LocalPlayer():GetPos()

			-- Loop through all of the panel.
			for _, v in pairs(self.list) do
				local position = v[1]

				if (v[7] and ourPosition:DistToSqr(position) <= 4194304) then
					cam.Start3D2D(position, v[2], v[5] or 0.1)
						render.PushFilterMin(TEXFILTER.ANISOTROPIC)
						render.PushFilterMag(TEXFILTER.ANISOTROPIC)
							surface.SetDrawColor(255, 255, 255)
							surface.SetMaterial(v[7])
							surface.DrawTexturedRect(0, 0, v[3], v[4])
						render.PopFilterMag()
						render.PopFilterMin()
					cam.End3D2D()
				end
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
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, url, width, height, scale)
		-- Get the position and angles of the panel.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		local angles = trace.HitNormal:Angle()
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 90)

		-- Add the panel.
		PLUGIN:AddPanel(position + angles:Up() * 0.1, angles, url, width, height, scale)
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
