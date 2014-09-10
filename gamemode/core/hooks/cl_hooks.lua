function GM:ForceDermaSkin()
	return "nutscript"
end

function GM:LoadFonts(font)
	surface.CreateFont("nutTitleFont", {
		font = font,
		size = 72,
		weight = 1000
	})

	surface.CreateFont("nutSubTitleFont", {
		font = font,
		size = 36,
		weight = 500
	})

	surface.CreateFont("nutMenuButtonFont", {
		font = font,
		size = 36,
		weight = 1000
	})

	surface.CreateFont("nutMenuButtonLightFont", {
		font = font,
		size = 36,
		weight = 200
	})

	-- The more readable font.
	font = "Calibri"

	surface.CreateFont("nutMediumFont", {
		font = font,
		size = 26,
		weight = 1000
	})

	surface.CreateFont("nutGenericFont", {
		font = font,
		size = 20,
		weight = 1000
	})

	surface.CreateFont("nutSmallFont", {
		font = font,
		size = 16,
		weight = 500
	})
end

function GM:InitializedConfig()
	hook.Run("LoadFonts", nut.config.get("font"))
	
	if (!nut.config.loaded and !IsValid(nut.gui.loading)) then
		local loader = vgui.Create("EditablePanel")
		loader:ParentToHUD()
		loader:Dock(FILL)
		loader.Paint = function(this, w, h)
			surface.SetDrawColor(0, 0, 0)
			surface.DrawRect(0, 0, w, h)
		end

		local label = loader:Add("DLabel")
		label:Dock(FILL)
		label:SetText(L"loading")
		label:SetFont("nutTitleFont")
		label:SetContentAlignment(5)
		label:SetTextColor(color_white)

		timer.Simple(5, function()
			if (IsValid(nut.gui.loading)) then
				local fault = getNetVar("dbError")

				if (fault) then
					label:SetText(fault and L"dbError" or L"loading")

					local label = loader:Add("DLabel")
					label:DockMargin(0, 64, 0, 0)
					label:Dock(TOP)
					label:SetFont("nutSubTitleFont")
					label:SetText(fault)
					label:SetContentAlignment(5)
					label:SizeToContentsY()
					label:SetTextColor(Color(255, 50, 50))
				end
			end
		end)

		nut.gui.loading = loader
		nut.config.loaded = true
	end
end

function GM:InitPostEntity()
	nut.joinTime = CurTime()
end

local vignette = nut.util.getMaterial("nutscript/gui/vignette.png")
local vignetteAlphaGoal = 0
local vignetteAlphaDelta = 0

timer.Create("nutVignetteChecker", 1, 0, function()
	local client = LocalPlayer()

	if (IsValid(client)) then
		local data = {}
			data.start = client:GetPos()
			data.endpos = data.start + Vector(0, 0, 768)
		local trace = util.TraceLine(data)

		if (trace.Hit) then
			vignetteAlphaGoal = 80
		else
			vignetteAlphaGoal = 0
		end
	end
end)

local OFFSET_NORMAL = Vector(0, 0, 80)
local OFFSET_CROUCHING = Vector(0, 0, 48)

local paintedEntitiesCache = {}

function GM:HUDPaint()
	vignetteAlphaDelta = math.Approach(vignetteAlphaDelta, vignetteAlphaGoal, FrameTime() * 30)

	surface.SetDrawColor(0, 0, 0, 175 + vignetteAlphaDelta)
	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

	local localPlayer = LocalPlayer()

	if (localPlayer:getChar()) then
		local data = {}
			data.start = localPlayer:GetShootPos()
			data.endpos = data.start + localPlayer:GetAimVector()*160
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and (entity.onShouldDrawEntityInfo and entity:onShouldDrawEntityInfo() or hook.Run("ShouldDrawEntityInfo", entity) == true)) then
			paintedEntitiesCache[entity] = true
		end
	end

	local frameTime = FrameTime() * 120

	for entity, drawing in pairs(paintedEntitiesCache) do
		if (IsValid(entity)) then
			local goal = drawing and 255 or 0
			local alpha = math.Approach(entity.nutAlpha or 0, goal, frameTime)

			paintedEntitiesCache[entity] = false

			if (alpha > 0) then
				if (entity.onDrawEntityInfo) then
					entity:onDrawEntityInfo(alpha)
				else
					hook.Run("DrawEntityInfo", entity, alpha)
				end
			end

			entity.nutAlpha = alpha

			if (alpha == 0 and goal == 0) then
				paintedEntitiesCache[entity] = nil
			end
		else
			paintedEntitiesCache[entity] = nil
		end
	end

	self.BaseClass:PaintWorldTips()
	nut.bar.drawAll()
end

function GM:ShouldDrawEntityInfo(entity)
	if (entity:IsPlayer()) then
		if (entity == LocalPlayer() and !LocalPlayer():ShouldDrawLocalPlayer()) then
			return false
		end

		return true
	end

	return false
end

function GM:DrawEntityInfo(entity, alpha)
	if (entity:IsPlayer()) then
		local localPlayer = LocalPlayer()
		local position = (entity:GetPos() + (entity:Crouching() and OFFSET_CROUCHING or OFFSET_NORMAL)):ToScreen()
		local character = entity:getChar()

		if (character) then
			local x, y = position.x, position.y

			nut.util.drawText(character:getName(), x, y, ColorAlpha(team.GetColor(entity:Team()), alpha), 1, 1, nil, alpha * 0.65)
			nut.util.drawText(character:getDesc(), x, y + 16, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
		end
	end
end

function GM:PlayerBindPress(client, bind, pressed)
	bind = bind:lower()
	
	if (bind:find("gm_showhelp") and pressed) then
		if (IsValid(nut.gui.menu)) then
			nut.gui.menu:remove()
		else
			vgui.Create("nutMenu")
		end

		return true
	end
end

local hidden = {}
hidden["CHudHealth"] = true
hidden["CHudBattery"] = true

function GM:HUDShouldDraw(element)
	if (hidden[element]) then
		return false
	end

	return true
end