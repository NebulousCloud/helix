
-- @todo this is going to be replaced later on
-- luacheck: ignore

local PLUGIN = PLUGIN

PLUGIN.name = "Area"
PLUGIN.author = "Black Tea"
PLUGIN.description = "Allows you to set area."
PLUGIN.areaTable = PLUGIN.areaTable or {}

ix.area = ix.area or {}
ALWAYS_RAISED["ix_areahelper"] = true

ix.config.Add("areaFontSize", 26, "The size of the font of Area Display.",
	function(oldValue, newValue)
		if (CLIENT) then
			hook.Run("LoadFonts", ix.config.Get("font"))
		end
	end,
	{data = {min = 1, max = 128},
	category = "areaPlugin"
})

ix.config.Add("areaDispSpeed", 20, "The Appearance Speed of Area Display.", nil, {
	data = {min = 1, max = 40},
	category = "areaPlugin"
})

local playerMeta = FindMetaTable("Player")

if (SERVER) then
	function ix.area.GetArea(areaID)
		return PLUGIN.areaTable[areaID]
	end

	function ix.area.GetAllArea()
		return PLUGIN.areaTable
	end

	-- This is for single check (ex: area items, checking area in commands)
	function playerMeta:IsInArea(areaID)
		local areaData = ix.area.GetArea(areaID)

		if (!areaData) then
			return false, "Area you specified is not valid."
		end

		local character = self:GetCharacter()

		if (!character) then
			return false, "Your character is not valid."
		end

		local clientPos = self:GetPos() + self:OBBCenter()
		return clientPos:WithinAABox(areaData.minVector, areaData.maxVector), areaData
	end

	-- This is for continous check (ex: checking gas area whatever.)
	function playerMeta:GetArea()
		return self.curArea
	end

	function PLUGIN:SaveAreas()
		self:SetData(self.areaTable)
	end

	function PLUGIN:LoadData()
		self.areaTable = self:GetData() or {}
	end

	function PLUGIN:PlayerLoadedChar(client, character, lastChar)
		client.curArea = nil
	end

	function PLUGIN:PlayerDeath(client)
		client.curArea = nil
	end

	function PLUGIN:PlayerSpawn(client)
		client.curArea = nil
	end

	-- gets two vector and gives min and max vector for Vector:WithinAA(min, max)
	local function sortVector(vector1, vector2)
		local minVector = Vector(0, 0, 0)
		local maxVector = Vector(0, 0, 0)

		for i = 1, 3 do
			if (vector1[i] >= vector2[i]) then
				maxVector[i] = vector1[i]
				minVector[i] = vector2[i]
			else
				maxVector[i] = vector2[i]
				minVector[i] = vector1[i]
			end
		end

		return minVector, maxVector
	end

	-- add area.
	function ix.area.AddArea(name, vector1, vector2, desc)
		if (!name or !vector1 or !vector2) then
			return false, "Required arguments are not provided."
		end

		local minVector, maxVector = sortVector(vector1, vector2)

		table.insert(PLUGIN.areaTable, {
			name = name,
			minVector = minVector,
			maxVector = maxVector,
			desc = desc or "",
		})

		PLUGIN:SaveAreas()
	end

	-- Timer instead of heavy think.
	timer.Create("ixAreaController", 0.33, 0, function()
		for _, v in ipairs(player.GetAll()) do
			local character = v:GetCharacter()

			if (character and v:Alive()) then
				local area = v:GetArea()
				for id, areaData in pairs(ix.area.GetAllArea()) do
					local clientPos = v:GetPos() + v:OBBCenter()

					if (clientPos:WithinAABox(areaData.minVector, areaData.maxVector)) then
						if (area != id) then
							v.curArea = id

							hook.Run("OnPlayerAreaChanged", v, id)
						end
					end
				end
			end
		end
	end)

	-- If area is changed, set display Area's Name to the client's screen.
	function PLUGIN:OnPlayerAreaChanged(client, areaID)
		local areaData = ix.area.GetArea(areaID)
		netstream.Start(client, "displayAreaText", tostring(areaData.name))
	end

	netstream.Hook("areaEdit", function(client, areaID, editData)
		-- Only Admin can edit the area.
		if (!client:IsAdmin()) then
			return false
		end

		-- If area is valid, merge editData to areaData.
		local areaData = table.Copy(ix.area.GetArea(areaID))

		if (areaData) then
			client:NotifyLocalized("areaModified", areaID)

			PLUGIN.areaTable[areaID] = table.Merge(areaData, editData)
			PLUGIN:SaveAreas()
		end
	end)

	netstream.Hook("areaTeleport", function(client, areaID, editData)
		-- Only Admin can do this.
		if (!client:IsAdmin()) then
			return false
		end

		-- If area is valid, merge editData to areaData.
		local areaData = table.Copy(ix.area.GetArea(areaID))

		if (areaData) then
			local min, max = areaData.maxVector, areaData.minVector
			client:SetPos(min + (max - min)/2)
		end
	end)

	netstream.Hook("areaAdd", function(client, name, vector1, vector2)
		-- Only Admin can edit the area.
		if (!client:IsAdmin() or !vector1 or !vector2 or !name) then
			return false
		end

		ix.area.AddArea(name, vector1, vector2)
	end)

	netstream.Hook("areaRemove", function(client, areaID, editData)
		-- Only Admin can edit the area.
		if (!client:IsAdmin()) then
			return false
		end

		-- If area is valid, merge editData to areaData.
		local areaData = table.Copy(ix.area.GetArea(areaID))
		if (areaData) then
			client:NotifyLocalized("areaRemoved", areaID)

			PLUGIN.areaTable[areaID] = nil
			PLUGIN:SaveAreas()
		end
	end)
