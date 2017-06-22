
local PANEL = {}
    function PANEL:Init()
        self:SetTall(64)
        
        local function assignClick(panel)   
            panel.OnMousePressed = function()
                self.pressing = -1
                self:onClick()
            end
            panel.OnMouseReleased = function()
                if (self.pressing) then
                    self.pressing = nil
                    --self:onClick()
                end
            end
        end


        self.icon = self:Add("SpawnIcon")
        self.icon:SetSize(128, 64)
        self.icon:InvalidateLayout(true)
        self.icon:Dock(LEFT)
        self.icon.PaintOver = function(this, w, h)
            /*
            if (panel.payload.model == k) then
                local color = nut.config.get("color", color_white)

                surface.SetDrawColor(color.r, color.g, color.b, 200)

                for i = 1, 3 do
                    local i2 = i * 2

                    surface.DrawOutlinedRect(i, i, w - i2, h - i2)
                end

                surface.SetDrawColor(color.r, color.g, color.b, 75)
                surface.SetMaterial(gradient)
                surface.DrawTexturedRect(0, 0, w, h)
            end
            */
        end
        assignClick(self.icon) 

        self.limit = self:Add("DLabel")
        self.limit:Dock(RIGHT)
        self.limit:SetMouseInputEnabled(true)
        self.limit:SetCursor("hand")
        self.limit:SetExpensiveShadow(1, Color(0, 0, 60))
        self.limit:SetContentAlignment(5)
        self.limit:SetFont("nutMediumFont")
        self.limit:SetWide(64)
        assignClick(self.limit) 

        self.label = self:Add("DLabel")
        self.label:Dock(FILL)
        self.label:SetMouseInputEnabled(true)
        self.label:SetCursor("hand")
        self.label:SetExpensiveShadow(1, Color(0, 0, 60))
        self.label:SetContentAlignment(5)
        self.label:SetFont("nutMediumFont")
        assignClick(self.label) 
    end

    function PANEL:onClick()
        nut.command.send("beclass", self.class)
    end

    function PANEL:setNumber(number)
        local limit = self.data.limit

        if (limit > 0) then
            self.limit:SetText(Format("%s/%s", number, limit))
        else
            self.limit:SetText("∞")
        end
    end

    function PANEL:setClass(data)
        if (data.model) then
            local model = data.model
            if (type(model):lower() == "table") then
                model = table.Random(model)
            end

            self.icon:SetModel(model)
        else
            local char = LocalPlayer():getChar()
            local model = LocalPlayer():GetModel()

            if (char) then
                model = char:getModel()
            end

            self.icon:SetModel(model)
        end

        self.label:SetText(L(data.name))   
        self.data = data 
        self.class = data.index

        self:setNumber(#nut.class.getPlayers(data.index))
    end
vgui.Register("nutClassPanel", PANEL, "DPanel")

PANEL = {}
    function PANEL:Init()
        nut.gui.classes = self

        self:SetSize(self:GetParent():GetSize())

        self.list = vgui.Create("DPanelList", self)
        self.list:Dock(FILL)
        self.list:EnableVerticalScrollbar()
        self.list:SetSpacing(5)
        self.list:SetPadding(5)

        self.classPanels = {}
        self:loadClasses()
    end

    function PANEL:loadClasses()
        self.list:Clear()
        
        for k, v in ipairs(nut.class.list) do
            local no, why = nut.class.canBe(LocalPlayer(), k)
            local itsFull = ("class is full" == why)

            if (no or itsFull) then
                local panel = vgui.Create("nutClassPanel", self.list)
                panel:setClass(v)
                table.insert(self.classPanels, panel)

                self.list:AddItem(panel)
            end
        end
    end
vgui.Register("nutClasses", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "nutClasses", function(tabs)
    local cnt = table.Count(nut.class.list)

    if (cnt <= 1) then return end
    
    for k, v in ipairs(nut.class.list) do
        if (!nut.class.canBe(LocalPlayer(), k)) then
            continue
        else
            tabs["classes"] = function(panel)
                panel:Add("nutClasses")
            end

            return
        end
    end
end)

netstream.Hook("classUpdate", function(joinedClient)
    if (nut.gui.classes and nut.gui.classes:IsVisible()) then
        if (joinedClient == LocalPlayer()) then
            nut.gui.classes:loadClasses()
        else
            for k, v in ipairs(nut.gui.classes.classPanels) do
                local data = v.data

                v:setNumber(#nut.class.getPlayers(data.index))
            end
        end
    end
end)