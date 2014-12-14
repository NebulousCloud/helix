local PLUGIN = PLUGIN
local PANEL = {}

function PANEL:Init()
	self:SetTitle(L("areaManager"))
	self:SetSize(500, 400)
	self:Center()
	self:MakePopup()

	local noticeBar = self:Add("nutNoticeBar")
	noticeBar:Dock(TOP)
	noticeBar:setType(4)
	noticeBar:setText(L("areaManagerTip"))

	self.list = self:Add("PanelList")
	self.list:Dock(FILL)
	self.list:DockMargin(0, 5, 0, 0)
	self.list:SetSpacing(5)
	self.list:SetPadding(5)
	self.list:EnableVerticalScrollbar()

	self:loadBusinesses()
end

function PANEL:loadBusinesses()
	for class, data in pairs(PLUGIN.areaTable) do
		local panel = self.list:Add("DButton")
		panel:SetText(data.name)
		panel:SetFont("ChatFont")
		panel:SetTextColor(color_white)
		panel:SetTall(30)
		local onConfirm = function(newName)
			netstream.Start("areaEdit", class, {name = newName})
			self:Close()
		end
		panel.OnMousePressed = function(this, code)
			if (code == MOUSE_LEFT) then
				surface.PlaySound("buttons/blip1.wav")
				Derma_StringRequest(
					L("enterAreaName"),
					L("enterAreaName"),
					data.name,
					onConfirm
				)
			elseif (code == MOUSE_RIGHT) then
				surface.PlaySound("buttons/blip2.wav")

				local menu = DermaMenu()
					menu:AddOption(L"renameArea", function()
						Derma_StringRequest(
							L("enterAreaName"),
							L("enterAreaName"),
							data.name,
							onConfirm
						)
					end):SetImage("icon16/comment.png")
					menu:AddOption(L"moveToArea", function()
						netstream.Start("areaTeleport", class)
					end):SetImage("icon16/door_in.png")
					menu:AddOption(L"deleteArea", function()
						netstream.Start("areaRemove", class)
						self:Close()
					end):SetImage("icon16/cross.png")
				menu:Open()
			end
		end
		self.list:AddItem(panel)
	end
end

vgui.Register("nutAreaManager", PANEL, "DFrame")

netstream.Hook("nutAreaManager", function(areaList)
	PLUGIN.areaTable = areaList
	areaManager = vgui.Create("nutAreaManager")
end)