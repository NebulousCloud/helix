PLUGIN.name = "3D Text"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds text that can be placed on the map."

-- List of available text dislays.
PLUGIN.list = PLUGIN.list or {}

local PLUGIN = PLUGIN

if (SERVER) then
	-- Called when the player is sending client info.
	function PLUGIN:PlayerInitialSpawn(client)
		-- Send the list of text displays.
		timer.Simple(1, function()
			if (IsValid(client)) then
				netstream.Start(client, "txtList", self.list)
			end
		end)
	end

	-- Adds a text to the list, sends it to the players, and saves data.
	function PLUGIN:addText(position, angles, text, scale)
		-- Find an ID for this text within the list of texts.
		local index = #self.list + 1
		-- Play with the numbers to get a 3D2D scale.
		scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)

		-- Add the text to the list of texts so it can be sent and saved.
		self.list[index] = {position, angles, text, scale}
		-- Send the text information to the players.
		netstream.Start(nil, "txt", index, position, angles, text, scale)

		-- Save the plugin data.
		self:SaveText()
	end

	-- Removes a text that are within the radius of a position.
	function PLUGIN:removeText(position, radius)
		-- Store how many texts are removed.
		local i = 0
		-- Default the radius to 100.
		radius = radius or 100

		-- Loop through all of the texts.
		for k, v in pairs(self.list) do
			-- Check if the distance from our specified position to the text is less than the radius.
			if (v[1]:Distance(position) <= radius) then
				-- Remove the text from the list of texts.
				self.list[k] = nil
				-- Tell the players to stop showing the text.
				netstream.Start(nil, "txt", k)

				-- Increase the number of deleted texts by one.
				i = i + 1
			end
		end

		-- Save the plugin data if we actually changed anything.
		if (i > 0) then
			self:SaveText()
		end

		-- Return the number of deleted texts.
		return i
	end

	-- Called after entities have been loaded on the map.
	function PLUGIN:LoadData()
		self.list = self:getData() or {}
	end

	-- Called when the plugin needs to save information.
	function PLUGIN:SaveText()
		self:setData(self.list)
	end
else
	-- Receives new text objects that need to be drawn.
	netstream.Hook("txt", function(index, position, angles, text, scale)
		-- Check if we are adding or deleting the text.
		if (position) then
			-- Generate a markup object to draw fancy stuff for the text.
			local object = nut.markup.parse("<font=nut3D2DFont>"..text:gsub("\\n", "\n"))
			-- We want to draw a shadow on the text object.
			object.onDrawText = function(text, font, x, y, color, alignX, alignY, alpha)
				draw.SimpleTextOutlined(text, font, x, y, ColorAlpha(color, alpha), alignX, alignY, 2, color_black)
			end

			-- Add the text to a list of drawn text objects.
			PLUGIN.list[index] = {position, angles, object, scale}
		else
			-- Delete the text object if we are deleting stuff.
			PLUGIN.list[index] = nil
		end
	end)

	-- Receives a full update on ALL texts.
	netstream.Hook("txtList", function(values)
		-- Set the list of texts to the ones provided by the server.
		PLUGIN.list = values

		-- Loop through the list of texts.
		for k, v in pairs(PLUGIN.list) do
			-- Generate markup object since it hasn't been done already.
			local object = nut.markup.parse("<font=nut3D2DFont>"..v[3]:gsub("\\n", "\n"))
			-- Same thing with adding a shadow.
			object.onDrawText = function(text, font, x, y, color, alignX, alignY, alpha)
				draw.TextShadow({
					pos = {x, y},
					color = ColorAlpha(color, alpha),
					text = text,
					xalign = 0,
					yalign = alignY,
					font = font
				}, 1, alpha)
			end

			-- Set the text to have a markup object to draw.
			v[3] = object
		end
	end)

	-- Called after all translucent objects are drawn.
	function PLUGIN:PostDrawTranslucentRenderables(drawingDepth, drawingSkyBox)
		if (!drawingDepth and !drawingSkyBox) then
			-- Store the position of the player to be more optimized.
			local position = LocalPlayer():GetPos()

			-- Loop through all of the text.
			for k, v in pairs(self.list) do
				-- Start a 3D2D camera at the text's position and angles.
				cam.Start3D2D(v[1], v[2], v[4] or 0.1)
					-- Calculate the distance from the player to the text.
					local distance = v[1]:Distance(position)

					-- Only draw the text if we are within 1024 units.
					if (distance <= 1024) then
						-- Get the alpha that fades out as one moves farther from the text.
						local alpha = (1 - ((distance - 256) / 768)) * 255

						-- Draw the markup object.
						v[3]:draw(0, 0, 1, 1, alpha)
					end
				cam.End3D2D()
			end
		end
	end
end

nut.command.add("textadd", {
	adminOnly = true,
	syntax = "<string text> [number scale]",
	onRun = function(client, arguments)
		-- Get the position and angles of the text.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		local angles = trace.HitNormal:Angle()
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 90)
		
		-- Add the text.
		PLUGIN:addText(position + angles:Up()*0.1, angles, arguments[1], tonumber(arguments[2]))

		-- Tell the player the text was added.
		return L("textAdded", client)
	end
})

nut.command.add("textremove", {
	adminOnly = true,
	syntax = "[number radius]",
	onRun = function(client, arguments)
		-- Get the origin to remove text.
		local trace = client:GetEyeTrace()
		local position = trace.HitPos + trace.HitNormal*2
		-- Remove the text(s) and get the amount removed.
		local amount = PLUGIN:removeText(position, tonumber(arguments[1]))

		-- Tell the player how many texts got removed.
		return L("textRemoved", client, amount)
	end
})