if (CLIENT) then
	hook.Add("CreateMenuButtons", "nutHelpMenu", function(tabs)
		tabs["zhelps"] = function(panel)
			local w, h = panel:GetSize()
			local body = [[<body style="color: #FAFAFA; font-family: Arial, Geneva, Helvetica, sans-serif;">]]
			local html = panel:Add("DHTML")
			html:SetPos(4, 4)
			html:SetSize(w - 8, h - 8)

			for k, v in SortedPairs(nut.plugin.list) do
				body = (body..[[
					<p>
						<span style="font-size: 22;"><b>%s</b><br /></span>
						<span style="font-size: smaller;">
						<b>%s</b>: %s<br />
						<b>%s</b>: %s
				]]):format(v.name or "Unknown", L"desc", v.desc, L"author", v.author)

				if (v.version) then
					body = body.."<br /><b>"..L"version".."</b>: "..v.version
				end

				body = body.."</span></p>"
			end

			html:SetHTML(body)
		end
	end)
end