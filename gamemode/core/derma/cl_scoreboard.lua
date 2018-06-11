
local PANEL = {}
local paintFunctions = {}

paintFunctions[0] = function(this, w, h)
	surface.SetDrawColor(0, 0, 0, 50)
	surface.DrawRect(0, 0, w, h)
end

paintFunctions[1] = function(this, w, h)
end

function PANEL:Init()
	if (IsValid(ix.gui.score)) then
		ix.gui.score:Remove()
	end

	ix.gui.score = self
	self:Dock(FILL)

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)
	self.scroll:DockMargin(1, 0, 1, 0)
	self.scroll.VBar:SetWide(0)

	self.layout = self.scroll:Add("DListLayout")
	self.layout:Dock(TOP)

	self.teams = {}
	self.slots = {}
	self.i = {}

	for k, v in ipairs(ix.faction.indices) do
		local color = team.GetColor(k)
		local r, g, b = color.r, color.g, color.b

		local list = self.layout:Add("DListLayout")
		list:Dock(TOP)
		list:SetTall(28)
		list.Think = function(this)
			for _, v2 in ipairs(team.GetPlayers(k)) do
				if (!IsValid(v2.ixScoreSlot) or v2.ixScoreSlot:GetParent() != this) then
					if (IsValid(v2.ixPlayerSlot)) then
						v2.ixPlayerSlot:SetParent(this)
					else
						self:AddPlayer(v2, this)
					end
				end
			end
		end

		local header = list:Add("DLabel")
		header:Dock(TOP)
		header:SetText(L(v.name))
		header:SetTextInset(3, 0)
		header:SetFont("ixMediumFont")
		header:SetTextColor(color_white)
		header:SetExpensiveShadow(1, color_black)
		header:SetTall(28)
		header.Paint = function(this, w, h)
			surface.SetDrawColor(r, g, b, 20)
			surface.DrawRect(0, 0, w, h)
		end

		self.teams[k] = list
	end
end

function PANEL:Think()
	if ((self.nextUpdate or 0) < CurTime()) then
		local visible, amount

		for k, v in ipairs(self.teams) do
			visible, amount = v:IsVisible(), team.NumPlayers(k)

			if (visible and amount == 0) then
				v:SetVisible(false)
				self.layout:InvalidateLayout()
			elseif (!visible and amount > 0) then
				v:SetVisible(true)
			end
		end

		for _, v in pairs(self.slots) do
			if (IsValid(v)) then
				v:Update()
			end
		end

		self.nextUpdate = CurTime() + 0.1
	end
end

