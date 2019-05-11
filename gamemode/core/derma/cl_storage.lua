
local PANEL = {}

AccessorFunc(PANEL, "money", "Money", FORCE_NUMBER)

function PANEL:Init()
	self:DockPadding(1, 1, 1, 1)
	self:SetTall(64)
	self:Dock(BOTTOM)

	self.moneyLabel = self:Add("DLabel")
	self.moneyLabel:Dock(TOP)
	self.moneyLabel:SetFont("ixGenericFont")
	self.moneyLabel:SetText("")
	self.moneyLabel:SetTextInset(2, 0)
	self.moneyLabel:SizeToContents()
	self.moneyLabel.Paint = function(panel, width, height)
		derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, ix.config.Get("color"))
	end

	self.amountEntry = self:Add("ixTextEntry")
	self.amountEntry:Dock(FILL)
	self.amountEntry:SetFont("ixGenericFont")
	self.amountEntry:SetNumeric(true)
	self.amountEntry:SetValue("0")

	self.transferButton = self:Add("DButton")
	self.transferButton:SetFont("ixIconsMedium")
	self:SetLeft(false)
	self.transferButton.DoClick = function()
		local amount = math.max(0, math.Round(tonumber(self.amountEntry:GetValue()) or 0))
		self.amountEntry:SetValue("0")

		if (amount != 0) then
			self:OnTransfer(amount)
		end
	end

	self.bNoBackgroundBlur = true
end

function PANEL:SetLeft(bValue)
	if (bValue) then
		self.transferButton:Dock(LEFT)
		self.transferButton:SetText("s")
	else
		self.transferButton:Dock(RIGHT)
		self.transferButton:SetText("t")
	end
end

function PANEL:SetMoney(money)
	local name = string.gsub(ix.util.ExpandCamelCase(ix.currency.plural), "%s", "")

	self.money = math.max(math.Round(tonumber(money) or 0), 0)
	self.moneyLabel:SetText(string.format("%s: %d", name, money))
end

function PANEL:OnTransfer(amount)
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintBaseFrame", self, width, height)
end

vgui.Register("ixStorageMoney", PANEL, "EditablePanel")

DEFINE_BASECLASS("Panel")
PANEL = {}

AccessorFunc(PANEL, "fadeTime", "FadeTime", FORCE_NUMBER)
AccessorFunc(PANEL, "frameMargin", "FrameMargin", FORCE_NUMBER)
AccessorFunc(PANEL, "storageID", "StorageID", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(ix.gui.openedStorage)) then
		ix.gui.openedStorage:Remove()
	end

	ix.gui.openedStorage = self

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetFadeTime(0.25)
	self:SetFrameMargin(4)

	self.storageInventory = self:Add("ixInventory")
	self.storageInventory.bNoBackgroundBlur = true
	self.storageInventory:ShowCloseButton(true)
	self.storageInventory:SetTitle("Storage")
	self.storageInventory.Close = function(this)
		net.Start("ixStorageClose")
		net.SendToServer()
		self:Remove()
	end

	self.storageMoney = self.storageInventory:Add("ixStorageMoney")
	self.storageMoney:SetVisible(false)
	self.storageMoney.OnTransfer = function(_, amount)
		net.Start("ixStorageMoneyTake")
			net.WriteUInt(self.storageID, 32)
			net.WriteUInt(amount, 32)
		net.SendToServer()
	end

	ix.gui.inv1 = self:Add("ixInventory")
	ix.gui.inv1.bNoBackgroundBlur = true
	ix.gui.inv1:ShowCloseButton(true)
	ix.gui.inv1.Close = function(this)
		net.Start("ixStorageClose")
		net.SendToServer()
		self:Remove()
	end

	self.localMoney = ix.gui.inv1:Add("ixStorageMoney")
	self.localMoney:SetVisible(false)
	self.localMoney:SetLeft(true)
	self.localMoney.OnTransfer = function(_, amount)
		net.Start("ixStorageMoneyGive")
			net.WriteUInt(self.storageID, 32)
			net.WriteUInt(amount, 32)
		net.SendToServer()
	end

	self:SetAlpha(0)
	self:AlphaTo(255, self:GetFadeTime())

	self.storageInventory:MakePopup()
	ix.gui.inv1:MakePopup()
end

function PANEL:OnChildAdded(panel)
	panel:SetPaintedManually(true)
end

function PANEL:SetLocalInventory(inventory)
	if (IsValid(ix.gui.inv1) and !IsValid(ix.gui.menu)) then
		ix.gui.inv1:SetInventory(inventory)
		ix.gui.inv1:SetPos(self:GetWide() / 2 + self:GetFrameMargin() / 2, self:GetTall() / 2 - ix.gui.inv1:GetTall() / 2)
	end
end

function PANEL:SetLocalMoney(money)
	if (!self.localMoney:IsVisible()) then
		self.localMoney:SetVisible(true)
		ix.gui.inv1:SetTall(ix.gui.inv1:GetTall() + self.localMoney:GetTall() + 2)
	end

	self.localMoney:SetMoney(money)
end

function PANEL:SetStorageTitle(title)
	self.storageInventory:SetTitle(title)
end

function PANEL:SetStorageInventory(inventory)
	self.storageInventory:SetInventory(inventory)
	self.storageInventory:SetPos(
		self:GetWide() / 2 - self.storageInventory:GetWide() - 2,
		self:GetTall() / 2 - self.storageInventory:GetTall() / 2
	)

	ix.gui["inv" .. inventory:GetID()] = self.storageInventory
end

function PANEL:SetStorageMoney(money)
	if (!self.storageMoney:IsVisible()) then
		self.storageMoney:SetVisible(true)
		self.storageInventory:SetTall(self.storageInventory:GetTall() + self.storageMoney:GetTall() + 2)
	end

	self.storageMoney:SetMoney(money)
end

function PANEL:Paint(width, height)
	ix.util.DrawBlurAt(0, 0, width, height)

	for _, v in ipairs(self:GetChildren()) do
		v:PaintManual()
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