else
	netstream.Hook("displayPosition", function(pos)
		local emitter = ParticleEmitter( pos )
		local bling = emitter:Add( "sprites/glow04_noz", pos )
		bling:SetVelocity( Vector( 0, 0, 1 ) )
		bling:SetDieTime(10)
		bling:SetStartAlpha(255)
		bling:SetEndAlpha(255)
		bling:SetStartSize(64)
		bling:SetEndSize(64)
		bling:SetColor(255,186,50)
		bling:SetAirResistance(300)
	end)

	-- area Manager.
	local function addAreaPanel(frame)
		local panel = frame:Add("DPanel")
		panel:SetTall(30)
		frame:AddItem(panel)
	end

	function ix.area.OpenAreaManager()
		local frame = vgui.Create("DFrame")
		frame:SetSize(400, 300)
		frame:Center()
		frame:MakePopup()
		frame:SetTitle("Area Manager")

		frame.menu = frame:Add("PanelList")
		frame.menu:Dock(FILL)
		frame.menu:DockMargin(5, 5, 5, 5)
		frame.menu:SetSpacing(2)
		frame.menu:SetPadding(2)
		frame.menu:EnableVerticalScrollbar()

		addAreaPanel(frame.menu)
	end

	function PLUGIN:LoadFonts(font)
		timer.Simple(0, function()
			surface.CreateFont("ixAreaDisplay", {
				font = font,
				extended = true,
				size = ScreenScale(ix.config.Get("areaFontSize")),
				weight = 500,
				shadow = true,
			})
		end)
	end

	-- draw matrix string.
	-- slow as fuck I guess?
	local function drawMatrixString(str, font, x, y, scale, angle, color)
		surface.SetFont(font)

		local matrix = Matrix()
		matrix:Translate(Vector(x, y, 1))
		matrix:Rotate(angle or Angle(0, 0, 0))
		matrix:Scale(scale)

		cam.PushModelMatrix(matrix)
			surface.SetTextPos(2, 2)
			surface.SetTextColor(color or color_white)
			surface.DrawText(str)
		cam.PopModelMatrix()
	end

	-- configureable values.
	local speed = 0
	local targetScale = 0
	local dispString = ""
	local tickSound = "UI/buttonrollover.wav"
	local dieTime = 5

	-- non configureable values.
	-- local scale = 0
	local scale = 0
	local flipTable = {}
	local powTime = RealTime()*speed
	local curChar = 0
	local mathsin = math.sin
	local mathcos = math.cos
	local dieTrigger = false
	local dieTimer = RealTime()
	local dieAlpha = 0
	local ft, w, h, dsx, dsy

	function displayScrText(str, time)
		speed = ix.config.Get("areaDispSpeed")
		targetScale = 1
		dispString = str
		dieTime = time or 5

		scale = targetScale * .5
		flipTable = {}
		powTime = RealTime()*speed
		curChar = 0
		dieTrigger = false
		dieTimer = RealTime()
		dieAlpha = 255
	end

	netstream.Hook("displayAreaText", function(str)
		displayScrText(str)
	end)

	function PLUGIN:HUDPaint()
		-- values
		if ((hook.Run("CanDisplayArea") == false) or (dieTrigger and dieTimer < RealTime() and dieAlpha <= 1)) then
			return
		end

		ft = FrameTime()
		w, h = ScrW(), ScrH()
		dsx, dsy = 0
		local strEnd = string.utf8len(dispString)
		local rTime = RealTime()

		surface.SetFont("ixAreaDisplay")
		local sx, sy = surface.GetTextSize(dispString)

		-- Number of characters to display.
		local maxDisplay = math.Round(rTime*speed - powTime)

		-- resize if it's too big.
		while (sx and sx*targetScale > w*.8) do
			targetScale = targetScale * .9
		end

		-- scale lerp
		scale = Lerp(ft*1, scale, targetScale)
		--scale = targetScale

		-- change event
		if (maxDisplay != curChar and curChar < strEnd) then
			curChar = maxDisplay
			if (string.utf8sub(dispString, curChar, curChar) != " ") then
				LocalPlayer():EmitSound(tickSound, 100, math.random(190, 200))
			end
		end

		-- draw recursive
		for i = 1, math.min(maxDisplay, strEnd) do
			-- character scale/color lerp
			flipTable[i] = flipTable[i] or {}
			flipTable[i][1] = flipTable[i][1] or .1
			--flipTable[i][1] = flipTable[i][1] or targetScale*3
			flipTable[i][2] = flipTable[i][2] or 0
			flipTable[i][1] = Lerp(ft*4, flipTable[i][1], scale)
			flipTable[i][2] = Lerp(ft*4, flipTable[i][2], 255)

			-- draw character.
			local char = string.utf8sub(dispString, i, i)
			local tx, ty = surface.GetTextSize(char)
			drawMatrixString(char,
				"ixAreaDisplay",
				math.Round(w/2 + dsx - (sx or 0)*scale/2),
				math.Round(h/3*1 - (sy or 0)*scale/2),
				Vector(Format("%.2f", flipTable[i][1]), Format("%.2f", scale), 1),
				nil,
				Color(255, 255, 255,
				(dieTrigger and dieTimer < RealTime()) and dieAlpha or flipTable[i][2])
			)

			-- next
			dsx = dsx + tx*scale
		end

		if (maxDisplay >= strEnd) then
			if (dieTrigger != true) then
				dieTrigger = true
				dieTimer = RealTime() + 2
			else
				if (dieTimer < RealTime()) then
					dieAlpha = Lerp(ft*4, dieAlpha, 0)
				end
			end
		end
	end
