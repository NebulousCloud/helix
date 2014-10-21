function GM:ForceDermaSkin()
	return "nutscript"
end

function GM:ScoreboardShow()
	if (IsValid(nut.gui.score)) then
		nut.gui.score:SetVisible(true)
	else
		vgui.Create("nutScoreboard")
	end

	gui.EnableScreenClicker(true)
end

function GM:ScoreboardHide()
	if (IsValid(nut.gui.score)) then
		nut.gui.score:SetVisible(false)
	end

	gui.EnableScreenClicker(false)
end

function GM:LoadFonts(font)
	surface.CreateFont("nut3D2DFont", {
		font = font,
		size = 2048,
		weight = 1000
	})

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

	surface.CreateFont("nutBigFont", {
		font = font,
		size = 36,
		weight = 1000
	})

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

	surface.CreateFont("nutChatFont", {
		font = font,
		size = 18,
		weight = 200
	})

	surface.CreateFont("nutChatFontItalics", {
		font = font,
		size = 18,
		weight = 200,
		italic = true
	})

	surface.CreateFont("nutSmallFont", {
		font = font,
		size = 16,
		weight = 500
	})
end

local LOWERED_ANGLES = Angle(30, -30, -25)

function GM:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)
	if (!IsValid(weapon)) then
		return
	end

	local client = LocalPlayer()
	local value = 0

	if (!client:isWepRaised()) then
		value = 100
	end

	local fraction = (client.nutRaisedFrac or 0) / 100
	local rotation = weapon.LowerAngles or LOWERED_ANGLES
	
	eyeAngles:RotateAroundAxis(eyeAngles:Up(), rotation.p * fraction)
	eyeAngles:RotateAroundAxis(eyeAngles:Forward(), rotation.y * fraction)
	eyeAngles:RotateAroundAxis(eyeAngles:Right(), rotation.r * fraction)

	client.nutRaisedFrac = Lerp(FrameTime() * 2, client.nutRaisedFrac or 0, value)

	viewModel:SetAngles(eyeAngles)

	if (weapon.GetViewModelPosition) then
		local position, angles = weapon:GetViewModelPosition(eyePos, eyeAngles)

		oldEyePos = position or oldEyePos
		eyeAngles = angles or eyeAngles
	end
	
	if (weapon.CalcViewModelView) then
		local position, angles = weapon:CalcViewModelView(viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)

		oldEyePos = position or oldEyePos
		eyeAngles = angles or eyeAngles
	end

	return oldEyePos, eyeAngles
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

	nut.menu.drawAll()
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

			nut.util.drawText(hook.Run("GetDisplayedName", entity) or character:getName(), x, y, ColorAlpha(team.GetColor(entity:Team()), alpha), 1, 1, nil, alpha * 0.65)
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
	elseif ((bind:find("use") or bind:find("attack")) and pressed) then
		local menu, callback = nut.menu.getActiveMenu()

		if (menu and nut.menu.onButtonPressed(menu, callback)) then
			return true
		elseif (bind:find("use") and pressed) then
			local data = {}
				data.start = client:GetShootPos()
				data.endpos = data.start + client:GetAimVector()*72
			local trace = util.TraceLine(data)
			local entity = trace.Entity

			if (IsValid(entity) and entity:GetClass() == "nut_item") then
				hook.Run("ItemShowEntityMenu", entity)
			end
		end
	end
end

-- Called when use has been pressed on an item.
function GM:ItemShowEntityMenu(entity)
	for k, v in ipairs(nut.menu.list) do
		if (v.entity == entity) then
			table.remove(nut.menu.list, k)
		end
	end

	local options = {}
	local itemTable = entity:getItemTable()

	local function Callback(index)
		if (IsValid(entity)) then
			netstream.Start("invAct", index, entity)
		end
	end

	itemTable.client = LocalPlayer()
	itemTable.entity = entity

	for k, v in SortedPairs(itemTable.functions) do
		if (v.onCanRun) then
			if (v.onCanRun(itemTable) == false) then
				continue
			end
		end

		options[L(v.name or k)] = function()
			local send = true

			if (v.onClick) then
				send = v.onClick(itemTable)
			end

			if (send != false) then
				Callback(k)
			end
		end
	end

	if (table.Count(options) > 0) then
		entity.nutMenuIndex = nut.menu.add(options, entity)
	end

	itemTable.client = nil
	itemTable.entity = nil
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