function PANEL:AddPlayer(client, parent)
	if (!client:GetChar() or !IsValid(parent)) then
		return
	end

	local slot = parent:Add("DPanel")
	slot:Dock(TOP)
	slot:SetTall(64)
	slot:DockMargin(0, 0, 0, 1)
	slot.character = client:GetChar()

	client.ixScoreSlot = slot

	slot.model = slot:Add("ixSpawnIcon")
	slot.model:SetModel(client:GetModel(), client:GetSkin())
	slot.model:SetSize(64, 64)
	slot.model.DoClick = function()
		local menu = DermaMenu()
			local options = {}

			hook.Run("ShowPlayerOptions", client, options)

			if (table.Count(options) > 0) then
				for k, v in SortedPairs(options) do
					menu:AddOption(L(k), v[2]):SetImage(v[1])
				end
			end
		menu:Open()

		RegisterDermaMenuForClose(menu)
	end
	slot.model:SetTooltip(L("sbOptions", client:SteamName()))

	timer.Simple(0, function()
		if (!IsValid(slot)) then
			return
		end

		local entity = slot.model.Entity

		if (IsValid(entity)) then
			for _, v in ipairs(client:GetBodyGroups()) do
				entity:SetBodygroup(v.id, client:GetBodygroup(v.id))
			end

			for k, _ in ipairs(client:GetMaterials()) do
				entity:SetSubMaterial(k - 1, client:GetSubMaterial(k - 1))
			end
		end
	end)

	slot.name = slot:Add("DLabel")
	slot.name:SetText(client:Name())
	slot.name:Dock(TOP)
	slot.name:DockMargin(65, 0, 48, 0)
	slot.name:SetTall(18)
	slot.name:SetFont("ixGenericFont")
	slot.name:SetTextColor(color_white)
	slot.name:SetExpensiveShadow(1, color_black)

	slot.ping = slot:Add("DLabel")
	slot.ping:SetPos(self:GetWide() - 48, 0)
	slot.ping:SetSize(48, 64)
	slot.ping:SetText("0")
	slot.ping.Think = function(this)
		if (IsValid(client)) then
			this:SetText(client:Ping())
		end
	end
	slot.ping:SetFont("ixGenericFont")
	slot.ping:SetContentAlignment(6)
	slot.ping:SetTextColor(color_white)
	slot.ping:SetTextInset(16, 0)
	slot.ping:SetExpensiveShadow(1, color_black)

	slot.description = slot:Add("DLabel")
	slot.description:Dock(FILL)
	slot.description:DockMargin(65, 0, 48, 0)
	slot.description:SetWrap(true)
	slot.description:SetContentAlignment(7)
	slot.description:SetText(
		hook.Run("GetDisplayedDescription", client) or (client:GetChar() and client:GetChar():GetDescription()) or ""
	)
	slot.description:SetTextColor(color_white)
	slot.description:SetExpensiveShadow(1, Color(0, 0, 0, 100))
	slot.description:SetFont("ixSmallFont")

	local oldTeam = client:Team()

	slot.Update = function(panel)
		if (!IsValid(client) or !client:GetCharacter() or
			!panel.character or panel.character != client:GetCharacter() or
			oldTeam != client:Team()) then
			panel:Remove()

			local i = 0

			for _, v in ipairs(parent:GetChildren()) do
				if (IsValid(v.model) and v != panel) then
					i = i + 1
					v.Paint = paintFunctions[i % 2]
				end
			end

			return
		end

		local overrideName = hook.Run("ShouldAllowScoreboardOverride", client, "name") and hook.Run("GetDisplayedName", client)
		local name = overrideName or client:Name()
		local model = client:GetModel()
		local skin = client:GetSkin()
		local desc = hook.Run("ShouldAllowScoreboardOverride", client, "description") and
		hook.Run("GetDisplayedDescription", client) or (client:GetChar() and client:GetChar():GetDescription()) or ""

		panel.model:SetHidden(overrideName)

		if (panel.lastName != name) then
			panel.name:SetText(name)
			panel.lastName = name
		end

		local entity = panel.model.Entity

		if (panel.lastDesc != desc) then
			panel.description:SetText(desc)
			panel.lastDesc = desc
		end

		if (!IsValid(entity)) then
			return
		end

		if (panel.lastModel != model or panel.lastSkin != skin) then
			panel.model:SetModel(client:GetModel(), client:GetSkin())
			panel.model:SetTooltip(L("sbOptions", client:SteamName()))

			panel.lastModel = model
			panel.lastSkin = skin
		end

		timer.Simple(0, function()
			if (!IsValid(entity) or !IsValid(client)) then
				return
			end

			for _, v in ipairs(client:GetBodyGroups()) do
				entity:SetBodygroup(v.id, client:GetBodygroup(v.id))
			end
		end)
	end

	self.slots[#self.slots + 1] = slot

	parent:SetVisible(true)
	parent:SizeToChildren(false, true)
	parent:InvalidateLayout(true)

	local i = 0

	for _, v in ipairs(parent:GetChildren()) do
		if (IsValid(v.model)) then
			i = i + 1
			v.Paint = paintFunctions[i % 2]
		end
	end

	return slot
end

function PANEL:OnRemove()
	CloseDermaMenus()
end

function PANEL:Paint(w, h)
	ix.util.DrawBlur(self, 10)

	surface.SetDrawColor(30, 30, 30, 100)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawOutlinedRect(0, 0, w, h)
end

vgui.Register("ixScoreboard", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "ixScoreboard", function(tabs)
	tabs["scoreboard"] = function(panel)
		panel:Add("ixScoreboard")
	end
end)
