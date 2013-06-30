local gradient = surface.GetTextureID("gui/gradient")
local surface = surface

local PANEL = {}
	function PANEL:Init()
		self:SetSize(ScrW() * 0.375, ScrH() * 0.85)
		self:Center()
		self:MakePopup()
		self:SetDrawBackground(false)

		self.title = self:Add("DLabel")
		self.title:Dock(TOP)
		self.title:DockMargin(8, 8, 8, 0)
		self.title:SetText(GetHostName())
		self.title:SetFont("nut_ScoreTitleFont")
		self.title:SetTextColor(color_white)
		self.title:SetExpensiveShadow(2, color_black)
		self.title:SizeToContents()

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:DockMargin(8, 8, 8, 8)
		self.list:DockPadding(4, 4, 4, 4)
		self.list.Paint = function(panel, w, h)
			surface.SetDrawColor(100, 100, 100, 5)
			surface.DrawOutlinedRect(0, 0, w, h)

			surface.SetDrawColor(50, 50, 50, 150)
			surface.DrawRect(0, 0, w, h)
		end

		self:PopulateList()

		self.lastUpdate = 0
		self.lastCount = #player.GetAll()
	end

	function PANEL:PopulateList()
		for k, v in ipairs(team.GetAllTeams()) do
			if (team.NumPlayers(k) > 0) then
				local title = self.list:Add("DLabel")
				title:Dock(TOP)
				title:DockMargin(4, 0, 4, 4)
				title:SetText(v.Name)
				title:SetFont("nut_ScoreTeamFont")
				title:SizeToContents()
				title:SetTextColor(color_white)
				title:SetExpensiveShadow(1, color_black)

				for k2, v2 in ipairs(team.GetPlayers(k)) do
					if (v2.character) then
						local panel = self.list:Add("nut_PlayerScore")
						panel:DockMargin(4, 0, 4, 2)
						panel:Dock(TOP)
						panel:SetPlayer(v2)
					end
				end
			end
		end
	end

	function PANEL:Think()
		if (self.lastUpdate < CurTime()) then
			self.lastUpdate = CurTime() + 1

			if (self.lastCount != #player.GetAll()) then
				self.list:Clear(true)
				self:PopulateList()
			end

			self.lastCount = #player.GetAll()
		end
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(25, 25, 25, 200)
		surface.DrawOutlinedRect(0, 0, w, h)

		surface.SetDrawColor(200, 200, 200, 100)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

		surface.SetDrawColor(0, 0, 0, 230)
		surface.DrawRect(0, 0, w, h)
	end
vgui.Register("nut_Scoreboard", PANEL, "DPanel")

local PANEL = {}
	function PANEL:Init()
		local width = (ScrW() * 0.375) - 32

		self:SetTall(68)

		self.model = vgui.Create("SpawnIcon", self)
		self.model:SetPos(2, 2)
		self.model:SetSize(64, 64)
		self.model:SetModel("models/error.mdl")
		self.model.DoClick = function()
			if (IsValid(self.player)) then
				self.player:ShowProfile()
			end
		end
		self.model:SetToolTip("Click to open their profile.")

		self.name = vgui.Create("DLabel", self)
		self.name:SetPos(68, 2)
		self.name:SetText("John Doe")
		self.name:SetFont("nut_TargetFont")
		self.name:SetTextColor(color_white)
		self.name:SetExpensiveShadow(1, color_black)

		self.desc = vgui.Create("DLabel", self)
		self.desc:SetPos(68, 22)
		self.desc:SetText("...")
		self.desc:SetTextColor(color_white)
		self.desc:SetExpensiveShadow(1, color_black)
		self.desc:SetWrap(true)
		self.desc:SetTall(38)
		self.desc:SetWide(width - 128)
		self.desc:SetContentAlignment(7)


		self.ping = vgui.Create("DLabel", self)
		self.ping:SetPos(width - 84, 24)
		self.ping:SetText("000")
		self.ping:SetTextColor(color_white)
		self.ping:SetExpensiveShadow(1, color_black)
		self.ping:SetFont("nut_TargetFont")
		self.ping:SetContentAlignment(6)
	end

	function PANEL:SetPlayer(client)
		self.player = client

		self.model:SetModel(client:GetModel())
		self.model:SetToolTip("Click to open "..client:RealName().."'s Steam profile.")

		self.name:SetText(client:Name())
		self.name:SizeToContents()

		local description = client.character:GetVar("description")

		if (description) then
			self.desc:SetText(description)
		end
	end

	function PANEL:Think()
		if (IsValid(self.player)) then
			self.ping:SetText(self.player:Ping())
		end
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(5, 5, 5, 150)
		surface.DrawOutlinedRect(0, 0, w, h)

		surface.SetDrawColor(255, 255, 255, 10)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

		surface.SetDrawColor(125, 125, 125, 25)
		surface.DrawRect(0, 0, w, h)

		if (IsValid(self.player)) then
			local color = team.GetColor(self.player:Team())

			surface.SetDrawColor(color.r, color.g, color.b, 35)
			surface.SetTexture(gradient)
			surface.DrawTexturedRect(0, 0, w, h)
		end
	end
vgui.Register("nut_PlayerScore", PANEL, "DPanel")

function GM:ScoreboardShow()
	if (!IsValid(nut.gui.score)) then
		nut.gui.score = vgui.Create("nut_Scoreboard")
	end
end

function GM:ScoreboardHide()
	if (IsValid(nut.gui.score)) then
		nut.gui.score:Remove()
	end
end