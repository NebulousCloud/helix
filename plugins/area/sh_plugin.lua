local PLUGIN = PLUGIN
PLUGIN.name = "Area"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Allows you to set area."
PLUGIN.areaTable = PLUGIN.areaTable or {}
nut.area = nut.area or {}
ALWAYS_RAISED["nut_areahelper"] = true

nut.config.add("areaFontSize", 26, "The size of the font of Area Display.", 
	function(oldValue, newValue)
		if (CLIENT) then
			hook.Run("LoadFonts", nut.config.get("font"))
		end
	end,
	{data = {min = 1, max = 128},
	category = "areaPlugin"
})
nut.config.add("areaDispSpeed", 20, "The Appearance Speed of Area Display.", nil, {
	data = {min = 1, max = 40},
	category = "areaPlugin"
})

local playerMeta = FindMetaTable("Player")
local PLUGIN = PLUGIN

if (SERVER) then
	function nut.area.getArea(areaID)
		return PLUGIN.areaTable[areaID]
	end

	function nut.area.getAllArea()
		return PLUGIN.areaTable
	end

	-- This is for single check (ex: area items, checking area in commands)
	function playerMeta:isInArea(areaID)
		local areaData = nut.area.getArea(areaID)

		if (!areaData) then
			return false, "Area you specified is not valid."
		end

		local char = v:getChar()

		if (!char) then
			return false, "Your character is not valid."
		end

		local clientPos = self:GetPos() + self:OBBCenter()
		return clientPos:WithinAABox(areaData.minVector, areaData.maxVector), areaData
	end

	-- This is for continous check (ex: checking gas area whatever.)
	function playerMeta:getArea()
		return self.curArea
	end

	function PLUGIN:saveAreas()
		self:setData(self.areaTable)
	end

	function PLUGIN:LoadData()
		self.areaTable = self:getData() or {}
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
	function nut.area.addArea(name, vector1, vector2, desc)
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

		PLUGIN:saveAreas()
	end

	-- Timer instead of heavy think.
	timer.Create("nutAreaController", 0.33, 0, function()
		for k, v in ipairs(player.GetAll()) do
			local char = v:getChar()

			if (char and v:Alive()) then
				local area = v:getArea()
				for id, areaData in pairs(nut.area.getAllArea()) do
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
		local areaData = nut.area.getArea(areaID)
		netstream.Start(client, "displayAreaText", tostring(areaData.name))
	end

	netstream.Hook("areaEdit", function(client, areaID, editData)
		-- Only Admin can edit the area.
		if (!client:IsAdmin()) then
			return false
		end

		-- If area is valid, merge editData to areaData.
		local areaData = table.Copy(nut.area.getArea(areaID))

		if (areaData) then
			client:notifyLocalized("areaModified", areaID)

			PLUGIN.areaTable[areaID] = table.Merge(areaData, editData)
			PLUGIN:saveAreas()
		end
	end)

	netstream.Hook("areaTeleport", function(client, areaID, editData)
		-- Only Admin can do this.
		if (!client:IsAdmin()) then
			return false
		end

		-- If area is valid, merge editData to areaData.
		local areaData = table.Copy(nut.area.getArea(areaID))

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

		nut.area.addArea(name, vector1, vector2)
	end)

	netstream.Hook("areaRemove", function(client, areaID, editData)
		-- Only Admin can edit the area.
		if (!client:IsAdmin()) then
			return false
		end

		-- If area is valid, merge editData to areaData.
		local areaData = table.Copy(nut.area.getArea(areaID))
		if (areaData) then
			client:notifyLocalized("areaRemoved", areaID)

			PLUGIN.areaTable[areaID] = nil
			PLUGIN:saveAreas()
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
	
	function nut.area.openAreaManager()
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

	netstream.Hook("areaManager", function()
		--nut.area.openAreaManager()
	end)

	function PLUGIN:LoadFonts(font)
		timer.Simple(0, function()
			surface.CreateFont("nutAreaDisplay", {
				font = font,
				size = ScreenScale(nut.config.get("areaFontSize")),
				weight = 500,
				shadow = true,
			})
		end)
	end

	-- draw matrix string.
	-- slow as fuck I guess?
	local function drawMatrixString(str, font, x, y, scale, angle, color)
		surface.SetFont(font)
		local tx, ty = surface.GetTextSize(str)

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
		speed = nut.config.get("areaDispSpeed")
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

		surface.SetFont("nutAreaDisplay")
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
				"nutAreaDisplay",
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

nut.command.add("areaadd", {
	adminOnly = true,
	syntax = "<string name>",
	onRun = function(client, arguments)
		local name = table.concat(arguments, " ") or "Area"

		local pos = client:GetEyeTraceNoCursor().HitPos

		if (!client:getNetVar("areaMin")) then
			if (!name) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end
			netstream.Start(client, "displayPosition", pos)

			client:setNetVar("areaMin", pos, client)
			client:setNetVar("areaName", name, client)

			return "@areaCommand"
		else
			local min = client:getNetVar("areaMin")
			local max = pos
			local name = client:getNetVar("areaName")

			netstream.Start(client, "displayPosition", pos)

			client:setNetVar("areaMin", nil, client)
			client:setNetVar("areaName", nil, client)

			nut.area.addArea(name, min, max)
			
			return "@areaAdded", name
		end
	end
})

nut.command.add("arearemove", {
	adminOnly = true,
	onRun = function(client, arguments)
		local areaID = client:getArea()

		if (!areaID) then
			return
		end

		local areaData = nut.area.getArea(areaID)

		if (areaData) then
			table.remove(PLUGIN.areaTable, areaID)
			PLUGIN:saveAreas()

			return "@areaRemoved", areaData.name
		end
	end
})

nut.command.add("areachange", {
	adminOnly = true,
	syntax = "<string name>",
	onRun = function(client, arguments)
		local name = table.concat(arguments, " ") or "Area"
		local areaID = client:getArea()

		if (!areaID) then
			return
		end

		local areaData = nut.area.getArea(areaID)

		if (areaData) then
			areaData.name = name
			PLUGIN:saveAreas()

			return "@areaChanged", name, areaData.name
		end
	end
})

nut.command.add("areamanager", {
	adminOnly = true,
	onRun = function(client, arguments)
		if (client:Alive()) then
			netstream.Start(client, "nutAreaManager", nut.area.getAllArea())
		end
	end
})