end

ix.command.Add("AreaAdd", {
	description = "@cmdAreaAdd",
	adminOnly = true,
	arguments = ix.type.text,
	OnRun = function(self, client, name)
		name = name:len() == 0 and "Area" or name
		local pos = client:GetEyeTraceNoCursor().HitPos

		if (!client:GetNetVar("areaMin")) then
			netstream.Start(client, "displayPosition", pos)

			client:SetNetVar("areaMin", pos, client)
			client:SetNetVar("areaName", name, client)

			return "@areaCommand"
		else
			local min = client:GetNetVar("areaMin")
			local max = pos
			local name = client:GetNetVar("areaName")

			netstream.Start(client, "displayPosition", pos)

			client:SetNetVar("areaMin", nil, client)
			client:SetNetVar("areaName", nil, client)

			ix.area.AddArea(name, min, max)

			return "@areaAdded", name
		end
	end
})

ix.command.Add("AreaRemove", {
	description = "@cmdAreaRemove",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		local areaID = client:GetArea()

		if (!areaID) then
			return
		end

		local areaData = ix.area.GetArea(areaID)

		if (areaData) then
			table.remove(PLUGIN.areaTable, areaID)
			PLUGIN:SaveAreas()

			return "@areaRemoved", areaData.name
		end
	end
})

ix.command.Add("AreaChange", {
	description = "@cmdAreaChange",
	adminOnly = true,
	arguments = ix.type.text,
	OnRun = function(self, client, name)
		name = name:len() == 0 and "Area" or name
		local areaID = client:GetArea()

		if (!areaID) then
			return
		end

		local areaData = ix.area.GetArea(areaID)

		if (areaData) then
			areaData.name = name
			PLUGIN:SaveAreas()

			return "@areaChanged", name, areaData.name
		end
	end
})

ix.command.Add("AreaManager", {
	description = "@cmdAreaManager",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		if (client:Alive()) then
			netstream.Start(client, "ixAreaManager", ix.area.GetAllArea())
		end
	end
})
