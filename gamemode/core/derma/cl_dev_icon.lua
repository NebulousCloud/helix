--Icon Editor Base and Math Scale Functions from: https://github.com/TeslaCloud/flux-ce/tree/master

local scaleFactorX = 1 / 1920
local scaleFactorY = 1 / 1080

local function scale(size)
    return math.floor(size * (ScrH() * scaleFactorY))
end

local function scale_x(size)
    return math.floor(size * (ScrW() * scaleFactorX))
end

local PANEL = {}

function PANEL:Init()
    if (IsValid(ix.gui.dev_icon)) then
        ix.gui.dev_icon:Remove()
    end

    ix.gui.dev_icon = self
    local pW, pH = ScrW() * 0.6, ScrH() * 0.6
    self:SetSize(pW, pH)
    self:MakePopup()
    self:Center()

    local buttonSize = scale(48)

    self.model = vgui.Create("DAdjustableModelPanel", self)
    self.model:SetSize(pW * 0.5, pH - buttonSize)
    self.model:Dock(LEFT)
    self.model:DockMargin(0, 0, 0, buttonSize + scale(8))
    self.model:SetModel("models/props_borealis/bluebarrel001.mdl")
    self.model:SetLookAt(Vector(0, 0, 0))

    self.model.LayoutEntity = function() end

    local x = scale_x(4)
    self.best = vgui.Create("DButton", self)
    self.best:SetSize(buttonSize, buttonSize)
    self.best:SetPos(x, pH - buttonSize - scale(4))
    self.best:SetFont("ixIconsMenuButton")
    self.best:SetText("b")
    self.best:SetTooltip(L("iconEditorAlignBest"))

    self.best.DoClick = function()
        local entity = self.model:GetEntity()
        local pos = entity:GetPos()
        local camData = PositionSpawnIcon(entity, pos)

        if (camData) then
            self.model:SetCamPos(camData.origin)
            self.model:SetFOV(camData.fov)
            self.model:SetLookAng(camData.angles)
        end
    end

    x = x + buttonSize + scale_x(4)

    self.front = vgui.Create("DButton", self)
    self.front:SetSize(buttonSize, buttonSize)
    self.front:SetPos(x, pH - buttonSize - scale(4))
    self.front:SetFont("ixIconsMenuButton")
    self.front:SetText("m")
    self.front:SetTooltip(L("iconEditorAlignFront"))

    self.front.DoClick = function()
        local entity = self.model:GetEntity()
        local pos = entity:GetPos()
        local camPos = pos + Vector(-200, 0, 0)
        self.model:SetCamPos(camPos)
        self.model:SetFOV(45)
        self.model:SetLookAng((camPos * -1):Angle())
    end

    x = x + buttonSize + scale_x(4)

    self.above = vgui.Create("DButton", self)
    self.above:SetSize(buttonSize, buttonSize)
    self.above:SetPos(x, pH - buttonSize - scale(4))
    self.above:SetFont("ixIconsMenuButton")
    self.above:SetText("u")
    self.above:SetTooltip(L("iconEditorAlignAbove"))

    self.above.DoClick = function()
        local entity = self.model:GetEntity()
        local pos = entity:GetPos()
        local camPos = pos + Vector(0, 0, 200)
        self.model:SetCamPos(camPos)
        self.model:SetFOV(45)
        self.model:SetLookAng((camPos * -1):Angle())
    end

    x = x + buttonSize + scale_x(4)

    self.right = vgui.Create("DButton", self)
    self.right:SetSize(buttonSize, buttonSize)
    self.right:SetPos(x, pH - buttonSize - scale(4))
    self.right:SetFont("ixIconsMenuButton")
    self.right:SetText("t")
    self.right:SetTooltip(L("iconEditorAlignRight"))

    self.right.DoClick = function()
        local entity = self.model:GetEntity()
        local pos = entity:GetPos()
        local camPos = pos + Vector(0, 200, 0)
        self.model:SetCamPos(camPos)
        self.model:SetFOV(45)
        self.model:SetLookAng((camPos * -1):Angle())
    end

    x = x + buttonSize + scale_x(4)

    self.center = vgui.Create("DButton", self)
    self.center:SetSize(buttonSize, buttonSize)
    self.center:SetPos(x, pH - buttonSize - scale(4))
    self.center:SetFont("ixIconsMenuButton")
    self.center:SetText("T")
    self.center:SetTooltip(L("iconEditorAlignCenter"))

    self.center.DoClick = function()
        local entity = self.model:GetEntity()
        local pos = entity:GetPos()
        self.model:SetCamPos(pos)
        self.model:SetFOV(45)
        self.model:SetLookAng(Angle(0, -180, 0))
    end

    self.best:DoClick()
    self.preview = vgui.Create("DPanel", self)
    self.preview:Dock(FILL)
    self.preview:DockMargin(scale_x(4), 0, 0, 0)
    self.preview:DockPadding(scale_x(4), scale(4), scale_x(4), scale(4))

    self.preview.Paint = function(pnl, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100))
    end

    self.modelLabel = self.preview:Add("DLabel")
    self.modelLabel:Dock(TOP)
    self.modelLabel:SetText("Model")
    self.modelLabel:SetFont("ixMenuButtonFontSmall")
    self.modelLabel:DockMargin(4, 4, 4, 4)

    self.modelPath = vgui.Create("ixTextEntry", self.preview)
    self.modelPath:SetValue(self.model:GetModel())
    self.modelPath:Dock(TOP)
    self.modelPath:SetFont("ixMenuButtonFontSmall")
    self.modelPath:SetPlaceholderText("Model...")

    self.modelPath.OnEnter = function(pnl)
        local model = pnl:GetValue()

        if (model and model != "") then
            self.model:SetModel(model)
            self.item:Rebuild()
        end
    end

    self.modelPath.OnLoseFocus = function(pnl)
        local model = pnl:GetValue()

        if (model and model != "") then
            self.model:SetModel(model)
            self.item:Rebuild()
        end
    end

    self.width = vgui.Create("ixSettingsRowNumber", self.preview)
    self.width:Dock(TOP)
    self.width:SetText(L("iconEditorWidth"))
    self.width:SetMin(1)
    self.width:SetMax(24)
    self.width:SetDecimals(0)
    self.width:SetValue(1)

    self.width.OnValueChanged = function(pnl, value)
        self.item:Rebuild()
    end

    self.height = vgui.Create("ixSettingsRowNumber", self.preview)
    self.height:Dock(TOP)
    self.height:SetText(L("iconEditorHeight"))
    self.height:SetMin(1)
    self.height:SetMax(24)
    self.height:SetDecimals(0)
    self.height:SetValue(1)

    self.height.OnValueChanged = function(pnl, value)
        self.item:Rebuild()
    end

    self.itemPanel = vgui.Create("DPanel", self.preview)
    self.itemPanel:Dock(FILL)

    self.itemPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100))
    end

    self.item = vgui.Create("DModelPanel", self.itemPanel)
    self.item:SetMouseInputEnabled(false)
    self.item.LayoutEntity = function() end

    self.item.PaintOver = function(pnl, w, h)
        surface.SetDrawColor(color_white)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    self.item.Rebuild = function(pnl)
        local slotSize = 64
        local padding = scale(2)
        local slotWidth, slotHeight = math.Round(self.width:GetValue()), math.Round(self.height:GetValue())
        local w, h = slotWidth * (slotSize + padding) - padding, slotHeight * (slotSize + padding) - padding
        pnl:SetModel(self.model:GetModel())
        pnl:SetCamPos(self.model:GetCamPos())
        pnl:SetFOV(self.model:GetFOV())
        pnl:SetLookAng(self.model:GetLookAng())
        pnl:SetSize(w, h)
        pnl:Center()
    end

    self.item:Rebuild()

    timer.Create("ix_icon_editor_update", 0.5, 0, function()
        if IsValid(self) and IsValid(self.model) then
            self.item:Rebuild()
        else
            timer.Remove("ix_icon_editor_update")
        end
    end)

    self.copy = vgui.Create("DButton", self)
    self.copy:SetSize(buttonSize, buttonSize)
    self.copy:SetPos(pW - buttonSize - scale_x(12), pH - buttonSize - scale(12))
    self.copy:SetFont("ixIconsMenuButton")
    self.copy:SetText("}")
    self.copy:SetTooltip(L("iconEditorCopy"))
    self.copy.DoClick = function()
        local camPos = self.model:GetCamPos()
        local camAng = self.model:GetLookAng()
		local str = "ITEM.model = \""..self.model:GetModel().."\"\n"
		.."ITEM.width = "..math.Round(self.width:GetValue()).."\n"
		.."ITEM.height = "..math.Round(self.height:GetValue()).."\n"
		.."ITEM.iconCam = {\n"
		.."\tpos = Vector("..math.Round(camPos.x, 2)..", "..math.Round(camPos.y, 2)..", "..math.Round(camPos.z, 2).."),\n"
		.."\tang = Angle("..math.Round(camAng.p, 2)..", "..math.Round(camAng.y, 2)..", "..math.Round(camAng.r, 2).."),\n"
		.."\tfov = "..math.Round(self.model:GetFOV(), 2).."\n"
		.."}\n"

        SetClipboardText(str)
        ix.util.Notify(L("iconEditorCopied"))
    end
end

vgui.Register("ix_icon_editor", PANEL, "DFrame")

concommand.Add("ix_dev_icon", function()
    if (LocalPlayer():IsAdmin()) then
        vgui.Create("ix_icon_editor")
    end
end)
