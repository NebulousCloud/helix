
local backgroundColor = Color(0, 0, 0, 66)

local PANEL = {}

AccessorFunc(PANEL, "maxWidth", "MaxWidth", FORCE_NUMBER)

function PANEL:Init()
	self:SetWide(180)
	self:Dock(LEFT)

	self.maxWidth = ScrW() * 0.2
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(backgroundColor)
	surface.DrawRect(0, 0, width, height)
end

function PANEL:SizeToContents()
	local width = 0

	for _, v in ipairs(self:GetChildren()) do
		width = math.max(width, v:GetWide())
	end

	self:SetSize(math.max(32, math.min(width, self.maxWidth)), self:GetParent():GetTall())
end

vgui.Register("ixHelpMenuCategories", PANEL, "EditablePanel")

-- help menu
PANEL = {}

function PANEL:Init()
	self:Dock(FILL)

	self.categories = {}
	self.categorySubpanels = {}
	self.categoryPanel = self:Add("ixHelpMenuCategories")

	self.canvasPanel = self:Add("EditablePanel")
	self.canvasPanel:Dock(FILL)

	self.idlePanel = self.canvasPanel:Add("Panel")
	self.idlePanel:Dock(FILL)
	self.idlePanel:DockMargin(8, 0, 0, 0)
	self.idlePanel.Paint = function(_, width, height)
		surface.SetDrawColor(backgroundColor)
		surface.DrawRect(0, 0, width, height)

		derma.SkinFunc("DrawHelixCurved", width * 0.5, height * 0.5, width * 0.25)

		surface.SetFont("ixIntroSubtitleFont")
		local text = L("helix"):lower()
		local textWidth, textHeight = surface.GetTextSize(text)

		surface.SetTextColor(color_white)
		surface.SetTextPos(width * 0.5 - textWidth * 0.5, height * 0.5 - textHeight * 0.75)
		surface.DrawText(text)

		surface.SetFont("ixMediumLightFont")
		text = L("helpIdle")
		local infoWidth, _ = surface.GetTextSize(text)

		surface.SetTextColor(color_white)
		surface.SetTextPos(width * 0.5 - infoWidth * 0.5, height * 0.5 + textHeight * 0.25)
		surface.DrawText(text)
	end

	local categories = {}
	hook.Run("PopulateHelpMenu", categories)

	for k, v in SortedPairs(categories) do
		if (!isstring(k)) then
			ErrorNoHalt("expected string for help menu key\n")
			continue
		elseif (!isfunction(v)) then
			ErrorNoHalt(string.format("expected function for help menu entry '%s'\n", k))
			continue
		end

		self:AddCategory(k)
		self.categories[k] = v
	end

	self.categoryPanel:SizeToContents()

	if (ix.gui.lastHelpMenuTab) then
		self:OnCategorySelected(ix.gui.lastHelpMenuTab)
	end
end

function PANEL:AddCategory(name)
	local button = self.categoryPanel:Add("ixMenuButton")
	button:SetText(L(name))
	-- @todo don't hardcode this but it's the only panel that needs docking at the bottom so it'll do for now
	button:Dock(name == "credits" and BOTTOM or TOP)
	button.DoClick = function()
		self:OnCategorySelected(name)
	end

	local panel = self.canvasPanel:Add("DScrollPanel")
	panel:SetVisible(false)
	panel:Dock(FILL)
	panel:DockMargin(8, 0, 0, 0)
	panel:GetCanvas():DockPadding(8, 8, 8, 8)

	panel.Paint = function(_, width, height)
		surface.SetDrawColor(backgroundColor)
		surface.DrawRect(0, 0, width, height)
	end

	-- reverts functionality back to a standard panel in the case that a category will manage its own scrolling
	panel.DisableScrolling = function()
		panel:GetCanvas():SetVisible(false)
		panel:GetVBar():SetVisible(false)
		panel.OnChildAdded = function() end
	end

	self.categorySubpanels[name] = panel
