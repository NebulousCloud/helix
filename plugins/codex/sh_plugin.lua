PLUGIN.name = "Cameras"
PLUGIN.author = "@liliaplayer"
PLUGIN.desc = "Adds Map Cameras"
if not CLIENT then return end
if not Codex then Codex = {} end
local dataFile = "codex_data.txt"
function Codex.Load()
    if not file.Exists(dataFile, "DATA") then return end
    local t = util.JSONToTable(file.Read(dataFile, "DATA") or "")
    if t then Codex.Categories = t end
end

Codex.Categories = Codex.Categories or {}
Codex.Load()
local function save()
    file.Write(dataFile, util.TableToJSON(Codex.Categories, true))
end

function Codex.RegisterCategory(id, title)
    if Codex.Categories[id] then return end
    Codex.Categories[id] = {
        title = title,
        entries = {}
    }

    save()
end

function Codex.RegisterEntry(catId, name, kind, content)
    local cat = Codex.Categories[catId]
    if not cat then return end
    table.insert(cat.entries, {
        name = name,
        type = string.lower(kind or "text"),
        content = content
    })

    save()
end

function Codex.Open()
    if IsValid(Codex.Frame) then Codex.Frame:Remove() end
    local sw, sh = ScrW(), ScrH()
    local fw, fh = sw * 0.85, sh * 0.85
    local skin = derma.GetDefaultSkin()
    local frame = vgui.Create("DFrame")
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetTitle("")
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

    frame:MakePopup()
end

concommand.Add("codex", Codex.Open)