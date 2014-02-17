local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("help"))

		local data = {}
		local help = {}

		self.tree = self:Add("DTree")
		self.tree:Dock(LEFT)
		self.tree:SetWide(ScrW() * 0.155)

		self.body = self:Add("DHTML")
		self.body:Dock(FILL)
		self.body:DockMargin(4, 1, 1, 1)

		function data:AddHelp(key, callback, icon)
			help[key] = {callback, icon or "icon16/folder.png"}
		end

		function data:AddCallback(key, callback)
			help[key].callback = callback
		end

		hook.Run("BuildHelpOptions", data, self.tree)

		local prefix = [[
			<head>
				<style>
					body {
						background-color: #fbfcfc;
						color: #2c3e50;
						font-family: Verdana, Geneva, sans-serif;
					}
				</style>
			</head>
		]]

		function self.body:SetContents(html)
			self:SetHTML(prefix..html)
		end

		for k, v in SortedPairs(help) do
			local node = self.tree:AddNode(k)
			node.Icon:SetImage(v[2])
			node.DoClick = function()
				local content = v[1](node)

				if (content) then
					if (content:sub(1, 4) == "http") then
						self.body:OpenURL(content)
					else
						self.body:SetContents(content)
					end
				end
			end

			if (v.callback) then
				v.callback(node, self.body)
			end
		end
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end
vgui.Register("nut_Help", PANEL, "DFrame")