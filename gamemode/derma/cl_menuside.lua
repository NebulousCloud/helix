local PANEL = {}
	local width = ScrW() * 0.3

	function PANEL:Init()
		self:ParentToHUD()
		self:SetPos(ScrW(), 0)
		self:SetSize(width, ScrH())
		self:SetDrawBackground(false)
		self:MoveTo(ScrW() - width, 0, 0.25, 0, 0.125)

		hook.Run("CreateSideMenu", self)
	end

	function PANEL:SlideOut()
		self:MoveTo(ScrW(), 0, 0.25, 0, 0.15)

		timer.Simple(0.25, function()
			if (!IsValid(self)) then
				return
			end

			self:Remove()
		end)
	end

	local gradient = surface.GetTextureID("vgui/gradient-r")

	function PANEL:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.SetTexture(gradient)
		surface.DrawTexturedRect(0, 0, w, h)
	end
vgui.Register("nut_MenuSide", PANEL, "DPanel")

--[[
-- Command to search within the materials folder.
-- May freeze your Garry's Mod for a little.

concommand.Add("mat_search", function(p, c, a)
	local found = {}
	local match = a[1]

	print("Searching for materials with '"..match.."'")
	timer.Simple(FrameTime() * 5, function()
		local function search(dir)
			local files, folders = file.Find(dir.."/*", "GAME")

			if (folders) then
				for k, v in pairs(folders) do
					search(dir.."/"..v)
				end
			end

			if (files) then
				for k, v in pairs(files) do
					if (string.find(v, a[1])) then
						found[#found + 1] = dir.."/"..v
					end
				end
			end
		end

		search("materials")

		local header = "----- "..#found.." RESULTS -----"
		print(header)
		for k, v in ipairs(found) do
			print(v)
		end
		print(string.rep("-", #header))
	end)
end)
--]]