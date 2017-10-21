
DEFINE_BASECLASS("Panel")

local PANEL = {}

AccessorFunc(PANEL, "fadeTime", "FadeTime", FORCE_NUMBER)
AccessorFunc(PANEL, "frameMargin", "FrameMargin", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(nut.gui.openedStorage)) then
		nut.gui.openedStorage:Remove()
	end

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetFadeTime(0.25)
	self:SetFrameMargin(4)

	self.storageInventory = vgui.Create("nutInventory", self)
	self.storageInventory:SetPaintedManually(true)
	self.storageInventory:ShowCloseButton(true)
	self.storageInventory:SetTitle("Storage")
	self.storageInventory.Close = function(this)
		netstream.Start("StorageClose")
		self:Remove()
	end

	nut.gui.inv1 = vgui.Create("nutInventory", self)
	nut.gui.inv1:SetPaintedManually(true)
	nut.gui.inv1:ShowCloseButton(true)
	nut.gui.inv1.Close = function(this)
		netstream.Start("StorageClose")
		self:Remove()
	end

	self:SetAlpha(0)
	self:AlphaTo(255, self:GetFadeTime())

	nut.gui.openedStorage = self
end

function PANEL:SetLocalInventory(inventory)
	if (IsValid(nut.gui.inv1) and !IsValid(nut.gui.menu)) then
		nut.gui.inv1:SetInventory(inventory)
		nut.gui.inv1:SetPos(self:GetWide() / 2 + self:GetFrameMargin() / 2, self:GetTall() / 2 - nut.gui.inv1:GetTall() / 2)
	end
end

function PANEL:SetStorageTitle(title)
	self.storageInventory:SetTitle(title)
end

function PANEL:SetStorageInventory(inventory)
	self.storageInventory:SetInventory(inventory)
	self.storageInventory:SetPos(self:GetWide() / 2 - self.storageInventory:GetWide() - 2, self:GetTall() / 2 - self.storageInventory:GetTall() / 2)

	nut.gui["inv" .. inventory:GetID()] = self.storageInventory
end

function PANEL:Paint(width, height)
	nut.util.DrawBlurAt(0, 0, width, height)

	-- manually paint so the parent alpha is accounted for
	if (IsValid(self.storageInventory)) then
		self.storageInventory:PaintManual()
	end

	if (IsValid(nut.gui.inv1)) then
		nut.gui.inv1:PaintManual()
	end
end

function PANEL:Remove()
	self:SetAlpha(255)
	self:AlphaTo(0, self:GetFadeTime(), 0, function()
		BaseClass.Remove(self)
	end)
end

function PANEL:OnRemove()
	if (!IsValid(nut.gui.menu)) then
		self.storageInventory:Remove()
		nut.gui.inv1:Remove()
	end
end

vgui.Register("nutStorageView", PANEL, "Panel")
