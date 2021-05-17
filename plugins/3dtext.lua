
local PLUGIN = PLUGIN

PLUGIN.name = "3D Text"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds text that can be placed on the map."

-- List of available text panels
PLUGIN.list = PLUGIN.list or {}

if (SERVER) then
	util.AddNetworkString("ixTextList")
	util.AddNetworkString("ixTextAdd")
	util.AddNetworkString("ixTextRemove")

	ix.log.AddType("undo3dText", function(client)
		return string.format("%s has removed their last 3D text.", client:GetName())
	end)

	-- Called when the player is sending client info.
	function PLUGIN:PlayerInitialSpawn(client)
		timer.Simple(1, function()
			if (IsValid(client)) then
				local json = util.TableToJSON(self.list)
				local compressed = util.Compress(json)
				local length = compressed:len()

				net.Start("ixTextList")
					net.WriteUInt(length, 32)
					net.WriteData(compressed, length)
				net.Send(client)
			end
		end)
	end

	-- Adds a text to the list, sends it to the players, and saves data.
	function PLUGIN:AddText(position, angles, text, scale, color)
		local index = #self.list + 1
		scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)
		color = color or "FFFFFF"

		self.list[index] = {position, angles, text, scale, color}

		net.Start("ixTextAdd")
			net.WriteUInt(index, 32)
			net.WriteVector(position)
			net.WriteAngle(angles)
			net.WriteString(text)
			net.WriteFloat(scale)
			net.WriteString(color)
		net.Broadcast()

		self:SaveText()
		return index
	end

	-- Removes a text that are within the radius of a position.
	function PLUGIN:RemoveText(position, radius)
		radius = radius or 100

		local textDeleted = {}

		for k, v in pairs(self.list) do
			if (k == 0) then
				continue
			end

			if (v[1]:Distance(position) <= radius) then
				textDeleted[#textDeleted + 1] = k
			end
		end

		if (#textDeleted > 0) then
			-- Invert index table to delete from highest -> lowest
			textDeleted = table.Reverse(textDeleted)

			for _, v in ipairs(textDeleted) do
				table.remove(self.list, v)

				net.Start("ixTextRemove")
					net.WriteUInt(v, 32)
				net.Broadcast()
			end

			self:SaveText()
		end

		return #textDeleted
	end

	function PLUGIN:RemoveTextByID(id)
		local info = self.list[id]

		if (!info) then
			return false
		end

		net.Start("ixTextRemove")
			net.WriteUInt(id, 32)
		net.Broadcast()

		table.remove(self.list, id)
		return true
	end

	-- Called after entities have been loaded on the map.
	function PLUGIN:LoadData()
		self.list = self:GetData() or {}

		-- Formats table to sequential to support legacy panels.
		self.list = table.ClearKeys(self.list)
	end

	-- Called when the plugin needs to save information.
	function PLUGIN:SaveText()
		self:SetData(self.list)
	end
else
	-- Pre-define the zero index in client before the net receives
	PLUGIN.list[0] = PLUGIN.list[0] or 0

	language.Add("Undone_ix3dText", "Removed 3D Text")

	local function HexToRGB(str)
		local color

		if (str:sub(1, 1) == "#") then
			if (#str == 4) then
				color = tonumber(str[2] .. str[2] .. str[3] .. str[3] .. str[4] .. str[4], 16)
			else
				color = tonumber(str:sub(2), 16)
			end
		else
			color = tonumber(str, 16)
		end

		local alpha = bit.band(bit.rshift(color, 24), 0xFF)
		if (alpha == 0) then alpha = 255 end

		return Color(bit.band(bit.rshift(color, 16), 0xFF), bit.band(bit.rshift(color, 8), 0xFF), bit.band(color, 0xFF), alpha)
	end

	function PLUGIN:GenerateMarkup(text, rgbaColor)
		local object = ix.markup.Parse("<font=ix3D2DFont><colour=" .. rgbaColor.r .. "," .. rgbaColor.g .. "," .. rgbaColor.b .. "," .. rgbaColor.a .. ">" .. text:gsub("\\n", "\n"))

		object.onDrawText = function(surfaceText, font, x, y, color, alignX, alignY, alpha)
			-- shadow
			surface.SetTextPos(x + 1, y + 1)
			surface.SetTextColor(0, 0, 0, alpha)
			surface.SetFont(font)
			surface.DrawText(surfaceText)

			surface.SetTextPos(x, y)
			surface.SetTextColor(color.r or 255, color.g or 255, color.b or 255, alpha)
			surface.SetFont(font)
			surface.DrawText(surfaceText)
		end

		return object
	end

	-- Receives new text objects that need to be drawn.
	net.Receive("ixTextAdd", function()
		local index = net.ReadUInt(32)
		local position = net.ReadVector()
		local angles = net.ReadAngle()
		local text = net.ReadString()
		local scale = net.ReadFloat()
		local color = net.ReadString()

		color = HexToRGB(color or "FFFFFF")

		if (text != "") then
			PLUGIN.list[index] = {
				position,
				angles,
				PLUGIN:GenerateMarkup(text, color),
				scale,
				color
			}

			PLUGIN.list[0] = #PLUGIN.list
		end
	end)

	net.Receive("ixTextRemove", function()
		local index = net.ReadUInt(32)

		table.remove(PLUGIN.list, index)

		PLUGIN.list[0] = #PLUGIN.list
	end)

	-- Receives a full update on ALL texts.
	net.Receive("ixTextList", function()
		local length = net.ReadUInt(32)
		local data = net.ReadData(length)
		local uncompressed = util.Decompress(data)

		if (!uncompressed) then
			ErrorNoHalt("[Helix] Unable to decompress text data!\n")
			return
		end

		PLUGIN.list = util.JSONToTable(uncompressed)

		-- Will be saved, but refresh just to make sure.
		PLUGIN.list[0] = #PLUGIN.list

		for k, v in pairs(PLUGIN.list) do
			if (k == 0) then
				continue
			end

			local rgbaColor = HexToRGB(v[5] or "FFFFFF")
			local object = ix.markup.Parse("<font=ix3D2DFont><colour=" .. rgbaColor.r .. "," .. rgbaColor.g .. "," .. rgbaColor.b .. "," .. rgbaColor.a .. ">" .. v[3]:gsub("\\n", "\n"))

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

			v[3] = object
		end
	end)

	function PLUGIN:StartChat()
		self.preview = nil
	end

	function PLUGIN:FinishChat()
		self.preview = nil
	end

	function PLUGIN:HUDPaint()
		if (ix.chat.currentCommand != "textremove") then
			return
		end

		local radius = tonumber(ix.chat.currentArguments[1]) or 100

		surface.SetDrawColor(200, 30, 30)
		surface.SetTextColor(200, 30, 30)
		surface.SetFont("ixMenuButtonFont")

		local i = 0

		for k, v in pairs(self.list) do
			if (k == 0) then
				continue
			end

			if (v[1]:Distance(LocalPlayer():GetEyeTraceNoCursor().HitPos) <= radius) then
				local screen = v[1]:ToScreen()
				surface.DrawLine(
					ScrW() * 0.5,
					ScrH() * 0.5,
					math.Clamp(screen.x, 0, ScrW()),
					math.Clamp(screen.y, 0, ScrH())
				)

				i = i + 1
			end
		end

		if (i > 0) then
			local textWidth, textHeight = surface.GetTextSize(i)
			surface.SetTextPos(ScrW() * 0.5 - textWidth * 0.5, ScrH() * 0.5 + textHeight + 8)
			surface.DrawText(i)
		end
	end

	function PLUGIN:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
		if (bDrawingDepth or bDrawingSkybox) then
			return
		end

		-- preview for textadd command
		if (ix.chat.currentCommand == "textadd") then
			local arguments = ix.chat.currentArguments
			local text = tostring(arguments[1] or "")
			local scale = math.Clamp((tonumber(arguments[2]) or 1) * 0.1, 0.001, 5)
			local color = HexToRGB(arguments[3] or "FFFFFF")
			local trace = LocalPlayer():GetEyeTraceNoCursor()
			local position = trace.HitPos
			local angles = trace.HitNormal:Angle()
			local markup

			angles:RotateAroundAxis(angles:Up(), 90)
			angles:RotateAroundAxis(angles:Forward(), 90)

			-- markup will error with invalid fonts
			pcall(function()
				markup = PLUGIN:GenerateMarkup(text, color)
			end)

			if (markup) then
				cam.Start3D2D(position, angles, scale)
					markup:draw(0, 0, 1, 1, 255)
				cam.End3D2D()
			end
		end

		local position = LocalPlayer():GetPos()
		local texts = self.list

		for i = 1, texts[0] do
			local distance = texts[i][1]:DistToSqr(position)

			if (distance > 1048576) then
				continue
			end

			cam.Start3D2D(texts[i][1], texts[i][2], texts[i][4] or 0.1)
				local alpha = (1 - ((distance - 65536) / 768432)) * 255
				texts[i][3]:draw(0, 0, 1, 1, alpha)
			cam.End3D2D()
		end
	end
end

ix.command.Add("TextAdd", {
	description = "@cmdTextAdd",
	adminOnly = true,
	arguments = {
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.string, ix.type.optional)
	},
	OnRun = function(self, client, text, scale, color)
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		local angles = trace.HitNormal:Angle()
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 90)

		local index = PLUGIN:AddText(position + angles:Up() * 0.1, angles, text, scale, color)

		undo.Create("ix3dText")
			undo.SetPlayer(client)
			undo.AddFunction(function()
				if (PLUGIN:RemoveTextByID(index)) then
					ix.log.Add(client, "undo3dText")
				end
			end)
		undo.Finish()

		return "@textAdded"
	end
})

ix.command.Add("TextRemove", {
	description = "@cmdTextRemove",
	adminOnly = true,
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, radius)
		local trace = client:GetEyeTrace()
		local position = trace.HitPos + trace.HitNormal * 2
		local amount = PLUGIN:RemoveText(position, radius)

		return "@textRemoved", amount
	end
})
