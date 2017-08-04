if (SERVER) then return end

TOOLTIP_GENERIC = 0
TOOLTIP_ITEM = 1

local tooltip_delay = 0.01

local PANEL = {}

function PANEL:Init()

	self:SetDrawOnTop( true )
	self.DeleteContentsOnClose = false
	self:SetText( "" )
	self:SetFont( "nutToolTipText" )

end

function PANEL:UpdateColours( skin )
	return self:SetTextStyleColor(color_black)
end

function PANEL:SetContents( panel, bDelete )
	panel:SetParent( self )

	self.Contents = panel
	self.DeleteContentsOnClose = bDelete or false
	self.Contents:SizeToContents()
	self:InvalidateLayout( true )

	self.Contents:SetVisible( false )
end

function PANEL:PerformLayout()
	if (self.iconMode != TOOLTIP_ITEM) then
		if ( self.Contents ) then
			self:SetWide( self.Contents:GetWide() + 8 )
			self:SetTall( self.Contents:GetTall() + 8 )
			self.Contents:SetPos( 4, 4 )
		else
			local w, h = self:GetContentSize()
			self:SetSize( w + 8, h + 6 )
			self:SetContentAlignment( 5 )
		end
	end
end

local Mat = Material( "vgui/arrow" )

function PANEL:DrawArrow( x, y )
	self.Contents:SetVisible( true )

	surface.SetMaterial( Mat )
	surface.DrawTexturedRect( self.ArrowPosX + x, self.ArrowPosY + y, self.ArrowWide, self.ArrowTall )
end

local itemWidth = ScrW()*.15
function PANEL:PositionTooltip()
	if ( !IsValid( self.TargetPanel ) ) then
		self:Remove()
		return
	end

	self:PerformLayout()

	local x, y = input.GetCursorPos()
	local w, h = self:GetSize()

	local lx, ly = self.TargetPanel:LocalToScreen( 0, 0 )

	y = y - 50

	y = math.min( y, ly - h * 1.5 )
	if ( y < 2 ) then y = 2 end

	-- Fixes being able to be drawn off screen
	self:SetPos( math.Clamp( x - w * 0.5, 0, ScrW() - self:GetWide() ), math.Clamp( y, 0, ScrH() - self:GetTall() ) )
end

function PANEL:Paint( w, h )
	self:PositionTooltip()

	if (self.iconMode == TOOLTIP_ITEM) then
		nut.util.drawBlur(self, 10)
		surface.SetDrawColor(55, 55, 55, 120)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 120)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

		if (self.markupObject) then
			self.markupObject:draw(15, 10)
		end
	else
		derma.SkinHook( "Paint", "Tooltip", self, w, h )
	end
end

function PANEL:OpenForPanel( panel )
	self.TargetPanel = panel
	self:PositionTooltip()
	
	if (panel.itemID) then
		self.iconMode = TOOLTIP_ITEM
	end
	
	if (self.iconMode == TOOLTIP_ITEM) then
		self.markupObject = nut.markup.parse(self:GetText(), itemWidth)
		self:SetText("")
		self:SetWide(math.max(itemWidth, 200) + 15)
		self:SetHeight(self.markupObject:getHeight() + 20)
	end

	if ( tooltip_delay > 0 ) then

		self:SetVisible( false )
		timer.Simple( tooltip_delay, function()
			if ( !IsValid( self ) ) then return end
			if ( !IsValid( panel ) ) then return end

			self:PositionTooltip()
			self:SetVisible( true )
		end )
	end

end

function PANEL:Close()

	if ( !self.DeleteContentsOnClose && self.Contents ) then

		self.Contents:SetVisible( false )
		self.Contents:SetParent( nil )

	end

	self:Remove()

end

function PANEL:GenerateExample( ClassName, PropertySheet, Width, Height )

	local ctrl = vgui.Create( "DButton" )
	ctrl:SetText( "Hover me" )
	ctrl:SetWide( 200 )
	ctrl:SetTooltip( "This is a tooltip" )

	PropertySheet:AddSheet( ClassName, ctrl, nil, true, true )

end

derma.DefineControl( "DTooltip", "", PANEL, "DLabel" )
