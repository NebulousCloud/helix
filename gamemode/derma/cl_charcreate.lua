local PANEL = {}
local gradient3 = surface.GetTextureID("gui/center_gradient")
function PANEL:Init()
	local w, h = ScrW(), ScrH()
	self:SetSize( h/1.5, h/2 )
	self:MakePopup()
	self:SetTitle( "Character Creation" )
	self:Center()
	self:SetBackgroundBlur(true)
end
function PANEL:SetupFaction( index )
	if (!index) then
		return
	end
	self.faction = nut.faction.GetByID(index)
	if (!self.faction) then
		return
	end
		
	self.finish = self:Add("DButton")
	self.finish:Dock(BOTTOM)
	self.finish:DockMargin(0, 4, 0, 0)
	self.finish:SetText( "Submit" )
	self.finish:SetImage("icon16/building_go.png")
	self.finish:SetTall(28)
	self.finish.DoClick = function(panel)
		local name = self.name:GetText()
		local gender = string.lower(self.gender:GetValue())
		local desc = self.desc:GetText()
		local model = IsValid(self.selectedModel) and self.selectedModel.model
		local faction = index
		local attribs = {}
		for k, v in pairs(self.bars) do
			attribs[k] = v:GetValue()
		end
		local fault

		-- Huge if that verifies values for characters.
		if (!name or !string.find(name, "[^%s+]") or name == "") then
			fault = "You need to provide a valid name."
		elseif (!gender or (gender != "male" and gender != "female")) then
			fault = "You need to provide a valid gender."
		elseif (!desc or #desc < nut.config.descMinChars or !string.find(desc, "[^%s+]")) then
			fault = "You need to provide a valid description."
		elseif (!model) then
			fault = "You need to pick a valid model."
		elseif (!faction or !nut.faction.GetByID(faction)) then
			fault = "You did not choose a valid faction."
		end

		if (fault) then
			surface.PlaySound("buttons/button8.wav")
			nut.util.Notify( fault )
			return
		end

		netstream.Start("nut_CharCreate", {
			name = name,
			gender = gender,
			desc = desc,
			model = model,
			faction = faction,
			attribs = attribs
		})

		self:ShowCloseButton(false)
		panel:SetDisabled(true)
		timer.Simple(7.5, function()
			if (IsValid(self)) then
				self:Remove()
				chat.AddText(Color(255, 0, 0), "Character creation request timed out!")
			end
		end)
	end
		
	local leftTab = self:Add( "DPanel" )
	leftTab:SetWide( self:GetWide() / 3*2 )
	leftTab:DockMargin( 0, 0, 5, 0 )
	leftTab:Dock( LEFT )
	self.charInfo = leftTab:Add( "DScrollPanel" )
	self.charInfo:Dock( FILL )
	self:SetupInformation()
	
	self.charVisual = self:Add( "Panel" )
	self.charVisual:Dock( FILL )
	self:SetupModel()
end

function PANEL:SetupModel()
	
	/*
		local lp = self.charVisual:Add( "DPanel" )
		lp:Dock( BOTTOM )
		lp:SetTall( self:GetTall() / 4 )
		local sp = self.charVisual:Add( "DScrollPanel" )
		sp:Dock( FILL )
		local p = sp:Add( "nut_NoticePanel" )
		p:Dock( TOP )
		p:DockMargin( 5, 5, 5, 0 )
		p:SetText( "Disabled." )
	*/ -- Planned Update.
	
	local rightpanel = self.charVisual:Add( "DPanel" )
	rightpanel:Dock( FILL )
	rightpanel:DockMargin( 0, 0, 0, 5 )
	
	local uppermodel = rightpanel:Add( "DPanel" )
	uppermodel:Dock( FILL )
	uppermodel.Paint = function( p, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.SetTexture(gradient3)
		surface.DrawTexturedRect(w * 0.25, 0, w * 0.5, h)
	end
	
	local MODEL_ANGLE = Angle(10, 50, 0)
	self.modelpanel = uppermodel:Add("DModelPanel")
	self.modelpanel:Dock(FILL)
	self.modelpanel:SetFOV(45)
	self.modelpanel.OnCursorEntered = function() end
	self.modelpanel:SetDisabled(true)
	self.modelpanel:SetCursor("none")
	local SetModel = self.modelpanel.SetModel
	self.modelpanel.SetModel = function(panel, model)
		SetModel(panel, model)
		local entity = panel.Entity
		local sequence = entity:LookupSequence("idle")
		if (sequence <= 0) then
			sequence = entity:LookupSequence("idle_subtle")
		end
		if (sequence <= 0) then
			sequence = entity:LookupSequence("batonidle2")
		end
		if (sequence <= 0) then
			sequence = entity:LookupSequence("idle_unarmed")
		end
		if (sequence <= 0) then
			sequence = entity:LookupSequence("idle01")
		end
		if (sequence > 0) then
			entity:ResetSequence(sequence)
		end
	end
	self.modelpanel.LayoutEntity = function(panel, entity)
		if (!IsValid(self.modelpanel)) then
			panel:Remove()
			return
		end
		local xRatio = gui.MouseX() / ScrW()
		local yRatio = gui.MouseY() / ScrH()
		entity:SetPoseParameter("head_pitch", yRatio*60 - 30)
		entity:SetPoseParameter("head_yaw", (xRatio - 0.75)*60)
		entity:SetPos( Vector( 	0, 0, 2 ) )
		entity:SetAngles(MODEL_ANGLE)
		entity:SetIK( false )
		panel:RunAnimation()
	end
end
-- INFORMATION SECTION
function PANEL:SetupInformation()
	local noticePanel = self.charInfo:Add( "nut_NoticePanel" )
	noticePanel:Dock( TOP )
	noticePanel:DockMargin( 5, 5, 5, 0 )
	noticePanel:SetText(  nut.lang.Get("char_create_warn")  )
	
	local noticePanel = self.charInfo:Add( "nut_NoticePanel" )
	noticePanel:Dock( TOP )
	noticePanel:DockMargin( 5, 5, 5, 5 )
	noticePanel:SetType( 4 )
	noticePanel:SetText( nut.lang.Get("char_create_tip") )
	
	self:InfoAddName( nut.lang.Get("name") )	
	self:InfoAddDesc( nut.lang.Get("name_desc") )
	self.name = self.charInfo:Add("DTextEntry")
	self.name:Dock(TOP)
	self.name:DockMargin(10,0,10,0)
	self.name:SetAllowNonAsciiCharacters(true)
	self.name:SetText( "" )
	if (self.faction.GetDefaultName) then
		local name, editable = self.faction:GetDefaultName(self.name, "male")
		if (name) then
			self.name:SetEditable(editable or false)
			self.name:SetText(name)
		end
	end
		
	self:InfoAddName( nut.lang.Get("desc") )
	self:InfoAddDesc( nut.lang.Get("desc_char_req", nut.config.descMinChars) )
	self.desc = self.charInfo:Add("DTextEntry")
	self.desc:Dock(TOP)
	self.desc:DockMargin(10,0,10,0)
	self.desc:SetAllowNonAsciiCharacters(true)
	self.desc:SetText( "" )
	
	self:InfoAddName( nut.lang.Get("gender") )
	self:InfoAddDesc( nut.lang.Get("gender_desc") )
	self.gender = self.charInfo:Add( "DComboBox" )
	self.gender:Dock(TOP)
	self.gender:DockMargin(10,0,10,0)
	self.gender.OnSelect = function(panel, index, value, data)
		local gender = string.lower(value)
		timer.Simple(0, function()
			self:UpdateModels(self.faction[gender.."Models"])
			if (self.faction.GetDefaultName) then
				local name, editable = self.faction:GetDefaultName(self.name, gender)
				if (name) then
					self.name:SetEditable(editable or false)
					self.name:SetText(name)
				end
			end
		end)
	end
	if (self.faction.maleModels and #self.faction.maleModels > 0) then
		self.gender:AddChoice("Male")
	end
	if (self.faction.femaleModels and #self.faction.femaleModels > 0) then
		self.gender:AddChoice("Female")
	end
	-- Update model list when it's value is changed.
	
	self.models = {}
	self:InfoAddName( nut.lang.Get("model") )
	self:InfoAddDesc( nut.lang.Get("model_desc") )
	self.modelList = self.charInfo:Add( "DScrollPanel" )
	self.modelList:Dock(TOP)
	self.modelList:SetTall(128)
	self.modelList:DockMargin(10,0,10,0)
	self.model = self.modelList:Add("DIconLayout")
	self.model:Dock(FILL)
	self.gender:ChooseOptionID(1)
	
	local points = nut.config.startingPoints
	local pointsLeft = points
	self.remp = self.charInfo:Add( "nut_NoticePanel" )
	self.remp:Dock( TOP )
	self.remp:DockMargin( 5, 15, 5, 0 )
	self.remp:SetText( nut.lang.Get("points_left", pointsLeft) )
	self.remp:SetType( 7 )
	
	self.bars = {}

	for k, attribute in ipairs(nut.attribs.GetAll()) do
		local bar = self.charInfo:Add("nut_AttribBar")
		bar:Dock(TOP)
		bar:DockMargin( 8, 10, 8, 0 )
		bar:SetMax(nut.config.startingPoints)
		bar:SetText(attribute.name)
		bar:SetToolTip(attribute.desc)
		bar.OnChanged = function(panel2, hindered)
			if (hindered) then
				pointsLeft = pointsLeft + 1
			else
				pointsLeft = pointsLeft - 1
			end
			self.remp:SetText(nut.lang.Get("points_left", pointsLeft))
		end
		bar.CanChange = function(panel2, hindered)
			if (hindered) then
				return true
			end
			return pointsLeft > 0
		end
		self.bars[k] = bar
	end
		
	local dummy = self.charInfo:Add( "Panel" )
	dummy:Dock( TOP )
end

function PANEL:Think()
	if (!self:IsActive()) then
		self:MakePopup()
	end
end

function PANEL:UpdateModels( models )
	local highlight = table.Copy(nut.config.mainColor)
	highlight.a = 200

	for k, v in pairs(self.models) do
		v:Remove()
	end

	self.selectedModel = nil
	local selected = false

	for k, v in ipairs(models) do
		local icon = self.model:Add("SpawnIcon")
		icon:SetModel(v)
		icon.model = v
		icon.PaintOver = function(panel, w, h)
			local model = self.selectedModel
			if (IsValid(model) and model == panel) then
				surface.SetDrawColor(highlight)
				for i = 1, 3 do
					local i2 = i * 2
					surface.DrawOutlinedRect(i, i, w - i2, h - i2)
				end
			end
		end
		icon.DoClick = function(panel)
			surface.PlaySound("garrysmod/ui_click.wav")
			self.selectedModel = panel
			self.modelpanel:SetModel( v )
		end

		if (!selected) then
			self.selectedModel = icon
			selected = true
		end

		self.models[#self.models + 1] = icon
	end

	self.modelList.VBar:SetEnabled(true)
	self.modelList.VBar:SetScroll(0)
end

function PANEL:InfoAddName(name)
	local label = self.charInfo:Add("DLabel")
		label:SetFont("nut_ScoreTeamFont")
		label:SetTextColor(color_black)
		label:SetText(name)
		label:SizeToContents()
		label:Dock(TOP)
		label:DockMargin(10, 5, 10, 0)
	return label
end

function PANEL:InfoAddDesc( name )
	local label = self.charInfo:Add("DLabel")
		label:SetTextColor(color_black)
		label:SetText(name)
		label:SizeToContents()
		label:Dock( TOP )
		label:DockMargin(10, 0, 10, 5)
	return label
end

vgui.Register("nut_CharCreate", PANEL, "DFrame")