end

function PANEL:OnCategorySelected(name)
	local panel = self.categorySubpanels[name]

	if (!IsValid(panel)) then
		return
	end

	if (!panel.bPopulated) then
		self.categories[name](panel)
		panel.bPopulated = true
	end

	if (IsValid(self.activeCategory)) then
		self.activeCategory:SetVisible(false)
	end

	panel:SetVisible(true)
	self.idlePanel:SetVisible(false)

	self.activeCategory = panel
	ix.gui.lastHelpMenuTab = name
end

vgui.Register("ixHelpMenu", PANEL, "EditablePanel")

local function DrawHelix(width, height, color) -- luacheck: ignore 211
	local segments = 76
	local radius = math.min(width, height) * 0.375

	surface.SetTexture(-1)

	for i = 1, math.ceil(segments) do
		local angle = math.rad((i / segments) * -360)
		local x = width * 0.5 + math.sin(angle + math.pi * 2) * radius
		local y = height * 0.5 + math.cos(angle + math.pi * 2) * radius
		local barOffset = math.sin(SysTime() + i * 0.5)
		local barHeight = barOffset * radius * 0.25

		if (barOffset > 0) then
			surface.SetDrawColor(color)
		else
			surface.SetDrawColor(Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a))
		end

		surface.DrawTexturedRectRotated(x, y, 4, barHeight, math.deg(angle))
	end
end

hook.Add("CreateMenuButtons", "ixHelpMenu", function(tabs)
	tabs["help"] = function(container)
		container:Add("ixHelpMenu")
	end
end)

