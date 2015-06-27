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
		CloseDermaMenus()
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
		size = ScreenScale(30),
		weight = 1000
	})

	surface.CreateFont("nutSubTitleFont", {
		font = font,
		size = ScreenScale(18),
		weight = 500
	})

	surface.CreateFont("nutMenuButtonFont", {
		font = font,
		size = ScreenScale(14),
		weight = 1000
	})

	surface.CreateFont("nutMenuButtonLightFont", {
		font = font,
		size = ScreenScale(14),
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
	font = "Segoe UI"

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
		size = 25,
		weight = 1000
	})

	surface.CreateFont("nutMediumLightFont", {
		font = font,
		size = 25,
		weight = 200
	})

	surface.CreateFont("nutGenericFont", {
		font = font,
		size = 20,
		weight = 1000
	})

	surface.CreateFont("nutChatFont", {
		font = font,
		size = math.max(ScreenScale(7), 17),
		weight = 200
	})

	surface.CreateFont("nutChatFontItalics", {
		font = font,
		size = math.max(ScreenScale(7), 17),
		weight = 200,
		italic = true
	})

	surface.CreateFont("nutSmallFont", {
		font = font,
		size = math.max(ScreenScale(6), 17),
		weight = 500
	})

	surface.CreateFont("nutSmallBoldFont", {
		font = font,
		size = math.max(ScreenScale(8), 20),
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
	nut.joinTime = RealTime() - 0.9716
end

local vignette = nut.util.getMaterial("nutscript/gui/vignette.png")
local vignetteAlphaGoal = 0
local vignetteAlphaDelta = 0
local blurGoal = 0
local blurDelta = 0
local hasVignetteMaterial = vignette != "___error"

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

	return self.BaseClass:CalcView(client, origin, angles, fov)
end

local nextUpdate = 0
local lastTrace = {}
local lastEntity
local mathApproach = math.Approach
local surface = surface
local hookRun = hook.Run
local toScreen = FindMetaTable("Vector").ToScreen

function GM:HUDPaint()
	local localPlayer = LocalPlayer()

	if (!localPlayer.getChar(localPlayer)) then
		return
	end
	
	local realTime = RealTime()
	local frameTime = FrameTime()
	local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()

	if (hasVignetteMaterial) then
		vignetteAlphaDelta = mathApproach(vignetteAlphaDelta, vignetteAlphaGoal, frameTime * 30)

		surface.SetDrawColor(0, 0, 0, 175 + vignetteAlphaDelta)
		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, scrW, scrH)
	end

	if (localPlayer.getChar(localPlayer) and nextUpdate < realTime) then
		nextUpdate = realTime + 0.5

		lastTrace.start = localPlayer.GetShootPos(localPlayer)
		lastTrace.endpos = lastTrace.start + localPlayer.GetAimVector(localPlayer)*160
		lastTrace.filter = localPlayer

		lastEntity = util.TraceLine(lastTrace).Entity

		if (IsValid(lastEntity) and (lastEntity.DrawEntityInfo or (lastEntity.onShouldDrawEntityInfo and lastEntity:onShouldDrawEntityInfo()) or hookRun("ShouldDrawEntityInfo", lastEntity))) then
			paintedEntitiesCache[lastEntity] = true
		end
	end

	for entity, drawing in pairs(paintedEntitiesCache) do
		if (IsValid(entity)) then
			local goal = drawing and 255 or 0
			local alpha = mathApproach(entity.nutAlpha or 0, goal, frameTime * 120)

			if (lastEntity != entity) then
				paintedEntitiesCache[entity] = false
			end

			if (alpha > 0) then
				local client = entity.getNetVar(entity, "player")

				if (IsValid(client)) then
					local position = toScreen(entity.LocalToWorld(entity, entity.OBBCenter(entity)))

					hookRun("DrawEntityInfo", client, alpha, position)
				elseif (entity.onDrawEntityInfo) then
					entity.onDrawEntityInfo(entity, alpha)
				else
					hookRun("DrawEntityInfo", entity, alpha)
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

	blurGoal = localPlayer.getLocalVar(localPlayer, "blur", 0) + (hookRun("AdjustBlurAmount", blurGoal) or 0)

	if (blurDelta != blurGoal) then
		blurDelta = mathApproach(blurDelta, blurGoal, frameTime * 20)
	end

	if (blurDelta > 0 and !localPlayer.ShouldDrawLocalPlayer(localPlayer)) then
		nut.util.drawBlurAt(0, 0, scrW, scrH, blurDelta)
	end

	self.BaseClass.PaintWorldTips(self.BaseClass)

	local weapon = localPlayer.GetActiveWeapon(localPlayer)

	if (IsValid(weapon) and weapon.DrawAmmo != false) then
		local clip = weapon.Clip1(weapon)
		local count = localPlayer.GetAmmoCount(localPlayer, weapon.GetPrimaryAmmoType(weapon))
		local secondary = localPlayer.GetAmmoCount(localPlayer, weapon.GetSecondaryAmmoType(weapon))
		local x, y = scrW - 80, scrH - 80

		if (secondary > 0) then
			nut.util.drawBlurAt(x, y, 64, 64)

			surface.SetDrawColor(255, 255, 255, 5)
			surface.DrawRect(x, y, 64, 64)
			surface.SetDrawColor(255, 255, 255, 3)
			surface.DrawOutlinedRect(x, y, 64, 64)

			nut.util.drawText(secondary, x + 32, y + 32, nil, 1, 1, "nutBigFont")
		end

		if (weapon.GetClass(weapon) != "weapon_slam" and clip > 0 or count > 0) then
			x = x - (secondary > 0 and 144 or 64)

			nut.util.drawBlurAt(x, y, 128, 64)

			surface.SetDrawColor(255, 255, 255, 5)
			surface.DrawRect(x, y, 128, 64)
			surface.SetDrawColor(255, 255, 255, 3)
			surface.DrawOutlinedRect(x, y, 128, 64)

			nut.util.drawText(clip == -1 and count or clip.."/"..count, x + 64, y + 32, nil, 1, 1, "nutBigFont")
		end
	end

	if (localPlayer.getLocalVar(localPlayer, "restricted") and !localPlayer.getLocalVar(localPlayer, "restrictNoMsg")) then
		nut.util.drawText(L"restricted", scrW * 0.5, scrH * 0.33, nil, 1, 1, "nutBigFont")
	end

	nut.menu.drawAll()
	nut.bar.drawAll()
	nut.hud.drawAll(false)
end

function GM:PostDrawHUD()
	nut.hud.drawAll(true)
end

function GM:ShouldDrawEntityInfo(entity)
	if (entity:IsPlayer() or IsValid(entity:getNetVar("player"))) then
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

local colorAlpha = ColorAlpha
local teamGetColor = team.GetColor
local drawText = nut.util.drawText

function GM:DrawCharInfo(client, character, info)
	local injText, injColor = hookRun("GetInjuredText", client)

	if (injText) then
		info[#info + 1] = {L(injText), injColor}
	end
end

local charInfo = {}

function GM:DrawEntityInfo(entity, alpha, position)
	if (entity.IsPlayer(entity)) then
		local localPlayer = LocalPlayer()
		local character = entity.getChar(entity)
		
		position = position or toScreen(entity.GetPos(entity) + (entity.Crouching(entity) and OFFSET_CROUCHING or OFFSET_NORMAL))

		if (character) then
			local x, y = position.x, position.y
			local ty = 0

			charInfo = {}
			charInfo[1] = {hookRun("GetDisplayedName", entity) or character.getName(character), teamGetColor(entity.Team(entity))}

			local description = character.getDesc(character)

			if (description != entity.nutDescCache) then
				entity.nutDescCache = description
				entity.nutDescLines = nut.util.wrapText(description, ScrW() * 0.7, "nutSmallFont")
			end

			for i = 1, #entity.nutDescLines do
				charInfo[#charInfo + 1] = {entity.nutDescLines[i]}
			end

			hookRun("DrawCharInfo", entity, character, charInfo)

			for i = 1, #charInfo do
				local info = charInfo[i]
				
				_, ty = drawText(info[1], x, y, colorAlpha(info[2] or color_white, alpha), 1, 1, "nutSmallFont")
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
	elseif (bind:find("speed") and client:KeyDown(IN_WALK) and pressed) then
		if (LocalPlayer():Crouching()) then
			RunConsoleCommand("-duck")
		else
			RunConsoleCommand("+duck")
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

	local function callback(index)
		if (IsValid(entity)) then
			netstream.Start("invAct", index, entity)
		end
	end

	itemTable.player = LocalPlayer()
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

			if (v.sound) then
				surface.PlaySound(v.sound)
			end

			if (send != false) then
				callback(k)
			end
		end
	end

	if (table.Count(options) > 0) then
		entity.nutMenuIndex = nut.menu.add(options, entity)
	end

	itemTable.player = nil
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
			name = name.." ("..name2..")"
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
	if (IsValid(nut.gui.char) and nut.gui.char:IsVisible()) then
		return false
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
				weapModel:SetNoDraw(true)
				ent.weapon = weapModel

				local act = ACT_MP_STAND_IDLE
				local model = ent:GetModel():lower()
				local class = nut.anim.getModelClass(model)
				local tree = nut.anim[class]

				if (tree) then
					local subClass = weapon.HoldType or weapon:GetHoldType()
					subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass

					if (tree[subClass] and tree[subClass][act]) then
						local branch = tree[subClass][act]
						local act2 = type(branch) == "table" and branch[1] or branch

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

function GM:ShowPlayerOptions(client, options)
	options["viewProfile"] = {"icon16/user.png", function()
		if (IsValid(client)) then
			client:ShowProfile()
		end	
	end}
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

function GM:PostPlayerDraw(client)
	if (client and client:getChar() and client:GetNoDraw() != true) then
		local wep = client:GetActiveWeapon()
		local curClass = ((wep and wep:IsValid()) and wep:GetClass():lower() or "")

		for k, v in ipairs(client:GetWeapons()) do
			if (v and IsValid(v)) then
				local class = v:GetClass():lower()
				local drawInfo = HOLSTER_DRAWINFO[class]

				if (drawInfo) then
					client.holsteredWeapons = client.holsteredWeapons or {}

					if (!client.holsteredWeapons[class] or !IsValid(client.holsteredWeapons[class])) then
						client.holsteredWeapons[class] = ClientsideModel(drawInfo.model, RENDERGROUP_TRANSLUCENT)
						client.holsteredWeapons[class]:SetNoDraw(true)
					end

					local drawModel = client.holsteredWeapons[class]
					local boneIndex = client:LookupBone(drawInfo.bone)

					if (boneIndex and boneIndex > 0) then
						local bonePos, boneAng = client:GetBonePosition(boneIndex)

						if (curClass != class and drawModel and IsValid(drawModel)) then
							local Right 	= boneAng:Right()
							local Up 		= boneAng:Up()
							local Forward 	= boneAng:Forward()	

							boneAng:RotateAroundAxis(Right, drawInfo.ang[1])
							boneAng:RotateAroundAxis(Up, drawInfo.ang[2])
							boneAng:RotateAroundAxis(Forward, drawInfo.ang[3])

							bonePos = bonePos + drawInfo.pos[1] * Right
							bonePos = bonePos + drawInfo.pos[2] * Forward
							bonePos = bonePos + drawInfo.pos[3] * Up

							drawModel:SetRenderOrigin(bonePos)
							drawModel:SetRenderAngles(boneAng)
							drawModel:DrawModel()
						end
					end
				end
			end
		end

		if (client.holsteredWeapons) then
			for k, v in pairs(client.holsteredWeapons) do
				local weapon = client:GetWeapon(k)

				if (!weapon or !IsValid(weapon)) then
					v:Remove()
				end
			end
		end
	end
end

function GM:ScreenResolutionChanged(oldW, oldH)
	RunConsoleCommand("fixchatplz")
	hook.Run("LoadFonts", nut.config.get("font"))
end
