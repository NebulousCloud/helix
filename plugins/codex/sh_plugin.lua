PLUGIN.name = "Codex"
PLUGIN.author = "@liliaplayer"
PLUGIN.desc = "Adds an in-game codex"

Codex = Codex or {}
Codex.Categories = Codex.Categories or {}

if SERVER then
    util.AddNetworkString("ixCodexData")
    util.AddNetworkString("ixCodexAddCategory")
    util.AddNetworkString("ixCodexAddEntry")

    local function Sync(client)
        local json = util.TableToJSON(Codex.Categories)
        local compressed = util.Compress(json)
        local length = compressed:len()

        net.Start("ixCodexData")
            net.WriteUInt(length, 32)
            net.WriteData(compressed, length)
        if client then
            net.Send(client)
        else
            net.Broadcast()
        end
    end

    function Codex.SetupTables()
        local query = mysql:Create("ix_codex_categories")
            query:Create("id", "VARCHAR(64) NOT NULL")
            query:Create("title", "VARCHAR(255) NOT NULL")
            query:PrimaryKey("id")
        query:Execute()

        query = mysql:Create("ix_codex_entries")
            query:Create("entry_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
            query:Create("category_id", "VARCHAR(64) NOT NULL")
            query:Create("name", "VARCHAR(255) NOT NULL")
            query:Create("type", "VARCHAR(32) NOT NULL")
            query:Create("content", "TEXT")
            query:PrimaryKey("entry_id")
        query:Execute()
    end

    function Codex.Load()
        Codex.Categories = {}

        local query = mysql:Select("ix_codex_categories")
            query:Callback(function(result)
                if istable(result) then
                    for _, v in ipairs(result) do
                        Codex.Categories[v.id] = {title = v.title, entries = {}}
                    end
                end

                local q = mysql:Select("ix_codex_entries")
                    q:Callback(function(res)
                        if istable(res) then
                            for _, e in ipairs(res) do
                                local cat = Codex.Categories[e.category_id]
                                if cat then
                                    cat.entries[#cat.entries + 1] = {
                                        name = e.name,
                                        type = e.type,
                                        content = e.content
                                    }
                                end
                            end
                        end

                        Sync()
                    end)
                q:Execute()
            end)
        query:Execute()
    end

    function Codex.RegisterCategory(id, title)
        if Codex.Categories[id] then return end

        Codex.Categories[id] = {title = title, entries = {}}

        local query = mysql:Insert("ix_codex_categories")
            query:Insert("id", id)
            query:Insert("title", title)
        query:Execute()

        Sync()
    end

    function Codex.RegisterEntry(catId, name, kind, content)
        local cat = Codex.Categories[catId]
        if not cat then return end

        table.insert(cat.entries, {
            name = name,
            type = string.lower(kind or "text"),
            content = content
        })

        local query = mysql:Insert("ix_codex_entries")
            query:Insert("category_id", catId)
            query:Insert("name", name)
            query:Insert("type", string.lower(kind or "text"))
            query:Insert("content", content)
        query:Execute()

        Sync()
    end

    net.Receive("ixCodexAddCategory", function(len, client)
        local id = net.ReadString()
        local title = net.ReadString()
        Codex.RegisterCategory(id, title)
    end)

    net.Receive("ixCodexAddEntry", function(len, client)
        local catId = net.ReadString()
        local name = net.ReadString()
        local kind = net.ReadString()
        local content = net.ReadString()
        Codex.RegisterEntry(catId, name, kind, content)
    end)

    function PLUGIN:PlayerInitialSpawn(client)
        timer.Simple(1, function()
            if IsValid(client) then
                Sync(client)
            end
        end)
    end

    function PLUGIN:OnLoaded()
        Codex.SetupTables()
        Codex.Load()
    end
else
    net.Receive("ixCodexData", function()
        local length = net.ReadUInt(32)
        local data = net.ReadData(length)
        local uncompressed = util.Decompress(data)
        Codex.Categories = util.JSONToTable(uncompressed) or {}
    end)

    function Codex.RegisterCategory(id, title)
        net.Start("ixCodexAddCategory")
            net.WriteString(id)
            net.WriteString(title)
        net.SendToServer()
    end

    function Codex.RegisterEntry(catId, name, kind, content)
        net.Start("ixCodexAddEntry")
            net.WriteString(catId)
            net.WriteString(name)
            net.WriteString(kind)
            net.WriteString(content)
        net.SendToServer()
    end
end

function Codex.Open(parent)
    if IsValid(Codex.Frame) then Codex.Frame:Remove() end
    local sw, sh = ScrW(), ScrH()
    local fw, fh

    if IsValid(parent) then
        fw, fh = parent:GetSize()
    else
        fw, fh = sw * 0.85, sh * 0.85
    end

    local skin = derma.GetDefaultSkin()
    local frame = vgui.Create(IsValid(parent) and "DPanel" or "DFrame", parent)

    if IsValid(parent) then
        frame:Dock(FILL)
    else
        frame:SetSize(fw, fh)
        frame:Center()
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame:SetTitle("")
    end

    Codex.Frame = frame
    local title = vgui.Create("DLabel", frame)
    title:SetFont("DermaLarge")
    title:SetText("CODEX")
    title:SizeToContents()
    title:SetPos(16, 8)
    local leftHeight = fh - 102
    local left = vgui.Create("DScrollPanel", frame)
    left:SetSize(fw * 0.35, leftHeight)
    left:SetPos(0, 72)
    local divider = vgui.Create("DPanel", frame)
    divider:SetSize(2, fh - 72)
    divider:SetPos(fw * 0.35, 72)
    divider.Paint = function(_, w, h)
        local c = skin.Colours.Label.Dark
        surface.SetDrawColor(c.r, c.g, c.b, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local content = vgui.Create("DPanel", frame)
    content:SetSize(fw - fw * 0.35 - 2, fh - 72)
    content:SetPos(fw * 0.35 + 2, 72)
    local textPanel = vgui.Create("RichText", content)
    textPanel:Dock(FILL)
    textPanel:SetVisible(false)
    local htmlPanel = vgui.Create("DHTML", content)
    htmlPanel:Dock(FILL)
    htmlPanel:SetVisible(false)
    local function showEntry(e)
        textPanel:SetVisible(false)
        htmlPanel:SetVisible(false)
        if e.type == "html" then
            htmlPanel:SetHTML(e.content)
            htmlPanel:SetVisible(true)
        else
            textPanel:SetText("")
            textPanel:InsertColorChange(255, 255, 255, 255)
            textPanel:AppendText(e.content)
            textPanel:SetVisible(true)
        end
    end

    for _, cat in SortedPairsByMemberValue(Codex.Categories, "title") do
        local header = left:Add("> " .. string.upper(cat.title))
        header.Header:SetFont("Trebuchet24")
        header.Header:SetTextColor(skin.Colours.Label.Bright)
        header.Header:SetContentAlignment(0)
        local list = vgui.Create("DListLayout")
        header:SetContents(list)
        header:SetExpanded(false)
        for _, entry in ipairs(cat.entries) do
            local b = vgui.Create("DButton")
            b:SetTall(26)
            b:SetText("    " .. entry.name)
            b:SetFont("DermaDefault")
            b:SetTextColor(skin.Colours.Label.Bright)
            b:Dock(TOP)
            b:SetPaintBackground(false)
            b.DoClick = function() showEntry(entry) end
            list:Add(b)
        end
    end

    local entryBtn = vgui.Create("DButton", frame)
    entryBtn:SetSize(fw * 0.35, 30)
    entryBtn:SetPos(0, fh - 60)
    entryBtn:SetText("Create Entry")
    entryBtn.DoClick = function()
        local w = vgui.Create("DFrame")
        w:SetSize(400, 260)
        w:Center()
        w:SetTitle("New Entry")
        w:MakePopup()
        local catBox = vgui.Create("DComboBox", w)
        catBox:Dock(TOP)
        catBox:SetTall(25)
        catBox:DockMargin(10, 10, 10, 0)
        for id, cat in pairs(Codex.Categories) do
            catBox:AddChoice(cat.title, id)
        end

        local nameEntry = vgui.Create("DTextEntry", w)
        nameEntry:Dock(TOP)
        nameEntry:SetTall(25)
        nameEntry:DockMargin(10, 10, 10, 0)
        nameEntry:SetPlaceholderText("Title")
        local typeBox = vgui.Create("DComboBox", w)
        typeBox:Dock(TOP)
        typeBox:SetTall(25)
        typeBox:DockMargin(10, 10, 10, 0)
        typeBox:AddChoice("Text")
        typeBox:AddChoice("HTML")
        typeBox:ChooseOptionID(1)
        local body = vgui.Create("DTextEntry", w)
        body:Dock(FILL)
        body:SetMultiline(true)
        body:DockMargin(10, 10, 10, 0)
        local ok = vgui.Create("DButton", w)
        ok:Dock(BOTTOM)
        ok:SetTall(30)
        ok:SetText("Create")
        ok.DoClick = function()
            local _, catId = catBox:GetSelected()
            local name = string.Trim(nameEntry:GetValue() or "")
            local kind = string.lower(typeBox:GetValue() or "text")
            local content = body:GetValue() or ""
            if not catId or name == "" or content == "" then return end
            Codex.RegisterEntry(catId, name, kind, content)
            w:Close()
            Codex.Open()
        end
    end

    local catBtn = vgui.Create("DButton", frame)
    catBtn:SetSize(fw * 0.35, 30)
    catBtn:SetPos(0, fh - 30)
    catBtn:SetText("Create Category")
    catBtn.DoClick = function()
        local w = vgui.Create("DFrame")
        w:SetSize(300, 120)
        w:Center()
        w:SetTitle("New Category")
        w:MakePopup()
        local text = vgui.Create("DTextEntry", w)
        text:Dock(TOP)
        text:SetTall(25)
        text:DockMargin(10, 10, 10, 0)
        text:SetPlaceholderText("Category Title")
        local ok = vgui.Create("DButton", w)
        ok:Dock(BOTTOM)
        ok:SetTall(30)
        ok:SetText("Create")
        ok.DoClick = function()
            local title = string.Trim(text:GetValue() or "")
            if title == "" then return end
            local id = string.lower(string.gsub(title, "[^%w]", "_"))
            Codex.RegisterCategory(id, title)
            w:Close()
            Codex.Open()
        end
    end

    if not IsValid(parent) then
        frame:MakePopup()
    end
end

concommand.Add("codex", Codex.Open)

if CLIENT then
    hook.Add("CreateMenuButtons", "ixCodex", function(tabs)
        tabs["codex"] = {
            Create = function(info, container)
                Codex.Open(container)
            end,

            OnSelected = function(info, container)
                if not IsValid(Codex.Frame) then
                    Codex.Open(container)
                end
            end,

            OnDeselected = function(info, container)
                if IsValid(Codex.Frame) and Codex.Frame:GetParent() == container then
                    Codex.Frame:Remove()
                end
            end
        }
    end)
end
