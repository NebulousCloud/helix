
local CREDITS = {
	{"Alex Grist", "76561197979205163", {"creditLeadDeveloper", "creditManager"}},
	{"Igor Radovanovic", "76561197990111113", {"creditLeadDeveloper", "creditUIDesigner"}},
	{"Jaydawg", "76561197970371430", {"creditTester"}}
}

local SPECIALS = {
	{
		{"Luna", "76561197988658543"},
		{"Rain GBizzle", "76561198036111376"}
	},
	{
		{"Black Tea", "76561197999893894"}
	}
}

local MISC = {
	{"nebulous", "Staff members finding bugs and providing input"},
	{"Contributors", "Ongoing support from various developers via GitHub"},
	{"NutScript", "Providing the base framework to build upon"}
}

local url = "https://gethelix.co/"
local padding = 32

-- logo
local PANEL = {}

function PANEL:Init()
	self:SetTall(ScrH() * 0.60)
	self:Dock(TOP)
end

function PANEL:Paint(width, height)
	derma.SkinFunc("DrawHelixCurved", width * 0.5, height * 0.5, width * 0.25)

	-- title
	surface.SetFont("ixIntroSubtitleFont")
	local text = L("helix"):lower()
	local textWidth, textHeight = surface.GetTextSize(text)

	surface.SetTextColor(color_white)
	surface.SetTextPos(width * 0.5 - textWidth * 0.5, height * 0.5 - textHeight * 0.5)
	surface.DrawText(text)

	-- version
	surface.SetFont("ixMenuMiniFont")
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetTextPos(width * 0.5 + textWidth * 0.5, height * 0.5 - textHeight * 0.5)
	surface.DrawText(GAMEMODE.Version)
end

vgui.Register("ixCreditsLogo", PANEL, "Panel")

-- nametag
PANEL = {}

function PANEL:Init()
	self.name = self:Add("DLabel")
	self.name:SetFont("ixMenuButtonFontThick")

	self.avatar = self:Add("AvatarImage")
end

function PANEL:SetName(name)
	self.name:SetText(name)
end

function PANEL:SetAvatar(steamid)
	self.avatar:SetSteamID(steamid, 64)
end

function PANEL:PerformLayout(width, height)
	self.name:SetPos(width - self.name:GetWide(), 0)
	self.avatar:MoveLeftOf(self.name, padding * 0.5)
end

function PANEL:SizeToContents()
	self.name:SizeToContents()

	local tall = self.name:GetTall()
	self.avatar:SetSize(tall, tall)
	self:SetSize(self.name:GetWide() + self.avatar:GetWide() + padding * 0.5, self.name:GetTall())
end

vgui.Register("ixCreditsNametag", PANEL, "Panel")

-- name row
PANEL = {}

function PANEL:Init()
	self:DockMargin(0, padding, 0, 0)
	self:Dock(TOP)

	self.nametag = self:Add("ixCreditsNametag")

	self.tags = self:Add("DLabel")
	self.tags:SetFont("ixMenuButtonFont")

	self:SizeToContents()
end

function PANEL:SetName(name)
	self.nametag:SetName(name)
end

function PANEL:SetAvatar(steamid)
	self.nametag:SetAvatar(steamid)
end

function PANEL:SetTags(tags)
	for i = 1, #tags do
		tags[i] = L(tags[i])
	end

	self.tags:SetText(table.concat(tags, "\n"))
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(ix.config.Get("color"))
	surface.DrawRect(width * 0.5 - 1, 0, 1, height)
end

function PANEL:PerformLayout(width, height)
	self.nametag:SetPos(width * 0.5 - self.nametag:GetWide() - padding, 0)
	self.tags:SetPos(width * 0.5 + padding, 0)
end

function PANEL:SizeToContents()
	self.nametag:SizeToContents()
	self.tags:SizeToContents()

	self:SetTall(math.max(self.nametag:GetTall(), self.tags:GetTall()))
end

