
DEFINE_BASECLASS("Panel")

local PANEL = {}

AccessorFunc(PANEL, "fadeTime", "FadeTime", FORCE_NUMBER)
AccessorFunc(PANEL, "frameMargin", "FrameMargin", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(ix.gui.openedStorage)) then
		ix.gui.openedStorage:Remove()
	end

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetFadeTime(0.25)
	self:SetFrameMargin(4)

	self.storageInventory = vgui.Create("ixInventory", self)
	self.storageInventory:SetPaintedManually(true)
	self.storageInventory:ShowCloseButton(true)
	self.storageInventory:SetTitle("Storage")
	self.storageInventory.Close = function(this)
		netstream.Start("StorageClose")
		self:Remove()
	end

	ix.gui.inv1 = vgui.Create("ixInventory", self)
	ix.gui.inv1:SetPaintedManually(true)
	ix.gui.inv1:ShowCloseButton(true)
	ix.gui.inv1.Close = function(this)
		netstream.Start("StorageClose")
		self:Remove()
	end

	self:SetAlpha(0)
	self:AlphaTo(255, self:GetFadeTime())

	ix.gui.openedStorage = self
end

function PANEL:SetLocalInventory(inventory)
	if (IsValid(ix.gui.inv1) and !IsValid(ix.gui.menu)) then
		ix.gui.inv1:SetInventory(inventory)
		ix.gui.inv1:SetPos(self:GetWide() / 2 + self:GetFrameMargin() / 2, self:GetTall() / 2 - ix.gui.inv1:GetTall() / 2)
	end
end

function PANEL:SetStorageTitle(title)
	self.storageInventory:SetTitle(title)
end

function PANEL:SetStorageInventory(inventory)
	self.storageInventory:SetInventory(inventory)
	self.storageInventory:SetPos(self:GetWide() / 2 - self.storageInventory:GetWide() - 2, self:GetTall() / 2 - self.storageInventory:GetTall() / 2)

	ix.gui["inv" .. inventory:GetID()] = self.storageInventory
end

function PANEL:Paint(width, height)
	ix.util.DrawBlurAt(0, 0, width, height)

	-- manually paint so the parent alpha is accounted for
	if (IsValid(self.storageInventory)) then
		self.storageInventory:PaintManual()
	end

	if (IsValid(ix.gui.inv1)) then
		ix.gui.inv1:PaintManual()
	end
end

function PANEL:Remove()
	self:SetAlpha(255)
	self:AlphaTo(0, self:GetFadeTime(), 0, function()
		BaseClass.Remove(self)
	end)
end

function PANEL:OnRemove()
	if (!IsValid(ix.gui.menu)) then
		self.storageInventory:Remove()
		ix.gui.inv1:Remove()
	end
end

vgui.Register("ixStorageView", PANEL, "Panel")
