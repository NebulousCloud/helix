BASE.name = "Base Book"
BASE.contents = "Hello world!"
BASE.category = "Literature"
BASE.model = "models/props_lab/bindergraylabel01b.mdl"
BASE.price = 10
BASE.functions = {}
BASE.functions.Read = {
	icon = "icon16/book_open.png",
	run = function(item)
		if (CLIENT) then
			if (IsValid(nut.gui.book)) then
				nut.gui.book:Remove()
			end

			if (IsValid(nut.gui.menu)) then
				nut.gui.menu.close:DoClick()
			end

			local frame = vgui.Create("DFrame")
			frame:SetSize(ScrW() * 0.375, ScrH() * 0.8)
			frame:SetTitle(item.name)
			frame:Center()
			frame:MakePopup()

			frame.html = frame:Add("DHTML")
			frame.html:Dock(FILL)
			frame.html:SetHTML([[
				<body style="background-color: #fefefe;">
				]]..item.contents..[[
				</body>
			]])
		end

		return false
	end
}