vgui.Register("ixCreditsRow", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
	self.left = {}
	self.right = {}
end

function PANEL:AddLeft(name, steamid)
	local nametag = self:Add("ixCreditsNametag")
	nametag:SetName(name)
	nametag:SetAvatar(steamid)
	nametag:SizeToContents()

	self.left[#self.left + 1] = nametag
end

function PANEL:AddRight(name, steamid)
	local nametag = self:Add("ixCreditsNametag")
	nametag:SetName(name)
	nametag:SetAvatar(steamid)
	nametag:SizeToContents()

	self.right[#self.right + 1] = nametag
end

function PANEL:PerformLayout(width, height)
	local y = 0

	for _, v in ipairs(self.left) do
		v:SetPos(width * 0.25 - v:GetWide() * 0.5, y)
		y = y + v:GetTall() + padding
	end

	y = 0

	for _, v in ipairs(self.right) do
		v:SetPos(width * 0.75 - v:GetWide() * 0.5, y)
		y = y + v:GetTall() + padding
	end

	if (IsValid(self.center)) then
		self.center:SetPos(width * 0.5 - self.center:GetWide() * 0.5, y)
	end
end

function PANEL:SizeToContents()
	local heightLeft, heightRight, centerHeight = 0, 0, 0

	if (#self.left > #self.right) then
		local center = self.left[#self.left]
		centerHeight = center:GetTall()

		self.center = center
		self.left[#self.left] = nil
	elseif (#self.right > #self.left) then
		local center = self.right[#self.right]
		centerHeight = center:GetTall()

		self.center = center
		self.right[#self.right] = nil
	end

	for _, v in ipairs(self.left) do
		heightLeft = heightLeft + v:GetTall() + padding
	end

	for _, v in ipairs(self.right) do
		heightRight = heightRight + v:GetTall() + padding
	end

	self:SetTall(math.max(heightLeft, heightRight) + centerHeight)
end

vgui.Register("ixCreditsSpecials", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
	self:Add("ixCreditsLogo")

	local link = self:Add("DLabel", self)
	link:SetFont("ixMenuMiniFont")
	link:SetTextColor(Color(200, 200, 200, 255))
	link:SetText(url)
	link:SetContentAlignment(5)
	link:Dock(TOP)
	link:SizeToContents()
	link:SetMouseInputEnabled(true)
	link:SetCursor("hand")
	link.OnMousePressed = function()
		gui.OpenURL(url)
	end

	for _, v in ipairs(CREDITS) do
		local row = self:Add("ixCreditsRow")
		row:SetName(v[1])
		row:SetAvatar(v[2])
		row:SetTags(v[3])
		row:SizeToContents()
	end

	local specials = self:Add("ixLabel")
	specials:SetFont("ixMenuButtonFont")
	specials:SetText(L("creditSpecial"):utf8upper())
	specials:SetTextColor(ix.config.Get("color"))
	specials:SetDropShadow(1)
	specials:SetKerning(16)
	specials:SetContentAlignment(5)
	specials:DockMargin(0, padding * 2, 0, padding)
	specials:Dock(TOP)
	specials:SizeToContents()

	local specialList = self:Add("ixCreditsSpecials")
	specialList:DockMargin(0, padding, 0, 0)
	specialList:Dock(TOP)

	for _, v in ipairs(SPECIALS[1]) do
		specialList:AddLeft(v[1], v[2])
	end

	for _, v in ipairs(SPECIALS[2]) do
		specialList:AddRight(v[1], v[2])
	end

	specialList:SizeToContents()

	-- less more padding if there's a center column nametag
	if (IsValid(specialList.center)) then
		specialList:DockMargin(0, padding, 0, padding)
	end

	for _, v in ipairs(MISC) do
		local title = self:Add("DLabel")
		title:SetFont("ixMenuButtonFontThick")
		title:SetText(v[1])
		title:SetContentAlignment(5)
		title:SizeToContents()
		title:DockMargin(0, padding, 0, 0)
		title:Dock(TOP)

		local description = self:Add("DLabel")
		description:SetFont("ixSmallTitleFont")
		description:SetText(v[2])
		description:SetContentAlignment(5)
		description:SizeToContents()
		description:Dock(TOP)
	end

	self:Dock(TOP)
	self:SizeToContents()
end

function PANEL:SizeToContents()
	local height = padding

	for _, v in pairs(self:GetChildren()) do
		local _, top, _, bottom = v:GetDockMargin()
		height = height + v:GetTall() + top + bottom
	end

	self:SetTall(height)
end

vgui.Register("ixCredits", PANEL, "Panel")

hook.Add("PopulateHelpMenu", "ixCredits", function(tabs)
	tabs["credits"] = function(container)
		container:Add("ixCredits")
	end
end)
