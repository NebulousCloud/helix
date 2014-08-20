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
end

function GM:InitializedConfig()
	local font = nut.config.get("font")
	local fault = GetNetVar("dbError")

	hook.Run("LoadFonts", font)

	local loader = vgui.Create("EditablePanel")
	loader:ParentToHUD()
	loader:Dock(FILL)
	loader.Paint = function(this, w, h)
		surface.SetDrawColor(0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end

	local label = loader:Add("DLabel")
	label:Dock(FILL)
	label:SetFont("nutTitleFont")
	label:SetText(fault and L"dbError" or L"loading")
	label:SetContentAlignment(5)
	label:SetTextColor(color_white)

	if (fault) then
		local label = loader:Add("DLabel")
		label:DockMargin(0, 64, 0, 0)
		label:Dock(TOP)
		label:SetFont("nutSubTitleFont")
		label:SetText(fault)
		label:SetContentAlignment(5)
		label:SizeToContentsY()
		label:SetTextColor(Color(255, 50, 50))
	end

	nut.gui.loading = loader
end

function GM:HUDPaint()
	nut.bar.drawAll()
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