--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

local PLUGIN = PLUGIN
PLUGIN.name = "Area"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Allows you to set area."
PLUGIN.areaTable = PLUGIN.areaTable or {}
nut.area = nut.area or {}
ALWAYS_RAISED["nut_areahelper"] = true

local playerMeta = FindMetaTable("Player")


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

	function PLUGIN:SaveDota()
		self:setData(self.areaTable)
	end

	function PLUGIN:LoadData()
		self.areaTable = self:getData() or {}
	end

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
	end

	function PLUGIN:Think()
		for k, v in ipairs(player.GetAll()) do
			local char = v:getChar()

			if (char) then
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
	end

	function PLUGIN:OnPlayerAreaChanged(client, areaID)
		local areaData = nut.area.getArea(areaID)
		netstream.Start(client, "displayAreaText", tostring(areaData.name))
	end
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
	function nut.area.openAreaManager()

	end

	netstream.Hook("areaManager", function()
		nut.area.openAreaManager()
	end)

	function PLUGIN:LoadFonts(font)
		surface.CreateFont("nutAreaDisplay", {
			font = font,
			size = ScreenScale(26),
			weight = 500,
			shadow = true,
		})
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

	-- fTime(): Powerful Fix for High Framerate Slowness.
	local function fTime() return math.Clamp(FrameTime(), 1/60, 1) end

	-- configureable values.
	local speed = 0
	local targetScale = 0
	local dispString = ""
	local tickSound = "UI/buttonrollover.wav"
	local dieTime = 5

	-- non configureable values.
	--local scale = 0
	local scale = 0
	local flipTable = {}
	local powTime = RealTime()*speed
	local curChar = 0
	local mathsin = math.sin
	local mathcos = math.cos
	local dieTrigger = false
	local dieTimer = RealTime()
	local dieAlpha = 0

	function displayScrText(str, time)
		speed = 20
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
		if (dieTrigger and dieTimer < RealTime() and dieAlpha <= 1) then
			return	
		end

		local w, h = ScrW(), ScrH()
		local dsx, dsy = 0
		local strEnd = string.len(dispString)
		local sx, sy = surface.GetTextSize(dispString)
		local rTime = RealTime()

		-- Number of characters to display.
		local maxDisplay = math.Round(rTime*speed - powTime)

		-- resize if it's too big.
		while (sx and sx*targetScale > w*.8) do
			targetScale = targetScale * .9
		end

		-- scale lerp
		scale = Lerp(fTime()*1, scale, targetScale)
		--scale = targetScale

		-- change event
		if (maxDisplay != curChar and curChar < strEnd) then
			curChar = maxDisplay
			if (dispString[curChar] != " ") then
				LocalPlayer():EmitSound(tickSound, 100, math.random(190, 200))
			end
		end

		-- draw recursive
		for i = 1, math.min(maxDisplay, strEnd) do
			-- character scale/color lerp
			flipTable[i] = flipTable[i] or {}
			flipTable[i][1] = flipTable[i][1] or 2
			--flipTable[i][1] = flipTable[i][1] or targetScale*3
			flipTable[i][2] = flipTable[i][2] or 0
			flipTable[i][1] = Lerp(fTime()*4, flipTable[i][1], scale)
			flipTable[i][2] = Lerp(fTime()*2, flipTable[i][2], 255)

			-- draw character.
			local tx, ty = surface.GetTextSize(dispString[i])
			drawMatrixString(dispString[i],
				"nutAreaDisplay",
				math.Round(w/2 + dsx - (sx or 0)*scale/2),
				math.Round(h/3*1 - (sy or 0)*scale/2),
				Vector(flipTable[i][1], Format("%.2f", scale), 1),
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
					dieAlpha = Lerp(fTime()*2, dieAlpha, 0)
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

		if (!client:getNetVar("areaMin")) then
			if (!name) then
				nut.util.Notify(nut.lang.Get("missing_arg", 1), client)

				return
			end

			local pos = client:GetEyeTraceNoCursor().HitPos

			netstream.Start(client, "displayPosition", pos)

			client:setNetVar("areaMin", pos, client)
			client:setNetVar("areaName", name, client)

			client:notify("Run the command again at a different position to set a maximum point.")
		else
			local data = {}
			local pos = client:GetEyeTraceNoCursor().HitPos
			local min = client:getNetVar("areaMin")
			local max = pos
			local name = client:getNetVar("areaName")

			netstream.Start(client, "displayPosition", pos)

			client:setNetVar("areaMin", nil, client)
			client:setNetVar("areaName", nil, client)

			nut.area.addArea(name, min, max)
			client:notify("You've added a new area.")
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
			client:notify(Format("You've removed (%s)", areaData.name))

			table.remove(PLUGIN.areaTable, areaID)
		end
	end
})