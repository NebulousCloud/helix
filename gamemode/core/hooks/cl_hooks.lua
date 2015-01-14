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

local NUT_CVAR_LOWER2 = CreateClientConVar("nut_usealtlower", "0", true)

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

	surface.CreateFont("nutToolTipText", {
		font = font,
		size = 20,
		weight = 500
	})

	surface.CreateFont("nutDynFontSmall", {
		font = font,
		size = ScreenScale(22),
		weight = 1000
	})

	surface.CreateFont("nutDynFontMedium", {
		font = font,
		size = ScreenScale(28),
		weight = 1000
	})

	surface.CreateFont("nutDynFontBig", {
		font = font,
		size = ScreenScale(48),
		weight = 1000
	})

	-- The more readable font.
	font = "Calibri"

	surface.CreateFont("nutCleanTitleFont", {
		font = font,
		size = 200,
		weight = 1000
	})

	surface.CreateFont("nutHugeFont", {
		font = font,
		size = 72,
		weight = 1000
	})

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

	surface.CreateFont("nutMediumLightFont", {
		font = font,
		size = 26,
		weight = 200
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

	surface.CreateFont("nutSmallBoldFont", {
		font = font,
		size = 20,
		weight = 800
	})

	-- Introduction fancy font.
	font = "Cambria"

	surface.CreateFont("nutIntroTitleFont", {
		font = font,
		size = 200,
		weight = 1000
	})

	surface.CreateFont("nutIntroBigFont", {
		font = font,
		size = 48,
		weight = 1000
	})

	surface.CreateFont("nutIntroMediumFont", {
		font = font,
		size = 28,
		weight = 1000
	})

	surface.CreateFont("nutIntroSmallFont", {
		font = font,
		size = 22,
		weight = 1000
	})

	surface.CreateFont("nutIconsSmall", {
		font = "fontello",
		size = 22,
		weight = 500
	})

	surface.CreateFont("nutIconsMedium", {
		font = "fontello",
		size = 28,
		weight = 500
	})

	surface.CreateFont("nutIconsBig", {
		font = "fontello",
		size = 48,
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
	
	if (NUT_CVAR_LOWER2:GetBool() and weapon.LowerAngles2) then
		rotation = weapon.LowerAngles2
	end
	
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

function GM:LoadIntro()
	-- If skip intro is on
	if (true) then 
		if (IsValid(nut.gui.char)) then
			vgui.Create("nutCharMenu")
		end
	else

	end
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

		hook.Run("LoadIntro")
	end
end

function GM:InitPostEntity()
	nut.joinTime = CurTime()
end

local vignette = nut.util.getMaterial("nutscript/gui/vignette.png")
local vignetteAlphaGoal = 0
local vignetteAlphaDelta = 0

local blurGoal = 0
local blurDelta = 0

timer.Create("nutVignetteChecker", 1, 0, function()
	local client = LocalPlayer()

	if (IsValid(client)) then
		local data = {}
			data.start = client:GetPos()
			data.endpos = data.start + Vector(0, 0, 768)
			data.filter = client
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

function GM:CalcView(client, origin, angles, fov)
	local view = self.BaseClass:CalcView(client, origin, angles, fov) or {}
	local entity = Entity(client:getLocalVar("ragdoll", 0))
	local ragdoll = client:GetRagdollEntity()

	if ((!client:ShouldDrawLocalPlayer() and IsValid(entity) and entity:IsRagdoll()) or 
		(!LocalPlayer():Alive() and IsValid(ragdoll))) then
	 	local ent = LocalPlayer():Alive() and entity or ragdoll
		local index = ent:LookupAttachment("eyes")

		if (index) then
			local data = ent:GetAttachment(index)

			if (data) then
				view.origin = data.Pos
				view.angles = data.Ang
			end
			
			return view
		end
	end
end

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
			data.filter = localPlayer
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

	if (nut.screenColor) then
		local realTime = RealTime()
		local endTime = nut.screenColorEnd

		if (realTime > endTime) then
			nut.screenColor = nil
		else
			local alpha = math.Clamp(1 - math.TimeFraction(nut.screenColorStart, endTime, realTime), 0, 1)

			surface.SetDrawColor(nut.screenColor.r, nut.screenColor.g, nut.screenColor.g, nut.screenColor.a * alpha)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		end
	end

	blurGoal = localPlayer:getLocalVar("blur", 0) + (hook.Run("AdjustBlurAmount", blurGoal) or 0)

	if (blurDelta != blurGoal) then
		blurDelta = math.Approach(blurDelta, blurGoal, FrameTime() * 20)
	end

	if (blurDelta > 0 and !LocalPlayer():ShouldDrawLocalPlayer()) then
		nut.util.drawBlurAt(0, 0, ScrW(), ScrH(), blurDelta)
	end

	self.BaseClass:PaintWorldTips()

	local weapon = LocalPlayer():GetActiveWeapon()

	if (IsValid(weapon) and weapon.DrawAmmo != false) then
		local clip = weapon:Clip1()
		local count = localPlayer:GetAmmoCount(weapon:GetPrimaryAmmoType())
		local secondary = localPlayer:GetAmmoCount(weapon:GetSecondaryAmmoType())
		local x, y = ScrW() - 80, ScrH() - 80

		if (secondary > 0) then
			nut.util.drawBlurAt(x, y, 64, 64)

			surface.SetDrawColor(255, 255, 255, 5)
			surface.DrawRect(x, y, 64, 64)
			surface.SetDrawColor(255, 255, 255, 3)
			surface.DrawOutlinedRect(x, y, 64, 64)

			nut.util.drawText(secondary, x + 32, y + 32, nil, 1, 1, "nutBigFont")
		end

		if (weapon:GetClass() != "weapon_slam" and clip > 0 or count > 0) then
			x = x - (secondary > 0 and 144 or 64)

			nut.util.drawBlurAt(x, y, 128, 64)

			surface.SetDrawColor(255, 255, 255, 5)
			surface.DrawRect(x, y, 128, 64)
			surface.SetDrawColor(255, 255, 255, 3)
			surface.DrawOutlinedRect(x, y, 128, 64)

			nut.util.drawText(clip == -1 and count or clip.."/"..count, x + 64, y + 32, nil, 1, 1, "nutBigFont")
		end
	end

	nut.menu.drawAll()
	nut.bar.drawAll()
	nut.hud.drawAll(false)
end

function GM:PostDrawHUD()
	nut.hud.drawAll(true)
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

local injTextTable = {
	[.3] = {"injMajor", Color(192, 57, 43)},
	[.6] = {"injLittle", Color(231, 76, 60)},
}

function GM:GetInjuredText(client)
	local health = client:Health()

	for k, v in pairs(injTextTable) do
		if ((health / LocalPlayer():GetMaxHealth()) < k) then
			return v[1], v[2]
		end
	end
end

function GM:DrawEntityInfo(entity, alpha)
	if (entity:IsPlayer()) then
		local localPlayer = LocalPlayer()
		local position = (entity:GetPos() + (entity:Crouching() and OFFSET_CROUCHING or OFFSET_NORMAL)):ToScreen()
		local character = entity:getChar()

		if (character) then
			local x, y = position.x, position.y
			local tx, ty = 0, 0
			tx, ty = nut.util.drawText(hook.Run("GetDisplayedName", entity) or character:getName(), x, y, ColorAlpha(team.GetColor(entity:Team()), alpha), 1, 1, nil, alpha * 0.65)
			y = y + ty
			
			tx, ty = nut.util.drawText(character:getDesc(), x, y, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
			y = y + ty

			x, y = hook.Run("DrawCharInfo", character, x, y, alpha)
			
			local injText, injColor = hook.Run("GetInjuredText", entity)
			if (injText) then
				tx, ty = nut.util.drawText(L(injText), x, y, ColorAlpha(injColor, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
				y = y + ty
			end
		end
	end
end

function GM:PlayerBindPress(client, bind, pressed)
	bind = bind:lower()
	
	if (bind:find("gm_showhelp") and pressed) then
		if (IsValid(nut.gui.menu)) then
			nut.gui.menu:remove()
		elseif (LocalPlayer():getChar()) then
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
				data.endpos = data.start + client:GetAimVector()*96
				data.filter = client
			local trace = util.TraceLine(data)
			local entity = trace.Entity

			if (IsValid(entity) and entity:GetClass() == "nut_item") then
				hook.Run("ItemShowEntityMenu", entity)
			end
		end
	elseif (bind:find("jump")) then
		nut.command.send("chargetup")
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
hidden["CHudAmmo"] = true
hidden["CHudSecondaryAmmo"] = true
hidden["CHudCrosshair"] = true
hidden["CHudHistoryResource"] = true

function GM:HUDShouldDraw(element)
	if (hidden[element]) then
		return false
	end

	return true
end

function GM:SetupQuickMenu(menu)
	-- Performance
	menu:addCheck(L"cheapBlur", function(panel, state)
		if (state) then
			RunConsoleCommand("nut_cheapblur", "1")
		else
			RunConsoleCommand("nut_cheapblur", "0")
		end
	end, NUT_CVAR_CHEAP:GetBool())

	-- Language settings
	menu:addSpacer()

	local current

	for k, v in SortedPairs(nut.lang.stored) do
		local name = nut.lang.names[k]
		local name2 = k:sub(1, 1):upper()..k:sub(2)
		local enabled = NUT_CVAR_LANG:GetString():match(k)

		if (name) then
			name = name2.." ("..name..")"
		else
			name = name2
		end

		local button = menu:addCheck(name, function(panel)
			panel.checked = true
			
			if (IsValid(current)) then
				if (current == panel) then
					return
				end

				current.checked = false
			end

			current = panel
			RunConsoleCommand("nut_language", k)
		end, enabled)

		if (enabled and !IsValid(current)) then
			current = button
		end
	end

	-- Appearance
	menu:addSpacer()

	menu:addCheck(L"altLower", function(panel, state)
		if (state) then
			RunConsoleCommand("nut_usealtlower", "1")
		else
			RunConsoleCommand("nut_usealtlower", "0")
		end
	end, NUT_CVAR_LOWER2:GetBool())
end

function GM:ShouldDrawLocalPlayer(client)
	if (nut.gui.char:IsVisible()) then
		return true
	end
end

function GM:OnCharInfoSetup(infoPanel)
	if (infoPanel.model) then
		-- Get the F1 ModelPanel.
		local mdl = infoPanel.model
		local ent = mdl.Entity
		local client = LocalPlayer()

		if (client and client:Alive() and IsValid(client:GetActiveWeapon())) then
			local weapon = client:GetActiveWeapon()
			local weapModel = ClientsideModel(weapon:GetModel(), RENDERGROUP_BOTH)

			if (weapModel) then
				weapModel:SetParent(ent)
				weapModel:AddEffects(EF_BONEMERGE)
				weapModel:SetSkin(weapon:GetSkin())
				weapModel:SetColor(weapon:GetColor())
				ent.weapon = weapModel

				local act = ACT_MP_STAND_IDLE
				local model = ent:GetModel():lower()
				local class = nut.anim.getModelClass(model)
				local tree = nut.anim[class]

				if (tree) then
					local subClass = "normal"
					subClass = weapon:GetHoldType()
					subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass

					if (tree[subClass] and tree[subClass][act]) then
						local act2 = tree[subClass][act][1]

						if (type(act2) == "string") then
							act2 = ent:LookupSequence(act2)

							return
						else
							act2 = ent:SelectWeightedSequence(act2)
						end

						ent:ResetSequence(act2)
					end
				end
			end
		end
	end
end

function GM:DrawNutModelView(panel, ent)
	if (ent.weapon and IsValid(ent.weapon)) then
		ent.weapon:DrawModel()
	end
end

netstream.Hook("strReq", function(time, title, subTitle, default)
	if (title:sub(1, 1) == "@") then
		title = L(title:sub(2))
	end

	if (subTitle:sub(1, 1) == "@") then
		subTitle = L(subTitle:sub(2))
	end

	Derma_StringRequest(title, subTitle, default or "", function(text)
		netstream.Start("strReq", time, text)
	end)
end)

netstream.Hook("scrClr", function(color, length, delay)
	nut.screenColor = color or color_white
	nut.screenColorStart = RealTime() + (delay or 0)
	nut.screenColorEnd = nut.screenColorStart + (length or 5)
end)