hook.Add("PopulateHelpMenu", "ixHelpMenu", function(tabs)
	tabs["commands"] = function(container)
		-- info text
		local info = container:Add("DLabel")
		info:SetFont("ixSmallFont")
		info:SetText(L("helpCommands"))
		info:SetContentAlignment(5)
		info:SetTextColor(color_white)
		info:SetExpensiveShadow(1, color_black)
		info:Dock(TOP)
		info:DockMargin(0, 0, 0, 8)
		info:SizeToContents()
		info:SetTall(info:GetTall() + 16)

		info.Paint = function(_, width, height)
			surface.SetDrawColor(ColorAlpha(derma.GetColor("Info", info), 160))
			surface.DrawRect(0, 0, width, height)
		end

		-- commands
		for uniqueID, command in SortedPairs(ix.command.list) do
			if (command.OnCheckAccess and !command:OnCheckAccess(LocalPlayer())) then
				continue
			end

			local bIsAlias = false
			local aliasText = ""

			-- we want to show aliases in the same entry for better readability
			if (command.alias) then
				local alias = istable(command.alias) and command.alias or {command.alias}

				for _, v in ipairs(alias) do
					if (v:lower() == uniqueID) then
						bIsAlias = true
						break
					end

					aliasText = aliasText .. ", /" .. v
				end

				if (bIsAlias) then
					continue
				end
			end

			-- command name
			local title = container:Add("DLabel")
			title:SetFont("ixMediumLightFont")
			title:SetText("/" .. command.name .. aliasText)
			title:Dock(TOP)
			title:SetTextColor(ix.config.Get("color"))
			title:SetExpensiveShadow(1, color_black)
			title:SizeToContents()

			-- syntax
			local syntaxText = command.syntax
			local syntax

			if (syntaxText != "" and syntaxText != "[none]") then
				syntax = container:Add("DLabel")
				syntax:SetFont("ixMediumLightFont")
				syntax:SetText(syntaxText)
				syntax:Dock(TOP)
				syntax:SetTextColor(color_white)
				syntax:SetExpensiveShadow(1, color_black)
				syntax:SetWrap(true)
				syntax:SetAutoStretchVertical(true)
				syntax:SizeToContents()
			end

			-- description
			local descriptionText = command:GetDescription()

			if (descriptionText != "") then
				local description = container:Add("DLabel")
				description:SetFont("ixSmallFont")
				description:SetText(descriptionText)
				description:Dock(TOP)
				description:SetTextColor(color_white)
				description:SetExpensiveShadow(1, color_black)
				description:SetWrap(true)
				description:SetAutoStretchVertical(true)
				description:SizeToContents()
				description:DockMargin(0, 0, 0, 8)
			elseif (syntax) then
				syntax:DockMargin(0, 0, 0, 8)
			else
				title:DockMargin(0, 0, 0, 8)
			end
		end
	end

	tabs["flags"] = function(container)
		-- info text
		local info = container:Add("DLabel")
		info:SetFont("ixSmallFont")
		info:SetText(L("helpFlags"))
		info:SetContentAlignment(5)
		info:SetTextColor(color_white)
		info:SetExpensiveShadow(1, color_black)
		info:Dock(TOP)
		info:DockMargin(0, 0, 0, 8)
		info:SizeToContents()
		info:SetTall(info:GetTall() + 16)

		info.Paint = function(_, width, height)
			surface.SetDrawColor(ColorAlpha(derma.GetColor("Info", info), 160))
			surface.DrawRect(0, 0, width, height)
		end

		-- flags
		for k, v in SortedPairs(ix.flag.list) do
			local background = ColorAlpha(
				LocalPlayer():GetCharacter():HasFlags(k) and derma.GetColor("Success", info) or derma.GetColor("Error", info), 88
			)

			local panel = container:Add("Panel")
			panel:Dock(TOP)
			panel:DockMargin(0, 0, 0, 8)
			panel:DockPadding(4, 4, 4, 4)
			panel.Paint = function(_, width, height)
				derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, background)
			end

			local flag = panel:Add("DLabel")
			flag:SetFont("ixMonoMediumFont")
			flag:SetText(string.format("[%s]", k))
			flag:Dock(LEFT)
			flag:SetTextColor(color_white)
			flag:SetExpensiveShadow(1, color_black)
			flag:SetTextInset(4, 0)
			flag:SizeToContents()
			flag:SetTall(flag:GetTall() + 8)

			local description = panel:Add("DLabel")
			description:SetFont("ixMediumLightFont")
			description:SetText(v.description)
			description:Dock(FILL)
			description:SetTextColor(color_white)
			description:SetExpensiveShadow(1, color_black)
			description:SetTextInset(8, 0)
			description:SizeToContents()
			description:SetTall(description:GetTall() + 8)

			panel:SizeToChildren(false, true)
		end
	end

	tabs["plugins"] = function(container)
		for _, v in SortedPairsByMemberValue(ix.plugin.list, "name") do
			-- name
			local title = container:Add("DLabel")
			title:SetFont("ixMediumLightFont")
			title:SetText(v.name or "Unknown")
			title:Dock(TOP)
			title:SetTextColor(ix.config.Get("color"))
			title:SetExpensiveShadow(1, color_black)
			title:SizeToContents()

			-- author
			local author = container:Add("DLabel")
			author:SetFont("ixSmallFont")
			author:SetText(string.format("%s: %s", L("author"), v.author))
			author:Dock(TOP)
			author:SetTextColor(color_white)
			author:SetExpensiveShadow(1, color_black)
			author:SetWrap(true)
			author:SetAutoStretchVertical(true)
			author:SizeToContents()

			-- description
			local descriptionText = v.description

			if (descriptionText != "") then
				local description = container:Add("DLabel")
				description:SetFont("ixSmallFont")
				description:SetText(descriptionText)
				description:Dock(TOP)
				description:SetTextColor(color_white)
				description:SetExpensiveShadow(1, color_black)
				description:SetWrap(true)
				description:SetAutoStretchVertical(true)
				description:SizeToContents()
				description:DockMargin(0, 0, 0, 8)
			else
				author:DockMargin(0, 0, 0, 8)
			end
		end
	end
end)
