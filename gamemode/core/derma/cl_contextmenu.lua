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

local PANEL = {}

AccessorFunc( PANEL, "m_bHangOpen", "HangOpen" )


function PANEL:Init()
	self:SetWorldClicker( true )

	self.Canvas = vgui.Create( "DCategoryList", self )
	self.m_bHangOpen = false
end

function PANEL:Open()

	self:SetHangOpen( false )
	
	if ( g_SpawnMenu:IsVisible() ) then
		g_SpawnMenu:Close( true )
	end
	
	if ( self:IsVisible() ) then return end
	
	CloseDermaMenus()
	
	self:MakePopup()
	self:SetVisible( true )
	self:SetKeyboardInputEnabled( false )
	self:SetMouseInputEnabled( true )
	
	RestoreCursorPosition()

	local bShouldShow = true;

	if ( bShouldShow && IsValid( spawnmenu.ActiveControlPanel() ) ) then
		self.OldParent = spawnmenu.ActiveControlPanel():GetParent()
		self.OldPosX, self.OldPosY = spawnmenu.ActiveControlPanel():GetPos()
		spawnmenu.ActiveControlPanel():SetParent( self )
		self.Canvas:Clear()
		self.Canvas:AddItem( spawnmenu.ActiveControlPanel() )
		self.Canvas:Rebuild()
		self.Canvas:SetVisible( true )
	else
		self.Canvas:SetVisible( false )
	end
	
	self:InvalidateLayout( true )

end


function PANEL:Close( bSkipAnim )

	if ( self:GetHangOpen() ) then
		self:SetHangOpen( false )
		return
	end
	
	RememberCursorPosition()
	
	CloseDermaMenus()

	self:SetKeyboardInputEnabled( false )
	self:SetMouseInputEnabled( false )
	
	self:SetAlpha( 255 )
	self:SetVisible( false )
	self:RestoreControlPanel()
	
end


function PANEL:PerformLayout()
	
	self:SetPos( 0, 0 )
	self:SetSize( ScrW(), ScrH() )

	self.Canvas:SetWide( 311 )
	self.Canvas:SetPos( ScrW() - self.Canvas:GetWide() - 50, self.y )
	
	if ( IsValid( spawnmenu.ActiveControlPanel() ) ) then
	
		spawnmenu.ActiveControlPanel():InvalidateLayout( true )
		
		local Tall = spawnmenu.ActiveControlPanel():GetTall() + 10
		local MaxTall = ScrH() * 0.8
		if ( Tall > MaxTall ) then Tall = MaxTall end
		
		self.Canvas:SetTall( Tall )
		self.Canvas.y = ScrH() - 50 - Tall
	
	end
	
	self.Canvas:InvalidateLayout( true )
	
end


function PANEL:StartKeyFocus( pPanel )

	self:SetKeyboardInputEnabled( true )
	self:SetHangOpen( true )
	
end


function PANEL:EndKeyFocus( pPanel )

	self:SetKeyboardInputEnabled( false )

end


function PANEL:RestoreControlPanel()
	if ( !spawnmenu.ActiveControlPanel() ) then return end
	if ( !self.OldParent ) then return end
	
	spawnmenu.ActiveControlPanel():SetParent( self.OldParent )
	spawnmenu.ActiveControlPanel():SetPos( self.OldPosX, self.OldPosY )
	
	self.OldParent = nil
end

vgui.Register( "ContextMenu", PANEL, "EditablePanel" )

function CreateContextMenu()
	if ( IsValid( g_ContextMenu ) ) then
		g_ContextMenu:Remove()
		g_ContextMenu = nil
	end

	g_ContextMenu = vgui.Create( "ContextMenu" )
	g_ContextMenu:SetVisible( false )
	
	g_ContextMenu.OnMousePressed = function( p, code )
		hook.Run( "GUIMousePressed", code, gui.ScreenToVector( gui.MousePos() ) )
	end
	g_ContextMenu.OnMouseReleased = function( p, code )
		hook.Run( "GUIMouseReleased", code, gui.ScreenToVector( gui.MousePos() ) )
	end
	
	hook.Run( "ContextMenuCreated", g_ContextMenu )
end

function GM:OnContextMenuOpen()
	if ( !hook.Call( "ContextMenuOpen", GAMEMODE ) ) then return end
		
	if ( IsValid( g_ContextMenu ) && !g_ContextMenu:IsVisible() ) then
		g_ContextMenu:Open()
		menubar.ParentTo( g_ContextMenu )
	end

	vgui.Create("nutQuick", g_ContextMenu)

	print("AAOA")
	for k, v in ipairs(nut.bar.list) do
		v.visible = true
	end
end

function GM:OnContextMenuClose()
	if ( IsValid( g_ContextMenu ) ) then
		g_ContextMenu:Close()
	end

	if (IsValid(nut.gui.quick)) then
		nut.gui.quick:Remove()
	end

	for k, v in ipairs(nut.bar.list) do
		v.visible = nil
	end
end




local PANEL = {}

AccessorFunc( PANEL, "m_bBackground", 			"PaintBackground",	FORCE_BOOL )
AccessorFunc( PANEL, "m_bBackground", 			"DrawBackground", 	FORCE_BOOL )
AccessorFunc( PANEL, "m_bIsMenuComponent", 		"IsMenu", 			FORCE_BOOL )

AccessorFunc( PANEL, "m_bDisabled", 	"Disabled" )
AccessorFunc( PANEL, "m_bgColor", 		"BackgroundColor" )

Derma_Hook( PANEL, "Paint", "Paint", "MenuBar" )

--[[---------------------------------------------------------
	
-----------------------------------------------------------]]
function PANEL:Init()

	self:Dock( TOP )
	self:SetTall( 24 )
	self:SetDrawBackground(false)
	self.Menus = {}

end

function PANEL:Paint()
end

function PANEL:GetOpenMenu()

	for k, v in pairs( self.Menus ) do
		if ( v:IsVisible() ) then return v end
	end
	
	return nil

end

function PANEL:AddOrGetMenu( label )

	if ( self.Menus[ label ] ) then return self.Menus[ label ] end
	return self:AddMenu( label )

end

function PANEL:AddMenu( label )

	local m = DermaMenu()
		m:SetDeleteSelf( true )
		m:SetDrawColumn( true )
		m:Hide()
	self.Menus[ label ] = m

	return m

end

function PANEL:OnRemove()
	for id, pnl in pairs( self.Menus ) do
		pnl:Remove()
	end
end

--[[---------------------------------------------------------
   Name: GenerateExample
-----------------------------------------------------------]]
function PANEL:GenerateExample( ClassName, PropertySheet, Width, Height )
end


derma.DefineControl( "DMenuBar", "", PANEL, "DPanel" )